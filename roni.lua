-- RONI HUB - Grow a Garden
print("🔥 RONI HUB Loaded")

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local LocalPlayer = Players.LocalPlayer

getgenv().Settings = {
    WalkSpeed = 90,
    JumpPower = 60,
    AutoBuySeed = false,
    AutoBuyEgg = false,
    AutoBuyGear = false,
    BuyAll = false,
    SelectedItem = "All"
}

-- ================== AUTO BUY LOGIC ==================
spawn(function()
    while wait(0.8) do
        if not (getgenv().Settings.AutoBuySeed or getgenv().Settings.AutoBuyEgg or getgenv().Settings.AutoBuyGear) then continue end

        pcall(function()
            for _, obj in pairs(Workspace:GetDescendants()) do
                if obj:IsA("ProximityPrompt") then
                    local name = obj.Parent.Name

                    if getgenv().Settings.BuyAll or getgenv().Settings.SelectedItem == "All" then
                        if name:find("Seed") or name:find("Egg") or name:find("Gear") or name:find("Shop") then
                            obj:InputHoldBegin()
                            wait(0.25)
                            obj:InputHoldEnd()
                        end
                    elseif getgenv().Settings.AutoBuySeed and name:find("Seed") then
                        obj:InputHoldBegin()
                        wait(0.25)
                        obj:InputHoldEnd()
                    elseif getgenv().Settings.AutoBuyEgg and name:find("Egg") then
                        obj:InputHoldBegin()
                        wait(0.25)
                        obj:InputHoldEnd()
                    elseif getgenv().Settings.AutoBuyGear and name:find("Gear") then
                        obj:InputHoldBegin()
                        wait(0.25)
                        obj:InputHoldEnd()
                    end
                end
            end
        end)
    end
end)

-- ================== GUI ==================
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Parent = LocalPlayer:WaitForChild("PlayerGui")

local MainFrame = Instance.new("Frame")
MainFrame.Size = UDim2.new(0, 700, 0, 500)
MainFrame.Position = UDim2.new(0.5, -350, 0.5, -250)
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

    -- Auto Buy Title
    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(0.9,0,0,40)
    title.Position = UDim2.new(0.05,0,0.05,0)
    title.BackgroundTransparency = 1
    title.Text = "AUTO BUY"
    title.TextColor3 = Color3.fromRGB(255,200,0)
    title.TextSize = 22
    title.Font = Enum.Font.GothamBold
    title.Parent = Content

    -- Buy All Toggle
    local buyAll = Instance.new("TextButton")
    buyAll.Size = UDim2.new(0.85,0,0,45)
    buyAll.Position = UDim2.new(0.1,0,0.15,0)
    buyAll.BackgroundColor3 = Color3.fromRGB(35,35,35)
    buyAll.Text = "Buy All : OFF"
    buyAll.TextColor3 = Color3.fromRGB(255,100,100)
    buyAll.TextSize = 17
    buyAll.Parent = Content
    Instance.new("UICorner", buyAll).CornerRadius = UDim.new(0,8)

    buyAll.MouseButton1Click:Connect(function()
        getgenv().Settings.BuyAll = not getgenv().Settings.BuyAll
        buyAll.Text = "Buy All : " .. (getgenv().Settings.BuyAll and "ON" or "OFF")
        buyAll.TextColor3 = getgenv().Settings.BuyAll and Color3.fromRGB(0,255,100) or Color3.fromRGB(255,100,100)
    end)

    -- Sub Toggles
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

    createToggle("Auto Buy Seed", 0.30, "AutoBuySeed")
    createToggle("Auto Buy Egg",  0.42, "AutoBuyEgg")
    createToggle("Auto Buy Gear", 0.54, "AutoBuyGear")
end

createSidebarButton("ELEPHANT", 0.05, function() 
    Content:ClearAllChildren()
    local txt = Instance.new("TextLabel")
    txt.Size = UDim2.new(0.9,0,0.8,0)
    txt.Position = UDim2.new(0.05,0,0.1,0)
    txt.BackgroundTransparency = 1
    txt.Text = "ELEPHANT SECTION\n\nSedang dibuat"
    txt.TextColor3 = Color3.fromRGB(180,180,180)
    txt.TextSize = 20
    txt.Parent = Content
end)

createSidebarButton("MISC", 0.45, showMiscContent)

showMiscContent()

print("✅ Auto Buy sudah bisa dipakai (Buy All + Spesifik)")
