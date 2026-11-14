local HttpService = game:GetService("HttpService")

local store = {}
local dir = "ascend"
local file = dir .. "/config.json"
local data = {}

local function canWrite()
	return type(writefile) == "function" and type(readfile) == "function" and type(isfile) == "function"
end

function store.init()
	if not canWrite() then
		return
	end
	pcall(function()
		if type(isfolder) == "function" and not isfolder(dir) then
			makefolder(dir)
		end
	end)
	local ok, raw = pcall(readfile, file)
	if not ok or type(raw) ~= "string" or raw == "" then
		return
	end
	local decoded, parsed = pcall(function()
		return HttpService:JSONDecode(raw)
	end)
	if decoded and type(parsed) == "table" then
		data = parsed
	end
end

function store.get(key, default)
	local v = data[key]
	if v == nil then
		return default
	end
	return v
end

function store.set(key, value)
	data[key] = value
end

function store.flush()
	if not canWrite() then
		return false
	end
	local ok = pcall(function()
		writefile(file, HttpService:JSONEncode(data))
	end)
	return ok
end

function store.wipe()
	data = {}
	store.flush()
end

function store.all()
	return data
end

return store
