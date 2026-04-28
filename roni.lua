-- RONI HUB - Grow a Garden
print("🔥 RONI HUB Loaded Successfully!")

local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

print("✅ Key System Passed")

getgenv().RoniHub = {
    WalkSpeed = 90,
    JumpPower = 60
}

-- WalkSpeed
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

print("🌱 RONI HUB Berjalan")
print("WalkSpeed = 90 | JumpPower = 60")
