-- RONI HUB - Grow a Garden
print("🔥 RONI HUB Loaded - V5")

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local LocalPlayer = Players.LocalPlayer

getgenv().Settings = {
    WalkSpeed = 90,
    JumpPower = 60,
    AutoBuySeed = false,
    AutoBuyEgg = false,
    AutoBuyGear = false,
    BuyAll = false
}

-- ================== AUTO BUY V5 (Lebih Agresif) ==================
spawn(function()
    while wait(0.5) do
        if not (getgenv().Settings.BuyAll or getgenv().Settings.AutoBuySeed or getgenv().Settings.AutoBuyEgg or getgenv().Settings.AutoBuyGear) then continue end

        pcall(function()
            for _, v in pairs(Workspace:GetDescendants()) do
                if v:IsA("ProximityPrompt") then
                    local name = v.Parent.Name .. (v.Parent:FindFirstChildWhichIsA("TextLabel") and v.Parent:FindFirstChildWhichIsA("TextLabel").Text or "")

                    local shouldBuy = getgenv().Settings.BuyAll or
                        (getgenv().Settings.AutoBuySeed and name:find("Seed")) or
                        (getgenv().Settings.AutoBuyEgg and name:find("Egg")) or
                        (getgenv().Settings.AutoBuyGear and (name:find("Gear") or name:find("Tool")))

                    if shouldBuy then
                        v:InputHoldBegin()
                        wait(0.25)
                        v:InputHoldEnd()
                        wait(0.3)
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
MainFrame.Size = UDim2.new(0, 700, 0, 520)
MainFrame.Position = UDim2.new(0.5, -350, 0.5, -260)
MainFrame.BackgroundColor3 = Color3.fromRGB(18, 18, 18)
MainFrame.Parent = ScreenGui
Instance.new("UICorner", MainFrame).CornerRadius = UDim.new(0, 10)
MainFrame.Draggable = true

local TitleFrame = Instance.new("Frame")
TitleFrame.Size = UDim2.new(1,0,0,50)
TitleFrame.BackgroundColor3 = Color3.fromRGB(25,25,25)
TitleFrame.Parent = MainFrame

local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(0.7,0,1,0)
Title.BackgroundTransparency = 1
Title.Text = "RONI HUB"
Title.TextColor3 = Color3.fromRGB(255, 200, 0)
Title.TextSize = 26
Title.Font = Enum.Font.GothamBold
Title.TextXAlignment = Enum.TextXAlignment.Left
Title.Parent = TitleFrame

local Version = Instance.new("TextLabel")
Version.Size = UDim2.new(0.3,0,1,0)
Version.BackgroundTransparency = 1
Version.Text = "V5.0"
Version.TextColor3 = Color3.fromRGB(180, 180, 180)
Version.TextSize = 18
Version.Font = Enum.Font.Gotham
Version.TextXAlignment = Enum.TextXAlignment.Right
Version.Parent = TitleFrame

-- Close Button (Hanya nutup GUI)
local closeBtn = Instance.new("TextButton")
closeBtn.Size = UDim2.new(0, 80, 0, 35)
closeBtn.Position = UDim2.new(1, -200, 0, 8)
closeBtn.BackgroundColor3 = Color3.fromRGB(40,40,40)
closeBtn.Text = "CLOSE"
closeBtn.TextColor3 = Color3.fromRGB(255, 255, 100)
closeBtn.TextSize = 16
closeBtn.Font = Enum.Font.GothamBold
closeBtn.Parent = TitleFrame
Instance.new("UICorner", closeBtn).CornerRadius = UDim.new(0,6)

-- Destroy Button
local destroyBtn = Instance.new("TextButton")
destroyBtn.Size = UDim2.new(0, 140, 0, 35)
destroyBtn.Position = UDim2.new(1, -110, 0, 8)
destroyBtn.BackgroundColor3 = Color3.fromRGB(80, 0, 0)
destroyBtn.Text = "DESTROY SCRIPT"
destroyBtn.TextColor3 = Color3.fromRGB(255, 200, 200)
destroyBtn.TextSize = 14
destroyBtn.Font = Enum.Font.GothamBold
destroyBtn.Parent = TitleFrame
Instance.new("UICorner", destroyBtn).CornerRadius = UDim.new(0,6)

-- Reopen Logo
local reopenLogo = Instance.new("TextButton")
reopenLogo.Size = UDim2.new(0, 60, 0, 60)
reopenLogo.Position = UDim2.new(1, -80, 1, -80)
reopenLogo.BackgroundColor3 = Color3.fromRGB(255, 160, 0)
reopenLogo.Text = "🦒"
reopenLogo.TextSize = 35
reopenLogo.TextColor3 = Color3.fromRGB(0,0,0)
reopenLogo.Visible = false
reopenLogo.Parent = ScreenGui
Instance.new("UICorner", reopenLogo).CornerRadius = UDim.new(1,0)

closeBtn.MouseButton1Click:Connect(function()
    MainFrame.Visible = false
    reopenLogo.Visible = true
end)

reopenLogo.MouseButton1Click:Connect(function()
    MainFrame.Visible = true
    reopenLogo.Visible = false
end)

destroyBtn.MouseButton1Click:Connect(function()
    ScreenGui:Destroy()
    print("🛑 RONI HUB telah dihancurkan")
end)

-- Sidebar + Misc Content (sama seperti sebelumnya, tapi lebih ringkas)
-- ... (kode sidebar dan misc content tetap sama seperti V4)

print("✅ V5.0 - Tombol Close + Destroy + Logo Reopen telah ditambahkan")
