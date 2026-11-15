local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local plr = Players.LocalPlayer

local TRAJ_POINTS = 26
local PTS = 12

local rt = {
	reach = 40,
	power = 1,
	volley = false,
	traj = false,
	volleyConn = nil,
	trajConn = nil,
	last = 0,
	parts = {},
	folder = nil,
}

local function net()
	local shared = ReplicatedStorage:FindFirstChild("Shared")
	local n = shared and shared:FindFirstChild("Net")
	return n
end

local function planRemote()
	local n = net()
	return n and n:FindFirstChild("RE/KickPlan")
end

local function ball()
	return workspace:FindFirstChild("Ball")
end

local function root()
	local c = plr.Character
	if not c then
		return nil
	end
	return c:FindFirstChild("Root") or c:FindFirstChild("HumanoidRootPart")
end

local function flat(v)
	return Vector3.new(v.X, 0, v.Z)
end

local function aimDir()
	local cam = workspace.CurrentCamera
	if not cam then
		return Vector3.new(0, 0, -1)
	end
	local d = flat(cam.CFrame.LookVector)
	if d.Magnitude < 0.01 then
		return Vector3.new(0, 0, -1)
	end
	return d.Unit
end

local function fire(family, power)
	local remote = planRemote()
	local b = ball()
	local r = root()
	if not remote or not b or not r then
		return false, "missing"
	end
	local dist = (r.Position - b.Position).Magnitude
	if dist > rt.reach then
		return false, ("%.0f studs, reach %.0f"):format(dist, rt.reach)
	end
	local now = workspace:GetServerTimeNow()
	if now - rt.last < 0.45 then
		return false, "cooldown"
	end
	rt.last = now
	local dir = aimDir()
	local payload = {
		id = math.random(100000, 999999),
		hold = false,
		leg = 1,
		t = now + 0.06,
		shift = Vector3.new(0, 0, 0),
		ball = b.Position,
		dir = dir,
		family = family or "Laced",
		power = power or rt.power,
		plant = b.Position - dir * 1.0,
		plantYaw = 0,
		plantAt = now,
	}
	remote:FireServer(payload)
	return true
end

local function airborne(b)
	local ground = 1.2
	local ray = RaycastParams.new()
	ray.FilterType = Enum.RaycastFilterType.Exclude
	ray.FilterDescendantsInstances = { b, plr.Character }
	local hit = workspace:Raycast(b.Position, Vector3.new(0, -40, 0), ray)
	if hit then
		ground = hit.Position.Y + b.Size.Y / 2
	end
	return b.Position.Y - ground > 1.6
end

local function volleyTick()
	if not rt.volley then
		return
	end
	local b = ball()
	if not b then
		return
	end
	if not airborne(b) then
		return
	end
	local family = "Volley"
	if b.Position.Y > 9 then
		family = "Bicycle"
	elseif b.Position.Y > 6.2 then
		family = "DivingHeader"
	end
	fire(family, rt.power)
end

local function trajFolder()
	if rt.folder and rt.folder.Parent then
		return rt.folder
	end
	local f = Instance.new("Folder")
	f.Name = "AscendTrajectory"
	f.Parent = workspace
	rt.folder = f
	return f
end

local function trajPart(i)
	local p = rt.parts[i]
	if p and p.Parent then
		return p
	end
	p = Instance.new("Part")
	p.Name = "Trajectory"
	p.Shape = Enum.PartType.Ball
	p.Size = Vector3.new(0.28, 0.28, 0.28)
	p.Material = Enum.Material.Neon
	p.Color = Color3.fromRGB(126, 108, 255)
	p.Transparency = 1
	p.Anchored = true
	p.CanCollide = false
	p.CanQuery = false
	p.CanTouch = false
	p.CastShadow = false
	p.Parent = trajFolder()
	rt.parts[i] = p
	return p
end

local function hideTraj(from)
	for i = from, TRAJ_POINTS do
		local p = rt.parts[i]
		if p then
			p.Transparency = 1
		end
	end
end

local function trajTick()
	local b = ball()
	if not b then
		hideTraj(1)
		return
	end
	local dir = aimDir()
	local speed = 131.5 * math.clamp(rt.power, 0.05, 1.05)
	local v = dir * speed + Vector3.new(0, speed * 0.06, 0)
	local g = Vector3.new(0, -(b:GetAttribute("Gravity") or 46), 0)
	local ray = RaycastParams.new()
	ray.FilterType = Enum.RaycastFilterType.Exclude
	ray.FilterDescendantsInstances = { b, plr.Character }
	local hit = workspace:Raycast(b.Position, Vector3.new(0, -60, 0), ray)
	local floor = hit and (hit.Position.Y + b.Size.Y * 0.5) or 1.0
	local dt = 0.055
	local shown = 0
	for i = 1, TRAJ_POINTS do
		local t = i * dt
		local p = b.Position + v * t + 0.5 * g * t * t
		if p.Y < floor then
			break
		end
		local part = trajPart(i)
		part.Position = p
		part.Transparency = 0.15 + (i / TRAJ_POINTS) * 0.6
		shown = i
	end
	hideTraj(shown + 1)
end

local mod = {
	name = "Ragdoll Soccer",
	icon = "",
	placeIds = { 106931373443671 },
	match = { "ragdoll soccer" },
	features = {},
}

mod.features = {
	{
		name = "Reach",
		type = "slider",
		section = "Kick",
		min = 0,
		max = 200,
		default = 40,
		run = function(value)
			rt.reach = value
		end,
	},
	{
		name = "Power",
		type = "slider",
		section = "Kick",
		min = 5,
		max = 105,
		default = 100,
		run = function(value)
			rt.power = value / 100
		end,
	},
	{
		name = "Auto volley",
		type = "toggle",
		section = "Kick",
		default = false,
		run = function(state)
			rt.volley = state
			if rt.volleyConn then
				rt.volleyConn:Disconnect()
				rt.volleyConn = nil
			end
			if state then
				rt.volleyConn = RunService.Heartbeat:Connect(function()
					local now = os.clock()
					if now - (rt.volleyAt or 0) < 0.08 then
						return
					end
					rt.volleyAt = now
					volleyTick()
				end)
			end
		end,
	},
	{
		name = "Trajectory",
		type = "toggle",
		section = "Visual",
		default = false,
		run = function(state)
			rt.traj = state
			if rt.trajConn then
				rt.trajConn:Disconnect()
				rt.trajConn = nil
			end
			if state then
				rt.trajConn = RunService.Heartbeat:Connect(function()
					local now = os.clock()
					if now - (rt.trajAt or 0) < 0.05 then
						return
					end
					rt.trajAt = now
					trajTick()
				end)
			else
				hideTraj(1)
			end
		end,
	},
	{
		name = "Kick now",
		section = "Kick",
		run = function()
			local ok, err = fire("Laced", rt.power)
			if not ok then
				print("[Ascend rs] kick: " .. tostring(err))
			end
		end,
	},
}

function mod.cleanup()
	for _, conn in ipairs({ rt.volleyConn, rt.trajConn }) do
		if conn then
			pcall(function()
				conn:Disconnect()
			end)
		end
	end
	rt.volleyConn, rt.trajConn = nil, nil
	if rt.folder then
		rt.folder:Destroy()
	end
end

mod.fire = fire
mod.airborne = airborne

return mod
