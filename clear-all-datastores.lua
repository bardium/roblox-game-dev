-- Iterate through all DataStores and remove all keys from each DataStore.

local DataStoreService = game:GetService("DataStoreService")

local DataStorePages = DataStoreService:ListDataStoresAsync()

while true do
	local CurrentPageItems = DataStorePages:GetCurrentPage()

	for _, DataStoreInfo in CurrentPageItems do
		local DataStore = DataStoreService:GetDataStore(DataStoreInfo.DataStoreName)
		local DataStoreKeyPages = DataStore:ListKeysAsync()

		while true do
			local CurrentKeysPage = DataStoreKeyPages:GetCurrentPage()

			for _, Key in CurrentKeysPage do
				DataStore:RemoveAsync(Key.KeyName)
			end

			if DataStoreKeyPages.IsFinished then
				break
			end

			DataStoreKeyPages:AdvanceToNextPageAsync()
			task.wait()
		end
	end

	if DataStorePages.IsFinished then
		warn("Completed clearing all DataStores!")
		break
	end

	DataStorePages:AdvanceToNextPageAsync()
	task.wait()
end
