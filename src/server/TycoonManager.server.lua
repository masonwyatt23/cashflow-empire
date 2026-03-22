--[[
	TycoonManager — Core game loop
	Handles plot assignment, income generation, purchases, and progression.
	All game state lives server-side for security.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local GameConfig = require(Shared:WaitForChild("GameConfig"))
local Utils = require(Shared:WaitForChild("Utils"))

local Remotes = ReplicatedStorage:WaitForChild("Remotes")

-- Create RemoteEvents
local function createRemote(name, className)
	local remote = Instance.new(className or "RemoteEvent")
	remote.Name = name
	remote.Parent = Remotes
	return remote
end

local PurchaseItemRemote = createRemote("PurchaseItem")
local UpdateCashRemote = createRemote("UpdateCash")
local UpdateItemsRemote = createRemote("UpdateItems")
local RequestDataRemote = createRemote("RequestData")
local ItemPurchasedRemote = createRemote("ItemPurchased")

-- Player tycoon state (server-authoritative)
local PlayerData = {} -- [player] = {cash, ownedItems, rebirthCount, ...}
local PlayerPlots = {} -- [player] = plotNumber

-- Track available plots
local AvailablePlots = {}
for i = 1, GameConfig.MaxPlots do
	table.insert(AvailablePlots, i)
end

-- Module references (set by DataManager)
local DataManager = nil
local MonetizationManager = nil

-- Expose PlayerData for other server scripts
_G.TycoonPlayerData = PlayerData
_G.TycoonPlayerPlots = PlayerPlots

-- Initialize player data (called by DataManager after loading)
function _G.InitializePlayerData(player, savedData)
	PlayerData[player] = savedData or {
		cash = GameConfig.StartingCash,
		ownedItems = {},
		rebirthCount = 0,
		totalEarned = 0,
		lastDaily = 0,
		dailyStreak = 0,
		tempBoostExpiry = 0,
	}

	-- Assign a plot
	if #AvailablePlots > 0 then
		local plotNum = table.remove(AvailablePlots, 1)
		PlayerPlots[player] = plotNum
	end

	-- Send initial state to client
	UpdateCashRemote:FireClient(player, PlayerData[player].cash)
	UpdateItemsRemote:FireClient(player, PlayerData[player].ownedItems)
end

-- Get player data (used by other managers)
function _G.GetPlayerData(player)
	return PlayerData[player]
end

-- Add cash to player (used by monetization, rebirth, etc.)
function _G.AddCash(player, amount)
	local data = PlayerData[player]
	if not data then return end
	data.cash = data.cash + amount
	data.totalEarned = data.totalEarned + math.max(0, amount)
	UpdateCashRemote:FireClient(player, data.cash)

	-- Update leaderboard
	local leaderstats = player:FindFirstChild("leaderstats")
	if leaderstats then
		local cashStat = leaderstats:FindFirstChild("Cash")
		if cashStat then
			cashStat.Value = data.cash
		end
	end
end

-- Get next available item index for player
local function getNextItemIndex(player)
	local data = PlayerData[player]
	if not data then return nil end
	return #data.ownedItems + 1
end

-- Handle item purchase
local function onPurchaseItem(player, itemIndex)
	local data = PlayerData[player]
	if not data then return end

	-- Validate: must be the next item in sequence
	local nextIndex = getNextItemIndex(player)
	if itemIndex ~= nextIndex then return end

	-- Validate: item exists
	local item = GameConfig.TycoonItems[itemIndex]
	if not item then return end

	-- Validate: player has enough cash
	if data.cash < item.cost then return end

	-- Deduct cash and add item
	data.cash = data.cash - item.cost
	table.insert(data.ownedItems, itemIndex)

	-- Notify client
	UpdateCashRemote:FireClient(player, data.cash)
	UpdateItemsRemote:FireClient(player, data.ownedItems)
	ItemPurchasedRemote:FireClient(player, itemIndex, item.name)
end

-- Handle client data request
local function onRequestData(player)
	local data = PlayerData[player]
	if not data then return end
	UpdateCashRemote:FireClient(player, data.cash)
	UpdateItemsRemote:FireClient(player, data.ownedItems)
end

-- Income tick — runs every IncomeInterval seconds
local incomeAccumulator = 0

RunService.Heartbeat:Connect(function(dt)
	incomeAccumulator = incomeAccumulator + dt

	if incomeAccumulator >= GameConfig.IncomeInterval then
		incomeAccumulator = incomeAccumulator - GameConfig.IncomeInterval

		for player, data in pairs(PlayerData) do
			if player.Parent then -- still in game
				-- Calculate multiplier
				local hasDoubleIncome = false
				local hasTempBoost = false

				-- Check game pass (via _G set by MonetizationManager)
				if _G.HasGamePass and _G.HasGamePass(player, "DoubleIncome") then
					hasDoubleIncome = true
				end

				-- Check temp boost
				if data.tempBoostExpiry and os.time() < data.tempBoostExpiry then
					hasTempBoost = true
				end

				local multiplier = Utils.getIncomeMultiplier(
					data.rebirthCount,
					hasDoubleIncome,
					hasTempBoost,
					GameConfig
				)

				local income = Utils.getTotalIncome(data.ownedItems, multiplier, GameConfig)

				if income > 0 then
					_G.AddCash(player, income)
				end
			end
		end
	end
end)

-- Connect events
PurchaseItemRemote.OnServerEvent:Connect(onPurchaseItem)
RequestDataRemote.OnServerEvent:Connect(onRequestData)

-- Player leaving — free up plot
Players.PlayerRemoving:Connect(function(player)
	local plotNum = PlayerPlots[player]
	if plotNum then
		table.insert(AvailablePlots, plotNum)
		table.sort(AvailablePlots)
	end
	PlayerPlots[player] = nil
	-- PlayerData cleanup happens after DataManager saves
	task.delay(5, function()
		PlayerData[player] = nil
	end)
end)

print("[TycoonManager] Initialized")
