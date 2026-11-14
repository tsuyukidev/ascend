local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")

local plr = Players.LocalPlayer

local PLACES = { 17679534951, 17783527320, 18142610575, 71663447399044, 94080374434723 }

local rt = { tracker = nil, gui = nil, power = nil, target = "Auto" }

local function pitch()
	return workspace:FindFirstChild("Pitch")
end

local function ball()
	local balls = workspace:FindFirstChild("Balls")
	return balls and balls:FindFirstChild("Ball")
end

local function goal(name)
	local p = pitch()
	local goals = p and p:FindFirstChild("Goals")
	local g = goals and goals:FindFirstChild(name)
	if not g then
		return nil
	end
	if g:IsA("Model") then
		local ok, cf = pcall(function()
			return g:GetPivot()
		end)
		return ok and cf.Position or nil
	end
	return g.Position
end

local function aimPoint()
	local home, away = goal("Home"), goal("Away")
	if rt.target == "Home" then
		return home
	end
	if rt.target == "Away" then
		return away
	end
	local b = ball()
	if not b or not home or not away then
		return away
	end
	local dhome = (b.Position - home).Magnitude
	local daway = (b.Position - away).Magnitude
	return dhome < daway and home or away
end

local function char()
	return plr.Character
end

local function ownerOf(b)
	local o = b and b:FindFirstChild("Owner")
	return o and o.Value or nil
end

local function facePoint(p)
	local c = char()
	local hrp = c and c:FindFirstChild("HumanoidRootPart")
	if not hrp or not p then
		return
	end
	local flat = (p - hrp.Position) * Vector3.new(1, 0, 1)
	if flat.Magnitude < 0.01 then
		return
	end
	hrp.CFrame = CFrame.lookAt(hrp.Position, hrp.Position + flat.Unit)
end

local function makeGui()
	if rt.gui and rt.gui.Parent then
		return rt.gui
	end
	local parent = (type(gethui) == "function" and gethui()) or plr:FindFirstChild("PlayerGui") or plr:WaitForChild("PlayerGui")
	local gui = Instance.new("ScreenGui")
	gui.Name = "AscendOFA"
	gui.ResetOnSpawn = false
	gui.IgnoreGuiInset = true
	gui.DisplayOrder = 999
	local label = Instance.new("TextLabel")
	label.Name = "Ball"
	label.BackgroundTransparency = 0.35
	label.BackgroundColor3 = Color3.fromRGB(14, 14, 20)
	label.BorderSizePixel = 0
	label.AnchorPoint = Vector2.new(0, 1)
	label.Position = UDim2.new(0, 16, 1, -24)
	label.Size = UDim2.fromOffset(300, 26)
	label.Font = Enum.Font.GothamMedium
	label.TextSize = 13
	label.TextColor3 = Color3.fromRGB(220, 220, 235)
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.Text = "ball: waiting"
	label.Parent = gui
	gui.Parent = parent
	rt.gui = gui
	return gui
end

local function updateTracker()
	local gui = makeGui()
	local label = gui:FindFirstChild("Ball")
	local b = ball()
	if not label then
		return
	end
	if not b then
		label.Text = "ball: not spawned"
		return
	end
	local c = char()
	local hrp = c and c:FindFirstChild("HumanoidRootPart")
	local owner = ownerOf(b)
	local dist = hrp and ("%.0f"):format((b.Position - hrp.Position).Magnitude) or "?"
	local target = aimPoint()
	local gdist = target and ("%.0f"):format((target - b.Position).Magnitude) or "?"
	label.Text = ("ball %s | owner %s | %s studs | goal %s"):format(
		("%.0f, %.0f, %.0f"):format(b.Position.X, b.Position.Y, b.Position.Z),
		owner and owner.Name or "none",
		dist,
		gdist
	)
end

local function setTracker(state)
	if rt.tracker then
		rt.tracker:Disconnect()
		rt.tracker = nil
	end
	if state then
		makeGui()
		rt.tracker = RunService.Heartbeat:Connect(updateTracker)
		updateTracker()
	elseif rt.gui then
		rt.gui:Destroy()
		rt.gui = nil
	end
end

local function setPower(state)
	if rt.power then
		rt.power:Disconnect()
		rt.power = nil
	end
	if not state then
		return
	end
	rt.power = RunService.Heartbeat:Connect(function()
		local gui = plr:FindFirstChild("PlayerGui")
		local pb = gui and gui:FindFirstChild("Powerbar")
		local bar = pb and pb:FindFirstChild("Bar")
		local lb = bar and bar:FindFirstChild("LoadingBar")
		if lb and lb.Size.X.Scale ~= 0 then
			lb.Size = UDim2.new(0, 0, lb.Size.Y.Scale, lb.Size.Y.Offset)
		end
	end)
end

local function shoot(speed, lift)
	local b = ball()
	local c = char()
	local hrp = c and c:FindFirstChild("HumanoidRootPart")
	local target = aimPoint()
	if not b or not hrp or not target then
		return false, "no ball"
	end
	if (b.Position - hrp.Position).Magnitude > 30 then
		return false, "ball too far"
	end
	local flat = (target - b.Position) * Vector3.new(1, 0, 1)
	if flat.Magnitude < 1 then
		return false, "no direction"
	end
	local bv = Instance.new("BodyVelocity")
	bv.Velocity = flat.Unit * speed + Vector3.new(0, lift, 0)
	bv.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
	bv.Parent = b
	ReplicatedStorage.ChangeOwner:FireServer(
		b,
		b:GetAttribute("ReactSession"),
		b.Position,
		b.Velocity.Magnitude,
		bv.Velocity.Magnitude,
		0.4,
		false,
		"Shoot",
		999
	)
	task.delay(0.45, function()
		if bv and bv.Parent then
			bv:Destroy()
		end
	end)
	return true
end

local mod = {
	name = "OFA Football",
	icon = "",
	placeIds = PLACES,
	match = { "[ofa]", "ofa", "match pitch", "official football association" },
	features = {},
}

mod.features = {
	{
		name = "Ball tracker",
		type = "toggle",
		section = "Ball",
		run = function(state)
			setTracker(state)
		end,
	},
	{
		name = "Target goal",
		type = "dropdown",
		section = "Ball",
		options = { "Auto", "Home", "Away" },
		default = "Auto",
		run = function(value)
			rt.target = value
		end,
	},
	{
		name = "Face goal",
		section = "Ball",
		run = function()
			local p = aimPoint()
			if p then
				facePoint(p)
			end
		end,
	},
	{
		name = "Max power",
		type = "toggle",
		section = "Shot",
		run = function(state)
			setPower(state)
		end,
	},
	{
		name = "Shot speed",
		type = "slider",
		section = "Shot",
		min = 45,
		max = 240,
		default = 110,
		run = function(value)
			rt.speed = value
		end,
	},
	{
		name = "Shot lift",
		type = "slider",
		section = "Shot",
		min = 0,
		max = 60,
		default = 18,
		run = function(value)
			rt.lift = value
		end,
	},
	{
		name = "Force shot",
		section = "Shot",
		run = function()
			local ok, err = shoot(rt.speed or 110, rt.lift or 18)
			if not ok then
				print("[Ascend ofa] force shot: " .. tostring(err))
			end
		end,
	},
}

function mod.autoRun()
	rt.speed = rt.speed or 110
	rt.lift = rt.lift or 18
	print("[Ascend ofa] " .. game.Name .. " (" .. game.PlaceId .. ")")
end

mod.shoot = shoot
mod.aimPoint = aimPoint

return mod
