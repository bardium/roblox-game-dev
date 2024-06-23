local CAR_OWNER_TAG = "Car_%d"

local function getOwnerTag(player: Player)
	return string.format(CAR_OWNER_TAG, player.UserId)
end

return getOwnerTag
