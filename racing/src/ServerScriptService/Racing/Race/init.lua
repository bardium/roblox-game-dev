--[[
	The Race class keeps track of the state of a currently running race.
	This includes handling checkpoints, lap times, the finish leaderboard, etc.
--]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Constants = require(ReplicatedStorage.Constants)
local disconnectAndClear = require(ReplicatedStorage.Utility.disconnectAndClear)
local getCheckpoints = require(ReplicatedStorage.Utility.getCheckpoints)
local getLeaderboard = require(ReplicatedStorage.Utility.getLeaderboard)
local getStartingArea = require(ReplicatedStorage.Utility.getStartingArea)
local createRaceLeaderboardEntry = require(script.createRaceLeaderboardEntry)
local lineupPlayers = require(script.lineupPlayers)
local holdPlayers = require(script.holdPlayers)

local remotes = ReplicatedStorage.Remotes
local joinRaceRemote = remotes.JoinRace
local leaveRaceRemote = remotes.LeaveRace
local finishedRaceRemote = remotes.FinishedRace
local showCountdownRemote = remotes.ShowCountdown

local UPDATE_RATE = 5

local Race = {}
Race.__index = Race

function Race.new(raceContainer: Model, players: { Player }, finishedCallback: () -> ())
	-- Make sure all the necessary attributes and instances exist
	local checkpoints = getCheckpoints(raceContainer)
	local startingArea = getStartingArea(raceContainer)
	local leaderboardFolder = getLeaderboard(raceContainer)

	local self = {
		raceContainer = raceContainer,
		startingArea = startingArea,
		checkpoints = checkpoints,
		leaderboardFolder = leaderboardFolder,
		players = {},
		connections = {},
		lineupAlignPositions = {},
		startTime = 0,
		finishedCallback = finishedCallback,
		lastUpdate = 0,
	}
	setmetatable(self, Race)

	self:initialize(players)

	return self
end

function Race:playerFinishedRace(player: Player)
	-- Calculate place and total time
	local playerPlace = #self.leaderboardFolder:GetChildren() + 1
	local playerTotalTime = os.clock() - self.startTime
	local playerBestLapTime = player:GetAttribute(Constants.PLAYER_BEST_LAP_TIME_ATTRIBUTE)

	-- Create an object value in the leaderboard to store the player's place and times
	-- Since multiple races could exist at once, we store leaderboard values inside each race rather
	-- than in leaderstats.
	local leaderboardEntry = createRaceLeaderboardEntry(player, playerPlace, playerTotalTime, playerBestLapTime)
	leaderboardEntry.Parent = self.leaderboardFolder

	finishedRaceRemote:FireClient(player, self.raceContainer)

	self:removePlayer(player)
end

function Race:playerFinishedLap(player: Player, lap: number)
	local numberOfLaps = self.raceContainer:GetAttribute(Constants.NUMBER_OF_LAPS_ATTRIBUTE)
	-- Calculate current lap time and set best lap time
	local playerLastLapStarted = player:GetAttribute(Constants.PLAYER_LAST_LAP_STARTED_ATTRIBUTE)
	local playerLapTime = os.clock() - playerLastLapStarted
	local playerBestLapTime = player:GetAttribute(Constants.PLAYER_BEST_LAP_TIME_ATTRIBUTE)

	if playerBestLapTime then
		player:SetAttribute(Constants.PLAYER_BEST_LAP_TIME_ATTRIBUTE, math.min(playerLapTime, playerBestLapTime))
	else
		player:SetAttribute(Constants.PLAYER_BEST_LAP_TIME_ATTRIBUTE, playerLapTime)
	end

	if lap == numberOfLaps then
		-- If the player has completed all the laps, they are finished with the race
		self:playerFinishedRace(player)
	else
		player:SetAttribute(Constants.PLAYER_LAST_LAP_STARTED_ATTRIBUTE, os.clock())
		player:SetAttribute(Constants.PLAYER_LAP_ATTRIBUTE, lap + 1)
	end
end

function Race:playerPassedCheckpoint(player: Player, checkpoint: number)
	player:SetAttribute(Constants.PLAYER_LAST_PASSED_CHECKPOINT_ATTRIBUTE, os.clock())

	if checkpoint == #self.checkpoints then
		-- If the player passed the last checkpoint then they've completed the current lap
		player:SetAttribute(Constants.PLAYER_CHECKPOINT_ATTRIBUTE, 0)
		local lap = player:GetAttribute(Constants.PLAYER_LAP_ATTRIBUTE)
		self:playerFinishedLap(player, lap)
	else
		player:SetAttribute(Constants.PLAYER_CHECKPOINT_ATTRIBUTE, checkpoint)
	end
end

function Race:onCheckpointTouched(checkpoint: number, hit: BasePart)
	if hit.Name ~= "HumanoidRootPart" then
		return
	end
	local character = hit.Parent
	local player = Players:GetPlayerFromCharacter(character)
	-- Check that the player exists and is participating in the current race
	if player == nil or table.find(self.players, player) == nil then
		return
	end

	local playerCheckpoint = player:GetAttribute(Constants.PLAYER_CHECKPOINT_ATTRIBUTE)
	if playerCheckpoint == checkpoint - 1 then
		self:playerPassedCheckpoint(player, checkpoint)
	end
end

function Race:lineupAndHoldPlayers()
	local lineupMaxPlayers = self.raceContainer:GetAttribute(Constants.START_LINEUP_MAX_PLAYERS_ATTRIBUTE)
	local lineupPadding = self.raceContainer:GetAttribute(Constants.START_LINEUP_PADDING_ATTRIBUTE)
	local position = self.startingArea.Position
	local direction = (self.checkpoints[1].Position - position) * Vector3.new(1, 0, 1)
	local lineupCFrame = CFrame.lookAt(position, position + direction)

	lineupPlayers(self.players, lineupCFrame, lineupMaxPlayers, lineupPadding)
	local alignPositions = holdPlayers(self.players)
	self.lineupAlignPositions = alignPositions
end

function Race:start()
	local startCountdown = self.raceContainer:GetAttribute(Constants.START_COUTNDOWN_ATTRIBUTE)
	-- Lineup the players and hold them in place
	self:lineupAndHoldPlayers()

	-- Wait a second to let the vehicles settle
	task.wait(1)

	for _, player in self.players do
		showCountdownRemote:FireClient(player, startCountdown)
	end

	task.wait(startCountdown)

	local now = os.clock()

	-- Initialize player timing attributes
	self.startTime = now
	for _, player in self.players do
		player:SetAttribute(Constants.PLAYER_LAST_PASSED_CHECKPOINT_ATTRIBUTE, now)
		player:SetAttribute(Constants.PLAYER_LAST_LAP_STARTED_ATTRIBUTE, now)
	end

	-- Enable checkpoint passing triggers
	for checkpoint, checkpointPart in self.checkpoints do
		table.insert(
			self.connections,
			checkpointPart.Touched:Connect(function(...)
				self:onCheckpointTouched(checkpoint, ...)
			end)
		)
	end

	-- Enable player timeout loop
	table.insert(
		self.connections,
		RunService.Heartbeat:Connect(function(deltaTime: number)
			self:onHeartbeat(deltaTime)
		end)
	)

	-- Release the players
	for _, alignPosition in self.lineupAlignPositions do
		-- AlignPositions might have been destroyed if a player left during the countdown
		if alignPosition:IsDescendantOf(game) then
			alignPosition:Destroy()
		end
	end
	table.clear(self.lineupAlignPositions)
end

function Race:finish()
	-- Call the finishedCallback and clean up the race object
	self.finishedCallback()
	self:destroy()
end

function Race:addPlayer(player: Player)
	-- Setup attributes
	player:SetAttribute(Constants.PLAYER_LAP_ATTRIBUTE, 1)
	player:SetAttribute(Constants.PLAYER_CHECKPOINT_ATTRIBUTE, 0)
	player:SetAttribute(Constants.PLAYER_LAST_PASSED_CHECKPOINT_ATTRIBUTE, 0)
	player:SetAttribute(Constants.PLAYER_BEST_LAP_TIME_ATTRIBUTE, nil)
	player:SetAttribute(Constants.PLAYER_LAST_LAP_STARTED_ATTRIBUTE, 0)

	table.insert(self.players, player)

	joinRaceRemote:FireClient(player, self.raceContainer)
end

function Race:removePlayer(player: Player)
	local index = table.find(self.players, player)
	if not index then
		return
	end

	table.remove(self.players, index)

	-- If the player is still in the experience, clean up tags and attributes
	if player.Parent == Players then
		player:RemoveTag(Constants.PLAYER_IN_RACE_TAG)
		leaveRaceRemote:FireClient(player)
	end

	-- If this player was the last one in the race, the race is finished
	if #self.players == 0 then
		self:finish()
	end
end

function Race:onHeartbeat(_deltaTime: number)
	local maxTimeBetweenCheckpoints = self.raceContainer:GetAttribute(Constants.MAX_TIME_BETWEEN_CHECKPOINTS_ATTRIBUTE)
	local elapsed = os.clock() - self.lastUpdate
	if elapsed < 1 / UPDATE_RATE then
		return
	end
	self.lastUpdate = os.clock()

	-- Remove players who have not passed a checkpoint in the required time
	-- Loop backwards through the table to avoid skipping over items whenever one is removed
	for i = #self.players, 1, -1 do
		local player = self.players[i]
		local lastPassedCheckpoint = player:GetAttribute(Constants.PLAYER_LAST_PASSED_CHECKPOINT_ATTRIBUTE)
		local timeSinceLastCheckpoint = os.clock() - lastPassedCheckpoint
		if timeSinceLastCheckpoint > maxTimeBetweenCheckpoints then
			self:removePlayer(player)
		end
	end
end

function Race:initialize(players: { Player })
	-- Remove players who leave the experience
	table.insert(
		self.connections,
		Players.PlayerRemoving:Connect(function(player: Player)
			if table.find(self.players, player) then
				self:removePlayer(player)
			end
		end)
	)

	self.leaderboardFolder:ClearAllChildren()

	-- Initialize all the players in the race
	for _, player in players do
		self:addPlayer(player)
	end
end

function Race:destroy()
	disconnectAndClear(self.connections)
end

return Race
