local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")

local Constants = require(ReplicatedStorage.Blaster.Constants)
local TouchInputController = require(script.Parent.TouchInputController)
local CameraRecoiler = require(script.Parent.CameraRecoiler)
local ViewModelController = require(script.Parent.ViewModelController)
local CharacterAnimationController = require(script.Parent.CharacterAnimationController)
local GuiController = require(script.Parent.GuiController)
local disconnectAndClear = require(ReplicatedStorage.Utility.disconnectAndClear)
local getRayDirections = require(script.Parent.Parent.Utility.getRayDirections)
local drawRayResults = require(script.Parent.Parent.Utility.drawRayResults)
local castRays = require(script.Parent.Parent.Utility.castRays)

local player = Players.LocalPlayer
local camera = Workspace.CurrentCamera
local remotes = ReplicatedStorage.Blaster.Remotes
local shootRemote = remotes.Shoot
local reloadRemote = remotes.Reload

local random = Random.new()

local BlasterController = {}
BlasterController.__index = BlasterController

function BlasterController.new(blaster: Tool)
	local viewModelController = ViewModelController.new(blaster)
	local guiController = GuiController.new(blaster)
	local touchInputController = TouchInputController.new(blaster)
	local characterAnimationController = CharacterAnimationController.new(blaster)

	local self = {
		blaster = blaster,
		viewModelController = viewModelController,
		guiController = guiController,
		touchInputController = touchInputController,
		characterAnimationController = characterAnimationController,
		activated = false,
		equipped = false,
		shooting = false,
		ammo = blaster:GetAttribute(Constants.AMMO_ATTRIBUTE),
		reloading = blaster:GetAttribute(Constants.RELOADING_ATTRIBUTE),
		connections = {},
	}
	setmetatable(self, BlasterController)

	self:initialize()

	return self
end

function BlasterController:isHumanoidAlive(): boolean
	return self.humanoid and self.humanoid.Health > 0
end

function BlasterController:canShoot(): boolean
	return self:isHumanoidAlive() and self.equipped and self.ammo > 0 and not self.reloading
end

function BlasterController:canReload(): boolean
	local magazineSize = self.blaster:GetAttribute(Constants.MAGAZINE_SIZE_ATTRIBUTE)
	return self:isHumanoidAlive() and self.equipped and self.ammo < magazineSize and not self.reloading
end

function BlasterController:recoil()
	local recoilMin = self.blaster:GetAttribute(Constants.RECOIL_MIN_ATTRIBUTE)
	local recoilMax = self.blaster:GetAttribute(Constants.RECOIL_MAX_ATTRIBUTE)

	local xDif = recoilMax.X - recoilMin.X
	local yDif = recoilMax.Y - recoilMin.Y
	local x = recoilMin.X + random:NextNumber() * xDif
	local y = recoilMin.Y + random:NextNumber() * yDif

	local recoil = Vector2.new(math.rad(-x), math.rad(y))

	CameraRecoiler.recoil(recoil)
end

function BlasterController:shoot()
	local spread = self.blaster:GetAttribute(Constants.SPREAD_ATTRIBUTE)
	local raysPerShot = self.blaster:GetAttribute(Constants.RAYS_PER_SHOT_ATTRIBUTE)
	local range = self.blaster:GetAttribute(Constants.RANGE_ATTRIBUTE)
	local rayRadius = self.blaster:GetAttribute(Constants.RAY_RADIUS_ATTRIBUTE)

	self.viewModelController:playShootAnimation()
	self.characterAnimationController:playShootAnimation()
	self:recoil()

	self.ammo -= 1

	self.guiController:setAmmo(self.ammo)

	local now = Workspace:GetServerTimeNow()
	local origin = camera.CFrame

	local rayDirections = getRayDirections(origin, raysPerShot, math.rad(spread), now)
	for index, direction in rayDirections do
		rayDirections[index] = direction * range
	end

	local rayResults = castRays(player, origin.Position, rayDirections, rayRadius)

	-- Rather than passing the entire table of rayResults to the server, we'll pass the shot origin and a list of tagged humanoids.
	-- The server will then recalculate the ray directions from the origin and validate the tagged humanoids.
	-- Strings are used for the indices since non-contiguous arrays do not get passed over the network correctly.
	-- (This may be non-contiguous in the case of firing a shotgun, where not all of the rays hit a target)
	local tagged = {}
	local didTag = false
	for index, rayResult in rayResults do
		if rayResult.taggedHumanoid then
			tagged[tostring(index)] = rayResult.taggedHumanoid
			didTag = true
		end
	end

	if didTag then
		self.guiController:showHitmarker()
	end

	shootRemote:FireServer(now, self.blaster, origin, tagged)

	local muzzlePosition = self.viewModelController:getMuzzlePosition()
	drawRayResults(muzzlePosition, rayResults)
end

function BlasterController:startShooting()
	-- If the player tries to shoot without any ammo, reload instead
	if self.ammo == 0 then
		self:reload()
		return
	end

	if not self:canShoot() then
		return
	end

	if self.shooting then
		return
	end

	local fireMode = self.blaster:GetAttribute(Constants.FIRE_MODE_ATTRIBUTE)
	local rateOfFire = self.blaster:GetAttribute(Constants.RATE_OF_FIRE_ATTRIBUTE)

	if fireMode == Constants.FIRE_MODE.SEMI then
		self.shooting = true
		self:shoot()
		task.delay(60 / rateOfFire, function()
			self.shooting = false

			if self.ammo == 0 then
				self:reload()
			end
		end)
	elseif fireMode == Constants.FIRE_MODE.AUTO then
		task.spawn(function()
			self.shooting = true
			while self.activated and self:canShoot() do
				self:shoot()
				task.wait(60 / rateOfFire)
			end
			self.shooting = false

			if self.ammo == 0 then
				self:reload()
			end
		end)
	end
end

function BlasterController:reload()
	if not self:canReload() then
		return
	end

	local reloadTime = self.blaster:GetAttribute(Constants.RELOAD_TIME_ATTRIBUTE)
	local magazineSize = self.blaster:GetAttribute(Constants.MAGAZINE_SIZE_ATTRIBUTE)

	self.viewModelController:playReloadAnimation(reloadTime)
	self.characterAnimationController:playReloadAnimation(reloadTime)

	self.reloading = true
	self.guiController:setReloading(self.reloading)
	reloadRemote:FireServer(self.blaster)

	self.reloadTask = task.delay(reloadTime, function()
		self.ammo = magazineSize
		self.reloading = false
		self.reloadTask = nil
		self.guiController:setAmmo(self.ammo)
		self.guiController:setReloading(self.reloading)
	end)
end

function BlasterController:activate()
	if self.activated then
		return
	end
	self.activated = true

	self:startShooting()
end

function BlasterController:deactivate()
	if not self.activated then
		return
	end
	self.activated = false
end

function BlasterController:equip()
	if self.equipped then
		return
	end
	self.equipped = true

	-- Resync ammo and reloading values
	self.ammo = self.blaster:GetAttribute(Constants.AMMO_ATTRIBUTE)
	self.reloading = self.blaster:GetAttribute(Constants.RELOADING_ATTRIBUTE)

	-- Enable view model
	self.viewModelController:enable()

	-- Enable GUI
	self.guiController:setAmmo(self.ammo)
	self.guiController:setReloading(self.reloading)
	self.guiController:enable()

	-- Enable touch input controller
	self.touchInputController:enable()

	-- Enable character animations
	self.characterAnimationController:enable()

	-- Keep track of the humanoid in the character currently equipping the blaster.
	-- We need this to make sure the player can't shoot while dead.
	self.humanoid = self.blaster.Parent:FindFirstChildOfClass("Humanoid")
end

function BlasterController:unequip()
	if not self.equipped then
		return
	end
	self.equipped = false

	-- Force deactivate the blaster when unequipping it
	self:deactivate()

	-- If the blaster is being reloaded, stop it
	if self.reloadTask then
		task.cancel(self.reloadTask)
		self.reloadTask = nil
	end

	-- Disable view model
	self.viewModelController:disable()

	-- Disable GUI
	self.guiController:disable()

	-- Disable touch input controller
	self.touchInputController:disable()

	-- Disable character animations
	self.characterAnimationController:disable()
end

function BlasterController:initialize()
	table.insert(
		self.connections,
		self.blaster.Equipped:Connect(function()
			self:equip()
		end)
	)
	table.insert(
		self.connections,
		self.blaster.Unequipped:Connect(function()
			self:unequip()
		end)
	)
	table.insert(
		self.connections,
		self.blaster.Activated:Connect(function()
			self:activate()
		end)
	)
	table.insert(
		self.connections,
		self.blaster.Deactivated:Connect(function()
			self:deactivate()
		end)
	)
	table.insert(
		self.connections,
		UserInputService.InputBegan:Connect(function(inputObject: InputObject, processed: boolean)
			if processed then
				return
			end

			if
				inputObject.KeyCode == Constants.KEYBOARD_RELOAD_KEY_CODE
				or inputObject.KeyCode == Constants.GAMEPAD_RELOAD_KEY_CODE
			then
				self:reload()
			end
		end)
	)

	self.touchInputController:setReloadCallback(function()
		self:reload()
	end)
end

function BlasterController:destroy()
	self:unequip()
	disconnectAndClear(self.connections)
	self.viewModelController:destroy()
	self.touchInputController:destroy()
	self.characterAnimationController:destroy()
end

return BlasterController
