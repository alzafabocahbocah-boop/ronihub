-- ============= ZENX INVENTORY VIEWER + REJOIN =============
-- Standalone: Inventory Show + Rejoin (style sama dgn ZenxLvl main script)
local SCRIPT_VERSION = "v2.0"
print("==== [ZenxInv] LOAD ("..SCRIPT_VERSION..") ====")

local Players = game:GetService("Players")
local TS = game:GetService("TeleportService")
local player = Players.LocalPlayer

pcall(function()
    if player:FindFirstChild("PlayerGui") and player.PlayerGui:FindFirstChild("ZenxInvGui") then
        player.PlayerGui.ZenxInvGui:Destroy()
    end
end)

-- COLOR (sama dgn ZenxLvl)
local C = {
    BG=Color3.fromRGB(15,15,15), Panel=Color3.fromRGB(21,21,21), Card=Color3.fromRGB(25,25,25),
    White=Color3.fromRGB(225,225,225), Gray=Color3.fromRGB(120,120,120), Dim=Color3.fromRGB(55,55,55),
    Green=Color3.fromRGB(70,190,90), Red=Color3.fromRGB(200,60,60), RDim=Color3.fromRGB(35,10,10),
    Gold=Color3.fromRGB(220,160,0), Blue=Color3.fromRGB(80,150,255),
    Teal=Color3.fromRGB(40,200,160), TDim=Color3.fromRGB(8,30,24),
}

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

-- togRow style sama dgn ZenxLvl
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

-- cfgRow style sama dgn ZenxLvl
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
    for _, attr in ipairs({"Loved","IsLoved","Heart","Hearted","Liked","IsLiked","IsHeart","Love","HeartIcon","Favorited","Favourited","Favorite","Favourite","IsFavorited","IsFavourited"}) do
        local v = item:GetAttribute(attr)
        if v == true then return true end
    end
    local d = item:GetAttribute("d")
    if d == true then return true end
    return false
end
local function getPetName(item) return item.Name:match("^(.-)%s*%[") or item.Name end
local function getKG(item) return tonumber(item.Name:match("%[([%d%.]+)%s*[Kk][Gg]%]")) end
local function getAge(item)
    for _, pat in ipairs({"%[Age%s+(%d+)%]", "%[Age(%d+)%]"}) do
        local f = item.Name:match(pat) if f then return tonumber(f) end
    end
    return nil
end

local maxKGCache = {}
local function buildMaxKGCache()
    local bp = player:FindFirstChild("Backpack") if not bp then return end
    for _, item in pairs(bp:GetChildren()) do
        if isPet(item) then
            local name = getPetName(item)
            local age = getAge(item)
            local kg = getKG(item)
            if name and age and kg and age >= 1 then
                local maxKG = kg * 11 / (age + 10)
                local existing = maxKGCache[name]
                if not existing or maxKG > existing then maxKGCache[name] = maxKG end
            end
        end
    end
end
local function getMaxKGForPet(name) return maxKGCache[name] end
local function getAgeFromKG(item)
    local age = getAge(item) if age then return age end
    local kg = getKG(item) if not kg then return nil end
    local maxKG = getMaxKGForPet(getPetName(item)) if not maxKG then return nil end
    if maxKG <= 0 then return nil end
    return math.floor((kg * 11 / maxKG) - 10 + 0.5)
end

-- ============================================
-- BUILD GUI (lebih tinggi buat fit rejoin section)
-- ============================================
local GUI_W = 460 local GUI_H = 440
local sg = mk("ScreenGui",{Name="ZenxInvGui", DisplayOrder=999, ResetOnSpawn=false, Parent=player:WaitForChild("PlayerGui")})

local main = mk("Frame",{
    Size=UDim2.new(0, GUI_W, 0, GUI_H),
    Position=UDim2.new(0.5, -GUI_W/2, 0.5, -GUI_H/2),
    BackgroundColor3=C.BG, BorderSizePixel=0, Active=true, Draggable=true, Parent=sg
})
corner(main, 10) stroke(main, C.Teal, 2)

-- TITLE BAR (sama dgn ZenxLvl)
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

-- Mini Z icon (sama style ZenxLvl)
local miniIcon = mk("TextButton",{
    Size=UDim2.new(0,38,0,38), Position=UDim2.new(0.5,-19,0.5,-19),
    BackgroundColor3=C.BG, Text="Z", TextColor3=C.Teal,
    Font=Enum.Font.GothamBold, TextSize=18, AutoButtonColor=false,
    Visible=false, Active=true, Draggable=true, Parent=sg
})
corner(miniIcon, 8) stroke(miniIcon, C.Teal, 2)
minBtn.MouseButton1Click:Connect(function() main.Visible=false miniIcon.Visible=true end)
miniIcon.MouseButton1Click:Connect(function() main.Visible=true miniIcon.Visible=false end)

-- ============================================
-- CONTENT (with UIListLayout for clean stacking)
-- ============================================
local content = mk("ScrollingFrame",{
    Size=UDim2.new(1,-10,1,-44), Position=UDim2.new(0,5,0,39),
    BackgroundTransparency=1, BorderSizePixel=0,
    ScrollBarThickness=4, CanvasSize=UDim2.new(0,0,0,0),
    AutomaticCanvasSize=Enum.AutomaticSize.Y, Parent=main
})
mk("UIListLayout",{SortOrder=Enum.SortOrder.LayoutOrder, Padding=UDim.new(0,5), Parent=content})
mk("UIPadding",{PaddingLeft=UDim.new(0,2), PaddingRight=UDim.new(0,2), Parent=content})

-- ===== INVENTORY HEADER =====
local invHeader = mk("Frame",{Size=UDim2.new(1,0,0,26), BackgroundColor3=C.Panel, BorderSizePixel=0, LayoutOrder=1, Parent=content})
corner(invHeader, 7) stroke(invHeader, C.Dim, 1.2)
local invHeaderLbl = lbl(invHeader, "Inventory Pet (loading...)", 9, C.Teal)
invHeaderLbl.Size = UDim2.new(1,-100,1,0) invHeaderLbl.Position = UDim2.new(0,8,0,0)
local invRefreshBtn = btn(invHeader, "Refresh", 9, C.TDim, C.Teal)
invRefreshBtn.Size = UDim2.new(0,80,0,20) invRefreshBtn.Position = UDim2.new(1,-86,0.5,-10)
stroke(invRefreshBtn, C.Teal, 1.2)

-- ===== KG PILLS =====
local statsBar = mk("Frame",{Size=UDim2.new(1,0,0,24), BackgroundTransparency=1, LayoutOrder=2, Parent=content})
mk("UIListLayout",{FillDirection=Enum.FillDirection.Horizontal, Padding=UDim.new(0,3), HorizontalAlignment=Enum.HorizontalAlignment.Left, Parent=statsBar})

local kgRanges = {{1,2},{2,3},{3,4},{4,5},{5,6},{6,7}}
local kgPills = {}
for i, r in ipairs(kgRanges) do
    local pill = mk("Frame",{Size=UDim2.new(0,68,1,0), BackgroundColor3=C.Card, BorderSizePixel=0, LayoutOrder=i, Parent=statsBar})
    corner(pill, 5) stroke(pill, C.Dim, 1)
    local pl = lbl(pill, r[1].."-"..r[2].."kg: 0", 9, C.Gray, Enum.TextXAlignment.Center)
    pl.Size = UDim2.new(1,0,1,0)
    kgPills[i] = pl
end

-- ===== DETAIL PANEL =====
local detailPanel = mk("Frame",{Size=UDim2.new(1,0,0,92), BackgroundColor3=C.Card, BorderSizePixel=0, LayoutOrder=3, Parent=content})
corner(detailPanel, 7) stroke(detailPanel, C.Dim, 1.2)
mk("UIPadding",{PaddingTop=UDim.new(0,8), PaddingLeft=UDim.new(0,10), PaddingRight=UDim.new(0,10), Parent=detailPanel})
mk("UIListLayout",{SortOrder=Enum.SortOrder.LayoutOrder, Padding=UDim.new(0,4), Parent=detailPanel})

local detailTotal = lbl(detailPanel, "Total: -", 11, C.Teal) detailTotal.Size=UDim2.new(1,0,0,16) detailTotal.LayoutOrder=1
local detailFav = lbl(detailPanel, "Favorite: -", 10, C.Gold) detailFav.Size=UDim2.new(1,0,0,14) detailFav.LayoutOrder=2
local detailHigh = lbl(detailPanel, "Pet age 100+: -", 10, C.Green) detailHigh.Size=UDim2.new(1,0,0,14) detailHigh.LayoutOrder=3
local detailRange = lbl(detailPanel, "BaseKG range: -", 10, C.Blue) detailRange.Size=UDim2.new(1,0,0,14) detailRange.LayoutOrder=4

-- ===== DIVIDER =====
div(content, 4)

-- ============================================
-- REJOIN SECTION (style PERSIS sama dgn ZenxLvl main)
-- ============================================
local rejoinHeader = lbl(content, "REJOIN", 9, C.Teal) rejoinHeader.Size=UDim2.new(1,0,0,14) rejoinHeader.LayoutOrder=5

local rnBtn = btn(content, "Rejoin Now", 10, C.TDim, C.Teal)
rnBtn.Size = UDim2.new(1,0,0,24) rnBtn.LayoutOrder=6 stroke(rnBtn, C.Teal, 1.5)

local rejoinMinutes = 30  -- default
cfgRow(content, "Interval (menit)", 7, rejoinMinutes, function(v)
    rejoinMinutes = math.max(1, math.min(120, v))
end)

local _, arTog, arTogStroke, arStroke = togRow(content, "Auto Rejoin", "Rejoin otomatis sesuai interval", 8)
local cdLbl = lbl(content, "Auto Rejoin: OFF", 9, C.Gray, Enum.TextXAlignment.Center)
cdLbl.Size = UDim2.new(1,0,0,20) cdLbl.LayoutOrder=9 cdLbl.BackgroundColor3=C.Panel cdLbl.BackgroundTransparency=0
corner(cdLbl, 6) stroke(cdLbl, C.Dim, 1.1)

-- ============================================
-- INVENTORY BUILD LOGIC
-- ============================================
local function _doBuildInvShow()
    local bp = player:FindFirstChild("Backpack")
    if not bp then invHeaderLbl.Text = "Backpack gak ada" return end

    pcall(buildMaxKGCache)
    local petsList = {}
    local minBase, maxBase, sumBase, baseCount = math.huge, 0, 0, 0
    local favCount = 0 local highAgeCount = 0

    for _, item in pairs(bp:GetChildren()) do
        if isPet(item) then
            local age = getAgeFromKG(item)
            local kg = getKG(item)
            local fav = isFavorite(item)
            local baseKG = nil
            if kg and age and age >= 1 then
                baseKG = kg * 11 / (age + 10)
                if baseKG < minBase then minBase = baseKG end
                if baseKG > maxBase then maxBase = baseKG end
                sumBase = sumBase + baseKG
                baseCount = baseCount + 1
            end
            if fav then favCount = favCount + 1 end
            if age and age >= 100 then highAgeCount = highAgeCount + 1 end
            table.insert(petsList, {age=age or 0, kg=kg or 0, baseKG=baseKG, fav=fav})
        end
    end

    local rangeCounts = {0,0,0,0,0,0}
    for _, p in ipairs(petsList) do
        if p.baseKG then
            for ri, r in ipairs(kgRanges) do
                if p.baseKG >= r[1] and p.baseKG < r[2] then
                    rangeCounts[ri] = rangeCounts[ri] + 1
                    break
                end
            end
        end
    end

    invHeaderLbl.Text = "Total: "..#petsList.." pet"
    invHeaderLbl.TextColor3 = C.Teal
    for i, lblWidget in ipairs(kgPills) do
        local r = kgRanges[i]
        lblWidget.Text = r[1].."-"..r[2].."kg: "..rangeCounts[i]
        lblWidget.TextColor3 = rangeCounts[i] > 0 and C.Teal or C.Gray
    end
    detailTotal.Text = "Total: "..#petsList.." pet ("..baseCount.." dgn baseKG)"
    detailFav.Text = "Favorite: "..favCount.." pet"
    detailHigh.Text = "Pet age 100+: "..highAgeCount.." pet"
    if baseCount > 0 then
        detailRange.Text = string.format("BaseKG: min=%.2f max=%.2f avg=%.2f", minBase, maxBase, sumBase/baseCount)
    else
        detailRange.Text = "BaseKG: gak ada data"
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
-- REJOIN logic (PERSIS sama dgn ZenxLvl main script)
-- ============================================
local isAR = false
local arTask = nil
local autoRejoin = false

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
    autoRejoin = false
    setArTog(false)
    cdLbl.Text = "Auto Rejoin: OFF"
    cdLbl.TextColor3 = C.Gray
end

local function startAR()
    isAR = true autoRejoin = true
    setArTog(true)
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

print("==== ZenxInv "..SCRIPT_VERSION.." READY ====")
