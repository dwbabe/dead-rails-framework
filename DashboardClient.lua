
local Lighting = game:GetService("Lighting")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local cfg = require(ReplicatedStorage:WaitForChild("GameConfig")).Dashboard

local Train = workspace:WaitForChild("Train")
local TC = Train:WaitForChild("TrainControls")

local function findNeedle(part)
	local sg = part:FindFirstChildWhichIsA("SurfaceGui")
	local img = sg and sg:FindFirstChild("ImageLabel")
	return img and img:FindFirstChild("Gauge")
end
local function findLabel(part)
	local sg = part:FindFirstChildWhichIsA("SurfaceGui")
	return sg and sg:FindFirstChildWhichIsA("TextLabel")
end

local speedNeedle = findNeedle(TC:WaitForChild("Spedometer"))
local fuelNeedle = findNeedle(TC:WaitForChild("Fuel"))
local distanceLabel = findLabel(TC:WaitForChild("DistanceDial"))
local timeLabel = findLabel(TC:WaitForChild("TimeDial"))

local function angleFor(value, maxValue)
	local a = math.clamp(value / maxValue, 0, 1)
	return cfg.NeedleMin + (cfg.NeedleMax - cfg.NeedleMin) * a
end

RunService.RenderStepped:Connect(function(dt)
	local alpha = math.clamp(dt * cfg.NeedleLerp, 0, 1)
	if speedNeedle then
		local goal = angleFor(Train:GetAttribute("Speed") or 0, cfg.SpeedGaugeMax)
		speedNeedle.Rotation += (goal - speedNeedle.Rotation) * alpha
	end
	if fuelNeedle then
		local goal = angleFor(Train:GetAttribute("Fuel") or 0, 100)
		fuelNeedle.Rotation += (goal - fuelNeedle.Rotation) * alpha
	end
end)

if distanceLabel then
	task.spawn(function()
		local last
		while true do
			local m = Train:GetAttribute("DistanceMeters") or 0
			if m ~= last then
				last = m
				distanceLabel.Text = m .. " m"
			end
			task.wait(cfg.DistanceRefresh)
		end
	end)
end

local function formatClock()
	local total = math.floor(Lighting.ClockTime * 60 + 0.5) % (24 * 60)
	local h, m = math.floor(total / 60), total % 60
	local ampm = h < 12 and "AM" or "PM"
	h = h % 12
	if h == 0 then h = 12 end
	return string.format("%d:%02d %s", h, m, ampm)
end

if timeLabel then
	local last
	local function refresh()
		local s = formatClock()
		if s ~= last then
			last = s
			timeLabel.Text = s
		end
	end
	Lighting:GetPropertyChangedSignal("ClockTime"):Connect(refresh)
	refresh()
end
