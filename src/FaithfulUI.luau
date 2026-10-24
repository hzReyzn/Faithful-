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
		TextTruncate = Enum.TextTruncate.AtEnd, ZIndex = parent.ZIndex + 3,
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
	local host = self:Make("Frame", parent, { Name = name .. "Icon", Position = position, Size = UDim2.fromOffset(size, size), ZIndex = parent.ZIndex + 3 })
	for _, path in ipairs(PATHS[name]) do
		for i = 1, #path - 2, 2 do
			self:Line(host, Vector2.new(path[i], path[i + 1]) * (size / 24),
				Vector2.new(path[i + 2], path[i + 3]) * (size / 24), color or self.Theme.Colors.Silver, 0.1, 1.25)
		end
	end
	return host
end

function UI:Gradient(parent, colors, rotation, transparency)
	local keys = {}
	for i, color in ipairs(colors) do table.insert(keys, ColorSequenceKeypoint.new((i - 1) / (#colors - 1), color)) end
	local gradient = self:Make("UIGradient", parent, { Color = ColorSequence.new(keys), Rotation = rotation or 0 })
	if transparency then gradient.Transparency = transparency end
	return gradient
end

-- Native layered button surface, based on Reyzn X's metal face / neon wash /
-- single reflection pattern. Its animation state is owned by FaithfulVFX.
function UI:Hover(button, selected)
	if self.ButtonLookup[button] then return self.ButtonLookup[button] end
	local c = self.Theme.Colors
	self:Alpha(button, "BackgroundTransparency", 1)
	local face = self:Make("Frame", button, { Name = "MetalFace", AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.new(1, -2, 1, -2),
		BackgroundColor3 = Color3.new(1, 1, 1), BackgroundTransparency = 0.10, ZIndex = button.ZIndex })
	self:Corner(face, 6)
	self:Gradient(face, { c.ButtonTop, c.ButtonBottom }, 90)
	local edge = self:Stroke(face, Color3.new(1, 1, 1), 0.78)
	local edgeGradient = self:Gradient(edge, { c.Metal, c.SteelLight, c.Metal }, 90)
	local glow = self:Make("Frame", face, { Name = "CrimsonWash", Position = UDim2.fromOffset(1, 1), Size = UDim2.new(1, -2, 1, -2),
		BackgroundColor3 = Color3.new(1, 1, 1), BackgroundTransparency = 1, ZIndex = button.ZIndex + 1 })
	self:Corner(glow, 5)
	local accent = self:Stroke(glow, c.Crimson, 1)
	local wash = self:Gradient(glow, { c.Crimson, c.CrimsonShade, c.Charcoal }, 0, NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.16), NumberSequenceKeypoint.new(0.5, 0.25), NumberSequenceKeypoint.new(1, 0.80),
	}))
	local sheen = self:Make("Frame", face, { Name = "Reflection", Position = UDim2.fromOffset(1, 1), Size = UDim2.new(1, -2, 1, -2),
		BackgroundColor3 = c.Bone, BackgroundTransparency = 1, ZIndex = button.ZIndex + 1 })
	self:Corner(sheen, 5)
	local sweep = self:Gradient(sheen, { c.Silver, c.Bone }, 24, NumberSequence.new({
		NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(0.38, 1),
		NumberSequenceKeypoint.new(0.5, 0), NumberSequenceKeypoint.new(0.62, 1), NumberSequenceKeypoint.new(1, 1),
	}))
	local lip = self:Make("Frame", face, { Name = "BeveledLip", Position = UDim2.fromOffset(9, 1), Size = UDim2.new(1, -18, 0, 1),
		BackgroundColor3 = c.Silver, BackgroundTransparency = 0.94, ZIndex = button.ZIndex + 1 })
	self:Gradient(lip, { c.MetalDark, c.SteelLight, c.MetalDark }, 0)
	local caption
	if button.Text ~= "" then
		caption = self:Label(button, button.Text, UDim2.fromOffset(5, 0), UDim2.new(1, -10, 1, 0), button.TextSize)
		caption.TextXAlignment = Enum.TextXAlignment.Center
		caption.Font = button.Font
		self:Alpha(button, "TextTransparency", 1)
		self:Connect(button:GetPropertyChangedSignal("Text"), function() caption.Text = button.Text end)
	end
	local record = { Button = button, Face = face, Edge = edge, Accent = accent, EdgeGradient = edgeGradient, Glow = glow,
		Wash = wash, Sheen = sheen, Sweep = sweep, Lip = lip, Caption = caption, IsSelected = selected,
		Scale = self:Make("UIScale", face, { Scale = 1 }),
		Energy = self:Make("NumberValue", button, { Name = "InteractionEnergy", Value = 0 }),
		Selection = self:Make("NumberValue", button, { Name = "SelectionEnergy", Value = 0 }),
		Hover = false, Pressed = nil, Seed = (#self.ButtonStyles + 1) * 1.37 }
	table.insert(self.ButtonStyles, record)
	self.ButtonLookup[button] = record
	local function allowed()
		return self.Open and self.Gui.Enabled and (not self.Modal or not self.Modal.Visible or button:IsDescendantOf(self.Modal))
	end
	local function hover(active)
		record.Hover = active and allowed()
		if self.VFX then self.VFX:InteractButton(record, record.Hover and "hover" or "leave") end
	end
	self:Connect(button.MouseEnter, function() hover(true) end)
	self:Connect(button.MouseLeave, function() hover(false) end)
	self:Connect(button.SelectionGained, function() hover(true) end)
	self:Connect(button.SelectionLost, function() hover(false) end)
	self:Connect(button.InputBegan, function(input)
		if not allowed() or not isPointer(input) or record.Pressed then return end
		record.Pressed = input
		if self.VFX then self.VFX:InteractButton(record, "press") end
	end)
	if self.VFX then self.VFX:BindButton(record) end
	return record
end

function UI:ReleaseButtons(input, force)
	for _, record in ipairs(self.ButtonStyles) do
		local pointer = record.Pressed
		if (force and (pointer or record.Hover or record.Energy.Value > 0)) or (pointer and (input == pointer or (pointer.UserInputType == Enum.UserInputType.MouseButton1
			and input and input.UserInputType == Enum.UserInputType.MouseButton1))) then
			record.Pressed = nil
			if force then record.Hover = false end
			if self.VFX then self.VFX:InteractButton(record, "release") end
		end
	end
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
		-- Keep a page-title drag area visible when partly offscreen.
		local retained = math.min(224, size.X, viewport.X)
		return Vector2.new(math.clamp(position.X, -size.X + retained, math.max(0, viewport.X - retained)),
			math.clamp(position.Y, 0, math.max(0, viewport.Y - math.min(size.Y, self.Theme.Layout.Header + 56))))
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
				if mode == "launcher" then self.LauncherDragging = true end
				local final = self:_ClampPosition(target, origin + delta, mode)
				target.Position = UDim2.fromOffset(final.X, final.Y)
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

function UI:_Layout(preservePointer)
	if self.Destroyed then return end
	if not preservePointer then self:_EndPointer() end
	self.TooltipBox.Visible = false
	local available = self.Root.AbsoluteSize
	if available.X < 100 or available.Y < 100 then return end
	local layout = self.Theme.Layout
	local w = math.min(layout.Width * self.WindowSize, available.X - layout.Margin * 2)
	local h = math.min(layout.Height * self.WindowSize, available.Y - layout.Margin * 2, available.Y * layout.MaxViewportHeight)
	local compact = w < layout.CompactAt
	local sidebar = compact and layout.CompactSidebar or layout.Sidebar
	self.Window.Size = UDim2.fromOffset(w, h)
	-- Keep the wide wordmark clear of the timer on narrow touch screens.
	self.Logo.Size = UDim2.fromOffset(w < 520 and 108 or layout.WordmarkWidth,
		w < 520 and 36 or layout.WordmarkHeight)
	self.Sidebar.Size = UDim2.new(0, sidebar, 1, -layout.Header)
	self.Content.Position = UDim2.fromOffset(sidebar + 18, layout.Header + 12)
	self.Content.Size = UDim2.new(1, -sidebar - 34, 1, -layout.Header - 26)
	self.PageTitle.TextSize = compact and 24 or 28
	for _, record in pairs(self.Navigation) do
		record.Label.Position = UDim2.fromOffset(compact and 34 or 44, 0)
		record.Label.Size = UDim2.new(1, compact and -37 or -52, 1, 0)
		record.Label.TextSize = compact and 12 or 13
		record.Icon.Position = UDim2.new(0, compact and 8 or 14, 0.5, -9)
	end
	if not self.Positioned then
		self.Window.Position = UDim2.fromOffset((available.X - w) / 2, (available.Y - h) / 2)
		self.Launcher.Position = UDim2.fromOffset(16, math.max(0, available.Y - 72))
		self.Positioned = true
	else
		local windowPoint = self:_ClampPosition(self.Window, Vector2.new(self.Window.Position.X.Offset, self.Window.Position.Y.Offset), "window")
		self.Window.Position = UDim2.fromOffset(windowPoint.X, windowPoint.Y)
		local p = self:_ClampPosition(self.Launcher, Vector2.new(self.Launcher.Position.X.Offset, self.Launcher.Position.Y.Offset), "launcher")
		self.Launcher.Position = UDim2.fromOffset(p.X, p.Y)
	end
end

function UI:_ClockText()
	local seconds = math.floor(self.ActiveSeconds + (self.ClockStart and os.clock() - self.ClockStart or 0))
	self.Timer.Text = string.format("%02d:%02d:%02d", math.floor(seconds / 3600), math.floor(seconds / 60) % 60, seconds % 60)
end
function UI:_StartClock()
	if self.ClockStart or not self.Open or not self.Gui.Enabled then return end
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
	self:ReleaseButtons(nil, true)
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
	if self.Destroyed or not self.Pages[name] then return end
	self.ActivePage = name
	self:CloseDropdown()
	self.TooltipBox.Visible = false
	for key, record in pairs(self.Navigation) do
		record.Selected = key == name
		record.Marker.Visible = record.Selected
		local style = self.ButtonLookup[record.Button]
		if self.VFX then self.VFX:SetButtonSelected(style)
		else self:Alpha(style.Glow, "BackgroundTransparency", record.Selected and 0.76 or 1) end
		record.Label.TextColor3 = record.Selected and self.Theme.Colors.Bone or self.Theme.Colors.Silver
		record.Label.Font = record.Selected and self.Theme.Fonts.Medium or self.Theme.Fonts.Body
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
		BackgroundColor3 = self.Theme.Colors.Obsidian, BackgroundTransparency = 0.08 })
	self:Corner(row, 6)
	local edge = self:Stroke(row, Color3.new(1, 1, 1), 0.6)
	self:Gradient(edge, { self.Theme.Colors.MetalDark, self.Theme.Colors.SteelLight, self.Theme.Colors.MetalDark }, 25)
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
	local title = self:Label(row, caption, UDim2.fromOffset(14, 0), UDim2.new(1, -88, 1, 0), 13)
	title.TextWrapped = true
	title.TextTruncate = Enum.TextTruncate.None
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
	local row = self:Row(parent, 90)
	self:Label(row, caption, UDim2.fromOffset(14, 5), UDim2.new(1, -28, 0, 26))
	local button = self:Make("TextButton", row, { Text = tostring(initial or options[1]), Position = UDim2.fromOffset(12, 34), Size = UDim2.new(1, -24, 0, 44),
		AutoButtonColor = false, BackgroundColor3 = self.Theme.Colors.Charcoal, BackgroundTransparency = 0.1 })
	self:Corner(button, 4)
	self:Hover(button)
	local list = self:Make("Frame", row, { Position = UDim2.fromOffset(12, 84), Size = UDim2.new(1, -24, 0, #options * 44), Visible = false })
	self:Make("UIListLayout", list, { SortOrder = Enum.SortOrder.LayoutOrder })
	local owner = self
	local control = { Root = row, Button = button, Value = initial, IsOpen = false, Items = {} }
	function control:SetOpen(open)
		if open then owner:CloseDropdown(); owner.OpenDropdown = self
		elseif owner.OpenDropdown == self then owner.OpenDropdown = nil end
		self.IsOpen = open
		list.Visible = open
		row.Size = UDim2.new(1, -6, 0, open and (92 + #options * 44) or 90)
		button.Text = tostring(self.Value) .. (open and "  −" or "  +")
	end
	function control:Set(value, silent)
		assert(table.find(options, value), "Unknown dropdown value")
		self.Value = value
		self:SetOpen(false)
		if not silent and callback then callback(value) end
	end
	for i, option in ipairs(options) do
		local item = self:Make("TextButton", list, { Text = option, LayoutOrder = i, Size = UDim2.new(1, 0, 0, 44), AutoButtonColor = false,
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
	local row = self:Row(parent, 90)
	self:Label(row, caption, UDim2.fromOffset(14, 5), UDim2.new(1, -28, 0, 26))
	local box = self:Make("TextBox", row, { PlaceholderText = placeholder, ClearTextOnFocus = false,
		Position = UDim2.fromOffset(12, 34), Size = UDim2.new(1, -24, 0, 44), TextXAlignment = Enum.TextXAlignment.Left,
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
	local main = self.Pages.Main
	local demo = self:Button(main, "Probar notificación", function() self:Notify("Interfaz lista.") end)
	self:Tooltip(demo.Button, "Notificación local de la interfaz")
	self:Toggle(main, "Estado visual", false, function() end)
	self:Slider(main, "Valor", 0, 100, 1, 50, function() end)
	self:Dropdown(main, "Variante", { "A", "B", "C" }, "A", function() end)
	self:TextField(main, "Texto", "Escribir…", function() end)
	self:Separator(main)
	self:Button(main, "Probar confirmación", function() self:Confirm("¿Confirmar esta prueba?", function() self:Notify("Confirmado.") end) end)
end

function UI:SetWindowSize(scale)
	self.WindowSize = math.clamp(scale, 0.78, 1)
	self:_Layout(true)
end

function UI:ResetLayout()
	self.WindowSize = 1
	self.Positioned = false
	self:_Layout()
end

function UI:_Build()
	local colors, layout = self.Theme.Colors, self.Theme.Layout
	self.Gui = self:Make("ScreenGui", self.PlayerGui, { Name = "Faithful", ResetOnSpawn = false,
		ZIndexBehavior = Enum.ZIndexBehavior.Global, DisplayOrder = layout.DisplayOrder,
		ScreenInsets = Enum.ScreenInsets.CoreUISafeInsets })
	self.Gui:SetAttribute("FaithfulOwner", self.Theme.Owner)
	self.Gui:SetAttribute("Version", self.Theme.Version)
	self.Gui:SetAttribute("Build", self.Theme.Build)
	self.Root = self:Make("Frame", self.Gui, { Name = "SafeRoot", Size = UDim2.fromScale(1, 1) })
	self.Window = self:Make("Frame", self.Root, { Name = "Window", Size = UDim2.fromOffset(layout.Width, layout.Height),
		Visible = false, ClipsDescendants = false }, "shell")
	-- Surface clips the artwork and reflection; the scene root retains the fine
	-- border halo, small embers and shadow around its edges.
	for i = 3, 1, -1 do
		local pad = i * 5
		local shadow = self:Make("Frame", self.Window, { Name = "SoftShadow" .. i,
			Position = UDim2.fromOffset(-pad, -pad + 3), Size = UDim2.new(1, pad * 2, 1, pad * 2),
			BackgroundColor3 = Color3.new(), BackgroundTransparency = 0.92 - (3 - i) * 0.03, ZIndex = 1 })
		self:Corner(shadow, layout.Radius + pad)
	end
	self.EmberLayer = self:Make("Frame", self.Window, { Name = "GhoulEmbers", Size = UDim2.fromScale(1, 1), ZIndex = 4 })
	self.Surface = self:Make("Frame", self.Window, { Name = "ObsidianSurface", Size = UDim2.fromScale(1, 1),
		BackgroundColor3 = colors.Obsidian, BackgroundTransparency = 0.025, ClipsDescendants = true, ZIndex = 5 })
	self:Corner(self.Surface)
	self.WindowEdge = self:Stroke(self.Surface, Color3.new(1, 1, 1), 0.2)
	self.WindowMetal = self:Gradient(self.WindowEdge, { colors.MetalDark, colors.Silver, colors.Metal, colors.Crimson, colors.SteelLight }, 28)
	self.Background = self:Make("ImageLabel", self.Surface, { Name = "Background", Size = UDim2.fromScale(1, 1),
		Image = self.Assets.Resolve(self.Assets.Background), ScaleType = Enum.ScaleType.Fit,
		ImageTransparency = math.clamp(self.Theme.BackgroundReferenceTransparency - self.Theme.BackgroundTransparencyReduction, 0, 1), ZIndex = 6 })
	-- Show the supplied artwork, including its FAITHFUL title, without an alpha mask.
	local inset = self:Make("Frame", self.Surface, { Name = "InsetRim", Position = UDim2.fromOffset(4, 4), Size = UDim2.new(1, -8, 1, -8), ZIndex = 9 })
	self:Corner(inset, 5)
	self:Gradient(self:Stroke(inset, Color3.new(1, 1, 1), 0.65), { colors.Metal, colors.Silver, colors.MetalDark }, 120)
	self.CornerDetails = {}
	for i, corner in ipairs({ { 0, 0, 1, 1 }, { 1, 0, -1, 1 }, { 1, 1, -1, -1 }, { 0, 1, 1, -1 } }) do
		local host = self:Make("Frame", self.Window, { Name = "CornerBevel" .. i,
			Position = UDim2.fromScale(corner[1], corner[2]), Size = UDim2.fromOffset(0, 0), ZIndex = 51 })
		local x, y = corner[3], corner[4]
		self:Line(host, Vector2.new(x * 6, y * 19), Vector2.new(x * 6, y * 10), colors.Silver, 0.45, 1)
		self:Line(host, Vector2.new(x * 6, y * 10), Vector2.new(x * 10, y * 6), colors.Silver, 0.4, 1)
		self:Line(host, Vector2.new(x * 10, y * 6), Vector2.new(x * 29, y * 6), colors.Silver, 0.45, 1)
		table.insert(self.CornerDetails, host)
	end
	self.Header = self:Make("Frame", self.Surface, { Name = "Header", Size = UDim2.new(1, 0, 0, layout.Header), ZIndex = 10,
		BackgroundColor3 = colors.Obsidian, BackgroundTransparency = 0.035 })
	self.DragHandle = self:Make("TextButton", self.Header, { Name = "DragHandle", Size = UDim2.new(1, -188, 1, 0), AutoButtonColor = false, Selectable = false })
	self.Timer = self:Label(self.Header, "00:00:00", UDim2.new(1, -194, 0, 0), UDim2.fromOffset(92, layout.Header), 12, colors.Silver)
	self.Timer.TextXAlignment = Enum.TextXAlignment.Center
	local function headerButton(name, offset)
		local button = self:Make("TextButton", self.Header, { Name = name, Position = UDim2.new(1, offset, 0, 4),
			Size = UDim2.fromOffset(44, 44), AutoButtonColor = false, ZIndex = 14 })
		self:Icon(button, name, UDim2.fromOffset(12, 12), 20)
		self:Hover(button)
		return button
	end
	self.Minimize = headerButton("Minimize", -98)
	self.Close = headerButton("Close", -52)
	local headerRule = self:Make("Frame", self.Header, { Position = UDim2.new(0, 8, 1, -1), Size = UDim2.new(1, -16, 0, 1),
		BackgroundColor3 = Color3.new(1, 1, 1), BackgroundTransparency = 0.3 })
	self:Gradient(headerRule, { colors.MetalDark, colors.Crimson, colors.SteelLight, colors.MetalDark }, 0)
	self.Sidebar = self:Make("Frame", self.Surface, { Position = UDim2.fromOffset(0, layout.Header), Size = UDim2.new(0, layout.Sidebar, 1, -layout.Header),
		BackgroundColor3 = colors.Obsidian, BackgroundTransparency = 0.06, ZIndex = 10 })
	local divider = self:Make("Frame", self.Sidebar, { Position = UDim2.new(1, -1, 0, 0), Size = UDim2.new(0, 1, 1, -7),
		BackgroundColor3 = Color3.new(1, 1, 1), BackgroundTransparency = 0.45 })
	self:Gradient(divider, { colors.CrimsonShade, colors.SteelLight, colors.MetalDark }, 90)
	local navigation = self:Make("ScrollingFrame", self.Sidebar, { Name = "Navigation", Position = UDim2.fromOffset(7, 12), Size = UDim2.new(1, -14, 1, -24),
		AutomaticCanvasSize = Enum.AutomaticSize.Y, CanvasSize = UDim2.fromOffset(0, 0), ScrollBarThickness = 2,
		ScrollBarImageColor3 = colors.Crimson, ScrollingDirection = Enum.ScrollingDirection.Y, ZIndex = 12 })
	self:Make("UIListLayout", navigation, { Padding = UDim.new(0, layout.NavigationGap), SortOrder = Enum.SortOrder.LayoutOrder })
	for i, name in ipairs(CATEGORIES) do
		local button = self:Make("TextButton", navigation, { Name = name, Size = UDim2.new(1, -3, 0, layout.NavigationHeight), LayoutOrder = i,
			AutoButtonColor = false, ZIndex = 13 })
		local marker = self:Make("Frame", button, { Position = UDim2.fromOffset(2, 11), Size = UDim2.new(0, 2, 1, -22),
			BackgroundColor3 = colors.BrightCrimson, BackgroundTransparency = 0.04, Visible = false, ZIndex = 17 })
		local icon = self:Icon(button, name, UDim2.new(0, 14, 0.5, -9), 18)
		local label = self:Label(button, name, UDim2.fromOffset(48, 0), UDim2.new(1, -52, 1, 0), 14, colors.Silver)
		local record = { Button = button, Marker = marker, Icon = icon, Label = label, Selected = false }
		self.Navigation[name] = record
		local style = self:Hover(button, function() return record.Selected end)
		record.Edge = style.Edge
		self:Connect(button.Activated, function() if self.Open and not self.Modal.Visible then self:SelectCategory(name) end end)
	end
	self.Content = self:Make("Frame", self.Surface, { Name = "Content", Position = UDim2.fromOffset(layout.Sidebar + 18, layout.Header + 12),
		Size = UDim2.new(1, -layout.Sidebar - 34, 1, -layout.Header - 26), ZIndex = 20 })
	self.TitleDragHandle = self:Make("TextButton", self.Content, { Name = "TitleDragHandle", Size = UDim2.new(1, 0, 0, 44),
		AutoButtonColor = false, Selectable = false })
	self.PageTitle = self:Label(self.Content, "Home", UDim2.fromOffset(26, 0), UDim2.new(1, -26, 0, 40), 30)
	self.PageTitle.Font = self.Theme.Fonts.Display
	self:Icon(self.Content, "Sigil", UDim2.fromOffset(0, 9), 18, colors.Crimson)
	local titleRule = self:Make("Frame", self.Content, { Position = UDim2.fromOffset(0, 44), Size = UDim2.new(1, 0, 0, 1),
		BackgroundColor3 = Color3.new(1, 1, 1), BackgroundTransparency = 0.56 })
	self:Gradient(titleRule, { colors.Crimson, colors.SteelLight, colors.Obsidian }, 0)
	for _, name in ipairs(CATEGORIES) do
		local page = self:Make("ScrollingFrame", self.Content, { Name = name, Position = UDim2.fromOffset(0, layout.PageTop),
			Size = UDim2.new(1, 0, 1, -layout.PageTop), AutomaticCanvasSize = Enum.AutomaticSize.Y, CanvasSize = UDim2.fromOffset(0, 0),
			ScrollBarThickness = 3, ScrollBarImageColor3 = colors.Crimson, ScrollingDirection = Enum.ScrollingDirection.Y, Visible = name == "Home", ZIndex = 22 }, "page:" .. name)
		self:Make("UIListLayout", page, { Padding = UDim.new(0, 10), SortOrder = Enum.SortOrder.LayoutOrder })
		self.Pages[name] = page
	end
	-- Native parenting keeps the wordmark attached during drag, resize and restore.
	-- Dragging this image moves the complete window, just like its header.
	self.Logo = self:Make("ImageButton", self.Header, { Name = "HeaderWordmark", Position = UDim2.fromOffset(16, 6),
		Size = UDim2.fromOffset(layout.WordmarkWidth, layout.WordmarkHeight), Selectable = false,
		Image = self.Assets.Resolve(self.Assets.Wordmark), ScaleType = Enum.ScaleType.Fit, AutoButtonColor = false, Visible = false, ZIndex = 60 }, "logo")
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
	self.CancelButton = self:Make("TextButton", dialog, { Text = "Cancelar", Position = UDim2.new(0, 16, 1, -60), Size = UDim2.new(0.5, -24, 0, 44),
		AutoButtonColor = false, BackgroundColor3 = colors.Charcoal, BackgroundTransparency = 0, ZIndex = 112 })
	self.ConfirmButton = self:Make("TextButton", dialog, { Text = "Confirmar", Position = UDim2.new(0.5, 8, 1, -60), Size = UDim2.new(0.5, -24, 0, 44),
		AutoButtonColor = false, BackgroundColor3 = colors.Crimson, BackgroundTransparency = 0, ZIndex = 112 })
	self:Corner(self.CancelButton, 4); self:Corner(self.ConfirmButton, 4)
	self:Hover(self.CancelButton)
	self:Hover(self.ConfirmButton, function() return true end)
	if self.Theme.ShowcaseControls then self:_BuildShowcase() end
end

function UI:_Bind()
	self:BindDrag(self.DragHandle, self.Window, "window")
	self:BindDrag(self.TitleDragHandle, self.Window, "window")
	self:BindDrag(self.Logo, self.Window, "window")
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
		self:ReleaseButtons(input, false)
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
	self:Connect(Input.WindowFocusReleased, function() self:_EndPointer(); self:ReleaseButtons(nil, true); self.TooltipBox.Visible = false end)
	self:Connect(self.Root:GetPropertyChangedSignal("AbsoluteSize"), function() self:_Layout() end)
	self:Connect(self.Gui:GetPropertyChangedSignal("Enabled"), function()
		if self.Gui.Enabled and self.Open then self:_StartClock()
		else
			self:_StopClock()
			self:_EndPointer()
			self:ReleaseButtons(nil, true)
			self.TooltipBox.Visible = false
			for owner in pairs(self.TooltipOwners) do self:CancelDelay(owner) end
			if self.VFX then self.VFX:CancelGroup("interaction", true) end
		end
	end)
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
		ButtonStyles = {}, ButtonLookup = {}, WindowSize = 1,
		Order = 0, Open = false, Destroyed = false, ActivePage = "Home", ActiveSeconds = 0,
		SuppressLauncherUntil = 0, Positioned = false,
	}, UI)
	self:_Build()
	self:_Bind()
	self:_Layout()
	self:SelectCategory("Home")
	return self
end

return UI
