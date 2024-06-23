local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local Constants = require(ReplicatedStorage.Constants)
local disconnectAndClear = require(ReplicatedStorage.Utility.disconnectAndClear)
local getCheckpoints = require(ReplicatedStorage.Utility.getCheckpoints)

local camera = Workspace.CurrentCamera
local player = Players.LocalPlayer
local playerGui = player.PlayerGui
-- RaceGui gets automatically cloned from StarterGui and may not be fully replicated when this script runs.
-- Use WaitForChild to wait for the necessary instances to replicate.
local raceGui = playerGui:WaitForChild("RaceGui")
local checkpointFrame = raceGui:WaitForChild("CheckpointFrame")
local textLabel = checkpointFrame:WaitForChild("TextLabel")

local CLAMP_DISTANCE = 0.45
local CLAMP_DISABLE_DISTANCE = 100

local enabled = false
local connections = {}
local checkpoints = {}
local target = nil
local numberOfLaps = 0

local function onRenderStepped(_deltaTime: number)
	if not target then
		return
	end

	-- Get the screen position of the target checkpoint
	local targetOffset = Vector3.new(0, target.Size.Y * 0.5, 0)
	local targetPosition = target.CFrame:PointToWorldSpace(targetOffset)
	local screenPosition = camera:WorldToScreenPoint(targetPosition)
	local screenPositionScale = Vector2.new(screenPosition.X, screenPosition.Y) / raceGui.AbsoluteSize
	local position = screenPositionScale - Vector2.new(0.5, 0.5)
	local depth = screenPosition.Z

	-- If the checkpoint is behind the camera, its screen position needs to be inverted and moved to the edge of the screen
	if depth < 0 then
		-- In the case where the checkpoint is directly behind the camera, (i.e. position = 0, 0) normalizing will result in NAN, NAN
		-- To avoid this, if the position is equal to 0, 0 we'll change it before normalizing
		if position == Vector2.zero then
			position = Vector2.new(0, 0.5)
		end
		position = -position.Unit
	end

	-- Clamp the position so it stays inside a more circular radius rather than clamping onto the edges of the screen
	local clampedPosition = position
	if clampedPosition.Magnitude > CLAMP_DISTANCE then
		clampedPosition = clampedPosition.Unit * CLAMP_DISTANCE
	end

	-- As we get closer to the checkpoint position, lower the amount of clamping done so that it does not get stuck in
	-- a weird position as the player drives past
	local targetDistance = (camera.CFrame.Position - targetPosition).Magnitude
	if targetDistance < CLAMP_DISABLE_DISTANCE then
		local alpha = targetDistance / CLAMP_DISABLE_DISTANCE
		alpha = alpha ^ (1 / 3)
		position = position:Lerp(clampedPosition, alpha)
	else
		position = clampedPosition
	end

	checkpointFrame.Position = UDim2.fromScale(0.5 + position.X, 0.5 + position.Y)
end

-- Pick the next checkpoint to target based on the player's current checkpoint
local function updateTarget()
	local playerLap = player:GetAttribute(Constants.PLAYER_LAP_ATTRIBUTE)
	local playerCheckpoint = player:GetAttribute(Constants.PLAYER_CHECKPOINT_ATTRIBUTE)
	local targetCheckpoint = playerCheckpoint + 1
	if targetCheckpoint > #checkpoints then
		targetCheckpoint -= #checkpoints
	end

	target = checkpoints[targetCheckpoint]

	if playerLap == numberOfLaps and targetCheckpoint == #checkpoints then
		textLabel.Text = "FINISH"
	else
		textLabel.Text = "CHECKPOINT"
	end
end

local CheckpointGui = {}

function CheckpointGui.enable(raceContainer: Model)
	if enabled then
		return
	end

	enabled = true

	checkpoints = getCheckpoints(raceContainer)
	numberOfLaps = raceContainer:GetAttribute(Constants.NUMBER_OF_LAPS_ATTRIBUTE)

	table.insert(
		connections,
		player:GetAttributeChangedSignal(Constants.PLAYER_CHECKPOINT_ATTRIBUTE):Connect(updateTarget)
	)
	table.insert(connections, RunService.RenderStepped:Connect(onRenderStepped))

	updateTarget()

	checkpointFrame.Visible = true
end

function CheckpointGui.disable()
	if not enabled then
		return
	end

	enabled = false

	disconnectAndClear(connections)

	checkpointFrame.Visible = false
end

return CheckpointGui
