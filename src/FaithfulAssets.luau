--!nonstrict
-- Native Roblox images take priority. When no ID is configured, compatible
-- executors may cache these fixed PNGs using their local custom-asset API.
-- No downloaded content is ever executed as Lua.
local Assets = {
	Background = "BACKGROUND_ASSET_ID", -- assets/FaithfulBackground.png (image 1)
	Logo = "LOGO_ASSET_ID",             -- assets/FaithfulLogo.png (image 2)
	Wordmark = "WORDMARK_ASSET_ID",     -- assets/FaithfulWordmark.png (header text)
}

-- Pin the existing, reviewed artwork bytes rather than fetching mutable files.
local BASE = "https://raw.githubusercontent.com/hzReyzn/Faithful-/dff138c05914f15c3c84bca1caef13a11969814b/assets/"
local WORDMARK_BASE = "https://raw.githubusercontent.com/hzReyzn/Faithful-/d7b3d966f7449bd3b76d6d6586d85776b6c0f988/assets/"
local remote = {
	Background = { Url = BASE .. "FaithfulBackground.png", File = "Faithful-background-dff138.png", Bytes = 2343282 },
	Logo = { Url = BASE .. "FaithfulLogo.png", File = "Faithful-logo-dff138.png", Bytes = 2561088 },
	Wordmark = { Url = WORDMARK_BASE .. "FaithfulWordmark.png", File = "Faithful-wordmark-d7b3d9.png", Bytes = 387488 },
}

local PNG_MAGIC = "\137PNG\r\n\26\n"
local function validPNG(data, expectedSize)
	return type(data) == "string" and #data == expectedSize and data:sub(1, 8) == PNG_MAGIC
end

function Assets.Resolve(value: string): string
	local digits = value:match("^rbxassetid://(%d+)$") or value:match("^(%d+)$")
	local number = digits and tonumber(digits)
	if digits and number and number > 0 then
		return "rbxassetid://" .. digits
	end
	return "" -- Unconfigured assets never become invented or invalid requests.
end

-- Roblox Studio has no getcustomasset/writefile functions. It continues to use
-- the configured Roblox image IDs and never calls HttpGet through this path.
function Assets.LoadFromRepository(name: string): (string, string)
	local entry = remote[name]
	if not entry then return "", "Unknown" end
	local customAsset = getcustomasset or getsynasset
	if type(customAsset) ~= "function" or type(writefile) ~= "function" then
		return "", "NeedsRobloxId"
	end

	local cached = false
	if type(isfile) == "function" and type(readfile) == "function" then
		local ok, bytes = pcall(function()
			if isfile(entry.File) then return readfile(entry.File) end
		end)
		cached = ok and validPNG(bytes, entry.Bytes)
	end

	if not cached then
		local downloaded = false
		for _ = 1, 2 do
			local ok, bytes = pcall(function() return game:HttpGet(entry.Url) end)
			if ok and validPNG(bytes, entry.Bytes) then
				local wrote = pcall(writefile, entry.File, bytes)
				if wrote then downloaded = true; break end
			end
		end
		if not downloaded then return "", "DownloadFailed" end
	end

	local ok, uri = pcall(customAsset, entry.File)
	if not ok or type(uri) ~= "string" or uri == "" then return "", "RegistrationFailed" end
	return uri, "Assigned"
end

return Assets
