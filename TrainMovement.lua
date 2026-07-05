
local RunService = game:GetService("RunService")

local Controller = require(script.Parent.TrainController)
Controller.init()

local Train = Controller.Train
local SPIN_SIGN = 1 

local wheels = {}
for _, d in ipairs(Train:GetDescendants()) do
	if d:IsA("BasePart") and (d.Name == "Axel" or (d.Parent and d.Parent.Name == "AxelNodes")) then
		table.insert(wheels, { part = d, radius = math.max(d.Size.Y / 2, 0.05) })
	end
end


local wheelModels = {}
for _, m in ipairs(Train:GetChildren()) do
	if m:IsA("Model") and m.Name == "Model" then
		local p = m:GetPivot().Position
		local best, bestD
		for _, w in ipairs(wheels) do
			if w.part.Name == "Axel" then
				local d = w.part.Position - p
				local dyz = math.sqrt(d.Y ^ 2 + d.Z ^ 2)
				if dyz < 2.5 and (not bestD or dyz < bestD) then best, bestD = w.part, dyz end
			end
		end
		if best then
			table.insert(wheelModels, { model = m, axle = best, rel = best.CFrame:ToObjectSpace(m:GetPivot()) })
		end
	end
end


for _, w in ipairs(wheels) do
	local bestR, bestD
	for _, wm in ipairs(wheelModels) do
		local d = wm.axle.Position - w.part.Position
		local dyz = math.sqrt(d.Y ^ 2 + d.Z ^ 2)
		if dyz < 2.5 and (not bestD or dyz < bestD) then
			local _, bbox = wm.model:GetBoundingBox()
			bestR, bestD = math.max(bbox.Y / 2, 0.05), dyz
		end
	end
	if bestR then w.radius = bestR end
end

RunService.Heartbeat:Connect(function(dt)
	Controller.step(dt)
	Train:PivotTo(Controller.getPivotCFrame())

	local moved = Controller.lastMoved or 0
	if moved ~= 0 then
		for _, w in ipairs(wheels) do
			w.part.CFrame = w.part.CFrame * CFrame.fromAxisAngle(Vector3.xAxis, moved / w.radius * SPIN_SIGN)
		end
		for _, wm in ipairs(wheelModels) do
			wm.model:PivotTo(wm.axle.CFrame * wm.rel)
		end
	end
end)
