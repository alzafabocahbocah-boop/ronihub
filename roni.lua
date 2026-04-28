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

-- Sidebar Labels (Clickable)
local function createSidebarButton(text, posY, callback)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1, -10, 0, 45)
    btn.Position = UDim2.new(0, 5, posY, 0)
    btn.BackgroundColor3 = Color3.fromRGB(30,30,30)
    btn.Text = text
    btn.TextColor3 = Color3.fromRGB(255, 200, 0)
    btn.TextSize = 18
    btn.Font = Enum.Font.GothamBold
    btn.Parent = Sidebar
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0,6)
    
    btn.MouseButton1Click:Connect(callback)
end

-- ================== SHOW MISC ==================
local function showMiscContent()
    Content:ClearAllChildren()

    -- Auto Buy
    local autoBuy = Instance.new("TextButton")
    autoBuy.Size = UDim2.new(0.9,0,0,50)
    autoBuy.Position = UDim2.new(0.05,0,0.05,0)
    autoBuy.BackgroundColor3 = Color3.fromRGB(35,35,35)
    autoBuy.Text = "Auto Buy"
    autoBuy.TextColor3 = Color3.fromRGB(255,200,0)
    autoBuy.TextSize = 20
    autoBuy.Parent = Content
    Instance.new("UICorner", autoBuy).CornerRadius = UDim.new(0,8)

    -- Auto Gift
    local autoGift = Instance.new("TextButton")
    autoGift.Size = UDim2.new(0.9,0,0,50)
    autoGift.Position = UDim2.new(0.05,0,0.18,0)
    autoGift.BackgroundColor3 = Color3.fromRGB(35,35,35)
    autoGift.Text = "Auto Gift"
    autoGift.TextColor3 = Color3.fromRGB(255,200,0)
    autoGift.TextSize = 20
    autoGift.Parent = Content
    Instance.new("UICorner", autoGift).CornerRadius = UDim.new(0,8)

    -- Rejoin
    local rejoin = Instance.new("TextButton")
    rejoin.Size = UDim2.new(0.9,0,0,50)
    rejoin.Position = UDim2.new(0.05,0,0.31,0)
    rejoin.BackgroundColor3 = Color3.fromRGB(35,35,35)
    rejoin.Text = "Rejoin Server"
    rejoin.TextColor3 = Color3.fromRGB(255,200,0)
    rejoin.TextSize = 20
    rejoin.Parent = Content
    Instance.new("UICorner", rejoin).CornerRadius = UDim.new(0,8)
end

-- Sidebar Buttons
createSidebarButton("ELEPHANT", 0.05, function() 
    Content:ClearAllChildren()
    local txt = Instance.new("TextLabel")
    txt.Size = UDim2.new(0.9,0,0.8,0)
    txt.Position = UDim2.new(0.05,0,0.1,0)
    txt.BackgroundTransparency = 1
    txt.Text = "Elephant Section\n\n(Fitur utama akan ditambahkan)"
    txt.TextColor3 = Color3.fromRGB(180,180,180)
    txt.TextSize = 20
    txt.Parent = Content
end)

createSidebarButton("MISC", 0.45, showMiscContent)

-- Tampilkan Misc secara default
showMiscContent()

print("✅ Misc Tab sudah interaktif (klik MISC)")
