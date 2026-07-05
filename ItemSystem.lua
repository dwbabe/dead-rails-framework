
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CollectionService = game:GetService("CollectionService")

local Config = require(ReplicatedStorage:WaitForChild("GameConfig"))
local cfg = Config.Items

local dropEvent = ReplicatedStorage:WaitForChild("TrainRemotes"):WaitForChild("DropItem")

local function isFuelItem(tool, handle)
	return Config.FuelItems[tool.Name] ~= nil
		or handle:GetAttribute("FuelAmount") ~= nil
		or CollectionService:HasTag(handle, "Fuel")
end

dropEvent.OnServerEvent:Connect(function(player)
	local char = player.Character
	local root = char and char:FindFirstChild("HumanoidRootPart")
	if not root then return end

	local tool = char:FindFirstChildOfClass("Tool")
	local handle = tool and tool:FindFirstChild("Handle")
	if not handle then return end


	local fuelDetect = workspace:FindFirstChild("FuelDetect", true)
	if fuelDetect and isFuelItem(tool, handle) then
		local toBox = fuelDetect.Position - root.Position
		if toBox.Magnitude < 7 and root.CFrame.LookVector:Dot(toBox.Unit) > 0.4 then
			tool.Parent = workspace
			handle.Anchored = true
			handle.CFrame = fuelDetect.CFrame
			task.delay(2, function()
				if handle.Parent then handle.Anchored = false end
			end)
			return
		end
	end


	local origin = root.CFrame * CFrame.new(0, 0.3, 0)
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = { char, tool }
	local hit = workspace:Raycast(origin.Position, origin.LookVector * (cfg.DropDistance + 2), params)
	local dist = hit and math.max(hit.Distance - 0.8, 0.8) or cfg.DropDistance

	tool.Parent = workspace
	handle.CanCollide = true
	local dropPos = (origin * CFrame.new(0, 0, -dist)).Position
	local flat = origin.LookVector * Vector3.new(1, 0, 1)
	flat = flat.Magnitude > 0.01 and flat.Unit or Vector3.zAxis
	handle.CFrame = CFrame.new(dropPos, dropPos + flat)
	handle.AssemblyLinearVelocity = root.CFrame.LookVector * cfg.ThrowSpeed + Vector3.new(0, 2, 0)
	handle.AssemblyAngularVelocity = Vector3.zero


	handle.CanTouch = false
	task.delay(cfg.PickupCooldown, function()
		if handle.Parent == tool and tool.Parent == workspace then
			handle.CanTouch = true
		end
	end)
end)
