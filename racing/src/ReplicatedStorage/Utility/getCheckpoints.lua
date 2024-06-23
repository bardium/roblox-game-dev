local function getCheckpoints(raceContainer: Model): { BasePart }
	local checkpointsFolder = raceContainer:FindFirstChild("Checkpoints")
	assert(checkpointsFolder, `No Checkpoints in {raceContainer:GetFullName()}`)

	-- Make sure all the checkpoints exist
	local checkpoints = {}
	local numCheckpoints = #checkpointsFolder:GetChildren()
	for i = 1, numCheckpoints do
		local checkpoint = checkpointsFolder:FindFirstChild(`Checkpoint{i}`)
		assert(checkpoint, `{raceContainer:GetFullName()} missing checkpoint: Checkpoint{i}`)
		table.insert(checkpoints, checkpoint)
	end

	return checkpoints
end

return getCheckpoints
