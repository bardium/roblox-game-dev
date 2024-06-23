local borderBeamTemplate = script.Parent.BorderBeam

-- Create a border beam between the specified attachments
local function createBeam(attachment0: Attachment, attachment1: Attachment): Beam
	local beam = borderBeamTemplate:Clone()
	beam.Attachment0 = attachment0
	beam.Attachment1 = attachment1
	beam.Parent = attachment0.Parent

	return beam
end

return createBeam
