local HttpService = game:GetService("HttpService")
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")

local animationIds = {}

local lastUpdate = 0
local refreshRate = 10

local function onHeartbeat()
	for _, character in Workspace:GetDescendants() do
		local humanoid = character:FindFirstChildOfClass("Humanoid")
		if humanoid then
			for _, v in humanoid:GetPlayingAnimationTracks() do
				local animationId = v.Animation and v.Animation.AnimationId:gsub("%D", "")
				if animationId and not table.find(animationIds, animationId) then
					table.insert(animationIds, animationId)
				end
			end
		end
	end
	if (os.clock() - lastUpdate) <= refreshRate then
		return
	end
	lastUpdate = os.clock()
	print(#animationIds)
	setclipboard(HttpService:JSONEncode(animationIds))
end

RunService.Heartbeat:Connect(onHeartbeat)
