local GameConfig = {}

-- Currency
GameConfig.CurrencyName = "Cash"
GameConfig.StartingCash = 0

-- Income tick rate (seconds between income ticks)
GameConfig.IncomeInterval = 1

-- Tycoon items — ordered unlock chain
-- Each item: {name, cost, incomePerSecond, description}
GameConfig.TycoonItems = {
	-- Tier 1: Starter (0-500 cash)
	{name = "Lemonade Stand",     cost = 0,      income = 2,    description = "Your first business!"},
	{name = "Newspaper Route",    cost = 50,     income = 5,    description = "Deliver the daily news"},
	{name = "Hot Dog Cart",       cost = 150,    income = 10,   description = "Sizzling profits"},

	-- Tier 2: Small Business (500-5,000 cash)
	{name = "Coffee Shop",        cost = 500,    income = 25,   description = "Caffeine empire begins"},
	{name = "Pizza Place",        cost = 1500,   income = 50,   description = "Everybody loves pizza"},
	{name = "Car Wash",           cost = 3000,   income = 80,   description = "Squeaky clean money"},

	-- Tier 3: Growing Empire (5,000-50,000 cash)
	{name = "Gas Station",        cost = 7000,   income = 150,  description = "Fuel your fortune"},
	{name = "Grocery Store",      cost = 15000,  income = 300,  description = "Stock up on profits"},
	{name = "Movie Theater",      cost = 30000,  income = 500,  description = "Blockbuster earnings"},

	-- Tier 4: Big Business (50,000-500,000 cash)
	{name = "Hotel",              cost = 60000,  income = 900,  description = "Five star income"},
	{name = "Shopping Mall",      cost = 150000, income = 2000, description = "Retail domination"},
	{name = "Airport",            cost = 350000, income = 4000, description = "Sky-high revenue"},

	-- Tier 5: Mega Corp (500,000+)
	{name = "Space Center",       cost = 700000,  income = 8000,  description = "To the moon!"},
	{name = "Mega Factory",       cost = 1500000, income = 15000, description = "Industrial powerhouse"},
	{name = "Golden Skyscraper",  cost = 5000000, income = 35000, description = "The ultimate tycoon"},
}

-- Rebirth system
GameConfig.Rebirth = {
	baseCost = 1000000,          -- Cash required for first rebirth
	costMultiplier = 2.5,        -- Each rebirth costs 2.5x more
	incomeMultiplier = 1.5,      -- Each rebirth gives 1.5x income boost
	maxRebirths = 50,
}

-- Plot settings
GameConfig.MaxPlots = 8
GameConfig.PlotSpacing = 100     -- Studs between plot centers

-- Daily reward amounts
GameConfig.DailyRewards = {
	100,    -- Day 1
	250,    -- Day 2
	500,    -- Day 3
	1000,   -- Day 4
	2500,   -- Day 5
	5000,   -- Day 6
	10000,  -- Day 7 (weekly bonus)
}

return GameConfig
