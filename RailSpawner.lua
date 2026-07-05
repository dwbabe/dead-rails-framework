
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")

local cfg = require(ReplicatedStorage:WaitForChild("GameConfig")).Rails
local Controller = require(script.Parent.TrainController)
Controller.init()

local state = Controller.state
local rails = workspace:WaitForChild("Rails")


local function worldZExtent(model)
	local minZ, maxZ = math.huge, -math.huge
	for _, p in ipairs(model:GetDescendants()) do
		if p:IsA("BasePart") then
			local cf, s = p.CFrame, p.Size
			local half = math.abs(cf.RightVector.Z) * s.X / 2
				+ math.abs(cf.UpVector.Z) * s.Y / 2
				+ math.abs(cf.LookVector.Z) * s.Z / 2
			minZ = math.min(minZ, p.Position.Z - half)
			maxZ = math.max(maxZ, p.Position.Z + half)
		end
	end
	return minZ, maxZ
end

local template = rails:Clone()
template.Parent = ServerStorage

local minZ, maxZ = worldZExtent(rails)
local tileLen = (maxZ - minZ) - 2
local basePivot = rails:GetPivot()

local tiles = { { model = rails, maxZ = maxZ } }
local placedOffset = 0

local function spawnNext()
	placedOffset += tileLen
	local clone = template:Clone()
	clone:PivotTo(basePivot + Vector3.new(0, 0, placedOffset))
	clone.Parent = workspace
	local _, cloneMax = worldZExtent(clone)
	table.insert(tiles, { model = clone, maxZ = cloneMax })

	local last = state.waypoints[#state.waypoints]
	Controller.extendPath({ last + Vector3.new(0, 0, tileLen) })
end

task.spawn(function()
	while true do
		while state.pathLength - state.distance < cfg.SpawnAhead do
			spawnNext()
		end

		local trainZ = Controller.Train:GetPivot().Position.Z
		for i = #tiles, 1, -1 do
			local t = tiles[i]
			if t.maxZ < trainZ - cfg.CleanupBehind then
				t.model:Destroy()
				table.remove(tiles, i)
			end
		end

		task.wait(2)
	end
end)
