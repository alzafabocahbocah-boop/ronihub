-- RONI HUB - Grow a Garden
print("🔥 RONI HUB Loaded")

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
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
    AutoGiftPet = false
}

-- ================== AUTO BUY LOGIC ==================
spawn(function()
    while wait(1.2) do
        if not (getgenv().Settings.AutoBuySeed or getgenv().Settings.AutoBuyEgg or getgenv().Settings.AutoBuyGear) then continue end
        
        pcall(function()
            for _, obj in pairs(Workspace:GetDescendants()) do
                if obj:IsA("ProximityPrompt") then
                    local parent = obj.Parent
                    
                    -- Auto Buy Seed
                    if getgenv().Settings.AutoBuySeed and (parent.Name:find("Seed") or parent.Name:find("Shop")) then
                        obj:InputHoldBegin()
                        wait(0.2)
                        obj:InputHoldEnd()
                    end
                    
                    -- Auto Buy Egg
                    if getgenv().Settings.AutoBuyEgg and (parent.Name:find("Egg") or parent.Name:find("Hatch")) then
                        obj:InputHoldBegin()
                        wait(0.2)
                        obj:InputHoldEnd()
                    end
                    
                    -- Auto Buy Gear
                    if getgenv().Settings.AutoBuyGear and (parent.Name:find("Gear") or parent.Name:find("Tool")) then
                        obj:InputHoldBegin()
                        wait(0.2)
                        obj:InputHoldEnd()
                    end
                end
            end
        end)
    end
end)

-- ================== GUI (Node Hub Style) ==================
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

local function showMiscContent()
    Content:ClearAllChildren()

    -- Auto Buy Section
    local autoBuyTitle = Instance.new("TextLabel")
    autoBuyTitle.Size = UDim2.new(0.9,0,0,40)
    autoBuyTitle.Position = UDim2.new(0.05,0,0.05,0)
    autoBuyTitle.BackgroundTransparency = 1
    autoBuyTitle.Text = "AUTO BUY"
    autoBuyTitle.TextColor3 = Color3.fromRGB(255,200,0)
    autoBuyTitle.TextSize = 22
    autoBuyTitle.Font = Enum.Font.GothamBold
    autoBuyTitle.Parent = Content

    local function createToggle(name, posY, setting)
        local toggle = Instance.new("TextButton")
        toggle.Size = UDim2.new(0.85,0,0,45)
        toggle.Position = UDim2.new(0.1,0,posY,0)
        toggle.BackgroundColor3 = Color3.fromRGB(35,35,35)
        toggle.Text = name .. ": OFF"
        toggle.TextColor3 = Color3.fromRGB(255,100,100)
        toggle.TextSize = 17
        toggle.Parent = Content
        Instance.new("UICorner", toggle).CornerRadius = UDim.new(0,8)

        toggle.MouseButton1Click:Connect(function()
            getgenv().Settings[setting] = not getgenv().Settings[setting]
            toggle.Text = name .. (getgenv().Settings[setting] and ": ON" or ": OFF")
            toggle.TextColor3 = getgenv().Settings[setting] and Color3.fromRGB(0,255,100) or Color3.fromRGB(255,100,100)
        end)
    end

    createToggle("Auto Buy Seed", 0.18, "AutoBuySeed")
    createToggle("Auto Buy Egg",  0.30, "AutoBuyEgg")
    createToggle("Auto Buy Gear", 0.42, "AutoBuyGear")

    -- Auto Gift & Rejoin (sederhana)
    local giftBtn = Instance.new("TextButton")
    giftBtn.Size = UDim2.new(0.85,0,0,50)
    giftBtn.Position = UDim2.new(0.1,0,0.60,0)
    giftBtn.BackgroundColor3 = Color3.fromRGB(35,35,35)
    giftBtn.Text = "Auto Gift (Coming Soon)"
    giftBtn.TextColor3 = Color3.fromRGB(255,200,0)
    giftBtn.TextSize = 18
    giftBtn.Parent = Content
    Instance.new("UICorner", giftBtn).CornerRadius = UDim.new(0,8)
end

createSidebarButton("ELEPHANT", 0.05, function() 
    Content:ClearAllChildren()
    local txt = Instance.new("TextLabel")
    txt.Size = UDim2.new(0.9,0,0.8,0)
    txt.Position = UDim2.new(0.05,0,0.1,0)
    txt.BackgroundTransparency = 1
    txt.Text = "ELEPHANT\n\nFitur utama sedang dibuat"
    txt.TextColor3 = Color3.fromRGB(180,180,180)
    txt.TextSize = 20
    txt.Parent = Content
end)

createSidebarButton("MISC", 0.45, showMiscContent)

showMiscContent()  -- Default Misc

print("✅ Auto Buy Seed, Egg, Gear sudah ada logic dasar")
