-- Format a number into: MM:SS.ss
local function formatTime(t: number): string
	local remaining = t
	local minutes = math.floor(t / 60)
	remaining -= minutes * 60
	local seconds = math.floor(remaining)
	remaining -= seconds
	return string.format("%.2d:%.2d.%.2d", minutes, seconds, math.floor(remaining * 100))
end

return formatTime
