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
local effects = VFX.new(ui, Theme, Assets)
local function check(condition, text)
	assert(condition, "[Faithful native check] " .. text)
	print("[Faithful native check] PASS: " .. text)
end

local ok, reason = xpcall(function()
	ui:SetOpen(true)
	task.wait(0.6)
	local count = #ui.Gui:GetDescendants()
	check(ui.Window.Visible and effects.Factors.shell.Value == 1, "Entrance")
	check(math.abs(ui.Background.ImageTransparency - 0.78) < 0.0001, "Background alpha")
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
	check(effects.Heartbeat == nil, "Minimal has no ambient loop")
	effects:SetQuality("Ultra")
	effects:SetReducedMotion(true)
	check(effects.Heartbeat == nil, "Reduced motion")
	effects:SetReducedMotion(false)
	-- External destruction is an independent lifecycle path.
	ui.Gui:Destroy()
	task.wait(0.1)
	check(ui.Destroyed and effects.Destroyed and effects.Heartbeat == nil, "External GUI destruction")
	check(next(ui.Threads) == nil and next(effects.Tweens) == nil, "Tracked tasks and tweens released")
end, debug.traceback)
ui:Destroy()
if not ok then error(reason) end
print("[Faithful] Native smoke checks completed. Visual QA and device profiling remain separate.")
