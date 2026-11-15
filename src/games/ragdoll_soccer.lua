local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local CollectionService = game:GetService("CollectionService")

local plr = Players.LocalPlayer

local rt = { on = false, goal = "Nearest", bound = false }

local function frames()
	return CollectionService:GetTagged("SoccerGoalFrame")
end

local function torso()
	local c = plr.Character
	return c and c:FindFirstChild("HumanoidRootPart")
end

local function pick()
	local list = frames()
	if #list == 0 then
		return nil
	end
	if rt.goal == "West" then
		for _, f in ipairs(list) do
			if f.Position.X > 0 then
				return f
			end
		end
	end
	if rt.goal == "East" then
		for _, f in ipairs(list) do
			if f.Position.X < 0 then
				return f
			end
		end
	end
	local root = torso()
	if not root then
		return list[1]
	end
	local best, dist = nil, nil
	for _, f in ipairs(list) do
		local d = (f.Position - root.Position).Magnitude
		if not dist or d < dist then
			best, dist = f, d
		end
	end
	return best
end

local function snap()
	local f = pick()
	local cam = workspace.CurrentCamera
	if not f or not cam then
		return
	end
	local target = Vector3.new(f.Position.X, f.Position.Y, f.Position.Z)
	local eye = cam.CFrame.Position
	if (target - eye).Magnitude < 1 then
		return
	end
	cam.CFrame = CFrame.lookAt(eye, target)
end

local function render()
	if rt.on then
		snap()
	end
end

local function start()
	if not rt.bound then
		RunService:BindToRenderStep("AscendGoalSnap", Enum.RenderPriority.Camera.Value + 5, render)
		rt.bound = true
	end
	rt.on = true
end

local function stop()
	rt.on = false
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
		name = "Goal snap",
		type = "toggle",
		section = "Aim",
		default = false,
		run = function(state)
			if state then
				start()
			else
				stop()
			end
		end,
	},
	{
		name = "Goal",
		type = "dropdown",
		section = "Aim",
		options = { "Nearest", "West", "East" },
		default = "Nearest",
		run = function(value)
			rt.goal = value
		end,
	},
}

function mod.cleanup()
	if rt.bound then
		RunService:UnbindFromRenderStep("AscendGoalSnap")
		rt.bound = false
	end
	rt.on = false
end

mod.pick = pick

return mod
