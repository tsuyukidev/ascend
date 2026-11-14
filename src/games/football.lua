local ReplicatedStorage = game:GetService("ReplicatedStorage")
local HttpService = game:GetService("HttpService")

local mod = {
	name = "Football",
	icon = "",
	placeIds = {},
	match = { "football", "soccer", "futbol", "striker", "goalkeeper" },
	features = {},
}

local keywords = { "ball", "kick", "shoot", "pass", "tackle", "sprint", "dribble", "goal" }

local function pathOf(inst)
	local parts = { inst.Name }
	local node = inst.Parent
	while node and node ~= game do
		table.insert(parts, 1, node.Name)
		node = node.Parent
	end
	return table.concat(parts, "/")
end

local function hunt()
	local hits = {}
	local function walk(root, depth)
		if depth <= 0 then
			return
		end
		for _, child in ipairs(root:GetChildren()) do
			local name = string.lower(child.Name)
			for _, keyword in ipairs(keywords) do
				if string.find(name, keyword, 1, true) then
					table.insert(hits, { path = pathOf(child), class = child.ClassName })
					break
				end
			end
			pcall(walk, child, depth - 1)
		end
	end
	walk(ReplicatedStorage, 6)
	return hits
end

mod.features = {
	{
		name = "Hunt football remotes",
		section = "Recon",
		run = function()
			local hits = hunt()
			local payload = HttpService:JSONEncode({ game = game.Name, placeId = game.PlaceId, hits = hits })
			print("[Ascend football] " .. payload)
			local lib = require("vendor.orion")
			if type(writefile) == "function" then
				local path = ("ascend/scan_%d_football.json"):format(game.PlaceId)
				if pcall(writefile, path, payload) then
					lib:MakeNotification({ Name = "Recon saved", Content = path, Time = 4 })
					return
				end
			end
			lib:MakeNotification({ Name = "Recon", Content = #hits .. " remote hits, see console", Time = 4 })
		end,
	},
}

function mod.autoRun()
	print("[Ascend football] detected " .. game.Name .. " (" .. game.PlaceId .. ")")
end

return mod
