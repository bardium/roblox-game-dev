local function playSoundFromSource(soundTemplate: Sound, source: Instance)
	local sound = soundTemplate:Clone()
	sound.Parent = source

	sound:Play()
	sound.Ended:Once(function()
		if sound:IsDescendantOf(game) then
			sound:Destroy()
		end
	end)
end

return playSoundFromSource
