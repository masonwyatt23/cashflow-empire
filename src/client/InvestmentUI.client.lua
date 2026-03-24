--[[
	InvestmentUI — Stock market display and trading interface
	Shows 6 fictional stocks with prices, sparklines, and buy/sell controls.
	Purely cosmetic — all game state is server-authoritative.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local GameConfig = require(Shared:WaitForChild("GameConfig"))
local Utils = require(Shared:WaitForChild("Utils"))

local Remotes = ReplicatedStorage:WaitForChild("Remotes", 15)
local StockUpdate = Remotes:WaitForChild("StockUpdate", 15)
local BuyStock = Remotes:WaitForChild("BuyStock", 15)
local SellStock = Remotes:WaitForChild("SellStock", 15)
local MarketEvent = Remotes:WaitForChild("MarketEvent", 15)

local player = Players.LocalPlayer
local PlayerGui = player:WaitForChild("PlayerGui")

-- State
local stockData = {} -- array of {id, name, basePrice, price, history}
local portfolio = {} -- stockId -> {shares, avgCost}
local stockCards = {} -- stockId -> UI references

-- Colors
local COLOR_BG = Color3.fromRGB(20, 20, 30)
local COLOR_GOLD = Color3.fromRGB(255, 215, 0)
local COLOR_GREEN = Color3.fromRGB(80, 220, 80)
local COLOR_RED = Color3.fromRGB(220, 80, 80)
local COLOR_WHITE = Color3.fromRGB(255, 255, 255)
local COLOR_DIM = Color3.fromRGB(160, 160, 180)
local COLOR_BUY = Color3.fromRGB(50, 160, 50)
local COLOR_SELL = Color3.fromRGB(180, 50, 50)
local COLOR_CARD = Color3.fromRGB(30, 30, 45)

-- Build the UI
local function createInvestUI()
	local screenGui = Instance.new("ScreenGui")
	screenGui.Name = "InvestGUI"
	screenGui.ResetOnSpawn = false
	screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	screenGui.Parent = PlayerGui

	-- Main invest frame (hidden by default)
	local investFrame = Instance.new("Frame")
	investFrame.Name = "InvestFrame"
	investFrame.Size = UDim2.new(0, 450, 0, 500)
	investFrame.Position = UDim2.new(0.5, -225, 0.5, -250)
	investFrame.BackgroundColor3 = COLOR_BG
	investFrame.BackgroundTransparency = 0.15
	investFrame.BorderSizePixel = 0
	investFrame.Visible = false
	investFrame.Parent = screenGui

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 12)
	corner.Parent = investFrame

	local stroke = Instance.new("UIStroke")
	stroke.Color = COLOR_GOLD
	stroke.Thickness = 2
	stroke.Transparency = 0.3
	stroke.Parent = investFrame

	-- Title
	local titleLabel = Instance.new("TextLabel")
	titleLabel.Name = "TitleLabel"
	titleLabel.Size = UDim2.new(1, -20, 0, 35)
	titleLabel.Position = UDim2.new(0, 10, 0, 8)
	titleLabel.BackgroundTransparency = 1
	titleLabel.Text = "INVESTMENT BOARD"
	titleLabel.TextColor3 = COLOR_GOLD
	titleLabel.TextSize = 22
	titleLabel.Font = Enum.Font.GothamBold
	titleLabel.TextXAlignment = Enum.TextXAlignment.Center
	titleLabel.Parent = investFrame

	-- Close button
	local closeButton = Instance.new("TextButton")
	closeButton.Name = "CloseButton"
	closeButton.Size = UDim2.new(0, 30, 0, 30)
	closeButton.Position = UDim2.new(1, -38, 0, 8)
	closeButton.BackgroundColor3 = COLOR_RED
	closeButton.BorderSizePixel = 0
	closeButton.Text = "X"
	closeButton.TextColor3 = COLOR_WHITE
	closeButton.TextSize = 16
	closeButton.Font = Enum.Font.GothamBold
	closeButton.Parent = investFrame

	local closeCorner = Instance.new("UICorner")
	closeCorner.CornerRadius = UDim.new(0, 6)
	closeCorner.Parent = closeButton

	closeButton.MouseButton1Click:Connect(function()
		investFrame.Visible = false
	end)

	-- Portfolio value display
	local portfolioLabel = Instance.new("TextLabel")
	portfolioLabel.Name = "PortfolioLabel"
	portfolioLabel.Size = UDim2.new(1, -20, 0, 22)
	portfolioLabel.Position = UDim2.new(0, 10, 0, 42)
	portfolioLabel.BackgroundTransparency = 1
	portfolioLabel.Text = "Portfolio Value: $0"
	portfolioLabel.TextColor3 = COLOR_GREEN
	portfolioLabel.TextSize = 15
	portfolioLabel.Font = Enum.Font.Gotham
	portfolioLabel.TextXAlignment = Enum.TextXAlignment.Center
	portfolioLabel.Parent = investFrame

	-- Scrolling frame for stock cards
	local scrollFrame = Instance.new("ScrollingFrame")
	scrollFrame.Name = "StockList"
	scrollFrame.Size = UDim2.new(1, -20, 1, -75)
	scrollFrame.Position = UDim2.new(0, 10, 0, 68)
	scrollFrame.BackgroundTransparency = 1
	scrollFrame.BorderSizePixel = 0
	scrollFrame.ScrollBarThickness = 6
	scrollFrame.ScrollBarImageColor3 = COLOR_GOLD
	scrollFrame.CanvasSize = UDim2.new(0, 0, 0, 6 * 68) -- 6 stocks * 68px each
	scrollFrame.Parent = investFrame

	local listLayout = Instance.new("UIListLayout")
	listLayout.Padding = UDim.new(0, 5)
	listLayout.SortOrder = Enum.SortOrder.LayoutOrder
	listLayout.Parent = scrollFrame

	-- Create stock cards
	for i, stock in ipairs(GameConfig.Stocks) do
		local card = Instance.new("Frame")
		card.Name = "Stock_" .. stock.id
		card.Size = UDim2.new(1, -12, 0, 63)
		card.BackgroundColor3 = COLOR_CARD
		card.BackgroundTransparency = 0.1
		card.BorderSizePixel = 0
		card.LayoutOrder = i
		card.Parent = scrollFrame

		local cardCorner = Instance.new("UICorner")
		cardCorner.CornerRadius = UDim.new(0, 8)
		cardCorner.Parent = card

		-- Stock name
		local nameLabel = Instance.new("TextLabel")
		nameLabel.Name = "NameLabel"
		nameLabel.Size = UDim2.new(0, 130, 0, 20)
		nameLabel.Position = UDim2.new(0, 8, 0, 4)
		nameLabel.BackgroundTransparency = 1
		nameLabel.Text = stock.name
		nameLabel.TextColor3 = COLOR_WHITE
		nameLabel.TextSize = 16
		nameLabel.Font = Enum.Font.GothamBold
		nameLabel.TextXAlignment = Enum.TextXAlignment.Left
		nameLabel.TextTruncate = Enum.TextTruncate.AtEnd
		nameLabel.Parent = card

		-- Current price
		local priceLabel = Instance.new("TextLabel")
		priceLabel.Name = "PriceLabel"
		priceLabel.Size = UDim2.new(0, 80, 0, 20)
		priceLabel.Position = UDim2.new(0, 140, 0, 4)
		priceLabel.BackgroundTransparency = 1
		priceLabel.Text = "$" .. tostring(stock.basePrice)
		priceLabel.TextColor3 = COLOR_GREEN
		priceLabel.TextSize = 15
		priceLabel.Font = Enum.Font.GothamBold
		priceLabel.TextXAlignment = Enum.TextXAlignment.Left
		priceLabel.Parent = card

		-- Percent change
		local changeLabel = Instance.new("TextLabel")
		changeLabel.Name = "ChangeLabel"
		changeLabel.Size = UDim2.new(0, 55, 0, 20)
		changeLabel.Position = UDim2.new(0, 220, 0, 4)
		changeLabel.BackgroundTransparency = 1
		changeLabel.Text = "0.0%"
		changeLabel.TextColor3 = COLOR_DIM
		changeLabel.TextSize = 13
		changeLabel.Font = Enum.Font.Gotham
		changeLabel.TextXAlignment = Enum.TextXAlignment.Left
		changeLabel.Parent = card

		-- Shares owned
		local sharesLabel = Instance.new("TextLabel")
		sharesLabel.Name = "SharesLabel"
		sharesLabel.Size = UDim2.new(0, 70, 0, 20)
		sharesLabel.Position = UDim2.new(0, 8, 0, 24)
		sharesLabel.BackgroundTransparency = 1
		sharesLabel.Text = "Shares: 0"
		sharesLabel.TextColor3 = COLOR_DIM
		sharesLabel.TextSize = 12
		sharesLabel.Font = Enum.Font.Gotham
		sharesLabel.TextXAlignment = Enum.TextXAlignment.Left
		sharesLabel.Parent = card

		-- Sparkline container
		local sparkFrame = Instance.new("Frame")
		sparkFrame.Name = "Sparkline"
		sparkFrame.Size = UDim2.new(0, 96, 0, 22)
		sparkFrame.Position = UDim2.new(0, 85, 0, 26)
		sparkFrame.BackgroundTransparency = 1
		sparkFrame.Parent = card

		-- Create 12 bars for sparkline
		for j = 1, 12 do
			local bar = Instance.new("Frame")
			bar.Name = "Bar" .. j
			bar.Size = UDim2.new(0, 6, 0.5, 0)
			bar.Position = UDim2.new(0, (j - 1) * 8, 1, 0)
			bar.AnchorPoint = Vector2.new(0, 1)
			bar.BackgroundColor3 = COLOR_GREEN
			bar.BorderSizePixel = 0
			bar.Parent = sparkFrame

			local barCorner = Instance.new("UICorner")
			barCorner.CornerRadius = UDim.new(0, 2)
			barCorner.Parent = bar
		end

		-- Buy button
		local buyBtn = Instance.new("TextButton")
		buyBtn.Name = "BuyBtn"
		buyBtn.Size = UDim2.new(0, 50, 0, 24)
		buyBtn.Position = UDim2.new(1, -112, 0, 28)
		buyBtn.BackgroundColor3 = COLOR_BUY
		buyBtn.BorderSizePixel = 0
		buyBtn.Text = "BUY"
		buyBtn.TextColor3 = COLOR_WHITE
		buyBtn.TextSize = 13
		buyBtn.Font = Enum.Font.GothamBold
		buyBtn.Parent = card

		local buyBtnCorner = Instance.new("UICorner")
		buyBtnCorner.CornerRadius = UDim.new(0, 6)
		buyBtnCorner.Parent = buyBtn

		buyBtn.MouseButton1Click:Connect(function()
			if _G.PlayButtonClick then _G.PlayButtonClick() end
			BuyStock:FireServer(stock.id, 1)
		end)

		-- Sell button
		local sellBtn = Instance.new("TextButton")
		sellBtn.Name = "SellBtn"
		sellBtn.Size = UDim2.new(0, 50, 0, 24)
		sellBtn.Position = UDim2.new(1, -56, 0, 28)
		sellBtn.BackgroundColor3 = COLOR_SELL
		sellBtn.BorderSizePixel = 0
		sellBtn.Text = "SELL"
		sellBtn.TextColor3 = COLOR_WHITE
		sellBtn.TextSize = 13
		sellBtn.Font = Enum.Font.GothamBold
		sellBtn.Parent = card

		local sellBtnCorner = Instance.new("UICorner")
		sellBtnCorner.CornerRadius = UDim.new(0, 6)
		sellBtnCorner.Parent = sellBtn

		sellBtn.MouseButton1Click:Connect(function()
			if _G.PlayButtonClick then _G.PlayButtonClick() end
			SellStock:FireServer(stock.id, 1)
		end)

		stockCards[stock.id] = {
			card = card,
			priceLabel = priceLabel,
			changeLabel = changeLabel,
			sharesLabel = sharesLabel,
			sparkFrame = sparkFrame,
		}
	end

	-- Market event banner (top of screen, hidden by default)
	local eventBanner = Instance.new("TextLabel")
	eventBanner.Name = "MarketEventBanner"
	eventBanner.Size = UDim2.new(0, 400, 0, 40)
	eventBanner.Position = UDim2.new(0.5, -200, 0, -50) -- starts offscreen
	eventBanner.AnchorPoint = Vector2.new(0, 0)
	eventBanner.BackgroundColor3 = Color3.fromRGB(220, 180, 30)
	eventBanner.BackgroundTransparency = 0.1
	eventBanner.BorderSizePixel = 0
	eventBanner.Text = ""
	eventBanner.TextColor3 = Color3.fromRGB(30, 30, 30)
	eventBanner.TextSize = 16
	eventBanner.Font = Enum.Font.GothamBold
	eventBanner.TextXAlignment = Enum.TextXAlignment.Center
	eventBanner.Visible = false
	eventBanner.ZIndex = 10
	eventBanner.Parent = screenGui

	local bannerCorner = Instance.new("UICorner")
	bannerCorner.CornerRadius = UDim.new(0, 8)
	bannerCorner.Parent = eventBanner

	return screenGui
end

local gui = createInvestUI()
local investFrame = gui.InvestFrame
local portfolioLabel = investFrame.PortfolioLabel
local eventBanner = gui.MarketEventBanner

-- Toggle visibility via _G (called from TycoonUI invest button)
_G.ShowInvestUI = function()
	investFrame.Visible = not investFrame.Visible
end

-- Update sparkline bars for a stock
local function updateSparkline(stockId, history)
	local refs = stockCards[stockId]
	if not refs or not history or #history == 0 then return end

	local sparkFrame = refs.sparkFrame
	local minPrice = math.huge
	local maxPrice = -math.huge

	for _, p in ipairs(history) do
		if p < minPrice then minPrice = p end
		if p > maxPrice then maxPrice = p end
	end

	local range = maxPrice - minPrice
	if range < 0.01 then range = 1 end -- prevent division by zero

	for j = 1, 12 do
		local bar = sparkFrame:FindFirstChild("Bar" .. j)
		if bar and history[j] then
			local normalized = (history[j] - minPrice) / range
			local height = math.clamp(normalized, 0.05, 1)
			bar.Size = UDim2.new(0, 6, height, 0)

			-- Color: green if this tick is higher than previous, red if lower
			if j > 1 and history[j] < history[j - 1] then
				bar.BackgroundColor3 = COLOR_RED
			else
				bar.BackgroundColor3 = COLOR_GREEN
			end
		end
	end
end

-- Update all stock displays
local function updateStockDisplays(stocks, playerPortfolio)
	stockData = stocks or stockData
	portfolio = playerPortfolio or portfolio

	local totalPortfolioValue = 0

	for _, stock in ipairs(stockData) do
		local refs = stockCards[stock.id]
		if refs then
			-- Price
			local priceText = "$" .. Utils.formatCash(math.floor(stock.price))
			refs.priceLabel.Text = priceText

			-- Percent change from base
			local pctChange = ((stock.price / stock.basePrice) - 1) * 100
			local pctText = string.format("%+.1f%%", pctChange)
			refs.changeLabel.Text = pctText
			if pctChange >= 0 then
				refs.priceLabel.TextColor3 = COLOR_GREEN
				refs.changeLabel.TextColor3 = COLOR_GREEN
			else
				refs.priceLabel.TextColor3 = COLOR_RED
				refs.changeLabel.TextColor3 = COLOR_RED
			end

			-- Shares
			local inv = portfolio[stock.id]
			local shares = inv and inv.shares or 0
			refs.sharesLabel.Text = "Shares: " .. shares
			if shares > 0 then
				refs.sharesLabel.TextColor3 = COLOR_GOLD
			else
				refs.sharesLabel.TextColor3 = COLOR_DIM
			end

			-- Portfolio value
			totalPortfolioValue = totalPortfolioValue + (shares * stock.price)

			-- Sparkline
			updateSparkline(stock.id, stock.history)
		end
	end

	portfolioLabel.Text = "Portfolio Value: $" .. Utils.formatCash(math.floor(totalPortfolioValue))
end

-- Listen for stock updates
StockUpdate.OnClientEvent:Connect(function(stocks, playerPortfolio)
	updateStockDisplays(stocks, playerPortfolio)
end)

-- Listen for market events
MarketEvent.OnClientEvent:Connect(function(eventText)
	eventBanner.Text = eventText
	eventBanner.Visible = true
	eventBanner.Position = UDim2.new(0.5, -200, 0, 10)

	-- Auto-hide after 5 seconds
	task.delay(5, function()
		if eventBanner.Text == eventText then
			eventBanner.Visible = false
			eventBanner.Position = UDim2.new(0.5, -200, 0, -50)
		end
	end)
end)

print("[InvestmentUI] Initialized")
