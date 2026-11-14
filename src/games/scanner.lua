local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local HttpService = game:GetService("HttpService")

local mod = {
	name = "Scanner",
	icon = "",
	features = {},
}

local remoteClasses = {
	RemoteEvent = true,
	RemoteFunction = true,
	UnreliableRemoteEvent = true,
	BindableEvent = true,
}

local function pathOf(inst)
	local parts = { inst.Name }
	local node = inst.Parent
	while node and node ~= game do
		table.insert(parts, 1, node.Name)
		node = node.Parent
	end
	return table.concat(parts, "/")
end

local function collectRemotes()
	local found = {}
	local function walk(root, depth)
		if depth <= 0 then
			return
		end
		for _, child in ipairs(root:GetChildren()) do
			if remoteClasses[child.ClassName] then
				table.insert(found, { path = pathOf(child), class = child.ClassName })
			end
			pcall(walk, child, depth - 1)
		end
	end
	walk(ReplicatedStorage, 6)
	return found
end

local function collectTree(root, depth)
	local found = {}
	local function walk(node, level, prefix)
		if level > depth then
			return
		end
		for _, child in ipairs(node:GetChildren()) do
			local path = prefix .. "/" .. child.Name
			table.insert(found, { path = path, class = child.ClassName })
			if level < depth then
				walk(child, level + 1, path)
			end
		end
	end
	walk(root, 1, root.Name)
	return found
end

local function dump(payload, label)
	local ok, encoded = pcall(function()
		return HttpService:JSONEncode(payload)
	end)
	if not ok then
		encoded = tostring(payload.error)
	end
	local fileName = ("ascend/scan_%d_%s.json"):format(game.PlaceId, label)
	local wrote = false
	if type(writefile) == "function" then
		if type(makefolder) == "function" and type(isfolder) == "function" and not isfolder("ascend") then
			pcall(makefolder, "ascend")
		end
		wrote = pcall(writefile, fileName, encoded)
	end
	local lib = require("vendor.orion")
	if wrote then
		lib:MakeNotification({ Name = "Scan saved", Content = fileName, Time = 4 })
	else
		lib:MakeNotification({ Name = "Scan (no file api)", Content = label .. ", see console", Time = 4 })
	end
	print("[Ascend scan] " .. label .. " " .. game.PlaceId .. " " .. tostring(game.Name))
	print(encoded)
	return fileName
end

mod.features = {
	{
		name = "Dump remotes",
		section = "Scan",
		run = function()
			dump({
				game = game.Name,
				placeId = game.PlaceId,
				remotes = collectRemotes(),
			}, "remotes")
		end,
	},
	{
		name = "Dump trees",
		type = "dropdown",
		section = "Scan",
		options = { "Workspace", "ReplicatedStorage", "Lighting", "Teams" },
		default = "Workspace",
		persist = false,
		onLoad = false,
		run = function(service)
			local target = game:FindFirstChild(service)
			if not target then
				return
			end
			dump({
				game = game.Name,
				placeId = game.PlaceId,
				service = service,
				nodes = collectTree(target, 3),
			}, string.lower(service))
		end,
	},
	{
		name = "Dump players",
		section = "Scan",
		run = function()
			local roster = {}
			for _, player in ipairs(Players:GetPlayers()) do
				table.insert(roster, {
					name = player.Name,
					display = player.DisplayName,
					userId = player.UserId,
					character = player.Character and player.Character:FindFirstChildOfClass("Humanoid") ~= nil or false,
				})
			end
			dump({ game = game.Name, placeId = game.PlaceId, players = roster }, "players")
		end,
	},
	{
		name = "Where am I",
		section = "Scan",
		run = function()
			local info = {
				game = game.Name,
				placeId = game.PlaceId,
				jobId = game.JobId,
				players = #Players:GetPlayers(),
			}
			print("[Ascend] " .. HttpService:JSONEncode(info))
			require("vendor.orion"):MakeNotification({
				Name = tostring(game.Name),
				Content = ("place %d, %d players"):format(game.PlaceId, #Players:GetPlayers()),
				Time = 5,
			})
		end,
	},
}

return mod
