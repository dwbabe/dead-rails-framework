
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CollectionService = game:GetService("CollectionService")

local Config = require(ReplicatedStorage:WaitForChild("GameConfig"))
local Controller = require(script.Parent.TrainController)
Controller.init()

local Train = Controller.Train
local FuelDetect = Train.TrainControls.FuelDetect

local refuelSound = FuelDetect:FindFirstChild("Sound")
local fireSound = FuelDetect:FindFirstChild("Fire") -- bu da bir Sound


local fireEmitter, refuelEmitter, fireLight
local fireBase = Train:FindFirstChild("FireBase", true)
if fireBase then
	local att = fireBase:FindFirstChildWhichIsA("Attachment") or fireBase
	fireEmitter = att:FindFirstChild("Fire")
	refuelEmitter = att:FindFirstChild("Refuel")
	fireLight = att:FindFirstChild("PointLight")
end


local function fuelValue(part)
	local tool = part:FindFirstAncestorOfClass("Tool")
	if tool and tool.Parent and tool.Parent:FindFirstChildOfClass("Humanoid") then
		return nil
	end
	if tool and Config.FuelItems[tool.Name] then
		return Config.FuelItems[tool.Name]
	end
	local attr = part:GetAttribute("FuelAmount")
	if attr then return attr end
	if CollectionService:HasTag(part, "Fuel") then return 25 end
	return nil
end

local used = setmetatable({}, { __mode = "k" })

local function consume(part)
	if used[part] then return end
	local amount = fuelValue(part)
	if not amount then return end
	used[part] = true

	Controller.addFuel(amount)
	if refuelSound then refuelSound:Play() end
	if fireSound then fireSound:Play() end
	if refuelEmitter then refuelEmitter:Emit(30) end

	local tool = part:FindFirstAncestorOfClass("Tool")
	;(tool or part):Destroy()
end

FuelDetect.Touched:Connect(consume)


task.spawn(function()
	while FuelDetect.Parent do
		for _, p in ipairs(workspace:GetPartsInPart(FuelDetect)) do
			consume(p)
		end
		task.wait(0.5)
	end
end)


local function updateFire()
	local lit = (Train:GetAttribute("Fuel") or 0) > 0
	if fireEmitter then fireEmitter.Enabled = lit end
	if fireLight then fireLight.Enabled = lit end
end
Train:GetAttributeChangedSignal("Fuel"):Connect(updateFire)
updateFire()
