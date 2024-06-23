-- This script replaces the default Health script
local RunService = game:GetService("RunService")

local character = script.Parent
local humanoid = character.Humanoid

local REGEN_DELAY = 5
local REGEN_RATE = 10

local lastHealth = humanoid.Health
local lastDamageTime = 0

local function onHeartbeat(deltaTime: number)
	local elapsed = os.clock() - lastDamageTime
	if elapsed < REGEN_DELAY then
		return
	end
	if humanoid.Health >= humanoid.MaxHealth then
		return
	end

	humanoid.Health = math.min(humanoid.Health + REGEN_RATE * deltaTime, humanoid.MaxHealth)
end

local function onHealthChanged(health: number)
	if health < lastHealth then
		lastDamageTime = os.clock()
	end
	lastHealth = health
end

RunService.Heartbeat:Connect(onHeartbeat)
humanoid.HealthChanged:Connect(onHealthChanged)
