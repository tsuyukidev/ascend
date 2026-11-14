local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local Players = game:GetService("Players")

local theme = {
	bg = Color3.fromRGB(17, 17, 21),
	side = Color3.fromRGB(23, 23, 29),
	panel = Color3.fromRGB(31, 31, 39),
	hover = Color3.fromRGB(41, 41, 51),
	stroke = Color3.fromRGB(45, 45, 57),
	text = Color3.fromRGB(235, 235, 242),
	dim = Color3.fromRGB(142, 142, 158),
	accent = Color3.fromRGB(126, 108, 255),
	ok = Color3.fromRGB(96, 200, 128),
}

local ui = { theme = theme }

local function mk(class, props, parent)
	local inst = Instance.new(class)
	for k, v in pairs(props or {}) do
		inst[k] = v
	end
	if parent then
		inst.Parent = parent
	end
	return inst
end

local function merge(base, extra)
	for k, v in pairs(extra or {}) do
		base[k] = v
	end
	return base
end

local function round(r, parent)
	return mk("UICorner", { CornerRadius = UDim.new(0, r) }, parent)
end

local function pad(p, parent)
	return mk("UIPadding", {
		PaddingLeft = UDim.new(0, p),
		PaddingRight = UDim.new(0, p),
		PaddingTop = UDim.new(0, p),
		PaddingBottom = UDim.new(0, p),
	}, parent)
end

local function stroke(parent, color)
	return mk("UIStroke", { Color = color or theme.stroke, Thickness = 1 }, parent)
end

local function tween(inst, props, time)
	local tw = TweenService:Create(inst, TweenInfo.new(time or 0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), props)
	tw:Play()
	return tw
end

local function label(props, parent)
	local base = {
		BackgroundTransparency = 1,
		Font = Enum.Font.GothamMedium,
		TextColor3 = theme.text,
		TextSize = 13,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextYAlignment = Enum.TextYAlignment.Center,
	}
	return mk("TextLabel", merge(base, props), parent)
end

local function hover(btn, base, target)
	btn.MouseEnter:Connect(function()
		tween(btn, { BackgroundColor3 = target or theme.hover }, 0.12)
	end)
	btn.MouseLeave:Connect(function()
		tween(btn, { BackgroundColor3 = base }, 0.12)
	end)
end

local noticeGui
local notices = {}

local function relayout()
	for i, item in ipairs(notices) do
		if item.frame.Parent then
			tween(item.frame, { Position = UDim2.new(1, -292, 0, 12 + (i - 1) * 68) }, 0.15)
		end
	end
end

function ui.clearNotices()
	if noticeGui then
		noticeGui:Destroy()
		noticeGui = nil
	end
	notices = {}
end

function ui.root()
	if ui.gui and ui.gui.Parent ~= nil then
		return ui.gui
	end
	local gui = mk("ScreenGui", {
		Name = "Ascend",
		ResetOnSpawn = false,
		IgnoreGuiInset = true,
		DisplayOrder = 99,
		ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
	})
	local ok = pcall(function()
		if type(gethui) == "function" then
			gui.Parent = gethui()
			return
		end
		if type(syn) == "table" and type(syn.protect_gui) == "function" then
			syn.protect_gui(gui)
		end
		gui.Parent = game:GetService("CoreGui")
	end)
	if not ok then
		gui.Parent = Players.LocalPlayer:WaitForChild("PlayerGui")
	end
	ui.gui = gui
	noticeGui = nil
	return gui
end

function ui.notify(title, body, duration)
	local gui = ui.gui or ui.root()
	if not noticeGui then
		noticeGui = mk("Frame", {
			Name = "Notices",
			Size = UDim2.new(0, 288, 1, 0),
			BackgroundTransparency = 1,
			Position = UDim2.new(1, -292, 0, 0),
			ZIndex = 50,
		}, gui)
	end
	local dur = duration or 3
	local frame = mk("TextButton", {
		Size = UDim2.fromOffset(288, 60),
		Position = UDim2.new(1, 40, 0, 12),
		BackgroundColor3 = theme.panel,
		BorderSizePixel = 0,
		Text = "",
		AutoButtonColor = false,
		ZIndex = 51,
	}, noticeGui)
	round(8, frame)
	stroke(frame, theme.accent)
	label({
		Text = tostring(title),
		Font = Enum.Font.GothamBold,
		Size = UDim2.new(1, -24, 0, 18),
		Position = UDim2.fromOffset(12, 9),
		ZIndex = 52,
	}, frame)
	label({
		Text = tostring(body or ""),
		TextColor3 = theme.dim,
		TextSize = 12,
		TextWrapped = true,
		TextYAlignment = Enum.TextYAlignment.Top,
		Size = UDim2.new(1, -24, 0, 26),
		Position = UDim2.fromOffset(12, 27),
		ZIndex = 52,
	}, frame)

	local item = { frame = frame }
	table.insert(notices, item)
	relayout()

	local closed = false
	local function close()
		if closed then
			return
		end
		closed = true
		local i = table.find(notices, item)
		if i then
			table.remove(notices, i)
		end
		tween(frame, { Position = UDim2.new(1, 320, 0, frame.Position.Y.Offset), BackgroundTransparency = 1 }, 0.15)
		task.delay(0.2, function()
			frame:Destroy()
		end)
		relayout()
	end
	frame.MouseButton1Click:Connect(close)
	task.delay(dur, close)
	return close
end

function ui.window(opts)
	opts = opts or {}
	local gui = opts.root or ui.root()
	ui.gui = gui
	local win = { tabs = {} }

	local frame = mk("Frame", {
		Name = "Window",
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromOffset(opts.width or 604, opts.height or 408),
		BackgroundColor3 = theme.bg,
		BorderSizePixel = 0,
		ClipsDescendants = true,
	}, gui)
	round(10, frame)
	stroke(frame)

	local top = mk("Frame", {
		Size = UDim2.new(1, 0, 0, 46),
		BackgroundColor3 = theme.side,
		BorderSizePixel = 0,
	}, frame)
	mk("Frame", {
		Size = UDim2.new(1, 0, 0, 12),
		Position = UDim2.new(0, 0, 1, -12),
		BackgroundColor3 = theme.side,
		BorderSizePixel = 0,
	}, top)
	round(10, top)
	mk("Frame", {
		Size = UDim2.new(1, 0, 0, 1),
		Position = UDim2.new(0, 0, 1, -1),
		BackgroundColor3 = theme.stroke,
		BorderSizePixel = 0,
	}, top)

	label({
		Text = opts.title or "Hub",
		Font = Enum.Font.GothamBold,
		TextSize = 15,
		Size = UDim2.new(0, 240, 0, 20),
		Position = UDim2.fromOffset(16, 8),
		TextTruncate = Enum.TextTruncate.AtEnd,
	}, top)
	label({
		Text = opts.subtitle or "",
		TextColor3 = theme.dim,
		TextSize = 11,
		Size = UDim2.new(0, 240, 0, 14),
		Position = UDim2.fromOffset(16, 26),
		TextTruncate = Enum.TextTruncate.AtEnd,
	}, top)

	local close = mk("TextButton", {
		Size = UDim2.fromOffset(26, 26),
		Position = UDim2.new(1, -34, 0, 10),
		BackgroundColor3 = theme.panel,
		Text = "×",
		Font = Enum.Font.GothamBold,
		TextSize = 16,
		TextColor3 = theme.dim,
		AutoButtonColor = false,
	}, top)
	round(6, close)
	hover(close, theme.panel)

	local min = mk("TextButton", {
		Size = UDim2.fromOffset(26, 26),
		Position = UDim2.new(1, -64, 0, 10),
		BackgroundColor3 = theme.panel,
		Text = "–",
		Font = Enum.Font.GothamBold,
		TextSize = 16,
		TextColor3 = theme.dim,
		AutoButtonColor = false,
	}, top)
	round(6, min)
	hover(min, theme.panel)

	local side = mk("Frame", {
		Size = UDim2.new(0, 154, 1, -47),
		Position = UDim2.fromOffset(0, 47),
		BackgroundColor3 = theme.side,
		BorderSizePixel = 0,
	}, frame)
	mk("ScrollingFrame", {
		Name = "Tabs",
		Size = UDim2.new(1, -16, 1, -16),
		Position = UDim2.fromOffset(8, 8),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		ScrollBarThickness = 0,
		CanvasSize = UDim2.new(),
	}, side)
	local tabHost = side.Tabs
	local tabLayout = mk("UIListLayout", {
		Padding = UDim.new(0, 4),
		SortOrder = Enum.SortOrder.LayoutOrder,
	}, tabHost)
	tabLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
		tabHost.CanvasSize = UDim2.new(0, 0, 0, tabLayout.AbsoluteContentSize.Y + 8)
	end)

	local content = mk("Frame", {
		Size = UDim2.new(1, -154, 1, -47),
		Position = UDim2.fromOffset(154, 47),
		BackgroundColor3 = theme.bg,
		ClipsDescendants = true,
	}, frame)

	local dragging, dragStart, startPos
	top.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			dragging = true
			dragStart = input.Position
			startPos = frame.Position
			input.Changed:Connect(function()
				if input.UserInputState == Enum.UserInputState.End then
					dragging = false
				end
			end)
		end
	end)
	UserInputService.InputChanged:Connect(function(input)
		if not dragging then
			return
		end
		if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
			local delta = input.Position - dragStart
			frame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
		end
	end)

	local minimized = false
	local fullHeight = frame.Size
	min.MouseButton1Click:Connect(function()
		minimized = not minimized
		local h = fullHeight
		tween(frame, { Size = minimized and UDim2.new(h.X.Scale, h.X.Offset, 0, 47) or h }, 0.2)
		content.Visible = not minimized
		side.Visible = not minimized
	end)
	close.MouseButton1Click:Connect(function()
		win:destroy()
	end)

	function win:tab(name)
		local btn = mk("TextButton", {
			Size = UDim2.new(1, 0, 0, 32),
			BackgroundColor3 = theme.side,
			Text = "",
			AutoButtonColor = false,
			BorderSizePixel = 0,
		}, tabHost)
		round(6, btn)
		local txt = label({
			Text = name,
			Position = UDim2.fromOffset(12, 0),
			Size = UDim2.new(1, -24, 1, 0),
			TextTruncate = Enum.TextTruncate.AtEnd,
		}, btn)
		local marker = mk("Frame", {
			Size = UDim2.new(0, 3, 0, 16),
			Position = UDim2.new(0, 0, 0.5, 0),
			AnchorPoint = Vector2.new(0, 0.5),
			BackgroundColor3 = theme.accent,
			BorderSizePixel = 0,
			Visible = false,
		}, btn)
		round(2, marker)

		local page = mk("ScrollingFrame", {
			Name = name,
			Size = UDim2.new(1, 0, 1, 0),
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			ScrollBarThickness = 4,
			ScrollBarImageColor3 = theme.stroke,
			CanvasSize = UDim2.new(),
			Visible = false,
			ScrollingDirection = Enum.ScrollingDirection.Y,
		}, content)
		pad(8, page)
		local pageLayout = mk("UIListLayout", {
			Padding = UDim.new(0, 10),
			SortOrder = Enum.SortOrder.LayoutOrder,
		}, page)
		pageLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
			page.CanvasSize = UDim2.new(0, 0, 0, pageLayout.AbsoluteContentSize.Y + 16)
		end)

		local tab = { name = name, page = page }

		local function activate()
			if win.active == tab then
				return
			end
			if win.active then
				win.active.page.Visible = false
				tween(win.active.btn, { BackgroundColor3 = theme.side }, 0.12)
				win.active.btn.TextLabel.TextColor3 = theme.dim
				win.active.marker.Visible = false
			end
			win.active = tab
			page.Visible = true
			tween(btn, { BackgroundColor3 = theme.panel }, 0.12)
			txt.TextColor3 = theme.text
			marker.Visible = true
		end
		txt.TextColor3 = theme.dim
		btn.MouseButton1Click:Connect(activate)
		btn.MouseEnter:Connect(function()
			if win.active ~= tab then
				tween(btn, { BackgroundColor3 = theme.hover }, 0.12)
			end
		end)
		btn.MouseLeave:Connect(function()
			if win.active ~= tab then
				tween(btn, { BackgroundColor3 = theme.side }, 0.12)
			end
		end)

		tab.btn = btn
		txt.Parent = btn

		function tab:section(title)
			local sec = mk("Frame", {
				Size = UDim2.new(1, 0, 0, 0),
				BackgroundTransparency = 1,
				AutomaticSize = Enum.AutomaticSize.Y,
			}, page)
			if title then
				label({
					Text = title,
					Font = Enum.Font.GothamBold,
					TextSize = 11,
					TextColor3 = theme.dim,
					Size = UDim2.new(1, 0, 0, 18),
				}, sec)
			end
			local body = mk("Frame", {
				Size = UDim2.new(1, 0, 0, 0),
				Position = UDim2.fromOffset(0, title and 22 or 0),
				BackgroundTransparency = 1,
				AutomaticSize = Enum.AutomaticSize.Y,
			}, sec)
			mk("UIListLayout", {
				Padding = UDim.new(0, 6),
				SortOrder = Enum.SortOrder.LayoutOrder,
			}, body)
			local self = { frame = sec, body = body }
			local rowIndex = 0
			local function nextRow(size, class, props)
				rowIndex += 1
				local row = mk(class or "Frame", merge({
					Size = UDim2.new(1, 0, 0, size),
					BackgroundColor3 = theme.panel,
					BorderSizePixel = 0,
					LayoutOrder = rowIndex,
				}, props), body)
				round(6, row)
				return row
			end

			function self:label(text)
				local row = nextRow(20, "Frame", { BackgroundTransparency = 1 })
				label({
					Text = text,
					TextColor3 = theme.dim,
					TextSize = 12,
					TextWrapped = true,
					AutomaticSize = Enum.AutomaticSize.Y,
					Size = UDim2.new(1, 0, 0, 0),
				}, row)
				return row
			end

			function self:button(text, cb)
				local row = nextRow(34, "TextButton", { Text = "", AutoButtonColor = false })
				label({
					Text = text,
					Size = UDim2.new(1, -24, 1, 0),
					Position = UDim2.fromOffset(12, 0),
					TextTruncate = Enum.TextTruncate.AtEnd,
				}, row)
				hover(row, theme.panel)
				row.MouseButton1Click:Connect(function()
					task.spawn(cb)
				end)
				return row
			end

			function self:toggle(text, default, cb)
				local state = default and true or false
				local row = nextRow(34, "Frame")
				label({
					Text = text,
					Size = UDim2.new(1, -70, 1, 0),
					Position = UDim2.fromOffset(12, 0),
					TextTruncate = Enum.TextTruncate.AtEnd,
				}, row)
				local pill = mk("TextButton", {
					Size = UDim2.fromOffset(38, 20),
					Position = UDim2.new(1, -50, 0.5, 0),
					AnchorPoint = Vector2.new(0, 0.5),
					BackgroundColor3 = theme.stroke,
					Text = "",
					AutoButtonColor = false,
					BorderSizePixel = 0,
				}, row)
				round(99, pill)
				local knob = mk("Frame", {
					Size = UDim2.fromOffset(14, 14),
					Position = UDim2.new(0, 3, 0.5, 0),
					AnchorPoint = Vector2.new(0, 0.5),
					BackgroundColor3 = Color3.fromRGB(255, 255, 255),
					BorderSizePixel = 0,
				}, pill)
				round(99, knob)
				local ctl = {}
				local function render(anim)
					local goal = UDim2.new(0, state and 21 or 3, 0.5, 0)
					if anim then
						tween(knob, { Position = goal }, 0.12)
						tween(pill, { BackgroundColor3 = state and theme.accent or theme.stroke }, 0.12)
					else
						knob.Position = goal
						pill.BackgroundColor3 = state and theme.accent or theme.stroke
					end
				end
				render(false)
				function ctl:get()
					return state
				end
				function ctl:set(v, fire)
					state = v and true or false
					render(true)
					if fire and cb then
						task.spawn(cb, state)
					end
				end
				pill.MouseButton1Click:Connect(function()
					ctl:set(not state, true)
				end)
				return ctl
			end

			function self:slider(text, minValue, maxValue, default, cb)
				local value = math.clamp(default or minValue, minValue, maxValue)
				local row = nextRow(46, "Frame")
				label({
					Text = text,
					Size = UDim2.new(1, -70, 0, 18),
					Position = UDim2.fromOffset(12, 6),
					TextTruncate = Enum.TextTruncate.AtEnd,
				}, row)
				local readout = label({
					Text = tostring(value),
					TextColor3 = theme.dim,
					TextSize = 12,
					TextXAlignment = Enum.TextXAlignment.Right,
					Size = UDim2.new(0, 54, 0, 18),
					Position = UDim2.new(1, -66, 0, 6),
				}, row)
				local track = mk("TextButton", {
					Size = UDim2.new(1, -24, 0, 6),
					Position = UDim2.fromOffset(12, 32),
					BackgroundColor3 = theme.stroke,
					Text = "",
					AutoButtonColor = false,
					BorderSizePixel = 0,
				}, row)
				round(99, track)
				local fill = mk("Frame", {
					Size = UDim2.new(0, 0, 1, 0),
					BackgroundColor3 = theme.accent,
					BorderSizePixel = 0,
				}, track)
				round(99, fill)
				local knob = mk("Frame", {
					Size = UDim2.fromOffset(12, 12),
					AnchorPoint = Vector2.new(0.5, 0.5),
					Position = UDim2.new(0, 0, 0.5, 0),
					BackgroundColor3 = Color3.fromRGB(255, 255, 255),
					BorderSizePixel = 0,
				}, track)
				round(99, knob)

				local ctl = {}
				local function draw()
					local alpha = (maxValue - minValue == 0) and 0 or (value - minValue) / (maxValue - minValue)
					fill.Size = UDim2.new(alpha, 0, 1, 0)
					knob.Position = UDim2.new(alpha, 0, 0.5, 0)
					readout.Text = tostring(math.round(value * 100) / 100)
				end
				local function setFromX(x)
					local ax = track.AbsolutePosition.X
					local width = track.AbsoluteSize.X
					if width <= 0 then
						return
					end
					local alpha = math.clamp((x - ax) / width, 0, 1)
					value = minValue + (maxValue - minValue) * alpha
					draw()
					if cb then
						task.spawn(cb, value)
					end
				end
				draw()

				local dragging = false
				track.InputBegan:Connect(function(input)
					if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
						dragging = true
						setFromX(input.Position.X)
					end
				end)
				UserInputService.InputChanged:Connect(function(input)
					if not dragging then
						return
					end
					if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
						setFromX(input.Position.X)
					end
				end)
				UserInputService.InputEnded:Connect(function(input)
					if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
						dragging = false
					end
				end)
				function ctl:get()
					return value
				end
				function ctl:set(v, fire)
					value = math.clamp(v, minValue, maxValue)
					draw()
					if fire and cb then
						task.spawn(cb, value)
					end
				end
				return ctl
			end

			function self:dropdown(text, options, default, cb)
				local value = default or options[1]
				local row = nextRow(34, "Frame")
				label({
					Text = text,
					Size = UDim2.new(1, -180, 1, 0),
					Position = UDim2.fromOffset(12, 0),
					TextTruncate = Enum.TextTruncate.AtEnd,
				}, row)
				local btn = mk("TextButton", {
					Size = UDim2.new(0, 150, 0, 24),
					Position = UDim2.new(1, -162, 0.5, 0),
					AnchorPoint = Vector2.new(0, 0.5),
					BackgroundColor3 = theme.bg,
					Text = "",
					AutoButtonColor = false,
					BorderSizePixel = 0,
				}, row)
				round(5, btn)
				stroke(btn)
				local current = label({
					Text = tostring(value),
					TextSize = 12,
					Size = UDim2.new(1, -34, 1, 0),
					Position = UDim2.fromOffset(10, 0),
					TextTruncate = Enum.TextTruncate.AtEnd,
				}, btn)
				label({
					Text = "▾",
					TextColor3 = theme.dim,
					TextSize = 11,
					TextXAlignment = Enum.TextXAlignment.Center,
					Size = UDim2.fromOffset(20, 24),
					Position = UDim2.new(1, -24, 0, 0),
				}, btn)

				local ctl = {}
				local list
				local closeConn
				local function inBounds(inst, p)
					local ap, size = inst.AbsolutePosition, inst.AbsoluteSize
					return p.X >= ap.X and p.X <= ap.X + size.X and p.Y >= ap.Y and p.Y <= ap.Y + size.Y
				end
				local function closeList()
					if closeConn then
						closeConn:Disconnect()
						closeConn = nil
					end
					if list then
						list:Destroy()
						list = nil
					end
				end
				local function openList()
					if list then
						closeList()
						return
					end
					local height = math.min(#options * 28 + 8, 168)
					list = mk("ScrollingFrame", {
						Size = UDim2.fromOffset(150, height),
						Position = UDim2.fromOffset(btn.AbsolutePosition.X, btn.AbsolutePosition.Y + 28),
						BackgroundColor3 = theme.panel,
						BorderSizePixel = 0,
						ScrollBarThickness = 3,
						CanvasSize = UDim2.new(),
						ZIndex = 60,
					}, gui)
					round(6, list)
					stroke(list)
					mk("UIListLayout", {
						Padding = UDim.new(0, 2),
						SortOrder = Enum.SortOrder.LayoutOrder,
					}, list)
					pad(4, list)
					for i, opt in ipairs(options) do
						local optBtn = mk("TextButton", {
							Size = UDim2.new(1, 0, 0, 26),
							BackgroundColor3 = theme.panel,
							Text = "",
							AutoButtonColor = false,
							BorderSizePixel = 0,
							LayoutOrder = i,
							ZIndex = 61,
						}, list)
						round(4, optBtn)
						label({
							Text = tostring(opt),
							TextSize = 12,
							Size = UDim2.new(1, -16, 1, 0),
							Position = UDim2.fromOffset(8, 0),
							TextTruncate = Enum.TextTruncate.AtEnd,
							ZIndex = 62,
						}, optBtn)
						hover(optBtn, theme.panel, theme.hover)
						optBtn.MouseButton1Click:Connect(function()
							value = opt
							current.Text = tostring(opt)
							closeList()
							if cb then
								task.spawn(cb, opt)
							end
						end)
					end
					list.CanvasSize = UDim2.new(0, 0, 0, #options * 28 + 8)
					closeConn = UserInputService.InputBegan:Connect(function(input)
						if input.UserInputType ~= Enum.UserInputType.MouseButton1 and input.UserInputType ~= Enum.UserInputType.Touch then
							return
						end
						if list and (inBounds(list, input.Position) or inBounds(btn, input.Position)) then
							return
						end
						closeList()
					end)
				end
				btn.MouseButton1Click:Connect(openList)
				function ctl:get()
					return value
				end
				function ctl:set(v, fire)
					value = v
					current.Text = tostring(v)
					if fire and cb then
						task.spawn(cb, v)
					end
				end
				return ctl
			end

			function self:textbox(text, placeholder, cb)
				local row = nextRow(34, "Frame")
				label({
					Text = text,
					Size = UDim2.new(1, -180, 1, 0),
					Position = UDim2.fromOffset(12, 0),
					TextTruncate = Enum.TextTruncate.AtEnd,
				}, row)
				local box = mk("TextBox", {
					Size = UDim2.new(0, 150, 0, 24),
					Position = UDim2.new(1, -162, 0.5, 0),
					AnchorPoint = Vector2.new(0, 0.5),
					BackgroundColor3 = theme.bg,
					BorderSizePixel = 0,
					ClearTextOnFocus = false,
					Font = Enum.Font.Gotham,
					PlaceholderText = placeholder or "",
					PlaceholderColor3 = theme.dim,
					Text = "",
					TextColor3 = theme.text,
					TextSize = 12,
					TextXAlignment = Enum.TextXAlignment.Left,
					ClipsDescendants = true,
				}, row)
				round(5, box)
				stroke(box)
				pad(6, box)
				box.FocusLost:Connect(function(enter)
					if cb then
						task.spawn(cb, box.Text, enter)
					end
				end)
				return box
			end

			function self:divider()
				local row = nextRow(1, "Frame", { BackgroundColor3 = theme.stroke, BackgroundTransparency = 0 })
				row.Size = UDim2.new(1, 0, 0, 1)
				return row
			end

			table.insert(tab.sections, self)
			return self
		end
		tab.sections = {}

		table.insert(win.tabs, tab)
		if not win.active then
			activate()
		end
		return tab
	end

	function win:destroy()
		frame:Destroy()
		ui.clearNotices()
		if ui.gui == gui then
			ui.gui = nil
		end
		if win.onDestroy then
			win.onDestroy()
		end
	end

	function win:frame()
		return frame
	end

	return win
end

return ui
