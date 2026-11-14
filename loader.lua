local url = "https://raw.githubusercontent.com/tsuyukidev/ascend/master/dist/hub.lua"

local ok, res = pcall(function()
	return loadstring(game:HttpGet(url))()
end)

if not ok then
	return warn("[Ascend] " .. tostring(res))
end

return res
