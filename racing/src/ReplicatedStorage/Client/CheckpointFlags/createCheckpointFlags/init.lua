local ReplicatedStorage = game:GetService("ReplicatedStorage")

local getCheckpoints = require(ReplicatedStorage.Utility.getCheckpoints)
local createFlag = require(script.createFlag)

local checkpointFlagTemplate = script.CheckpointFlag
local finishFlagTemplate = script.FinishFlag

local function createFlagPair(checkpoint: BasePart, template: Model): Model
	local flags = Instance.new("Model")

	-- Create a flag with an offset proportion of 0.5. Since the offset is based on the X size of the part,
	-- 0.5 places the flag directly on the edge of the checkpoint part.
	local rightFlag = createFlag(checkpoint, template, 0.5)
	rightFlag.Parent = flags

	-- Create a flag on the opposite side.
	local leftFlag = createFlag(checkpoint, template, -0.5)
	leftFlag.Parent = flags

	return flags
end

-- Create and return checkpoint and finish flags for a race
local function createCheckpointFlags(raceContainer: Model): ({ Model }, Model)
	local checkpoints = getCheckpoints(raceContainer)
	local orderedCheckpointFlags = {}

	-- Create checkpoint flags for each checkpoint. These are inserted into a table in order so they can be
	-- easily iterated over later when toggling their visibility.
	for _, checkpoint in checkpoints do
		local flags = createFlagPair(checkpoint, checkpointFlagTemplate)
		flags.Name = "CheckpointFlags"
		flags.Parent = checkpoint

		table.insert(orderedCheckpointFlags, flags)
	end

	-- Create finish flags on the last checkpoint
	local lastCheckpoint = checkpoints[#checkpoints]
	local finishFlags = createFlagPair(lastCheckpoint, finishFlagTemplate)
	finishFlags.Name = "FinishFlags"
	finishFlags.Parent = lastCheckpoint

	return orderedCheckpointFlags, finishFlags
end

return createCheckpointFlags
