-- Use MarketplaceService to grab product info for Roblox assets using their IDs from an array ASSET_IDS. Print out assetsDictionary as JSON.
local HttpService = game:GetService("HttpService")
local MarketPlaceService = game:GetService("MarketplaceService")

local ASSET_IDS = {
	"17237488394",
	"14840403674",
	"10414001254",
	"17240191081",
}

local assetsDictionary = {}

for _, assetId in ASSET_IDS do
	local productInfo = MarketPlaceService:GetProductInfo(assetId)
	assetsDictionary[assetId] = productInfo
end

print(HttpService:JSONEncode(assetsDictionary))
