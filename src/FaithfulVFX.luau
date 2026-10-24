--!nonstrict
-- One throttled Heartbeat, fixed object pools, immutable base alpha and cancellable tweens.
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local GuiService = game:GetService("GuiService")

local VFX = {}
VFX.__index = VFX
local PI = math.pi
local function unit(seed)
	return (math.sin(seed * 12.9898 + 78.233) * 43758.5453) % 1
end
local function set(object, properties)
	for property, value in pairs(properties) do object[property] = value end
end

function VFX:RegisterEntry(entry)
	self.ByScope[entry.Scope] = self.ByScope[entry.Scope] or {}
	table.insert(self.ByScope[entry.Scope], entry)
	self:ApplyEntry(entry)
end
function VFX:ApplyEntry(entry)
	local scope = entry.Scope
	local opacity = 1
	if scope ~= "fixed" then
		opacity = self.Factors.shell.Value
		if scope ~= "shell" and self.Factors[scope] then opacity *= self.Factors[scope].Value end
	end
	entry.Object[entry.Property] = 1 - (1 - entry.Base) * opacity
end
function VFX:_Refresh(scope)
	if self.Destroyed then return end
	if scope == "shell" then
		for key, entries in pairs(self.ByScope) do
			if key ~= "fixed" then for _, entry in ipairs(entries) do self:ApplyEntry(entry) end end
		end
	else
		for _, entry in ipairs(self.ByScope[scope] or {}) do self:ApplyEntry(entry) end
	end
end

function VFX:CancelTween(object)
	local record = self.Tweens[object]
	if not record then return end
	self.Tweens[object] = nil
	record.Connection:Disconnect()
	record.Tween:Cancel()
	record.Tween:Destroy()
end
function VFX:CancelGroup(group, finish)
	local objects = {}
	for object, record in pairs(self.Tweens) do
		if record.Group == group then
			if finish then set(object, record.Goals) end
			table.insert(objects, object)
		end
	end
	for _, object in ipairs(objects) do self:CancelTween(object) end
end
function VFX:Tween(object, duration, goals, group, onComplete)
	if self.Destroyed then return end
	self:CancelTween(object)
	if self.Reduced then duration = math.min(duration, 0.06) end
	if duration <= 0 then
		set(object, goals)
		if onComplete then onComplete() end
		return
	end
	-- Alpha animations go through NumberValues; never sample partially faded GUI alpha.
	local tween = TweenService:Create(object, TweenInfo.new(duration, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), goals)
	local record = { Tween = tween, Goals = goals, Group = group or "interaction" }
	self.Tweens[object] = record
	record.Connection = tween.Completed:Connect(function(playbackState)
		if self.Tweens[object] ~= record then return end
		self.Tweens[object] = nil
		record.Connection:Disconnect()
		tween:Destroy()
		if playbackState == Enum.PlaybackState.Completed and not self.Destroyed and onComplete then onComplete() end
	end)
	tween:Play()
	return tween
end
function VFX:FadeScope(scope, opacity, duration, callback)
	self:Tween(self.Factors[scope], duration, { Value = opacity }, "scope:" .. scope, callback)
end

-- Button effects intentionally mirror the useful Reyzn X concepts: a layered
-- metal face, an independently moving crimson wash, and ONE shared reflection.
function VFX:_Shown(object)
	while object and object ~= self.UI.Gui do
		if object:IsA("GuiObject") and not object.Visible then return false end
		object = object.Parent
	end
	return object ~= nil
end

function VFX:ApplyButton(record, steady)
	local selected, energy = record.Selection.Value, record.Energy.Value
	local pulse = not steady and not self.Reduced and self.Enabled.Border and self.Theme.QualityLevels[self.Quality].Border
		and math.sin(self.Time * 0.8 + record.Seed) ^ 2 or 0
	self.UI:Alpha(record.Glow, "BackgroundTransparency", 1 - selected * (0.24 + pulse * 0.025) - energy * 0.075)
	self.UI:Alpha(record.Edge, "Transparency", 0.78 - selected * 0.08 - energy * 0.16)
	self.UI:Alpha(record.Accent, "Transparency", 1 - selected * (0.60 + pulse * 0.03) - energy * 0.12)
	self.UI:Alpha(record.Lip, "BackgroundTransparency", 0.94 - selected * 0.10 - energy * 0.12)
end

function VFX:BindButton(record)
	if record.Bound then return end
	record.Bound = true
	record.Selection.Value = record.IsSelected and record.IsSelected() and 1 or 0
	table.insert(self.Connections, record.Energy.Changed:Connect(function() if not self.Destroyed then self:ApplyButton(record) end end))
	table.insert(self.Connections, record.Selection.Changed:Connect(function() if not self.Destroyed then self:ApplyButton(record) end end))
	self:ApplyButton(record, true)
end

function VFX:RequestReflection(record)
	if not self.Visible or self.Reduced or not self.Enabled.Border or self.Theme.QualityLevels[self.Quality].Rate == 0 then return end
	if not self:_Shown(record.Button) then return end
	if self.Reflection and self.Reflection.Record == record and self.Time - self.Reflection.Start < 0.15 then return end
	if self.Reflection then self.UI:Alpha(self.Reflection.Record.Sheen, "BackgroundTransparency", 1) end
	self.Reflection = { Record = record, Start = self.Time }
	self.NextReflection = self.Time + 6.5
end

function VFX:InteractButton(record, action)
	if self.Destroyed then return end
	local energy = action == "press" and 1 or (record.Hover and 0.65 or 0)
	self:Tween(record.Energy, 0.16, { Value = energy }, "interaction")
	self:Tween(record.Scale, 0.11, { Scale = not self.Reduced and record.Pressed and 0.985 or 1 }, "interaction")
	if action == "hover" or action == "press" then self:RequestReflection(record) end
end

function VFX:SetButtonSelected(record)
	if not record or self.Destroyed then return end
	local selected = record.IsSelected and record.IsSelected() or false
	self:Tween(record.Selection, 0.16, { Value = selected and 1 or 0 }, "interaction")
	if selected then self:RequestReflection(record) end
end

function VFX:_UpdateButtons(time)
	for _, record in ipairs(self.UI.ButtonStyles) do
		if self:_Shown(record.Button) then
			self:ApplyButton(record)
			if self.Enabled.Border and self.Theme.QualityLevels[self.Quality].Border and (record.Selection.Value > 0.01 or record.Hover) then
				local phase = time * 0.38 + record.Seed
				record.Wash.Offset = Vector2.new(math.sin(phase) * 0.12, math.cos(phase * 0.7) * 0.04)
				record.EdgeGradient.Offset = Vector2.new(math.sin(phase + 0.6) * 0.10, 0)
			end
		end
	end
	if self.Reflection then
		local record = self.Reflection.Record
		local progress = (time - self.Reflection.Start) / 0.8
		if progress >= 1 or not self:_Shown(record.Button) then
			self.UI:Alpha(record.Sheen, "BackgroundTransparency", 1)
			self.Reflection = nil
		else
			record.Sweep.Offset = Vector2.new(-1.1 + 2.2 * progress, 0)
			self.UI:Alpha(record.Sheen, "BackgroundTransparency", 1 - math.sin(progress * PI) ^ 2 * 0.12)
		end
	elseif time >= self.NextReflection then
		self.NextReflection = time + 6.5
		local selected = self.UI.Navigation[self.UI.ActivePage]
		if selected then self:RequestReflection(self.UI.ButtonLookup[selected.Button]) end
	end
end

function VFX:_MakeEffects()
	local ui, colors = self.UI, self.Theme.Colors
	local maxEmbers = math.min(self.Theme.QualityLevels.Ultra.Embers, 16)
	-- One reusable glass-like surface reflection, clipped inside the panel.
	-- Gradients and their sequences are created once; only Offset/alpha animate.
	local host = ui:Make("Frame", ui.Surface, { Name = "ObsidianReflection", Position = UDim2.fromOffset(6, 6),
		Size = UDim2.new(1, -12, 1, -12), ClipsDescendants = true, Visible = false, ZIndex = 11 })
	local crimson = ui:Make("Frame", host, { Name = "CrimsonReflectionTint", Size = UDim2.fromScale(1, 1),
		BackgroundColor3 = colors.Crimson, BackgroundTransparency = 1, ZIndex = 11 })
	local silver = ui:Make("Frame", host, { Name = "SilverReflection", Size = UDim2.fromScale(1, 1),
		BackgroundColor3 = Color3.new(1, 1, 1), BackgroundTransparency = 1, ZIndex = 12 })
	local silverSweep = ui:Gradient(silver, { colors.Silver, colors.Bone, colors.Silver }, 24, NumberSequence.new({
		NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(0.38, 1), NumberSequenceKeypoint.new(0.48, 0.18),
		NumberSequenceKeypoint.new(0.52, 0), NumberSequenceKeypoint.new(0.62, 1), NumberSequenceKeypoint.new(1, 1),
	}))
	local crimsonSweep = ui:Gradient(crimson, { colors.Crimson, colors.BrightCrimson, colors.Crimson }, 24, NumberSequence.new({
		NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(0.30, 1), NumberSequenceKeypoint.new(0.48, 0),
		NumberSequenceKeypoint.new(0.70, 1), NumberSequenceKeypoint.new(1, 1),
	}))
	self.SurfaceReflection = { Host = host, Silver = silver, Crimson = crimson, SilverSweep = silverSweep, CrimsonSweep = crimsonSweep }
	for i = 1, maxEmbers do
		local size = 1.2 + unit(i) * 1.8
		local node = ui:Make("Frame", ui.EmberLayer, { Name = "Ember" .. i, AnchorPoint = Vector2.new(0.5, 0.5),
			Size = UDim2.fromOffset(size, size), BackgroundColor3 = i % 4 == 0 and colors.BrightCrimson or colors.Crimson,
			BackgroundTransparency = 1, Visible = false, ZIndex = 4 })
		ui:Corner(node, 2)
		table.insert(self.Embers, { Node = node, Seed = i * 1.319, Duration = 5.5 + unit(i + 17) * 5 })
	end
	local fade = NumberSequence.new({ NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(0.45, 0.08),
		NumberSequenceKeypoint.new(0.6, 0), NumberSequenceKeypoint.new(1, 1) })
	for i = 1, 4 do
		local vertical = i == 2 or i == 4
		local host = ui:Make("Frame", ui.Window, { Name = "BorderTrack" .. i, ClipsDescendants = true, ZIndex = 50, Visible = false })
		local halo = ui:Make("Frame", host, { Name = "CrimsonHalo", BackgroundColor3 = colors.Crimson,
			BackgroundTransparency = 0.86, ZIndex = 50 })
		local line = ui:Make("Frame", host, { Name = "CrimsonFlow", BackgroundColor3 = Color3.new(1, 1, 1),
			BackgroundTransparency = 0.22, ZIndex = 51 })
		ui:Gradient(halo, { colors.CrimsonShade, colors.BrightCrimson, colors.CrimsonShade }, vertical and 90 or 0, fade)
		ui:Gradient(line, { colors.Crimson, colors.BrightCrimson, colors.Silver, colors.Crimson }, vertical and 90 or 0, fade)
		table.insert(self.Edges, { Host = host, Line = line, Halo = halo, Vertical = vertical, Reverse = i >= 3 })
	end
end

function VFX:_UpdateSurfaceReflection(time)
	local reflection = self.SurfaceReflection
	if not self.Enabled.Reflection then reflection.Host.Visible = false; return end
	if not self.SurfaceSweepStart then
		if time < self.NextSurfaceReflection then reflection.Host.Visible = false; return end
		self.SurfaceSweepStart = time
	end
	local config = self.Theme.Reflection
	local progress = (time - self.SurfaceSweepStart) / math.max(0.4, config.Duration)
	if progress >= 1 then
		reflection.Host.Visible = false
		self.SurfaceSweepStart = nil
		self.NextSurfaceReflection = time + math.max(1, config.Interval)
		self.UI:Alpha(reflection.Silver, "BackgroundTransparency", 1)
		self.UI:Alpha(reflection.Crimson, "BackgroundTransparency", 1)
		return
	end
	local travel = progress * progress * (3 - 2 * progress)
	local envelope = math.sin(progress * PI) ^ 2
	reflection.Host.Visible = true
	reflection.SilverSweep.Offset = Vector2.new(-1.25 + 2.5 * travel, 0)
	reflection.CrimsonSweep.Offset = Vector2.new(-1.34 + 2.5 * travel, 0)
	self.UI:Alpha(reflection.Silver, "BackgroundTransparency", 1 - envelope * math.clamp(config.Opacity, 0, 0.18))
	self.UI:Alpha(reflection.Crimson, "BackgroundTransparency", 1 - envelope * math.clamp(config.TintOpacity, 0, 0.06))
end

function VFX:_StopLoop()
	if self.Heartbeat then self.Heartbeat:Disconnect(); self.Heartbeat = nil end
	self.Accumulator = 0
	self.SurfaceSweepStart = nil
	if self.SurfaceReflection then
		self.SurfaceReflection.Host.Visible = false
		self.UI:Alpha(self.SurfaceReflection.Silver, "BackgroundTransparency", 1)
		self.UI:Alpha(self.SurfaceReflection.Crimson, "BackgroundTransparency", 1)
	end
	for _, particle in ipairs(self.Embers) do particle.Node.Visible = false end
	for _, edge in ipairs(self.Edges) do edge.Host.Visible = false end
	if self.Reflection then self.UI:Alpha(self.Reflection.Record.Sheen, "BackgroundTransparency", 1) end
	self.Reflection = nil
	for _, record in ipairs(self.UI.ButtonStyles) do self:ApplyButton(record, true) end
end

function VFX:_StartLoop()
	self:_StopLoop()
	if self.Destroyed or not self.Visible or self.Reduced or not self.UI.Gui.Enabled then return end
	local budget = self.Theme.QualityLevels[self.Quality]
	if budget.Rate <= 0 then return end
	local interval = 1 / math.clamp(budget.Rate, 10, 60)
	self:_Update(self.Time, budget)
	self.Heartbeat = RunService.Heartbeat:Connect(function(dt)
		self.Time += dt
		self.Accumulator += dt
		if self.Accumulator < interval then return end
		local elapsed = self.Accumulator
		self.Accumulator %= interval
		self.Burst = math.max(0, self.Burst - elapsed * 1.7)
		self:_Update(self.Time, budget)
	end)
end

function VFX:_Update(time, budget)
	local ui = self.UI
	local width, height = ui.Window.AbsoluteSize.X, ui.Window.AbsoluteSize.Y
	if width < 50 or height < 50 then return end
	self:_UpdateSurfaceReflection(time)
	for i, particle in ipairs(self.Embers) do
		local node = particle.Node
		node.Visible = i <= budget.Embers and self.Enabled.Embers
		if node.Visible then
			local age = (time / particle.Duration + unit(particle.Seed)) % 1
			local side = i % 2 == 0 and -1 or 1
			local borderX = side < 0 and 0 or width
			local x = borderX + side * (7 + unit(particle.Seed + 5) * 12) + math.sin(age * 5 + particle.Seed) * 7
			node.Position = UDim2.fromOffset(x, height + 10 - age * height * 0.88)
			ui:Alpha(node, "BackgroundTransparency", 1 - math.sin(age * PI) ^ 2 * (0.30 + unit(particle.Seed) * 0.30))
		end
	end
	if budget.Border and self.Enabled.Border then
		self:_Border(time, width, height)
		ui.WindowMetal.Offset = Vector2.new(math.sin(time * 0.24) * 0.12, 0)
	end
	self:_UpdateButtons(time)
end

function VFX:_Border(time, width, height)
	local perimeter = 2 * (width + height)
	local head = (time * 64) % perimeter
	local tail, start = math.min(160, width * 0.25), 0
	for i, edge in ipairs(self.Edges) do
		local length = edge.Vertical and height or width
		local distance = (head - start + perimeter) % perimeter
		local active = distance <= length + tail
		edge.Host.Visible = active
		if active then
			if i == 1 then edge.Host.Position = UDim2.fromOffset(0, -4)
			elseif i == 2 then edge.Host.Position = UDim2.fromOffset(width - 4, 0)
			elseif i == 3 then edge.Host.Position = UDim2.fromOffset(0, height - 4)
			else edge.Host.Position = UDim2.fromOffset(-4, 0) end
			edge.Host.Size = edge.Vertical and UDim2.fromOffset(9, height) or UDim2.fromOffset(width, 9)
			local offset = edge.Reverse and length - distance or distance - tail
			edge.Line.Position = edge.Vertical and UDim2.fromOffset(4, offset) or UDim2.fromOffset(offset, 4)
			edge.Line.Size = edge.Vertical and UDim2.fromOffset(1, tail) or UDim2.fromOffset(tail, 1)
			edge.Halo.Position = edge.Vertical and UDim2.fromOffset(1, offset) or UDim2.fromOffset(offset, 1)
			edge.Halo.Size = edge.Vertical and UDim2.fromOffset(7, tail) or UDim2.fromOffset(tail, 7)
			self.UI:Alpha(edge.Line, "BackgroundTransparency", 0.27 - self.Burst * 0.12)
			self.UI:Alpha(edge.Halo, "BackgroundTransparency", 0.90 - self.Burst * 0.06)
		end
		start += length
	end
end

function VFX:PulseBorder()
	self.Burst = 1
end
function VFX:SetQuality(_requestedQuality)
	-- Compatibility with integrations using the earlier setter: the shipped UI
	-- always stays on Ultra and exposes no quality or appearance selector.
	self.Quality = "Ultra"
	self.UI.Gui:SetAttribute("VFXQuality", self.Quality)
	self:_StartLoop()
	return self.Quality
end
function VFX:_RefreshReducedMotion()
	local systemReduced = false
	if self.Theme.RespectSystemReduceMotion then
		local ok, value = pcall(function() return GuiService.ReducedMotionEnabled end)
		systemReduced = ok and value == true
	end
	self.Reduced = self.UserReduced or systemReduced
	self.UI.Gui:SetAttribute("ReducedMotion", self.Reduced)
	if self.Reduced then
		self:CancelGroup("navigation")
		self:_NormalizePages()
		for _, record in ipairs(self.UI.ButtonStyles) do
			self:CancelTween(record.Scale)
			record.Scale.Scale = 1
		end
	end
	self:_StartLoop()
end
function VFX:SetReducedMotion(reduced)
	self.UserReduced = reduced == true
	self:_RefreshReducedMotion()
end
function VFX:SetEffect(name, enabled)
	assert(self.Enabled[name] ~= nil, "Unknown Faithful effect")
	self.Enabled[name] = enabled == true
	self.UI.Gui:SetAttribute("Effect" .. name, self.Enabled[name])
	self:_StartLoop()
end

function VFX:_NormalizePages()
	self.CurrentPage = self.UI.ActivePage
	for name, page in pairs(self.UI.Pages) do
		self:CancelTween(page)
		self:CancelTween(self.Factors["page:" .. name])
		page.Position = UDim2.fromOffset(0, self.Theme.Layout.PageTop)
		page.Visible = name == self.CurrentPage
		self.Factors["page:" .. name].Value = name == self.CurrentPage and 1 or 0
	end
	self.UI.PageTitle.Text = self.CurrentPage
end

function VFX:SwitchPage(name)
	self.NavigationVersion += 1
	local version = self.NavigationVersion
	self:CancelGroup("navigation")
	self:PulseBorder()
	local oldName = self.CurrentPage
	local oldPage = self.UI.Pages[oldName]
	for key, page in pairs(self.UI.Pages) do
		if key ~= oldName then
			page.Visible = false
			self.Factors["page:" .. key].Value = 0
			page.Position = UDim2.fromOffset(0, self.Theme.Layout.PageTop)
		end
	end
	if oldName == name then
		self:Tween(self.Factors["page:" .. name], 0.1, { Value = 1 }, "navigation")
		self:Tween(oldPage, 0.1, { Position = UDim2.fromOffset(0, self.Theme.Layout.PageTop) }, "navigation")
		return
	end
	local function reveal()
		if version ~= self.NavigationVersion or self.Destroyed then return end
		oldPage.Visible = false
		oldPage.Position = UDim2.fromOffset(0, self.Theme.Layout.PageTop)
		self.CurrentPage = name
		local page = self.UI.Pages[name]
		self.UI.PageTitle.Text = name
		page.Visible = true
		page.Position = UDim2.fromOffset(0, self.Theme.Layout.PageTop + (self.Reduced and 0 or 7))
		self.Factors["page:" .. name].Value = 0
		self:Tween(self.Factors["page:" .. name], self.Theme.Timings.PageIn, { Value = 1 }, "navigation")
		self:Tween(page, self.Theme.Timings.PageIn, { Position = UDim2.fromOffset(0, self.Theme.Layout.PageTop) }, "navigation")
	end
	if not self.Visible then self:_NormalizePages(); return end
	self:Tween(self.Factors["page:" .. oldName], self.Theme.Timings.PageOut, { Value = 0 }, "navigation", reveal)
end

function VFX:SetVisible(visible)
	if self.Destroyed then return end
	self.VisibilityVersion += 1
	self.NavigationVersion += 1
	local version = self.VisibilityVersion
	self.Visible = visible
	self:CancelGroup("navigation")
	self:CancelGroup("interaction", true)
	self.UI:CancelDelay("entrance")
	self:CancelTween(self.Factors.shell)
	self:CancelTween(self.Factors.logo)
	self:_StopLoop()
	self:_NormalizePages()
	if visible then
		-- A short contained reflection follows the header reveal.
		self.NextSurfaceReflection = self.Time + 0.20
		self.UI.Window.Visible = true
		self.UI.Logo.Visible = true
		self.UI.Launcher.Visible = false
		self.UI.Gui:SetAttribute("State", "Open")
		self.Factors.logo.Value = 0
		self:FadeScope("shell", 1, self.Theme.Timings.Entrance)
		self.UI:Delay("entrance", self.Reduced and 0 or 0.09, function()
			if version ~= self.VisibilityVersion or not self.Visible then return end
			self:FadeScope("logo", 1, 0.15)
			self:PulseBorder()
			self:_StartLoop()
		end)
	else
		self.UI:CancelDelay("toast")
		self.UI.Toast.Visible = false
		self:FadeScope("toast", 0, 0)
		self.UI.Gui:SetAttribute("State", "Hidden")
		self:FadeScope("shell", 0, self.Theme.Timings.Exit, function()
			if version ~= self.VisibilityVersion then return end
			self.UI.Window.Visible = false
			self.UI.Logo.Visible = false
			self.UI.Launcher.Visible = true
		end)
	end
end

function VFX:Destroy()
	if self.Destroyed then return end
	self:_StopLoop()
	self.Destroyed = true
	self.UI:CancelDelay("entrance")
	local objects = {}
	for object in pairs(self.Tweens) do table.insert(objects, object) end
	for _, object in ipairs(objects) do self:CancelTween(object) end
	for _, connection in ipairs(self.Connections) do connection:Disconnect() end
	for _, factor in pairs(self.Factors) do factor:Destroy() end
	self.Connections = {}
end

function VFX.new(ui, theme)
	local self = setmetatable({ UI = ui, Theme = theme, Factors = {}, ByScope = {},
		Tweens = {}, Connections = {}, Embers = {}, Edges = {}, Quality = "Ultra",
		UserReduced = theme.ReduceMotion, Reduced = false,
		Enabled = { Reflection = theme.Effects.Reflection, Embers = theme.Effects.Embers, Border = theme.Effects.Border },
		NextReflection = 4, NextSurfaceReflection = 0.20,
		Visible = false, Destroyed = false, Time = 0, Accumulator = 0, Burst = 0,
		CurrentPage = ui.ActivePage, NavigationVersion = 0, VisibilityVersion = 0,
	}, VFX)
	assert(theme.QualityLevels.Ultra, "Faithful requires its fixed Ultra preset")
	local scopes = { "shell", "logo", "toast", "modal" }
	for name in pairs(ui.Pages) do table.insert(scopes, "page:" .. name) end
	for _, name in ipairs(scopes) do
		local factor = Instance.new("NumberValue")
		factor.Name = name
		factor.Value = name == "page:" .. ui.ActivePage and 1 or 0
		self.Factors[name] = factor
		table.insert(self.Connections, factor.Changed:Connect(function() self:_Refresh(name) end))
	end
	for _, entry in ipairs(ui.AlphaEntries) do self:RegisterEntry(entry) end
	ui.VFX = self
	self:_MakeEffects()
	for _, record in ipairs(ui.ButtonStyles) do self:BindButton(record) end
	for name, enabled in pairs(self.Enabled) do ui.Gui:SetAttribute("Effect" .. name, enabled) end
	-- ReducedMotionEnabled is read defensively for older client/API environments.
	local ok, signal = pcall(function() return GuiService:GetPropertyChangedSignal("ReducedMotionEnabled") end)
	if ok then table.insert(self.Connections, signal:Connect(function() self:_RefreshReducedMotion() end)) end
	table.insert(self.Connections, ui.Gui:GetPropertyChangedSignal("Enabled"):Connect(function() self:_StartLoop() end))
	self:_RefreshReducedMotion()
	ui.Gui:SetAttribute("VFXQuality", self.Quality)
	return self
end

return VFX
