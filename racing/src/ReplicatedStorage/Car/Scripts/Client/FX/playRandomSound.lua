-- Play a random sound from a list of sounds
local function playRandomSound(sounds: { Sound }, source: BasePart, volume: number?)
	local soundTemplate = sounds[math.random(1, #sounds)]

	local sound = soundTemplate:Clone()
	sound.Volume *= (volume or 1)
	sound.Parent = source
	sound:Play()

	-- Calculate the actual time it will take the sound to play based on its playback speed
	local actualLength = sound.TimeLength / sound.PlaybackSpeed
	task.delay(actualLength, function()
		sound:Destroy()
	end)
end

return playRandomSound
