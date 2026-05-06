-- ============= ZENX INVENTORY VIEWER v3.0 =============
-- Weight categories (Large/Huge/Titanic/Godly/Colossal) sesuai game.guide
-- Formula: weight = baseKG * (age + 10) / 11

local SCRIPT_VERSION = "v3.6 (age regex + maxKG cache)"
print("==== [ZenxInv] LOAD ("..SCRIPT_VERSION..") ====")

local Players = game:GetService("Players")
local TS = game:GetService("TeleportService")
local HttpService = game:GetService("HttpService")
local player = Players.LocalPlayer

-- persistence
local STATE_FILE = "ZenxInv_state.json"
local function saveState(state)
    if not writefile then return end
    pcall(function() writefile(STATE_FILE, HttpService:JSONEncode(state)) end)
end
local function loadState()
    if not (isfile and readfile and isfile(STATE_FILE)) then return nil end
    local ok, data = pcall(function() return HttpService:JSONDecode(readfile(STATE_FILE)) end)
    return ok and data or nil
end
local savedState = loadState() or {}

pcall(function()
    if player:FindFirstChild("PlayerGui") and player.PlayerGui:FindFirstChild("ZenxInvGui") then
        player.PlayerGui.ZenxInvGui:Destroy()
    end
end)

-- COLOR
local C = {
    BG=Color3.fromRGB(15,15,15), Panel=Color3.fromRGB(21,21,21), Card=Color3.fromRGB(25,25,25),
    White=Color3.fromRGB(225,225,225), Gray=Color3.fromRGB(120,120,120), Dim=Color3.fromRGB(55,55,55),
    Green=Color3.fromRGB(70,190,90), Red=Color3.fromRGB(200,60,60), RDim=Color3.fromRGB(35,10,10),
    Gold=Color3.fromRGB(220,160,0), Blue=Color3.fromRGB(80,150,255),
    Teal=Color3.fromRGB(40,200,160), TDim=Color3.fromRGB(8,30,24),
    Cyan=Color3.fromRGB(80,200,230), Purple=Color3.fromRGB(180,90,210),
    Pink=Color3.fromRGB(220,100,160), Orange=Color3.fromRGB(230,140,60),
}

-- v3.0: WEIGHT CATEGORIES dari game.guide
-- Pakai CURRENT KG (bukan baseKG) buat kategorisasi
local CATEGORIES = {
    {name="Small",     short="Sm",  min=0, max=2, color=C.Blue},
    {name="Large",     short="Lg",  min=2, max=3, color=C.Cyan},
    {name="Semi Huge", short="SH",  min=3, max=5, color=C.Pink},
    {name="Huge",      short="Hg",  min=5, max=6, color=C.Purple},
    {name="Semi Tit",  short="ST",  min=6, max=math.huge, color=C.Orange},
}

local function categorize(kg)
    if not kg then return nil end
    for _, cat in ipairs(CATEGORIES) do
        if kg >= cat.min and kg < cat.max then return cat end
    end
    return CATEGORIES[#CATEGORIES]
end

-- HELPERS
local function mk(cls, props)
    local o = Instance.new(cls)
    for k,v in pairs(props) do o[k] = v end
    return o
end
local function corner(p, r) return mk("UICorner",{CornerRadius=UDim.new(0, r or 7), Parent=p}) end
local function stroke(p, col, th) return mk("UIStroke",{Color=col or C.Teal, Thickness=th or 1.5, Parent=p}) end
local function lbl(p, txt, ts, col, xa)
    return mk("TextLabel",{
        BackgroundTransparency=1, Text=txt, TextColor3=col or C.White,
        Font=Enum.Font.GothamBold, TextSize=ts or 11, TextScaled=false,
        TextXAlignment=xa or Enum.TextXAlignment.Left, Parent=p
    })
end
local function btn(p, txt, ts, bg, tc)
    local b = mk("TextButton",{
        BackgroundColor3=bg or C.Card, Text=txt, TextColor3=tc or C.White,
        Font=Enum.Font.GothamBold, TextSize=ts or 11, TextScaled=false, AutoButtonColor=false, Parent=p
    })
    corner(b, 7)
    return b
end
local function div(parent, lo)
    return mk("Frame",{Size=UDim2.new(1,0,0,1), BackgroundColor3=C.Dim, BorderSizePixel=0, LayoutOrder=lo, Parent=parent})
end

local function togRow(parent, labelTxt, descTxt, lo)
    local row = mk("Frame",{Size=UDim2.new(1,0,0,32), BackgroundColor3=C.Card, BorderSizePixel=0, LayoutOrder=lo, Parent=parent})
    corner(row, 6) local rowStroke = stroke(row, C.Dim, 1.1)
    local l = lbl(row, labelTxt, 9, C.White) l.Size = UDim2.new(0.65,0,0,16) l.Position = UDim2.new(0,8,0,4)
    if descTxt then
        local dl = lbl(row, descTxt, 8, C.Dim) dl.Size = UDim2.new(0.75,0,0,11) dl.Position = UDim2.new(0,8,0,19)
    end
    local tog = btn(row, "OFF", 9, C.Panel, C.Gray) tog.Size = UDim2.new(0,44,0,20) tog.Position = UDim2.new(1,-50,0.5,-10)
    local togStroke = stroke(tog, C.Dim, 1.1)
    return row, tog, togStroke, rowStroke
end

local function cfgRow(parent, labelTxt, lo, default, onChange)
    local r = mk("Frame",{Size=UDim2.new(1,0,0,26), BackgroundColor3=C.Card, BorderSizePixel=0, LayoutOrder=lo, Parent=parent})
    corner(r, 6) stroke(r, C.Dim, 1.1)
    local l = lbl(r, labelTxt, 9, C.Gray) l.Size = UDim2.new(0.6,0,1,0) l.Position = UDim2.new(0,8,0,0)
    local box = mk("TextBox",{
        Size=UDim2.new(0,56,0,20), Position=UDim2.new(1,-62,0.5,-10),
        BackgroundColor3=C.Panel, Text=tostring(default), TextColor3=C.White,
        Font=Enum.Font.GothamBold, TextSize=10, TextScaled=false,
        TextXAlignment=Enum.TextXAlignment.Center, ClearTextOnFocus=false, Parent=r
    })
    corner(box, 5) stroke(box, C.Dim, 1)
    box:GetPropertyChangedSignal("Text"):Connect(function()
        local v = tonumber(box.Text)
        if v then onChange(v) end
    end)
    return r, box
end

-- PET HELPERS
local function isPet(item) return item:FindFirstChild("PetToolLocal") or item:FindFirstChild("PetToolServer") end
local function isFavorite(item)
    for _, attr in ipairs({"Loved","IsLoved","Heart","Hearted","Liked","IsLiked","IsHeart","Love","HeartIcon","Favorited","Favourited","Favorite","Favourite","IsFavorited","IsFavourited","d"}) do
        local v = item:GetAttribute(attr) if v == true then return true end
    end
    return false
end
local function getPetName(item) return item.Name:match("^(.-)%s*%[") or item.Name end
local function getKG(item)
    local n = item.Name
    local kg = n:match("%[%s*([%d%.]+)%s*[Kk][Gg]%s*%]")
    if kg then return tonumber(kg) end
    kg = n:match("([%d%.]+)%s*[Kk][Gg]")
    if kg then return tonumber(kg) end
    return nil
end
local function getAge(item)
    local n = item.Name
    -- v3.6: super lenient - "Age" followed by non-digit, then digits (case insensitive)
    -- handles "[Age 65]", "[Age:65]", "[ Age 65]", "Age65", "AGE 65", etc
    for _, pat in ipairs({
        "[Aa][Gg][Ee][^%d]*(%d+)",     -- Age + any non-digits + digits
        "[Aa][Gg][Ee]%s*(%d+)",         -- Age (optional space) digits
    }) do
        local f = n:match(pat) if f then return tonumber(f) end
    end
    return nil
end

-- v3.6: maxKG cache - build dari pet yg punya BOTH age + kg di nama
-- Pakai buat back-calculate age di pet yg gak punya Age di nama
local function getBaseName(name)
    -- Strip common mutation prefixes
    local mutPrefixes = {
        "Everchanted ","Enchanted ","Shiny ","Rainbow ","Wet ","Chocolate ","Zombified ","Disco ","Gold ","Frozen ",
        "Lunar ","Plasma ","Angelic ","Corrupt ","Crystal ","Verdant ","Blazing ","Icy ","Storm ","Shadow ",
        "Celestial ","Infernal ","Ancient ","Mythic ","Divine ","Venom ","Mimic ","Cosmic ","Galactic ","Stellar ",
        "Toxic ","Radiant ","Mystic ","Phantom ","Spectral ","Eldritch ","Primal ","Ethereal ","Astral ","Chromatic ",
        "Prismatic ","Volcanic ","Glacial ","Tempest ","Solar ","Nightmare ","Dreadbound ","Ghostly ","Diamond ","Bearded ",
        "Glimmering ","Sparkling ","Inverted ","Bloodlust ","Dawn ","Twilight ","Eclipse ","Aurora ","Frostbite ","Inferno ",
        "Demonic ","Holy ","Cursed ","Blessed ","Chaotic ","GIANT ","Mega ","Mini ","Tiny ","Royal ",
    }
    local current = name
    -- Strip multiple prefixes (e.g. "Nightmare Diamond Panther" → "Panther")
    for _ = 1, 3 do  -- max 3 layers
        local matched = false
        for _, prefix in ipairs(mutPrefixes) do
            if current:sub(1, #prefix) == prefix then
                current = current:sub(#prefix + 1)
                matched = true
                break
            end
        end
        if not matched then break end
    end
    return current
end

local maxKGCache = {}
local function buildMaxKGCache()
    maxKGCache = {}
    local bp = player:FindFirstChild("Backpack") if not bp then return end
    for _, item in pairs(bp:GetChildren()) do
        if isPet(item) then
            local name = getPetName(item)
            local age = getAge(item)  -- pakai getAge raw, BUKAN estimated
            local kg = getKG(item)
            if name and age and kg and age >= 1 then
                local maxKG = kg * 11 / (age + 10)
                -- Index by full name + base name
                local existing = maxKGCache[name]
                if not existing or maxKG > existing then maxKGCache[name] = maxKG end
                local base = getBaseName(name)
                if base ~= name then
                    local existingBase = maxKGCache[base]
                    if not existingBase or maxKG > existingBase then maxKGCache[base] = maxKG end
                end
            end
        end
    end
end

local function getMaxKGForPet(name)
    if maxKGCache[name] then return maxKGCache[name] end
    local base = getBaseName(name)
    if maxKGCache[base] then return maxKGCache[base] end
    return nil
end

-- v3.6: smart age fallback w/ maxKG cache lookup
local function getEstimatedAge(item)
    local age = getAge(item) if age then return age end
    local kg = getKG(item) if not kg then return nil end
    -- Try cache lookup buat back-calc age
    local maxKG = getMaxKGForPet(getPetName(item))
    if maxKG and maxKG > 0 then
        return math.max(1, math.min(100, math.floor(kg * 11 / maxKG - 10 + 0.5)))
    end
    -- Last resort
    if kg >= 20 then return 100 end
    return 1
end

-- v3.0: hitung baseKG dari current KG + age
local function calcBaseKG(kg, age)
    if not kg or not age or age < 1 then return nil end
    return kg * 11 / (age + 10)
end

-- ============================================
-- BUILD GUI
-- ============================================
local GUI_W = 480 local GUI_H = 460
local sg = mk("ScreenGui",{Name="ZenxInvGui", DisplayOrder=999, ResetOnSpawn=false, Parent=player:WaitForChild("PlayerGui")})

local main = mk("Frame",{
    Size=UDim2.new(0, GUI_W, 0, GUI_H),
    Position=UDim2.new(0.5, -GUI_W/2, 0.5, -GUI_H/2),
    BackgroundColor3=C.BG, BorderSizePixel=0, Active=true, Draggable=true, Parent=sg
})
corner(main, 10) stroke(main, C.Teal, 2)

-- TITLE BAR
local TB = mk("Frame",{Size=UDim2.new(1,0,0,34), BackgroundColor3=C.Panel, BorderSizePixel=0, Parent=main})
corner(TB, 10)
mk("Frame",{Size=UDim2.new(1,0,0,1.5), Position=UDim2.new(0,0,1,-1.5), BackgroundColor3=C.Teal, BorderSizePixel=0, Parent=TB})
local titleLbl = lbl(TB, "ZENX INVENTORY  "..SCRIPT_VERSION, 11, C.Teal)
titleLbl.Size = UDim2.new(1, -60, 1, 0) titleLbl.Position = UDim2.new(0, 10, 0, 0)

local minBtn = btn(TB, "-", 13, C.Panel, C.Gray)
minBtn.Size = UDim2.new(0,22,0,22) minBtn.Position = UDim2.new(1,-50,0.5,-11) stroke(minBtn, C.Dim, 1.2)
local closeBtn = btn(TB, "X", 10, C.RDim, C.Red)
closeBtn.Size = UDim2.new(0,22,0,22) closeBtn.Position = UDim2.new(1,-24,0.5,-11) stroke(closeBtn, C.Red, 1.2)
closeBtn.MouseButton1Click:Connect(function() sg:Destroy() end)

local miniIcon = mk("TextButton",{
    Size=UDim2.new(0,38,0,38), Position=UDim2.new(0.5,-19,0.5,-19),
    BackgroundColor3=C.BG, Text="Z", TextColor3=C.Teal,
    Font=Enum.Font.GothamBold, TextSize=18, AutoButtonColor=false,
    Visible=false, Active=true, Draggable=true, Parent=sg
})
corner(miniIcon, 8) stroke(miniIcon, C.Teal, 2)
minBtn.MouseButton1Click:Connect(function() main.Visible=false miniIcon.Visible=true end)
miniIcon.MouseButton1Click:Connect(function() main.Visible=true miniIcon.Visible=false end)

-- CONTENT
local content = mk("ScrollingFrame",{
    Size=UDim2.new(1,-10,1,-44), Position=UDim2.new(0,5,0,39),
    BackgroundTransparency=1, BorderSizePixel=0,
    ScrollBarThickness=4, AutomaticCanvasSize=Enum.AutomaticSize.Y, Parent=main
})
mk("UIListLayout",{SortOrder=Enum.SortOrder.LayoutOrder, Padding=UDim.new(0,5), Parent=content})
mk("UIPadding",{PaddingLeft=UDim.new(0,2), PaddingRight=UDim.new(0,2), Parent=content})

-- INVENTORY HEADER
local invHeader = mk("Frame",{Size=UDim2.new(1,0,0,26), BackgroundColor3=C.Panel, BorderSizePixel=0, LayoutOrder=1, Parent=content})
corner(invHeader, 7) stroke(invHeader, C.Dim, 1.2)
local invHeaderLbl = lbl(invHeader, "Pet Inventory (loading...)", 10, C.Teal)
invHeaderLbl.Size = UDim2.new(1,-100,1,0) invHeaderLbl.Position = UDim2.new(0,8,0,0)
local invRefreshBtn = btn(invHeader, "Refresh", 9, C.TDim, C.Teal)
invRefreshBtn.Size = UDim2.new(0,80,0,20) invRefreshBtn.Position = UDim2.new(1,-86,0.5,-10)
stroke(invRefreshBtn, C.Teal, 1.2)

-- v3.0: WEIGHT CATEGORY PILLS (7 categories)
-- 2 rows: Row 1 (4 pills) + Row 2 (3 pills) biar muat
local catRow1 = mk("Frame",{Size=UDim2.new(1,0,0,32), BackgroundTransparency=1, LayoutOrder=2, Parent=content})
mk("UIListLayout",{FillDirection=Enum.FillDirection.Horizontal, Padding=UDim.new(0,4), HorizontalAlignment=Enum.HorizontalAlignment.Left, Parent=catRow1})

local catLabels = {}
for i, cat in ipairs(CATEGORIES) do
    -- v3.4: 4 pills 1 row (Small/Large/Semi Huge/Huge), pill lebih lebar
    local pillW = 90  -- v3.5: 5 pills fit
    local pill = mk("Frame",{Size=UDim2.new(0, pillW, 1, 0), BackgroundColor3=C.Card, BorderSizePixel=0, LayoutOrder=i, Parent=catRow1})
    corner(pill, 5) stroke(pill, C.Dim, 1)
    local pl = lbl(pill, cat.name..": 0", 10, C.Gray, Enum.TextXAlignment.Center)
    pl.Size = UDim2.new(1,0,1,0)
    pl.Font = Enum.Font.GothamBold
    catLabels[i] = pl
end

-- DETAIL PANEL
local detailPanel = mk("Frame",{Size=UDim2.new(1,0,0,110), BackgroundColor3=C.Card, BorderSizePixel=0, LayoutOrder=3, Parent=content})
corner(detailPanel, 7) stroke(detailPanel, C.Dim, 1.2)
mk("UIPadding",{PaddingTop=UDim.new(0,8), PaddingLeft=UDim.new(0,10), PaddingRight=UDim.new(0,10), Parent=detailPanel})
mk("UIListLayout",{SortOrder=Enum.SortOrder.LayoutOrder, Padding=UDim.new(0,4), Parent=detailPanel})

local detailTotal = lbl(detailPanel, "Total: -", 11, C.Teal) detailTotal.Size=UDim2.new(1,0,0,16) detailTotal.LayoutOrder=1
local detailFav = lbl(detailPanel, "Favorite: -", 10, C.Gold) detailFav.Size=UDim2.new(1,0,0,14) detailFav.LayoutOrder=2
local detailHigh = lbl(detailPanel, "Pet age 100+: -", 10, C.Green) detailHigh.Size=UDim2.new(1,0,0,14) detailHigh.LayoutOrder=3
local detailKG = lbl(detailPanel, "Weight range: -", 10, C.Blue) detailKG.Size=UDim2.new(1,0,0,14) detailKG.LayoutOrder=4
local detailUnread = lbl(detailPanel, "Unread: -", 10, C.Gray) detailUnread.Size=UDim2.new(1,0,0,14) detailUnread.LayoutOrder=5

-- DIVIDER
div(content, 4)

-- REJOIN
local rejoinHeader = lbl(content, "REJOIN", 9, C.Teal) rejoinHeader.Size=UDim2.new(1,0,0,14) rejoinHeader.LayoutOrder=5

local rnBtn = btn(content, "Rejoin Now", 10, C.TDim, C.Teal)
rnBtn.Size = UDim2.new(1,0,0,24) rnBtn.LayoutOrder=6 stroke(rnBtn, C.Teal, 1.5)

local rejoinMinutes = savedState.rejoinMinutes or 30
cfgRow(content, "Interval (menit)", 7, rejoinMinutes, function(v)
    rejoinMinutes = math.max(1, math.min(120, v))
    saveState({autoRejoin=savedState.autoRejoin, rejoinMinutes=rejoinMinutes})
end)

local _, arTog, arTogStroke, arStroke = togRow(content, "Auto Rejoin", "Rejoin otomatis sesuai interval", 8)
local cdLbl = lbl(content, "Auto Rejoin: OFF", 9, C.Gray, Enum.TextXAlignment.Center)
cdLbl.Size = UDim2.new(1,0,0,20) cdLbl.LayoutOrder=9 cdLbl.BackgroundColor3=C.Panel cdLbl.BackgroundTransparency=0
corner(cdLbl, 6) stroke(cdLbl, C.Dim, 1.1)

-- ============================================
-- INVENTORY BUILD
-- ============================================
local function _doBuildInvShow()
    local bp = player:FindFirstChild("Backpack")
    if not bp then invHeaderLbl.Text = "Backpack gak ada" return end

    -- v3.6: build maxKG cache dulu (dari pet yg punya age di nama)
    pcall(buildMaxKGCache)

    local petsList = {}
    local minKG, maxKG, sumKG, kgCount = math.huge, 0, 0, 0
    local favCount = 0 local highAgeCount = 0 local unreadCount = 0
    local catCounts = {}  -- per category
    for i = 1, #CATEGORIES do catCounts[i] = 0 end

    for _, item in pairs(bp:GetChildren()) do
        if isPet(item) then
            local kg = getKG(item)
            local age = getEstimatedAge(item)
            local fav = isFavorite(item)

            if kg then
                if kg < minKG then minKG = kg end
                if kg > maxKG then maxKG = kg end
                sumKG = sumKG + kg
                kgCount = kgCount + 1

                -- v3.1: categorize by BASE KG (kg di age 1, sesuai game.guide)
                -- baseKG = kg * 11 / (age + 10)
                local baseKG = nil
                if age and age >= 1 then
                    baseKG = kg * 11 / (age + 10)
                end
                if baseKG then
                    local cat = categorize(baseKG)
                    if cat then
                        for i, c in ipairs(CATEGORIES) do
                            if c == cat then catCounts[i] = catCounts[i] + 1 break end
                        end
                    end
                end
            else
                unreadCount = unreadCount + 1
                print("[ZenxInv] UNREAD pet: '"..item.Name.."'")
            end

            if fav then favCount = favCount + 1 end
            if age and age >= 100 then highAgeCount = highAgeCount + 1 end
            table.insert(petsList, {kg=kg, age=age, fav=fav, name=item.Name})
        end
    end

    invHeaderLbl.Text = "Total: "..#petsList.." pet"
    invHeaderLbl.TextColor3 = C.Teal

    for i, lblWidget in ipairs(catLabels) do
        local cat = CATEGORIES[i]
        local count = catCounts[i]
        -- v3.2: tampilin range KG di pill
        local rangeStr
        if cat.max == math.huge then
            rangeStr = cat.min.."+"
        else
            rangeStr = cat.min.."-"..cat.max
        end
        lblWidget.Text = cat.name.." ("..rangeStr.."): "..count
        lblWidget.TextColor3 = count > 0 and cat.color or C.Gray
    end

    detailTotal.Text = "Total: "..#petsList.." pet ("..kgCount.." dgn KG)"
    detailFav.Text = "Favorite: "..favCount.." pet"
    detailHigh.Text = "Pet age 100+: "..highAgeCount.." pet"
    if kgCount > 0 then
        detailKG.Text = string.format("Current KG: min=%.2f max=%.2f avg=%.2f", minKG, maxKG, sumKG/kgCount)
    else
        detailKG.Text = "Weight: gak ada data"
    end
    if unreadCount > 0 then
        detailUnread.Text = "Unread: "..unreadCount.." pet (cek console)"
        detailUnread.TextColor3 = C.Red
    else
        detailUnread.Text = "Semua pet ke-baca"
        detailUnread.TextColor3 = C.Green
    end
end

local function buildInvShow()
    local ok, err = pcall(_doBuildInvShow)
    if not ok then
        invHeaderLbl.Text = "ERR: "..tostring(err):sub(1,80)
        invHeaderLbl.TextColor3 = C.Red
    end
end

invRefreshBtn.MouseButton1Click:Connect(buildInvShow)
task.spawn(function() task.wait(0.5) buildInvShow() end)

-- ============================================
-- REJOIN
-- ============================================
local isAR = false
local arTask = nil

rnBtn.MouseButton1Click:Connect(function()
    rnBtn.Text = "Rejoining..."
    task.wait(0.5)
    TS:Teleport(game.PlaceId, player)
end)

local function setArTog(val)
    arTog.Text = val and "ON" or "OFF"
    arTog.BackgroundColor3 = val and C.TDim or C.Panel
    arTog.TextColor3 = val and C.Teal or C.Gray
    arTogStroke.Color = val and C.Teal or C.Dim
    arStroke.Color = val and C.Teal or C.Dim
end
setArTog(false)

local function stopAR()
    isAR = false
    if arTask then task.cancel(arTask) arTask = nil end
    setArTog(false)
    cdLbl.Text = "Auto Rejoin: OFF"
    cdLbl.TextColor3 = C.Gray
    saveState({autoRejoin=false, rejoinMinutes=rejoinMinutes})
end

local function startAR()
    isAR = true
    setArTog(true)
    saveState({autoRejoin=true, rejoinMinutes=rejoinMinutes})
    arTask = task.spawn(function()
        while isAR do
            local mins = rejoinMinutes
            for i = mins*60, 1, -1 do
                if not isAR then return end
                cdLbl.Text = string.format("Rejoin dalam: %02d:%02d", math.floor(i/60), i%60)
                cdLbl.TextColor3 = C.Teal
                task.wait(1)
            end
            if isAR then
                cdLbl.Text = "Rejoining..."
                task.wait(0.5)
                TS:Teleport(game.PlaceId, player)
            end
        end
    end)
end

arTog.MouseButton1Click:Connect(function()
    if isAR then stopAR() else startAR() end
end)

-- Auto resume Auto Rejoin
if savedState.autoRejoin == true then
    print("[ZenxInv] resume Auto Rejoin ON")
    task.spawn(function() task.wait(2) startAR() end)
end

print("==== ZenxInv "..SCRIPT_VERSION.." READY ====")
