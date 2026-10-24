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

function VFX:_MakePools()
	local ui, colors = self.UI, self.Theme.Colors
	local maxMist, maxEmbers = 0, 0
	for _, budget in pairs(self.Theme.QualityLevels) do
		maxMist = math.max(maxMist, budget.Mist)
		maxEmbers = math.max(maxEmbers, budget.Embers)
	end
	-- Cap caller-supplied budgets to prevent accidental runaway allocation.
	maxMist, maxEmbers = math.min(maxMist, 24), math.min(maxEmbers, 32)
	local texture = self.Assets.Resolve(self.Assets.Smoke)
	for i = 1, maxMist do
		local depth = (i - 1) % 3
		local node = ui:Make("ImageLabel", ui.MistLayer, { Name = "Mist" .. i,
			AnchorPoint = Vector2.new(0.5, 0.5), Image = texture, ImageTransparency = 1,
			ScaleType = Enum.ScaleType.Stretch, ZIndex = 3, Visible = false })
		ui:Make("UIGradient", node, {
			Rotation = 90,
			Color = ColorSequence.new({
				ColorSequenceKeypoint.new(0, colors.Obsidian),
				ColorSequenceKeypoint.new(0.50, depth == 2 and colors.BrightCrimson or colors.Crimson),
				ColorSequenceKeypoint.new(1, colors.Obsidian),
			}),
			Transparency = NumberSequence.new({
				NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(0.30, 0.12),
				NumberSequenceKeypoint.new(0.70, 0), NumberSequenceKeypoint.new(1, 0.85),
			}),
		})
		table.insert(self.Mist, { Node = node, Seed = i * 1.731, Depth = depth,
			Duration = 8.4 + depth * 2.2 + unit(i) * 3, Side = i % 2 == 0 and 1 or -1 })
	end
	self.SmokeReady = texture ~= "" and self.Mist[1] ~= nil and self.Mist[1].Node.IsLoaded
	if self.Mist[1] then
		table.insert(self.Connections, self.Mist[1].Node:GetPropertyChangedSignal("IsLoaded"):Connect(function()
			self.SmokeReady = texture ~= "" and self.Mist[1].Node.IsLoaded
		end))
	end
	for i = 1, maxEmbers do
		local node = ui:Make("Frame", ui.EmberLayer, { Name = "Ember" .. i, AnchorPoint = Vector2.new(0.5, 0.5),
			Size = UDim2.fromOffset(1 + unit(i) * 1.5, 1 + unit(i) * 1.5), BackgroundColor3 = i % 4 == 0 and colors.BrightCrimson or colors.Crimson,
			BackgroundTransparency = 1, Visible = false, ZIndex = 4 })
		ui:Corner(node, 2)
		table.insert(self.Embers, { Node = node, Seed = i * 1.319, Duration = 5 + unit(i + 17) * 6 })
	end
	for i = 1, 4 do
		local vertical = i == 2 or i == 4
		local host = ui:Make("Frame", ui.Window, { Name = "BorderTrack" .. i, ClipsDescendants = true, ZIndex = 50, Visible = false })
		local line = ui:Make("Frame", host, { Name = "CrimsonFlow", BackgroundColor3 = colors.BrightCrimson,
			BackgroundTransparency = 0.4, ZIndex = 50 })
		ui:Make("UIGradient", line, { Rotation = vertical and 90 or 0,
			Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(0.45, 0.12),
				NumberSequenceKeypoint.new(0.55, 0.12), NumberSequenceKeypoint.new(1, 1) }) })
		table.insert(self.Edges, { Host = host, Line = line, Vertical = vertical, Reverse = i >= 3 })
	end
end

function VFX:_StopLoop()
	if self.Heartbeat then self.Heartbeat:Disconnect(); self.Heartbeat = nil end
	self.Accumulator = 0
	for _, particle in ipairs(self.Mist) do particle.Node.Visible = false end
	for _, particle in ipairs(self.Embers) do particle.Node.Visible = false end
	for _, edge in ipairs(self.Edges) do edge.Host.Visible = false end
	for _, record in pairs(self.UI.Navigation) do
		self.UI:Alpha(record.Edge, "Transparency", record.Selected and 0.46 or 1)
	end
end
function VFX:_StartLoop()
	self:_StopLoop()
	if self.Destroyed or not self.Visible or self.Reduced then return end
	local budget = self.Theme.QualityLevels[self.Quality]
	if budget.Rate <= 0 then return end
	local interval = 1 / math.clamp(budget.Rate, 10, 60)
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
	local rise = math.min(170, height * 0.38)
	local mistReveal = math.clamp((time - self.MistStartsAt) / 0.65, 0, 1)
	for i, particle in ipairs(self.Mist) do
		local node = particle.Node
		local enabled = i <= budget.Mist and self.SmokeReady and self.Intensity > 0
		node.Visible = enabled
		if enabled then
			local age = (time / particle.Duration + unit(particle.Seed)) % 1
			local envelope = math.sin(age * PI) ^ 2
			local band = 0.025 + unit(particle.Seed + 2) * 0.12
			local originX = particle.Side < 0 and width * band or width * (1 - band)
			local drift = math.sin(time * 0.29 + particle.Seed + age * 3) * (11 + age * 24)
			local spread = 0.72 + age * 0.85
			local baseWidth = math.min(190, width * 0.32) * (1 + particle.Depth * 0.11)
			node.Position = UDim2.fromOffset(originX + drift, height + 18 - age * rise)
			node.Size = UDim2.fromOffset(baseWidth * spread, (64 + particle.Depth * 17) * spread)
			node.Rotation = math.sin(time * 0.21 + particle.Seed) * 11 + particle.Side * age * 9
			-- The front glow is the faintest layer. No additive blending or opaque core.
			local depthAlpha = particle.Depth == 2 and 0.48 or (particle.Depth == 1 and 0.82 or 0.65)
			ui:Alpha(node, "ImageTransparency", 1 - envelope * self.Intensity * depthAlpha * mistReveal)
		end
	end
	for i, particle in ipairs(self.Embers) do
		local node = particle.Node
		node.Visible = i <= budget.Embers
		if node.Visible then
			local age = (time / particle.Duration + unit(particle.Seed)) % 1
			local left = i % 2 == 0
			local edge = 8 + unit(particle.Seed + 5) * math.min(60, width * 0.12)
			local x = left and edge or width - edge
			node.Position = UDim2.fromOffset(x + math.sin(age * 5 + particle.Seed) * 12, height + 4 - age * (height * 0.73))
			ui:Alpha(node, "BackgroundTransparency", 1 - math.sin(age * PI) ^ 2 * (0.22 + unit(particle.Seed) * 0.3))
		end
	end
	if budget.Border then self:_Border(time, width, height) end
	local pulse = math.sin(time * 0.9) ^ 2
	for _, record in pairs(ui.Navigation) do
		if record.Selected then ui:Alpha(record.Edge, "Transparency", 0.50 - pulse * 0.12) end
	end
end

function VFX:_Border(time, width, height)
	local perimeter = 2 * (width + height)
	local head = (time * 43) % perimeter
	local tail, start = 96, 0
	for i, edge in ipairs(self.Edges) do
		local length = edge.Vertical and height or width
		local distance = (head - start + perimeter) % perimeter
		local active = distance <= length + tail
		edge.Host.Visible = active
		if active then
			if i == 1 then edge.Host.Position = UDim2.fromOffset(0, 1)
			elseif i == 2 then edge.Host.Position = UDim2.fromOffset(width - 2, 0)
			elseif i == 3 then edge.Host.Position = UDim2.fromOffset(0, height - 2)
			else edge.Host.Position = UDim2.fromOffset(1, 0) end
			edge.Host.Size = edge.Vertical and UDim2.fromOffset(1, height) or UDim2.fromOffset(width, 1)
			local offset = edge.Reverse and length - distance or distance - tail
			edge.Line.Position = edge.Vertical and UDim2.fromOffset(0, offset) or UDim2.fromOffset(offset, 0)
			edge.Line.Size = edge.Vertical and UDim2.fromOffset(1, tail) or UDim2.fromOffset(tail, 1)
			self.UI:Alpha(edge.Line, "BackgroundTransparency", 0.45 - self.Burst * 0.22)
		end
		start += length
	end
end

function VFX:PulseBorder()
	self.Burst = 1
end
function VFX:SetQuality(quality)
	assert(self.Theme.QualityLevels[quality], "Unknown Faithful VFX quality")
	self.Quality = quality
	self.UI.Gui:SetAttribute("VFXQuality", quality)
	self:_StartLoop()
end
function VFX:_RefreshReducedMotion()
	local systemReduced = false
	if self.Theme.RespectSystemReduceMotion then
		local ok, value = pcall(function() return GuiService.ReducedMotionEnabled end)
		systemReduced = ok and value == true
	end
	self.Reduced = self.UserReduced or systemReduced
	self.UI.Gui:SetAttribute("ReducedMotion", self.Reduced)
	self:_StartLoop()
end
function VFX:SetReducedMotion(reduced)
	self.UserReduced = reduced == true
	self:_RefreshReducedMotion()
	if self.Reduced then
		self:CancelGroup("navigation")
		self:_NormalizePages()
	end
end
function VFX:SetMistIntensity(intensity)
	self.Intensity = math.clamp(intensity, 0, 0.4)
end

function VFX:_NormalizePages()
	self.CurrentPage = self.UI.ActivePage
	for name, page in pairs(self.UI.Pages) do
		self:CancelTween(page)
		self:CancelTween(self.Factors["page:" .. name])
		page.Position = UDim2.fromOffset(0, 66)
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
			page.Position = UDim2.fromOffset(0, 66)
		end
	end
	if oldName == name then
		self:Tween(self.Factors["page:" .. name], 0.1, { Value = 1 }, "navigation")
		self:Tween(oldPage, 0.1, { Position = UDim2.fromOffset(0, 66) }, "navigation")
		return
	end
	local function reveal()
		if version ~= self.NavigationVersion or self.Destroyed then return end
		oldPage.Visible = false
		oldPage.Position = UDim2.fromOffset(0, 66)
		self.CurrentPage = name
		local page = self.UI.Pages[name]
		self.UI.PageTitle.Text = name
		page.Visible = true
		page.Position = UDim2.fromOffset(0, self.Reduced and 66 or 74)
		self.Factors["page:" .. name].Value = 0
		self:Tween(self.Factors["page:" .. name], self.Theme.Timings.PageIn, { Value = 1 }, "navigation")
		self:Tween(page, self.Theme.Timings.PageIn, { Position = UDim2.fromOffset(0, 66) }, "navigation")
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
		-- Begin mist after the logo reveal, then let it gather gradually at the edges.
		self.MistStartsAt = self.Time + 0.15
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

function VFX.new(ui, theme, assets)
	local self = setmetatable({ UI = ui, Theme = theme, Assets = assets, Factors = {}, ByScope = {},
		Tweens = {}, Connections = {}, Mist = {}, Embers = {}, Edges = {}, Quality = theme.Quality,
		UserReduced = theme.ReduceMotion, Reduced = false, Intensity = math.clamp(theme.MistIntensity, 0, 0.4),
		Visible = false, Destroyed = false, Time = 0, MistStartsAt = 0, Accumulator = 0, Burst = 0,
		CurrentPage = ui.ActivePage, NavigationVersion = 0, VisibilityVersion = 0,
	}, VFX)
	assert(theme.QualityLevels[theme.Quality], "Invalid default VFX quality")
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
	self:_MakePools()
	-- ReducedMotionEnabled is read defensively for older client/API environments.
	local ok, signal = pcall(function() return GuiService:GetPropertyChangedSignal("ReducedMotionEnabled") end)
	if ok then table.insert(self.Connections, signal:Connect(function() self:_RefreshReducedMotion() end)) end
	self:_RefreshReducedMotion()
	ui.Gui:SetAttribute("VFXQuality", self.Quality)
	return self
end

return VFX
