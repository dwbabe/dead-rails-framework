-- @75132 @scampilI

local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local cfg = require(ReplicatedStorage:WaitForChild("GameConfig")).Train

local Controller = {}

local INVERT_FORWARD = true 
local END_TAPER = 45 
local SLICE = 2
local Y_TOLERANCE = 0.75
local STOP_EPS = 0.05

local state = {
	initialized = false,
	speed = 0,
	speedVel = 0,
	distance = 0,
	traveled = 0,
	fuel = 0,
	braking = false,
	lastMoved = 0,
	clientThrottle = 0,
	waypoints = {},
	cumLen = {},
	pathLength = 0,
	localOffset = CFrame.identity,
	segHint = 1,
}
Controller.state = state

local Train, Base, Seat


local function buildCenterline()
	local rails = workspace:FindFirstChild("Rails")
	assert(rails, "workspace.Rails bulunamadi")
	local parts = {}
	for _, d in ipairs(rails:GetDescendants()) do
		if d:IsA("BasePart") then table.insert(parts, d) end
	end

	local ys = {}
	for _, p in ipairs(parts) do table.insert(ys, p.Position.Y) end
	table.sort(ys)
	local medianY = ys[math.max(1, math.floor(#ys / 2))]
	local filtered = {}
	for _, p in ipairs(parts) do
		if math.abs(p.Position.Y - medianY) <= Y_TOLERANCE then
			table.insert(filtered, p)
		end
	end
	if #filtered >= 2 then parts = filtered end

	table.sort(parts, function(a, b) return a.Position.Z < b.Position.Z end)
	local nodes = {}
	local i = 1
	while i <= #parts do
		local z0 = parts[i].Position.Z
		local sum, n = Vector3.zero, 0
		while i <= #parts and (parts[i].Position.Z - z0) < SLICE do
			sum += parts[i].Position
			n += 1
			i += 1
		end
		table.insert(nodes, sum / n)
	end
	return nodes
end

function Controller.getPathFrame(d)
	local wp, cum = state.waypoints, state.cumLen
	d = math.clamp(d, 0, state.pathLength)
	local i = math.clamp(state.segHint, 1, #wp - 1)
	if cum[i] > d then i = 1 end
	while i < #wp - 1 and cum[i + 1] < d do i += 1 end
	state.segHint = i
	local a, b = wp[i], wp[i + 1]
	local segLen = cum[i + 1] - cum[i]
	local t = segLen > 0 and (d - cum[i]) / segLen or 0
	local pos = a:Lerp(b, t)
	local dir = b - a
	if dir.Magnitude < 1e-4 then dir = Vector3.zAxis end
	return CFrame.lookAt(pos, pos + dir.Unit, Vector3.yAxis)
end

function Controller.getPivotCFrame()
	return Controller.getPathFrame(state.distance) * state.localOffset
end


function Controller.extendPath(nodes)
	for _, n in ipairs(nodes) do
		local i = #state.waypoints
		table.insert(state.waypoints, n)
		state.cumLen[i + 1] = state.cumLen[i] + (n - state.waypoints[i]).Magnitude
	end
	state.pathLength = state.cumLen[#state.cumLen]
end

local function nearestDistance(pos)
	local wp, cum = state.waypoints, state.cumLen
	local bestD, best = math.huge, 0
	for i = 1, #wp - 1 do
		local a, ab = wp[i], wp[i + 1] - wp[i]
		local len2 = ab:Dot(ab)
		local t = len2 > 0 and math.clamp((pos - a):Dot(ab) / len2, 0, 1) or 0
		local d = (pos - (a + ab * t)).Magnitude
		if d < bestD then
			bestD = d
			best = cum[i] + ab.Magnitude * t
		end
	end
	return best
end

local function smoothDamp(current, target, vel, smoothTime, dt)
	smoothTime = math.max(0.0001, smoothTime)
	local omega = 2 / smoothTime
	local x = omega * dt
	local expf = 1 / (1 + x + 0.48 * x * x + 0.235 * x * x * x)
	local change = current - target
	local temp = (vel + omega * change) * dt
	local newVel = (vel - omega * temp) * expf
	local output = target + (change + temp) * expf
	if (target - current > 0) == (output > target) then
		output = target
		newVel = (output - target) / dt
	end
	return output, newVel
end

local function readThrottle()
	local override = Train:GetAttribute("ThrottleOverride")
	if typeof(override) == "number" then
		return math.clamp(override, -1, 1)
	end
	if Seat and Seat.Occupant then
		if Seat.ThrottleFloat ~= 0 then
			return math.clamp(Seat.ThrottleFloat, -1, 1)
		end
		return math.clamp(state.clientThrottle, -1, 1)
	end
	return 0
end

local function publish()
	Train:SetAttribute("Speed", math.abs(state.speed))
	Train:SetAttribute("SpeedSigned", state.speed)
	Train:SetAttribute("Fuel", state.fuel / cfg.FuelCapacity * 100)
	Train:SetAttribute("DistanceMeters", math.floor(state.traveled * cfg.MetersPerStud))
end

function Controller.step(dt)
	if not state.initialized or dt <= 0 then return end

	local throttle = readThrottle()
	local hasFuel = state.fuel > 0

	local target = 0
	if hasFuel and throttle > 0 then
		target = throttle * cfg.MaxSpeed
	elseif hasFuel and throttle < 0 then
		target = throttle * cfg.MaxSpeed * cfg.ReverseFraction
	end


	if target > 0 then
		local left = state.pathLength - state.distance
		if left < END_TAPER then target = math.min(target, cfg.MaxSpeed * left / END_TAPER) end
	elseif target < 0 then
		local left = state.distance
		if left < END_TAPER then target = math.max(target, -cfg.MaxSpeed * left / END_TAPER) end
	end

	local smoothTime
	if state.braking then
		smoothTime = cfg.BrakeTime
		target = 0
	elseif hasFuel and math.abs(target) > math.abs(state.speed) then
		smoothTime = cfg.AccelTime
	else
		smoothTime = cfg.CoastTime
	end

	state.speed, state.speedVel = smoothDamp(state.speed, target, state.speedVel, smoothTime, dt)
	if math.abs(state.speed) < STOP_EPS and math.abs(target) < STOP_EPS then
		state.speed, state.speedVel = 0, 0
	end

	local prev = state.distance
	state.distance += state.speed * dt
	if state.distance <= 0 then
		state.distance = 0
		if state.speed < 0 then state.speed, state.speedVel = 0, 0 end
	elseif state.distance >= state.pathLength then
		state.distance = state.pathLength
		if state.speed > 0 then state.speed, state.speedVel = 0, 0 end
	end
	state.lastMoved = state.distance - prev
	state.traveled += math.abs(state.lastMoved)
	Controller.lastMoved = state.lastMoved

	if hasFuel then
		local drain = cfg.IdleDrain + math.abs(state.speed) / cfg.MaxSpeed * cfg.MovingDrain
		state.fuel = math.max(0, state.fuel - drain * dt)
	end

	publish()
end

function Controller.addFuel(amount)
	state.fuel = math.clamp(state.fuel + amount, 0, cfg.FuelCapacity)
	publish()
end

function Controller.setBraking(on)
	state.braking = on == true
end

function Controller.init()
	if state.initialized then return end

	Train = workspace:WaitForChild("Train")
	Controller.Train = Train

	Base = Train:FindFirstChild("Base")
	assert(Base, "Train.Base bulunamadi")
	Train.PrimaryPart = Base


	for _, p in ipairs(Train:GetDescendants()) do
		if p:IsA("BasePart") then p.Anchored = true end
	end

	Seat = Train:FindFirstChildWhichIsA("VehicleSeat", true)
	if Seat then
		Seat.HeadsUpDisplay = false -- koltugun kendi hiz gostergesi hep 0 gosterir
		Seat:GetPropertyChangedSignal("Occupant"):Connect(function()
			if not Seat.Occupant then
				Controller.setBraking(false)
				state.clientThrottle = 0
			end
		end)
	end

	local remotes = game:GetService("ReplicatedStorage"):FindFirstChild("TrainRemotes")
	remotes.EmergencyBrake.OnServerEvent:Connect(function(_, held)
		Controller.setBraking(held == true)
	end)

	remotes.SetThrottle.OnServerEvent:Connect(function(player, value)
		if typeof(value) ~= "number" or value ~= value then return end
		local occupant = Seat and Seat.Occupant
		if occupant and occupant.Parent == player.Character then
			state.clientThrottle = math.clamp(value, -1, 1)
		end
	end)

	local nodes = buildCenterline()
	local aligned = (nodes[2] - nodes[1]).Unit:Dot(Base.CFrame.LookVector) >= 0
	if INVERT_FORWARD then aligned = not aligned end
	if not aligned then
		local rev = {}
		for i = #nodes, 1, -1 do table.insert(rev, nodes[i]) end
		nodes = rev
	end

	state.waypoints = nodes
	state.cumLen = { 0 }
	for i = 2, #nodes do
		state.cumLen[i] = state.cumLen[i - 1] + (nodes[i] - nodes[i - 1]).Magnitude
	end
	state.pathLength = state.cumLen[#nodes]

	state.distance = nearestDistance(Base.Position)
	state.localOffset = Controller.getPathFrame(state.distance):Inverse() * Base.CFrame
	state.fuel = cfg.StartFuel
	state.initialized = true
	publish()
end

if RunService:IsServer() then
	Controller.init()
end

return Controller
