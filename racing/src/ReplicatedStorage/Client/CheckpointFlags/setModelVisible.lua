-- Set LocalTransparencyModifier on parts and toggle Enabled on SurfaceGuis based on whether the model should be visible or not.
-- LocalTransparencyModifier is used to avoid having to store the original Transparency values of parts.
local function setModelVisible(model: Model, visible: boolean)
	local localTransparencyModifier = if visible then 0 else 1

	for _, v in model:GetDescendants() do
		if v:IsA("BasePart") then
			v.LocalTransparencyModifier = localTransparencyModifier
		elseif v:IsA("SurfaceGui") then
			v.Enabled = visible
		end
	end
end

return setModelVisible
