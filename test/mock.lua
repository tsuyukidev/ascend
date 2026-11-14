local function event()
	local e = {}
	function e:Connect()
		return { Disconnect = function() end }
	end
	function e:Wait() end
	function e:Once()
		return { Disconnect = function() end }
	end
	return e
end

local Inst = {}
Inst.__index = function(t, k)
	if k == "Destroy" then
		return function(self)
			self.__dead = true
		end
	elseif k == "FindFirstChildOfClass" then
		return function()
			return nil
		end
	elseif k == "GetChildren" then
		return function()
			return {}
		end
	elseif k == "GetPropertyChangedSignal" then
		return function()
			return event()
		end
	elseif k == "IsA" then
		return function()
			return false
		end
	elseif k == "FindFirstChild" then
		return function()
			return nil
		end
	elseif k == "WaitForChild" then
		return function(self, name)
			local c = setmetatable({ ClassName = name }, Inst)
			c.Parent = self
			return c
		end
	elseif k == "GetDescendants" then
		return function()
			return {}
		end
	elseif k == "IsDescendantOf" then
		return function()
			return false
		end
	end
	return event()
end
Inst.__newindex = function(t, k, v)
	rawset(t, k, v)
end

Instance = {}
function Instance.new(class, parent)
	local o = setmetatable({ ClassName = class }, Inst)
	if parent then
		o.Parent = parent
	end
	return o
end

local services = {}
game = { PlaceId = 1, JobId = "job" }
function game:GetService(name)
	if name == "TweenService" then
		return {
			Create = function(_, _, _, _)
				return {
					Play = function() end,
					Cancel = function() end,
				}
			end,
		}
	end
	if not services[name] then
		services[name] = setmetatable({ ClassName = name }, Inst)
	end
	return services[name]
end

Enum = setmetatable({}, {
	__index = function(_, k)
		return setmetatable({}, {
			__index = function(_, v)
				return tostring(k) .. "." .. tostring(v)
			end,
		})
	end,
})

UDim = { new = function(s, o) return { Scale = s, Offset = o } end }
UDim2 = {
	new = function(xs, xo, ys, yo)
		return { X = { Scale = xs, Offset = xo }, Y = { Scale = ys, Offset = yo } }
	end,
	fromOffset = function(x, y) return UDim2.new(0, x, 0, y) end,
	fromScale = function(x, y) return UDim2.new(x, 0, y, 0) end,
}
Vector2 = {
	new = function(x, y) return { X = x, Y = y } end,
}
Color3 = {
	fromRGB = function(r, g, b) return { R = r, G = g, B = b } end,
}
TweenInfo = { new = function() return {} end }

task = {
	spawn = function(f, ...)
		local co = coroutine.create(f)
		local ok, err = coroutine.resume(co, ...)
		if not ok then
			print("[mock] task.spawn error: " .. tostring(err))
		end
		return co
	end,
	delay = function(_, _) return nil end,
	wait = function()
		coroutine.yield()
	end,
	cancel = function() end,
	defer = function(f, ...) task.spawn(f, ...) end,
}

warn = function(...) print("[warn]", ...) end
typeof = typeof or type

local genv = {}
getgenv = function()
	return genv
end
