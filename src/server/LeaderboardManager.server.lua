--[[
	LeaderboardManager — In-game leaderboard
	Uses Roblox's built-in leaderstats system.
	Shows Cash and Rebirth count for social proof.
]]

local Players = game:GetService("Players")

Players.PlayerAdded:Connect(function(player)
	-- Wait for player data to be initialized
	task.wait(2)

	-- Create leaderstats folder
	local leaderstats = Instance.new("Folder")
	leaderstats.Name = "leaderstats"
	leaderstats.Parent = player

	-- Cash display
	local cashStat = Instance.new("IntValue")
	cashStat.Name = "Cash"
	cashStat.Parent = leaderstats

	-- Rebirth count display
	local rebirthStat = Instance.new("IntValue")
	rebirthStat.Name = "Rebirths"
	rebirthStat.Parent = leaderstats

	-- Set initial values from player data
	local data = _G.GetPlayerData(player)
	if data then
		cashStat.Value = data.cash
		rebirthStat.Value = data.rebirthCount
	end
end)

print("[LeaderboardManager] Initialized")
