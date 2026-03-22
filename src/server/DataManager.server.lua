--[[
	DataManager — Player data persistence
	Handles save/load via DataStoreService with retry logic and auto-save.
]]

local Players = game:GetService("Players")
local DataStoreService = game:GetService("DataStoreService")
local RunService = game:GetService("RunService")

local PlayerStore = DataStoreService:GetDataStore("PlayerData_v1")

local AUTOSAVE_INTERVAL = 60 -- seconds
local MAX_RETRIES = 3
local RETRY_DELAY = 1 -- seconds

-- Default data template
local DEFAULT_DATA = {
	cash = 0,
	ownedItems = {},
	rebirthCount = 0,
	totalEarned = 0,
	lastDaily = 0,
	dailyStreak = 0,
	tempBoostExpiry = 0,
}

-- Retry wrapper for DataStore operations
local function retryAsync(func, ...)
	local args = {...}
	for attempt = 1, MAX_RETRIES do
		local success, result = pcall(function()
			return func(unpack(args))
		end)
		if success then
			return true, result
		end
		if attempt < MAX_RETRIES then
			warn(string.format("[DataManager] Attempt %d failed, retrying in %ds...", attempt, RETRY_DELAY))
			task.wait(RETRY_DELAY)
		else
			warn(string.format("[DataManager] All %d attempts failed: %s", MAX_RETRIES, tostring(result)))
			return false, result
		end
	end
end

-- Load player data
local function loadPlayerData(player)
	local key = "Player_" .. player.UserId

	local success, data = retryAsync(function()
		return PlayerStore:GetAsync(key)
	end)

	if success and data then
		-- Merge with defaults (handles new fields added in updates)
		for field, default in pairs(DEFAULT_DATA) do
			if data[field] == nil then
				data[field] = default
			end
		end
		return data
	end

	-- New player or load failed — use defaults
	return table.clone(DEFAULT_DATA)
end

-- Save player data
local function savePlayerData(player)
	local data = _G.GetPlayerData(player)
	if not data then return false end

	local key = "Player_" .. player.UserId

	local success, err = retryAsync(function()
		return PlayerStore:UpdateAsync(key, function(oldData)
			-- UpdateAsync is safer than SetAsync for concurrent writes
			return data
		end)
	end)

	if not success then
		warn("[DataManager] Failed to save data for " .. player.Name .. ": " .. tostring(err))
	end

	return success
end

-- Player joined — load data and initialize
Players.PlayerAdded:Connect(function(player)
	local data = loadPlayerData(player)

	-- Initialize via TycoonManager
	if _G.InitializePlayerData then
		_G.InitializePlayerData(player, data)
	end

	print("[DataManager] Loaded data for " .. player.Name)
end)

-- Player leaving — save data
Players.PlayerRemoving:Connect(function(player)
	savePlayerData(player)
	print("[DataManager] Saved data for " .. player.Name)
end)

-- Auto-save loop
task.spawn(function()
	while true do
		task.wait(AUTOSAVE_INTERVAL)
		for _, player in ipairs(Players:GetPlayers()) do
			task.spawn(function()
				savePlayerData(player)
			end)
		end
	end
end)

-- Save all on server shutdown
game:BindToClose(function()
	for _, player in ipairs(Players:GetPlayers()) do
		task.spawn(function()
			savePlayerData(player)
		end)
	end
	-- Give time for saves to complete
	task.wait(3)
end)

-- Handle players already in game (Studio testing)
for _, player in ipairs(Players:GetPlayers()) do
	task.spawn(function()
		local data = loadPlayerData(player)
		if _G.InitializePlayerData then
			_G.InitializePlayerData(player, data)
		end
	end)
end

print("[DataManager] Initialized")
