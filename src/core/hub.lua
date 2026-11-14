local ui = require("lib.ui")
local store = require("lib.store")

local hub = {
	name = "Ascend",
	version = "0.1.0",
	modules = {},
}

local function env()
	return (type(getgenv) == "function" and getgenv()) or _G
end

function hub:add(mod)
	table.insert(self.modules, mod)
	return mod
end

local function bind(mod, feature, sec)
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
			ui.notify(feature.name, tostring(err), 4)
		end
	end

	local kind = feature.type or "button"
	if kind == "toggle" then
		local saved = store.get(key, feature.default == true)
		if type(saved) ~= "boolean" then
			saved = feature.default == true
		end
		local ctl = sec:toggle(feature.name, saved, function(state)
			remember(state)
			fire(state)
		end)
		if saved then
			task.spawn(fire, true)
		end
		return ctl
	elseif kind == "slider" then
		local lo = feature.min or 0
		local hi = feature.max or 100
		local saved = store.get(key, feature.default or lo)
		if type(saved) ~= "number" then
			saved = feature.default or lo
		end
		return sec:slider(feature.name, lo, hi, saved, function(value)
			remember(value)
			fire(value)
		end)
	elseif kind == "dropdown" then
		local options = feature.options or {}
		local saved = store.get(key, feature.default or options[1])
		return sec:dropdown(feature.name, options, saved, function(value)
			remember(value)
			fire(value)
		end)
	elseif kind == "textbox" then
		local box = sec:textbox(feature.name, feature.placeholder, function(text, enter)
			if feature.run then
				fire(text, enter)
			end
		end)
		box.Text = tostring(store.get(key, ""))
		return box
	end
	return sec:button(feature.name, function()
		fire()
	end)
end

function hub:start(opts)
	opts = opts or {}
	local e = env()
	if type(e.Ascend) == "table" and type(e.Ascend.unload) == "function" then
		pcall(e.Ascend.unload, e.Ascend)
	end

	store.init()

	local win = ui.window({
		title = self.name,
		subtitle = opts.subtitle or ("v" .. self.version),
		width = opts.width,
		height = opts.height,
	})

	for _, mod in ipairs(self.modules) do
		local tab = win:tab(mod.name)
		if mod.init then
			local ok, err = pcall(mod.init, tab)
			if not ok then
				ui.notify("Module error", mod.name .. ": " .. tostring(err), 5)
			end
		end
		local current
		local function secFor(name)
			if not current or current.name ~= name then
				current = { name = name, sec = tab:section(name) }
			end
			return current.sec
		end
		local features = mod.features or {}
		if #features == 0 and not mod.init then
			secFor("General"):label("No features registered.")
		end
		for _, feature in ipairs(features) do
			bind(mod, feature, secFor(feature.section or "General"))
		end
		if mod.build then
			local ok, err = pcall(mod.build, tab)
			if not ok then
				ui.notify("Build error", mod.name .. ": " .. tostring(err), 5)
			end
		end
	end

	local htab = win:tab("Hub")
	local runner = htab:section("Runner")
	local lastUrl = ""
	runner:textbox("Script URL", "raw github url", function(text)
		lastUrl = text
	end)
	runner:button("Run URL", function()
		if lastUrl == "" then
			ui.notify("Ascend", "paste a url first", 2)
			return
		end
		local ok, src = pcall(function()
			return game:HttpGet(lastUrl)
		end)
		if not ok then
			ui.notify("Fetch failed", tostring(src), 4)
			return
		end
		local chunk = loadstring(src)
		if not chunk then
			ui.notify("Compile failed", "bad lua at " .. lastUrl, 4)
			return
		end
		local ran, err = pcall(chunk)
		if ran then
			ui.notify("Ran", lastUrl:match("([^/]+)$") or "script", 2)
		else
			ui.notify("Runtime error", tostring(err), 5)
		end
	end)

	local config = htab:section("Config")
	config:label("Saved to ascend/config.json")
	config:button("Save now", function()
		if store.flush() then
			ui.notify("Saved", "config written", 2)
		else
			ui.notify("No executor file api", "config kept in memory", 3)
		end
	end)
	config:button("Reset config", function()
		store.wipe()
		ui.notify("Reset", "restart the hub to apply", 3)
	end)

	local inst = { window = win, version = self.version }

	function inst:unload()
		for _, mod in ipairs(hub.modules) do
			if mod.cleanup then
				pcall(mod.cleanup)
			end
		end
		pcall(store.flush)
		win:destroy()
		local ev = env()
		if ev.Ascend == inst then
			ev.Ascend = nil
		end
	end

	config:button("Unload", function()
		inst:unload()
	end)
	config:button("Rerun hub", function()
		inst:unload()
		hub:start(opts)
	end)

	e.Ascend = inst
	return inst
end

return hub
