--!strict
-- Change these settings before initialization; no gameplay settings live here.
local Theme = {
	Name = "Faithful",
	Owner = "Faithful.NativeUI.v1",
	Version = "1.0.0",
	Colors = {
		Obsidian = Color3.fromHex("090A0D"),
		Charcoal = Color3.fromHex("15161C"),
		Crimson = Color3.fromHex("8B1E32"),
		BrightCrimson = Color3.fromHex("C72C47"),
		Silver = Color3.fromHex("BEB8B8"),
		Bone = Color3.fromHex("E5DDDA"),
		Muted = Color3.fromRGB(139, 133, 137),
		Metal = Color3.fromRGB(83, 77, 83),
	},
	Fonts = { Body = Enum.Font.Gotham, Medium = Enum.Font.GothamMedium, Display = Enum.Font.Garamond },
	Layout = {
		Width = 940, Height = 528, Margin = 16, Header = 58,
		Sidebar = 160, CompactSidebar = 98, CompactAt = 600,
		Radius = 7, LogoSize = 44, DisplayOrder = 40,
	},
	-- The original 0.78 made artwork nearly invisible; show the supplied image
	-- at 62% opacity while keeping the controls on dark readable surfaces.
	BackgroundReferenceTransparency = 0.83,
	BackgroundTransparencyReduction = 0.45,
	Quality = "Ultra",
	ReduceMotion = false,
	RespectSystemReduceMotion = true,
	MistIntensity = 0.24,
	-- The requested clean default exposes only the five navigation categories.
	-- Enable this to exercise every reusable component and appearance settings.
	ShowcaseControls = false,
	ConfirmClose = true,
	Timings = { Entrance = 0.24, Exit = 0.16, PageOut = 0.09, PageIn = 0.15, Interaction = 0.13 },
	QualityLevels = {
		Minimal = { Mist = 0, Embers = 0, Border = false, Rate = 0 },
		Balanced = { Mist = 0, Embers = 6, Border = true, Rate = 30 },
		Ultra = { Mist = 12, Embers = 14, Border = true, Rate = 30 },
	},
}

return Theme
