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
    AutoBuySeed = false,
    AutoBuyEgg = false,
    AutoBuyGear = false,
    AutoGiftPet = false,
    TargetPlayer = nil,
    SelectedPet = nil
}

-- ================== GUI ==================
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Parent = LocalPlayer:WaitForChild("PlayerGui")

local MainFrame = Instance.new("Frame")
MainFrame.Size = UDim2.new(0, 700, 0, 480)
MainFrame.Position = UDim2.new(0.5, -350, 0.5, -240)
MainFrame.BackgroundColor3 = Color3.fromRGB(18, 18, 18)
MainFrame.Parent = ScreenGui
Instance.new("UICorner", MainFrame).CornerRadius = UDim.new(0, 10)
MainFrame.Draggable = true

local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(1,0,0,50)
Title.BackgroundColor3 = Color3.fromRGB(25,25,25)
Title.Text = "RONI HUB"
Title.TextColor3 = Color3.fromRGB(255, 200, 0)
Title.TextSize = 26
Title.Font = Enum.Font.GothamBold
Title.Parent = MainFrame

local Sidebar = Instance.new("Frame")
Sidebar.Size = UDim2.new(0, 180, 1, -50)
Sidebar.Position = UDim2.new(0,0,0,50)
Sidebar.BackgroundColor3 = Color3.fromRGB(22,22,22)
Sidebar.Parent = MainFrame

local Content = Instance.new("Frame")
Content.Size = UDim2.new(1, -180, 1, -50)
Content.Position = UDim2.new(0,180,0,50)
Content.BackgroundTransparency = 1
Content.Parent = MainFrame

-- Close
local closeBtn = Instance.new("TextButton")
closeBtn.Size = UDim2.new(0,40,0,40)
closeBtn.Position = UDim2.new(1,-45,0,5)
closeBtn.Text = "✕"
closeBtn.TextColor3 = Color3.fromRGB(255,80,80)
closeBtn.BackgroundTransparency = 1
closeBtn.TextSize = 24
closeBtn.Parent = MainFrame
closeBtn.MouseButton1Click:Connect(function() ScreenGui:Destroy() end)

-- Sidebar
local function createSidebarLabel(text, posY)
    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(1,0,0,40)
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

-- ================== MISC CONTENT ==================
local function showMisc()
    Content:ClearAllChildren()

    -- Auto Buy Button
    local autoBuyBtn = Instance.new("TextButton")
    autoBuyBtn.Size = UDim2.new(0.9,0,0,50)
    autoBuyBtn.Position = UDim2.new(0.05,0,0.05,0)
    autoBuyBtn.BackgroundColor3 = Color3.fromRGB(35,35,35)
    autoBuyBtn.Text = "Auto Buy"
    autoBuyBtn.TextColor3 = Color3.fromRGB(255,200,0)
    autoBuyBtn.TextSize = 20
    autoBuyBtn.Parent = Content
    Instance.new("UICorner", autoBuyBtn).CornerRadius = UDim.new(0,8)

    -- Auto Gift Button
    local autoGiftBtn = Instance.new("TextButton")
    autoGiftBtn.Size = UDim2.new(0.9,0,0,50)
    autoGiftBtn.Position = UDim2.new(0.05,0,0.20,0)
    autoGiftBtn.BackgroundColor3 = Color3.fromRGB(35,35,35)
    autoGiftBtn.Text = "Auto Gift"
    autoGiftBtn.TextColor3 = Color3.fromRGB(255,200,0)
    autoGiftBtn.TextSize = 20
    autoGiftBtn.Parent = Content
    Instance.new("UICorner", autoGiftBtn).CornerRadius = UDim.new(0,8)

    -- Rejoin Button
    local rejoinBtn = Instance.new("TextButton")
    rejoinBtn.Size = UDim2.new(0.9,0,0,50)
    rejoinBtn.Position = UDim2.new(0.05,0,0.35,0)
    rejoinBtn.BackgroundColor3 = Color3.fromRGB(35,35,35)
    rejoinBtn.Text = "Rejoin Server"
    rejoinBtn.TextColor3 = Color3.fromRGB(255,200,0)
    rejoinBtn.TextSize = 20
    rejoinBtn.Parent = Content
    Instance.new("UICorner", rejoinBtn).CornerRadius = UDim.new(0,8)
end

showMisc()

print("✅ Misc Tab dengan Auto Buy & Auto Gift telah dibuat")
