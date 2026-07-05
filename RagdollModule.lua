
local Ragdoll = {}

local SKIP = { RootJoint = true, ["Root Hip"] = true } -- govde koke bagli kalsin

local active = {}

local function makeSocket(part0, part1, cf0, cf1)
	local a0 = Instance.new("Attachment")
	a0.Name = "RagdollJoint"
	a0.CFrame = cf0
	a0.Parent = part0
	local a1 = Instance.new("Attachment")
	a1.Name = "RagdollJoint"
	a1.CFrame = cf1
	a1.Parent = part1
	local s = Instance.new("BallSocketConstraint")
	s.Name = "RagdollJoint"
	s.Attachment0 = a0
	s.Attachment1 = a1
	s.LimitsEnabled = true
	s.UpperAngle = 60
	s.TwistLimitsEnabled = true
	s.TwistLowerAngle = -45
	s.TwistUpperAngle = 45
	s.Parent = part0
	return a0, a1, s
end

-- duration verilmezse kalici (olum), verilirse o kadar sn sonra kalkar
function Ragdoll.ragdoll(character, duration)
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	if not humanoid or not character:FindFirstChild("HumanoidRootPart") then return end

	local entry = active[character]
	local token = {}

	if not entry then
		entry = { motors = {}, welds = {}, created = {} }
		active[character] = entry

		for _, d in ipairs(character:GetDescendants()) do
			if d:IsA("Motor6D") and not SKIP[d.Name] and d.Part0 and d.Part1 then
				table.insert(entry.motors, d)
				local a0, a1, s = makeSocket(d.Part0, d.Part1, d.C0, d.C1)
				table.insert(entry.created, a0)
				table.insert(entry.created, a1)
				table.insert(entry.created, s)
				d.Enabled = false
			elseif d:IsA("WeldConstraint") and d.Enabled and d.Part0 and d.Part1
				and (d.Name:find("Shoulder") or d.Name:find("Hip")) then
				local limb = d.Part1
				local pivot = limb.CFrame * CFrame.new(0, limb.Size.Y / 2 * 0.8, 0)
				table.insert(entry.welds, d)
				local a0, a1, s = makeSocket(d.Part0, limb,
					d.Part0.CFrame:ToObjectSpace(pivot), limb.CFrame:ToObjectSpace(pivot))
				table.insert(entry.created, a0)
				table.insert(entry.created, a1)
				table.insert(entry.created, s)
				d.Enabled = false
			end
		end
	end

	entry.token = token
	humanoid.PlatformStand = true
	humanoid:ChangeState(Enum.HumanoidStateType.Physics)

	if duration then
		task.delay(duration, function()
			if active[character] == entry and entry.token == token and humanoid.Health > 0 then
				Ragdoll.restore(character)
			end
		end)
	end
end

function Ragdoll.restore(character)
	local entry = active[character]
	if not entry then return end
	active[character] = nil

	for _, inst in ipairs(entry.created) do
		if inst.Parent then inst:Destroy() end
	end
	for _, m in ipairs(entry.motors) do
		if m.Parent then m.Enabled = true end
	end
	for _, w in ipairs(entry.welds) do
		if w.Parent then w.Enabled = true end
	end

	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if humanoid then
		humanoid.PlatformStand = false
		humanoid:ChangeState(Enum.HumanoidStateType.GettingUp)
	end
end

function Ragdoll.setup(character)
	local humanoid = character:WaitForChild("Humanoid", 10)
	if not humanoid then return end

	humanoid.BreakJointsOnDeath = false
	humanoid.RequiresNeck = false
	humanoid.Died:Connect(function()
		Ragdoll.ragdoll(character)
	end)
end

return Ragdoll
