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
    AutoGift = false
}

-- WalkSpeed & JumpPower Real-time
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

-- ================== AUTO SELL ==================
spawn(function()
    while wait(1) do
        if getgenv().Settings.AutoSellAll or getgenv().Settings.AutoSellStrawberry then
            pcall(function()
                for _, item in pairs(LocalPlayer.Backpack:GetChildren()) do
                    local name = item.Name
                    
                    if getgenv().Settings.AutoSellAll then
                        if name:find("Strawberry") or name:find("Beanstalk") or name:find("Blueberry") or 
                           name:find("Raspberry") or name:find("Banana") or name:find("Apple") then
                            local prompt = item:FindFirstChildWhichIsA("ProximityPrompt")
                            if prompt then prompt:InputHoldBegin() wait(0.15) prompt:InputHoldEnd() end
                        end
                    end
                    
                    if getgenv().Settings.AutoSellStrawberry and name:find("Strawberry") then
                        local prompt = item:FindFirstChildWhichIsA("ProximityPrompt")
                        if prompt then prompt:InputHoldBegin() wait(0.15) prompt:InputHoldEnd() end
                    end
                end
            end)
        end
    end
end)

-- ================== GUI ==================
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Parent = LocalPlayer:WaitForChild("PlayerGui")

local MainFrame = Instance.new("Frame")
MainFrame.Size = UDim2.new(0, 340, 0, 520)
MainFrame.Position = UDim2.new(0.5, -170, 0.5, -260)
MainFrame.BackgroundColor3 = Color3.fromRGB(18, 18, 18)
MainFrame.Parent = ScreenGui
Instance.new("UICorner", MainFrame).CornerRadius = UDim.new(0, 12)

local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(1,0,0,50)
Title.BackgroundTransparency = 1
Title.Text = "Garden Helper"
Title.TextColor3 = Color3.fromRGB(0, 220, 100)
Title.TextScaled = true
Title.Font = Enum.Font.GothamBold
Title.Parent = MainFrame

-- Slider Function
local function createSlider(name, posY, min, max, default, setting)
    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(0.9,0,0,25)
    label.Position = UDim2.new(0.05,0,posY,0)
    label.BackgroundTransparency = 1
    label.Text = name .. ": " .. default
    label.TextColor3 = Color3.fromRGB(255,255,255)
    label.TextScaled = true
    label.Font = Enum.Font.Gotham
    label.Parent = MainFrame

    local slider = Instance.new("TextButton")
    slider.Size = UDim2.new(0.9,0,0,30)
    slider.Position = UDim2.new(0.05,0,posY + 0.06,0)
    slider.BackgroundColor3 = Color3.fromRGB(50,50,50)
    slider.Text = ""
    slider.Parent = MainFrame
    Instance.new("UICorner", slider).CornerRadius = UDim.new(0,8)

    -- Drag logic sederhana
    local dragging = false
    slider.MouseButton1Down:Connect(function()
        dragging = true
    end)
    game:GetService("UserInputService").InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = false
        end
    end)

    game:GetService("RunService").RenderStepped:Connect(function()
        if dragging then
            local mouseX = game.Players.LocalPlayer:GetMouse().X
            local sliderPos = slider.AbsolutePosition.X
            local sliderWidth = slider.AbsoluteSize.X
            local percent = math.clamp((mouseX - sliderPos) / sliderWidth, 0, 1)
            local value = math.floor(min + (max - min) * percent)
            
            getgenv().Settings[setting] = value
            label.Text = name .. ": " .. value
        end
    end)
end

-- Toggles
local function createToggle(name, posY, setting)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(0.9,0,0,42)
    btn.Position = UDim2.new(0.05, 0, posY, 0)
    btn.BackgroundColor3 = Color3.fromRGB(35,35,35)
    btn.Text = name .. ": OFF"
    btn.TextColor3 = Color3.fromRGB(255,80,80)
    btn.TextScaled = true
    btn.Parent = MainFrame
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0,8)

    btn.MouseButton1Click:Connect(function()
        getgenv().Settings[setting] = not getgenv().Settings[setting]
        if getgenv().Settings[setting] then
            btn.Text = name .. ": ON"
            btn.TextColor3 = Color3.fromRGB(0,255,100)
        else
            btn.Text = name .. ": OFF"
            btn.TextColor3 = Color3.fromRGB(255,80,80)
        end
    end)
end

-- Tambahkan Slider & Toggle
createSlider("WalkSpeed", 0.12, 16, 300, 90, "WalkSpeed")
createSlider("JumpPower", 0.28, 50, 200, 60, "JumpPower")

createToggle("Auto Harvest",      0.48, "AutoHarvest")
createToggle("Auto Sell ALL Buah", 0.60, "AutoSellAll")
createToggle("Auto Sell Strawberry", 0.72, "AutoSellStrawberry")
createToggle("Auto Plant",        0.84, "AutoPlant")

print("✅ GUI with Slider Updated")
