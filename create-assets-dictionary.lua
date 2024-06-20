-- Use MarketplaceService to grab product info for Roblox assets using their IDs from an array ASSET_IDS. Print out productInfo as JSON.
local HttpService = game:GetService("HttpService")
local MarketPlaceService = game:GetService("MarketplaceService")

local ASSET_IDS = {
	"17237488394",
	"14840403674",
	"10414001254",
	"17240191081",
}

local productInfo = {}

for _, assetId in ASSET_IDS do
	local assetProductInfo = MarketPlaceService:GetProductInfo(assetId)
	table.insert(productInfo, assetProductInfo)
end

local stringValue = Instance.new("StringValue", game.ServerStorage)
stringValue.Name = "ProductInfo"

stringValue.Text = HttpService:JSONEncode(productInfo)
print(stringValue, stringValue:GetFullName())
