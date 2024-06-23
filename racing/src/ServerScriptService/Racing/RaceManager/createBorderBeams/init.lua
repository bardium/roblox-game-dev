local createAttachment = require(script.createAttachment)
local createBeam = require(script.createBeam)

local function createBorderBeams(startingArea: BasePart): { Beam }
	local frontRightAttachment = createAttachment(startingArea, Vector3.new(0.5, 0, -0.5))
	local frontLeftAttachment = createAttachment(startingArea, Vector3.new(-0.5, 0, -0.5))
	local backRightAttachment = createAttachment(startingArea, Vector3.new(0.5, 0, 0.5))
	local backLeftAttachment = createAttachment(startingArea, Vector3.new(-0.5, 0, 0.5))

	local beamA = createBeam(frontRightAttachment, frontLeftAttachment)
	local beamB = createBeam(frontLeftAttachment, backLeftAttachment)
	local beamC = createBeam(backLeftAttachment, backRightAttachment)
	local beamD = createBeam(backRightAttachment, frontRightAttachment)

	local beams = { beamA, beamB, beamC, beamD }

	return beams
end

return createBorderBeams
