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
FaithfulVFX.new(ui, Theme, Assets)
if script then ui:Connect(script.Destroying, function() ui:Destroy() end) end
ui:SetOpen(true)

-- Native Roblox delivery only. No HTTP downloads, dynamic execution or executor APIs.
-- Preloading runs separately, so missing permissions/assets cannot block the controls.
local requested = {}
for _, name in ipairs({ "Background", "Logo", "Smoke" }) do
	local asset = Assets.Resolve(Assets[name])
	ui.Gui:SetAttribute("Asset" .. name, asset == "" and "Unconfigured" or "Loading")
	if asset ~= "" then table.insert(requested, asset) end
end
if #requested > 0 then
	ui:Spawn("preload", function()
		local ok, reason = pcall(function()
			ContentProvider:PreloadAsync(requested, function(asset, status)
				if ui.Destroyed then return end
				for _, name in ipairs({ "Background", "Logo", "Smoke" }) do
					if Assets.Resolve(Assets[name]) == asset then ui.Gui:SetAttribute("Asset" .. name, status.Name) end
				end
			end)
		end)
		if not ok and not ui.Destroyed then warn("[Faithful] Asset preload failed: " .. tostring(reason)) end
	end)
end

-- A developer can hold this controller in an integration; it never changes gameplay.
return ui
