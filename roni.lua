-- =============================================
-- RONI HUB - Grow a Garden Script
-- Username: alzafabocahbocah-boop
-- =============================================

print("🔥 RONI HUB Loaded from GitHub")

local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

-- ================== KEY SYSTEM ==================
local AllowedKeys = {
    "resti gendut",
    "RestiGendut",
    "restigendut",
    "RoniHub2026"
}

print("✅ RONI HUB - Grow a Garden")

getgenv().RoniHub = {
    AutoPlant = true,
    AutoHarvest = true,
    AutoAcceptGift = true,
    WalkSpeed = 90,
    JumpPower = 60
}

-- WalkSpeed & JumpPower
spawn(function()
    while wait(1) do
        pcall(function()
            local hum = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid")
            if hum then
                hum.WalkSpeed = getgenv().RoniHub.WalkSpeed
                hum.JumpPower = getgenv().RoniHub.JumpPower
            end
        end)
    end
end)

print("🌱 RONI HUB Berjalan - WalkSpeed & JumpPower aktif")
print("Siap ditambahkan fitur Auto Gift, Auto Plant, dll")
