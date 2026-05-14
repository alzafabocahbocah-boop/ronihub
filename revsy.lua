local plr = game.Players.LocalPlayer
local rs = game:GetService("ReplicatedStorage")
local out = {}
local function log(s) table.insert(out, tostring(s)) end

-- ===== 1. SEED DATA =====
log("===== SeedData CATALOG =====")
local ok, sd = pcall(require, rs.Data.SeedData)
if ok and type(sd) == "table" then
    local cnt = 0
    for k, v in pairs(sd) do
        cnt = cnt + 1
        if cnt <= 20 then
            log("  " .. tostring(k) .. " = " .. type(v))
            if type(v) == "table" then
                local sub = 0
                for k2, v2 in pairs(v) do
                    sub = sub + 1
                    if sub <= 5 then
                        log("    ." .. tostring(k2) .. " = " .. tostring(v2):sub(1,40))
                    end
                end
                if sub > 5 then log("    ... ("..sub.." fields)") end
            end
        end
    end
    log("TOTAL SEEDS: " .. cnt)
end

-- ===== 2. GEAR DATA =====
log("\n===== GearData CATALOG =====")
local ok2, gd = pcall(require, rs.Data.GearData)
if ok2 and type(gd) == "table" then
    local cnt = 0
    for k, v in pairs(gd) do
        cnt = cnt + 1
        if cnt <= 20 then
            log("  " .. tostring(k) .. " = " .. type(v))
            if type(v) == "table" then
                local sub = 0
                for k2, v2 in pairs(v) do
                    sub = sub + 1
                    if sub <= 5 then
                        log("    ." .. tostring(k2) .. " = " .. tostring(v2):sub(1,40))
                    end
                end
                if sub > 5 then log("    ... ("..sub.." fields)") end
            end
        end
    end
    log("TOTAL GEARS: " .. cnt)
end

-- ===== 3. ITEM TYPE ENUMS (category code → name) =====
log("\n===== ItemTypeEnums =====")
local ok3, ite = pcall(require, rs.Data.EnumRegistry.ItemTypeEnums)
if ok3 and type(ite) == "table" then
    for k, v in pairs(ite) do log("  " .. tostring(k) .. " = " .. tostring(v)) end
end

log("\n===== ReversedItemTypeEnums (code → name) =====")
local ok4, rite = pcall(require, rs.Data.EnumRegistry.ReversedItemTypeEnums)
if ok4 and type(rite) == "table" then
    for k, v in pairs(rite) do log("  " .. tostring(k) .. " = " .. tostring(v)) end
end

-- ===== 4. FAVORITE PETS (LIVE DATA) =====
log("\n===== ⭐ FAVORITE PETS =====")
local APS = require(rs.Modules.PetServices.ActivePetsService)
local PetMutReg = require(rs.Data.PetRegistry.PetMutationRegistry)
local mutMap = PetMutReg.EnumToPetMutation

local favs = {}
local ds_ok, ds = pcall(function() return APS:GetPlayerDatastorePetData(plr.Name) end)
if ds_ok and ds and ds.PetInventory and ds.PetInventory.Data then
    for uuid, info in pairs(ds.PetInventory.Data) do
        if info.PetData and info.PetData.IsFavorite then
            table.insert(favs, {
                uuid = uuid,
                petType = info.PetType,
                petName = info.PetData.Name,
                level = info.PetData.Level,
                mutation = info.PetData.MutationType and (mutMap[info.PetData.MutationType] or info.PetData.MutationType) or "none",
                weight = info.PetData.BaseWeight,
            })
        end
    end
end

log("Total favorited: " .. #favs)
for _, f in ipairs(favs) do
    log(string.format("  ⭐ [%s] %s '%s' | Lv:%s | BaseW:%.2f",
        f.mutation, f.petType, f.petName or "?", tostring(f.level), f.weight or 0))
end

local result = table.concat(out, "\n")
print(result)
if setclipboard then pcall(setclipboard, result) end

-- DISPLAY UI
pcall(function() plr.PlayerGui.OutputView:Destroy() end)
local sg = Instance.new("ScreenGui"); sg.Name = "OutputView"
sg.IgnoreGuiInset = true; sg.ResetOnSpawn = false; sg.Parent = plr.PlayerGui
local f = Instance.new("Frame", sg)
f.Size = UDim2.new(0.95, 0, 0.85, 0); f.Position = UDim2.new(0.025, 0, 0.05, 0)
f.BackgroundColor3 = Color3.fromRGB(20,20,25)
local b = Instance.new("TextBox", f)
b.Size = UDim2.new(1,-10,1,-60); b.Position = UDim2.new(0,5,0,5)
b.MultiLine=true; b.TextEditable=false; b.ClearTextOnFocus=false
b.TextWrapped=true; b.Text=result; b.TextSize=13; b.Font=Enum.Font.Code
b.TextXAlignment=Enum.TextXAlignment.Left; b.TextYAlignment=Enum.TextYAlignment.Top
b.BackgroundColor3=Color3.fromRGB(10,10,15); b.TextColor3=Color3.fromRGB(220,220,220)
local cb = Instance.new("TextButton", f)
cb.Size = UDim2.new(0,150,0,45); cb.Position = UDim2.new(0.3,-75,1,-52)
cb.Text="📋 COPY"; cb.BackgroundColor3=Color3.fromRGB(50,150,80)
cb.TextColor3=Color3.new(1,1,1); cb.Font=Enum.Font.GothamBold; cb.TextSize=16
cb.MouseButton1Click:Connect(function()
    local ok = pcall(setclipboard, result)
    cb.Text = ok and "✅ COPIED!" or "❌ FAILED"
    cb.BackgroundColor3 = ok and Color3.fromRGB(30,120,50) or Color3.fromRGB(180,50,50)
    task.wait(2); cb.Text="📋 COPY"; cb.BackgroundColor3=Color3.fromRGB(50,150,80)
end)
local cls = Instance.new("TextButton", f)
cls.Size=UDim2.new(0,100,0,45); cls.Position=UDim2.new(0.7,-50,1,-52)
cls.Text="CLOSE"; cls.BackgroundColor3=Color3.fromRGB(180,50,50)
cls.TextColor3=Color3.new(1,1,1); cls.Font=Enum.Font.GothamBold; cls.TextSize=16
cls.MouseButton1Click:Connect(function() sg:Destroy() end)
