--[[
	SpinWheelManager — Lucky Spin Wheel system
	Free spin every 30 minutes, premium spin for R$19.
	8 weighted segments with cash, boosts, and jackpot rewards.
]]

local Players = game:GetService("Players")
local MarketplaceService = game:GetService("MarketplaceService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Utils = require(Shared:WaitForChild("Utils"))

local Remotes = ReplicatedStorage:WaitForChild("Remotes")

-- Create remotes
local RequestSpinRemote = Instance.new("RemoteEvent")
RequestSpinRemote.Name = "RequestSpin"
RequestSpinRemote.Parent = Remotes

local SpinResultRemote = Instance.new("RemoteEvent")
SpinResultRemote.Name = "SpinResult"
SpinResultRemote.Parent = Remotes

local SpinInfoRemote = Instance.new("RemoteEvent")
SpinInfoRemote.Name = "SpinInfo"
SpinInfoRemote.Parent = Remotes

local FREE_SPIN_COOLDOWN = 1800 -- 30 minutes

-- Developer product ID for premium spin (placeholder — create in Creator Dashboard)
local PREMIUM_SPIN_PRODUCT_ID = 0

-- Pending premium spins awaiting purchase completion
local pendingPremiumSpins = {} -- [player] = true

-- Wheel segments: name, weight (out of 100), reward type, reward value, description
local SEGMENTS = {
	{name = "Small Cash",     weight = 25, rewardType = "cash",    rewardValue = 5000,    description = "+$5,000"},
	{name = "Medium Cash",    weight = 20, rewardType = "cash",    rewardValue = 25000,   description = "+$25,000"},
	{name = "Large Cash",     weight = 10, rewardType = "cash",    rewardValue = 100000,  description = "+$100,000"},
	{name = "Temp 2x Boost",  weight = 15, rewardType = "boost",   rewardValue = 300,     description = "2x Income for 5 min", boostMultiplier = 2},
	{name = "Temp 3x Boost",  weight = 5,  rewardType = "boost",   rewardValue = 180,     description = "3x Income for 3 min", boostMultiplier = 3},
	{name = "Free Rebirth",   weight = 3,  rewardType = "rebirth", rewardValue = 1,       description = "Skip next rebirth cost!"},
	{name = "Nothing",        weight = 15, rewardType = "nothing", rewardValue = 0,       description = "Better luck next time!"},
	{name = "JACKPOT",        weight = 2,  rewardType = "cash",    rewardValue = 500000,  description = "+$500,000!"},
}

-- Precompute total weight (should be 95, but we normalize anyway)
local TOTAL_WEIGHT = 0
for _, seg in ipairs(SEGMENTS) do
	TOTAL_WEIGHT = TOTAL_WEIGHT + seg.weight
end

-- Weighted random selection — returns segment index
local function pickSegment()
	local roll = math.random() * TOTAL_WEIGHT
	local cumulative = 0
	for i, seg in ipairs(SEGMENTS) do
		cumulative = cumulative + seg.weight
		if roll <= cumulative then
			return i
		end
	end
	return #SEGMENTS -- fallback
end

-- Apply the reward for a given segment to a player
local function applyReward(player, segIndex)
	local seg = SEGMENTS[segIndex]
	if not seg then return end

	local data = _G.GetPlayerData and _G.GetPlayerData(player)
	if not data then return end

	if seg.rewardType == "cash" then
		if _G.AddCash then
			_G.AddCash(player, seg.rewardValue)
		end

	elseif seg.rewardType == "boost" then
		-- Set boost expiry to whichever is later: current expiry or now + duration
		local newExpiry = os.time() + seg.rewardValue
		if data.tempBoostExpiry and data.tempBoostExpiry > os.time() then
			-- Extend existing boost if it's still active
			data.tempBoostExpiry = math.max(data.tempBoostExpiry, newExpiry)
		else
			data.tempBoostExpiry = newExpiry
		end

	elseif seg.rewardType == "rebirth" then
		data.freeRebirthGranted = true

	-- "nothing" — no action needed
	end
end

-- Perform a spin for the player
local function doSpin(player)
	local segIndex = pickSegment()
	local seg = SEGMENTS[segIndex]

	-- Update last spin time
	local data = _G.GetPlayerData and _G.GetPlayerData(player)
	if data then
		data.lastSpinTime = os.time()
	end

	-- Apply reward server-side
	applyReward(player, segIndex)

	-- Send result to client
	SpinResultRemote:FireClient(player, segIndex, seg.name, seg.description)

	print("[SpinWheel] " .. player.Name .. " spun and got: " .. seg.name .. " — " .. seg.description)
end

-- Get time until next free spin
local function getTimeUntilFreeSpin(player)
	local data = _G.GetPlayerData and _G.GetPlayerData(player)
	if not data then return FREE_SPIN_COOLDOWN end

	local elapsed = os.time() - (data.lastSpinTime or 0)
	return math.max(0, FREE_SPIN_COOLDOWN - elapsed)
end

-- Send spin info to a single player
local function sendSpinInfo(player)
	local remaining = getTimeUntilFreeSpin(player)
	SpinInfoRemote:FireClient(player, {
		timeUntilFreeSpin = remaining,
		segments = SEGMENTS,
	})
end

-- Handle spin requests
RequestSpinRemote.OnServerEvent:Connect(function(player, isPremium)
	local data = _G.GetPlayerData and _G.GetPlayerData(player)
	if not data then return end

	if isPremium then
		-- Premium spin: prompt dev product purchase
		if PREMIUM_SPIN_PRODUCT_ID > 0 then
			pendingPremiumSpins[player] = true
			MarketplaceService:PromptProductPurchase(player, PREMIUM_SPIN_PRODUCT_ID)
		else
			-- Placeholder ID — just do the spin for testing
			doSpin(player)
			sendSpinInfo(player)
		end
	else
		-- Free spin: check cooldown
		local remaining = getTimeUntilFreeSpin(player)
		if remaining <= 0 then
			doSpin(player)
			sendSpinInfo(player)
		else
			-- Not ready yet, send updated info
			sendSpinInfo(player)
		end
	end
end)

-- Handle premium spin purchase completion
-- NOTE: If PREMIUM_SPIN_PRODUCT_ID is set to a real ID, add it to the processReceipt
-- handler in MonetizationManager.server.lua. For now, we hook into PromptProductPurchaseFinished.
MarketplaceService.PromptProductPurchaseFinished:Connect(function(userId, productId, wasPurchased)
	if productId ~= PREMIUM_SPIN_PRODUCT_ID or not wasPurchased then return end

	local player = Players:GetPlayerByUserId(userId)
	if not player then return end

	if pendingPremiumSpins[player] then
		pendingPremiumSpins[player] = nil
		doSpin(player)
		sendSpinInfo(player)
	end
end)

-- Periodically send spin info to all players (every 30s)
task.spawn(function()
	while true do
		task.wait(30)
		for _, player in ipairs(Players:GetPlayers()) do
			task.spawn(function()
				if _G.GetPlayerData and _G.GetPlayerData(player) then
					sendSpinInfo(player)
				end
			end)
		end
	end
end)

-- Poll-wait for player data
local function waitForPlayerData(player, timeout)
	local elapsed = 0
	while not (_G.GetPlayerData and _G.GetPlayerData(player)) and elapsed < (timeout or 15) do
		task.wait(0.5)
		elapsed = elapsed + 0.5
	end
	return _G.GetPlayerData and _G.GetPlayerData(player) ~= nil
end

-- Player joined — send initial spin info
Players.PlayerAdded:Connect(function(player)
	if not waitForPlayerData(player, 15) then
		warn("[SpinWheel] Timed out waiting for player data: " .. player.Name)
		return
	end
	task.wait(2) -- let UI initialize
	sendSpinInfo(player)
end)

-- Cleanup
Players.PlayerRemoving:Connect(function(player)
	pendingPremiumSpins[player] = nil
end)

-- Handle players already in game (Studio testing)
for _, player in ipairs(Players:GetPlayers()) do
	task.spawn(function()
		if not waitForPlayerData(player, 15) then return end
		task.wait(2)
		sendSpinInfo(player)
	end)
end

print("[SpinWheelManager] Initialized")
