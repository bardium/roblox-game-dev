local ReplicatedStorage = game:GetService("ReplicatedStorage")

local BlasterController = require(ReplicatedStorage.Blaster.Scripts.BlasterController)
local bindToInstanceDestroyed = require(ReplicatedStorage.Utility.bindToInstanceDestroyed)

local blaster = script.Parent.Parent

-- To easily share code between blasters, the main controller code is stored in a single ModuleScript.
-- We'll initialize a new controller tied to this tool.
local controller = BlasterController.new(blaster)

-- When this tool is destroyed, we'll clean up the controller that we created.
bindToInstanceDestroyed(blaster, function()
	controller:destroy()
end)
