local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Constants = require(ReplicatedStorage.Constants)
local disconnectAndClear = require(ReplicatedStorage.Utility.disconnectAndClear)
local formatTime = require(ReplicatedStorage.Utility.formatTime)

local player = Players.LocalPlayer
local playerGui = player.PlayerGui
-- RaceGui gets automatically cloned from StarterGui and may not be fully replicated when this script runs.
-- Use WaitForChild to wait for the necessary instances to replicate.
local raceGui = playerGui:WaitForChild("RaceGui")
local leaderboardFrame = raceGui:WaitForChild("LeaderboardFrame")
local playerListFrame = leaderboardFrame:WaitForChild("PlayerListFrame")
local closeButton = leaderboardFrame:WaitForChild("CloseButton")
local playerFrameTemplate = script.PlayerFrame

local enabled = false
local connections = {}

-- Remove all player frames from the leaderboard UI
local function clearPlayerEntries()
	for _, v in playerListFrame:GetChildren() do
		-- There are UI layout instances and a header inside playerListFrame, which we need to make sure not to delete
		if v.Name == playerFrameTemplate.Name then
			v:Destroy()
		end
	end
end

-- Add a new entry to the leaderboard UI
local function addPlayerEntry(leaderboardValue: ObjectValue)
	local entryPlayer = leaderboardValue.Value
	local bestLapTime = leaderboardValue:GetAttribute(Constants.PLAYER_BEST_LAP_TIME_ATTRIBUTE)
	local totalTime = leaderboardValue:GetAttribute(Constants.PLAYER_TOTAL_TIME_ATTRIBUTE)
	local place = leaderboardValue:GetAttribute(Constants.PLAYER_PLACE_ATTRIBUTE)

	local playerFrame = playerFrameTemplate:Clone()
	playerFrame.LayoutOrder = place
	playerFrame.NameLabel.Text = entryPlayer.DisplayName
	playerFrame.PlaceLabel.Text = tostring(place)
	playerFrame.BestLabel.Text = formatTime(bestLapTime)
	playerFrame.TimeLabel.Text = formatTime(totalTime)
	playerFrame.Parent = playerListFrame
end

local LeaderboardGui = {}

function LeaderboardGui.enable(raceContainer: Model)
	if enabled then
		return
	end

	enabled = true

	local leaderboard = raceContainer:FindFirstChild("Leaderboard")
	assert(leaderboard, `No Leaderboard in {raceContainer:GetFullName()}`)

	-- Add entries to the UI whenever they are added to the leaderboard
	table.insert(connections, leaderboard.ChildAdded:Connect(addPlayerEntry))
	table.insert(connections, closeButton.Activated:Connect(LeaderboardGui.disable))

	-- Add any entries that already exist
	for _, leaderboardValue in leaderboard:GetChildren() do
		addPlayerEntry(leaderboardValue)
	end

	leaderboardFrame.Visible = true
end

function LeaderboardGui.disable()
	if not enabled then
		return
	end

	enabled = false

	-- Clear any entries from the leaderboard
	clearPlayerEntries()
	disconnectAndClear(connections)

	leaderboardFrame.Visible = false
end

return LeaderboardGui
