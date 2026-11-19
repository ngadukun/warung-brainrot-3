-- Config.luau — every tuning number for Warung Brainrot in one module.
-- Services require this instead of scattering magic numbers around.

local Config = {}

-- Economy
Config.StartCash = 150
Config.TickSeconds = 1

-- Conveyor belt (runs along Z through the middle of the market)
Config.BeltX = 0
Config.BeltStartZ = -30
Config.BeltEndZ = 30
Config.BeltSurfaceY = 0.4
Config.BeltSpawnInterval = 4
Config.BeltMaxBrainrots = 8
Config.BeltWalkSpeed = 3
Config.WalkHomeSpeed = 14
Config.BuyPromptDistance = 12

-- Base plots and slots
Config.StartSlots = 6
Config.MaxSlots = 10
Config.SlotBasePrice = 500 -- price of the next slot is SlotBasePrice * 2^(owned - StartSlots)
Config.PadSurfaceY = 0.7

-- Steal and lock
Config.StealHoldSeconds = 2.5
Config.StealPromptDistance = 10
Config.LockSeconds = 20
Config.LockCooldownSeconds = 60

-- How far a player may stand from a plot's centre and still count as
-- "inside a base" (depositing a steal, sheltering from the krupuk wave).
Config.BaseSafeMargin = 11

-- Events (alternate Hujan Krupuk -> Lampu Disko -> ...)
Config.EventInterval = 100
Config.KrupukWarningSeconds = 5
Config.KrupukSweepSeconds = 3.5
Config.DiscoSeconds = 30
Config.DiscoFactor = 2
Config.EventDisplayNames = {
	Krupuk = "Hujan Krupuk",
	Disco = "Lampu Disko",
}

-- Rebirth
Config.RebirthThreshold = 25000
Config.RebirthMultiplierStep = 0.5

-- Mutations, rolled in this order at spawn: Rainbow, then Diamond, then Gold.
Config.Mutations = {
	{ key = "Rainbow", prefix = "✦ RAINBOW ", chance = 0.005, factor = 10, scale = 1.45, color = nil },
	{ key = "Diamond", prefix = "◆ DIAMOND ", chance = 0.03, factor = 5, scale = 1.3, color = Color3.fromRGB(130, 235, 255) },
	{ key = "Gold", prefix = "★ GOLD ", chance = 0.08, factor = 2, scale = 1.15, color = Color3.fromRGB(255, 200, 40) },
}

-- Rarity colours, used by labels and by the neon ring under a filled base pad.
Config.RarityColors = {
	Common = Color3.fromRGB(205, 205, 205),
	Rare = Color3.fromRGB(70, 150, 255),
	Epic = Color3.fromRGB(180, 90, 255),
	Legendary = Color3.fromRGB(255, 160, 30),
	Mythic = Color3.fromRGB(255, 70, 120),
	["Brainrot God"] = Color3.fromRGB(255, 230, 80),
	Secret = Color3.fromRGB(120, 240, 255),
}

-- The cast: 12 brainrots. Income is $/second, price is the conveyor buy price,
-- weight is the relative spawn chance (normalised by BrainrotFactory).
Config.Cast = {
	{ name = "Krupuk Terbang", rarity = "Common", income = 2, price = 30, weight = 28, color = Color3.fromRGB(245, 240, 220) },
	{ name = "Es Teh Manis", rarity = "Common", income = 4, price = 75, weight = 20, color = Color3.fromRGB(200, 150, 90) },
	{ name = "Klepon Gemas", rarity = "Common", income = 6, price = 120, weight = 16, color = Color3.fromRGB(90, 200, 110) },
	{ name = "Gorengan Sakti", rarity = "Rare", income = 9, price = 200, weight = 12, color = Color3.fromRGB(245, 190, 40) },
	{ name = "Kopi Tubruk Titan", rarity = "Rare", income = 15, price = 450, weight = 9, color = Color3.fromRGB(90, 55, 30) },
	{ name = "Nasi Padang Raksasa", rarity = "Epic", income = 30, price = 1000, weight = 6, color = Color3.fromRGB(215, 45, 35) },
	{ name = "Becak Terbang", rarity = "Epic", income = 55, price = 2200, weight = 4, color = Color3.fromRGB(30, 180, 160) },
	{ name = "Komodo Berkepala Dua", rarity = "Legendary", income = 110, price = 5000, weight = 2.6, color = Color3.fromRGB(85, 140, 60) },
	{ name = "Garuda Emas", rarity = "Mythic", income = 250, price = 12000, weight = 1.4, color = Color3.fromRGB(250, 200, 50) },
	{ name = "Rendang Dewa", rarity = "Mythic", income = 380, price = 20000, weight = 0.6, color = Color3.fromRGB(110, 25, 35) },
	{ name = "Kujang Petir", rarity = "Brainrot God", income = 600, price = 30000, weight = 0.3, color = Color3.fromRGB(150, 80, 255) },
	{ name = "Tung-Tung Sahur", rarity = "Secret", income = 1500, price = 75000, weight = 0.1, color = Color3.fromRGB(35, 55, 140) },
}

-- Lookup by exact character name (TourHelper spawns cast members by name).
Config.CastByName = {}
for _, def in ipairs(Config.Cast) do
	Config.CastByName[def.name] = def
end

return Config
