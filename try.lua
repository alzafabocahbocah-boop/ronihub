-- ============================================================
-- ZENX AGE STATS v2.0
-- Tab [STATS] / [GIFT]
-- STATS: per-type pet count (age 100 vs <100)
-- GIFT : auto-gift pet age 100 ke target player (recent targets saved)
-- ============================================================

local Players    = game:GetService("Players")
local CoreGui    = game:GetService("CoreGui")
local RS         = game:GetService("ReplicatedStorage")
local HS         = game:GetService("HttpService")
local player     = Players.LocalPlayer
local playerGui  = player:WaitForChild("PlayerGui", 10)
local VER = "v2.0"
local TARGETS_FILE = "ZenxAgeStats_targets.json"
local MAX_RECENT = 8

-- ===== CLEANUP =====
local function cleanup()
    for _, p in ipairs({playerGui, CoreGui}) do
        for _, c in ipairs(p:GetChildren()) do
            if c.Name == "ZenxAgeStats" then pcall(function() c:Destroy() end) end
        end
    end
    pcall(function()
        if gethui then
            for _, c in ipairs(gethui():GetChildren()) do
                if c.Name == "ZenxAgeStats" then c:Destroy() end
            end
        end
    end)
end
cleanup()

-- ============================================================
-- MEMORY CONTAINER (getgc bypass)
-- ============================================================
local function findMemoryContainer()
    if not getgc then return nil, 0 end
    local best, bestCount = nil, 0
    pcall(function()
        for _, obj in pairs(getgc(true)) do
            if type(obj) == "table" then
                local uuidLike = 0
                for k in pairs(obj) do
                    if type(k) == "string" and #k >= 32 and k:find("-") then
                        uuidLike = uuidLike + 1
                        if uuidLike >= 5 then break end
                    end
                end
                if uuidLike >= 5 then
                    local sample = nil
                    for _, v in pairs(obj) do sample = v; break end
                    if type(sample) == "table" and rawget(sample, "PetData") then
                        local cnt = 0
                        for _ in pairs(obj) do cnt = cnt + 1 end
                        if cnt > bestCount then best = obj; bestCount = cnt end
                    end
                end
            end
        end
    end)
    return best, bestCount
end

local MUTATION_PREFIXES = {
    "Everchanted ","Rainbow ","Frozen ","Inverted ","Golden ","Diamond ",
    "Mythical ","Hexed ","Ascended ","Radiant ","Shocked ","Bloodlit ",
    "Twilight ","Voidtouched ","Foxfire ","Aurora ","Static ","Stormcloud ",
    "Frost ","Burnt ","Lethal ","Cooked ","Choc ",
}
local function stripMutation(s)
    if not s then return "" end
    for _, p in ipairs(MUTATION_PREFIXES) do
        if s:sub(1, #p) == p then return s:sub(#p + 1) end
    end
    return s
end

local function getPetLevel(container, uuid)
    if not container or not uuid then return 0 end
    local key = tostring(uuid)
    if key:sub(1,1) ~= "{" then key = "{"..key.."}" end
    local entry = container[key]
    if type(entry) == "table" and entry.PetData and entry.PetData.Level then
        return tonumber(entry.PetData.Level) or 0
    end
    return 0
end

local function collectStats(container)
    local byType, total, age100, lessAge = {}, 0, 0, 0
    local bp = player:FindFirstChild("Backpack")
    if not bp then return byType, total, age100, lessAge end
    for _, tool in ipairs(bp:GetChildren()) do
        if tool:IsA("Tool") then
            local uuid = tool:GetAttribute("PET_UUID")
            if uuid then
                local pType = stripMutation(tostring(tool:GetAttribute("f") or "?"))
                local level = getPetLevel(container, uuid)
                if not byType[pType] then byType[pType] = {age100=0, less100=0} end
                if level >= 100 then
                    byType[pType].age100 = byType[pType].age100 + 1
                    age100 = age100 + 1
                else
                    byType[pType].less100 = byType[pType].less100 + 1
                    lessAge = lessAge + 1
                end
                total = total + 1
            end
        end
    end
    return byType, total, age100, lessAge
end

-- ============================================================
-- RECENT TARGETS (persistence)
-- ============================================================
local function loadTargets()
    local ok, content = pcall(function()
        if isfile and readfile and isfile(TARGETS_FILE) then return readfile(TARGETS_FILE) end
        return nil
    end)
    if not ok or not content then return {} end
    local ok2, data = pcall(function() return HS:JSONDecode(content) end)
    if ok2 and type(data) == "table" then return data end
    return {}
end

local function saveTargets(list)
    pcall(function()
        if writefile then writefile(TARGETS_FILE, HS:JSONEncode(list)) end
    end)
end

local function addRecentTarget(name)
    if not name or name == "" then return end
    local list = loadTargets()
    -- remove duplicate
    for i = #list, 1, -1 do
        if (list[i] or ""):lower() == name:lower() then table.remove(list, i) end
    end
    -- prepend
    table.insert(list, 1, name)
    -- trim to MAX_RECENT
    while #list > MAX_RECENT do table.remove(list) end
    saveTargets(list)
end

local function removeRecentTarget(name)
    local list = loadTargets()
    for i = #list, 1, -1 do
        if (list[i] or ""):lower() == name:lower() then table.remove(list, i) end
    end
    saveTargets(list)
end

-- ============================================================
-- GIFT LOGIC (dari rainbow leveling)
-- ============================================================
local giftRE = nil
local PGS = nil  -- PetGiftingService module
pcall(function()
    local ge = RS:FindFirstChild("GameEvents")
    if ge then giftRE = ge:FindFirstChild("PetGiftingService") end
    if not giftRE then giftRE = RS:FindFirstChild("PetGiftingService", true) end
end)
pcall(function()
    local mods = RS:FindFirstChild("Modules") and RS.Modules:FindFirstChild("PetServices")
    local gm = mods and mods:FindFirstChild("PetGiftingInputService")
    if gm then
        local ok, mod = pcall(require, gm)
        if ok then PGS = mod end
    end
end)

local function findPlayerByName(name)
    if not name or name == "" then return nil end
    local low = name:lower()
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= player and (p.Name:lower() == low or p.DisplayName:lower() == low) then
            return p
        end
    end
    -- partial match
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= player and (p.Name:lower():find(low, 1, true) or p.DisplayName:lower():find(low, 1, true)) then
            return p
        end
    end
    return nil
end

local function giftPetToPlayer(targetPlayer, petTool)
    if not targetPlayer or not petTool then return false end
    local char = player.Character
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    if not hum then return false end

    -- Unequip current tools
    pcall(function() hum:UnequipTools() end)
    task.wait(0.1)
    -- Equip the pet
    pcall(function() hum:EquipTool(petTool) end)
    task.wait(0.25)

    -- Try module path first
    local sent = false
    if PGS and PGS.GivePet then
        pcall(function() PGS.GivePet(targetPlayer) end)
        task.wait(0.4)
        if not petTool.Parent or petTool.Parent == nil then sent = true end
    end
    -- Fallback: remote
    if not sent and giftRE then
        local uuid = petTool:GetAttribute("PET_UUID")
        local u = tostring(uuid)
        if u:sub(1,1) ~= "{" then u = "{"..u.."}" end
        pcall(function() giftRE:FireServer("GivePet", targetPlayer, u) end)
        task.wait(0.4)
        if not petTool.Parent or petTool.Parent == nil then sent = true end
        if not sent then
            pcall(function() giftRE:FireServer("GivePet", targetPlayer) end)
            task.wait(0.4)
            if not petTool.Parent or petTool.Parent == nil then sent = true end
        end
    end
    return sent
end

-- ============================================================
-- COLORS
-- ============================================================
local C = {
    BG     = Color3.fromRGB(18, 18, 18),
    Panel  = Color3.fromRGB(28, 28, 28),
    Card   = Color3.fromRGB(36, 36, 36),
    Accent = Color3.fromRGB(255, 200, 0),
    Text   = Color3.fromRGB(230, 230, 230),
    Dim    = Color3.fromRGB(140, 140, 140),
    Green  = Color3.fromRGB(100, 200, 120),
    Orange = Color3.fromRGB(255, 140, 60),
    Red    = Color3.fromRGB(220, 80, 80),
    Blue   = Color3.fromRGB(80, 130, 200),
}

-- ============================================================
-- ScreenGui
-- ============================================================
local sg = Instance.new("ScreenGui")
sg.Name = "ZenxAgeStats"
sg.ResetOnSpawn = false
sg.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
sg.DisplayOrder = 9999
local parented = false
pcall(function() if gethui then sg.Parent = gethui(); parented = true end end)
if not parented then sg.Parent = playerGui end

-- ============================================================
-- DIMENSIONS
-- ============================================================
local W = 340
local TITLE_H = 34
local HEADER_H = 54
local TAB_H = 30
local CONTENT_H = 280
local FOOTER_H = 22

local COLLAPSED_HEIGHT = TITLE_H + 8 + HEADER_H + 8  -- ~ 104 (just header)
local EXPANDED_HEIGHT  = COLLAPSED_HEIGHT + TAB_H + 6 + CONTENT_H + 4 + FOOTER_H

-- ============================================================
-- MAIN WINDOW
-- ============================================================
local main = Instance.new("Frame")
main.Size = UDim2.new(0, W, 0, EXPANDED_HEIGHT)
main.Position = UDim2.new(0, 10, 0.5, -EXPANDED_HEIGHT/2)
main.BackgroundColor3 = C.BG
main.BorderSizePixel = 0
main.Active = true
main.Draggable = true
main.Parent = sg
Instance.new("UICorner", main).CornerRadius = UDim.new(0, 10)
local mainStroke = Instance.new("UIStroke", main)
mainStroke.Color = C.Accent
mainStroke.Thickness = 1.5

-- ============================================================
-- TITLE BAR
-- ============================================================
local titleBar = Instance.new("Frame")
titleBar.Size = UDim2.new(1, 0, 0, TITLE_H)
titleBar.BackgroundColor3 = C.Panel
titleBar.BorderSizePixel = 0
titleBar.Parent = main
Instance.new("UICorner", titleBar).CornerRadius = UDim.new(0, 10)
local tbFix = Instance.new("Frame")
tbFix.Size = UDim2.new(1, 0, 0, 10)
tbFix.Position = UDim2.new(0, 0, 1, -10)
tbFix.BackgroundColor3 = C.Panel
tbFix.BorderSizePixel = 0
tbFix.Parent = titleBar

local titleLbl = Instance.new("TextLabel")
titleLbl.Size = UDim2.new(1, -98, 1, 0)
titleLbl.Position = UDim2.new(0, 12, 0, 0)
titleLbl.BackgroundTransparency = 1
titleLbl.Text = "⚡ ZENX AGE STATS "..VER
titleLbl.TextColor3 = C.Accent
titleLbl.Font = Enum.Font.GothamBold
titleLbl.TextSize = 13
titleLbl.TextXAlignment = Enum.TextXAlignment.Left
titleLbl.Parent = titleBar

local function mkTitleBtn(x, txt, color, txtColor)
    local b = Instance.new("TextButton")
    b.Size = UDim2.new(0, 26, 0, 22)
    b.Position = UDim2.new(1, x, 0.5, -11)
    b.BackgroundColor3 = color
    b.Text = txt b.TextColor3 = txtColor or Color3.new(1,1,1)
    b.Font = Enum.Font.GothamBold
    b.TextSize = 14
    b.BorderSizePixel = 0
    b.AutoButtonColor = false
    b.Parent = titleBar
    Instance.new("UICorner", b).CornerRadius = UDim.new(0, 4)
    return b
end

local expandBtn = mkTitleBtn(-92, "+", C.Accent, Color3.new(0,0,0))
local minBtn    = mkTitleBtn(-62, "—", C.Blue)
local closeBtn  = mkTitleBtn(-32, "✕", C.Red)
closeBtn.MouseButton1Click:Connect(function() sg:Destroy() end)

-- ============================================================
-- HEADER STATS
-- ============================================================
local header = Instance.new("Frame")
header.Size = UDim2.new(1, -16, 0, HEADER_H)
header.Position = UDim2.new(0, 8, 0, TITLE_H + 8)
header.BackgroundColor3 = C.Card
header.BorderSizePixel = 0
header.Parent = main
Instance.new("UICorner", header).CornerRadius = UDim.new(0, 6)

local function mkStat(parent, x, w, labelText, valColor)
    local cell = Instance.new("Frame")
    cell.Size = UDim2.new(w, 0, 1, 0)
    cell.Position = UDim2.new(x, 0, 0, 0)
    cell.BackgroundTransparency = 1
    cell.Parent = parent
    local t = Instance.new("TextLabel")
    t.Size = UDim2.new(1, 0, 0, 16)
    t.Position = UDim2.new(0, 0, 0, 6)
    t.BackgroundTransparency = 1
    t.Text = labelText t.TextColor3 = C.Dim
    t.Font = Enum.Font.Gotham t.TextSize = 10
    t.Parent = cell
    local v = Instance.new("TextLabel")
    v.Size = UDim2.new(1, 0, 0, 28)
    v.Position = UDim2.new(0, 0, 0, 22)
    v.BackgroundTransparency = 1
    v.Text = "0" v.TextColor3 = valColor or C.Text
    v.Font = Enum.Font.GothamBold v.TextSize = 18
    v.Parent = cell
    return v
end
local totalVal  = mkStat(header, 0,    0.33, "TOTAL",     C.Text)
local age100Val = mkStat(header, 0.33, 0.33, "AGE 100",   C.Green)
local lessVal   = mkStat(header, 0.66, 0.33, "AGE <100",  C.Orange)

-- ============================================================
-- TAB ROW [STATS] [GIFT]
-- ============================================================
local tabRow = Instance.new("Frame")
tabRow.Size = UDim2.new(1, -16, 0, TAB_H)
tabRow.Position = UDim2.new(0, 8, 0, TITLE_H + 8 + HEADER_H + 6)
tabRow.BackgroundTransparency = 1
tabRow.Parent = main

local function mkTabBtn(x, w, label)
    local b = Instance.new("TextButton")
    b.Size = UDim2.new(w, -3, 1, 0)
    b.Position = UDim2.new(x, x > 0 and 3 or 0, 0, 0)
    b.BackgroundColor3 = C.Card
    b.Text = label
    b.TextColor3 = C.Dim
    b.Font = Enum.Font.GothamBold
    b.TextSize = 12
    b.BorderSizePixel = 0
    b.AutoButtonColor = false
    b.Parent = tabRow
    Instance.new("UICorner", b).CornerRadius = UDim.new(0, 5)
    return b
end

local tabStatsBtn = mkTabBtn(0,    0.5, "📊 STATS")
local tabGiftBtn  = mkTabBtn(0.5,  0.5, "🎁 GIFT")

-- ============================================================
-- CONTENT AREAS (statsPanel / giftPanel)
-- ============================================================
local CONTENT_Y = TITLE_H + 8 + HEADER_H + 6 + TAB_H + 6

-- ===== STATS PANEL =====
local statsPanel = Instance.new("Frame")
statsPanel.Size = UDim2.new(1, -16, 0, CONTENT_H)
statsPanel.Position = UDim2.new(0, 8, 0, CONTENT_Y)
statsPanel.BackgroundTransparency = 1
statsPanel.Parent = main

local searchBox = Instance.new("TextBox")
searchBox.Size = UDim2.new(1, 0, 0, 28)
searchBox.BackgroundColor3 = C.Card
searchBox.Text = ""
searchBox.PlaceholderText = "🔍 Cari jenis pet..."
searchBox.PlaceholderColor3 = C.Dim
searchBox.TextColor3 = C.Text
searchBox.Font = Enum.Font.Gotham
searchBox.TextSize = 12
searchBox.TextXAlignment = Enum.TextXAlignment.Left
searchBox.ClearTextOnFocus = false
searchBox.BorderSizePixel = 0
searchBox.Parent = statsPanel
Instance.new("UICorner", searchBox).CornerRadius = UDim.new(0, 4)
local sPad = Instance.new("UIPadding", searchBox)
sPad.PaddingLeft = UDim.new(0, 10)

local colHeader = Instance.new("Frame")
colHeader.Size = UDim2.new(1, 0, 0, 22)
colHeader.Position = UDim2.new(0, 0, 0, 34)
colHeader.BackgroundColor3 = C.Panel
colHeader.BorderSizePixel = 0
colHeader.Parent = statsPanel
Instance.new("UICorner", colHeader).CornerRadius = UDim.new(0, 4)

local function mkColLbl(parent, x, w, text, color, align)
    local l = Instance.new("TextLabel")
    l.Size = UDim2.new(w, 0, 1, 0)
    l.Position = UDim2.new(x, 0, 0, 0)
    l.BackgroundTransparency = 1
    l.Text = text l.TextColor3 = color
    l.Font = Enum.Font.GothamBold l.TextSize = 10
    l.TextXAlignment = align or Enum.TextXAlignment.Center
    l.Parent = parent
    return l
end
mkColLbl(colHeader, 0.03, 0.47, "PET",     C.Accent, Enum.TextXAlignment.Left)
mkColLbl(colHeader, 0.50, 0.16, "AGE100",  C.Green)
mkColLbl(colHeader, 0.66, 0.14, "<100",    C.Orange)
mkColLbl(colHeader, 0.80, 0.17, "TOTAL",   C.Text)

local scroll = Instance.new("ScrollingFrame")
scroll.Size = UDim2.new(1, 0, 1, -60)
scroll.Position = UDim2.new(0, 0, 0, 60)
scroll.BackgroundColor3 = C.Card
scroll.BorderSizePixel = 0
scroll.ScrollBarThickness = 4
scroll.ScrollBarImageColor3 = C.Accent
scroll.CanvasSize = UDim2.new(0, 0, 0, 0)
scroll.Parent = statsPanel
Instance.new("UICorner", scroll).CornerRadius = UDim.new(0, 6)

local layout = Instance.new("UIListLayout")
layout.Padding = UDim.new(0, 2)
layout.Parent = scroll
local listPad = Instance.new("UIPadding", scroll)
listPad.PaddingTop = UDim.new(0, 4) listPad.PaddingBottom = UDim.new(0, 4)
listPad.PaddingLeft = UDim.new(0, 4) listPad.PaddingRight = UDim.new(0, 4)

-- ===== GIFT PANEL =====
local giftPanel = Instance.new("Frame")
giftPanel.Size = UDim2.new(1, -16, 0, CONTENT_H)
giftPanel.Position = UDim2.new(0, 8, 0, CONTENT_Y)
giftPanel.BackgroundTransparency = 1
giftPanel.Visible = false
giftPanel.Parent = main

-- Target input
local targetLbl = Instance.new("TextLabel")
targetLbl.Size = UDim2.new(1, 0, 0, 16)
targetLbl.Position = UDim2.new(0, 0, 0, 0)
targetLbl.BackgroundTransparency = 1
targetLbl.Text = "🎯 Target Player"
targetLbl.TextColor3 = C.Dim
targetLbl.Font = Enum.Font.GothamBold
targetLbl.TextSize = 10
targetLbl.TextXAlignment = Enum.TextXAlignment.Left
targetLbl.Parent = giftPanel

local targetBox = Instance.new("TextBox")
targetBox.Size = UDim2.new(1, 0, 0, 28)
targetBox.Position = UDim2.new(0, 0, 0, 18)
targetBox.BackgroundColor3 = C.Card
targetBox.Text = ""
targetBox.PlaceholderText = "Ketik nama player..."
targetBox.PlaceholderColor3 = C.Dim
targetBox.TextColor3 = C.Text
targetBox.Font = Enum.Font.Gotham
targetBox.TextSize = 12
targetBox.TextXAlignment = Enum.TextXAlignment.Left
targetBox.ClearTextOnFocus = false
targetBox.BorderSizePixel = 0
targetBox.Parent = giftPanel
Instance.new("UICorner", targetBox).CornerRadius = UDim.new(0, 4)
local tbPad = Instance.new("UIPadding", targetBox)
tbPad.PaddingLeft = UDim.new(0, 10)

-- Recent targets section
local recentLbl = Instance.new("TextLabel")
recentLbl.Size = UDim2.new(1, 0, 0, 14)
recentLbl.Position = UDim2.new(0, 0, 0, 52)
recentLbl.BackgroundTransparency = 1
recentLbl.Text = "Recent Targets (klik untuk pick)"
recentLbl.TextColor3 = C.Dim
recentLbl.Font = Enum.Font.Gotham
recentLbl.TextSize = 9
recentLbl.TextXAlignment = Enum.TextXAlignment.Left
recentLbl.Parent = giftPanel

local recentScroll = Instance.new("ScrollingFrame")
recentScroll.Size = UDim2.new(1, 0, 0, 60)
recentScroll.Position = UDim2.new(0, 0, 0, 68)
recentScroll.BackgroundColor3 = C.Card
recentScroll.BorderSizePixel = 0
recentScroll.ScrollBarThickness = 3
recentScroll.ScrollBarImageColor3 = C.Accent
recentScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
recentScroll.Parent = giftPanel
Instance.new("UICorner", recentScroll).CornerRadius = UDim.new(0, 4)
local recLayout = Instance.new("UIListLayout")
recLayout.Padding = UDim.new(0, 2) recLayout.Parent = recentScroll
local recPad = Instance.new("UIPadding", recentScroll)
recPad.PaddingTop = UDim.new(0, 3) recPad.PaddingLeft = UDim.new(0, 3) recPad.PaddingRight = UDim.new(0, 3)

-- Filter row
local filterLbl = Instance.new("TextLabel")
filterLbl.Size = UDim2.new(1, 0, 0, 14)
filterLbl.Position = UDim2.new(0, 0, 0, 136)
filterLbl.BackgroundTransparency = 1
filterLbl.Text = "🎂 Filter: Age 100 only"
filterLbl.TextColor3 = C.Green
filterLbl.Font = Enum.Font.GothamBold
filterLbl.TextSize = 10
filterLbl.TextXAlignment = Enum.TextXAlignment.Left
filterLbl.Parent = giftPanel

-- Eligible count
local eligibleLbl = Instance.new("TextLabel")
eligibleLbl.Size = UDim2.new(1, 0, 0, 16)
eligibleLbl.Position = UDim2.new(0, 0, 0, 152)
eligibleLbl.BackgroundTransparency = 1
eligibleLbl.Text = "Pet eligible (age 100): —"
eligibleLbl.TextColor3 = C.Text
eligibleLbl.Font = Enum.Font.Gotham
eligibleLbl.TextSize = 11
eligibleLbl.TextXAlignment = Enum.TextXAlignment.Left
eligibleLbl.Parent = giftPanel

-- Start button
local startBtn = Instance.new("TextButton")
startBtn.Size = UDim2.new(1, 0, 0, 34)
startBtn.Position = UDim2.new(0, 0, 0, 174)
startBtn.BackgroundColor3 = C.Green
startBtn.Text = "▶ START AUTO-GIFT"
startBtn.TextColor3 = Color3.new(0, 0, 0)
startBtn.Font = Enum.Font.GothamBold
startBtn.TextSize = 13
startBtn.BorderSizePixel = 0
startBtn.AutoButtonColor = false
startBtn.Parent = giftPanel
Instance.new("UICorner", startBtn).CornerRadius = UDim.new(0, 5)

-- Status
local statusLbl = Instance.new("TextLabel")
statusLbl.Size = UDim2.new(1, 0, 0, 18)
statusLbl.Position = UDim2.new(0, 0, 0, 214)
statusLbl.BackgroundTransparency = 1
statusLbl.Text = "Status: idle"
statusLbl.TextColor3 = C.Dim
statusLbl.Font = Enum.Font.Gotham
statusLbl.TextSize = 11
statusLbl.TextXAlignment = Enum.TextXAlignment.Left
statusLbl.Parent = giftPanel

-- Counter
local gCounterLbl = Instance.new("TextLabel")
gCounterLbl.Size = UDim2.new(1, 0, 0, 18)
gCounterLbl.Position = UDim2.new(0, 0, 0, 234)
gCounterLbl.BackgroundTransparency = 1
gCounterLbl.Text = "Sent: 0   Failed: 0"
gCounterLbl.TextColor3 = C.Accent
gCounterLbl.Font = Enum.Font.GothamBold
gCounterLbl.TextSize = 11
gCounterLbl.TextXAlignment = Enum.TextXAlignment.Left
gCounterLbl.Parent = giftPanel

-- ============================================================
-- FOOTER
-- ============================================================
local footer = Instance.new("TextLabel")
footer.Size = UDim2.new(1, -16, 0, 16)
footer.Position = UDim2.new(0, 8, 1, -FOOTER_H + 4)
footer.BackgroundTransparency = 1
footer.Text = "scope: backpack • auto 5s"
footer.TextColor3 = C.Dim
footer.Font = Enum.Font.Gotham
footer.TextSize = 10
footer.TextXAlignment = Enum.TextXAlignment.Left
footer.Parent = main

-- ============================================================
-- RENDER STATS
-- ============================================================
local cachedContainer, cachedCount = nil, 0

local function renderStats()
    for _, c in ipairs(scroll:GetChildren()) do
        if c:IsA("Frame") then c:Destroy() end
    end
    local byType, total, age100, lessAge = collectStats(cachedContainer)
    totalVal.Text  = tostring(total)
    age100Val.Text = tostring(age100)
    lessVal.Text   = tostring(lessAge)
    eligibleLbl.Text = "Pet eligible (age 100): "..age100
    footer.Text = "scope: backpack • memData "..(cachedContainer and (cachedCount.." ✅") or "FAIL ❌").." • auto 5s"

    local sorted = {}
    for k, v in pairs(byType) do table.insert(sorted, {name=k, data=v}) end
    table.sort(sorted, function(a, b)
        return (a.data.age100 + a.data.less100) > (b.data.age100 + b.data.less100)
    end)
    local filter = (searchBox.Text or ""):lower()
    for _, item in ipairs(sorted) do
        if filter == "" or item.name:lower():find(filter, 1, true) then
            local petTotal = item.data.age100 + item.data.less100
            local row = Instance.new("Frame")
            row.Size = UDim2.new(1, -8, 0, 26)
            row.BackgroundColor3 = C.Panel
            row.BorderSizePixel = 0 row.Parent = scroll
            Instance.new("UICorner", row).CornerRadius = UDim.new(0, 4)
            local n = Instance.new("TextLabel")
            n.Size = UDim2.new(0.47, -4, 1, 0) n.Position = UDim2.new(0.03, 0, 0, 0)
            n.BackgroundTransparency = 1 n.Text = item.name n.TextColor3 = C.Text
            n.Font = Enum.Font.Gotham n.TextSize = 11
            n.TextXAlignment = Enum.TextXAlignment.Left
            n.TextTruncate = Enum.TextTruncate.AtEnd n.Parent = row
            local c1 = Instance.new("TextLabel")
            c1.Size = UDim2.new(0.16, 0, 1, 0) c1.Position = UDim2.new(0.50, 0, 0, 0)
            c1.BackgroundTransparency = 1 c1.Text = tostring(item.data.age100)
            c1.TextColor3 = C.Green c1.Font = Enum.Font.GothamBold c1.TextSize = 12
            c1.Parent = row
            local c2 = Instance.new("TextLabel")
            c2.Size = UDim2.new(0.14, 0, 1, 0) c2.Position = UDim2.new(0.66, 0, 0, 0)
            c2.BackgroundTransparency = 1 c2.Text = tostring(item.data.less100)
            c2.TextColor3 = C.Orange c2.Font = Enum.Font.GothamBold c2.TextSize = 12
            c2.Parent = row
            local c3 = Instance.new("TextLabel")
            c3.Size = UDim2.new(0.17, 0, 1, 0) c3.Position = UDim2.new(0.80, 0, 0, 0)
            c3.BackgroundTransparency = 1 c3.Text = tostring(petTotal)
            c3.TextColor3 = C.Accent c3.Font = Enum.Font.GothamBold c3.TextSize = 12
            c3.Parent = row
        end
    end
    scroll.CanvasSize = UDim2.new(0, 0, 0, layout.AbsoluteContentSize.Y + 8)
end

-- ============================================================
-- RENDER RECENT TARGETS
-- ============================================================
local function renderRecent()
    for _, c in ipairs(recentScroll:GetChildren()) do
        if c:IsA("Frame") then c:Destroy() end
    end
    local list = loadTargets()
    for _, name in ipairs(list) do
        local row = Instance.new("Frame")
        row.Size = UDim2.new(1, -6, 0, 22)
        row.BackgroundColor3 = C.Panel
        row.BorderSizePixel = 0 row.Parent = recentScroll
        Instance.new("UICorner", row).CornerRadius = UDim.new(0, 3)

        local pickBtn = Instance.new("TextButton")
        pickBtn.Size = UDim2.new(1, -28, 1, 0)
        pickBtn.Position = UDim2.new(0, 0, 0, 0)
        pickBtn.BackgroundTransparency = 1
        pickBtn.Text = "  "..name
        pickBtn.TextColor3 = C.Text
        pickBtn.Font = Enum.Font.Gotham
        pickBtn.TextSize = 10
        pickBtn.TextXAlignment = Enum.TextXAlignment.Left
        pickBtn.AutoButtonColor = false
        pickBtn.Parent = row
        pickBtn.MouseButton1Click:Connect(function()
            targetBox.Text = name
        end)

        local delBtn = Instance.new("TextButton")
        delBtn.Size = UDim2.new(0, 22, 0, 18)
        delBtn.Position = UDim2.new(1, -25, 0.5, -9)
        delBtn.BackgroundColor3 = C.Red
        delBtn.Text = "✕" delBtn.TextColor3 = Color3.new(1,1,1)
        delBtn.Font = Enum.Font.GothamBold delBtn.TextSize = 9
        delBtn.BorderSizePixel = 0
        delBtn.AutoButtonColor = false
        delBtn.Parent = row
        Instance.new("UICorner", delBtn).CornerRadius = UDim.new(0, 3)
        delBtn.MouseButton1Click:Connect(function()
            removeRecentTarget(name)
            renderRecent()
        end)
    end
    recentScroll.CanvasSize = UDim2.new(0, 0, 0, recLayout.AbsoluteContentSize.Y + 6)
end

-- ============================================================
-- GIFT LOOP
-- ============================================================
local giftActive = false
local giftStopReq = false
local sentCount, failCount = 0, 0

local function setRunning(v)
    if v then
        startBtn.Text = "⛔ STOP"
        startBtn.BackgroundColor3 = C.Red
        startBtn.TextColor3 = Color3.new(1, 1, 1)
    else
        startBtn.Text = "▶ START AUTO-GIFT"
        startBtn.BackgroundColor3 = C.Green
        startBtn.TextColor3 = Color3.new(0, 0, 0)
    end
end

startBtn.MouseButton1Click:Connect(function()
    if giftActive then
        giftStopReq = true
        statusLbl.Text = "Status: stopping..."
        statusLbl.TextColor3 = C.Orange
        return
    end
    local targetName = (targetBox.Text or ""):gsub("^%s+",""):gsub("%s+$","")
    if targetName == "" then
        statusLbl.Text = "❌ Target player kosong"
        statusLbl.TextColor3 = C.Red
        return
    end
    local target = findPlayerByName(targetName)
    if not target then
        statusLbl.Text = "❌ Player '"..targetName.."' gak ada di server"
        statusLbl.TextColor3 = C.Red
        return
    end
    if not giftRE and not PGS then
        statusLbl.Text = "❌ Gift remote/module gak ditemukan"
        statusLbl.TextColor3 = C.Red
        return
    end

    addRecentTarget(target.Name)
    renderRecent()

    giftActive = true
    giftStopReq = false
    sentCount, failCount = 0, 0
    gCounterLbl.Text = "Sent: 0   Failed: 0"
    setRunning(true)
    statusLbl.Text = "Status: starting → "..target.Name
    statusLbl.TextColor3 = C.Accent

    task.spawn(function()
        while not giftStopReq do
            local bp = player:FindFirstChild("Backpack")
            if not bp then break end
            -- Find next eligible pet (age 100)
            local petTool = nil
            for _, t in ipairs(bp:GetChildren()) do
                if t:IsA("Tool") and t:GetAttribute("PET_UUID") then
                    local lvl = getPetLevel(cachedContainer, t:GetAttribute("PET_UUID"))
                    if lvl >= 100 then petTool = t; break end
                end
            end
            if not petTool then
                statusLbl.Text = "✅ Selesai, gak ada pet age 100 lagi"
                statusLbl.TextColor3 = C.Green
                break
            end
            local petName = petTool.Name
            statusLbl.Text = "🎁 Sending "..petName:sub(1,30).."..."
            statusLbl.TextColor3 = C.Blue
            local ok = giftPetToPlayer(target, petTool)
            if ok then
                sentCount = sentCount + 1
            else
                failCount = failCount + 1
            end
            gCounterLbl.Text = "Sent: "..sentCount.."   Failed: "..failCount
            task.wait(1.5)  -- rate limit
            -- Check target still in server
            if not target.Parent then
                statusLbl.Text = "❌ Target left server"
                statusLbl.TextColor3 = C.Red
                break
            end
        end
        giftActive = false
        setRunning(false)
        if giftStopReq then
            statusLbl.Text = "⛔ Stopped (Sent: "..sentCount..")"
            statusLbl.TextColor3 = C.Dim
        end
    end)
end)

-- ============================================================
-- TAB SWITCH
-- ============================================================
local activeTab = "stats"
local function setTab(tab)
    activeTab = tab
    if tab == "stats" then
        tabStatsBtn.BackgroundColor3 = C.Accent
        tabStatsBtn.TextColor3 = Color3.new(0, 0, 0)
        tabGiftBtn.BackgroundColor3 = C.Card
        tabGiftBtn.TextColor3 = C.Dim
        statsPanel.Visible = true
        giftPanel.Visible = false
    else
        tabGiftBtn.BackgroundColor3 = C.Accent
        tabGiftBtn.TextColor3 = Color3.new(0, 0, 0)
        tabStatsBtn.BackgroundColor3 = C.Card
        tabStatsBtn.TextColor3 = C.Dim
        statsPanel.Visible = false
        giftPanel.Visible = true
        renderRecent()
    end
end
tabStatsBtn.MouseButton1Click:Connect(function() setTab("stats") end)
tabGiftBtn.MouseButton1Click:Connect(function() setTab("gift") end)
setTab("stats")

-- ============================================================
-- TOGGLE EXPAND
-- ============================================================
local expanded = false
local function setExpanded(v)
    expanded = v
    tabRow.Visible = v
    statsPanel.Visible = v and (activeTab == "stats")
    giftPanel.Visible = v and (activeTab == "gift")
    footer.Visible = v
    if v then
        main.Size = UDim2.new(0, W, 0, EXPANDED_HEIGHT)
        expandBtn.Text = "—"
    else
        main.Size = UDim2.new(0, W, 0, COLLAPSED_HEIGHT)
        expandBtn.Text = "+"
    end
end
setExpanded(false)
expandBtn.MouseButton1Click:Connect(function() setExpanded(not expanded) end)

-- ============================================================
-- MINIMIZE — floating logo
-- ============================================================
local zLogo = Instance.new("TextButton")
zLogo.Size = UDim2.new(0, 42, 0, 42)
zLogo.Position = UDim2.new(0, 10, 0.5, -21)
zLogo.BackgroundColor3 = C.Accent
zLogo.Text = "⚡" zLogo.TextColor3 = Color3.new(0,0,0)
zLogo.Font = Enum.Font.GothamBold zLogo.TextSize = 22
zLogo.BorderSizePixel = 0
zLogo.AutoButtonColor = false
zLogo.Active = true
zLogo.Draggable = true
zLogo.Visible = false
zLogo.Parent = sg
Instance.new("UICorner", zLogo).CornerRadius = UDim.new(1, 0)
local zStroke = Instance.new("UIStroke", zLogo)
zStroke.Color = Color3.new(0,0,0) zStroke.Thickness = 1.5

minBtn.MouseButton1Click:Connect(function()
    main.Visible = false
    zLogo.Visible = true
end)
zLogo.MouseButton1Click:Connect(function()
    main.Visible = true
    zLogo.Visible = false
end)

-- ============================================================
-- INIT + AUTO-REFRESH
-- ============================================================
cachedContainer, cachedCount = findMemoryContainer()
print("[ZenxAgeStats] memContainer: "..(cachedContainer and cachedCount.." entries" or "FAIL"))
print("[ZenxAgeStats] giftRE="..(giftRE and "OK" or "FAIL").." PGS="..(PGS and "OK" or "FAIL"))

renderStats()
renderRecent()

searchBox:GetPropertyChangedSignal("Text"):Connect(function()
    if activeTab == "stats" then renderStats() end
end)

task.spawn(function()
    while sg.Parent do
        task.wait(5)
        if not sg.Parent then break end
        local nc, ncnt = findMemoryContainer()
        if nc and ncnt > 0 then cachedContainer = nc; cachedCount = ncnt end
        if activeTab == "stats" then renderStats() end
    end
end)

print("[ZenxAgeStats] "..VER.." loaded")
