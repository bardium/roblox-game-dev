local CollectionService = game:GetService("CollectionService")

local getOwnerTag = require(script.Parent.getOwnerTag)

-- Destroy all the cars owned by a player
local function destroyPlayerCars(player: Player)
	local ownerTag = getOwnerTag(player)
	local cars = CollectionService:GetTagged(ownerTag)

	for _, car in cars do
		car:Destroy()
	end
end

return destroyPlayerCars
