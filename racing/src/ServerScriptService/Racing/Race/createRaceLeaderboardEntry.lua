local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Constants = require(ReplicatedStorage.Constants)

local function createRaceLeaderboardEntry(
	player: Player,
	place: number,
	totalTime: number,
	bestLapTime: number
): ObjectValue
	local leaderboardEntry = Instance.new("ObjectValue")
	leaderboardEntry.Name = player.Name
	leaderboardEntry.Value = player
	leaderboardEntry:SetAttribute(Constants.PLAYER_PLACE_ATTRIBUTE, place)
	leaderboardEntry:SetAttribute(Constants.PLAYER_BEST_LAP_TIME_ATTRIBUTE, bestLapTime)
	leaderboardEntry:SetAttribute(Constants.PLAYER_TOTAL_TIME_ATTRIBUTE, totalTime)

	return leaderboardEntry
end

return createRaceLeaderboardEntry
