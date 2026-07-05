
local Players = game:GetService("Players")
local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage:WaitForChild("GameConfig"))
local Ragdoll = require(script.Parent.RagdollModule)


local function dropToolsAt(player, character)
	local pivot = character:GetPivot()
	local tools = {}
	for _, t in ipairs(character:GetChildren()) do
		if t:IsA("Tool") then table.insert(tools, t) end
	end
	local backpack = player:FindFirstChildOfClass("Backpack")
	if backpack then
		for _, t in ipairs(backpack:GetChildren()) do
			if t:IsA("Tool") then table.insert(tools, t) end
		end
	end
	for i, t in ipairs(tools) do
		local handle = t:FindFirstChild("Handle")
		t.Parent = workspace
		if handle then
			-- cesedin biraz ustune, ic ice girip firlamasinlar
			handle.CanCollide = true
			handle.CFrame = pivot * CFrame.new((i - 1) * 2, 2.5, 1.5)
			handle.AssemblyLinearVelocity = Vector3.zero
			handle.AssemblyAngularVelocity = Vector3.zero
		end
	end
end

local function onCharacter(player, character)
	Ragdoll.setup(character)
	local humanoid = character:FindFirstChildOfClass("Humanoid") or character:WaitForChild("Humanoid", 10)
	if humanoid then
		humanoid.Died:Connect(function()
			dropToolsAt(player, character)
		end)
	end
end

local function hookPlayer(player)
	player.CharacterAdded:Connect(function(char) onCharacter(player, char) end)
	if player.Character then onCharacter(player, player.Character) end
end

Players.PlayerAdded:Connect(hookPlayer)
for _, player in ipairs(Players:GetPlayers()) do hookPlayer(player) end


local function isNpc(model)
	return model:IsA("Model")
		and (model.Name == "Zombie" or CollectionService:HasTag(model, "Ragdollable"))
		and model:FindFirstChildOfClass("Humanoid") ~= nil
		and Players:GetPlayerFromCharacter(model) == nil
end

local function setupNpc(model)
	if not isNpc(model) then return end
	Ragdoll.setup(model)
	local dmg = model:FindFirstChild("Damage", true)
	if dmg and dmg:IsA("IntValue") then
		dmg.Value = Config.Zombie.Damage
	end
end

for _, m in ipairs(workspace:GetChildren()) do setupNpc(m) end
workspace.ChildAdded:Connect(function(m)
	task.defer(setupNpc, m)
end)
