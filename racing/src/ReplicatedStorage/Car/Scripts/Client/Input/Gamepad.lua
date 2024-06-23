local ContextActionService = game:GetService("ContextActionService")
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")

local Constants = require(script.Parent.Parent.Parent.Constants)
local cycleCameraModeHandler = require(script.Parent.cycleCameraModeHandler)
local exitHandlerAsync = require(script.Parent.exitHandlerAsync)
local nitroHandler = require(script.Parent.nitroHandler)
local handBrakeHandler = require(script.Parent.handBrakeHandler)

local player = Players.LocalPlayer
local playerGui = player.PlayerGui
local controlsGuiTemplate = script.Parent.ControlsGui
local car = script.Parent.Parent.Parent.Parent
local inputs = car.Inputs

local LEFT_THUMBSTICK = Enum.KeyCode.Thumbstick1
local RIGHT_TRIGGER = Enum.KeyCode.ButtonR2
local LEFT_TRIGGER = Enum.KeyCode.ButtonL2
local STEERING_DEADZONE = 0.1

local currentGamepad = Enum.UserInputType.Gamepad1
local enabled = false
local lastInputTypeChangedConnection = nil
local controlsGui = nil

local function onLastInputTypeChanged(inputType: Enum.UserInputType)
	if string.find(inputType.Name, "Gamepad") then
		currentGamepad = inputType
	end
end

local Gamepad = {}

function Gamepad:getThrottleAndSteering(): (number, number)
	local throttle = 0
	local steering = 0
	local gamepadState = UserInputService:GetGamepadState(currentGamepad)

	for _, inputObject in gamepadState do
		if inputObject.KeyCode == LEFT_THUMBSTICK then
			local position = inputObject.Position.X
			if math.abs(position) > STEERING_DEADZONE then
				-- Apply deadzone
				steering = ((math.abs(position) - STEERING_DEADZONE) / (1 - STEERING_DEADZONE)) * math.sign(position)
			end
		elseif inputObject.KeyCode == RIGHT_TRIGGER then
			throttle += inputObject.Position.Z
		elseif inputObject.KeyCode == LEFT_TRIGGER then
			throttle -= inputObject.Position.Z
		end
	end

	return throttle, steering
end

function Gamepad:enable()
	if enabled then
		return
	end
	enabled = true

	local cycleCameraModeKeyCode = inputs:GetAttribute(Constants.GAMEPAD_CYCLE_CAMERA_MODE_KEY_CODE_ATTRIBUTE)
	local exitKeyCode = inputs:GetAttribute(Constants.GAMEPAD_EXIT_KEY_CODE_ATTRIBUTE)
	local nitroKeyCode = inputs:GetAttribute(Constants.GAMEPAD_NITRO_KEY_CODE_ATTRIBUTE)
	local handBrakeKeyCode = inputs:GetAttribute(Constants.GAMEPAD_HAND_BRAKE_KEY_CODE_ATTRIBUTE)

	controlsGui = controlsGuiTemplate:Clone()
	controlsGui.Parent = playerGui

	-- Get the gamepad button images to display on the controls UI. UserInputService:GetImageForKeycode() returns
	-- platform-specific icons to support various platforms.
	local cycleCameraModeImage = UserInputService:GetImageForKeyCode(cycleCameraModeKeyCode)
	local exitImage = UserInputService:GetImageForKeyCode(exitKeyCode)
	local nitroImage = UserInputService:GetImageForKeyCode(nitroKeyCode)
	local handBrakeImage = UserInputService:GetImageForKeyCode(handBrakeKeyCode)

	-- Display the gamepad bindings for the car's controls
	controlsGui.Controls.CameraFrame.GamepadLabel.Image = cycleCameraModeImage
	controlsGui.Controls.ExitFrame.GamepadLabel.Image = exitImage
	controlsGui.Controls.NitroFrame.GamepadLabel.Image = nitroImage
	controlsGui.Controls.HandBrakeFrame.GamepadLabel.Image = handBrakeImage
	controlsGui.Controls.CameraFrame.GamepadLabel.Visible = true
	controlsGui.Controls.ExitFrame.GamepadLabel.Visible = true
	controlsGui.Controls.NitroFrame.GamepadLabel.Visible = true
	controlsGui.Controls.HandBrakeFrame.GamepadLabel.Visible = true

	ContextActionService:BindAction(
		Constants.GAMEPAD_CYCLE_CAMERA_MODE_BIND_NAME,
		cycleCameraModeHandler,
		false,
		cycleCameraModeKeyCode
	)
	ContextActionService:BindAction(Constants.GAMEPAD_EXIT_BIND_NAME, exitHandlerAsync, false, exitKeyCode)
	ContextActionService:BindAction(Constants.GAMEPAD_NITRO_BIND_NAME, nitroHandler, false, nitroKeyCode)
	ContextActionService:BindAction(Constants.GAMEPAD_HAND_BRAKE_BIND_NAME, handBrakeHandler, false, handBrakeKeyCode)

	-- We listen to LastInputTypeChanged so we can specifically check which was the last gamepad being used.
	-- Simply calling GetLastInputType in getThrottleAndSteering would potentially return non-gamepad InputTypes.
	lastInputTypeChangedConnection = UserInputService.LastInputTypeChanged:Connect(onLastInputTypeChanged)

	local lastInputType = UserInputService:GetLastInputType()
	onLastInputTypeChanged(lastInputType)
end

function Gamepad:disable()
	if not enabled then
		return
	end
	enabled = false

	ContextActionService:UnbindAction(Constants.GAMEPAD_CYCLE_CAMERA_MODE_BIND_NAME)
	ContextActionService:UnbindAction(Constants.GAMEPAD_EXIT_BIND_NAME)
	ContextActionService:UnbindAction(Constants.GAMEPAD_NITRO_BIND_NAME)
	ContextActionService:UnbindAction(Constants.GAMEPAD_HAND_BRAKE_BIND_NAME)

	if lastInputTypeChangedConnection then
		lastInputTypeChangedConnection:Disconnect()
		lastInputTypeChangedConnection = nil
	end

	if controlsGui then
		controlsGui:Destroy()
		controlsGui = nil
	end
end

return Gamepad
