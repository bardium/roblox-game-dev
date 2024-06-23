local function getLeaderboard(raceContainer: Model): Folder
	local leaderboardFolder = raceContainer:FindFirstChild("Leaderboard")
	if not leaderboardFolder then
		leaderboardFolder = Instance.new("Folder")
		leaderboardFolder.Name = "Leaderboard"
		leaderboardFolder.Parent = raceContainer
	end
	return leaderboardFolder
end

return getLeaderboard
