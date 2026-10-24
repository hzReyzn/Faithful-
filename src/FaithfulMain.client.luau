--!nonstrict
-- StarterPlayer > StarterPlayerScripts > Faithful (Folder) > FaithfulMain (LocalScript)
local Theme = require(script.Parent:WaitForChild("FaithfulTheme"))
local Assets = require(script.Parent:WaitForChild("FaithfulAssets"))
local FaithfulUI = require(script.Parent:WaitForChild("FaithfulUI"))
local FaithfulVFX = require(script.Parent:WaitForChild("FaithfulVFX"))

local Players = game:GetService("Players")
local ContentProvider = game:GetService("ContentProvider")
local player = Players.LocalPlayer
assert(player, "FaithfulMain must run as a LocalScript on the client")
local playerGui = player:WaitForChild("PlayerGui")

-- Each previous instance owns its cleanup via Destroying; only Faithful-owned GUIs retire.
for _, previous in ipairs(playerGui:GetChildren()) do
	if previous:IsA("ScreenGui") and previous.Name == "Faithful" and previous:GetAttribute("FaithfulOwner") == Theme.Owner then
		previous:Destroy()
	end
end

local ui = FaithfulUI.new(playerGui, Theme, Assets)
FaithfulVFX.new(ui, Theme)
if script then ui:Connect(script.Destroying, function() ui:Destroy() end) end
ui:SetOpen(true)

-- A configured Roblox image ID works in Studio. Without an ID, compatible
-- executors can fetch only the pinned PNG artwork from this project's GitHub.
-- The UI is created first; downloading cannot block the controls or session clock.
local requested = {}
for _, name in ipairs({ "Background", "Logo", "Wordmark" }) do
	local asset = Assets.Resolve(Assets[name])
	ui.Gui:SetAttribute("Asset" .. name, "Loading")
	if asset ~= "" then
		table.insert(requested, asset)
	else
		ui:Spawn("asset:" .. name, function()
			local uri, status = Assets.LoadFromRepository(name)
			if ui.Destroyed then return end
			if uri == "" then
				ui.Gui:SetAttribute("Asset" .. name, status)
				if status ~= "NeedsRobloxId" then warn("[Faithful] " .. name .. " artwork: " .. status) end
				return
			end

			local target
			if name == "Background" then
				ui.Background.Image = uri
				target = ui.Background
			elseif name == "Logo" then
				ui.Launcher.Image = uri
				target = ui.Launcher
			elseif name == "Wordmark" then
				ui.Logo.Image = uri
				target = ui.Logo
			end
			ui.Gui:SetAttribute("Asset" .. name, target and target.IsLoaded and "Ready" or "Assigned")
			if target then
				ui:Connect(target:GetPropertyChangedSignal("IsLoaded"), function()
					if target.IsLoaded then ui.Gui:SetAttribute("Asset" .. name, "Ready") end
				end)
			end
		end)
	end
end
if #requested > 0 then
	ui:Spawn("preload", function()
		local ok, reason = pcall(function()
			ContentProvider:PreloadAsync(requested, function(asset, status)
				if ui.Destroyed then return end
				for _, name in ipairs({ "Background", "Logo", "Wordmark" }) do
					if Assets.Resolve(Assets[name]) == asset then ui.Gui:SetAttribute("Asset" .. name, status.Name) end
				end
			end)
		end)
		if not ok and not ui.Destroyed then warn("[Faithful] Asset preload failed: " .. tostring(reason)) end
	end)
end

-- A developer can hold this controller in an integration; it never changes gameplay.
return ui
