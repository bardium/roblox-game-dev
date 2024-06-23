local Players = game:GetService("Players")

-- Runs a callback for players who join as well as any who are already in the experience
local function safePlayerAdded(callback: (Player) -> ())
	for _, player in Players:GetPlayers() do
		task.spawn(callback, player)
	end
	return Players.PlayerAdded:Connect(callback)
end

return safePlayerAdded
