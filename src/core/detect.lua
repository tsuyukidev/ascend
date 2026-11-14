local detect = {}

function detect.score(mod, placeId, gameName)
	local score = 0
	for _, id in ipairs(mod.placeIds or {}) do
		if tonumber(id) == placeId then
			score += 10
		end
	end
	local lower = string.lower(gameName)
	for _, keyword in ipairs(mod.match or {}) do
		if string.find(lower, string.lower(keyword), 1, true) then
			score += 3
		end
	end
	return score
end

function detect.order(modules)
	local placeId = game.PlaceId
	local gameName = game.Name or ""
	local ranked = {}
	for index, mod in ipairs(modules) do
		table.insert(ranked, { mod = mod, index = index, score = detect.score(mod, placeId, gameName) })
	end
	table.sort(ranked, function(a, b)
		if a.score == b.score then
			return a.index < b.index
		end
		return a.score > b.score
	end)
	local ordered, best = {}, nil
	for _, entry in ipairs(ranked) do
		table.insert(ordered, entry.mod)
		if not best and entry.score > 0 then
			best = entry
		end
	end
	return ordered, best
end

return detect
