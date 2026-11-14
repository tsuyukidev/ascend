local OrionLib = require("vendor.orion")
local store = require("lib.store")

local hub = {
	name = "Ascend",
	version = "0.2.0",
	modules = {},
	accent = Color3.fromRGB(126, 108, 255),
}

local function env()
	return (type(getgenv) == "function" and getgenv()) or _G
end

local function notify(title, body, time)
	OrionLib:MakeNotification({
		Name = tostring(title),
		Content = tostring(body),
		Time = time or 3,
	})
end

hub.notify = notify

function hub:add(mod)
	table.insert(self.modules, mod)
	return mod
end

local function bind(mod, feature, target)
	local key = mod.name .. "." .. feature.name
	local pending
	local function remember(value)
		store.set(key, value)
		if pending then
			task.cancel(pending)
		end
		pending = task.delay(0.4, store.flush)
	end
	local function fire(...)
		if not feature.run then
			return
		end
		local ok, err = pcall(feature.run, ...)
		if not ok then
			notify(feature.name, err, 4)
		end
	end

	local kind = feature.type or "button"
	if kind == "toggle" then
		local saved = store.get(key, feature.default == true)
		if type(saved) ~= "boolean" then
			saved = feature.default == true
		end
		target:AddToggle({
			Name = feature.name,
			Default = saved,
			Color = feature.color or hub.accent,
			Callback = function(state)
				remember(state)
				fire(state)
			end,
		})
	elseif kind == "slider" then
		local lo = feature.min or 0
		local hi = feature.max or 100
		local saved = store.get(key, feature.default or lo)
		if type(saved) ~= "number" then
			saved = feature.default or lo
		end
		target:AddSlider({
			Name = feature.name,
			Min = lo,
			Max = hi,
			Default = saved,
			Increment = feature.step or 1,
			Color = feature.color or hub.accent,
			ValueName = feature.unit or "",
			Callback = function(value)
				remember(value)
				fire(value)
			end,
		})
	elseif kind == "dropdown" then
		local options = feature.options or {}
		local saved = store.get(key, feature.default or options[1])
		if not table.find(options, saved) then
			saved = options[1]
		end
		target:AddDropdown({
			Name = feature.name,
			Options = options,
			Default = saved,
			Callback = function(value)
				remember(value)
				fire(value)
			end,
		})
	elseif kind == "textbox" then
		target:AddTextbox({
			Name = feature.name,
			Default = tostring(store.get(key, "")),
			TextDisappear = false,
			Callback = function(text)
				remember(text)
				fire(text)
			end,
		})
	else
		target:AddButton({
			Name = feature.name,
			Callback = function()
				fire()
			end,
		})
	end
end

function hub:start(opts)
	opts = opts or {}
	local ev = env()
	if type(ev.Ascend) == "table" and type(ev.Ascend.unload) == "function" then
		pcall(ev.Ascend.unload, ev.Ascend)
	end

	store.init()

	local win = OrionLib:MakeWindow({
		Name = opts.title or (self.name .. " | v" .. self.version),
		ConfigFolder = "Ascend",
		SaveConfig = false,
		IntroEnabled = false,
		HidePremium = true,
		CloseCallback = function() end,
	})

	local inst = { window = win, version = self.version }

	function inst:unload()
		for _, mod in ipairs(hub.modules) do
			if mod.cleanup then
				pcall(mod.cleanup)
			end
		end
		pcall(store.flush)
		pcall(OrionLib.Destroy, OrionLib)
		local e = env()
		if e.Ascend == inst then
			e.Ascend = nil
		end
	end

	for _, mod in ipairs(self.modules) do
		local tab = win:MakeTab({
			Name = mod.name,
			Icon = mod.icon or "",
		})
		if mod.init then
			local ok, err = pcall(mod.init, tab)
			if not ok then
				notify("Module error", mod.name .. ": " .. tostring(err), 5)
			end
		end
		local current
		local function targetFor(name)
			if not current or current.name ~= name then
				current = { name = name, target = tab:AddSection({ Name = name }) }
			end
			return current.target
		end
		local features = mod.features or {}
		if #features == 0 and not mod.init then
			tab:AddLabel("No features registered.")
		end
		for _, feature in ipairs(features) do
			bind(mod, feature, targetFor(feature.section or "General"))
		end
		if mod.build then
			local ok, err = pcall(mod.build, tab)
			if not ok then
				notify("Build error", mod.name .. ": " .. tostring(err), 5)
			end
		end
	end

	local htab = win:MakeTab({ Name = "Hub", Icon = "" })
	local runner = htab:AddSection({ Name = "Runner" })
	local lastUrl = ""
	runner:AddTextbox({
		Name = "Script URL",
		Default = "",
		TextDisappear = false,
		Callback = function(text)
			lastUrl = text
		end,
	})
	runner:AddButton({
		Name = "Run URL",
		Callback = function()
			if lastUrl == "" then
				notify("Ascend", "paste a url first", 2)
				return
			end
			local ok, src = pcall(function()
				return game:HttpGet(lastUrl)
			end)
			if not ok then
				notify("Fetch failed", src, 4)
				return
			end
			local chunk = loadstring(src)
			if not chunk then
				notify("Compile failed", "bad lua at " .. lastUrl, 4)
				return
			end
			local ran, err = pcall(chunk)
			if ran then
				notify("Ran", lastUrl:match("([^/]+)$") or "script", 2)
			else
				notify("Runtime error", err, 5)
			end
		end,
	})

	local config = htab:AddSection({ Name = "Config" })
	config:AddParagraph("Storage", "ascend/config.json")
	config:AddButton({
		Name = "Save now",
		Callback = function()
			if store.flush() then
				notify("Saved", "config written", 2)
			else
				notify("No executor file api", "config kept in memory", 3)
			end
		end,
	})
	config:AddButton({
		Name = "Reset config",
		Callback = function()
			store.wipe()
			notify("Reset", "reinject to apply", 3)
		end,
	})
	config:AddButton({
		Name = "Unload",
		Callback = function()
			inst:unload()
		end,
	})

	local about = htab:AddSection({ Name = "About" })
	about:AddParagraph(
		self.name .. " v" .. self.version,
		#self.modules .. " modules loaded. getgenv().Ascend:unload() works too."
	)

	ev.Ascend = inst
	return inst
end

return hub
