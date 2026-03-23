--[[
	EffectsManager — Visual feedback
	Cash popup numbers, purchase effects, rebirth flash.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Utils = require(Shared:WaitForChild("Utils"))

local Remotes = ReplicatedStorage:WaitForChild("Remotes")
local ItemPurchased = Remotes:WaitForChild("ItemPurchased")
local RebirthSuccess = Remotes:WaitForChild("RebirthSuccess")
local BuildingAppeared = Remotes:WaitForChild("BuildingAppeared")

local player = Players.LocalPlayer
local PlayerGui = player:WaitForChild("PlayerGui")

-- Create effects ScreenGui
local effectsGui = Instance.new("ScreenGui")
effectsGui.Name = "EffectsGUI"
effectsGui.ResetOnSpawn = false
effectsGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
effectsGui.Parent = PlayerGui

-- Floating text effect (purchase notification)
local function showFloatingText(text, color)
	local label = Instance.new("TextLabel")
	label.Size = UDim2.new(0, 300, 0, 50)
	label.Position = UDim2.new(0.5, -150, 0.4, 0)
	label.BackgroundTransparency = 1
	label.Text = text
	label.TextColor3 = color or Color3.fromRGB(255, 215, 0)
	label.TextSize = 28
	label.Font = Enum.Font.GothamBold
	label.TextStrokeTransparency = 0.5
	label.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
	label.Parent = effectsGui

	-- Animate: float up and fade out
	local tweenInfo = TweenInfo.new(1.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
	local tween = TweenService:Create(label, tweenInfo, {
		Position = UDim2.new(0.5, -150, 0.3, 0),
		TextTransparency = 1,
		TextStrokeTransparency = 1,
	})
	tween:Play()
	tween.Completed:Connect(function()
		label:Destroy()
	end)
end

-- Screen flash effect (rebirth)
local function showRebirthEffect()
	local flash = Instance.new("Frame")
	flash.Size = UDim2.new(1, 0, 1, 0)
	flash.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	flash.BackgroundTransparency = 0.3
	flash.BorderSizePixel = 0
	flash.ZIndex = 100
	flash.Parent = effectsGui

	-- Show rebirth text
	local rebirthText = Instance.new("TextLabel")
	rebirthText.Size = UDim2.new(1, 0, 0, 80)
	rebirthText.Position = UDim2.new(0, 0, 0.35, 0)
	rebirthText.BackgroundTransparency = 1
	rebirthText.Text = "REBIRTH!"
	rebirthText.TextColor3 = Color3.fromRGB(255, 50, 50)
	rebirthText.TextSize = 60
	rebirthText.Font = Enum.Font.GothamBold
	rebirthText.TextStrokeTransparency = 0
	rebirthText.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
	rebirthText.ZIndex = 101
	rebirthText.Parent = effectsGui

	-- Fade out flash
	local tweenInfo = TweenInfo.new(2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
	TweenService:Create(flash, tweenInfo, {BackgroundTransparency = 1}):Play()
	TweenService:Create(rebirthText, tweenInfo, {
		TextTransparency = 1,
		TextStrokeTransparency = 1,
		Position = UDim2.new(0, 0, 0.25, 0),
	}):Play()

	task.delay(2.5, function()
		flash:Destroy()
		rebirthText:Destroy()
	end)
end

-- 3D sparkle effect at a world position (building appeared)
local function showBuildingSparkle(position)
	-- Create temporary part with particle emitter
	local effectPart = Instance.new("Part")
	effectPart.Size = Vector3.new(1, 1, 1)
	effectPart.Position = position + Vector3.new(0, 5, 0)
	effectPart.Anchored = true
	effectPart.Transparency = 1
	effectPart.CanCollide = false
	effectPart.Parent = workspace

	local particles = Instance.new("ParticleEmitter")
	particles.Color = ColorSequence.new(Color3.fromRGB(255, 215, 0), Color3.fromRGB(255, 255, 200))
	particles.Size = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 1),
		NumberSequenceKeypoint.new(1, 0),
	})
	particles.Lifetime = NumberRange.new(0.5, 1)
	particles.Rate = 50
	particles.Speed = NumberRange.new(5, 15)
	particles.SpreadAngle = Vector2.new(180, 180)
	particles.Parent = effectPart

	-- Emit burst then cleanup
	particles:Emit(30)
	particles.Enabled = false

	task.delay(2, function()
		effectPart:Destroy()
	end)
end

-- Event handlers
ItemPurchased.OnClientEvent:Connect(function(itemIndex, itemName)
	showFloatingText("Purchased: " .. itemName, Color3.fromRGB(100, 255, 100))
end)

BuildingAppeared.OnClientEvent:Connect(function(position)
	if position then
		showBuildingSparkle(position)
	end
end)

RebirthSuccess.OnClientEvent:Connect(function(newCount)
	showRebirthEffect()
	task.wait(0.5)
	showFloatingText("Rebirth #" .. newCount .. "!", Color3.fromRGB(255, 100, 100))
end)

print("[EffectsManager] Initialized")
