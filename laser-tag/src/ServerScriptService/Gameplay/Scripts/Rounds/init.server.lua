local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local Teams = game:GetService("Teams")

local Constants = require(ReplicatedStorage.Gameplay.Constants)
local Scoring = require(script.Parent.Scoring)
local spawnCharacters = require(script.spawnCharacters)
local despawnCharacters = require(script.despawnCharacters)

local remotes = ReplicatedStorage.Gameplay.Remotes
local ronudWinnerRemote = remotes.RoundWinner

local MODES = {
	require(script.Parent.Modes.TDM),
}

local random = Random.new()

local function startRoundLoopAsync()
	while true do
		-- Reset scores
		Scoring.resetScores()

		-- Pick mode
		local mode = MODES[random:NextInteger(1, #MODES)]
		local timer = mode.timer

		-- Start the mode, passing in a callback to be called if it finishes early
		local roundFinished = false
		mode.start(function()
			roundFinished = true
		end)

		-- Spawn characters
		Players.CharacterAutoLoads = true
		spawnCharacters()

		-- Countdown timer
		while timer > 0 and not roundFinished do
			timer -= 1
			Workspace:SetAttribute(Constants.TIMER_ATTRIBUTE, timer)
			task.wait(1)
		end

		-- End the mode
		mode.stop()

		-- Display winning team
		local teams = Teams:GetTeams()
		table.sort(teams, function(teamA: Team, teamB: Team)
			return Scoring.getTeamScore(teamA) > Scoring.getTeamScore(teamB)
		end)

		local winningTeam = teams[1]
		ronudWinnerRemote:FireAllClients(winningTeam)

		-- Disable spawning
		Players.CharacterAutoLoads = false
		despawnCharacters()

		-- Wait for intermission
		task.wait(Constants.INTERMISSION_TIME)
	end
end

task.spawn(startRoundLoopAsync)
