--[[
	InvestmentManager — Stock market mini-game
	6 fictional stocks with random walk pricing, mean reversion, and market events.
	All state is server-authoritative; clients receive price updates via RemoteEvents.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local GameConfig = require(Shared:WaitForChild("GameConfig"))
local Utils = require(Shared:WaitForChild("Utils"))

local Remotes = ReplicatedStorage:WaitForChild("Remotes")

-- Create remotes
local StockUpdateRemote = Instance.new("RemoteEvent")
StockUpdateRemote.Name = "StockUpdate"
StockUpdateRemote.Parent = Remotes

local BuyStockRemote = Instance.new("RemoteEvent")
BuyStockRemote.Name = "BuyStock"
BuyStockRemote.Parent = Remotes

local SellStockRemote = Instance.new("RemoteEvent")
SellStockRemote.Name = "SellStock"
SellStockRemote.Parent = Remotes

local MarketEventRemote = Instance.new("RemoteEvent")
MarketEventRemote.Name = "MarketEvent"
MarketEventRemote.Parent = Remotes

-- Stock state
local PRICE_HISTORY_LENGTH = 12
local TICK_INTERVAL = 5
local MARKET_EVENT_MIN = 120 -- seconds
local MARKET_EVENT_MAX = 300 -- seconds
local RATE_LIMIT = 0.5 -- seconds between buy/sell per player

local stockPrices = {} -- stockId -> current price
local priceHistory = {} -- stockId -> {last 12 prices}
local lastTradeTime = {} -- player UserId -> last trade timestamp

-- Initialize stock prices from config
for _, stock in ipairs(GameConfig.Stocks) do
	stockPrices[stock.id] = stock.basePrice
	priceHistory[stock.id] = {}
	for i = 1, PRICE_HISTORY_LENGTH do
		priceHistory[stock.id][i] = stock.basePrice
	end
end

-- Wait for core systems
local function waitForGlobal(name, timeout)
	local elapsed = 0
	while not _G[name] and elapsed < (timeout or 30) do
		task.wait(0.1)
		elapsed = elapsed + 0.1
	end
	return _G[name] ~= nil
end

-- Build snapshot of all stock data for clients
local function buildStockSnapshot()
	local snapshot = {}
	for _, stock in ipairs(GameConfig.Stocks) do
		table.insert(snapshot, {
			id = stock.id,
			name = stock.name,
			basePrice = stock.basePrice,
			price = stockPrices[stock.id],
			history = priceHistory[stock.id],
		})
	end
	return snapshot
end

-- Get player's investment data, initializing if needed
local function getInvestments(player)
	local data = _G.GetPlayerData and _G.GetPlayerData(player)
	if not data then return nil end
	if not data.investments then
		data.investments = {}
	end
	if data.totalStockProfit == nil then
		data.totalStockProfit = 0
	end
	return data
end

-- Rate limiter
local function canTrade(player)
	local now = tick()
	local last = lastTradeTime[player.UserId]
	if last and (now - last) < RATE_LIMIT then
		return false
	end
	lastTradeTime[player.UserId] = now
	return true
end

-- Buy stock
_G.BuyStock = function(player, stockId, quantity)
	if not canTrade(player) then return false, "Too fast" end

	local data = getInvestments(player)
	if not data then return false, "No data" end

	-- Validate stock exists
	local stockConfig = nil
	for _, s in ipairs(GameConfig.Stocks) do
		if s.id == stockId then
			stockConfig = s
			break
		end
	end
	if not stockConfig then return false, "Invalid stock" end

	-- Validate quantity
	quantity = math.floor(tonumber(quantity) or 1)
	if quantity < 1 then return false, "Invalid quantity" end

	-- Calculate total cost
	local price = stockPrices[stockId]
	local totalCost = math.floor(price * quantity)

	-- Validate cash
	if data.cash < totalCost then return false, "Not enough cash" end

	-- Deduct cash (use direct subtraction since _G.AddCash adds)
	if _G.AddCash then
		_G.AddCash(player, -totalCost)
	end

	-- Add shares to portfolio
	if not data.investments[stockId] then
		data.investments[stockId] = {shares = 0, avgCost = 0}
	end

	local inv = data.investments[stockId]
	-- Update average cost basis
	local totalShares = inv.shares + quantity
	local totalValue = (inv.avgCost * inv.shares) + (price * quantity)
	inv.avgCost = totalValue / totalShares
	inv.shares = totalShares

	return true
end

-- Sell stock
_G.SellStock = function(player, stockId, quantity)
	if not canTrade(player) then return false, "Too fast" end

	local data = getInvestments(player)
	if not data then return false, "No data" end

	-- Validate stock exists
	local stockConfig = nil
	for _, s in ipairs(GameConfig.Stocks) do
		if s.id == stockId then
			stockConfig = s
			break
		end
	end
	if not stockConfig then return false, "Invalid stock" end

	-- Validate quantity
	quantity = math.floor(tonumber(quantity) or 1)
	if quantity < 1 then return false, "Invalid quantity" end

	-- Validate shares
	local inv = data.investments[stockId]
	if not inv or inv.shares < quantity then return false, "Not enough shares" end

	-- Calculate proceeds and profit
	local price = stockPrices[stockId]
	local proceeds = math.floor(price * quantity)
	local costBasis = math.floor(inv.avgCost * quantity)
	local profit = proceeds - costBasis

	-- Add cash
	if _G.AddCash then
		_G.AddCash(player, proceeds)
	end

	-- Remove shares
	inv.shares = inv.shares - quantity
	if inv.shares <= 0 then
		data.investments[stockId] = nil
	end

	-- Track profit for achievements and quests
	if profit > 0 then
		data.totalStockProfit = (data.totalStockProfit or 0) + profit

		-- Update stock_profit quest progress if QuestManager hook exists
		-- QuestManager wraps _G.AddCash to track earn_cash, but stock_profit is separate
		-- We check for the quest type directly in player data
		if data.dailyQuests then
			for _, quest in ipairs(data.dailyQuests) do
				if quest.type == "stock_profit" and not quest.claimed then
					quest.progress = quest.progress + profit
				end
			end
		end
	end

	return true, profit
end

-- No passive income bonus from stocks (active trading only)
_G.GetStockBonus = function(player)
	return 0
end

-- Handle buy/sell remote events
BuyStockRemote.OnServerEvent:Connect(function(player, stockId, quantity)
	if type(stockId) ~= "string" then return end
	quantity = tonumber(quantity) or 1
	local success, msg = _G.BuyStock(player, stockId, quantity)
	if success then
		-- Send updated stock info so client refreshes portfolio
		local data = getInvestments(player)
		StockUpdateRemote:FireClient(player, buildStockSnapshot(), data and data.investments or {})
	end
end)

SellStockRemote.OnServerEvent:Connect(function(player, stockId, quantity)
	if type(stockId) ~= "string" then return end
	quantity = tonumber(quantity) or 1
	local success, profit = _G.SellStock(player, stockId, quantity)
	if success then
		local data = getInvestments(player)
		StockUpdateRemote:FireClient(player, buildStockSnapshot(), data and data.investments or {})
	end
end)

-- Wait for core systems before starting tick loop
task.spawn(function()
	if not waitForGlobal("GetPlayerData", 30) then
		warn("[InvestmentManager] Timed out waiting for GetPlayerData")
		return
	end
	if not waitForGlobal("AddCash", 30) then
		warn("[InvestmentManager] Timed out waiting for AddCash")
		return
	end

	print("[InvestmentManager] Core systems ready, starting price ticker")

	-- Price tick loop
	task.spawn(function()
		while true do
			task.wait(TICK_INTERVAL)

			-- Update each stock price
			for _, stock in ipairs(GameConfig.Stocks) do
				local price = stockPrices[stock.id]

				-- Random walk
				price = price * (1 + (math.random() - 0.5) * 2 * stock.volatility)

				-- Mean reversion toward base price
				price = price + (stock.basePrice - price) * 0.02

				-- Clamp to minimum 10% of base price
				price = math.max(price, stock.basePrice * 0.1)

				stockPrices[stock.id] = price

				-- Update history (shift left, add new price at end)
				local history = priceHistory[stock.id]
				table.remove(history, 1)
				table.insert(history, price)
			end

			-- Send update to all players with their portfolio data
			local snapshot = buildStockSnapshot()
			for _, player in ipairs(Players:GetPlayers()) do
				local data = getInvestments(player)
				StockUpdateRemote:FireClient(player, snapshot, data and data.investments or {})
			end
		end
	end)

	-- Market event loop
	task.spawn(function()
		while true do
			local delay = math.random(MARKET_EVENT_MIN, MARKET_EVENT_MAX)
			task.wait(delay)

			-- Pick a random stock
			local stockIndex = math.random(1, #GameConfig.Stocks)
			local stock = GameConfig.Stocks[stockIndex]

			-- Apply spike: +/- 15-30%
			local direction = math.random() > 0.5 and 1 or -1
			local magnitude = 0.15 + math.random() * 0.15 -- 15% to 30%
			local multiplier = 1 + (direction * magnitude)

			local oldPrice = stockPrices[stock.id]
			local newPrice = math.max(oldPrice * multiplier, stock.basePrice * 0.1)
			stockPrices[stock.id] = newPrice

			-- Update history with the spike
			local history = priceHistory[stock.id]
			table.remove(history, 1)
			table.insert(history, newPrice)

			-- Build event message
			local changePercent = math.floor(((newPrice / oldPrice) - 1) * 100)
			local eventText
			if direction > 0 then
				eventText = stock.name .. " surges +" .. changePercent .. "%!"
			else
				eventText = stock.name .. " crashes " .. changePercent .. "%!"
			end

			-- Notify all players
			local snapshot = buildStockSnapshot()
			for _, player in ipairs(Players:GetPlayers()) do
				MarketEventRemote:FireClient(player, eventText)
				local data = getInvestments(player)
				StockUpdateRemote:FireClient(player, snapshot, data and data.investments or {})
			end

			print("[InvestmentManager] Market Event: " .. eventText)
		end
	end)
end)

-- Clean up rate limit data on player leave
Players.PlayerRemoving:Connect(function(player)
	lastTradeTime[player.UserId] = nil
end)

print("[InvestmentManager] Initialized")
