local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")

local spawnCar = require(script.spawnCar)
local destroyPlayerCars = require(script.destroyPlayerCars)

local spawnPromptTemplate = script.SpawnPrompt

local KIOSK_TAG = "CarSpawnKiosk"

local function setupKiosk(kiosk: Model)
	local spawnLocation = kiosk:FindFirstChild("SpawnLocation")
	assert(spawnLocation, `{kiosk:GetFullName()} has no SpawnLocation part`)
	local promptPart = kiosk:FindFirstChild("Prompt")
	assert(promptPart, `{kiosk:GetFullName()} has no Prompt part`)

	-- Hide the car spawn location
	spawnLocation.Transparency = 1

	-- Create a new prompt to spawn the car
	local spawnPrompt = spawnPromptTemplate:Clone()
	spawnPrompt.Parent = promptPart

	spawnPrompt.Triggered:Connect(function(player: Player)
		-- Remove any existing cars the player has spawned
		destroyPlayerCars(player)
		-- Spawn a new car at the spawnLocation, owned by the player
		spawnCar(spawnLocation.CFrame, player)
	end)
end

local function initialize()
	-- Remove cars owned by players whenever they leave
	Players.PlayerRemoving:Connect(destroyPlayerCars)

	-- Setup all car spawning kiosks
	CollectionService:GetInstanceAddedSignal(KIOSK_TAG):Connect(setupKiosk)

	for _, kiosk in CollectionService:GetTagged(KIOSK_TAG) do
		setupKiosk(kiosk)
	end
end

initialize()
