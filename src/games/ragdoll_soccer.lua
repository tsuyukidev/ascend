local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local plr = Players.LocalPlayer

local FAM = {
	Laced = { 46.94835680751174, 131.45539906103286, 0.03490658503988659, 0.15707963267948966 },
	Volley = { 56.33802816901409, 140.84507042253523, 0, 0.13962634015954636 },
	DivingHeader = { 46.94835680751174, 93.89671361502349, -0.13962634015954636, 0.10471975511965978 },
	Bicycle = { 70.42253521126761, 110.32863849765259, -0.13962634015954636, 0.10471975511965978 },
	JumpHeader = { 32.863849765258216, 75.11737089201878, -0.10471975511965977, 0.17453292519943295 },
}

local TRAJ_POINTS = 32

local rt = {
	power = 1,
	reach = 60,
	volley = false,
	traj = false,
	hookOld = nil,
	hookOn = false,
	last = 0,
	lastAuto = 0,
	kicks = 0,
	parts = {},
	folder = nil,
	conns = {},
}

local function netDir()
	local shared = ReplicatedStorage:FindFirstChild("Shared")
	return shared and shared:FindFirstChild("Net")
end

local function planRemote()
	local n = netDir()
	return n and n:FindFirstChild("RE/KickPlan")
end

local function ballPart()
	return workspace:FindFirstChild("Ball")
end

local function rootPart()
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

local function ballHeight(b)
	if not b then
		return 0
	end
	local ray = RaycastParams.new()
	ray.FilterType = Enum.RaycastFilterType.Exclude
	ray.FilterDescendantsInstances = { b, plr.Character }
	local hit = workspace:Raycast(b.Position, Vector3.new(0, -80, 0), ray)
	local gy = hit and hit.Position.Y or (b.Position.Y - b.Size.Y * 0.5)
	return b.Position.Y - gy - b.Size.Y * 0.5
end

local function pickFamily(h)
	if h >= 11 then
		return "JumpHeader"
	elseif h >= 6.9 then
		return "Bicycle"
	elseif h >= 2.4 then
		return "DivingHeader"
	elseif h >= 0.9 then
		return "Volley"
	end
	return "Laced"
end

local function shoot(b, family, power)
	local remote = planRemote()
	local r = rootPart()
	if not (remote and b and r) then
		return false, "missing"
	end
	local now = os.clock()
	if now - rt.last < 0.3 then
		return false, "cooldown"
	end
	rt.last = now
	local dir = aimDir()
	local st = workspace:GetServerTimeNow()
	rt.kicks = rt.kicks + 1
	remote:FireServer({
		id = math.random(100000, 999999),
		hold = false,
		leg = 1,
		t = st + 0.06,
		shift = Vector3.new(0, 0, 0),
		ball = b.Position,
		dir = dir,
		family = family or "Laced",
		power = power or rt.power,
		plant = b.Position - dir * 1.0,
		plantYaw = 0,
		plantAt = st,
	})
	return true
end

local function hook()
	if rt.hookOn then
		return true
	end
	local remote = planRemote()
	if not remote then
		return false
	end
	local old
	local ok = pcall(function()
		local fn = function(self, plan, ...)
			if getnamecallmethod() == "FireServer" and self == remote and typeof(plan) == "table" then
				plan.power = rt.power
				if rt.volley then
					local b = ballPart()
					if b then
						local h = ballHeight(b)
						if h > 1 then
							plan.family = pickFamily(h)
						end
					end
				end
			end
			return old(self, plan, ...)
		end
		if newcclosure then
			fn = newcclosure(fn)
		end
		old = hookmetamethod(game, "__namecall", fn)
	end)
	if not ok or not old then
		return false
	end
	rt.hookOld = old
	rt.hookOn = true
	return true
end

local function unhook()
	if not rt.hookOn or not rt.hookOld then
		rt.hookOn = false
		return
	end
	pcall(function()
		hookmetamethod(game, "__namecall", rt.hookOld)
	end)
	rt.hookOn = false
end

local function autoTick()
	if not rt.volley then
		return
	end
	local b = ballPart()
	if not b then
		return
	end
	local r = rootPart()
	if not r then
		return
	end
	local dist = (r.Position - b.Position).Magnitude
	if dist > rt.reach or dist < 1.2 then
		return
	end
	local h = ballHeight(b)
	if h < 1.3 then
		return
	end
	local vel = b.AssemblyLinearVelocity
	if vel.Magnitude < 3 then
		return
	end
	local toMe = flat(r.Position - b.Position)
	if toMe.Magnitude > 0.1 and vel:Dot(toMe.Unit) < 1 then
		return
	end
	if os.clock() - rt.lastAuto < 0.5 then
		return
	end
	rt.lastAuto = os.clock()
	shoot(b, pickFamily(h), rt.power)
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
	p.Size = Vector3.new(0.42, 0.42, 0.42)
	p.Material = Enum.Material.Neon
	p.Color = Color3.fromRGB(120, 255, 180)
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
	if not rt.traj then
		return
	end
	local b = ballPart()
	if not b then
		hideTraj(1)
		return
	end
	local h = ballHeight(b)
	local family = pickFamily(h)
	local spec = FAM[family] or FAM.Laced
	local p = math.clamp(rt.power, 0.05, 1.05)
	local speed = spec[1] + (spec[2] - spec[1]) * p
	local launch = spec[3] + (spec[4] - spec[3]) * p
	local dir = aimDir()
	local v = dir * (speed * math.cos(launch)) + Vector3.new(0, speed * math.sin(launch), 0)
	local g = Vector3.new(0, -(b:GetAttribute("Gravity") or 46), 0)
	local floor = b.Position.Y - h - b.Size.Y * 0.5
	local dt = 0.045
	local shown = 0
	for i = 1, TRAJ_POINTS do
		local t = i * dt
		local pos = b.Position + v * t + 0.5 * g * t * t
		if pos.Y < floor then
			break
		end
		local part = trajPart(i)
		part.Position = pos
		part.Transparency = 0.1 + (i / TRAJ_POINTS) * 0.65
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
		default = 60,
		unit = " studs",
		run = function(value)
			rt.reach = value
		end,
	},
	{
		name = "Power",
		type = "slider",
		section = "Kick",
		min = 30,
		max = 105,
		default = 100,
		unit = "%",
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
			hook()
		end,
	},
	{
		name = "Trajectory",
		type = "toggle",
		section = "Visual",
		default = false,
		run = function(state)
			rt.traj = state
			if not state then
				hideTraj(1)
			end
		end,
	},
	{
		name = "Kick now",
		section = "Kick",
		run = function()
			local b = ballPart()
			if not b then
				return
			end
			shoot(b, pickFamily(ballHeight(b)), rt.power)
		end,
	},
}

local function onInput(input, processed)
	if processed then
		return
	end
	if input.UserInputType ~= Enum.UserInputType.MouseButton1 then
		return
	end
	local b = ballPart()
	local r = rootPart()
	if not (b and r) then
		return
	end
	local dist = (r.Position - b.Position).Magnitude
	if dist <= 4 or dist > rt.reach then
		return
	end
	shoot(b, pickFamily(ballHeight(b)), rt.power)
end

function mod.autoRun()
	hook()
	table.insert(rt.conns, RunService.Heartbeat:Connect(function()
		if not rt.hookOn then
			hook()
		end
		autoTick()
	end))
	table.insert(rt.conns, RunService.RenderStepped:Connect(function()
		if rt.traj then
			trajTick()
		end
	end))
	table.insert(rt.conns, UserInputService.InputBegan:Connect(onInput))
end

function mod.cleanup()
	for _, c in ipairs(rt.conns) do
		pcall(function()
			c:Disconnect()
		end)
	end
	rt.conns = {}
	unhook()
	if rt.folder then
		rt.folder:Destroy()
		rt.folder = nil
	end
end

mod.shoot = shoot
mod.pickFamily = pickFamily
mod.height = ballHeight
mod.hook = hook
mod.onInput = onInput
mod.rt = rt

return mod
