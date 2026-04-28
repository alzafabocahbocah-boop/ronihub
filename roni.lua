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

-- Sidebar Button
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

    -- Sub Auto Buy (Seed, Egg, Gear)
    local function createSubToggle(name, posY, setting)
        local toggle = Instance.new("TextButton")
        toggle.Size = UDim2.new(0.85,0,0,40)
        toggle.Position = UDim2.new(0.1,0,posY,0)
        toggle.BackgroundColor3 = Color3.fromRGB(30,30,30)
        toggle.Text = name .. ": OFF"
        toggle.TextColor3 = Color3.fromRGB(255,100,100)
        toggle.TextSize = 16
        toggle.Parent = Content
        Instance.new("UICorner", toggle).CornerRadius = UDim.new(0,8)

        toggle.MouseButton1Click:Connect(function()
            getgenv().Settings[setting] = not getgenv().Settings[setting]
            toggle.Text = name .. (getgenv().Settings[setting] and ": ON" or ": OFF")
            toggle.TextColor3 = getgenv().Settings[setting] and Color3.fromRGB(0,255,100) or Color3.fromRGB(255,100,100)
        end)
    end

    createSubToggle("Auto Buy Seed", 0.20, "AutoBuySeed")
    createSubToggle("Auto Buy Egg",  0.32, "AutoBuyEgg")
    createSubToggle("Auto Buy Gear", 0.44, "AutoBuyGear")

    -- Auto Gift Button
    local autoGiftBtn = Instance.new("TextButton")
    autoGiftBtn.Size = UDim2.new(0.9,0,0,50)
    autoGiftBtn.Position = UDim2.new(0.05,0,0.60,0)
    autoGiftBtn.BackgroundColor3 = Color3.fromRGB(35,35,35)
    autoGiftBtn.Text = "Auto Gift"
    autoGiftBtn.TextColor3 = Color3.fromRGB(255,200,0)
    autoGiftBtn.TextSize = 20
    autoGiftBtn.Parent = Content
    Instance.new("UICorner", autoGiftBtn).CornerRadius = UDim.new(0,8)

    -- Rejoin
    local rejoinBtn = Instance.new("TextButton")
    rejoinBtn.Size = UDim2.new(0.9,0,0,50)
    rejoinBtn.Position = UDim2.new(0.05,0,0.75,0)
    rejoinBtn.BackgroundColor3 = Color3.fromRGB(35,35,35)
    rejoinBtn.Text = "Rejoin Server"
    rejoinBtn.TextColor3 = Color3.fromRGB(255,200,0)
    rejoinBtn.TextSize = 20
    rejoinBtn.Parent = Content
    Instance.new("UICorner", rejoinBtn).CornerRadius = UDim.new(0,8)
end

-- Sidebar
createSidebarButton("ELEPHANT", 0.05, function() 
    Content:ClearAllChildren()
    local txt = Instance.new("TextLabel")
    txt.Size = UDim2.new(0.9,0,0.8,0)
    txt.Position = UDim2.new(0.05,0,0.1,0)
    txt.BackgroundTransparency = 1
    txt.Text = "ELEPHANT SECTION\n\nFitur utama akan ditambahkan di sini"
    txt.TextColor3 = Color3.fromRGB(180,180,180)
    txt.TextSize = 20
    txt.Parent = Content
end)

createSidebarButton("MISC", 0.45, showMiscContent)

-- Default tampilkan Misc
showMiscContent()

print("✅ Misc dengan Auto Buy (Seed, Egg, Gear) telah aktif")
