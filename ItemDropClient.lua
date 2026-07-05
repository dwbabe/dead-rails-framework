
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CAS = game:GetService("ContextActionService")

local dropEvent = ReplicatedStorage:WaitForChild("TrainRemotes"):WaitForChild("DropItem")
local player = Players.LocalPlayer

CAS:BindAction("DropItem", function(_, state)
	if state ~= Enum.UserInputState.Begin then
		return Enum.ContextActionResult.Pass
	end
	local char = player.Character
	if char and char:FindFirstChildOfClass("Tool") then
		dropEvent:FireServer()
		return Enum.ContextActionResult.Sink
	end
	return Enum.ContextActionResult.Pass
end, false, Enum.KeyCode.G)
