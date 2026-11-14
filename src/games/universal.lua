local Players = game:GetService("Players")
local Lighting = game:GetService("Lighting")
local UserInputService = game:GetService("UserInputService")
local VirtualUser = game:GetService("VirtualUser")
local store = require("lib.store")

local plr = Players.LocalPlayer

local function humanoid()
	local char = plr.Character
	return char and char:FindFirstChildOfClass("Humanoid")
end

local runtime = {
	conns = {},
	afk = nil,
	brightness = nil,
	fog = nil,
}

local function track(conn)
	table.insert(runtime.conns, conn)
	return conn
end

local mod = {
	name = "Universal",
	features = {},
}

mod.features = {
	{
		name = "WalkSpeed",
		type = "slider",
		section = "Movement",
		min = 16,
		max = 300,
		default = 16,
		run = function(value)
			local hum = humanoid()
			if hum then
				hum.WalkSpeed = value
			end
		end,
	},
	{
		name = "JumpPower",
		type = "slider",
		section = "Movement",
		min = 50,
		max = 400,
		default = 50,
		run = function(value)
			local hum = humanoid()
			if hum then
				hum.UseJumpPower = true
				hum.JumpPower = value
			end
		end,
	},
	{
		name = "Infinite Jump",
		type = "toggle",
		section = "Movement",
		run = function(state)
			if state then
				runtime.jump = track(UserInputService.JumpRequest:Connect(function()
					local hum = humanoid()
					if hum then
						hum:ChangeState(Enum.HumanoidStateType.Jumping)
					end
				end))
			elseif runtime.jump then
				pcall(function()
					runtime.jump:Disconnect()
				end)
				runtime.jump = nil
			end
		end,
	},
	{
		name = "Reset Character",
		section = "Movement",
		run = function()
			local hum = humanoid()
			if hum then
				hum.Health = 0
			end
		end,
	},
	{
		name = "Fullbright",
		type = "toggle",
		section = "Visuals",
		run = function(state)
			if state then
				runtime.brightness = Lighting.Brightness
				Lighting.Brightness = 3
				Lighting.ClockTime = 14
				Lighting.GlobalShadows = false
				Lighting.FogEnd = 1e6
			else
				Lighting.Brightness = runtime.brightness or 2
				Lighting.GlobalShadows = true
			end
		end,
	},
	{
		name = "Remove Fog",
		type = "toggle",
		section = "Visuals",
		run = function(state)
			if state then
				runtime.fog = Lighting.FogEnd
				Lighting.FogEnd = 1e6
			else
				Lighting.FogEnd = runtime.fog or 100000
			end
		end,
	},
	{
		name = "Anti AFK",
		type = "toggle",
		section = "Utility",
		run = function(state)
			if state then
				runtime.afk = task.spawn(function()
					while true do
						task.wait(30)
						pcall(function()
							VirtualUser:CaptureController()
							VirtualUser:ClickButton1(Vector2.new(0, 0))
						end)
					end
				end)
			elseif runtime.afk then
				task.cancel(runtime.afk)
				runtime.afk = nil
			end
		end,
	},
	{
		name = "Server Hop",
		section = "Utility",
		run = function()
			local ok, err = pcall(function()
				local placeId = game.PlaceId
				local url = ("https://games.roblox.com/v1/games/%d/servers/Public?limit=100"):format(placeId)
				local res = game:HttpGet(url)
				local body = game:GetService("HttpService"):JSONDecode(res)
				local servers = body and body.data or {}
				for _, srv in ipairs(servers) do
					if srv.id ~= game.JobId and srv.playing < srv.maxPlayers then
						game:GetService("TeleportService"):TeleportToPlaceInstance(placeId, srv.id, plr)
						return
					end
				end
				error("no open server found")
			end)
			if not ok then
				require("vendor.orion"):MakeNotification({
					Name = "Server Hop",
					Content = tostring(err),
					Time = 3,
				})
			end
		end,
	},
}

function mod.init()
	plr.CharacterAdded:Connect(function()
		task.wait(0.6)
		local hum = humanoid()
		if not hum then
			return
		end
		hum.WalkSpeed = store.get("Universal.WalkSpeed", 16)
		hum.UseJumpPower = true
		hum.JumpPower = store.get("Universal.JumpPower", 50)
	end)
end

function mod.cleanup()
	for _, conn in ipairs(runtime.conns) do
		pcall(function()
			conn:Disconnect()
		end)
	end
	runtime.conns = {}
	if runtime.afk then
		task.cancel(runtime.afk)
		runtime.afk = nil
	end
	local hum = humanoid()
	if hum then
		hum.WalkSpeed = 16
		hum.JumpPower = 50
	end
	Lighting.Brightness = runtime.brightness or 2
	Lighting.FogEnd = runtime.fog or 100000
	Lighting.GlobalShadows = true
end

return mod
