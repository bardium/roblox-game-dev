--[[
	The RaceManager class keeps track of players in the starting area and starts races
	when enough players have joined.
--]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Constants = require(ReplicatedStorage.Constants)
local Race = require(script.Parent.Race)
local createBorderBeams = require(script.createBorderBeams)
local getDriversInPart = require(script.getDriversInPart)
local getStartingArea = require(ReplicatedStorage.Utility.getStartingArea)
local getCheckpoints = require(ReplicatedStorage.Utility.getCheckpoints)

local ManagerState = {
	Waiting = "Waiting",
	Starting = "Starting",
	Racing = "Racing",
}

local raceGuiTemplate = script.RaceGui

local UPDATE_RATE = 5

local RaceManager = {
	ManagerState = ManagerState,
}
RaceManager.__index = RaceManager

function RaceManager.new(raceContainer: Model)
	local startingArea = getStartingArea(raceContainer)
	local checkpoints = getCheckpoints(raceContainer)

	local raceGui = raceGuiTemplate:Clone()
	raceGui.Parent = startingArea

	local borderBeams = createBorderBeams(startingArea)

	-- Hide the starting area and checkpoint parts. They are left visible in studio to be easily edited.
	startingArea.Transparency = 1
	for _, checkpoint in checkpoints do
		checkpoint.Transparency = 1
	end

	local self = {
		raceContainer = raceContainer,
		raceGui = raceGui,
		borderBeams = borderBeams,
		startingArea = startingArea,
		players = {},
		lastUpdate = 0,
		connections = {},
	}
	setmetatable(self, RaceManager)

	self:initialize()

	return self
end

function RaceManager:updateGui()
	local state = self.raceContainer:GetAttribute(Constants.MANAGER_STATE_ATTRIBUTE)
	local minPlayers = self.raceContainer:GetAttribute(Constants.MIN_PLAYERS_ATTRIBUTE)
	local maxPlayers = self.raceContainer:GetAttribute(Constants.MAX_PLAYERS_ATTRIBUTE)

	self.raceGui.ContentFrame.PlayersFrame.PlayersLabel.Text = `{#self.players}/{minPlayers}-{maxPlayers}`

	if state == ManagerState.Waiting then
		self.raceGui.Enabled = true
		self.raceGui.ContentFrame.StatusLabel.Text = "WAITING..."
	elseif state == ManagerState.Starting then
		self.raceGui.Enabled = true
		local countdown = self.raceContainer:GetAttribute(Constants.START_DELAY_COUNTDOWN_ATTRIBUTE)
		self.raceGui.ContentFrame.StatusLabel.Text = `STARTING IN {countdown}...`
	else
		self.raceGui.Enabled = false
	end

	for _, beam in self.borderBeams do
		beam.Enabled = self.raceGui.Enabled
	end
end

function RaceManager:canStart(): boolean
	local minPlayers = self.raceContainer:GetAttribute(Constants.MIN_PLAYERS_ATTRIBUTE)
	if #self.players < minPlayers then
		return false
	end
	if self.raceContainer:GetAttribute(Constants.MANAGER_STATE_ATTRIBUTE) == ManagerState.Racing then
		return false
	end
	return true
end

function RaceManager:startCountdown()
	local startDelay = self.raceContainer:GetAttribute(Constants.START_DELAY_ATTRIBUTE)
	local maxPlayers = self.raceContainer:GetAttribute(Constants.MAX_PLAYERS_ATTRIBUTE)

	if self.raceContainer:GetAttribute(Constants.MANAGER_STATE_ATTRIBUTE) ~= ManagerState.Waiting then
		return
	end
	self.raceContainer:SetAttribute(Constants.MANAGER_STATE_ATTRIBUTE, ManagerState.Starting)

	local countdown = startDelay

	task.spawn(function()
		repeat
			self.raceContainer:SetAttribute(Constants.START_DELAY_COUNTDOWN_ATTRIBUTE, countdown)
			task.wait(1)
			countdown -= 1
			-- If the race reaches the max amount of players, no need to wait for the rest of the countdown
			if #self.players == maxPlayers then
				countdown = 0
			end
		until countdown == 0 or not self:canStart()

		-- Force update players right before starting to avoid edge cases such as a player exiting their
		-- vehicle right before the race starts.
		self:updatePlayers()

		if countdown == 0 and self:canStart() then
			-- Make sure that the countdown finished and that we still have enough players to start the race
			self:start()
		else
			-- If the countdown didn't finish or there aren't enough players, reset back to the waiting state
			-- and wait for players to join again.
			self:reset()
		end
	end)
end

function RaceManager:start()
	self.raceContainer:SetAttribute(Constants.MANAGER_STATE_ATTRIBUTE, ManagerState.Racing)
	-- Create a new race object with the current players in the starting area
	local race = Race.new(self.raceContainer, self.players, function()
		self:reset()
	end)
	-- Start the race
	race:start()
end

function RaceManager:reset()
	-- Loop backwards through the table to avoid skipping over items whenever one is removed
	for i = #self.players, 1, -1 do
		local player = self.players[i]
		self:removePlayer(player)
	end

	self.raceContainer:SetAttribute(Constants.MANAGER_STATE_ATTRIBUTE, ManagerState.Waiting)
end

function RaceManager:addPlayer(player: Player)
	local maxPlayers = self.raceContainer:GetAttribute(Constants.MAX_PLAYERS_ATTRIBUTE)
	if #self.players == maxPlayers then
		warn("Race is full")
		return
	end
	if table.find(self.players, player) then
		warn(`{player} is already in the race`)
		return
	end
	if player:HasTag(Constants.PLAYER_IN_RACE_TAG) then
		warn(`{player} is already in another race`)
	end

	player:AddTag(Constants.PLAYER_IN_RACE_TAG)
	table.insert(self.players, player)

	-- If there are enough players to start the race, initiate the countdown
	if self:canStart() then
		self:startCountdown()
	end
end

function RaceManager:removePlayer(player: Player)
	local index = table.find(self.players, player)
	if not index then
		warn(`{player} is not in race`)
		return
	end

	player:RemoveTag(Constants.PLAYER_IN_RACE_TAG)
	table.remove(self.players, index)
end

function RaceManager:updatePlayers()
	local maxPlayers = self.raceContainer:GetAttribute(Constants.MAX_PLAYERS_ATTRIBUTE)
	-- Get all players inside the starting area who are driving a car
	local driversInStartingArea = getDriversInPart(self.startingArea)
	-- Remove players who have left the starting area
	-- Loop backwards through the table to avoid skipping over items whenever one is removed
	for i = #self.players, 1, -1 do
		local player = self.players[i]
		if not table.find(driversInStartingArea, player) then
			self:removePlayer(player)
		end
	end

	-- Add any new players who have entered the starting area
	for _, player in driversInStartingArea do
		if table.find(self.players, player) then
			continue
		end
		if #self.players == maxPlayers then
			break
		end
		self:addPlayer(player)
	end

	self:updateGui()
end

function RaceManager:onHeartbeat(_deltaTime: number)
	local elapsed = os.clock() - self.lastUpdate
	if elapsed < 1 / UPDATE_RATE then
		return
	end
	if self.raceContainer:GetAttribute(Constants.MANAGER_STATE_ATTRIBUTE) == ManagerState.Racing then
		return
	end

	self.lastUpdate = os.clock()
	self:updatePlayers()
end

function RaceManager:initialize()
	self.raceContainer:SetAttribute(Constants.MANAGER_STATE_ATTRIBUTE, ManagerState.Waiting)

	table.insert(
		self.connections,
		RunService.Heartbeat:Connect(function(deltaTime: number)
			self:onHeartbeat(deltaTime)
		end)
	)
	table.insert(
		self.connections,
		self.raceContainer:GetAttributeChangedSignal(Constants.MANAGER_STATE_ATTRIBUTE):Connect(function()
			self:updateGui()
		end)
	)
	table.insert(
		self.connections,
		self.raceContainer:GetAttributeChangedSignal(Constants.START_DELAY_COUNTDOWN_ATTRIBUTE):Connect(function()
			self:updateGui()
		end)
	)

	self:updateGui()
end

return RaceManager
