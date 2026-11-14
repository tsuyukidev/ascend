local hub = require("core.hub")

for _, name in ipairs(__games or { "games.universal" }) do
	hub:add(require(name))
end

return hub:start()
