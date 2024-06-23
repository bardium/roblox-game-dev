local CollectionService = game:GetService("CollectionService")

local RaceManager = require(script.RaceManager)

local RACE_TAG = "Race"

local function manageRace(raceContainer: Model)
	RaceManager.new(raceContainer)
end

local function initialize()
	CollectionService:GetInstanceAddedSignal(RACE_TAG):Connect(manageRace)

	for _, raceContainer in CollectionService:GetTagged(RACE_TAG) do
		manageRace(raceContainer)
	end
end

initialize()
