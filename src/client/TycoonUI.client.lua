--[[
	TycoonUI — Main HUD
	Displays cash, income rate, rebirth info, and next purchase.
	Purely cosmetic — all game state is server-authoritative.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local GameConfig = require(Shared:WaitForChild("GameConfig"))
local Utils = require(Shared:WaitForChild("Utils"))

local Remotes = ReplicatedStorage:WaitForChild("Remotes")
local UpdateCash = Remotes:WaitForChild("UpdateCash")
local UpdateItems = Remotes:WaitForChild("UpdateItems")
local RequestData = Remotes:WaitForChild("RequestData")
local PurchaseItem = Remotes:WaitForChild("PurchaseItem")
local ItemPurchased = Remotes:WaitForChild("ItemPurchased")
local RequestRebirth = Remotes:WaitForChild("RequestRebirth")
local RebirthInfo = Remotes:WaitForChild("RebirthInfo")
local RebirthSuccess = Remotes:WaitForChild("RebirthSuccess")

local player = Players.LocalPlayer
local PlayerGui = player:WaitForChild("PlayerGui")

-- State
local currentCash = 0
local ownedItems = {}
local rebirthData = {count = 0, cost = 0, currentMultiplier = 1, nextMultiplier = 1.5}

-- Build the UI
local function createHUD()
	local screenGui = Instance.new("ScreenGui")
	screenGui.Name = "TycoonHUD"
	screenGui.ResetOnSpawn = false
	screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	screenGui.Parent = PlayerGui

	-- Main frame (top center)
	local mainFrame = Instance.new("Frame")
	mainFrame.Name = "MainPanel"
	mainFrame.Size = UDim2.new(0, 320, 0, 120)
	mainFrame.Position = UDim2.new(0.5, -160, 0, 10)
	mainFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 30)
	mainFrame.BackgroundTransparency = 0.15
	mainFrame.BorderSizePixel = 0
	mainFrame.Parent = screenGui

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 12)
	corner.Parent = mainFrame

	local stroke = Instance.new("UIStroke")
	stroke.Color = Color3.fromRGB(255, 215, 0)
	stroke.Thickness = 2
	stroke.Transparency = 0.3
	stroke.Parent = mainFrame

	-- Cash display
	local cashLabel = Instance.new("TextLabel")
	cashLabel.Name = "CashLabel"
	cashLabel.Size = UDim2.new(1, -20, 0, 40)
	cashLabel.Position = UDim2.new(0, 10, 0, 8)
	cashLabel.BackgroundTransparency = 1
	cashLabel.Text = "$0"
	cashLabel.TextColor3 = Color3.fromRGB(255, 215, 0)
	cashLabel.TextSize = 32
	cashLabel.Font = Enum.Font.GothamBold
	cashLabel.TextXAlignment = Enum.TextXAlignment.Center
	cashLabel.Parent = mainFrame

	-- Income rate display
	local incomeLabel = Instance.new("TextLabel")
	incomeLabel.Name = "IncomeLabel"
	incomeLabel.Size = UDim2.new(1, -20, 0, 20)
	incomeLabel.Position = UDim2.new(0, 10, 0, 48)
	incomeLabel.BackgroundTransparency = 1
	incomeLabel.Text = "$0/sec"
	incomeLabel.TextColor3 = Color3.fromRGB(180, 255, 180)
	incomeLabel.TextSize = 16
	incomeLabel.Font = Enum.Font.Gotham
	incomeLabel.TextXAlignment = Enum.TextXAlignment.Center
	incomeLabel.Parent = mainFrame

	-- Multiplier display
	local multLabel = Instance.new("TextLabel")
	multLabel.Name = "MultLabel"
	multLabel.Size = UDim2.new(0.5, -10, 0, 20)
	multLabel.Position = UDim2.new(0, 10, 0, 70)
	multLabel.BackgroundTransparency = 1
	multLabel.Text = "1.0x Multiplier"
	multLabel.TextColor3 = Color3.fromRGB(200, 180, 255)
	multLabel.TextSize = 14
	multLabel.Font = Enum.Font.Gotham
	multLabel.TextXAlignment = Enum.TextXAlignment.Left
	multLabel.Parent = mainFrame

	-- Rebirth count
	local rebirthLabel = Instance.new("TextLabel")
	rebirthLabel.Name = "RebirthLabel"
	rebirthLabel.Size = UDim2.new(0.5, -10, 0, 20)
	rebirthLabel.Position = UDim2.new(0.5, 0, 0, 70)
	rebirthLabel.BackgroundTransparency = 1
	rebirthLabel.Text = "Rebirths: 0"
	rebirthLabel.TextColor3 = Color3.fromRGB(255, 180, 180)
	rebirthLabel.TextSize = 14
	rebirthLabel.Font = Enum.Font.Gotham
	rebirthLabel.TextXAlignment = Enum.TextXAlignment.Right
	rebirthLabel.Parent = mainFrame

	-- Next item info (bottom center)
	local nextFrame = Instance.new("Frame")
	nextFrame.Name = "NextItemPanel"
	nextFrame.Size = UDim2.new(0, 300, 0, 50)
	nextFrame.Position = UDim2.new(0.5, -150, 0, 140)
	nextFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 30)
	nextFrame.BackgroundTransparency = 0.15
	nextFrame.BorderSizePixel = 0
	nextFrame.Parent = screenGui

	local nextCorner = Instance.new("UICorner")
	nextCorner.CornerRadius = UDim.new(0, 10)
	nextCorner.Parent = nextFrame

	local nextLabel = Instance.new("TextLabel")
	nextLabel.Name = "NextItemLabel"
	nextLabel.Size = UDim2.new(1, -20, 1, 0)
	nextLabel.Position = UDim2.new(0, 10, 0, 0)
	nextLabel.BackgroundTransparency = 1
	nextLabel.Text = "Next: Lemonade Stand — FREE"
	nextLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
	nextLabel.TextSize = 16
	nextLabel.Font = Enum.Font.Gotham
	nextLabel.TextXAlignment = Enum.TextXAlignment.Center
	nextLabel.Parent = nextFrame

	-- Buy button
	local buyButton = Instance.new("TextButton")
	buyButton.Name = "BuyButton"
	buyButton.Size = UDim2.new(0, 120, 0, 40)
	buyButton.Position = UDim2.new(0.5, -60, 0, 195)
	buyButton.BackgroundColor3 = Color3.fromRGB(50, 180, 50)
	buyButton.BorderSizePixel = 0
	buyButton.Text = "BUY"
	buyButton.TextColor3 = Color3.fromRGB(255, 255, 255)
	buyButton.TextSize = 20
	buyButton.Font = Enum.Font.GothamBold
	buyButton.Parent = screenGui

	local buyCorner = Instance.new("UICorner")
	buyCorner.CornerRadius = UDim.new(0, 8)
	buyCorner.Parent = buyButton

	-- Rebirth button (bottom right)
	local rebirthButton = Instance.new("TextButton")
	rebirthButton.Name = "RebirthButton"
	rebirthButton.Size = UDim2.new(0, 160, 0, 45)
	rebirthButton.Position = UDim2.new(1, -170, 1, -55)
	rebirthButton.BackgroundColor3 = Color3.fromRGB(180, 50, 50)
	rebirthButton.BorderSizePixel = 0
	rebirthButton.Text = "REBIRTH\n$1M"
	rebirthButton.TextColor3 = Color3.fromRGB(255, 255, 255)
	rebirthButton.TextSize = 14
	rebirthButton.Font = Enum.Font.GothamBold
	rebirthButton.Parent = screenGui

	local rebirthCorner = Instance.new("UICorner")
	rebirthCorner.CornerRadius = UDim.new(0, 8)
	rebirthCorner.Parent = rebirthButton

	-- Shop button (bottom left)
	local shopButton = Instance.new("TextButton")
	shopButton.Name = "ShopButton"
	shopButton.Size = UDim2.new(0, 120, 0, 45)
	shopButton.Position = UDim2.new(0, 10, 1, -55)
	shopButton.BackgroundColor3 = Color3.fromRGB(50, 100, 200)
	shopButton.BorderSizePixel = 0
	shopButton.Text = "SHOP"
	shopButton.TextColor3 = Color3.fromRGB(255, 255, 255)
	shopButton.TextSize = 18
	shopButton.Font = Enum.Font.GothamBold
	shopButton.Parent = screenGui

	local shopCorner = Instance.new("UICorner")
	shopCorner.CornerRadius = UDim.new(0, 8)
	shopCorner.Parent = shopButton

	return screenGui
end

local hud = createHUD()

-- Update functions
local function updateCashDisplay()
	local cashLabel = hud.MainPanel.CashLabel
	cashLabel.Text = "$" .. Utils.formatCash(currentCash)
end

local function updateIncomeDisplay()
	-- Estimate income (client-side approximation for display only)
	local totalIncome = 0
	for _, index in ipairs(ownedItems) do
		local item = GameConfig.TycoonItems[index]
		if item then
			totalIncome = totalIncome + item.income
		end
	end
	totalIncome = totalIncome * (rebirthData.currentMultiplier or 1)
	hud.MainPanel.IncomeLabel.Text = "$" .. Utils.formatCash(totalIncome) .. "/sec"
end

local function updateNextItem()
	local nextIndex = #ownedItems + 1
	local nextItem = GameConfig.TycoonItems[nextIndex]
	local nextLabel = hud.NextItemPanel.NextItemLabel
	local buyButton = hud.BuyButton

	if nextItem then
		local costText = nextItem.cost == 0 and "FREE" or ("$" .. Utils.formatCash(nextItem.cost))
		nextLabel.Text = "Next: " .. nextItem.name .. " — " .. costText
		buyButton.Visible = true

		if currentCash >= nextItem.cost then
			buyButton.BackgroundColor3 = Color3.fromRGB(50, 180, 50)
			buyButton.Text = "BUY"
		else
			buyButton.BackgroundColor3 = Color3.fromRGB(100, 100, 100)
			buyButton.Text = "BUY"
		end
	else
		nextLabel.Text = "All items purchased! Time to rebirth?"
		buyButton.Visible = false
	end
end

local function updateRebirthDisplay()
	local rebirthLabel = hud.MainPanel.RebirthLabel
	rebirthLabel.Text = "Rebirths: " .. rebirthData.count

	local multLabel = hud.MainPanel.MultLabel
	multLabel.Text = string.format("%.1fx Multiplier", rebirthData.currentMultiplier)

	local rebirthButton = hud.RebirthButton
	rebirthButton.Text = "REBIRTH\n$" .. Utils.formatCash(rebirthData.cost)

	if currentCash >= rebirthData.cost then
		rebirthButton.BackgroundColor3 = Color3.fromRGB(180, 50, 50)
	else
		rebirthButton.BackgroundColor3 = Color3.fromRGB(80, 40, 40)
	end
end

local function updateAll()
	updateCashDisplay()
	updateIncomeDisplay()
	updateNextItem()
	updateRebirthDisplay()
end

-- Event handlers
UpdateCash.OnClientEvent:Connect(function(cash)
	currentCash = cash
	updateCashDisplay()
	updateNextItem()
	updateRebirthDisplay()
end)

UpdateItems.OnClientEvent:Connect(function(items)
	ownedItems = items
	updateIncomeDisplay()
	updateNextItem()
end)

RebirthInfo.OnClientEvent:Connect(function(info)
	rebirthData = info
	updateRebirthDisplay()
	updateIncomeDisplay()
end)

ItemPurchased.OnClientEvent:Connect(function(itemIndex, itemName)
	-- Flash effect could go here
end)

RebirthSuccess.OnClientEvent:Connect(function(newCount)
	rebirthData.count = newCount
	updateAll()
end)

-- Button clicks
hud.BuyButton.MouseButton1Click:Connect(function()
	local nextIndex = #ownedItems + 1
	PurchaseItem:FireServer(nextIndex)
end)

hud.RebirthButton.MouseButton1Click:Connect(function()
	RequestRebirth:FireServer()
end)

hud.ShopButton.MouseButton1Click:Connect(function()
	-- Toggle shop visibility (ShopUI handles this)
	local shopGui = PlayerGui:FindFirstChild("ShopGUI")
	if shopGui then
		local frame = shopGui:FindFirstChild("ShopFrame")
		if frame then
			frame.Visible = not frame.Visible
		end
	end
end)

-- Request initial data
task.wait(1)
RequestData:FireServer()

print("[TycoonUI] Initialized")
