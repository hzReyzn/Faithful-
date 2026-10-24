--!nonstrict
-- OPTIONAL native test. Run this instead of FaithfulMain, never alongside it.
-- Put this LocalScript next to the four ModuleScripts in the Faithful folder.
-- This file was compiled here but has NOT been executed in Roblox Studio.
local Players = game:GetService("Players")
local Theme = require(script.Parent:WaitForChild("FaithfulTheme"))
local Assets = require(script.Parent:WaitForChild("FaithfulAssets"))
local UI = require(script.Parent:WaitForChild("FaithfulUI"))
local VFX = require(script.Parent:WaitForChild("FaithfulVFX"))
local playerGui = Players.LocalPlayer:WaitForChild("PlayerGui")
local ui = UI.new(playerGui, Theme, Assets)
local effects = VFX.new(ui, Theme)
local function check(condition, text)
	assert(condition, "[Faithful native check] " .. text)
	print("[Faithful native check] PASS: " .. text)
end

local ok, reason = xpcall(function()
	ui:SetOpen(true)
	task.wait(0.6)
	local count = #ui.Gui:GetDescendants()
	check(ui.Window.Visible and effects.Factors.shell.Value == 1, "Entrance")
	check(math.abs(ui.Background.ImageTransparency - 0.38) < 0.0001, "Background alpha")
	check(effects.Mist == nil and #effects.Embers == 8, "Smoke removed and embers bounded")
	check(effects.SurfaceReflection.Host.Parent == ui.Surface and ui.Surface.ClipsDescendants, "Reflection stays inside panel")
	check(ui.Theme.Layout.Width == 780 and ui.Theme.Layout.Height == 440, "Smaller base dimensions")
	check(ui.Appearance == nil and ui.QualityBadge == nil, "No appearance or quality controls")
	check(ui.Logo.Parent == ui.Header, "Attached header wordmark")
	check(ui.Background:FindFirstChildOfClass("UIGradient") == nil, "Background title is unmasked")
	check(effects:SetQuality("Balanced") == "Ultra", "Fixed Ultra profile")
	local oldWindow = ui.Window.Position
	local oldLogo = ui.Logo.AbsolutePosition
	ui.Window.Position = oldWindow + UDim2.fromOffset(20, 15)
	task.wait(0.1)
	check((ui.Logo.AbsolutePosition - oldLogo - Vector2.new(20, 15)).Magnitude < 1, "Wordmark follows window movement")
	ui:ResetLayout()
	for i = 1, 30 do
		ui:SelectCategory(i % 2 == 0 and "Main" or "Visuals")
		task.wait(0.02)
		ui:SetOpen(false)
		task.wait(0.02)
		ui:SetOpen(true)
	end
	ui:SelectCategory("Settings")
	task.wait(0.5)
	check(ui.Pages.Settings.Visible and not ui.Pages.Main.Visible, "Rapid navigation")
	check(#ui.Gui:GetDescendants() == count, "Stable GUI instance count after 30 cycles")
	ui:SetOpen(false)
	task.wait(0.4)
	local seconds = ui.ActiveSeconds
	check(effects.Heartbeat == nil and next(effects.Tweens) == nil, "No ambient loop or tween while hidden")
	task.wait(1.1)
	check(ui.ActiveSeconds == seconds and ui.ClockStart == nil, "Timer pauses")
	ui:SetOpen(true)
	task.wait(0.5)
	effects:SetQuality("Minimal")
	check(effects.Quality == "Ultra", "Minimal request cannot change Ultra")
	effects:SetQuality("Ultra")
	effects:SetReducedMotion(true)
	check(effects.Heartbeat == nil and not effects.SurfaceReflection.Host.Visible, "Reduced motion")
	effects:SetReducedMotion(false)
	ui.Gui.Enabled = false
	task.wait(0.3)
	local disabledSeconds = ui.ActiveSeconds
	check(effects.Heartbeat == nil and ui.ClockStart == nil, "ScreenGui disable suspends work")
	task.wait(0.2)
	check(ui.ActiveSeconds == disabledSeconds, "Disabled ScreenGui pauses timer")
	ui.Gui.Enabled = true
	task.wait(0.1)
	check(ui.ClockStart ~= nil, "ScreenGui enable resumes timer")
	-- External destruction is an independent lifecycle path.
	ui.Gui:Destroy()
	task.wait(0.1)
	check(ui.Destroyed and effects.Destroyed and effects.Heartbeat == nil, "External GUI destruction")
	check(next(ui.Threads) == nil and next(effects.Tweens) == nil, "Tracked tasks and tweens released")
end, debug.traceback)
ui:Destroy()
if not ok then error(reason) end
print("[Faithful] Native smoke checks completed. Visual QA and device profiling remain separate.")
