--!nonstrict
-- Native GUI construction, input and local UI state. Animation belongs to FaithfulVFX.
local Input = game:GetService("UserInputService")
local GuiService = game:GetService("GuiService")

local UI = {}
UI.__index = UI
local CATEGORIES = { "Home", "Main", "Visuals", "Scripts", "Settings" }
local PATHS = {
	Home = { { 2, 11, 12, 3, 22, 11 }, { 5, 10, 5, 22, 10, 22, 10, 15, 15, 15, 15, 22, 20, 22, 20, 10 } },
	Main = { { 12, 2, 12, 7 }, { 12, 17, 12, 22 }, { 2, 12, 7, 12 }, { 17, 12, 22, 12 }, { 7, 7, 17, 7, 17, 17, 7, 17, 7, 7 } },
	Visuals = { { 2, 12, 7, 7, 12, 5, 17, 7, 22, 12, 17, 17, 12, 19, 7, 17, 2, 12 }, { 12, 9, 15, 12, 12, 15, 9, 12, 12, 9 } },
	Scripts = { { 5, 2, 15, 2, 20, 7, 20, 22, 5, 22, 5, 2 }, { 15, 2, 15, 7, 20, 7 }, { 8, 11, 16, 11 }, { 8, 15, 16, 15 }, { 8, 19, 14, 19 } },
	Settings = { { 3, 6, 21, 6 }, { 3, 12, 21, 12 }, { 3, 18, 21, 18 }, { 8, 3, 8, 9 }, { 16, 9, 16, 15 }, { 10, 15, 10, 21 } },
	Sigil = { { 12, 1, 14, 9, 20, 12, 14, 15, 12, 23, 10, 15, 4, 12, 10, 9, 12, 1 } },
	Close = { { 6, 6, 18, 18 }, { 18, 6, 6, 18 } },
	Minimize = { { 5, 15, 19, 15 } },
}

local function point(input)
	return Vector2.new(input.Position.X, input.Position.Y)
end
local function isPointer(input)
	return input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch
end
local function contains(object, position)
	local p, s = object.AbsolutePosition, object.AbsoluteSize
	return position.X >= p.X and position.Y >= p.Y and position.X <= p.X + s.X and position.Y <= p.Y + s.Y
end
local function apply(object, properties)
	for property, value in pairs(properties) do object[property] = value end
end

function UI:Connect(signal, callback)
	local connection = signal:Connect(function(...)
		if not self.Destroyed then callback(...) end
	end)
	table.insert(self.Connections, connection)
	return connection
end

function UI:CancelDelay(key)
	local thread = self.Threads[key]
	self.Threads[key] = nil
	if thread and coroutine.status(thread) ~= "dead" then task.cancel(thread) end
end

function UI:Delay(key, duration, callback)
	self:CancelDelay(key)
	self.Threads[key] = task.delay(duration, function()
		self.Threads[key] = nil
		if not self.Destroyed then callback() end
	end)
end

-- Unlike a timer callback, this task may yield inside a native asset preload.
-- Retain the coroutine until it finishes so Destroy can cancel it as well.
function UI:Spawn(key, callback)
	self:CancelDelay(key)
	self.Threads[key] = task.defer(function()
		if self.Destroyed then return end
		callback()
		if self.Threads[key] == coroutine.running() then self.Threads[key] = nil end
	end)
end

function UI:Make(className, parent, properties, scope)
	local object = Instance.new(className)
	if object:IsA("GuiObject") then
		object.BorderSizePixel = 0
		object.AutoLocalize = false
		object.BackgroundTransparency = 1
		object.ZIndex = (parent and parent:IsA("GuiObject")) and parent.ZIndex or 1
	end
	if object:IsA("TextLabel") or object:IsA("TextButton") or object:IsA("TextBox") then
		object.Font = self.Theme.Fonts.Body
		object.TextColor3 = self.Theme.Colors.Bone
		object.TextSize = 14
		object.Text = ""
	end
	apply(object, properties or {})
	object.Parent = parent
	self.Scopes[object] = scope or self.Scopes[parent] or "fixed"
	local alphaProperties = {}
	if object:IsA("GuiObject") then table.insert(alphaProperties, "BackgroundTransparency") end
	if object:IsA("TextLabel") or object:IsA("TextButton") or object:IsA("TextBox") then
		table.insert(alphaProperties, "TextTransparency")
		table.insert(alphaProperties, "TextStrokeTransparency")
	end
	if object:IsA("ImageLabel") or object:IsA("ImageButton") then table.insert(alphaProperties, "ImageTransparency") end
	if object:IsA("ScrollingFrame") then table.insert(alphaProperties, "ScrollBarImageTransparency") end
	if object:IsA("UIStroke") then table.insert(alphaProperties, "Transparency") end
	for _, property in ipairs(alphaProperties) do
		local entry = { Object = object, Property = property, Base = object[property], Scope = self.Scopes[object] }
		table.insert(self.AlphaEntries, entry)
		self.AlphaLookup[object] = self.AlphaLookup[object] or {}
		self.AlphaLookup[object][property] = entry
		if self.VFX then self.VFX:RegisterEntry(entry) end
	end
	return object
end

function UI:Alpha(object, property, value)
	local entry = self.AlphaLookup[object] and self.AlphaLookup[object][property]
	if entry then
		entry.Base = math.clamp(value, 0, 1)
		if self.VFX then self.VFX:ApplyEntry(entry) else object[property] = entry.Base end
	else
		object[property] = value
	end
end

function UI:Animate(object, properties, duration)
	if self.VFX then
		self.VFX:Tween(object, duration or self.Theme.Timings.Interaction, properties, "interaction")
	else
		apply(object, properties)
	end
end

function UI:Corner(object, radius)
	return self:Make("UICorner", object, { CornerRadius = UDim.new(0, radius or self.Theme.Layout.Radius) })
end
function UI:Stroke(object, color, transparency)
	return self:Make("UIStroke", object, {
		Color = color or self.Theme.Colors.Metal, Transparency = transparency or 0.45,
		Thickness = 1, ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
	})
end
function UI:Label(parent, text, position, size, textSize, color)
	return self:Make("TextLabel", parent, {
		Text = text, Position = position, Size = size, TextSize = textSize or 14,
		TextColor3 = color or self.Theme.Colors.Bone, TextXAlignment = Enum.TextXAlignment.Left,
		TextTruncate = Enum.TextTruncate.AtEnd,
	})
end
function UI:Line(parent, a, b, color, transparency, thickness)
	local delta = b - a
	return self:Make("Frame", parent, {
		Position = UDim2.fromOffset((a.X + b.X) / 2, (a.Y + b.Y) / 2),
		Size = UDim2.fromOffset(delta.Magnitude, thickness or 1), AnchorPoint = Vector2.new(0.5, 0.5),
		Rotation = math.deg(math.atan2(delta.Y, delta.X)), BackgroundColor3 = color,
		BackgroundTransparency = transparency or 0,
	})
end
function UI:Icon(parent, name, position, size, color)
	local host = self:Make("Frame", parent, { Name = name .. "Icon", Position = position, Size = UDim2.fromOffset(size, size) })
	for _, path in ipairs(PATHS[name]) do
		for i = 1, #path - 2, 2 do
			self:Line(host, Vector2.new(path[i], path[i + 1]) * (size / 24),
				Vector2.new(path[i + 2], path[i + 3]) * (size / 24), color or self.Theme.Colors.Silver, 0.1, 1.25)
		end
	end
	return host
end

function UI:Hover(button, selected)
	local normalAlpha = self.AlphaLookup[button].BackgroundTransparency.Base
	self:Connect(button.MouseEnter, function()
		if not self.Modal.Visible then
			self:Alpha(button, "BackgroundTransparency", math.min(normalAlpha, 0.86))
			self:Animate(button, { BackgroundColor3 = self.Theme.Colors.Charcoal })
		end
	end)
	self:Connect(button.MouseLeave, function()
		self:Alpha(button, "BackgroundTransparency", (selected and selected()) and 0.77 or normalAlpha)
		self:Animate(button, { BackgroundColor3 = (selected and selected()) and self.Theme.Colors.Crimson or self.Theme.Colors.Obsidian })
	end)
end

function UI:Tooltip(owner, message)
	self.TooltipOwners[owner] = true
	local function hide()
		self:CancelDelay(owner)
		if self.TooltipOwner == owner then self.TooltipBox.Visible = false; self.TooltipOwner = nil end
	end
	local function show()
		if not self.Open or self.Pointer or self.Modal.Visible then return end
		self.TooltipOwner = owner
		self.TooltipBox.Text = message
		local relative = owner.AbsolutePosition - self.Root.AbsolutePosition
		local maxX = math.max(0, self.Root.AbsoluteSize.X - 222)
		local maxY = math.max(0, self.Root.AbsoluteSize.Y - 44)
		self.TooltipBox.Position = UDim2.fromOffset(math.clamp(relative.X, 0, maxX), math.clamp(relative.Y + owner.AbsoluteSize.Y + 5, 0, maxY))
		self.TooltipBox.Visible = true
	end
	self:Connect(owner.MouseEnter, function() self:Delay(owner, 0.55, show) end)
	self:Connect(owner.MouseLeave, hide)
	self:Connect(owner.SelectionGained, show)
	self:Connect(owner.SelectionLost, hide)
	self:Connect(owner.InputBegan, function(input)
		if input.UserInputType == Enum.UserInputType.Touch then self:Delay(owner, 0.65, show) end
	end)
	self:Connect(owner.InputEnded, function(input) if isPointer(input) then hide() end end)
end

function UI:_ClampPosition(target, position, mode)
	local viewport, size = self.Root.AbsoluteSize, target.AbsoluteSize
	if mode == "window" then
		-- Allow placement partly outside every horizontal edge, retaining a usable header.
		return Vector2.new(math.clamp(position.X, -size.X + 96, math.max(0, viewport.X - 96)),
			math.clamp(position.Y, 0, math.max(0, viewport.Y - 48)))
	end
	return Vector2.new(math.clamp(position.X, 0, math.max(0, viewport.X - size.X)),
		math.clamp(position.Y, 0, math.max(0, viewport.Y - size.Y)))
end

function UI:_EndPointer()
	if self.Pointer and self.Pointer.Ended then self.Pointer.Ended() end
	self.Pointer = nil
end

function UI:BindDrag(handle, target, mode)
	self:Connect(handle.InputBegan, function(input)
		if not isPointer(input) or self.Pointer or self.Modal.Visible then return end
		if mode ~= "launcher" and not self.Open then return end
		self.TooltipBox.Visible = false
		local start = point(input)
		local origin = Vector2.new(target.Position.X.Offset, target.Position.Y.Offset)
		local moved = false
		self.Pointer = {
			Input = input,
			Move = function(position)
				local delta = position - start
				if delta.Magnitude < 5 and not moved then return end
				moved = true
				if mode == "logo" then self.LogoDetached = true end
				if mode == "launcher" then self.LauncherDragging = true end
				local final = self:_ClampPosition(target, origin + delta, mode)
				target.Position = UDim2.fromOffset(final.X, final.Y)
				if mode == "window" then self:_PlaceLogo() end
			end,
			Ended = function()
				if mode == "launcher" then
					self.LauncherDragging = false
					if moved then self.SuppressLauncherUntil = os.clock() + 0.15 end
				end
			end,
		}
	end)
end

function UI:_PlaceLogo()
	if self.LogoDetached then return end
	local position = Vector2.new(self.Window.Position.X.Offset + 12, self.Window.Position.Y.Offset + 8)
	position = self:_ClampPosition(self.Logo, position, "logo")
	self.Logo.Position = UDim2.fromOffset(position.X, position.Y)
end

function UI:_Layout()
	if self.Destroyed then return end
	self:_EndPointer()
	self.TooltipBox.Visible = false
	local available = self.Root.AbsoluteSize
	if available.X < 100 or available.Y < 100 then return end
	local layout = self.Theme.Layout
	local w = math.min(layout.Width, available.X - layout.Margin * 2)
	local h = math.min(layout.Height, available.Y - layout.Margin * 2)
	local compact = w < layout.CompactAt
	local sidebar = compact and layout.CompactSidebar or layout.Sidebar
	self.Window.Size = UDim2.fromOffset(w, h)
	self.Sidebar.Size = UDim2.new(0, sidebar, 1, -layout.Header)
	self.Content.Position = UDim2.fromOffset(sidebar + 20, layout.Header + 14)
	self.Content.Size = UDim2.new(1, -sidebar - 38, 1, -layout.Header - 30)
	self.PageTitle.TextSize = compact and 28 or 34
	-- Custom-asset URIs may render correctly without reporting IsLoaded. When the
	-- supplied background already includes its own wordmark, never stack a
	-- second FAITHFUL title on top of it after assigning the image.
	self.Brand.Visible = w >= 520 and not (self.Background.Image ~= "" and self.Assets.BackgroundContainsTitle)
	for _, record in pairs(self.Navigation) do
		record.Label.Position = UDim2.fromOffset(compact and 36 or 52, 0)
		record.Label.Size = UDim2.new(1, compact and -38 or -58, 1, 0)
		record.Label.TextSize = compact and 12 or 15
		record.Icon.Position = UDim2.new(0, compact and 8 or 18, 0.5, -11)
	end
	if not self.Positioned then
		self.Window.Position = UDim2.fromOffset((available.X - w) / 2, (available.Y - h) / 2)
		self.Launcher.Position = UDim2.fromOffset(16, math.max(0, available.Y - 72))
		self.Positioned = true
	else
		local windowPoint = self:_ClampPosition(self.Window, Vector2.new(self.Window.Position.X.Offset, self.Window.Position.Y.Offset), "window")
		self.Window.Position = UDim2.fromOffset(windowPoint.X, windowPoint.Y)
		for _, object in ipairs({ self.Logo, self.Launcher }) do
			local p = self:_ClampPosition(object, Vector2.new(object.Position.X.Offset, object.Position.Y.Offset), "logo")
			object.Position = UDim2.fromOffset(p.X, p.Y)
		end
	end
	self:_PlaceLogo()
end

function UI:_ClockText()
	local seconds = math.floor(self.ActiveSeconds + (self.ClockStart and os.clock() - self.ClockStart or 0))
	self.Timer.Text = string.format("%02d:%02d:%02d", math.floor(seconds / 3600), math.floor(seconds / 60) % 60, seconds % 60)
end
function UI:_StartClock()
	if self.ClockStart then return end
	self.ClockStart = os.clock()
	local function tick()
		if not self.Open then return end
		self:_ClockText()
		self:Delay("clock", 1, tick)
	end
	tick()
end
function UI:_StopClock()
	if self.ClockStart then self.ActiveSeconds += os.clock() - self.ClockStart; self.ClockStart = nil end
	self:CancelDelay("clock")
	self:_ClockText()
end

function UI:SetOpen(open)
	if self.Destroyed or self.Open == open then return end
	self.Open = open
	self:_EndPointer()
	self.TooltipBox.Visible = false
	for owner in pairs(self.TooltipOwners) do self:CancelDelay(owner) end
	if not open then
		local focused = Input:GetFocusedTextBox()
		if focused and focused:IsDescendantOf(self.Gui) then focused:ReleaseFocus(false) end
		local selected = GuiService.SelectedObject
		if selected and selected:IsDescendantOf(self.Gui) then GuiService.SelectedObject = nil end
	end
	self:DismissConfirmation()
	self:CloseDropdown()
	if open then self:_StartClock() else self:_StopClock() end
	if self.VFX then self.VFX:SetVisible(open)
	else self.Window.Visible = open; self.Logo.Visible = open; self.Launcher.Visible = not open end
end

function UI:SelectCategory(name)
	if not self.Pages[name] then return end
	self.ActivePage = name
	self:CloseDropdown()
	self.TooltipBox.Visible = false
	for key, record in pairs(self.Navigation) do
		record.Selected = key == name
		record.Marker.Visible = record.Selected
		self:Alpha(record.Button, "BackgroundTransparency", record.Selected and 0.77 or 1)
		self:Alpha(record.Edge, "Transparency", record.Selected and 0.46 or 1)
		self:Animate(record.Button, { BackgroundColor3 = record.Selected and self.Theme.Colors.Crimson or self.Theme.Colors.Obsidian })
		record.Label.TextColor3 = record.Selected and self.Theme.Colors.Bone or self.Theme.Colors.Silver
	end
	if self.VFX then self.VFX:SwitchPage(name)
	else
		for key, page in pairs(self.Pages) do page.Visible = key == name end
		self.PageTitle.Text = name
	end
end

function UI:Notify(message, duration)
	if not self.Open or self.Destroyed then return end
	self.ToastText.Text = message
	self.Toast.Visible = true
	if self.VFX then self.VFX:FadeScope("toast", 1, 0.14) end
	self:Delay("toast", duration or 2.8, function()
		if self.VFX then
			self.VFX:FadeScope("toast", 0, 0.15, function() self.Toast.Visible = false end)
		else self.Toast.Visible = false end
	end)
end

function UI:Confirm(message, callback)
	if not self.Open or self.Destroyed then return end
	self:_EndPointer()
	self:CloseDropdown()
	self.TooltipBox.Visible = false
	self.ConfirmCallback = callback
	self.ModalText.Text = message
	self.Modal.Visible = true
	self.PreviousSelection = GuiService.SelectedObject
	GuiService.SelectedObject = self.CancelButton
	if self.VFX then self.VFX:FadeScope("modal", 1, 0.12) end
end

function UI:DismissConfirmation()
	if not self.Modal then return end
	if self.Modal.Visible then
		local selected = GuiService.SelectedObject
		if selected and selected:IsDescendantOf(self.Modal) then
			local previous = self.PreviousSelection
			GuiService.SelectedObject = (previous and previous.Parent) and previous or nil
		end
	end
	self.Modal.Visible = false
	self.ConfirmCallback = nil
	if self.VFX then self.VFX:FadeScope("modal", 0, 0) end
end

function UI:CloseDropdown()
	if self.OpenDropdown then self.OpenDropdown:SetOpen(false) end
end

-- Reusable native components. The clean default does not instantiate the showcase.
function UI:Row(parent, height)
	self.Order += 1
	local row = self:Make("Frame", parent, { Size = UDim2.new(1, -6, 0, height), LayoutOrder = self.Order,
		BackgroundColor3 = self.Theme.Colors.Obsidian, BackgroundTransparency = 0.18 })
	self:Corner(row)
	self:Stroke(row, nil, 0.64)
	return row
end

function UI:Button(parent, caption, callback)
	local row = self:Row(parent, 48)
	local button = self:Make("TextButton", row, { Text = caption, Size = UDim2.fromScale(1, 1), AutoButtonColor = false,
		BackgroundColor3 = self.Theme.Colors.Obsidian, BackgroundTransparency = 0.25, Font = self.Theme.Fonts.Medium })
	self:Corner(button)
	self:Hover(button)
	self:Connect(button.Activated, function() if self.Open and not self.Modal.Visible then callback() end end)
	return { Root = row, Button = button }
end

function UI:Toggle(parent, caption, initial, callback)
	local row = self:Row(parent, 56)
	self:Label(row, caption, UDim2.fromOffset(14, 0), UDim2.new(1, -88, 1, 0))
	local button = self:Make("TextButton", row, { Position = UDim2.new(1, -70, 0, 6), Size = UDim2.fromOffset(60, 44), AutoButtonColor = false })
	local track = self:Make("Frame", button, { Position = UDim2.fromOffset(6, 9), Size = UDim2.fromOffset(48, 26), BackgroundTransparency = 0 })
	self:Corner(track, 13)
	local edge = self:Stroke(track)
	local knob = self:Make("Frame", track, { Size = UDim2.fromOffset(18, 18), BackgroundColor3 = self.Theme.Colors.Bone, BackgroundTransparency = 0 })
	self:Corner(knob, 9)
	local control = { Root = row, Button = button, Value = initial == true }
	local owner = self
	function control:Set(value, silent)
		self.Value = value == true
		owner:Animate(track, { BackgroundColor3 = self.Value and owner.Theme.Colors.Crimson or owner.Theme.Colors.Charcoal })
		owner:Animate(knob, { Position = UDim2.fromOffset(self.Value and 26 or 4, 4) })
		owner:Alpha(edge, "Transparency", self.Value and 0.25 or 0.6)
		if not silent and callback then callback(self.Value) end
	end
	self:Connect(button.Activated, function() if self.Open and not self.Modal.Visible then control:Set(not control.Value) end end)
	control:Set(initial, true)
	return control
end

function UI:Slider(parent, caption, minimum, maximum, step, initial, callback)
	assert(maximum > minimum and step > 0, "Invalid slider range")
	local row = self:Row(parent, 80)
	self:Label(row, caption, UDim2.fromOffset(14, 5), UDim2.new(1, -84, 0, 27))
	local valueLabel = self:Label(row, "", UDim2.new(1, -66, 0, 5), UDim2.fromOffset(52, 27), 13, self.Theme.Colors.Silver)
	valueLabel.TextXAlignment = Enum.TextXAlignment.Right
	local button = self:Make("TextButton", row, { Position = UDim2.fromOffset(18, 32), Size = UDim2.new(1, -36, 0, 44), AutoButtonColor = false })
	local track = self:Make("Frame", button, { Position = UDim2.new(0, 0, 0.5, -2), Size = UDim2.new(1, 0, 0, 4),
		BackgroundColor3 = self.Theme.Colors.Metal, BackgroundTransparency = 0.2 })
	self:Corner(track, 2)
	local fill = self:Make("Frame", track, { Size = UDim2.fromScale(0, 1), BackgroundColor3 = self.Theme.Colors.BrightCrimson, BackgroundTransparency = 0 })
	self:Corner(fill, 2)
	local knob = self:Make("Frame", track, { AnchorPoint = Vector2.new(0.5, 0.5), Size = UDim2.fromOffset(14, 14),
		BackgroundColor3 = self.Theme.Colors.Bone, BackgroundTransparency = 0 })
	self:Corner(knob, 7)
	local control = { Root = row, Button = button, Value = minimum }
	function control:Set(value, silent)
		self.Value = math.clamp(minimum + math.floor((value - minimum) / step + 0.5) * step, minimum, maximum)
		local ratio = (self.Value - minimum) / (maximum - minimum)
		fill.Size = UDim2.fromScale(ratio, 1)
		knob.Position = UDim2.fromScale(ratio, 0.5)
		valueLabel.Text = string.format("%.2f", self.Value):gsub("0+$", ""):gsub("%.$", "")
		if not silent and callback then callback(self.Value) end
	end
	local function move(position)
		local ratio = math.clamp((position.X - track.AbsolutePosition.X) / math.max(1, track.AbsoluteSize.X), 0, 1)
		control:Set(minimum + ratio * (maximum - minimum))
	end
	self:Connect(button.InputBegan, function(input)
		if not self.Open or self.Modal.Visible or self.Pointer or not isPointer(input) then return end
		local scrolling = row:FindFirstAncestorWhichIsA("ScrollingFrame")
		if scrolling then scrolling.ScrollingEnabled = false end
		self.Pointer = { Input = input, Move = move, Ended = function() if scrolling then scrolling.ScrollingEnabled = true end end }
		move(point(input))
	end)
	self.KeyboardHandlers[button] = function(key)
		if key == Enum.KeyCode.Left then control:Set(control.Value - step)
		elseif key == Enum.KeyCode.Right then control:Set(control.Value + step) end
	end
	control:Set(initial, true)
	return control
end

function UI:Dropdown(parent, caption, options, initial, callback)
	assert(#options > 0, "Dropdown needs options")
	local row = self:Row(parent, 86)
	self:Label(row, caption, UDim2.fromOffset(14, 5), UDim2.new(1, -28, 0, 26))
	local button = self:Make("TextButton", row, { Position = UDim2.fromOffset(12, 34), Size = UDim2.new(1, -24, 0, 40),
		AutoButtonColor = false, BackgroundColor3 = self.Theme.Colors.Charcoal, BackgroundTransparency = 0.1 })
	self:Corner(button, 4)
	local list = self:Make("Frame", row, { Position = UDim2.fromOffset(12, 80), Size = UDim2.new(1, -24, 0, #options * 40), Visible = false })
	self:Make("UIListLayout", list, { SortOrder = Enum.SortOrder.LayoutOrder })
	local owner = self
	local control = { Root = row, Button = button, Value = initial, IsOpen = false, Items = {} }
	function control:SetOpen(open)
		if open then owner:CloseDropdown(); owner.OpenDropdown = self
		elseif owner.OpenDropdown == self then owner.OpenDropdown = nil end
		self.IsOpen = open
		list.Visible = open
		row.Size = UDim2.new(1, -6, 0, open and (88 + #options * 40) or 86)
		button.Text = tostring(self.Value) .. (open and "  −" or "  +")
	end
	function control:Set(value, silent)
		assert(table.find(options, value), "Unknown dropdown value")
		self.Value = value
		self:SetOpen(false)
		if not silent and callback then callback(value) end
	end
	for i, option in ipairs(options) do
		local item = self:Make("TextButton", list, { Text = option, LayoutOrder = i, Size = UDim2.new(1, 0, 0, 40), AutoButtonColor = false,
			BackgroundColor3 = self.Theme.Colors.Obsidian, BackgroundTransparency = 0.1 })
		table.insert(control.Items, item)
		self:Hover(item)
		self:Connect(item.Activated, function() if self.Open and not self.Modal.Visible then control:Set(option) end end)
	end
	self:Connect(button.Activated, function() if self.Open and not self.Modal.Visible then control:SetOpen(not control.IsOpen) end end)
	control:Set(table.find(options, initial) and initial or options[1], true)
	return control
end

function UI:TextField(parent, caption, placeholder, callback)
	local row = self:Row(parent, 86)
	self:Label(row, caption, UDim2.fromOffset(14, 5), UDim2.new(1, -28, 0, 26))
	local box = self:Make("TextBox", row, { PlaceholderText = placeholder, ClearTextOnFocus = false,
		Position = UDim2.fromOffset(12, 34), Size = UDim2.new(1, -24, 0, 40), TextXAlignment = Enum.TextXAlignment.Left,
		BackgroundColor3 = self.Theme.Colors.Charcoal, BackgroundTransparency = 0.1, MultiLine = false })
	self:Corner(box, 4)
	self:Make("UIPadding", box, { PaddingLeft = UDim.new(0, 10), PaddingRight = UDim.new(0, 10) })
	self:Connect(box:GetPropertyChangedSignal("Text"), function()
		local cutoff = utf8.offset(box.Text, 129)
		if cutoff then box.Text = box.Text:sub(1, cutoff - 1) end
	end)
	self:Connect(box.FocusLost, function(enterPressed) if self.Open and callback then callback(box.Text, enterPressed) end end)
	return { Root = row, Box = box }
end

function UI:Separator(parent)
	self.Order += 1
	return self:Make("Frame", parent, { LayoutOrder = self.Order, Size = UDim2.new(1, -6, 0, 1),
		BackgroundColor3 = self.Theme.Colors.Metal, BackgroundTransparency = 0.5 })
end

function UI:_BuildShowcase()
	local main, settings = self.Pages.Main, self.Pages.Settings
	local demo = self:Button(main, "Probar notificación", function() self:Notify("Interfaz lista.") end)
	self:Tooltip(demo.Button, "Notificación local de la interfaz")
	self:Toggle(main, "Estado visual", false, function() end)
	self:Slider(main, "Valor", 0, 100, 1, 50, function() end)
	self:Dropdown(main, "Variante", { "A", "B", "C" }, "A", function() end)
	self:TextField(main, "Texto", "Escribir…", function() end)
	self:Separator(main)
	self:Button(main, "Probar confirmación", function() self:Confirm("¿Confirmar esta prueba?", function() self:Notify("Confirmado.") end) end)
	self:Dropdown(settings, "VFX", { "Minimal", "Balanced", "Ultra" }, self.Theme.Quality, function(value) self.VFX:SetQuality(value) end)
	self:Toggle(settings, "Reducir movimiento", self.Theme.ReduceMotion, function(value) self.VFX:SetReducedMotion(value) end)
	self:Slider(settings, "Niebla", 0, 0.4, 0.01, self.Theme.MistIntensity, function(value) self.VFX:SetMistIntensity(value) end)
end

function UI:_Build()
	local colors, layout = self.Theme.Colors, self.Theme.Layout
	self.Gui = self:Make("ScreenGui", self.PlayerGui, { Name = "Faithful", ResetOnSpawn = false,
		ZIndexBehavior = Enum.ZIndexBehavior.Global, DisplayOrder = layout.DisplayOrder,
		ScreenInsets = Enum.ScreenInsets.CoreUISafeInsets })
	self.Gui:SetAttribute("FaithfulOwner", self.Theme.Owner)
	self.Gui:SetAttribute("Version", self.Theme.Version)
	self.Root = self:Make("Frame", self.Gui, { Name = "SafeRoot", Size = UDim2.fromScale(1, 1) })
	self.Window = self:Make("Frame", self.Root, { Name = "Window", Size = UDim2.fromOffset(layout.Width, layout.Height),
		BackgroundColor3 = colors.Obsidian, BackgroundTransparency = 0.035, Visible = false, ClipsDescendants = true }, "shell")
	self:Corner(self.Window)
	self.WindowEdge = self:Stroke(self.Window, colors.Silver, 0.62)
	self.Background = self:Make("ImageLabel", self.Window, { Name = "Background", Size = UDim2.fromScale(1, 1),
		Image = self.Assets.Resolve(self.Assets.Background), ScaleType = Enum.ScaleType.Fit,
		ImageTransparency = math.clamp(self.Theme.BackgroundReferenceTransparency - self.Theme.BackgroundTransparencyReduction, 0, 1), ZIndex = 2 })
	self.MistLayer = self:Make("Frame", self.Window, { Name = "CrimsonMist", Size = UDim2.fromScale(1, 1), ZIndex = 3, ClipsDescendants = true })
	self.EmberLayer = self:Make("Frame", self.Window, { Name = "GhoulEmbers", Size = UDim2.fromScale(1, 1), ZIndex = 4, ClipsDescendants = true })
	local inset = self:Make("Frame", self.Window, { Position = UDim2.fromOffset(5, 5), Size = UDim2.new(1, -10, 1, -10), ZIndex = 5 })
	self:Corner(inset, 4); self:Stroke(inset, colors.Metal, 0.72)
	self.Header = self:Make("Frame", self.Window, { Name = "Header", Size = UDim2.new(1, 0, 0, layout.Header), ZIndex = 10,
		BackgroundColor3 = colors.Obsidian, BackgroundTransparency = 0.38 })
	self.DragHandle = self:Make("TextButton", self.Header, { Name = "DragHandle", Size = UDim2.new(1, -188, 1, 0), AutoButtonColor = false, Selectable = false })
	self.Brand = self:Label(self.Header, "FAITHFUL", UDim2.fromOffset(76, 0), UDim2.new(1, -300, 1, 0), 29)
	self.Brand.Font = self.Theme.Fonts.Display
	self.Timer = self:Label(self.Header, "00:00:00", UDim2.new(1, -194, 0, 0), UDim2.fromOffset(92, layout.Header), 13, colors.Silver)
	self.Timer.TextXAlignment = Enum.TextXAlignment.Center
	local function headerButton(name, offset)
		local button = self:Make("TextButton", self.Header, { Name = name, Position = UDim2.new(1, offset, 0, 10),
			Size = UDim2.fromOffset(44, 44), AutoButtonColor = false, ZIndex = 14, BackgroundColor3 = colors.Obsidian })
		self:Icon(button, name, UDim2.fromOffset(10, 10), 24)
		self:Hover(button)
		return button
	end
	self.Minimize = headerButton("Minimize", -98)
	self.Close = headerButton("Close", -52)
	self:Make("Frame", self.Header, { Position = UDim2.new(0, 8, 1, -1), Size = UDim2.new(1, -16, 0, 1),
		BackgroundColor3 = colors.Metal, BackgroundTransparency = 0.44 })
	self.Sidebar = self:Make("Frame", self.Window, { Position = UDim2.fromOffset(0, layout.Header), Size = UDim2.new(0, layout.Sidebar, 1, -layout.Header),
		BackgroundColor3 = colors.Obsidian, BackgroundTransparency = 0.27, ZIndex = 10 })
	self:Make("Frame", self.Sidebar, { Position = UDim2.new(1, -1, 0, 0), Size = UDim2.new(0, 1, 1, -7),
		BackgroundColor3 = colors.Metal, BackgroundTransparency = 0.5 })
	local arch = self:Make("Frame", self.Sidebar, { Position = UDim2.new(0.5, -40, 1, -108), Size = UDim2.fromOffset(80, 100), ZIndex = 11 })
	for _, insetX in ipairs({ 0, 6 }) do
		local path = { Vector2.new(insetX, 96), Vector2.new(insetX, 52), Vector2.new(10 + insetX, 28), Vector2.new(40, 3), Vector2.new(70 - insetX, 28), Vector2.new(80 - insetX, 52), Vector2.new(80 - insetX, 96) }
		for i = 1, #path - 1 do self:Line(arch, path[i], path[i + 1], colors.Metal, 0.65) end
	end
	self:Icon(arch, "Sigil", UDim2.fromOffset(30, 42), 20, colors.Crimson)
	local navigation = self:Make("ScrollingFrame", self.Sidebar, { Name = "Navigation", Position = UDim2.fromOffset(7, 12), Size = UDim2.new(1, -14, 1, -24),
		AutomaticCanvasSize = Enum.AutomaticSize.Y, CanvasSize = UDim2.fromOffset(0, 0), ScrollBarThickness = 2,
		ScrollBarImageColor3 = colors.Crimson, ScrollingDirection = Enum.ScrollingDirection.Y, ZIndex = 12 })
	self:Make("UIListLayout", navigation, { Padding = UDim.new(0, 8), SortOrder = Enum.SortOrder.LayoutOrder })
	for i, name in ipairs(CATEGORIES) do
		local button = self:Make("TextButton", navigation, { Name = name, Size = UDim2.new(1, -3, 0, 50), LayoutOrder = i,
			AutoButtonColor = false, BackgroundColor3 = colors.Obsidian, ZIndex = 13 })
		self:Corner(button, 5)
		local edge = self:Stroke(button, colors.Crimson, 1)
		local marker = self:Make("Frame", button, { Position = UDim2.fromOffset(0, 7), Size = UDim2.new(0, 3, 1, -14),
			BackgroundColor3 = colors.BrightCrimson, BackgroundTransparency = 0.06, Visible = false })
		local icon = self:Icon(button, name, UDim2.new(0, 18, 0.5, -11), 22)
		local label = self:Label(button, name, UDim2.fromOffset(52, 0), UDim2.new(1, -58, 1, 0), 15, colors.Silver)
		local record = { Button = button, Edge = edge, Marker = marker, Icon = icon, Label = label, Selected = false }
		self.Navigation[name] = record
		self:Hover(button, function() return record.Selected end)
		self:Connect(button.Activated, function() if self.Open and not self.Modal.Visible then self:SelectCategory(name) end end)
	end
	self.Content = self:Make("Frame", self.Window, { Name = "Content", Position = UDim2.fromOffset(layout.Sidebar + 20, layout.Header + 14),
		Size = UDim2.new(1, -layout.Sidebar - 38, 1, -layout.Header - 30), ZIndex = 20 })
	self.PageTitle = self:Label(self.Content, "Home", UDim2.fromOffset(24, 0), UDim2.new(1, -24, 0, 44), 38)
	self.PageTitle.Font = self.Theme.Fonts.Display
	self:Icon(self.Content, "Sigil", UDim2.fromOffset(0, 10), 20, colors.Crimson)
	self:Make("Frame", self.Content, { Position = UDim2.fromOffset(0, 51), Size = UDim2.new(1, 0, 0, 1),
		BackgroundColor3 = colors.Metal, BackgroundTransparency = 0.65 })
	for _, name in ipairs(CATEGORIES) do
		local page = self:Make("ScrollingFrame", self.Content, { Name = name, Position = UDim2.fromOffset(0, 66),
			Size = UDim2.new(1, 0, 1, -66), AutomaticCanvasSize = Enum.AutomaticSize.Y, CanvasSize = UDim2.fromOffset(0, 0),
			ScrollBarThickness = 3, ScrollBarImageColor3 = colors.Crimson, ScrollingDirection = Enum.ScrollingDirection.Y, Visible = name == "Home", ZIndex = 22 }, "page:" .. name)
		self:Make("UIListLayout", page, { Padding = UDim.new(0, 12), SortOrder = Enum.SortOrder.LayoutOrder })
		self.Pages[name] = page
	end
	self.Logo = self:Make("ImageButton", self.Root, { Name = "DraggableLogo", Size = UDim2.fromOffset(layout.LogoSize, layout.LogoSize),
		Image = self.Assets.Resolve(self.Assets.Logo), ScaleType = Enum.ScaleType.Fit, AutoButtonColor = false, Visible = false, ZIndex = 60 }, "logo")
	self.Launcher = self:Make("ImageButton", self.Root, { Name = "Reopen", Size = UDim2.fromOffset(52, 52),
		Image = self.Assets.Resolve(self.Assets.Logo), ScaleType = Enum.ScaleType.Fit, AutoButtonColor = false, Visible = false, ZIndex = 61,
		BackgroundColor3 = colors.Obsidian, BackgroundTransparency = 0.1 })
	self:Corner(self.Launcher, 8); self:Stroke(self.Launcher, colors.Crimson, 0.2)
	self.TooltipBox = self:Make("TextLabel", self.Root, { Name = "Tooltip", Visible = false, Size = UDim2.fromOffset(220, 42),
		BackgroundColor3 = colors.Charcoal, BackgroundTransparency = 0.02, TextWrapped = true, TextSize = 12, ZIndex = 180 })
	self:Corner(self.TooltipBox, 5); self:Stroke(self.TooltipBox, colors.Metal, 0.3)
	self.Toast = self:Make("Frame", self.Window, { Name = "Notification", AnchorPoint = Vector2.new(1, 1), Position = UDim2.new(1, -14, 1, -14),
		Size = UDim2.new(0.8, 0, 0, 52), BackgroundColor3 = colors.Charcoal, BackgroundTransparency = 0.02, Visible = false, ZIndex = 90 }, "toast")
	self:Make("UISizeConstraint", self.Toast, { MaxSize = Vector2.new(340, 52) })
	self:Corner(self.Toast); self:Stroke(self.Toast, colors.Crimson, 0.25)
	self.ToastText = self:Label(self.Toast, "", UDim2.fromOffset(14, 0), UDim2.new(1, -28, 1, 0), 13)
	self.Modal = self:Make("TextButton", self.Window, { Name = "Modal", Text = "", Size = UDim2.fromScale(1, 1),
		AutoButtonColor = false, Selectable = false, BackgroundColor3 = Color3.new(), BackgroundTransparency = 0.25, Visible = false, ZIndex = 110 }, "modal")
	local dialog = self:Make("Frame", self.Modal, { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.new(1, -40, 0, 154), BackgroundColor3 = colors.Obsidian, BackgroundTransparency = 0, ZIndex = 111 })
	self:Make("UISizeConstraint", dialog, { MaxSize = Vector2.new(340, 154) })
	self:Corner(dialog); self:Stroke(dialog, colors.Crimson, 0.25)
	self.ModalText = self:Label(dialog, "", UDim2.fromOffset(18, 18), UDim2.new(1, -36, 0, 62), 16)
	self.ModalText.TextWrapped = true
	self.CancelButton = self:Make("TextButton", dialog, { Text = "Cancelar", Position = UDim2.new(0, 16, 1, -58), Size = UDim2.new(0.5, -24, 0, 42),
		AutoButtonColor = false, BackgroundColor3 = colors.Charcoal, BackgroundTransparency = 0, ZIndex = 112 })
	self.ConfirmButton = self:Make("TextButton", dialog, { Text = "Confirmar", Position = UDim2.new(0.5, 8, 1, -58), Size = UDim2.new(0.5, -24, 0, 42),
		AutoButtonColor = false, BackgroundColor3 = colors.Crimson, BackgroundTransparency = 0, ZIndex = 112 })
	self:Corner(self.CancelButton, 4); self:Corner(self.ConfirmButton, 4)
	if self.Theme.ShowcaseControls then self:_BuildShowcase() end
end

function UI:_Bind()
	self:BindDrag(self.DragHandle, self.Window, "window")
	self:BindDrag(self.Logo, self.Logo, "logo")
	self:BindDrag(self.Launcher, self.Launcher, "launcher")
	self:Tooltip(self.Close, "Cerrar")
	self:Tooltip(self.Minimize, "Minimizar")
	self:Connect(self.Minimize.Activated, function() if not self.Modal.Visible then self:SetOpen(false) end end)
	self:Connect(self.Close.Activated, function()
		if not self.Open or self.Modal.Visible then return end
		if self.Theme.ConfirmClose then self:Confirm("¿Cerrar Faithful?", function() self:SetOpen(false) end)
		else self:SetOpen(false) end
	end)
	self:Connect(self.Launcher.Activated, function()
		if not self.LauncherDragging and os.clock() >= self.SuppressLauncherUntil then self:SetOpen(true) end
	end)
	self:Connect(self.CancelButton.Activated, function() self:DismissConfirmation() end)
	self:Connect(self.ConfirmButton.Activated, function()
		local callback = self.ConfirmCallback
		self:DismissConfirmation()
		if callback then callback() end
	end)
	self:Connect(Input.InputChanged, function(input)
		local pointer = self.Pointer
		if not pointer then return end
		if input == pointer.Input or (pointer.Input.UserInputType == Enum.UserInputType.MouseButton1 and input.UserInputType == Enum.UserInputType.MouseMovement) then
			pointer.Move(point(input))
		end
	end)
	self:Connect(Input.InputEnded, function(input)
		local pointer = self.Pointer
		if pointer and (input == pointer.Input or (pointer.Input.UserInputType == Enum.UserInputType.MouseButton1 and input.UserInputType == Enum.UserInputType.MouseButton1)) then self:_EndPointer() end
	end)
	self:Connect(Input.InputBegan, function(input, processed)
		if isPointer(input) and self.OpenDropdown and not contains(self.OpenDropdown.Root, point(input)) then self:CloseDropdown() end
		if processed or not self.Open or Input:GetFocusedTextBox() then return end
		if self.Modal.Visible then
			if input.KeyCode == Enum.KeyCode.Escape then self:DismissConfirmation() end
			return
		end
		local handler = self.KeyboardHandlers[GuiService.SelectedObject]
		if handler then handler(input.KeyCode) end
	end)
	self:Connect(Input.WindowFocusReleased, function() self:_EndPointer(); self.TooltipBox.Visible = false end)
	self:Connect(self.Root:GetPropertyChangedSignal("AbsoluteSize"), function() self:_Layout() end)
	self:Connect(self.Background:GetPropertyChangedSignal("Image"), function() self:_Layout() end)
	self:Connect(self.Background:GetPropertyChangedSignal("IsLoaded"), function() self:_Layout() end)
	self:Connect(self.Gui.Destroying, function() self:Destroy(true) end)
end

function UI:Destroy(fromInstance)
	if self.Destroyed then return end
	self:_EndPointer()
	self:DismissConfirmation()
	self.Destroyed = true
	if self.VFX then self.VFX:Destroy() end
	for _, connection in ipairs(self.Connections) do connection:Disconnect() end
	local keys = {}
	for key in pairs(self.Threads) do table.insert(keys, key) end
	for _, key in ipairs(keys) do self:CancelDelay(key) end
	self.Connections = {}
	if not fromInstance and self.Gui then self.Gui:Destroy() end
end

function UI.new(playerGui, theme, assets)
	assert(playerGui and playerGui:IsA("PlayerGui"), "FaithfulUI requires a PlayerGui")
	local self = setmetatable({
		PlayerGui = playerGui, Theme = theme, Assets = assets, Connections = {}, Threads = {},
		Scopes = {}, AlphaEntries = {}, AlphaLookup = {}, KeyboardHandlers = {}, TooltipOwners = {}, Pages = {}, Navigation = {},
		Order = 0, Open = false, Destroyed = false, ActivePage = "Home", ActiveSeconds = 0,
		SuppressLauncherUntil = 0, LogoDetached = false, Positioned = false,
	}, UI)
	self:_Build()
	self:_Bind()
	self:_Layout()
	self:SelectCategory("Home")
	return self
end

return UI
