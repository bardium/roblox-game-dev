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

local fullText = HttpService:JSONEncode(productInfo)

local maxStringLength = 100000
local chunks = {}
for i = 1, #fullText, maxStringLength do
	table.insert(chunks, fullText:sub(i, i + maxStringLength - 1))
end

for _, chunk in chunks do
    print(chunk)
end
