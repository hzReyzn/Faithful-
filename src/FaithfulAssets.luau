--!strict
-- Upload the supplied PNGs to your experience's owner/group, then paste their
-- Roblox IMAGE asset IDs here. A GitHub URL or a decal page URL is not an image ID.
local Assets = {
	Background = "BACKGROUND_ASSET_ID", -- assets/FaithfulBackground.png (image 1)
	Logo = "LOGO_ASSET_ID",             -- assets/FaithfulLogo.png (image 2)
	Smoke = "SMOKE_ASSET_ID",           -- assets/CrimsonMist.png (transparent sprite)
	BackgroundContainsTitle = true,
}

function Assets.Resolve(value: string): string
	local digits = value:match("^rbxassetid://(%d+)$") or value:match("^(%d+)$")
	local number = digits and tonumber(digits)
	if digits and number and number > 0 then
		return "rbxassetid://" .. digits
	end
	return "" -- Unconfigured assets never become invented or invalid requests.
end

return Assets
