
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CAS = game:GetService("ContextActionService")
local UserInputService = game:GetService("UserInputService")

local cfg = require(ReplicatedStorage:WaitForChild("GameConfig")).Train

local remotes = ReplicatedStorage:WaitForChild("TrainRemotes")
local brakeEvent = remotes:WaitForChild("EmergencyBrake")
local throttleEvent = remotes:WaitForChild("SetThrottle")

local player = Players.LocalPlayer

local holdingBrake = false
local fwdHeld, backHeld = false, false
local sentThrottle = 0

local function releaseBrake()
	if holdingBrake then
		holdingBrake = false
		brakeEvent:FireServer(false)
	end
end


local function sendThrottle()
	local net = (fwdHeld and 1 or 0) - (backHeld and 1 or 0)
	if net ~= sentThrottle then
		sentThrottle = net
		throttleEvent:FireServer(net)
	end
end

local function resetThrottle()
	fwdHeld, backHeld = false, false
	sendThrottle()
end

local function onThrottle(_, state, input)
	local isFwd = input.KeyCode == Enum.KeyCode.W or input.KeyCode == Enum.KeyCode.Up
	if state == Enum.UserInputState.Begin then
		if isFwd then fwdHeld = true else backHeld = true end
	elseif state == Enum.UserInputState.End or state == Enum.UserInputState.Cancel then
		if isFwd then fwdHeld = false else backHeld = false end
	end
	sendThrottle()
	return Enum.ContextActionResult.Sink
end

local function onBrake(_, state)
	if state == Enum.UserInputState.Begin then
		local train = workspace:FindFirstChild("Train")
		local speed = train and train:GetAttribute("Speed") or 0
		if speed > cfg.DismountSpeed then
			holdingBrake = true
			brakeEvent:FireServer(true)
			return Enum.ContextActionResult.Sink -- hizliyken ziplayip dusme
		end
		return Enum.ContextActionResult.Pass -- durunca Space = koltuktan in
	elseif state == Enum.UserInputState.End or state == Enum.UserInputState.Cancel then
		if holdingBrake then
			releaseBrake()
			return Enum.ContextActionResult.Sink
		end
	end
	return Enum.ContextActionResult.Pass
end

UserInputService.WindowFocusReleased:Connect(function()
	releaseBrake()
	resetThrottle()
end)

local function seatedInTrain()
	local char = player.Character
	local hum = char and char:FindFirstChildOfClass("Humanoid")
	local seat = hum and hum.SeatPart
	local train = workspace:FindFirstChild("Train")
	return seat ~= nil and train ~= nil and seat:IsDescendantOf(train)
end

local bound = false
local function updateBinding()
	local seated = seatedInTrain()
	if seated and not bound then
		CAS:BindActionAtPriority("TrainBrake", onBrake, false,
			Enum.ContextActionPriority.High.Value, Enum.KeyCode.Space)
		CAS:BindActionAtPriority("TrainThrottle", onThrottle, false,
			Enum.ContextActionPriority.High.Value,
			Enum.KeyCode.W, Enum.KeyCode.S, Enum.KeyCode.Up, Enum.KeyCode.Down)
		bound = true
	elseif not seated and bound then
		CAS:UnbindAction("TrainBrake")
		CAS:UnbindAction("TrainThrottle")
		bound = false
		holdingBrake = false
		brakeEvent:FireServer(false)
		resetThrottle()
	end
end

local function hookCharacter(char)
	local hum = char:FindFirstChildOfClass("Humanoid") or char:WaitForChild("Humanoid")
	hum:GetPropertyChangedSignal("SeatPart"):Connect(updateBinding)
	updateBinding()
end

player.CharacterAdded:Connect(hookCharacter)
if player.Character then hookCharacter(player.Character) end
