local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local Constants = require(script.Parent.Parent.Parent.Constants)
local getAverageWheelSlip = require(script.Parent.getAverageWheelSlip)
local getSuspensionLength = require(script.Parent.getSuspensionLength)
local playRandomSound = require(script.Parent.playRandomSound)

local car = script.Parent.Parent.Parent.Parent
local chassis = car.Chassis
local engine = car.Engine

local engineStartup = chassis.EngineStartupSound
local engineShutdown = chassis.EngineShutdownSound
local engineLoop = chassis.EngineLoopSound
local engineDistortion = engineLoop.DistortionSoundEffect
local tiresLoop = chassis.TiresLoopSound
local tiresSlidingLoop = chassis.TiresSlidingLoopSound
local nitroStart = chassis.NitroStartSound
local nitroStop = chassis.NitroStopSound
local nitroLoop = chassis.NitroLoopSound
local suspension = chassis.SuspensionSounds:GetChildren()
local collision = chassis.CollisionSounds:GetChildren()

local ENGINE_VOLUME = engineLoop.Volume -- Default engine volume
local ENGINE_VOLUME_STARTUP_TWEEN_TIME = 0.3 -- Time it takes for the engine loop to fade in
local ENGINE_PLAYBACK_SPEED = engineLoop.PlaybackSpeed -- Default engine playback speed
local ENGINE_PLAYBACK_SPEED_FACTOR = 1 / 80 -- Amount to adjust playback speed based on the car's speed
local ENGINE_DISTORTION_FACTOR = 1 / 200 -- Amount to adjust engine distortion based on the car's speed
local TIRES_VOLUME = tiresLoop.Volume -- Default tires volume
local TIRES_VOLUME_FACTOR = 1 / 100 -- Amount to adjust volume based on the speed of the car
local TIRES_SLIDING_VOLUME = tiresSlidingLoop.Volume -- Default tires sliding volume
local TIRES_SLIDING_VOLUME_FACTOR = 1 / 80 -- Amount to adjust volume based on the amount the car is sliding

local SUSPENSION_UPDATE_INTERVAL = 0.1 -- Time interval to calculate average change over
local SUSPENSION_THRESHOLD = 15 -- Amount of average change that must be passed to play a suspension sound
local SUSPENSION_VOLUME_FACTOR = 1 / 50 -- Amount to adjust volume based on the average change

local COLLISION_UPDATE_INTERVAL = 0.1 -- Time interval to calculate average change over
local COLLISION_THRESHOLD = 400 -- Amount of average change that must be passed to play a collision sound
local COLLISION_VOLUME_FACTOR = 1 / 800 -- Amount to adjust volume based on the average change

local engineRunning = false
local nitroEnabled = false

local totalSuspensionChange = 0
local lastSuspensionLength = getSuspensionLength()
local lastSuspensionUpdate = os.clock()

local totalSpeedChange = 0
local lastSpeed = chassis.AssemblyLinearVelocity.Magnitude
local lastCollisionUpdate = os.clock()

-- Play collision sounds when the speed of the car changes abruptly.
-- This is more consistent than listening to .Touched,
local function updateCollisionSounds()
	-- Calculate the change in the car's speed and add it to totalSpeedChange
	local speed = chassis.AssemblyLinearVelocity.Magnitude
	local change = math.abs(speed - lastSpeed)
	lastSpeed = speed
	totalSpeedChange += change

	local elapsed = os.clock() - lastCollisionUpdate
	if elapsed < COLLISION_UPDATE_INTERVAL then
		return
	end
	lastCollisionUpdate = os.clock()

	-- Calculate the average change in speed over the update interval
	local averageChangeOverInterval = totalSpeedChange / elapsed
	if averageChangeOverInterval > COLLISION_THRESHOLD then
		-- If the change is higher than the threshold, play a random collision sound
		local volume = averageChangeOverInterval * COLLISION_VOLUME_FACTOR
		playRandomSound(collision, chassis, volume)
	end

	totalSpeedChange = 0
end

-- Play suspension rattle sounds when the car's total suspension length changes abruptly.
-- To keep things simple, the car's suspension is treated as a single long spring.
local function updateSuspensionSounds()
	local suspensionLength = getSuspensionLength()
	local change = math.abs(suspensionLength - lastSuspensionLength)
	lastSuspensionLength = suspensionLength
	totalSuspensionChange += change

	local elapsed = os.clock() - lastSuspensionUpdate
	if elapsed < SUSPENSION_UPDATE_INTERVAL then
		return
	end
	lastSuspensionUpdate = os.clock()

	-- Calculate the average change in length over the update interval
	local averageChangeOverInterval = totalSuspensionChange / elapsed
	if averageChangeOverInterval > SUSPENSION_THRESHOLD then
		-- If the change is higher than the threshold, play a random suspension sound
		local volume = averageChangeOverInterval * SUSPENSION_VOLUME_FACTOR
		playRandomSound(suspension, chassis, volume)
	end

	totalSuspensionChange = 0
end

local function onHeartbeat(_deltaTime: number)
	local chassisVelocity = chassis.AssemblyLinearVelocity
	local localChassisVelocity = chassis.CFrame:VectorToObjectSpace(chassisVelocity)
	local forwardSpeed = math.abs(localChassisVelocity.Z)
	local actualEngineSpeed = engine:GetAttribute(Constants.ENGINE_SPEED_ATTRIBUTE)

	-- Adjust the engine playback speed/pitch and distortion based on the speed of the car.
	-- Use the max of either the car's target speed or its actual speed so that the engine still revs
	-- up in situations where it's not moving but the wheels are spinning.
	local engineSpeed = math.max(forwardSpeed, actualEngineSpeed)
	local enginePlaybackSpeed = ENGINE_PLAYBACK_SPEED + engineSpeed * ENGINE_PLAYBACK_SPEED_FACTOR
	local engineDistortionLevel = engineSpeed * ENGINE_DISTORTION_FACTOR
	engineLoop.PlaybackSpeed = enginePlaybackSpeed
	engineDistortion.Level = engineDistortionLevel

	-- Adjust the tire driving volume based on the speed of the car
	local tiresVolume = TIRES_VOLUME * forwardSpeed * TIRES_VOLUME_FACTOR
	tiresLoop.Volume = tiresVolume

	-- Adjust the tire sliding volume based on the average wheel slippage
	local averageWheelSlip = getAverageWheelSlip()
	local tiresSlidingVolume = TIRES_SLIDING_VOLUME * averageWheelSlip * TIRES_SLIDING_VOLUME_FACTOR
	tiresSlidingLoop.Volume = tiresSlidingVolume

	-- Play suspension bumping and collision sounds
	updateSuspensionSounds()
	updateCollisionSounds()
end

local Audio = {}

function Audio.startNitro()
	if nitroEnabled then
		return
	end

	nitroEnabled = true

	nitroStart:Play()
	nitroLoop:Play()
end

function Audio.stopNitro()
	if not nitroEnabled then
		return
	end

	nitroEnabled = false

	nitroStop:Play()
	nitroLoop:Stop()
end

function Audio.startupEngine()
	if engineRunning then
		return
	end

	engineRunning = true

	engineStartup:Play()

	engineLoop.Volume = 0
	engineLoop:Play()

	-- Tween in the engine loop volume, since the startup sound is not instant
	local tweenInfo = TweenInfo.new(ENGINE_VOLUME_STARTUP_TWEEN_TIME, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
	local tween = TweenService:Create(engineLoop, tweenInfo, { Volume = ENGINE_VOLUME })
	tween:Play()
end

function Audio.shutdownEngine()
	if not engineRunning then
		return
	end

	engineRunning = false

	engineShutdown:Play()
	engineLoop:Stop()
end

function Audio.initialize()
	-- The tire driving and sliding loops should always be playing
	tiresLoop.Volume = 0
	tiresSlidingLoop.Volume = 0
	tiresLoop:Play()
	tiresSlidingLoop:Play()

	RunService.Heartbeat:Connect(onHeartbeat)
end

Audio.initialize()

return Audio
