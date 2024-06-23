local Workspace = game:GetService("Workspace")

local RAYCAST_PARAMETERS = RaycastParams.new()
RAYCAST_PARAMETERS.RespectCanCollide = true
RAYCAST_PARAMETERS.IgnoreWater = true

-- Amount that flags will face up vs being aligned to the surface normal
local VERTICAL_ALIGNMENT_PROPORTION = 0.7

-- Create a flag at the X offset relative to the checkpoint part's CFrame, raycasting to place it on the ground
local function createFlag(checkpoint: BasePart, template: Model, offsetProportion: number): Model
	-- Calculate the offset position
	local offset = Vector3.new(checkpoint.Size.X * offsetProportion, 0, 0)
	local position = checkpoint.CFrame:PointToWorldSpace(offset)
	-- Raycast down in the checkpoint's local space
	local direction = -checkpoint.CFrame.UpVector * checkpoint.Size.Y

	local result = Workspace:Raycast(position, direction, RAYCAST_PARAMETERS)
	local flag = template:Clone()

	if result then
		-- If the raycast hits something, place the flag at the hit position aligned with the surface normal
		local resultPosition = result.Position
		local resultNormal = result.Normal
		-- Create an up vector that is adjusted to face global up based on VERTICAL_ALIGNMENT_PROPORTION
		local up = (resultNormal:Lerp(Vector3.yAxis, VERTICAL_ALIGNMENT_PROPORTION)).Unit
		local forward = checkpoint.CFrame.LookVector
		local cframe = CFrame.lookAt(resultPosition, resultPosition + forward, up)

		flag:PivotTo(cframe)
	else
		-- The raycast didn't intersect with anything, so this edge of the checkpoint is not grounded.
		-- We'll just place our flag floating at the corner.
		local cframe = checkpoint.CFrame * CFrame.new(checkpoint.Size.X * offsetProportion, -checkpoint.Size.Y * 0.5, 0)

		flag:PivotTo(cframe)
	end

	return flag
end

return createFlag
