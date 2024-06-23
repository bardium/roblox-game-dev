local function getStartingArea(raceContainer: Model): BasePart
	local startingArea = raceContainer:FindFirstChild("StartingArea")
	assert(startingArea, `No StartingArea in {raceContainer:GetFullName()}`)

	return startingArea
end

return getStartingArea
