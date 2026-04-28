-- RONI HUB - Grow a Garden V8.7
print("🔥 RONI HUB V8.7 Loaded")

local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

getgenv().Settings = {
    AutoGiftPet = false,
    TargetPlayer = nil,
    SelectedPet = nil
}

-- Auto Gift Pet
spawn(function()
    while wait(2) do
        if getgenv().Settings.AutoGiftPet and getgenv().Settings.TargetPlayer and getgenv().Settings.SelectedPet then
            pcall(function()
                local target = Players:FindFirstChild(getgenv().Settings.TargetPlayer)
                if target then
                    for _, item in pairs(LocalPlayer.Backpack:GetChildren()) do
                        if item.Name == getgenv().Settings.SelectedPet then
                            local prompt = item:FindFirstChildWhichIsA("ProximityPrompt")
                            if prompt then
                                prompt:InputHoldBegin()
                                wait(0.4)
                                prompt:InputHoldEnd()
                                print("🎁 Gifted "..item.Name.." to "..target.Name)
                                wait(3)
                            end
                        end
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
MainFrame.Size = UDim2.new(0, 420, 0, 520)
MainFrame.Position = UDim2.new(0.5, -210, 0.5, -260)
MainFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
MainFrame.Parent = ScreenGui
Instance.new("UICorner", MainFrame).CornerRadius = UDim.new(0, 12)
MainFrame.Draggable = true

local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(1,0,0,45)
Title.BackgroundColor3 = Color3.fromRGB(30,30,30)
Title.Text = "RONI HUB - Auto Gift Pet"
Title.TextColor3 = Color3.fromRGB(255, 200, 0)
Title.TextSize = 20
Title.Font = Enum.Font.GothamBold
Title.Parent = MainFrame

-- Close
local closeBtn = Instance.new("TextButton")
closeBtn.Size = UDim2.new(0,60,0,30)
closeBtn.Position = UDim2.new(1,-70,0,8)
closeBtn.BackgroundColor3 = Color3.fromRGB(40,40,40)
closeBtn.Text = "CLOSE"
closeBtn.TextColor3 = Color3.fromRGB(255,255,100)
closeBtn.TextSize = 14
closeBtn.Parent = MainFrame
Instance.new("UICorner", closeBtn).CornerRadius = UDim.new(0,6)

closeBtn.MouseButton1Click:Connect(function() MainFrame.Visible = false end)

-- Pilih Pet (Daftar Manual)
local petList = {"Dog","Cat","Bunny","Chicken","Cow","Pig","Sheep","Horse","Lion","Tiger","Panda","Koala","Penguin","Fox","Wolf","Raccoon","Peacock","Ruby","Mimic","Venom Mimic","Golden Mimic","Shadow Mimic","Dragon","Phoenix","Unicorn","Griffin","Kitsune","T-Rex","Disco Bee","Octopus","Shark"}

local y = 60
for _, petName in ipairs(petList) do
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(0.9,0,0,35)
    btn.Position = UDim2.new(0.05,0,0,y/520)
    btn.BackgroundColor3 = Color3.fromRGB(35,35,35)
    btn.Text = petName
    btn.TextColor3 = Color3.fromRGB(255,220,100)
    btn.TextSize = 15
    btn.Parent = MainFrame
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0,8)

    btn.MouseButton1Click:Connect(function()
        getgenv().Settings.SelectedPet = petName
        print("Selected Pet: " .. petName)
        -- Optional: beri feedback
        btn.TextColor3 = Color3.fromRGB(0,255,150)
        wait(0.3)
        btn.TextColor3 = Color3.fromRGB(255,220,100)
    end)
    y = y + 40
end

-- Pilih Player
local playerBtn = Instance.new("TextButton")
playerBtn.Size = UDim2.new(0.9,0,0,40)
playerBtn.Position = UDim2.new(0.05,0,0,0.75)
playerBtn.BackgroundColor3 = Color3.fromRGB(35,35,35)
playerBtn.Text = "Pilih Player →"
playerBtn.TextColor3 = Color3.fromRGB(255,220,100)
playerBtn.TextSize = 16
playerBtn.Parent = MainFrame
Instance.new("UICorner", playerBtn).CornerRadius = UDim.new(0,8)

playerBtn.MouseButton1Click:Connect(function()
    local list = {}
    for _, plr in pairs(Players:GetPlayers()) do
        if plr ~= LocalPlayer then table.insert(list, plr.Name) end
    end
    if #list > 0 then
        playerBtn.Text = "Player: " .. list[1]
        getgenv().Settings.TargetPlayer = list[1]
    end
end)

-- Toggle Auto Gift
local giftToggle = Instance.new("TextButton")
giftToggle.Size = UDim2.new(0.9,0,0,50)
giftToggle.Position = UDim2.new(0.05,0,0,0.85)
giftToggle.BackgroundColor3 = Color3.fromRGB(35,35,35)
giftToggle.Text = "Auto Gift Pet : OFF"
giftToggle.TextColor3 = Color3.fromRGB(255,100,100)
giftToggle.TextSize = 17
giftToggle.Parent = MainFrame
Instance.new("UICorner", giftToggle).CornerRadius = UDim.new(0,8)

giftToggle.MouseButton1Click:Connect(function()
    getgenv().Settings.AutoGiftPet = not getgenv().Settings.AutoGiftPet
    giftToggle.Text = "Auto Gift Pet : " .. (getgenv().Settings.AutoGiftPet and "ON" or "OFF")
    giftToggle.TextColor3 = getgenv().Settings.AutoGiftPet and Color3.fromRGB(0,255,100) or Color3.fromRGB(255,100,100)
end)

print("✅ Pilih Pet sekarang berupa daftar manual (Peacock, Mimic, Ruby, dll)")
