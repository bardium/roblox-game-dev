local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local carTemplate = ReplicatedStorage.Car

local CarConstants = require(carTemplate.Scripts.Constants)
local randomColor = require(script.Parent.randomColor)
local recolorModel = require(script.Parent.recolorModel)
local getOwnerTag = require(script.Parent.getOwnerTag)

-- Spawn a car at the specified location, setting its ownership if required
local function spawnCar(location: CFrame, owner: Player?)
	local car = carTemplate:Clone()
	car:PivotTo(location)

	-- Randomly color the car
	local color = randomColor()
	recolorModel(car, color)

	-- Set the car's owner
	if owner then
		local ownerTag = getOwnerTag(owner)
		car:AddTag(ownerTag)
		-- Since instance references can't be stored in attributes, the car owner is stored by UserId
		car:SetAttribute(CarConstants.CAR_OWNER_ATTRIBUTE, owner.UserId)
	end

	car.Parent = Workspace
end

return spawnCar
