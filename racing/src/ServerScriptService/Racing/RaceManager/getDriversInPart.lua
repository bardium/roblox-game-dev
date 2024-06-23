local Players = game:GetService("Players")

local function isInBounds(point: Vector3, boundsCframe: CFrame, boundsSize: Vector3): boolean
	local offset = boundsCframe:PointToObjectSpace(point)
	return math.abs(offset.X) <= boundsSize.X / 2
		and math.abs(offset.Y) <= boundsSize.Y / 2
		and math.abs(offset.Z) <= boundsSize.Z / 2
end

-- Return all the players inside a specified part who are currently sitting in a VehicleSeat
local function getDriversInPart(part: BasePart): { Player }
	local drivers = {}

	for _, player in Players:GetPlayers() do
		local character = player.Character
		if not (player.Character and player.Character.PrimaryPart) then
			continue
		end

		if isInBounds(player.Character.PrimaryPart.Position, part.CFrame, part.Size) then
			local humanoid = character:FindFirstChildOfClass("Humanoid")
			if not humanoid then
				continue
			end
			if humanoid.SeatPart and humanoid.SeatPart:IsA("VehicleSeat") then
				table.insert(drivers, player)
			end
		end
	end

	return drivers
end

return getDriversInPart
