-- Take all the meshes in the place and create a folder to store every unique mesh in a grid

local meshParts = {}

local meshesFolder = workspace:FindFirstChild("Meshes") or Instance.new("Folder", workspace)
meshesFolder.Name = "Meshes"

meshesFolder:ClearAllChildren()

for _, meshPart in game:GetDescendants() do
	if not meshPart:IsA("MeshPart") or meshPart:IsDescendantOf(meshesFolder) then
		continue
	end

	local meshId = meshPart.MeshId
	local meshSize = meshPart.Size.Magnitude

	if not meshParts[meshId] or meshParts[meshId].Size.Magnitude > meshSize then
		meshParts[meshId] = meshPart
	end
end

local numberOfMeshParts = 0
for _, _ in meshParts do
	numberOfMeshParts += 1
end

local gridSpacing = 4
local gridSize = math.ceil(math.sqrt(numberOfMeshParts))

print(gridSize)

local row = 0
local column = 0

local meshModels = {}

for _, meshPart in meshParts do
	local meshPartModel = Instance.new("Model", meshesFolder)
	
	local newMeshPart = meshPart:Clone()
	newMeshPart:ClearAllChildren()
	newMeshPart.Parent = meshPartModel

	local position = Vector3.new(column * gridSpacing, 0, row * gridSpacing)
	newMeshPart:PivotTo(CFrame.new(position))
	
	column = column + 1
	if column >= gridSize then
		column = 0
		row = row + 1
	end
	
	table.insert(meshModels, meshPartModel)
end

local meshSizes = {}

for _, meshModel in meshModels do
	table.insert(meshSizes, meshModel:FindFirstChildOfClass("MeshPart").Size.Magnitude)
end

local totalSize = 0
for _, size in meshSizes do
	totalSize = totalSize + size
end

local averageSize = #meshSizes > 0 and (totalSize / #meshSizes) or 0

for _, meshModel in meshModels do
	local meshPart = meshModel:FindFirstChildOfClass("MeshPart")
	meshPart.Transparency = meshPart.Transparency >= 0.95 and 0.5 or meshPart.Transparency
	meshModel:ScaleTo(averageSize / meshPart.Size.Magnitude)
end
