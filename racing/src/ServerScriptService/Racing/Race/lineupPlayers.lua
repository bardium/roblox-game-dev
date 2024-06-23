local function lineupPlayers(players: { Players }, lineupCFrame: CFrame, lineupWidth: number, lineupOffset: Vector3)
	for index, player in players do
		local character = player.Character
		if not character then
			continue
		end
		local humanoid = character:FindFirstChildOfClass("Humanoid")
		if not humanoid then
			continue
		end
		local seat = humanoid.SeatPart
		if not seat then
			continue
		end

		local offset = CFrame.new(0, 0, 0)
		if #players ~= 1 then
			local lineSize = math.min(lineupWidth, #players)
			local xIndex = (index - 1) % lineSize
			local xOffset = (xIndex / (lineSize - 1) - 0.5) * 2
			local zOffset = math.floor((index - 1) / lineSize)
			offset = CFrame.new(xOffset * lineupOffset.X, 0, zOffset * lineupOffset.Z)
		end
		-- This assumes the seat is parented within the car model but not nested within another model
		local car = seat:FindFirstAncestorWhichIsA("Model")
		car:PivotTo(lineupCFrame * offset)
	end
end

return lineupPlayers
