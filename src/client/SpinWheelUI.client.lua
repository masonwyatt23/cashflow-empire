--[[
	SpinWheelUI — Lucky Spin Wheel popup
	Shows 8 reward segments with spinning animation.
	Free spin every 30 min, premium spin for R$19.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Utils = require(Shared:WaitForChild("Utils"))

local Remotes = ReplicatedStorage:WaitForChild("Remotes")
local RequestSpin = Remotes:WaitForChild("RequestSpin", 15)
local SpinResult = Remotes:WaitForChild("SpinResult", 15)
local SpinInfo = Remotes:WaitForChild("SpinInfo", 15)

local player = Players.LocalPlayer
local PlayerGui = player:WaitForChild("PlayerGui")

-- State
local spinInfo = nil
local isSpinning = false

-- Segment display data (colors for visual variety)
local SEGMENT_COLORS = {
	Color3.fromRGB(50, 180, 50),   -- Small Cash (green)
	Color3.fromRGB(80, 200, 80),   -- Medium Cash (brighter green)
	Color3.fromRGB(50, 220, 50),   -- Large Cash (bright green)
	Color3.fromRGB(80, 150, 255),  -- Temp 2x Boost (blue)
	Color3.fromRGB(150, 100, 255), -- Temp 3x Boost (purple)
	Color3.fromRGB(255, 215, 0),   -- Free Rebirth (gold)
	Color3.fromRGB(100, 100, 100), -- Nothing (gray)
	Color3.fromRGB(255, 50, 50),   -- JACKPOT (red)
}

local SEGMENT_NAMES = {
	"Small Cash (25%)",
	"Medium Cash (20%)",
	"Large Cash (10%)",
	"2x Boost 5min (15%)",
	"3x Boost 3min (5%)",
	"Free Rebirth (3%)",
	"Nothing (15%)",
	"JACKPOT (2%)",
}

-- Build the UI
local function createSpinUI()
	local screenGui = Instance.new("ScreenGui")
	screenGui.Name = "SpinWheelGUI"
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
	overlay.Parent = screenGui

	-- Main frame
	local frame = Instance.new("Frame")
	frame.Name = "SpinFrame"
	frame.Size = UDim2.new(0, 400, 0, 450)
	frame.Position = UDim2.new(0.5, -200, 0.5, -225)
	frame.BackgroundColor3 = Color3.fromRGB(25, 25, 40)
	frame.BackgroundTransparency = 0.05
	frame.BorderSizePixel = 0
	frame.Visible = false
	frame.Parent = screenGui

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 14)
	corner.Parent = frame

	local stroke = Instance.new("UIStroke")
	stroke.Color = Color3.fromRGB(255, 215, 0)
	stroke.Thickness = 2
	stroke.Parent = frame

	-- Title
	local title = Instance.new("TextLabel")
	title.Size = UDim2.new(1, 0, 0, 40)
	title.BackgroundTransparency = 1
	title.Text = "LUCKY SPIN!"
	title.TextColor3 = Color3.fromRGB(255, 215, 0)
	title.TextSize = 26
	title.Font = Enum.Font.GothamBold
	title.Parent = frame

	-- Close button
	local closeBtn = Instance.new("TextButton")
	closeBtn.Size = UDim2.new(0, 30, 0, 30)
	closeBtn.Position = UDim2.new(1, -35, 0, 5)
	closeBtn.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
	closeBtn.BorderSizePixel = 0
	closeBtn.Text = "X"
	closeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
	closeBtn.TextSize = 16
	closeBtn.Font = Enum.Font.GothamBold
	closeBtn.Parent = frame

	local closeCorner = Instance.new("UICorner")
	closeCorner.CornerRadius = UDim.new(0, 6)
	closeCorner.Parent = closeBtn

	closeBtn.MouseButton1Click:Connect(function()
		if isSpinning then return end -- don't close during spin
		frame.Visible = false
		overlay.Visible = false
	end)

	-- Reward rows container
	local rowsFrame = Instance.new("Frame")
	rowsFrame.Name = "Rows"
	rowsFrame.Size = UDim2.new(1, -30, 0, 260)
	rowsFrame.Position = UDim2.new(0, 15, 0, 45)
	rowsFrame.BackgroundTransparency = 1
	rowsFrame.Parent = frame

	local rowLayout = Instance.new("UIListLayout")
	rowLayout.FillDirection = Enum.FillDirection.Vertical
	rowLayout.Padding = UDim.new(0, 3)
	rowLayout.Parent = rowsFrame

	-- Create 8 reward rows
	local rows = {}
	for i = 1, 8 do
		local row = Instance.new("Frame")
		row.Name = "Row" .. i
		row.Size = UDim2.new(1, 0, 0, 29)
		row.BackgroundColor3 = Color3.fromRGB(35, 35, 55)
		row.BorderSizePixel = 0
		row.LayoutOrder = i
		row.Parent = rowsFrame

		local rowCorner = Instance.new("UICorner")
		rowCorner.CornerRadius = UDim.new(0, 6)
		rowCorner.Parent = row

		-- Color indicator
		local indicator = Instance.new("Frame")
		indicator.Name = "Indicator"
		indicator.Size = UDim2.new(0, 8, 0, 20)
		indicator.Position = UDim2.new(0, 8, 0.5, -10)
		indicator.BackgroundColor3 = SEGMENT_COLORS[i]
		indicator.BorderSizePixel = 0
		indicator.Parent = row

		local indCorner = Instance.new("UICorner")
		indCorner.CornerRadius = UDim.new(0, 3)
		indCorner.Parent = indicator

		-- Reward name label
		local nameLabel = Instance.new("TextLabel")
		nameLabel.Name = "NameLabel"
		nameLabel.Size = UDim2.new(1, -30, 1, 0)
		nameLabel.Position = UDim2.new(0, 24, 0, 0)
		nameLabel.BackgroundTransparency = 1
		nameLabel.Text = SEGMENT_NAMES[i]
		nameLabel.TextColor3 = Color3.fromRGB(220, 220, 220)
		nameLabel.TextSize = 14
		nameLabel.Font = Enum.Font.Gotham
		nameLabel.TextXAlignment = Enum.TextXAlignment.Left
		nameLabel.Parent = row

		rows[i] = row
	end

	-- Timer label
	local timerLabel = Instance.new("TextLabel")
	timerLabel.Name = "TimerLabel"
	timerLabel.Size = UDim2.new(1, -30, 0, 25)
	timerLabel.Position = UDim2.new(0, 15, 0, 310)
	timerLabel.BackgroundTransparency = 1
	timerLabel.Text = "Free spin in: --:--"
	timerLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
	timerLabel.TextSize = 14
	timerLabel.Font = Enum.Font.Gotham
	timerLabel.TextXAlignment = Enum.TextXAlignment.Center
	timerLabel.Parent = frame

	-- Result label (hidden until spin completes)
	local resultLabel = Instance.new("TextLabel")
	resultLabel.Name = "ResultLabel"
	resultLabel.Size = UDim2.new(1, -30, 0, 35)
	resultLabel.Position = UDim2.new(0, 15, 0, 335)
	resultLabel.BackgroundTransparency = 1
	resultLabel.Text = ""
	resultLabel.TextColor3 = Color3.fromRGB(255, 215, 0)
	resultLabel.TextSize = 18
	resultLabel.Font = Enum.Font.GothamBold
	resultLabel.TextXAlignment = Enum.TextXAlignment.Center
	resultLabel.TextWrapped = true
	resultLabel.Parent = frame

	-- Buttons frame
	local buttonsFrame = Instance.new("Frame")
	buttonsFrame.Name = "Buttons"
	buttonsFrame.Size = UDim2.new(1, -30, 0, 45)
	buttonsFrame.Position = UDim2.new(0, 15, 1, -55)
	buttonsFrame.BackgroundTransparency = 1
	buttonsFrame.Parent = frame

	-- Free spin button
	local freeBtn = Instance.new("TextButton")
	freeBtn.Name = "FreeSpinBtn"
	freeBtn.Size = UDim2.new(0.48, 0, 1, 0)
	freeBtn.Position = UDim2.new(0, 0, 0, 0)
	freeBtn.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
	freeBtn.BorderSizePixel = 0
	freeBtn.Text = "SPIN FREE"
	freeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
	freeBtn.TextSize = 16
	freeBtn.Font = Enum.Font.GothamBold
	freeBtn.Parent = buttonsFrame

	local freeCorner = Instance.new("UICorner")
	freeCorner.CornerRadius = UDim.new(0, 8)
	freeCorner.Parent = freeBtn

	-- Premium spin button
	local premiumBtn = Instance.new("TextButton")
	premiumBtn.Name = "PremiumSpinBtn"
	premiumBtn.Size = UDim2.new(0.48, 0, 1, 0)
	premiumBtn.Position = UDim2.new(0.52, 0, 0, 0)
	premiumBtn.BackgroundColor3 = Color3.fromRGB(200, 160, 30)
	premiumBtn.BorderSizePixel = 0
	premiumBtn.Text = "PREMIUM R$19"
	premiumBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
	premiumBtn.TextSize = 16
	premiumBtn.Font = Enum.Font.GothamBold
	premiumBtn.Parent = buttonsFrame

	local premCorner = Instance.new("UICorner")
	premCorner.CornerRadius = UDim.new(0, 8)
	premCorner.Parent = premiumBtn

	return screenGui, frame, overlay, rows, timerLabel, resultLabel, freeBtn, premiumBtn
end

local gui, frame, overlay, rows, timerLabel, resultLabel, freeBtn, premiumBtn = createSpinUI()

-- Highlight a single row, reset others
local function highlightRow(index)
	for i, row in ipairs(rows) do
		if i == index then
			row.BackgroundColor3 = SEGMENT_COLORS[i]
			local nameLabel = row:FindFirstChild("NameLabel")
			if nameLabel then
				nameLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
			end
		else
			row.BackgroundColor3 = Color3.fromRGB(35, 35, 55)
			local nameLabel = row:FindFirstChild("NameLabel")
			if nameLabel then
				nameLabel.TextColor3 = Color3.fromRGB(220, 220, 220)
			end
		end
	end
end

-- Reset all row highlights
local function resetRows()
	for i, row in ipairs(rows) do
		row.BackgroundColor3 = Color3.fromRGB(35, 35, 55)
		local nameLabel = row:FindFirstChild("NameLabel")
		if nameLabel then
			nameLabel.TextColor3 = Color3.fromRGB(220, 220, 220)
		end
	end
end

-- Spinning animation: cycle through rows with decreasing speed, land on winner
local function playSpinAnimation(winnerIndex)
	isSpinning = true
	resultLabel.Text = ""
	freeBtn.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
	premiumBtn.BackgroundColor3 = Color3.fromRGB(100, 80, 20)

	-- Spin for ~3 seconds, slowing down
	local totalSteps = 30 + math.random(5, 10)
	local currentIndex = 1

	for step = 1, totalSteps do
		-- Calculate delay: starts fast, slows down exponentially toward the end
		local progress = step / totalSteps
		local delay = 0.05 + (progress * progress * 0.25)

		-- On the last step, land on the winner
		if step == totalSteps then
			currentIndex = winnerIndex
		else
			currentIndex = ((currentIndex) % 8) + 1
		end

		highlightRow(currentIndex)
		task.wait(delay)
	end

	isSpinning = false
end

-- Update timer display
local function updateTimer()
	if not spinInfo then return end

	local remaining = spinInfo.timeUntilFreeSpin or 0
	-- Adjust for time since we received the info
	if spinInfo._receivedAt then
		local elapsed = os.clock() - spinInfo._receivedAt
		remaining = math.max(0, remaining - elapsed)
	end

	if remaining <= 0 then
		timerLabel.Text = "FREE SPIN AVAILABLE!"
		timerLabel.TextColor3 = Color3.fromRGB(100, 255, 100)
		freeBtn.BackgroundColor3 = Color3.fromRGB(50, 180, 50)
		freeBtn.Text = "SPIN FREE"
	else
		local mins = math.floor(remaining / 60)
		local secs = math.floor(remaining % 60)
		timerLabel.Text = string.format("Free spin in: %02d:%02d", mins, secs)
		timerLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
		if not isSpinning then
			freeBtn.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
		end
		freeBtn.Text = "SPIN FREE"
	end

	if not isSpinning then
		premiumBtn.BackgroundColor3 = Color3.fromRGB(200, 160, 30)
	end
end

-- Timer update loop
task.spawn(function()
	while true do
		task.wait(1)
		if frame.Visible then
			updateTimer()
		end
	end
end)

-- Button handlers
freeBtn.MouseButton1Click:Connect(function()
	if isSpinning then return end
	if _G.PlayButtonClick then _G.PlayButtonClick() end
	resultLabel.Text = ""
	RequestSpin:FireServer(false)
end)

premiumBtn.MouseButton1Click:Connect(function()
	if isSpinning then return end
	if _G.PlayButtonClick then _G.PlayButtonClick() end
	resultLabel.Text = ""
	RequestSpin:FireServer(true)
end)

-- Show/hide (called by TycoonUI button)
_G.ShowSpinWheel = function()
	frame.Visible = true
	overlay.Visible = true
	updateTimer()
end

_G.HideSpinWheel = function()
	if isSpinning then return end
	frame.Visible = false
	overlay.Visible = false
end

-- Server events
SpinInfo.OnClientEvent:Connect(function(info)
	spinInfo = info
	spinInfo._receivedAt = os.clock()
	updateTimer()
end)

SpinResult.OnClientEvent:Connect(function(segIndex, rewardName, rewardDescription)
	-- Play the spinning animation, then show result
	task.spawn(function()
		playSpinAnimation(segIndex)

		-- Show result
		if rewardName == "Nothing" then
			resultLabel.TextColor3 = Color3.fromRGB(180, 180, 180)
		elseif rewardName == "JACKPOT" then
			resultLabel.TextColor3 = Color3.fromRGB(255, 50, 50)
		else
			resultLabel.TextColor3 = Color3.fromRGB(255, 215, 0)
		end
		resultLabel.Text = rewardName .. ": " .. rewardDescription

		-- Update timer state (spin was consumed)
		updateTimer()
	end)
end)

print("[SpinWheelUI] Initialized")
