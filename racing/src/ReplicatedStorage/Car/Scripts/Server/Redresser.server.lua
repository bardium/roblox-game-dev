local car = script.Parent.Parent.Parent
local chassis = car.Chassis
local redress = car.Redress
local redressOrientation = redress.RedressOrientation

local FLIPPED_LIMIT = -0.5
local UPRIGHT_LIMIT = 0.7
local MOVING_LIMIT = 10

local redressParameters: { [string]: number } = {
	maxTimeFlipped = 2,
	redressMaxTorque = 500000,
	redressResponsiveness = 10,
}

local timeFlipped = 0

local function isFlipped(): boolean
	local chassisUp = chassis.CFrame.UpVector
	return chassisUp:Dot(Vector3.yAxis) < FLIPPED_LIMIT
end

local function isUpright(): boolean
	local chassisUp = chassis.CFrame.UpVector
	return chassisUp:Dot(Vector3.yAxis) > UPRIGHT_LIMIT
end

local function isMoving(): boolean
	return chassis.AssemblyLinearVelocity.Magnitude > MOVING_LIMIT
end

-- Enable the RedressOrientation constraint until the car has flipped upright
local function redressAsync()
	local forward = chassis.CFrame.LookVector
	local cframe = CFrame.lookAt(Vector3.zero, forward, Vector3.yAxis)
	redressOrientation.CFrame = cframe
	redressOrientation.Enabled = true
	repeat
		task.wait()
	until isUpright()
	redressOrientation.Enabled = false
end

local function initialize()
	-- Cache the attribute values in a table and update them when the attribute changes.
	-- Parameters aren't going to change very often so there's no reason to call :GetAttribute() constantly.
	for parameter in redressParameters do
		redress:GetAttributeChangedSignal(parameter):Connect(function()
			redressParameters[parameter] = redress:GetAttribute(parameter)
		end)

		redressParameters[parameter] = redress:GetAttribute(parameter)
	end

	task.spawn(function()
		while true do
			local deltaTime = task.wait(0.1)
			-- If the car is currently flipped, keep track of the amount of time it has been flipped
			if isFlipped() and not isMoving() then
				timeFlipped += deltaTime
			else
				timeFlipped = 0
			end
			-- Once the time flipped exceeds the limit, flip the car back over
			if timeFlipped >= redressParameters.maxTimeFlipped then
				timeFlipped = 0
				redressAsync()
			end
		end
	end)
end

initialize()
