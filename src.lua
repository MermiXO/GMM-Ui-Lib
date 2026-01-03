local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local ContextActionService = game:GetService("ContextActionService")

local GmmUI = {}
GmmUI.__index = GmmUI

local function mk(className, props)
	local inst = Instance.new(className)
	for k, v in pairs(props or {}) do
		inst[k] = v
	end
	return inst
end

local function tween(obj, ti, props)
	local t = TweenService:Create(obj, ti, props)
	t:Play()
	return t
end

local DEFAULTS = {
	Title = "RAMPAGE",
	Tab = "HOME",
	Size = UDim2.fromOffset(320, 460),
	Position = UDim2.new(0.06, 0, 0.12, 0),

	Accent = Color3.fromRGB(150, 0, 0),
	Select = Color3.fromRGB(180, 0, 0),
	Bg = Color3.fromRGB(0, 0, 0),
	Text = Color3.fromRGB(255, 255, 255),

	HeaderHeight = 78,
	SubHeight = 24,
	FooterHeight = 38,
	RowHeight = 30,
}

local function safeParentGui()
	local lp = Players.LocalPlayer
	local pg = lp and lp:FindFirstChildOfClass("PlayerGui")
	if pg then return pg end
	return game:GetService("CoreGui")
end

local Menu = {}
Menu.__index = Menu

function Menu.new(ui, name)
	local self = setmetatable({}, Menu)
	self.UI = ui
	self.Name = tostring(name or "MENU"):upper()
	self.Items = {}
	return self
end

function Menu:_addItem(item)
	table.insert(self.Items, item)
	return item
end

function Menu:Button(label, desc, callback)
	return self:_addItem({
		Type = "Button",
		Label = tostring(label),
		Desc = tostring(desc or ""),
		Activate = function()
			if typeof(callback) == "function" then
				task.spawn(callback)
			end
		end,
	})
end

function Menu:Toggle(label, desc, defaultValue, callback)
	local state = defaultValue == true
	return self:_addItem({
		Type = "Toggle",
		Label = tostring(label),
		Desc = tostring(desc or ""),
		Get = function() return state end,
		Set = function(v)
			state = v and true or false
			if typeof(callback) == "function" then
				task.spawn(callback, state)
			end
		end,
		Left = function(it) it.Set(not it.Get()) end,
		Right = function(it) it.Set(not it.Get()) end,
		Activate = function(it) it.Set(not it.Get()) end,
		ValueText = function(it) return it.Get() and "ON" or "OFF" end,
	})
end

function Menu:Slider(label, desc, min, max, step, defaultValue, callback)
	min = tonumber(min) or 0
	max = tonumber(max) or 100
	step = tonumber(step) or 1
	local value = tonumber(defaultValue)
	if value == nil then value = min end
	value = math.clamp(value, min, max)

	local function set(v)
		v = math.clamp(v, min, max)
		local snapped = min + math.floor((v - min) / step + 0.5) * step
		value = math.clamp(snapped, min, max)
		if typeof(callback) == "function" then
			task.spawn(callback, value)
		end
	end

	return self:_addItem({
		Type = "Slider",
		Label = tostring(label),
		Desc = tostring(desc or ""),
		Get = function() return value end,
		Set = set,
		Left = function(it) it.Set(it.Get() - step) end,
		Right = function(it) it.Set(it.Get() + step) end,
		Activate = function() end,
		ValueText = function(it) return tostring(it.Get()) end,
	})
end

function Menu:List(label, desc, values, defaultIndex, callback)
	values = (typeof(values) == "table" and values) or {}
	local idx = tonumber(defaultIndex) or 1
	if #values == 0 then
		values = { "N/A" }
		idx = 1
	end
	idx = math.clamp(idx, 1, #values)

	local function setIndex(i)
		idx = ((i - 1) % #values) + 1
		if typeof(callback) == "function" then
			task.spawn(callback, values[idx], idx)
		end
	end

	return self:_addItem({
		Type = "List",
		Label = tostring(label),
		Desc = tostring(desc or ""),
		GetIndex = function() return idx end,
		SetIndex = setIndex,
		Left = function(it) it.SetIndex(it.GetIndex() - 1) end,
		Right = function(it) it.SetIndex(it.GetIndex() + 1) end,
		Activate = function(it) it.SetIndex(it.GetIndex() + 1) end,
		ValueText = function(it) return tostring(values[idx]) end,
	})
end

function Menu:Submenu(label, desc, submenu)
	assert(getmetatable(submenu) == Menu, "Submenu must be a Menu created by UI:NewMenu(...)")
	return self:_addItem({
		Type = "Submenu",
		Label = tostring(label),
		Desc = tostring(desc or ""),
		HasArrow = true,
		Activate = function()
			self.UI:PushMenu(submenu)
		end,
	})
end

function GmmUI.new(opts)
	opts = opts or {}
	for k, v in pairs(DEFAULTS) do
		if opts[k] == nil then opts[k] = v end
	end

	local self = setmetatable({}, GmmUI)
	self.Opts = opts
	self.Opened = true

	self.MenuStack = {}
	self.Current = nil
	self.SelectedIndex = 0

	self._connections = {}
	self._rowObjects = {}

	self._edit = nil
	self._holdDir = nil
	self._holdToken = 0

	local gui = mk("ScreenGui", {
		Name = "GmmUI",
		ResetOnSpawn = false,
		IgnoreGuiInset = true,
		ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
		Parent = safeParentGui(),
	})
	self.Gui = gui

	local main = mk("Frame", {
		Name = "Main",
		Parent = gui,
		Size = opts.Size,
		Position = opts.Position,
		BackgroundColor3 = opts.Bg,
		BackgroundTransparency = 0.12,
		BorderSizePixel = 0,
		ClipsDescendants = true,
	})
	self.Main = main

	local header = mk("Frame", {
		Name = "Header",
		Parent = main,
		Size = UDim2.new(1, 0, 0, opts.HeaderHeight),
		BackgroundColor3 = opts.Accent,
		BorderSizePixel = 0,
	})
	self.Header = header

	self.TitleLabel = mk("TextLabel", {
		Parent = header,
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 1, 0),
		Font = Enum.Font.GothamBlack,
		Text = tostring(opts.Title):upper(),
		TextColor3 = opts.Text,
		TextSize = 44,
		TextStrokeTransparency = 0.78,
		TextStrokeColor3 = Color3.fromRGB(0, 0, 0),
	})

	local sub = mk("Frame", {
		Name = "Sub",
		Parent = main,
		Position = UDim2.fromOffset(0, opts.HeaderHeight),
		Size = UDim2.new(1, 0, 0, opts.SubHeight),
		BackgroundColor3 = opts.Bg,
		BackgroundTransparency = 0,
		BorderSizePixel = 0,
	})
	self.Sub = sub

	self.TabLabel = mk("TextLabel", {
		Parent = sub,
		BackgroundTransparency = 1,
		Position = UDim2.fromOffset(10, 0),
		Size = UDim2.new(0.6, 0, 1, 0),
		Font = Enum.Font.GothamMedium,
		Text = tostring(opts.Tab):upper(),
		TextColor3 = opts.Text,
		TextSize = 14,
		TextXAlignment = Enum.TextXAlignment.Left,
	})

	self.CounterLabel = mk("TextLabel", {
		Parent = sub,
		BackgroundTransparency = 1,
		Position = UDim2.new(0.6, 0, 0, 0),
		Size = UDim2.new(0.4, -10, 1, 0),
		Font = Enum.Font.GothamMedium,
		Text = "0 / 0",
		TextColor3 = opts.Text,
		TextSize = 14,
		TextXAlignment = Enum.TextXAlignment.Right,
	})

	local listTop = opts.HeaderHeight + opts.SubHeight
	local listBottom = opts.FooterHeight
	local listHeightOffset = listTop + listBottom

	local scroll = mk("ScrollingFrame", {
		Name = "Scroll",
		Parent = main,
		Position = UDim2.fromOffset(0, listTop),
		Size = UDim2.new(1, 0, 1, -listHeightOffset),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		ScrollBarThickness = 0,
		CanvasSize = UDim2.new(0, 0, 0, 0),
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		ScrollingDirection = Enum.ScrollingDirection.Y,
		ScrollingEnabled = false,
	})
	self.Scroll = scroll

	local layout = mk("UIListLayout", {
		Parent = scroll,
		SortOrder = Enum.SortOrder.LayoutOrder,
		Padding = UDim.new(0, 0),
	})
	self.Layout = layout

	local footer = mk("Frame", {
		Name = "Footer",
		Parent = main,
		Position = UDim2.new(0, 0, 1, -opts.FooterHeight),
		Size = UDim2.new(1, 0, 0, opts.FooterHeight),
		BackgroundColor3 = opts.Bg,
		BorderSizePixel = 0,
	})
	self.Footer = footer

	mk("Frame", {
		Parent = footer,
		Size = UDim2.new(1, 0, 0, 2),
		BackgroundColor3 = opts.Accent,
		BorderSizePixel = 0,
	})

	self.DescLabel = mk("TextLabel", {
		Parent = footer,
		BackgroundTransparency = 1,
		Position = UDim2.fromOffset(8, 2),
		Size = UDim2.new(1, -16, 1, -4),
		Font = Enum.Font.Gotham,
		Text = "Select an option.",
		TextColor3 = opts.Text,
		TextSize = 12,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextYAlignment = Enum.TextYAlignment.Center,
		TextWrapped = true,
	})

	self._casActions = {
		"GmmUI_Toggle",
		"GmmUI_Up",
		"GmmUI_Down",
		"GmmUI_Left",
		"GmmUI_Right",
		"GmmUI_PageUp",
		"GmmUI_PageDown",
		"GmmUI_Back",
		"GmmUI_Select",
	}

	for _, name in ipairs(self._casActions) do
		pcall(function()
			ContextActionService:UnbindAction(name)
		end)
	end

	local function bind(actionName, fn, ...)
		ContextActionService:BindActionAtPriority(actionName, fn, false, 2000, ...)
	end

	bind("GmmUI_Toggle", function(_, state)
		if state ~= Enum.UserInputState.Begin then return Enum.ContextActionResult.Pass end
		self:Toggle()
		return Enum.ContextActionResult.Sink
	end, Enum.KeyCode.F4, Enum.KeyCode.Insert)

	bind("GmmUI_Up", function(_, state)
		if state ~= Enum.UserInputState.Begin then return Enum.ContextActionResult.Pass end
		if not self.Opened then return Enum.ContextActionResult.Pass end
		if self._edit then return Enum.ContextActionResult.Sink end
		self:SetSelected(self.SelectedIndex - 1)
		return Enum.ContextActionResult.Sink
	end, Enum.KeyCode.Up, Enum.KeyCode.KeypadEight)

	bind("GmmUI_Down", function(_, state)
		if state ~= Enum.UserInputState.Begin then return Enum.ContextActionResult.Pass end
		if not self.Opened then return Enum.ContextActionResult.Pass end
		if self._edit then return Enum.ContextActionResult.Sink end
		self:SetSelected(self.SelectedIndex + 1)
		return Enum.ContextActionResult.Sink
	end, Enum.KeyCode.Down, Enum.KeyCode.KeypadTwo)

	bind("GmmUI_Left", function(_, state)
		if not self.Opened then return Enum.ContextActionResult.Pass end

		if state == Enum.UserInputState.Begin then
			self:DoLeft()
			self:_startHold(-1)
			return Enum.ContextActionResult.Sink
		elseif state == Enum.UserInputState.End then
			self:_stopHold(-1)
			return Enum.ContextActionResult.Sink
		end

		return Enum.ContextActionResult.Pass
	end, Enum.KeyCode.Left, Enum.KeyCode.KeypadFour)

	bind("GmmUI_Right", function(_, state)
		if not self.Opened then return Enum.ContextActionResult.Pass end

		if state == Enum.UserInputState.Begin then
			self:DoRight()
			self:_startHold(1)
			return Enum.ContextActionResult.Sink
		elseif state == Enum.UserInputState.End then
			self:_stopHold(1)
			return Enum.ContextActionResult.Sink
		end

		return Enum.ContextActionResult.Pass
	end, Enum.KeyCode.Right, Enum.KeyCode.KeypadSix)

	bind("GmmUI_PageUp", function(_, state)
		if state ~= Enum.UserInputState.Begin then return Enum.ContextActionResult.Pass end
		if not self.Opened then return Enum.ContextActionResult.Pass end
		if self._edit then return Enum.ContextActionResult.Sink end
		self:SetSelected(self.SelectedIndex - 10)
		return Enum.ContextActionResult.Sink
	end, Enum.KeyCode.PageUp, Enum.KeyCode.KeypadNine)

	bind("GmmUI_PageDown", function(_, state)
		if state ~= Enum.UserInputState.Begin then return Enum.ContextActionResult.Pass end
		if not self.Opened then return Enum.ContextActionResult.Pass end
		if self._edit then return Enum.ContextActionResult.Sink end
		self:SetSelected(self.SelectedIndex + 10)
		return Enum.ContextActionResult.Sink
	end, Enum.KeyCode.PageDown, Enum.KeyCode.KeypadThree)

	bind("GmmUI_Back", function(_, state)
		if state ~= Enum.UserInputState.Begin then return Enum.ContextActionResult.Pass end
		if not self.Opened then return Enum.ContextActionResult.Pass end

		if self._edit then
			self:CancelEdit()
		else
			self:Back()
		end
		return Enum.ContextActionResult.Sink
	end, Enum.KeyCode.Backspace, Enum.KeyCode.KeypadZero)

	bind("GmmUI_Select", function(_, state)
		if state ~= Enum.UserInputState.Begin then return Enum.ContextActionResult.Pass end
		if not self.Opened then return Enum.ContextActionResult.Pass end
		self:Select()
		return Enum.ContextActionResult.Sink
	end, Enum.KeyCode.Return, Enum.KeyCode.KeypadFive)

	return self
end

function GmmUI:NewMenu(name)
	return Menu.new(self, name)
end

function GmmUI:SetTitle(text)
	self.TitleLabel.Text = tostring(text):upper()
end

function GmmUI:SetTab(text)
	self.TabLabel.Text = tostring(text):upper()
end

function GmmUI:_updateCounter()
	local total = (self.Current and #self.Current.Items) or 0
	local sel = (total > 0) and math.clamp(self.SelectedIndex, 1, total) or 0
	self.CounterLabel.Text = string.format("%d / %d", sel, total)
end

function GmmUI:_clearRows()
	for _, row in ipairs(self._rowObjects) do
		if row and row.Destroy then row:Destroy() end
	end
	self._rowObjects = {}
end

function GmmUI:_makeRow(item, index)
	local opts = self.Opts

	local row = mk("TextButton", {
		Parent = self.Scroll,
		Size = UDim2.new(1, 0, 0, opts.RowHeight),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		AutoButtonColor = false,
		Text = "",
	})

	local selBg = mk("Frame", {
		Parent = row,
		Size = UDim2.new(1, 0, 1, 0),
		BackgroundColor3 = opts.Select,
		BorderSizePixel = 0,
		Visible = false,
	})

	mk("Frame", {
		Parent = row,
		AnchorPoint = Vector2.new(0, 1),
		Position = UDim2.new(0, 0, 1, 0),
		Size = UDim2.new(1, 0, 0, 1),
		BackgroundColor3 = Color3.fromRGB(255, 255, 255),
		BackgroundTransparency = 0.92,
		BorderSizePixel = 0,
	})

	mk("TextLabel", {
		Parent = row,
		BackgroundTransparency = 1,
		Position = UDim2.fromOffset(10, 0),
		Size = UDim2.new(1, -110, 1, 0),
		Font = Enum.Font.Gotham,
		Text = item.Label,
		TextColor3 = opts.Text,
		TextSize = 14,
		TextXAlignment = Enum.TextXAlignment.Left,
	})

	local right = mk("TextLabel", {
		Parent = row,
		BackgroundTransparency = 1,
		Position = UDim2.new(1, -86, 0, 0),
		Size = UDim2.fromOffset(62, opts.RowHeight),
		Font = Enum.Font.GothamBold,
		Text = "",
		TextColor3 = opts.Text,
		TextSize = 13,
		TextXAlignment = Enum.TextXAlignment.Right,
	})

	local arrow = mk("TextLabel", {
		Parent = row,
		BackgroundTransparency = 1,
		Position = UDim2.new(1, -24, 0, 0),
		Size = UDim2.fromOffset(24, opts.RowHeight),
		Font = Enum.Font.GothamBold,
		Text = ">",
		TextColor3 = opts.Text,
		TextSize = 14,
	})

	if item.HasArrow or item.Type == "Submenu" then
		arrow.Visible = true
	else
		arrow.Visible = false
	end

	local function setSelected(on)
		selBg.Visible = on
		if on then
			selBg.BackgroundTransparency = 0.2
			tween(selBg, TweenInfo.new(0.08, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { BackgroundTransparency = 0 })
		end
	end

	local function refreshValue()
		if item.ValueText then
			local t = item:ValueText()
			if item.Type == "Slider" and self._edit and self._edit.Item == item then
				right.Text = "< " .. t .. " >"
			else
				right.Text = t
			end
		else
			right.Text = ""
		end
	end

	refreshValue()

	row.MouseButton1Click:Connect(function()
		if self._edit then return end
		self:SetSelected(index)
		self:Select()
	end)

	return row, setSelected, refreshValue
end

function GmmUI:_renderMenu(menu)
	self:_clearRows()
	self.Current = menu
	self:SetTab(menu.Name)

	for i, item in ipairs(menu.Items) do
		local row, setSelected, refreshValue = self:_makeRow(item, i)
		item.__row = row
		item.__setSelected = setSelected
		item.__refreshValue = refreshValue
		table.insert(self._rowObjects, row)
	end

	if #menu.Items > 0 then
		self:SetSelected(1)
	else
		self.SelectedIndex = 0
		self.DescLabel.Text = "No options."
		self:_updateCounter()
	end
end

function GmmUI:PushMenu(menu)
	table.insert(self.MenuStack, menu)
	self:_renderMenu(menu)
end

function GmmUI:Back()
	if self._edit then
		self:CancelEdit()
		return
	end

	if #self.MenuStack <= 1 then
		self:Close()
		return
	end
	table.remove(self.MenuStack, #self.MenuStack)
	local top = self.MenuStack[#self.MenuStack]
	self:_renderMenu(top)
end

function GmmUI:SetSelected(idx)
	if not self.Current then return end
	local items = self.Current.Items
	if #items == 0 then return end

	idx = ((idx - 1) % #items) + 1
	self.SelectedIndex = idx

	for i, it in ipairs(items) do
		if it.__setSelected then
			it.__setSelected(i == idx)
		end
	end

	local it = items[idx]
	self.DescLabel.Text = (it and it.Desc and it.Desc ~= "") and it.Desc or "Select an option."
	self:_updateCounter()

	local row = it and it.__row
	if row then
		local y = row.AbsolutePosition.Y
		local h = row.AbsoluteSize.Y
		local topY = self.Scroll.AbsolutePosition.Y
		local botY = topY + self.Scroll.AbsoluteSize.Y

		if y < topY then
			self.Scroll.CanvasPosition = Vector2.new(0, math.max(0, self.Scroll.CanvasPosition.Y - (topY - y)))
		elseif (y + h) > botY then
			self.Scroll.CanvasPosition = Vector2.new(0, self.Scroll.CanvasPosition.Y + ((y + h) - botY))
		end
	end
end

function GmmUI:_getSelectedItem()
	if not self.Current then return nil end
	return self.Current.Items[self.SelectedIndex]
end

function GmmUI:_stopHold(dir)
	if dir == nil or self._holdDir == dir then
		self._holdDir = nil
		self._holdToken = (self._holdToken or 0) + 1
	end
end

function GmmUI:_startHold(dir)
	local it = self._edit and self._edit.Item
	if not (self.Opened and it and it == self:_getSelectedItem() and it.Type == "Slider") then
		return
	end

	self._holdDir = dir
	self._holdToken = (self._holdToken or 0) + 1
	local token = self._holdToken

	task.spawn(function()
		task.wait(0.35)
		while self._holdToken == token and self._holdDir == dir do
			if not self.Opened then break end
			if not self._edit or self._edit.Item ~= it then break end
			if dir < 0 then
				self:DoLeft()
			else
				self:DoRight()
			end
			task.wait(0.05)
		end
	end)
end

function GmmUI:BeginEdit()
	if self._edit then return end
	local it = self:_getSelectedItem()
	if not it or it.Type ~= "Slider" then return end

	self._edit = { Item = it, Original = it.Get and it.Get() or nil }
	if it.__refreshValue then it.__refreshValue() end
end

function GmmUI:ConfirmEdit()
	if not self._edit then return end
	local it = self._edit.Item
	self._edit = nil
	self:_stopHold()
	if it and it.__refreshValue then it.__refreshValue() end
end

function GmmUI:CancelEdit()
	if not self._edit then return end
	local it = self._edit.Item
	local original = self._edit.Original
	self._edit = nil
	self:_stopHold()
	if it and original ~= nil and it.Set then
		it.Set(original)
	end
	if it and it.__refreshValue then it.__refreshValue() end
end

function GmmUI:DoLeft()
	local it = self:_getSelectedItem()
	if not it then return end

	if it.Type == "Slider" then
		if not (self._edit and self._edit.Item == it) then
			return
		end
	end

	if it.Left then
		it:Left()
		if it.__refreshValue then it.__refreshValue() end
	end
end

function GmmUI:DoRight()
	local it = self:_getSelectedItem()
	if not it then return end

	if it.Type == "Slider" then
		if not (self._edit and self._edit.Item == it) then
			return
		end
	end

	if it.Right then
		it:Right()
		if it.__refreshValue then it.__refreshValue() end
	end
end

function GmmUI:Select()
	local it = self:_getSelectedItem()
	if not it then return end

	if it.Type == "Slider" then
		if self._edit and self._edit.Item == it then
			self:ConfirmEdit()
		else
			self:BeginEdit()
		end
		return
	end

	if it.Activate then
		it:Activate()
		if it.__refreshValue then it.__refreshValue() end
	end
end

function GmmUI:Open()
	if self.Opened then return end
	self.Opened = true
	self.Main.Visible = true
	self.Main.BackgroundTransparency = 0.35
	tween(self.Main, TweenInfo.new(0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { BackgroundTransparency = 0.12 })
end

function GmmUI:Close()
	if not self.Opened then return end
	if self._edit then
		self:ConfirmEdit()
	else
		self:_stopHold()
	end
	self.Opened = false
	local t = tween(self.Main, TweenInfo.new(0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.In), { BackgroundTransparency = 0.35 })
	t.Completed:Connect(function()
		if not self.Opened then
			self.Main.Visible = false
		end
	end)
end

function GmmUI:Toggle()
	if self.Opened then self:Close() else self:Open() end
end

function GmmUI:Destroy()
	for _, c in ipairs(self._connections) do
		pcall(function() c:Disconnect() end)
	end
	self._connections = {}

	if self._casActions then
		for _, name in ipairs(self._casActions) do
			pcall(function()
				ContextActionService:UnbindAction(name)
			end)
		end
		self._casActions = nil
	end

	if self.Gui then self.Gui:Destroy() end
end

return GmmUI
