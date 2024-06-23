local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local Constants = require(ReplicatedStorage.Constants)
local setModelVisible = require(script.setModelVisible)
local createCheckpointFlags = require(script.createCheckpointFlags)

local MAX_CHECKPOINTS_VISIBLE = 3

local player = Players.LocalPlayer

local enabled = false
local checkpointChangedConnection = nil
local checkpointFlags = {}
local finishFlags = nil
local numberOfLaps = 0

-- Update the visibility of the checkpoint flags
local function updateCheckpointFlagsVisibility()
	local playerLap = player:GetAttribute(Constants.PLAYER_LAP_ATTRIBUTE)
	local isFinalLap = playerLap == numberOfLaps
	local playerCheckpoint = player:GetAttribute(Constants.PLAYER_CHECKPOINT_ATTRIBUTE)

	-- If the player isn't on the final lap, there's no need for the finish flags
	if not isFinalLap then
		setModelVisible(finishFlags, false)
	end

	for checkpoint, flags in checkpointFlags do
		local distance = checkpoint - playerCheckpoint

		if isFinalLap then
			-- Special case for the final lap, since we don't want to show flags past the finish line
			-- Make sure the flags are in front of the player (but not too far)
			if distance > 0 and distance <= MAX_CHECKPOINTS_VISIBLE then
				-- If it's the final checkpoint, show the finish flags instead of the checkpoint flags
				if checkpoint == #checkpointFlags then
					setModelVisible(finishFlags, true)
					setModelVisible(flags, false)
				else
					setModelVisible(flags, true)
				end
			else
				setModelVisible(flags, false)
			end
		else
			-- Checkpoints are ordered 1, 2, ..., n
			-- When going from checkpoint n - MAX_CHECKPOINTS_VISIBLE to checkpoint 1, distance will be negative.
			-- This will cause future checkpoints to be invisible as the player finishes each lap.
			-- The modulo operator can be used to have distance 'wrap around'
			distance = distance % #checkpointFlags
			local isVisible = distance > 0 and distance <= MAX_CHECKPOINTS_VISIBLE

			setModelVisible(flags, isVisible)
		end
	end
end

local CheckpointFlags = {}

function CheckpointFlags.enable(raceContainer: Model)
	if enabled then
		return
	end

	enabled = true

	-- Create new checkpoint and finish flags for the race
	checkpointFlags, finishFlags = createCheckpointFlags(raceContainer)
	numberOfLaps = raceContainer:GetAttribute(Constants.NUMBER_OF_LAPS_ATTRIBUTE)

	checkpointChangedConnection =
		player:GetAttributeChangedSignal(Constants.PLAYER_CHECKPOINT_ATTRIBUTE):Connect(updateCheckpointFlagsVisibility)

	updateCheckpointFlagsVisibility()
end

function CheckpointFlags.disable()
	if not enabled then
		return
	end

	enabled = false

	if checkpointChangedConnection then
		checkpointChangedConnection:Disconnect()
		checkpointChangedConnection = nil
	end

	-- Destroy all the checkpoint flags
	for _, flags in checkpointFlags do
		flags:Destroy()
	end
	table.clear(checkpointFlags)

	-- Destroy the finish flags
	if finishFlags then
		finishFlags:Destroy()
		finishFlags = nil
	end
end

return CheckpointFlags
