local ui = __req("lib.ui")
local hub = __req("core.hub")

ui.notify("Test", "notify path")
ui.notify("Second", "stacking", 1)

for _, mod in ipairs(hub.modules) do
	for _, feature in ipairs(mod.features or {}) do
		local ok, err = pcall(feature.run, feature.type == "slider" and feature.default or true)
		if not ok then
			print("feature failed: " .. mod.name .. "." .. feature.name .. " -> " .. tostring(err))
			error("feature failed")
		end
	end
end

__H:unload()

local again = hub:start()
if not again then
	error("restart failed")
end
again:unload()

print("probe ok")
