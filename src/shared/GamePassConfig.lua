local GamePassConfig = {}

-- Game Passes (one-time purchases)
-- Replace IDs with real ones after creating them in Creator Dashboard
GamePassConfig.Passes = {
	DoubleIncome = {
		id = 0,  -- REPLACE with real GamePass ID
		name = "2x Income",
		price = 199, -- Robux
		description = "Permanently double all your income!",
		multiplier = 2,
	},
	AutoCollect = {
		id = 0,  -- REPLACE with real GamePass ID
		name = "Auto-Collect",
		price = 149,
		description = "Automatically collect income — no clicking needed!",
	},
	VIP = {
		id = 0,  -- REPLACE with real GamePass ID
		name = "VIP",
		price = 399,
		description = "Exclusive VIP buildings + VIP badge!",
	},
	SpeedBoost = {
		id = 0,  -- REPLACE with real GamePass ID
		name = "Speed Boost",
		price = 99,
		description = "Walk 1.5x faster!",
		speedMultiplier = 1.5,
	},
}

-- Developer Products (repeatable purchases)
-- Replace IDs with real ones after creating them in Creator Dashboard
GamePassConfig.Products = {
	SmallCashPack = {
		id = 0,  -- REPLACE with real Product ID
		name = "Small Cash Pack",
		price = 49,
		cashAmount = 10000,
		description = "+10,000 Cash",
	},
	LargeCashPack = {
		id = 0,  -- REPLACE with real Product ID
		name = "Large Cash Pack",
		price = 199,
		cashAmount = 50000,
		description = "+50,000 Cash",
	},
	InstantRebirth = {
		id = 0,  -- REPLACE with real Product ID
		name = "Instant Rebirth",
		price = 99,
		description = "Rebirth without meeting the cash requirement!",
	},
	TemporaryBoost = {
		id = 0,  -- REPLACE with real Product ID
		name = "5min 2x Boost",
		price = 29,
		duration = 300, -- seconds
		multiplier = 2,
		description = "2x income for 5 minutes!",
	},
}

return GamePassConfig
