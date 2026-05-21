-- ============================================================
-- ZENX AGE STATS v1.3
-- Statistik pet per type: Age 100 vs <100, Total
-- Data via getgc memory container (sama market v8.124+)
-- Auto-refresh 5 detik
-- Layout minimalis: search + button, table di bawah pas tombol + ditekan
-- ============================================================

local Players    = game:GetService("Players")
local CoreGui    = game:GetService("CoreGui")
local player     = Players.LocalPlayer
local playerGui  = player:WaitForChild("PlayerGui", 10)
local VER = "v1.5"

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

-- Strip mutation prefix
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

local function collectStats(container)
    local byType, total, age100, lessAge = {}, 0, 0, 0
    if not container then return byType, total, age100, lessAge end
    for _, entry in pairs(container) do
        if type(entry) == "table" and entry.PetData then
            local pType = stripMutation(tostring(entry.PetType or "?"))
            local level = tonumber(entry.PetData.Level) or 0
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
    return byType, total, age100, lessAge
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
-- ScreenGui — HIGH DisplayOrder biar gak tenggelam
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
local SEARCH_H = 32
local TABLE_H = 230  -- collapsible
local FOOTER_H = 22
local PAD = 8

local COLLAPSED_HEIGHT = TITLE_H + 8 + HEADER_H + 6 + SEARCH_H + PAD  -- ~ 132
local EXPANDED_HEIGHT  = COLLAPSED_HEIGHT + 4 + TABLE_H + 4 + FOOTER_H

-- ============================================================
-- MAIN WINDOW
-- ============================================================
local main = Instance.new("Frame")
main.Size = UDim2.new(0, W, 0, EXPANDED_HEIGHT)
-- v1.4: spawn di kiri-tengah biar gak nutupin tampilan tengah
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
-- TITLE BAR  ([—] [×])
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
titleLbl.Size = UDim2.new(1, -68, 1, 0)
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

local minBtn   = mkTitleBtn(-62, "—", C.Blue)
local closeBtn = mkTitleBtn(-32, "✕", C.Red)
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
-- SEARCH ROW (search box + plus toggle button)
-- ============================================================
local searchRow = Instance.new("Frame")
searchRow.Size = UDim2.new(1, -16, 0, SEARCH_H - 4)
searchRow.Position = UDim2.new(0, 8, 0, TITLE_H + 8 + HEADER_H + 6)
searchRow.BackgroundTransparency = 1
searchRow.Parent = main

local searchBox = Instance.new("TextBox")
searchBox.Size = UDim2.new(1, -36, 1, 0)
searchBox.Position = UDim2.new(0, 0, 0, 0)
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
searchBox.Parent = searchRow
Instance.new("UICorner", searchBox).CornerRadius = UDim.new(0, 4)
local sPad = Instance.new("UIPadding", searchBox)
sPad.PaddingLeft = UDim.new(0, 10)

local plusBtn = Instance.new("TextButton")
plusBtn.Size = UDim2.new(0, 30, 1, 0)
plusBtn.Position = UDim2.new(1, -30, 0, 0)
plusBtn.BackgroundColor3 = C.Accent
plusBtn.Text = "+"
plusBtn.TextColor3 = Color3.new(0, 0, 0)
plusBtn.Font = Enum.Font.GothamBold
plusBtn.TextSize = 18
plusBtn.BorderSizePixel = 0
plusBtn.AutoButtonColor = false
plusBtn.Parent = searchRow
Instance.new("UICorner", plusBtn).CornerRadius = UDim.new(0, 4)

-- ============================================================
-- TABLE SECTION (collapsible — hidden by default)
-- ============================================================
local tableSection = Instance.new("Frame")
tableSection.Size = UDim2.new(1, -16, 0, TABLE_H)
tableSection.Position = UDim2.new(0, 8, 0, TITLE_H + 8 + HEADER_H + 6 + SEARCH_H + 4)
tableSection.BackgroundTransparency = 1
tableSection.Visible = false  -- HIDDEN BY DEFAULT
tableSection.Parent = main

-- Column header
local colHeader = Instance.new("Frame")
colHeader.Size = UDim2.new(1, 0, 0, 22)
colHeader.Position = UDim2.new(0, 0, 0, 0)
colHeader.BackgroundColor3 = C.Panel
colHeader.BorderSizePixel = 0
colHeader.Parent = tableSection
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

-- Scroll body
local scroll = Instance.new("ScrollingFrame")
scroll.Size = UDim2.new(1, 0, 1, -26)
scroll.Position = UDim2.new(0, 0, 0, 26)
scroll.BackgroundColor3 = C.Card
scroll.BorderSizePixel = 0
scroll.ScrollBarThickness = 4
scroll.ScrollBarImageColor3 = C.Accent
scroll.CanvasSize = UDim2.new(0, 0, 0, 0)
scroll.Parent = tableSection
Instance.new("UICorner", scroll).CornerRadius = UDim.new(0, 6)

local layout = Instance.new("UIListLayout")
layout.Padding = UDim.new(0, 2)
layout.Parent = scroll
local listPad = Instance.new("UIPadding", scroll)
listPad.PaddingTop = UDim.new(0, 4) listPad.PaddingBottom = UDim.new(0, 4)
listPad.PaddingLeft = UDim.new(0, 4) listPad.PaddingRight = UDim.new(0, 4)

-- ============================================================
-- FOOTER (collapsible too)
-- ============================================================
local footer = Instance.new("TextLabel")
footer.Size = UDim2.new(1, -16, 0, 16)
footer.Position = UDim2.new(0, 8, 1, -FOOTER_H + 4)
footer.BackgroundTransparency = 1
footer.Text = "memContainer: scanning..."
footer.TextColor3 = C.Dim
footer.Font = Enum.Font.Gotham
footer.TextSize = 10
footer.TextXAlignment = Enum.TextXAlignment.Left
footer.Visible = false  -- HIDDEN BY DEFAULT (sama dgn table)
footer.Parent = main

-- ============================================================
-- RENDER
-- ============================================================
local function render(container, filter, count)
    for _, c in ipairs(scroll:GetChildren()) do
        if c:IsA("Frame") then c:Destroy() end
    end

    local byType, total, age100, lessAge = collectStats(container)
    totalVal.Text  = tostring(total)
    age100Val.Text = tostring(age100)
    lessVal.Text   = tostring(lessAge)
    footer.Text = "memContainer: "..(container and (count.." entries ✅") or "FAIL ❌").."  •  auto 5s"

    local sorted = {}
    for k, v in pairs(byType) do table.insert(sorted, {name=k, data=v}) end
    table.sort(sorted, function(a, b)
        return (a.data.age100 + a.data.less100) > (b.data.age100 + b.data.less100)
    end)

    filter = (filter or ""):lower()

    for _, item in ipairs(sorted) do
        if filter == "" or item.name:lower():find(filter, 1, true) then
            local petTotal = item.data.age100 + item.data.less100
            local row = Instance.new("Frame")
            row.Size = UDim2.new(1, -8, 0, 26)
            row.BackgroundColor3 = C.Panel
            row.BorderSizePixel = 0
            row.Parent = scroll
            Instance.new("UICorner", row).CornerRadius = UDim.new(0, 4)

            local n = Instance.new("TextLabel")
            n.Size = UDim2.new(0.47, -4, 1, 0)
            n.Position = UDim2.new(0.03, 0, 0, 0)
            n.BackgroundTransparency = 1
            n.Text = item.name n.TextColor3 = C.Text
            n.Font = Enum.Font.Gotham n.TextSize = 11
            n.TextXAlignment = Enum.TextXAlignment.Left
            n.TextTruncate = Enum.TextTruncate.AtEnd
            n.Parent = row

            local c1 = Instance.new("TextLabel")
            c1.Size = UDim2.new(0.16, 0, 1, 0)
            c1.Position = UDim2.new(0.50, 0, 0, 0)
            c1.BackgroundTransparency = 1
            c1.Text = tostring(item.data.age100) c1.TextColor3 = C.Green
            c1.Font = Enum.Font.GothamBold c1.TextSize = 12
            c1.Parent = row

            local c2 = Instance.new("TextLabel")
            c2.Size = UDim2.new(0.14, 0, 1, 0)
            c2.Position = UDim2.new(0.66, 0, 0, 0)
            c2.BackgroundTransparency = 1
            c2.Text = tostring(item.data.less100) c2.TextColor3 = C.Orange
            c2.Font = Enum.Font.GothamBold c2.TextSize = 12
            c2.Parent = row

            local c3 = Instance.new("TextLabel")
            c3.Size = UDim2.new(0.17, 0, 1, 0)
            c3.Position = UDim2.new(0.80, 0, 0, 0)
            c3.BackgroundTransparency = 1
            c3.Text = tostring(petTotal) c3.TextColor3 = C.Accent
            c3.Font = Enum.Font.GothamBold c3.TextSize = 12
            c3.Parent = row
        end
    end

    scroll.CanvasSize = UDim2.new(0, 0, 0, layout.AbsoluteContentSize.Y + 8)
end

-- ============================================================
-- TOGGLE TABLE (+/- button)
-- ============================================================
local expanded = false
local function setExpanded(v)
    expanded = v
    tableSection.Visible = v
    footer.Visible = v
    if v then
        main.Size = UDim2.new(0, W, 0, EXPANDED_HEIGHT)
        plusBtn.Text = "—"
    else
        main.Size = UDim2.new(0, W, 0, COLLAPSED_HEIGHT)
        plusBtn.Text = "+"
    end
end
setExpanded(false)  -- default collapsed

plusBtn.MouseButton1Click:Connect(function()
    setExpanded(not expanded)
end)

-- ============================================================
-- FLOATING LOGO (muncul pas minimize)
-- ============================================================
local zLogo = Instance.new("TextButton")
zLogo.Size = UDim2.new(0, 42, 0, 42)
zLogo.Position = UDim2.new(0, 10, 0.5, -21)
zLogo.BackgroundColor3 = C.Accent
zLogo.Text = "⚡"
zLogo.TextColor3 = Color3.new(0, 0, 0)
zLogo.Font = Enum.Font.GothamBold
zLogo.TextSize = 22
zLogo.BorderSizePixel = 0
zLogo.AutoButtonColor = false
zLogo.Active = true
zLogo.Draggable = true
zLogo.Visible = false
zLogo.Parent = sg
Instance.new("UICorner", zLogo).CornerRadius = UDim.new(1, 0)
local zStroke = Instance.new("UIStroke", zLogo)
zStroke.Color = Color3.new(0, 0, 0)
zStroke.Thickness = 1.5

-- ============================================================
-- MINIMIZE (title bar)
-- ============================================================
local minimized = false
local lastExpanded = false
minBtn.MouseButton1Click:Connect(function()
    minimized = true
    lastExpanded = expanded
    main.Visible = false
    zLogo.Visible = true
end)

zLogo.MouseButton1Click:Connect(function()
    minimized = false
    main.Visible = true
    zLogo.Visible = false
end)

-- Live search
searchBox:GetPropertyChangedSignal("Text"):Connect(function()
    if expanded then
        render(findMemoryContainer(), searchBox.Text, 0)  -- re-render with filter
    end
end)

-- ============================================================
-- INIT + AUTO-REFRESH
-- ============================================================
local memContainer, memCount = findMemoryContainer()
print("[ZenxAgeStats] memContainer: "..(memContainer and memCount.." entries" or "FAIL"))

render(memContainer, "", memCount or 0)

-- Re-bind search to use cached container properly
searchBox:GetPropertyChangedSignal("Text"):Connect(function()
    render(memContainer, searchBox.Text, memCount or 0)
end)

task.spawn(function()
    while sg.Parent do
        task.wait(5)
        if not sg.Parent then break end
        local nc, ncnt = findMemoryContainer()
        if nc and ncnt > 0 then
            memContainer = nc
            memCount = ncnt
        end
        render(memContainer, searchBox.Text, memCount or 0)
    end
end)

print("[ZenxAgeStats] "..VER.." loaded")
