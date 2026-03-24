--[[
	WelcomeBackUI — Returning player welcome popup
	Shows what the player missed while away + offline earnings bonus.
	Fires only for returning players via the WelcomeBack RemoteEvent.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Utils = require(Shared:WaitForChild("Utils"))

local Remotes = ReplicatedStorage:WaitForChild("Remotes")
local WelcomeBackRemote = Remotes:WaitForChild("WelcomeBack", 15)

local player = Players.LocalPlayer
local PlayerGui = player:WaitForChild("PlayerGui")

if not WelcomeBackRemote then
	warn("[WelcomeBackUI] WelcomeBack remote not found")
	return
end

-- Format time duration into human-readable string
local function formatTimeDuration(seconds)
	if seconds >= 86400 then
		local days = math.floor(seconds / 86400)
		return days .. (days == 1 and " day" or " days")
	elseif seconds >= 3600 then
		local hours = math.floor(seconds / 3600)
		return hours .. (hours == 1 and " hour" or " hours")
	else
		local minutes = math.max(1, math.floor(seconds / 60))
		return minutes .. (minutes == 1 and " minute" or " minutes")
	end
end

-- Build UI
local function createWelcomeBackUI()
	local screenGui = Instance.new("ScreenGui")
	screenGui.Name = "WelcomeBackGUI"
	screenGui.ResetOnSpawn = false
	screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	screenGui.Parent = PlayerGui

	-- Background overlay
	local overlay = Instance.new("Frame")
	overlay.Name = "Overlay"
	overlay.Size = UDim2.new(1, 0, 1, 0)
	overlay.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
	overlay.BackgroundTransparency = 0.5
	overlay.BorderSizePixel = 0
	overlay.Visible = false
	overlay.ZIndex = 90
	overlay.Parent = screenGui

	-- Main frame
	local frame = Instance.new("Frame")
	frame.Name = "WelcomeFrame"
	frame.Size = UDim2.new(0, 380, 0, 280)
	frame.Position = UDim2.new(0.5, -190, 0.5, -140)
	frame.BackgroundColor3 = Color3.fromRGB(25, 25, 40)
	frame.BackgroundTransparency = 0.05
	frame.BorderSizePixel = 0
	frame.Visible = false
	frame.ZIndex = 91
	frame.Parent = screenGui

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 12)
	corner.Parent = frame

	local stroke = Instance.new("UIStroke")
	stroke.Color = Color3.fromRGB(255, 215, 0)
	stroke.Thickness = 2
	stroke.Parent = frame

	-- Title
	local title = Instance.new("TextLabel")
	title.Size = UDim2.new(1, 0, 0, 40)
	title.Position = UDim2.new(0, 0, 0, 8)
	title.BackgroundTransparency = 1
	title.Text = "WELCOME BACK!"
	title.TextColor3 = Color3.fromRGB(255, 215, 0)
	title.TextSize = 26
	title.Font = Enum.Font.GothamBold
	title.ZIndex = 92
	title.Parent = frame

	-- Stats container
	local statsFrame = Instance.new("Frame")
	statsFrame.Name = "Stats"
	statsFrame.Size = UDim2.new(1, -40, 0, 150)
	statsFrame.Position = UDim2.new(0, 20, 0, 52)
	statsFrame.BackgroundTransparency = 1
	statsFrame.ZIndex = 92
	statsFrame.Parent = frame

	local statsLayout = Instance.new("UIListLayout")
	statsLayout.FillDirection = Enum.FillDirection.Vertical
	statsLayout.HorizontalAlignment = Enum.HorizontalAlignment.Left
	statsLayout.Padding = UDim.new(0, 6)
	statsLayout.Parent = statsFrame

	-- Helper to create stat lines
	local function createStatLine(text, color, order)
		local label = Instance.new("TextLabel")
		label.Size = UDim2.new(1, 0, 0, 22)
		label.BackgroundTransparency = 1
		label.Text = text
		label.TextColor3 = color
		label.TextSize = 16
		label.Font = Enum.Font.GothamBold
		label.TextXAlignment = Enum.TextXAlignment.Left
		label.LayoutOrder = order
		label.ZIndex = 93
		label.Parent = statsFrame
		return label
	end

	-- Collect & Play button
	local collectBtn = Instance.new("TextButton")
	collectBtn.Name = "CollectButton"
	collectBtn.Size = UDim2.new(0, 220, 0, 45)
	collectBtn.Position = UDim2.new(0.5, -110, 1, -58)
	collectBtn.BackgroundColor3 = Color3.fromRGB(50, 180, 50)
	collectBtn.BorderSizePixel = 0
	collectBtn.Text = "COLLECT & PLAY"
	collectBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
	collectBtn.TextSize = 18
	collectBtn.Font = Enum.Font.GothamBold
	collectBtn.ZIndex = 92
	collectBtn.Parent = frame

	local btnCorner = Instance.new("UICorner")
	btnCorner.CornerRadius = UDim.new(0, 8)
	btnCorner.Parent = collectBtn

	return screenGui, frame, overlay, createStatLine, collectBtn
end

local gui, frame, overlay, createStatLine, collectBtn = createWelcomeBackUI()

local function dismissPopup()
	if _G.PlayButtonClick then _G.PlayButtonClick() end

	local tween = TweenService:Create(frame, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
		Position = UDim2.new(0.5, -190, 0, -300),
	})
	tween:Play()

	TweenService:Create(overlay, TweenInfo.new(0.3), {
		BackgroundTransparency = 1,
	}):Play()

	tween.Completed:Connect(function()
		frame.Visible = false
		overlay.Visible = false
	end)
end

collectBtn.MouseButton1Click:Connect(dismissPopup)

-- Listen for WelcomeBack remote
WelcomeBackRemote.OnClientEvent:Connect(function(info)
	if not info then return end

	-- Clear any previous stat lines
	for _, child in ipairs(frame:FindFirstChild("Stats"):GetChildren()) do
		if child:IsA("TextLabel") then
			child:Destroy()
		end
	end

	-- Build stat lines
	local order = 0

	-- Time away
	order = order + 1
	createStatLine(
		"You were away for " .. formatTimeDuration(info.timeSinceLastVisit),
		Color3.fromRGB(220, 220, 220),
		order
	)

	-- Offline earnings
	if info.offlineEarnings and info.offlineEarnings > 0 then
		order = order + 1
		createStatLine(
			"Offline earnings: +$" .. Utils.formatCash(info.offlineEarnings),
			Color3.fromRGB(100, 255, 100),
			order
		)
	end

	-- Daily reward available
	if info.dailyAvailable then
		order = order + 1
		createStatLine(
			"Daily Reward available!",
			Color3.fromRGB(255, 215, 0),
			order
		)
	end

	-- Active event
	if info.activeEvent then
		order = order + 1
		createStatLine(
			"Event active: " .. info.activeEvent .. "!",
			Color3.fromRGB(0, 220, 255),
			order
		)
	end

	-- Show popup with entrance animation
	frame.Position = UDim2.new(0.5, -190, 0, -300)
	frame.Visible = true
	overlay.BackgroundTransparency = 1
	overlay.Visible = true

	TweenService:Create(overlay, TweenInfo.new(0.3), {
		BackgroundTransparency = 0.5,
	}):Play()

	TweenService:Create(frame, TweenInfo.new(0.5, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
		Position = UDim2.new(0.5, -190, 0.5, -140),
	}):Play()

	-- Auto-dismiss after 10 seconds
	task.delay(10, function()
		if frame.Visible then
			dismissPopup()
		end
	end)
end)

print("[WelcomeBackUI] Initialized")
