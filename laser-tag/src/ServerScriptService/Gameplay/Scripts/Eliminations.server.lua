local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local blasterEvents = ServerScriptService.Blaster.Events
local eliminatedEvent = blasterEvents.Eliminated

local remotes = ReplicatedStorage.Gameplay.Remotes
local eliminatedRemote = remotes.Eliminated

local function onEliminated(player: Player, eliminatedHumanoid: Humanoid)
	-- When a player gets an elimination, fire a remote to tell them to display an elimination UI
	local eliminatedCharacter = eliminatedHumanoid.Parent
	local eliminatedPlayer = Players:GetPlayerFromCharacter(eliminatedCharacter)
	local name = if eliminatedPlayer then eliminatedPlayer.DisplayName else eliminatedCharacter.Name

	eliminatedRemote:FireClient(player, name)
end

eliminatedEvent.Event:Connect(onEliminated)
