--[[
	WelcomeBackManager — Returning player welcome notification
	Shows returning players what they missed + awards offline earnings bonus.
	Only fires for players who have played before (tutorialComplete + totalEarned > 0).
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local GameConfig = require(Shared:WaitForChild("GameConfig"))
local Utils = require(Shared:WaitForChild("Utils"))

local Remotes = ReplicatedStorage:WaitForChild("Remotes")

-- Create RemoteEvent
local WelcomeBackRemote = Instance.new("RemoteEvent")
WelcomeBackRemote.Name = "WelcomeBack"
WelcomeBackRemote.Parent = Remotes

local DAY_SECONDS = 86400
local OFFLINE_EARNINGS_CAP = 100000
local OFFLINE_EARNINGS_RATE = 0.1 -- 10% of what they would have earned

-- Poll-wait helper: waits for a _G function to be registered by another script
local function waitForGlobal(name, timeout)
	local elapsed = 0
	while not _G[name] and elapsed < (timeout or 30) do
		task.wait(0.1)
		elapsed = elapsed + 0.1
	end
	return _G[name] ~= nil
end

-- Calculate base income for a player (same logic as TycoonManager income tick)
local function getPlayerBaseIncome(data)
	if not data or not data.ownedItems or #data.ownedItems == 0 then
		return 0
	end

	local multiplier = Utils.getIncomeMultiplier(
		data.rebirthCount or 0,
		false, -- can't know game pass status at this point
		false, -- no temp boost for offline
		GameConfig
	)

	return Utils.getTotalIncome(data.ownedItems, multiplier, GameConfig)
end

Players.PlayerAdded:Connect(function(player)
	-- Wait for data to be loaded by DataManager/TycoonManager
	if not waitForGlobal("GetPlayerData", 30) then return end

	-- Wait for player data to be initialized
	local elapsed = 0
	local data = nil
	while elapsed < 15 do
		data = _G.GetPlayerData(player)
		if data then break end
		task.wait(0.5)
		elapsed = elapsed + 0.5
	end

	if not data then return end

	-- Only show for returning players (not first-time)
	if not data.tutorialComplete or (data.totalEarned or 0) <= 0 then
		-- Still update lastLoginTime for next visit
		data.lastLoginTime = os.time()
		return
	end

	-- Calculate time since last visit
	local now = os.time()
	local lastLogin = data.lastLoginTime or 0

	-- If lastLoginTime is 0, this is a legacy player's first login with this field
	-- Update and skip the welcome back (we don't have accurate timing)
	if lastLogin == 0 then
		data.lastLoginTime = now
		return
	end

	local timeSinceLastVisit = now - lastLogin

	-- Don't show welcome back if they were gone less than 5 minutes
	if timeSinceLastVisit < 300 then
		data.lastLoginTime = now
		return
	end

	-- Calculate offline earnings bonus
	local baseIncome = getPlayerBaseIncome(data)
	local offlineEarnings = math.floor(timeSinceLastVisit * (baseIncome * OFFLINE_EARNINGS_RATE))
	offlineEarnings = math.min(offlineEarnings, OFFLINE_EARNINGS_CAP)

	-- Check if daily reward is available
	local dailyAvailable = false
	local timeSinceDaily = now - (data.lastDaily or 0)
	if timeSinceDaily >= DAY_SECONDS then
		dailyAvailable = true
	end

	-- Check if an event is active
	local eventInfo = nil
	if _G.GetActiveEventInfo then
		local info = _G.GetActiveEventInfo()
		if info and info.active then
			eventInfo = info.name
		end
	end

	-- Update lastLoginTime
	data.lastLoginTime = now

	-- Wait 5 seconds for UI to settle before showing
	task.wait(5)

	-- Verify player is still in game
	if not player.Parent then return end

	-- Award offline earnings
	if offlineEarnings > 0 and _G.AddCash then
		_G.AddCash(player, offlineEarnings)
	end

	-- Fire the WelcomeBack remote to client
	WelcomeBackRemote:FireClient(player, {
		timeSinceLastVisit = timeSinceLastVisit,
		cash = data.cash,
		rebirthCount = data.rebirthCount or 0,
		itemsOwned = #(data.ownedItems or {}),
		offlineEarnings = offlineEarnings,
		dailyAvailable = dailyAvailable,
		activeEvent = eventInfo,
	})
end)

print("[WelcomeBackManager] Initialized")
