-- RONI HUB - Grow a Garden
print("🔥 RONI HUB Loaded")

local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

getgenv().Settings = {
    WalkSpeed = 90,
    JumpPower = 60,
    AutoHarvest = false,
    AutoSellAll = false,
    AutoSellStrawberry = false,
    AutoGiftPet = false,
    AutoBuySeed = false,
    AutoBuyGear = false,
    TargetPlayer = nil,
    SelectedPet = nil
}

-- ================== GUI (Node Hub Style) ==================
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Parent = LocalPlayer:WaitForChild("PlayerGui")

local MainFrame = Instance.new("Frame")
MainFrame.Size = UDim2.new(0, 680, 0, 460)      -- Ukuran lebar
MainFrame.Position = UDim2.new(0.5, -340, 0.5, -230)
MainFrame.BackgroundColor3 = Color3.fromRGB(18, 18, 18)
MainFrame.Parent = ScreenGui
Instance.new("UICorner", MainFrame).CornerRadius = UDim.new(0, 10)
MainFrame.Draggable = true

-- Title
local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(1,0,0,50)
Title.BackgroundColor3 = Color3.fromRGB(25,25,25)
Title.Text = "RONI HUB"
Title.TextColor3 = Color3.fromRGB(255, 200, 0)
Title.TextSize = 26
Title.Font = Enum.Font.GothamBold
Title.Parent = MainFrame

-- Sidebar Kiri
local Sidebar = Instance.new("Frame")
Sidebar.Size = UDim2.new(0, 180, 1, -50)
Sidebar.Position = UDim2.new(0,0,0,50)
Sidebar.BackgroundColor3 = Color3.fromRGB(22,22,22)
Sidebar.Parent = MainFrame

-- Content Area
local Content = Instance.new("Frame")
Content.Size = UDim2.new(1, -180, 1, -50)
Content.Position = UDim2.new(0,180,0,50)
Content.BackgroundTransparency = 1
Content.Parent = MainFrame

-- Close Button
local closeBtn = Instance.new("TextButton")
closeBtn.Size = UDim2.new(0,40,0,40)
closeBtn.Position = UDim2.new(1,-45,0,5)
closeBtn.Text = "✕"
closeBtn.TextColor3 = Color3.fromRGB(255,80,80)
closeBtn.BackgroundTransparency = 1
closeBtn.TextSize = 24
closeBtn.Parent = MainFrame
closeBtn.MouseButton1Click:Connect(function() ScreenGui:Destroy() end)

-- ================== SIDEBAR ==================
local function createSidebarLabel(text, posY)
    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(1,0,0,35)
    lbl.Position = UDim2.new(0,0,posY,0)
    lbl.BackgroundTransparency = 1
    lbl.Text = text
    lbl.TextColor3 = Color3.fromRGB(255, 200, 0)
    lbl.TextSize = 18
    lbl.Font = Enum.Font.GothamBold
    lbl.Parent = Sidebar
end

createSidebarLabel("ELEPHANT", 0.05)
createSidebarLabel("MISC", 0.45)

print("✅ UI Sidebar (Elephant & Misc) telah dibuat")

-- Untuk sementara content kosong dulu
local tempText = Instance.new("TextLabel")
tempText.Size = UDim2.new(0.9,0,0.8,0)
tempText.Position = UDim2.new(0.05,0,0.1,0)
tempText.BackgroundTransparency = 1
tempText.Text = "Pilih fitur di sidebar kiri\n\nElephant = Fitur Utama\nMisc = Fitur Tambahan"
tempText.TextColor3 = Color3.fromRGB(180,180,180)
tempText.TextSize = 18
tempText.Font = Enum.Font.Gotham
tempText.TextWrapped = true
tempText.Parent = Content
