local PhysicsService = game:GetService("PhysicsService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local safePlayerAdded = require(script.safePlayerAdded)

local CAR_COLLISION_GROUP = "Car"
local CHARACTER_COLLISION_GROUP = "Character"

local carTemplate = ReplicatedStorage.Car

local function onCharacterAdded(character: Model)
	-- Set the collision group for any parts that are added to the character
	character.DescendantAdded:Connect(function(descendant)
		if descendant:IsA("BasePart") then
			descendant.CollisionGroup = CHARACTER_COLLISION_GROUP
		end
	end)

	-- Set the collision group for any parts currently in the character
	for _, descendant in character:GetDescendants() do
		if descendant:IsA("BasePart") then
			descendant.CollisionGroup = CHARACTER_COLLISION_GROUP
		end
	end
end

local function onPlayerAdded(player: Player)
	player.CharacterAdded:Connect(onCharacterAdded)

	if player.Character then
		onCharacterAdded(player.Character)
	end
end

local function initialize()
	-- Setup collision groups
	PhysicsService:RegisterCollisionGroup(CAR_COLLISION_GROUP)
	PhysicsService:RegisterCollisionGroup(CHARACTER_COLLISION_GROUP)

	-- Stop the collision groups from colliding with each other
	PhysicsService:CollisionGroupSetCollidable(CAR_COLLISION_GROUP, CAR_COLLISION_GROUP, false)
	PhysicsService:CollisionGroupSetCollidable(CHARACTER_COLLISION_GROUP, CHARACTER_COLLISION_GROUP, false)
	PhysicsService:CollisionGroupSetCollidable(CAR_COLLISION_GROUP, CHARACTER_COLLISION_GROUP, false)

	-- Set the car collision group
	for _, descendant in carTemplate:GetDescendants() do
		if descendant:IsA("BasePart") then
			descendant.CollisionGroup = CAR_COLLISION_GROUP
		end
	end

	-- Set character collision groups for all players
	safePlayerAdded(onPlayerAdded)
end

initialize()
