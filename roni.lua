-- =============================================
-- RONI HUB - Grow a Garden
-- =============================================

print("🔥 RONI HUB Loaded Successfully!")

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local LocalPlayer = Players.LocalPlayer

-- ================== SETTINGS ==================
getgenv().RoniHub = {
    WalkSpeed = 90,
    JumpPower = 60,
    AutoPlant = false,
    AutoHarvest = false,
    AutoAcceptGift = false,
    AutoSell = false
}

print("🌱 RONI HUB Menu Loaded")

-- ================== GUI MENU ==================
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "RoniHubGUI"
ScreenGui.ResetOnSpawn = false
ScreenGui.Parent = LocalPlayer:WaitForChild("PlayerGui")

local MainFrame = Instance.new("Frame")
MainFrame.Size = UDim2.new(0, 320, 0, 400)
MainFrame.Position = UDim2.new(0.5, -160, 0.5, -200)
MainFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
MainFrame.Parent = ScreenGui

Instance.new("UICorner", MainFrame).CornerRadius = UDim.new(0, 12)

local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(1, 0, 0, 50)
Title.BackgroundTransparency = 1
Title.Text = "🔑 RONI HUB"
Title.TextColor3 = Color3.fromRGB(0, 255, 120)
Title.TextScaled = true
Title.Font = Enum.Font.GothamBold
Title.Parent = MainFrame

-- WalkSpeed
local wsLabel = Instance.new("TextLabel")
wsLabel.Text = "WalkSpeed: " .. getgenv().RoniHub.WalkSpeed
wsLabel.Size = UDim2.new(0.9,0,0,30)
wsLabel.Position = UDim2.new(0.05,0,0.15,0)
wsLabel.BackgroundTransparency = 1
wsLabel.TextColor3 = Color3.fromRGB(255,255,255)
wsLabel.Parent = MainFrame

-- Toggle Auto Accept Gift
local function createToggle(name, position, setting)
    local toggle = Instance.new("TextButton")
    toggle.Size = UDim2.new(0.9,0,0,40)
    toggle.Position = position
    toggle.BackgroundColor3 = Color3.fromRGB(40,40,40)
    toggle.Text = name .. ": OFF"
    toggle.TextColor3 = Color3.fromRGB(255,100,100)
    toggle.Parent = MainFrame
    Instance.new("UICorner", toggle).CornerRadius = UDim.new(0,8)

    toggle.MouseButton1Click:Connect(function()
        getgenv().RoniHub[setting] = not getgenv().RoniHub[setting]
        if getgenv().RoniHub[setting] then
            toggle.Text = name .. ": ON"
            toggle.TextColor3 = Color3.fromRGB(0,255,100)
        else
            toggle.Text = name .. ": OFF"
            toggle.TextColor3 = Color3.fromRGB(255,100,100)
        end
    end)
end

createToggle("Auto Accept Gift", UDim2.new(0.05,0,0.3,0), "AutoAcceptGift")
createToggle("Auto Plant", UDim2.new(0.05,0,0.45,0), "AutoPlant")
createToggle("Auto Harvest", UDim2.new(0.05,0,0.6,0), "AutoHarvest")
createToggle("Auto Sell", UDim2.new(0.05,0,0.75,0), "AutoSell")

print("✅ RONI HUB GUI telah muncul!")
