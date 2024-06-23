local Constants = require(script.Parent.Parent.Constants)
local Audio = require(script.Audio)
local Particles = require(script.Particles)

local car = script.Parent.Parent.Parent
local driverSeat = car.DriverSeat
local engine = car.Engine

local function onOccupantChanged()
	if driverSeat.Occupant then
		Audio.startupEngine()
	else
		Audio.shutdownEngine()
	end
end

local function onNitroEnabledChanged()
	local isNitroEnabled = engine:GetAttribute(Constants.NITRO_ENABLED_ATTRIBUTE)
	if isNitroEnabled then
		Audio.startNitro()
		Particles.startNitro()
	else
		Audio.stopNitro()
		Particles.stopNitro()
	end
end

local function initialize()
	driverSeat:GetPropertyChangedSignal("Occupant"):Connect(onOccupantChanged)
	engine:GetAttributeChangedSignal(Constants.NITRO_ENABLED_ATTRIBUTE):Connect(onNitroEnabledChanged)

	onOccupantChanged()
	onNitroEnabledChanged()
end

initialize()
