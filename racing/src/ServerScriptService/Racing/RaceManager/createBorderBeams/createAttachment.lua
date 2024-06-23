local Workspace = game:GetService("Workspace")

local RAYCAST_PARAMETERS = RaycastParams.new()
RAYCAST_PARAMETERS.IgnoreWater = true
RAYCAST_PARAMETERS.RespectCanCollide = true

local HEIGHT_OFFSET = 2

-- Create an attachment at the specified offset, raycasting down to place it above the ground
local function createAttachment(part: BasePart, offset: Vector3): Attachment
	local origin = part.CFrame:PointToWorldSpace(part.Size * offset)
	local direction = -part.CFrame.UpVector * part.Size.Y * 0.5
	local result = Workspace:Raycast(origin, direction, RAYCAST_PARAMETERS)

	local position = origin + direction
	if result then
		position = result.Position
	end

	local localPosition = part.CFrame:PointToObjectSpace(position)
	local attachment = Instance.new("Attachment")
	attachment.Position = localPosition + Vector3.new(0, HEIGHT_OFFSET, 0)
	attachment.Parent = part

	return attachment
end

return createAttachment
