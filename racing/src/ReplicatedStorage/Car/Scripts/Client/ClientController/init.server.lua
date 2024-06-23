local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local Constants = require(script.Parent.Parent.Constants)
local Controller = require(script.Parent.Parent.Controller)
local Camera = require(script.Parent.Camera)
local Input = require(script.Parent.Input)
local Speedometer = require(script.Parent.Speedometer)
local setJumpingEnabled = require(script.setJumpingEnabled)
local disconnectAndClear = require(script.Parent.disconnectAndClear)

local destructionHandlerTemplate = script.DestructionHandler
local player = Players.LocalPlayer
local car = script.Parent.Parent.Parent
local driverSeat = car.DriverSeat
local engine = car.Engine
local remotes = car.Remotes
local setNitroEnabledRemote = remotes.SetNitroEnabled
local animations = car.Animations
local driveAnimation = animations.DriveAnimation

local isControlling = false
local connections = {}
local driveAnimationTrack = nil

-- Enable the client modules and Controller update loop
local function startControlling()
	if isControlling then
		return
	end
	isControlling = true

	-- Stop the player from jumping out the seat since a separate key is bound to exit the car.
	local character = player.Character
	if character then
		setJumpingEnabled(character, false)

		-- Play the driving animation
		local humanoid = character:FindFirstChildOfClass("Humanoid")
		if humanoid then
			local animator = humanoid:FindFirstChildOfClass("Animator")
			if animator then
				driveAnimationTrack = animator:LoadAnimation(driveAnimation)
				driveAnimationTrack:Play()
			end
		end
	end

	-- Connect the Controller's update function to RunService.Stepped.
	-- Stepped is used here since it fires prior to the physics simulation, and the controller
	-- updates the physics constraints on the car.
	table.insert(
		connections,
		RunService.Stepped:Connect(function(_, deltaTime: number)
			Controller:update(deltaTime)
		end)
	)

	-- Enable replication for the nitro audio and VFX
	table.insert(
		connections,
		engine:GetAttributeChangedSignal(Constants.NITRO_ENABLED_ATTRIBUTE):Connect(function()
			local isNitroEnabled = engine:GetAttribute(Constants.NITRO_ENABLED_ATTRIBUTE)
			setNitroEnabledRemote:FireServer(isNitroEnabled)
		end)
	)

	-- Enable the client modules
	Camera:enable()
	Input:enable()
	Speedometer:enable()
end

-- Disable the client modules and Controller update loop
local function stopControlling()
	if not isControlling then
		return
	end
	isControlling = false

	-- Disable the client modules
	Camera:disable()
	Input:disable()
	Speedometer:disable()

	-- Disconnect event connections
	disconnectAndClear(connections)

	-- Reset the car Controller. If the car has been destroyed (i.e. is not parented anywhere in the DataModel) this can be skipped.
	if car:IsDescendantOf(game) then
		Controller:reset()
	end

	-- Reenable jumping for the player
	local character = player.Character
	if character then
		setJumpingEnabled(character, true)
	end

	-- Stop the driving animation
	if driveAnimationTrack then
		driveAnimationTrack:Stop()
		driveAnimationTrack = nil
	end
end

-- Call startControlling() or stopControlling() if the player enters or exits the seat
local function onOccupantChanged()
	local isOccupiedByLocalPlayer = false

	local humanoid = driverSeat.Occupant
	if humanoid then
		local character = humanoid.Parent
		local playerInSeat = Players:GetPlayerFromCharacter(character)
		if playerInSeat == player then
			isOccupiedByLocalPlayer = true
		end
	end

	if isOccupiedByLocalPlayer then
		startControlling()
	else
		stopControlling()
	end
end

-- When using Deferred signal mode: since this script is parented to the car, destroying the car will clean up
-- all connections (including .Destroying) before they can actually execute.
-- To avoid this, we'll use a slightly hacky solution and clone a listener script into PlayerScripts.
-- This script will continue running after the car is destroyed and allow us to properly clean up when the car is destroyed.
local function setupDestructionHandler()
	local destructionHandler = destructionHandlerTemplate:Clone()
	destructionHandler.Parent = player.PlayerScripts
	destructionHandler.Enabled = true

	-- Defer firing the BindableEvent so the script is able to initialize first
	task.defer(function()
		destructionHandler.BindToCar:Fire(car, stopControlling)
	end)
end

setupDestructionHandler()
driverSeat:GetPropertyChangedSignal("Occupant"):Connect(onOccupantChanged)
