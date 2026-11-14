local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local plr = Players.LocalPlayer
local UpdatePing = ReplicatedStorage:WaitForChild("UpdatePing")

local rt = { reach = 0, base = {}, conn = nil, guard = false }

local function char()
	return plr.Character
end

local function blockReports()
	if rt.guard then
		return
	end
	if type(hookmetamethod) ~= "function" or type(getrawmetatable) ~= "function" then
		return
	end
	local mt = getrawmetatable(game)
	if not mt or type(mt.__namecall) ~= "function" then
		return
	end
	local old = mt.__namecall
	local wrap = type(newcclosure) == "function" and newcclosure or function(f)
		return f
	end
	if type(setreadonly) == "function" then
		pcall(setreadonly, mt, false)
	end
	mt.__namecall = wrap(function(self, ...)
		if type(checkcaller) ~= "function" or not checkcaller() then
			if getnamecallmethod() == "FireServer" and self == UpdatePing then
				local a = { ... }
				if type(a[1]) == "string" and string.find(a[1], "Exploiting", 1, true) then
					return
				end
			end
		end
		return old(self, ...)
	end)
	if type(setreadonly) == "function" then
		pcall(setreadonly, mt, true)
	end
	rt.guard = true
end

local function applyReach()
	local c = char()
	if not c then
		return
	end
	local r = rt.reach
	for _, name in ipairs({ "RL", "LL" }) do
		local p = c:FindFirstChild(name)
		if p and p:IsA("BasePart") then
			local base = rt.base[p]
			if not base then
				base = p.Size
				rt.base[p] = base
			end
			local want = Vector3.new(base.X, base.Y, base.Z + r * 2)
			if p.Size ~= want then
				p.Size = want
			end
		end
	end
end

local function setReach(value)
	rt.reach = value or 0
	if rt.conn then
		rt.conn:Disconnect()
		rt.conn = nil
	end
	if rt.reach > 0 then
		blockReports()
		applyReach()
		rt.conn = RunService.Heartbeat:Connect(applyReach)
	else
		for part, base in pairs(rt.base) do
			if part.Parent then
				part.Size = base
			end
		end
		rt.base = {}
	end
end

local mod = {
	name = "OFA Football",
	icon = "",
	placeIds = { 17679534951, 17783527320, 18142610575, 71663447399044, 94080374434723 },
	match = { "[ofa]", "ofa", "match pitch", "official football association" },
	features = {},
}

mod.features = {
	{
		name = "Reach",
		type = "slider",
		section = "Reach",
		min = 0,
		max = 14,
		default = 0,
		step = 0.5,
		run = function(value)
			setReach(value)
		end,
	},
}

function mod.autoRun()
	plr.CharacterAdded:Connect(function()
		task.wait(0.5)
		rt.base = {}
		if rt.reach > 0 then
			applyReach()
		end
	end)
end

return mod
