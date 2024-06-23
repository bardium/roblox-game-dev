local ALIGN_MAX_FORCE = 100_000
local ALIGN_RESPONSIVENESS = 100

local function holdPlayers(players: { Player }): { AlignPosition }
	local alignPositions = {}

	for _, player in players do
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

		local anchorAttachment = character.PrimaryPart:FindFirstChild("RaceLineupAttachment")
		if not anchorAttachment then
			anchorAttachment = Instance.new("Attachment")
			anchorAttachment.Name = "RaceLineupAttachment"
			anchorAttachment.Parent = seat
		end

		-- Use an AlignPosition to lock the car in place
		local alignPosition = script.RaceLineupAlignPosition:Clone()
		alignPosition.Attachment0 = anchorAttachment
		alignPosition.MaxAxesForce = Vector3.new(ALIGN_MAX_FORCE, 0, ALIGN_MAX_FORCE)
		alignPosition.Responsiveness = ALIGN_RESPONSIVENESS
		alignPosition.Position = seat.Position
		alignPosition.Parent = seat

		table.insert(alignPositions, alignPosition)
	end

	return alignPositions
end

return holdPlayers
