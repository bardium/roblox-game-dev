local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Constants = require(ReplicatedStorage.Constants)
local CheckpointFlags = require(script.Parent.CheckpointFlags)
local CheckpointGui = require(script.Parent.GuiModules.CheckpointGui)
local RaceInfoGui = require(script.Parent.GuiModules.RaceInfoGui)
local LeaderboardGui = require(script.Parent.GuiModules.LeaderboardGui)

local player = Players.LocalPlayer
local playerGui = player.PlayerGui
-- RaceGui gets automatically cloned from StarterGui and may not be fully replicated when this script runs.
-- Use WaitForChild to wait for the necessary instances to replicate.
local raceGui = playerGui:WaitForChild("RaceGui")
local uiScale = raceGui:WaitForChild("UIScale")
local countdownLabel = raceGui:WaitForChild("CountdownLabel")
local finishFrame = raceGui:WaitForChild("FinishFrame")

local remotes = ReplicatedStorage.Remotes
local joinRaceRemote = remotes.JoinRace
local leaveRaceRemote = remotes.LeaveRace
local finishedRaceRemote = remotes.FinishedRace
local showCountdownRemote = remotes.ShowCountdown
local sounds = script.Sounds
local tickSound = sounds.TickSound
local startSound = sounds.StartSound
local finishSound = sounds.FinishSound
local checkpointSound = sounds.CheckpointSound

-- Pixel size under which a screen is considered 'small'. This is the same threshold used by the default touch UI.
local SMALL_SCREEN_THRESHOLD = 500
-- Amount to scale the UI when on a small screen
local SMALL_SCREEN_SCALE = 0.8

local checkpointPassedConnection = nil

local function showCountdown(countdown: number)
	task.spawn(function()
		countdownLabel.Visible = true

		-- Display the countdown
		for i = countdown, 1, -1 do
			tickSound:Play()
			countdownLabel.Text = tostring(i)
			task.wait(1)
		end

		-- Once the countdown finishes, enable the lap and total time timers
		RaceInfoGui.raceStarted()

		-- Time to GO!!!
		startSound:Play()
		countdownLabel.Text = "GO!!!"
		task.wait(1.5)
		countdownLabel.Visible = false
	end)
end

local function finishedRace(raceContainer: Model)
	-- When the race is finished, show the victory screen for a few seconds and then show the leaderboard
	task.spawn(function()
		finishSound:Play()
		finishFrame.Visible = true
		task.wait(3)
		finishFrame.Visible = false

		LeaderboardGui.enable(raceContainer)
	end)
end

local function joinRace(raceContainer: Model)
	-- Enable HUD elements when joining a race
	CheckpointFlags.enable(raceContainer)
	RaceInfoGui.enable(raceContainer)
	CheckpointGui.enable(raceContainer)

	-- Play the checkpoint passing sound whenever the current checkpoint changes
	checkpointPassedConnection = player
		:GetAttributeChangedSignal(Constants.PLAYER_CHECKPOINT_ATTRIBUTE)
		:Connect(function()
			checkpointSound:Play()
		end)
end

local function leaveRace()
	-- Disable HUD elements when leaving a race
	CheckpointFlags.disable()
	RaceInfoGui.disable()
	CheckpointGui.disable()

	if checkpointPassedConnection then
		checkpointPassedConnection:Disconnect()
		checkpointPassedConnection = nil
	end
end

local function updateScale()
	-- Update UI size. This is the same logic used by the default touch controls
	local minScreenSize = math.min(raceGui.AbsoluteSize.X, raceGui.AbsoluteSize.Y)
	local isSmallScreen = minScreenSize < SMALL_SCREEN_THRESHOLD
	uiScale.Scale = if isSmallScreen then SMALL_SCREEN_SCALE else 1
end

local function initialize()
	joinRaceRemote.OnClientEvent:Connect(joinRace)
	leaveRaceRemote.OnClientEvent:Connect(leaveRace)
	finishedRaceRemote.OnClientEvent:Connect(finishedRace)
	showCountdownRemote.OnClientEvent:Connect(showCountdown)
	raceGui:GetPropertyChangedSignal("AbsoluteSize"):Connect(updateScale)

	updateScale()
end

initialize()
