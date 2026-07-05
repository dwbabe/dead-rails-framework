
local Players = game:GetService("Players")

local function ensureR6(player, character)
	local humanoid = character:WaitForChild("Humanoid", 10)
	if not humanoid or humanoid.RigType == Enum.HumanoidRigType.R6 then return end

	local ok, err = pcall(function()
		local desc = humanoid:GetAppliedDescription()
		local model = Players:CreateHumanoidModelFromDescription(desc, Enum.HumanoidRigType.R6)
		model.Name = player.Name
		local pivot = character:GetPivot()
		player.Character = model
		model.Parent = workspace
		model:PivotTo(pivot)
		character:Destroy()
	end)
	if not ok then
		warn("R6 cevirme olmadi, Game Settings > Avatar > R6 yapin: " .. tostring(err))
	end
end

Players.PlayerAdded:Connect(function(player)
	player.CharacterAdded:Connect(function(char) ensureR6(player, char) end)
end)
for _, player in ipairs(Players:GetPlayers()) do
	player.CharacterAdded:Connect(function(char) ensureR6(player, char) end)
	if player.Character then ensureR6(player, player.Character) end
end
