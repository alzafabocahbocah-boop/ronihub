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
    AutoPlant = false,
    AutoGiftPet = false,
    TargetPlayer = nil,
    SelectedPet = nil,
    GiftKG = 100,
    GiftAge = 10
}

-- WalkSpeed & JumpPower
spawn(function()
    while wait(0.5) do
        pcall(function()
            local hum = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid")
            if hum then
                hum.WalkSpeed = getgenv().Settings.WalkSpeed
                hum.JumpPower = getgenv().Settings.JumpPower
            end
        end)
    end
end)

-- Auto Sell
spawn(function()
    while wait(1) do
        if getgenv().Settings.AutoSellAll or getgenv().Settings.AutoSellStrawberry then
            pcall(function()
                for _, item in pairs(LocalPlayer.Backpack:GetChildren()) do
                    local name = item.Name
                    if (getgenv().Settings.AutoSellAll and (name:find("Strawberry") or name:find("Beanstalk"))) or
                       (getgenv().Settings.AutoSellStrawberry and name:find("Strawberry")) then
                        local prompt = item:FindFirstChildWhichIsA("ProximityPrompt")
                        if prompt then
                            prompt:InputHoldBegin()
                            wait(0.15)
                            prompt:InputHoldEnd()
                        end
                    end
                end
            end)
        end
    end
end)

-- Auto Gift Pet
spawn(function()
    while wait(2.5) do
        if getgenv().Settings.AutoGiftPet and getgenv().Settings.TargetPlayer and getgenv().Settings.SelectedPet then
            pcall(function()
                local target = Players:FindFirstChild(getgenv().Settings.TargetPlayer)
                if target then
                    for _, pet in pairs(LocalPlayer.Backpack:GetChildren()) do
                        if pet.Name == getgenv().Settings.SelectedPet then
                            local prompt = pet:FindFirstChildWhichIsA("ProximityPrompt")
                            if prompt then
                                prompt:InputHoldBegin()
                                wait(0.4)
                                prompt:InputHoldEnd()
                                print("Gifted "..pet.Name.." to "..target.Name)
                            end
                        end
                    end
                end
            end)
        end
    end
end)

-- ================== GUI BARU (Kuning Gelap + Text Kecil) ==================
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Parent = LocalPlayer:WaitForChild("PlayerGui")

local MainFrame = Instance.new("Frame")
MainFrame.Size = UDim2.new(0, 340, 0, 580)
MainFrame.Position = UDim2.new(0, 30, 0.2, 0)
MainFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
MainFrame.Parent = ScreenGui
Instance.new("UICorner", MainFrame).CornerRadius = UDim.new(0, 12)
MainFrame.Draggable = true
MainFrame.Active = true

local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(1,0,0,45)
Title.BackgroundTransparency = 1
Title.Text = "Garden Helper"
Title.TextColor3 = Color3.fromRGB(255, 200, 0)     -- Kuning gelap
Title.TextSize = 22                                -- Text lebih kecil
Title.Font = Enum.Font.GothamSemibold
Title.Parent = MainFrame

-- Close Button
local closeBtn = Instance.new("TextButton")
closeBtn.Size = UDim2.new(0,30,0,30)
closeBtn.Position = UDim2.new(1,-38,0,8)
closeBtn.Text = "✕"
closeBtn.TextColor3 = Color3.fromRGB(255, 100, 100)
closeBtn.BackgroundTransparency = 1
closeBtn.TextSize = 20
closeBtn.Parent = MainFrame
closeBtn.MouseButton1Click:Connect(function() ScreenGui:Destroy() end)

-- Dropdown Pet
local petBtn = Instance.new("TextButton")
petBtn.Size = UDim2.new(0.9,0,0,38)
petBtn.Position = UDim2.new(0.05,0,0.11,0)
petBtn.BackgroundColor3 = Color3.fromRGB(35,35,35)
petBtn.Text = "Pilih Pet →"
petBtn.TextColor3 = Color3.fromRGB(255, 220, 100)
petBtn.TextSize = 16
petBtn.Font = Enum.Font.Gotham
petBtn.Parent = MainFrame
Instance.new("UICorner", petBtn).CornerRadius = UDim.new(0,8)

petBtn.MouseButton1Click:Connect(function()
    local pets = {}
    for _, item in pairs(LocalPlayer.Backpack:GetChildren()) do
        if item:IsA("Tool") then
            table.insert(pets, item.Name)
        end
    end
    if #pets > 0 then
        petBtn.Text = pets[1]
        getgenv().Settings.SelectedPet = pets[1]
    else
        petBtn.Text = "Tidak ada Pet"
    end
end)

-- Dropdown Player
local playerBtn = Instance.new("TextButton")
playerBtn.Size = UDim2.new(0.9,0,0,38)
playerBtn.Position = UDim2.new(0.05,0,0.22,0)
playerBtn.BackgroundColor3 = Color3.fromRGB(35,35,35)
playerBtn.Text = "Pilih Player →"
playerBtn.TextColor3 = Color3.fromRGB(255, 220, 100)
playerBtn.TextSize = 16
playerBtn.Font = Enum.Font.Gotham
playerBtn.Parent = MainFrame
Instance.new("UICorner", playerBtn).CornerRadius = UDim.new(0,8)

playerBtn.MouseButton1Click:Connect(function()
    local list = {}
    for _, plr in pairs(Players:GetPlayers()) do
        if plr ~= LocalPlayer then table.insert(list, plr.Name) end
    end
    if #list > 0 then
        playerBtn.Text = list[1]
        getgenv().Settings.TargetPlayer = list[1]
    end
end)

-- Slider Function
local function createSlider(name, posY, min, max, default, setting)
    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(0.9,0,0,22)
    label.Position = UDim2.new(0.05,0,posY,0)
    label.BackgroundTransparency = 1
    label.Text = name .. ": " .. default
    label.TextColor3 = Color3.fromRGB(220, 220, 220)
    label.TextSize = 15
    label.Font = Enum.Font.Gotham
    label.Parent = MainFrame

    local slider = Instance.new("TextButton")
    slider.Size = UDim2.new(0.9,0,0,28)
    slider.Position = UDim2.new(0.05,0,posY+0.05,0)
    slider.BackgroundColor3 = Color3.fromRGB(45,45,45)
    slider.Text = ""
    slider.Parent = MainFrame
    Instance.new("UICorner", slider).CornerRadius = UDim.new(0,8)

    local dragging = false
    slider.MouseButton1Down:Connect(function() dragging = true end)
    game:GetService("UserInputService").InputEnded:Connect(function() dragging = false end)

    game:GetService("RunService").RenderStepped:Connect(function()
        if dragging then
            local percent = math.clamp((LocalPlayer:GetMouse().X - slider.AbsolutePosition.X) / slider.AbsoluteSize.X, 0, 1)
            local value = math.floor(min + (max - min) * percent)
            getgenv().Settings[setting] = value
            label.Text = name .. ": " .. value
        end
    end)
end

createSlider("Gift KG",  0.35, 10, 500, 100, "GiftKG")
createSlider("Gift Age", 0.47, 1, 100, 10, "GiftAge")

-- Toggle Function
local function createToggle(name, posY, setting)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(0.9,0,0,38)
    btn.Position = UDim2.new(0.05,0,posY,0)
    btn.BackgroundColor3 = Color3.fromRGB(35,35,35)
    btn.Text = name .. ": OFF"
    btn.TextColor3 = Color3.fromRGB(255, 180, 80)
    btn.TextSize = 16
    btn.Font = Enum.Font.Gotham
    btn.Parent = MainFrame
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0,8)

    btn.MouseButton1Click:Connect(function()
        getgenv().Settings[setting] = not getgenv().Settings[setting]
        btn.Text = name .. (getgenv().Settings[setting] and ": ON" or ": OFF")
        btn.TextColor3 = getgenv().Settings[setting] and Color3.fromRGB(255, 240, 100) or Color3.fromRGB(255, 180, 80)
    end)
end

createToggle("Auto Harvest", 0.62, "AutoHarvest")
createToggle("Auto Sell ALL", 0.72, "AutoSellAll")
createToggle("Auto Sell Strawberry", 0.82, "AutoSellStrawberry")
createToggle("Auto Gift Pet", 0.92, "AutoGiftPet")

print("✅ UI Updated - Kuning Gelap + Text Kecil")
