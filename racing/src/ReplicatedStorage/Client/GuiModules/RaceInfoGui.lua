local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Constants = require(ReplicatedStorage.Constants)
local disconnectAndClear = require(ReplicatedStorage.Utility.disconnectAndClear)
local formatTime = require(ReplicatedStorage.Utility.formatTime)

local player = Players.LocalPlayer
local playerGui = player.PlayerGui
-- RaceGui gets automatically cloned from StarterGui and may not be fully replicated when this script runs.
-- Use WaitForChild to wait for the necessary instances to replicate.
local raceGui = playerGui:WaitForChild("RaceGui")
local raceInfoFrame = raceGui:WaitForChild("RaceInfoFrame")
local lapsLabel = raceInfoFrame:WaitForChild("Laps"):WaitForChild("LapsLabel")
local timersFrame = raceInfoFrame:WaitForChild("Timers")
local bestLabel = timersFrame:WaitForChild("BestLabel")
local lapLabel = timersFrame:WaitForChild("LapLabel")
local totalLabel = timersFrame:WaitForChild("TotalLabel")

local enabled = false
local connections = {}
local numberOfLaps = 0
local raceStarted = false
local totalTime = 0
local lapTime = 0

-- Update the best lap time label whenever the player's best lap time changes
local function onBestLapTimeChanged()
	local bestLapTime = player:GetAttribute(Constants.PLAYER_BEST_LAP_TIME_ATTRIBUTE)

	if bestLapTime then
		bestLabel.Text = `BEST - {formatTime(bestLapTime)}`
	else
		bestLabel.Text = "BEST - --:--.--"
	end
end

-- When the player's lap changes, reset lapTime and update the number of laps label
local function onLapChanged()
	lapTime = 0
	local playerLap = player:GetAttribute(Constants.PLAYER_LAP_ATTRIBUTE)
	lapsLabel.Text = `{playerLap}/{numberOfLaps}`
end

-- Update the timers and timer labels
local function onHeartbeat(deltaTime: number)
	if raceStarted then
		totalTime += deltaTime
		lapTime += deltaTime
	end

	lapLabel.Text = `LAP - {formatTime(lapTime)}`
	totalLabel.Text = `TOTAL - {formatTime(totalTime)}`
end

local RaceInfoGui = {}

function RaceInfoGui.raceStarted()
	raceStarted = true
end

function RaceInfoGui.enable(raceContainer: Model)
	if enabled then
		return
	end

	enabled = true
	numberOfLaps = raceContainer:GetAttribute(Constants.NUMBER_OF_LAPS_ATTRIBUTE)
	-- Start with the timers reset and disabled
	raceStarted = false
	totalTime = 0
	lapTime = 0

	table.insert(
		connections,
		player:GetAttributeChangedSignal(Constants.PLAYER_BEST_LAP_TIME_ATTRIBUTE):Connect(onBestLapTimeChanged)
	)
	table.insert(connections, player:GetAttributeChangedSignal(Constants.PLAYER_LAP_ATTRIBUTE):Connect(onLapChanged))
	table.insert(connections, RunService.Heartbeat:Connect(onHeartbeat))

	onBestLapTimeChanged()
	onLapChanged()

	raceInfoFrame.Visible = true
end

function RaceInfoGui.disable()
	if not enabled then
		return
	end

	enabled = false

	disconnectAndClear(connections)

	raceInfoFrame.Visible = false
end

return RaceInfoGui
