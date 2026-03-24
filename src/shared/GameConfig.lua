local GameConfig = {}

-- Currency
GameConfig.CurrencyName = "Cash"
GameConfig.StartingCash = 100
GameConfig.AutoPurchaseFirstItem = true

-- Income tick rate (seconds between income ticks)
GameConfig.IncomeInterval = 1

-- Tycoon items — ordered unlock chain (rebalanced for snappy early game)
-- Items 1-6 in ~1 min, all 15 in ~6 min, first rebirth at ~7 min
GameConfig.TycoonItems = {
	-- Tier 1: Starter (instant to ~20s)
	{name = "Lemonade Stand",     cost = 0,      income = 5,    description = "Your first business!"},
	{name = "Newspaper Route",    cost = 25,     income = 8,    description = "Deliver the daily news"},
	{name = "Hot Dog Cart",       cost = 75,     income = 15,   description = "Sizzling profits"},

	-- Tier 2: Small Business (20s-60s each)
	{name = "Coffee Shop",        cost = 200,    income = 30,   description = "Caffeine empire begins"},
	{name = "Pizza Place",        cost = 500,    income = 50,   description = "Everybody loves pizza"},
	{name = "Car Wash",           cost = 1200,   income = 80,   description = "Squeaky clean money"},

	-- Tier 3: Growing Empire (15s-25s each)
	{name = "Gas Station",        cost = 3000,   income = 150,  description = "Fuel your fortune"},
	{name = "Grocery Store",      cost = 7500,   income = 300,  description = "Stock up on profits"},
	{name = "Movie Theater",      cost = 18000,  income = 500,  description = "Blockbuster earnings"},

	-- Tier 4: Big Business (30s-45s each)
	{name = "Hotel",              cost = 40000,  income = 900,  description = "Five star income"},
	{name = "Shopping Mall",      cost = 100000, income = 2000, description = "Retail domination"},
	{name = "Airport",            cost = 250000, income = 4000, description = "Sky-high revenue"},

	-- Tier 5: Mega Corp (42s-66s each)
	{name = "Space Center",       cost = 500000,  income = 8000,  description = "To the moon!"},
	{name = "Mega Factory",       cost = 1200000, income = 15000, description = "Industrial powerhouse"},
	{name = "Golden Skyscraper",  cost = 3500000, income = 35000, description = "The ultimate tycoon"},

	-- Tier 6: Mega Corp
	{name = "Theme Park",         cost = 5000000,   income = 75000,   description = "Thrills and bills"},
	{name = "Cruise Line",        cost = 12000000,  income = 120000,  description = "Sail into profit"},
	{name = "Tech Campus",        cost = 25000000,  income = 200000,  description = "Silicon Valley vibes"},

	-- Tier 7: Global Empire
	{name = "Oil Rig",            cost = 50000000,  income = 350000,  description = "Black gold rush"},
	{name = "Diamond Mine",       cost = 100000000, income = 600000,  description = "Diamonds are forever"},
	{name = "Rocket Factory",     cost = 200000000, income = 1000000, description = "Launch your fortune"},

	-- Tier 8: Planetary Scale
	{name = "Moon Base",          cost = 500000000,  income = 1800000, description = "Lunar real estate"},
	{name = "Mars Colony",        cost = 1000000000, income = 3000000, description = "Red planet profits"},
	{name = "Quantum Lab",        cost = 2000000000, income = 5000000, description = "Infinite possibilities"},

	-- Tier 9: Cosmic (unlocks after 5 rebirths)
	{name = "Dyson Sphere",       cost = 5000000000,  income = 10000000,  description = "Harness a star"},
	{name = "Galaxy HQ",          cost = 10000000000, income = 18000000,  description = "Intergalactic HQ"},

	-- Tier 10: Secret (unlocks after 10 rebirths)
	{name = "The Multiverse",     cost = 25000000000, income = 50000000,  description = "Reality is yours", secret = true},

	-- VIP Exclusive (requires VIP game pass)
	{name = "VIP Penthouse",      cost = 50000000000,  income = 80000000,  description = "Luxury living", vip = true},
	{name = "VIP Casino",         cost = 100000000000, income = 150000000, description = "High roller profits", vip = true},
	{name = "VIP Space Station",  cost = 250000000000, income = 300000000, description = "Orbital empire", vip = true},
}

-- Rebirth system
GameConfig.Rebirth = {
	baseCost = 500000,           -- Cash required for first rebirth (reachable in ~7 min)
	costMultiplier = 2.5,        -- Each rebirth costs 2.5x more
	incomeMultiplier = 1.5,      -- Each rebirth gives 1.5x income boost
	maxRebirths = 25,            -- Capped to prevent number overflow
}

-- Number of standard (non-VIP) items
GameConfig.StandardItemCount = 28

-- Plot settings
GameConfig.MaxPlots = 8
GameConfig.PlotSpacing = 100     -- Studs between plot centers
GameConfig.PlotSize = 80         -- Studs per plot platform (width and depth)

-- Building appearance per tier (items 1-3 = tier 1, 4-6 = tier 2, etc.)
GameConfig.BuildingColors = {
	Color3.fromRGB(139, 195, 74),   -- Tier 1: Green
	Color3.fromRGB(255, 183, 77),   -- Tier 2: Orange
	Color3.fromRGB(100, 181, 246),  -- Tier 3: Blue
	Color3.fromRGB(186, 104, 200),  -- Tier 4: Purple
	Color3.fromRGB(255, 215, 0),    -- Tier 5: Gold
	Color3.fromRGB(255, 100, 50),   -- Tier 6: Mega Corp Orange-Red
	Color3.fromRGB(50, 200, 255),   -- Tier 7: Global Empire Cyan
	Color3.fromRGB(200, 50, 255),   -- Tier 8: Planetary Purple
	Color3.fromRGB(255, 255, 255),  -- Tier 9: Cosmic White
	Color3.fromRGB(255, 50, 200),   -- Tier 10: Secret Pink
	Color3.fromRGB(255, 100, 100),  -- VIP Red-Gold
}
GameConfig.BuildingHeights = {4, 6, 10, 14, 20, 25, 30, 35, 40, 45, 50}
GameConfig.BuildingMaterials = {"Wood", "Brick", "Concrete", "Metal", "Neon", "ForceField", "DiamondPlate", "Glass", "Neon", "ForceField", "ForceField"}

-- Plot base colors (one per plot)
GameConfig.PlotColors = {
	Color3.fromRGB(200, 230, 200),
	Color3.fromRGB(200, 200, 230),
	Color3.fromRGB(230, 200, 200),
	Color3.fromRGB(200, 230, 230),
	Color3.fromRGB(230, 230, 200),
	Color3.fromRGB(220, 200, 230),
	Color3.fromRGB(200, 220, 210),
	Color3.fromRGB(225, 215, 200),
}

-- Promo codes: code -> cash reward
GameConfig.Codes = {
	LAUNCH  = 5000,
	TYCOON  = 1000,
	RICH    = 10000,
	REBIRTH = 50000,
	SPACE   = 25000,   -- Cross-promo: from Space Tycoon
	EMPIRE  = 15000,   -- Social media code
	FOLLOW  = 5000,    -- Group follow code
	GALAXY  = 25000,   -- Cross-promo: play Galaxy Empire
	FOODIE  = 25000,   -- Cross-promo: play Food Factory
	TOWER   = 25000,   -- Cross-promo: play Tower of Chaos
}

-- Daily reward amounts (scaled to new economy)
GameConfig.DailyRewards = {
	500,     -- Day 1
	1500,    -- Day 2
	5000,    -- Day 3
	15000,   -- Day 4
	50000,   -- Day 5
	150000,  -- Day 6
	500000,  -- Day 7 (weekly bonus)
}

-- Stock market configuration
GameConfig.Stocks = {
	{id = "lemonco",    name = "LemonCo",         basePrice = 50,   volatility = 0.08},
	{id = "pizzacorp",  name = "PizzaCorp",       basePrice = 100,  volatility = 0.06},
	{id = "techstart",  name = "TechStart",       basePrice = 200,  volatility = 0.10},
	{id = "skyhigh",    name = "SkyHigh Airlines", basePrice = 500,  volatility = 0.07},
	{id = "goldmine",   name = "GoldMine Inc",    basePrice = 1000, volatility = 0.05},
	{id = "megacorp",   name = "MegaCorp",        basePrice = 5000, volatility = 0.04},
}

-- Quest definitions (pool for daily quests)
GameConfig.QuestPool = {
	{type = "earn_cash",     description = "Earn $%s cash",          baseTarget = 50000,  rewardMult = 2},
	{type = "buy_items",     description = "Buy %s items",           baseTarget = 3,      rewardMult = 3},
	{type = "rebirth",       description = "Rebirth %s time(s)",     baseTarget = 1,      rewardMult = 5},
	{type = "play_time",     description = "Play for %s minutes",    baseTarget = 10,     rewardMult = 2},
	{type = "reach_item",    description = "Reach item #%s",         baseTarget = 10,     rewardMult = 3},
	{type = "stock_profit",  description = "Earn $%s from stocks",   baseTarget = 10000,  rewardMult = 2},
}

-- Achievements
GameConfig.Achievements = {
	{id = "first_business",  name = "First Business",   trigger = "items",      threshold = 1,       reward = 500},
	{id = "entrepreneur",    name = "Entrepreneur",     trigger = "items",      threshold = 5,       reward = 5000},
	{id = "mogul",           name = "Mogul",            trigger = "items",      threshold = 15,      reward = 50000},
	{id = "first_rebirth",   name = "First Rebirth",    trigger = "rebirths",   threshold = 1,       reward = 10000},
	{id = "veteran",         name = "Veteran",          trigger = "rebirths",   threshold = 5,       reward = 100000},
	{id = "millionaire",     name = "Millionaire",      trigger = "totalEarned", threshold = 1000000, reward = 50000},
	{id = "ten_million",     name = "10 Million Club",  trigger = "totalEarned", threshold = 10000000, reward = 500000},
	{id = "stock_trader",    name = "Stock Trader",     trigger = "stockProfit", threshold = 50000,    reward = 25000},
}

return GameConfig
