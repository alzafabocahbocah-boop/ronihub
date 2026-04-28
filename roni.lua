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
    TargetPlayer = nil,
    SelectedPet = nil,
    GiftKG = 100,
    GiftAge = 10
}

-- ================== AUTO GIFT PET ==================
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
                                print("Gifted "..pet.Name.." → "..target.Name)
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
MainFrame.Size = UDim2.new(0, 360, 0, 620)
MainFrame.Position = UDim2.new(0, 30, 0.15, 0)
MainFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
MainFrame.Parent = ScreenGui
Instance.new("UICorner", MainFrame).CornerRadius = UDim.new(0, 12)
MainFrame.Draggable = true
MainFrame.Active = true

local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(1,0,0,45)
Title.BackgroundTransparency = 1
Title.Text = "Garden Helper"
Title.TextColor3 = Color3.fromRGB(255, 200, 0)
Title.TextSize = 22
Title.Font = Enum.Font.GothamSemibold
Title.Parent = MainFrame

-- Close
local closeBtn = Instance.new("TextButton")
closeBtn.Size = UDim2.new(0,35,0,35)
closeBtn.Position = UDim2.new(1,-40,0,8)
closeBtn.Text = "✕"
closeBtn.TextColor3 = Color3.fromRGB(255,100,100)
closeBtn.BackgroundTransparency = 1
closeBtn.TextSize = 22
closeBtn.Parent = MainFrame
closeBtn.MouseButton1Click:Connect(function() ScreenGui:Destroy() end)

-- ================== PLAYER SELECTION (Baru & Lebih Baik) ==================
local selectedLabel = Instance.new("TextLabel")
selectedLabel.Size = UDim2.new(0.65,0,0,40)
selectedLabel.Position = UDim2.new(0.05,0,0.13,0)
selectedLabel.BackgroundColor3 = Color3.fromRGB(30,30,30)
selectedLabel.Text = "Belum pilih player"
selectedLabel.TextColor3 = Color3.fromRGB(200,200,200)
selectedLabel.TextSize = 15
selectedLabel.Font = Enum.Font.Gotham
selectedLabel.Parent = MainFrame
Instance.new("UICorner", selectedLabel).CornerRadius = UDim.new(0,8)

-- Tombol Pilih Player
local selectPlayerBtn = Instance.new("TextButton")
selectPlayerBtn.Size = UDim2.new(0.25,0,0,40)
selectPlayerBtn.Position = UDim2.new(0.72,0,0.13,0)
selectPlayerBtn.BackgroundColor3 = Color3.fromRGB(35,35,35)
selectPlayerBtn.Text = "Pilih"
selectPlayerBtn.TextColor3 = Color3.fromRGB(255,220,100)
selectPlayerBtn.TextSize = 16
selectPlayerBtn.Parent = MainFrame
Instance.new("UICorner", selectPlayerBtn).CornerRadius = UDim.new(0,8)

selectPlayerBtn.MouseButton1Click:Connect(function()
    local players = {}
    for _, plr in pairs(Players:GetPlayers()) do
        if plr ~= LocalPlayer then
            table.insert(players, plr.Name)
        end
    end
    if #players > 0 then
        selectedLabel.Text = players[1]
        getgenv().Settings.TargetPlayer = players[1]
    else
        selectedLabel.Text = "Tidak ada player lain"
    end
end)

-- Tombol Batal (Clear)
local cancelBtn = Instance.new("TextButton")
cancelBtn.Size = UDim2.new(0.25,0,0,40)
cancelBtn.Position = UDim2.new(0.72,0,0.22,0)
cancelBtn.BackgroundColor3 = Color3.fromRGB(80,30,30)
cancelBtn.Text = "Batal"
cancelBtn.TextColor3 = Color3.fromRGB(255,150,150)
cancelBtn.TextSize = 16
cancelBtn.Parent = MainFrame
Instance.new("UICorner", cancelBtn).CornerRadius = UDim.new(0,8)

cancelBtn.MouseButton1Click:Connect(function()
    selectedLabel.Text = "Belum pilih player"
    getgenv().Settings.TargetPlayer = nil
end)

-- ================== Pet Selection ==================
local petBtn = Instance.new("TextButton")
petBtn.Size = UDim2.new(0.9,0,0,40)
petBtn.Position = UDim2.new(0.05,0,0.32,0)
petBtn.BackgroundColor3 = Color3.fromRGB(35,35,35)
petBtn.Text = "Pilih Pet →"
petBtn.TextColor3 = Color3.fromRGB(255,220,100)
petBtn.TextSize = 16
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
        petBtn.Text = "Tidak ada Pet di Backpack"
    end
end)

--
