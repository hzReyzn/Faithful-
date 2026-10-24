--!strict
-- Change these settings before initialization; no gameplay settings live here.
local Theme = {
	Name = "Faithful",
	Owner = "Faithful.NativeUI.v1",
	Version = "1.0.0",
	Build = "attached-wordmark-ultra-mist-20261024",
	Colors = {
		Obsidian = Color3.fromHex("090A0D"),
		Charcoal = Color3.fromHex("15161C"),
		Crimson = Color3.fromHex("8B1E32"),
		BrightCrimson = Color3.fromHex("C72C47"),
		Silver = Color3.fromHex("BEB8B8"),
		Bone = Color3.fromHex("E5DDDA"),
		Muted = Color3.fromRGB(139, 133, 137),
		Metal = Color3.fromRGB(83, 77, 83),
		SteelLight = Color3.fromRGB(152, 139, 143),
		MetalDark = Color3.fromRGB(33, 26, 32),
		CrimsonShade = Color3.fromRGB(44, 12, 23),
	},
	Fonts = { Body = Enum.Font.Gotham, Medium = Enum.Font.GothamMedium, Display = Enum.Font.Garamond },
	Layout = {
		Width = 860, Height = 480, Margin = 18, Header = 56,
		MaxViewportHeight = 0.88,
		Sidebar = 148, CompactSidebar = 108, CompactAt = 580,
		Radius = 8, WordmarkWidth = 170, WordmarkHeight = 44, DisplayOrder = 40,
		PageTop = 56, NavigationHeight = 46, NavigationGap = 7,
	},
	-- The original 0.78 made artwork nearly invisible; show the supplied image
	-- at 62% opacity while keeping the controls on dark readable surfaces.
	BackgroundReferenceTransparency = 0.83,
	BackgroundTransparencyReduction = 0.45,
	Quality = "Ultra", -- Fixed preset; no player-facing quality selector.
	ReduceMotion = false,
	RespectSystemReduceMotion = true,
	MistIntensity = 0.90,
	Effects = { Mist = true, Embers = true, Border = true },
	-- Keep all five pages clean. No appearance/quality options are exposed.
	-- Enable this to exercise the generic demonstration components in Main.
	ShowcaseControls = false,
	ConfirmClose = true,
	Timings = { Entrance = 0.24, Exit = 0.16, PageOut = 0.09, PageIn = 0.15, Interaction = 0.13 },
	QualityLevels = {
		Ultra = { Mist = 32, Embers = 18, Border = true, Rate = 30 },
	},
}

return Theme
