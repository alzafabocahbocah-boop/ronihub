-- ============= ZENX INVENTORY VIEWER v3.0 =============
-- Weight categories (Large/Huge/Titanic/Godly/Colossal) sesuai game.guide
-- Formula: weight = baseKG * (age + 10) / 11

local SCRIPT_VERSION = "v5.0 (Simplify: buang mut divisor, display kg = base kg)"
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

-- ===== REJOIN SERVER DETECTION =====
-- Bandingkan JobId saat ini vs JobId sebelum rejoin
local currentJobId = tostring(game.JobId or "")
local serverDGT = workspace.DistributedGameTime or 0
print("============================================")
print("[ZenxInv] REJOIN DETECTION ANALYSIS")
print("[ZenxInv] Current JobId: "..currentJobId)
print("[ZenxInv] Server uptime: "..math.floor(serverDGT).." detik ("..string.format("%.1f", serverDGT/60).." menit)")
print("[ZenxInv] Saved state file exists: "..tostring(isfile and isfile(STATE_FILE) or false))
if savedState and savedState.lastJobId then
    print("[ZenxInv] savedState.lastJobId: "..tostring(savedState.lastJobId))
    print("[ZenxInv] savedState.rejoinTime: "..tostring(savedState.rejoinTime))
    print("[ZenxInv] elapsed since rejoin: "..(os.time() - (savedState.rejoinTime or 0)).." detik")
    print("[ZenxInv] savedState.retryCount: "..tostring(savedState.retryCount))
end
print("============================================")
local rejoinStatus = "fresh"  -- fresh | new | same
local rejoinTimeAgo = nil
local retryCount = tonumber(savedState.retryCount or 0)
local triedJobIds = savedState.triedJobIds or {}

if savedState.lastJobId and savedState.lastJobId ~= "" then
    local elapsed = os.time() - (savedState.rejoinTime or 0)
    if elapsed < 600 then
        rejoinTimeAgo = elapsed
        if savedState.lastJobId == currentJobId then
            rejoinStatus = "same"
            print("[ZenxInv] ⚠ Server LAMA! Retry #"..retryCount.." JobId: "..currentJobId:sub(1,12).."...")
        else
            rejoinStatus = "new"
            print("[ZenxInv] ✓ Server BARU after "..retryCount.." retries. Old: "..savedState.lastJobId:sub(1,12).."... → New: "..currentJobId:sub(1,12).."...")
            -- Reset tried list on success
            retryCount = 0
            triedJobIds = {}
        end
    end
end
-- Add current JobId to tried list (avoid retrying same)
local alreadyTried = false
for _, j in ipairs(triedJobIds) do
    if j == currentJobId then alreadyTried = true break end
end
if not alreadyTried then table.insert(triedJobIds, currentJobId) end
-- Save clean state for next teleport
savedState.lastJobId = nil
savedState.rejoinTime = nil
savedState.retryCount = retryCount
savedState.triedJobIds = triedJobIds
saveState(savedState)

-- Destroy old GUI di SEMUA possible parents
pcall(function()
    -- PlayerGui (default)
    if player:FindFirstChild("PlayerGui") and player.PlayerGui:FindFirstChild("ZenxInvGui") then
        player.PlayerGui.ZenxInvGui:Destroy()
    end
    -- gethui (executor protected container)
    if gethui then
        local hui = gethui()
        if hui and hui:FindFirstChild("ZenxInvGui") then
            hui.ZenxInvGui:Destroy()
        end
    end
    -- CoreGui
    local cg = game:GetService("CoreGui")
    if cg:FindFirstChild("ZenxInvGui") then
        cg.ZenxInvGui:Destroy()
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
    Black=Color3.fromRGB(0,0,0),  -- v4.9: buat gajah pill bawah
}

-- v4.0: Weight categories 2 rows
-- v4.9: gajah pill cuma 🐘, no kg range no count. Top=bg merah, Bot=bg hitam
local CAT_TOP = {
    {name="0-2",     min=0,    max=2,         color=C.Green},
    {name="2-3",     min=2,    max=3,         color=C.Gold},
    {name="3-3.7",   min=3,    max=3.7,       color=C.Orange},
    {name="3.8-4",   min=3.8,  max=4,         color=C.Red},
    {name="🐘",      min=38,   max=math.huge, color=C.White, bg=C.Black, no_text=true},
}
local CAT_BOT = {
    {name="3-4",     min=3,    max=4,         color=C.Green},
    {name="4-5",     min=4,    max=5,         color=C.Gold},
    {name="5-5.9",   min=5,    max=5.9,       color=C.Orange},
    {name="5.9-6.4", min=5.9,  max=6.4,       color=C.Red},
    {name="🐘",      min=60,   max=math.huge, color=C.White, bg=C.Red, no_text=true},
}
-- Backward compat alias (CATEGORIES used elsewhere)
local CATEGORIES = CAT_TOP

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
    -- v4.1: probe SEMUA attributes pet (cepet - cuma attribute lookup)
    -- Source 1: scan all attributes, cari yg namanya kayak "age"/"level"
    local ok, attrs = pcall(function() return item:GetAttributes() end)
    if ok and attrs then
        for k, v in pairs(attrs) do
            if tonumber(v) and tonumber(v) > 0 and tonumber(v) <= 200 then
                local kl = k:lower()
                if kl == "age" or kl == "level" or kl == "petage" or kl == "petlevel"
                    or kl == "displayage" or kl == "currentage" or kl == "currentlevel" then
                    return tonumber(v)
                end
            end
        end
    end

    -- Source 2: child IntValue/NumberValue (no deep scan)
    for _, childName in ipairs({"Age", "AGE", "age", "Level", "LEVEL", "level", "PetAge", "PetLevel"}) do
        local c = item:FindFirstChild(childName)
        if c and c.Value and tonumber(c.Value) then return tonumber(c.Value) end
    end

    -- v4.1: parse dari nama dengan banyak format (sync sm sc leveling)
    local n = item.Name
    for _, pat in ipairs({
        "%[Age%s+(%d+)%]","%[Age(%d+)%]",
        "%[Lv%s+(%d+)%]","%[Lv(%d+)%]",
        "%[Level%s+(%d+)%]","%[Level(%d+)%]",
        "%[Lvl%s+(%d+)%]","%[Lvl(%d+)%]",
        "Age%s*[:=]%s*(%d+)","Lv%s*[:=]%s*(%d+)","Level%s*[:=]%s*(%d+)",
    }) do
        local f = n:match(pat) if f then return tonumber(f) end
    end
    -- v4.1: handle [Age MAX] / [MAX] = 100
    if n:match("%[Age%s*MAX%]") or n:match("%[MAX%]") then return 100 end
    return nil
end

-- v3.24: MUTATION_NAMES sinkron dengan sc leveling - tambah Moonlit/Galactic/Eclipsed/dll
-- Plus auto-build prefix list dengan ", " (format antar mutasi) DAN " " (sebelum base name)
local MUTATION_NAMES = {
    -- Single-word mutations (sorted alphabetical)
    "Alienated","Ancient","Angelic","Aromatic","Ascended","Astral","Aurora",
    "Bearded","Blazing","Blessed","Blossoming","Bloodlust",
    "Celestial","Chaotic","Chilled","Chocolate","Christmas","Chromatic","Corrupt","Corrupted",
    "Cosmic","Crocodile","Crystal","Cursed",
    "Dawn","Demonic","Diamond","Disco","Divine","Dreadbound",
    "Eclipse","Eclipsed","Eldritch","Enchanted","Ethereal","Everchanted",
    "Fiery","Forger","Fried","Frostbite","Frozen",
    "Galactic","GIANT","Giraffe","Ghostly","Glacial","Glimmering","Gold","Golden",
    "HyperHunger","Holy",
    "Icy","Infernal","Inferno","Inverted","IronSkin",
    "JollyDecorator","JUMBO",
    "Lion","Lunar","Luminous",
    "Mega","MerryNursery","Mimic","Mini","Moonlit","Mystic","Mythic",
    "Nightmare","Nocturnal","Nutty",
    "Oxpecker",
    "Peppermint","Phantom","Plasma","Prismatic","Primal",
    "Radiant","Rainbow","Rhino","Rideable","Royal",
    "Shadow","Shiny","Shocked","Silver","SpiritSparkle","Solar","Soulflame","Sparkling","Spectral","Starlit","Stellar","Storm",
    "Tempest","Tethered","Tiny","Toxic","Tranquil","Twilight",
    "UFO",
    "Venom","Verdant","Volcanic",
    "Wet","Windy",
    "Zombified",
    -- Multi-word PascalCase + spaced variants
    "Christmas Rally","ChristmasRally",
    "Giant Bean","GiantBean",
    "Giant Golem","GiantGolem",
    "Hyper Hunger",
    "Iron Skin",
    "Jolly Decorator",
    "Merry Nursery","MerryNursery",
    "Spirit Sparkle",
}
-- Auto-build prefix list with both " " and ", " separators
local MUTATION_PREFIXES = {}
for _, m in ipairs(MUTATION_NAMES) do
    table.insert(MUTATION_PREFIXES, m..", ")  -- comma + space (between mutations)
    table.insert(MUTATION_PREFIXES, m.." ")   -- space (before base name)
end

-- v4.2: detect mutasi by name prefix (declared early — dipake banyak helper)
local function hasMutation(item)
    if not item then return false end
    local name = item.Name or ""
    for _, prefix in ipairs(MUTATION_PREFIXES) do
        if name:sub(1, #prefix) == prefix then return true end
    end
    return false
end

-- v4.4: hardcoded set of pet names where FIRST WORD conflicts with mutation name
-- Without this, "Mimic Octopus" pet → getBaseName strips "Mimic " → "Octopus" (WRONG)
local CONFLICTING_PET_NAMES = {
    ["Mimic Octopus"] = true,
    -- add more kalo nemu (e.g. "Lion Fish", "Tiger Shark")
}

local function getBaseName(name)
    -- v4.4: kalo nama input persis pet di list konflik, return as-is (don't over-strip)
    if CONFLICTING_PET_NAMES[name] then return name end
    local result = name
    local changed = true
    -- Strip multi-layer mutations (e.g. "Shocked, Moonlit, Galactic Mimic Octopus" → "Mimic Octopus")
    while changed do
        changed = false
        for _, prefix in ipairs(MUTATION_PREFIXES) do
            if result:sub(1, #prefix) == prefix then
                local stripped = result:sub(#prefix + 1)
                if stripped == "" then break end
                result = stripped
                changed = true
                -- v4.4: stop strip kalo hasil udah jadi pet name asli yang valid
                if CONFLICTING_PET_NAMES[result] then return result end
                break
            end
        end
    end
    return result
end

local maxKGCache = {}
local function buildMaxKGCache()
    maxKGCache = {}
    local bp = player:FindFirstChild("Backpack") if not bp then return end
    for _, item in pairs(bp:GetChildren()) do
        if isPet(item) then
            local name = getPetName(item)
            local age = getAge(item)
            local kg = getKG(item)
            -- v5.0: gak pake mut divisor, kg langsung normalize by age
            if name and age and kg and age >= 1 then
                local maxKG = kg * 11 / (age + 10)
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

-- v5.0: getEstimatedAge — pakai cache + normalize by age (no mut divisor)
local function getEstimatedAge(item)
    local age = getAge(item) if age then return age end
    local kg = getKG(item) if not kg then return nil end
    -- inverse formula: age = (kg × 11) / maxKG - 10
    local maxKG = getMaxKGForPet(getPetName(item))
    if maxKG and maxKG > 0 then
        return math.max(1, math.min(200, math.floor(kg * 11 / maxKG - 10 + 0.5)))
    end
    return nil
end

-- v5.0: SIMPLIFY — buang mutation divisor. Pet display 6kg → base 6kg (apapun mutasinya).
-- Logic: mutation udah kebake di kg display, gak perlu dibagi lagi. Cuma normalize by age.
local function getPetBaseKG(item)
    local kg = getKG(item)
    if not kg then return nil end
    local age = getAge(item)

    -- Priority 1: dari age + kg formula (paling akurat & konsisten)
    if age and age >= 1 then
        return kg * 11 / (age + 10)
    end

    -- Priority 2: cache (dari pet sejenis yang punya age)
    local cached = getMaxKGForPet(getPetName(item))
    if cached then return cached end

    -- Priority 3: assume pet baru hatched
    if kg < 20 then return kg end
    return nil  -- skip categorization
end

local function calcBaseKG(kg, age)
    if not kg or not age or age < 1 then return nil end
    return kg * 11 / (age + 10)
end

-- ============================================
-- BUILD GUI
-- ============================================
local GUI_W = 420 local GUI_H_COMPACT = 150 local GUI_H_FULL = 300 local GUI_H = GUI_H_COMPACT  -- v4.8: W=420

-- Try parent ke CoreGui supaya tidak bisa di-destroy oleh script game/script lain
local guiParent = player:WaitForChild("PlayerGui")
local protected = false
do
    -- Try gethui() (Synapse/Krnl/Delta/Fluxus exposes ProtectedGuis container)
    local ok, hui = pcall(function()
        if gethui then return gethui() end
        return nil
    end)
    if ok and hui then
        guiParent = hui
        protected = true
        print("[ZenxInv] GUI parented to gethui() — protected from destroy")
    else
        -- Fallback: try CoreGui directly (kalau executor support)
        local ok2, cg = pcall(function() return game:GetService("CoreGui") end)
        if ok2 and cg then
            -- Test if we can parent (executor needs perms)
            local test = pcall(function()
                local tmp = Instance.new("ScreenGui")
                tmp.Name = "_zenxTest"
                tmp.Parent = cg
                tmp:Destroy()
            end)
            if test then
                guiParent = cg
                protected = true
                print("[ZenxInv] GUI parented to CoreGui — protected")
            end
        end
    end
    if not protected then
        print("[ZenxInv] GUI di PlayerGui (gak protected, executor gak support gethui/CoreGui)")
    end
end

local sg = mk("ScreenGui",{
    Name="ZenxInvGui",
    DisplayOrder=2147483647,  -- max int32, paling depan
    ResetOnSpawn=false,
    IgnoreGuiInset=true,
    ZIndexBehavior=Enum.ZIndexBehavior.Sibling,
    Parent=guiParent
})

-- Keep DisplayOrder max + re-parent kalau di-destroy (anti-tamper)
task.spawn(function()
    while sg do
        task.wait(2)
        pcall(function()
            if sg.DisplayOrder ~= 2147483647 then sg.DisplayOrder = 2147483647 end
            if not sg.Parent or sg.Parent == nil then
                sg.Parent = guiParent
            end
        end)
    end
end)

local main = mk("Frame",{
    Size=UDim2.new(0, GUI_W, 0, GUI_H),
    -- v4.2: anchor di bottom-left (Y=1, AnchorPoint Y=1), 20px dari edge bawah
    AnchorPoint=Vector2.new(0, 1),
    Position=UDim2.new(0, 70, 1, -20),
    BackgroundColor3=C.BG, BorderSizePixel=0, Active=true, Draggable=true,
    Visible=true,  -- v3.10: start visible (gui lebar langsung muncul)
    Parent=sg
})
corner(main, 10) stroke(main, C.Teal, 2)

-- TITLE BAR
local TB = mk("Frame",{Size=UDim2.new(1,0,0,34), BackgroundColor3=C.Panel, BorderSizePixel=0, Parent=main})
corner(TB, 10)
mk("Frame",{Size=UDim2.new(1,0,0,1.5), Position=UDim2.new(0,0,1,-1.5), BackgroundColor3=C.Teal, BorderSizePixel=0, Parent=TB})
local titleLbl = lbl(TB, "ZENX INVENTORY  "..SCRIPT_VERSION, 11, C.Teal)
titleLbl.Size = UDim2.new(1, -60, 1, 0) titleLbl.Position = UDim2.new(0, 10, 0, 0)

-- v3.8: tombol expand "+" (toggle Rejoin section), minimize "-", close "X"
local expBtn = btn(TB, "+", 14, C.TDim, C.Teal)
expBtn.Size = UDim2.new(0,22,0,22) expBtn.Position = UDim2.new(1,-76,0.5,-11) stroke(expBtn, C.Teal, 1.2)
local minBtn = btn(TB, "-", 13, C.Panel, C.Gray)
minBtn.Size = UDim2.new(0,22,0,22) minBtn.Position = UDim2.new(1,-50,0.5,-11) stroke(minBtn, C.Dim, 1.2)
local closeBtn = btn(TB, "X", 10, C.RDim, C.Red)
closeBtn.Size = UDim2.new(0,22,0,22) closeBtn.Position = UDim2.new(1,-24,0.5,-11) stroke(closeBtn, C.Red, 1.2)
closeBtn.MouseButton1Click:Connect(function() sg:Destroy() end)

-- v3.10: mini Z fixed (visible cuma pas minimize, gak nongol pas pertama load)
local miniIcon = mk("TextButton",{
    Size=UDim2.new(0,40,0,40),
    Position=UDim2.new(0,18,0.5,-20),
    BackgroundColor3=C.BG, Text="Z", TextColor3=C.Teal,
    Font=Enum.Font.GothamBold, TextSize=22, AutoButtonColor=false,
    Visible=false, Active=false, Draggable=false, Parent=sg
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

-- v4.0: WEIGHT CATEGORY PILLS - 2 rows × 5 pills each
-- v4.5: pill text gedein dari 9 → 16, row tinggiin 28 → 42
-- Top: 0-2, 2-3, 3-3.7, 3.8-4, Gajah Abu 38+
-- Bot: 3-4, 4-5, 5-5.9, 5.9-6.4, Gajah Merah 60+
local catRow1 = mk("Frame",{Size=UDim2.new(1,0,0,42), BackgroundTransparency=1, LayoutOrder=2, Parent=content})
mk("UIListLayout",{FillDirection=Enum.FillDirection.Horizontal, Padding=UDim.new(0,3), HorizontalAlignment=Enum.HorizontalAlignment.Left, Parent=catRow1})

local catRow2 = mk("Frame",{Size=UDim2.new(1,0,0,42), BackgroundTransparency=1, LayoutOrder=3, Parent=content})
mk("UIListLayout",{FillDirection=Enum.FillDirection.Horizontal, Padding=UDim.new(0,3), HorizontalAlignment=Enum.HorizontalAlignment.Left, Parent=catRow2})

-- v4.9: PILL_W default 88, gajah pill (no_text) cuma 36 biar pill lain (5.9-6.4) lega
local PILL_W = 88
local PILL_W_GAJAH = 36

local catTopLabels = {}
for i, cat in ipairs(CAT_TOP) do
    local w = cat.no_text and PILL_W_GAJAH or PILL_W
    -- v4.9: pake cat.bg kalo ada (buat gajah merah)
    local pill = mk("Frame",{Size=UDim2.new(0, w, 1, 0), BackgroundColor3=cat.bg or C.Card, BorderSizePixel=0, LayoutOrder=i, Parent=catRow1})
    corner(pill, 5) stroke(pill, C.Dim, 1)
    -- v4.9: no_text → hanya nama (mis "🐘"), tanpa ": 0"
    local initText = cat.no_text and cat.name or (cat.name..": 0")
    local pl = lbl(pill, initText, 16, cat.no_text and (cat.color or C.White) or C.Gray, Enum.TextXAlignment.Center)
    pl.Size = UDim2.new(1,0,1,0)
    pl.Font = Enum.Font.GothamBold
    catTopLabels[i] = pl
end

local catBotLabels = {}
for i, cat in ipairs(CAT_BOT) do
    local w = cat.no_text and PILL_W_GAJAH or PILL_W
    local pill = mk("Frame",{Size=UDim2.new(0, w, 1, 0), BackgroundColor3=cat.bg or C.Card, BorderSizePixel=0, LayoutOrder=i, Parent=catRow2})
    corner(pill, 5) stroke(pill, C.Dim, 1)
    local initText = cat.no_text and cat.name or (cat.name..": 0")
    local pl = lbl(pill, initText, 16, cat.no_text and (cat.color or C.White) or C.Gray, Enum.TextXAlignment.Center)
    pl.Size = UDim2.new(1,0,1,0)
    pl.Font = Enum.Font.GothamBold
    catBotLabels[i] = pl
end

-- Backward compat
local catLabels = catTopLabels

-- v3.11: detail panel dihapus (gak guna). Sisain stub vars buat backward-compat sama _doBuildInvShow.
local detailTotal = {Text="", TextColor3=C.Teal}
local detailFav = {Text="", TextColor3=C.Gold}
local detailHigh = {Text="", TextColor3=C.Green}
local detailKG = {Text="", TextColor3=C.Blue}
local detailUnread = {Text="", TextColor3=C.Gray}

-- DIVIDER
div(content, 4)

-- REJOIN
local rejoinHeader = lbl(content, "REJOIN", 9, C.Teal) rejoinHeader.Size=UDim2.new(1,0,0,14) rejoinHeader.LayoutOrder=5

local rnBtn = btn(content, "Rejoin Now", 10, C.TDim, C.Teal)
rnBtn.Size = UDim2.new(1,0,0,24) rnBtn.LayoutOrder=6 stroke(rnBtn, C.Teal, 1.5)

local rejoinMinutes = savedState.rejoinMinutes or 30
cfgRow(content, "Interval (menit)", 7, rejoinMinutes, function(v)
    rejoinMinutes = math.max(1, math.min(120, v))
    saveState({autoRejoin=savedState.autoRejoin, rejoinMinutes=rejoinMinutes,
               rejoinDelay=savedState.rejoinDelay, serverHistory=savedState.serverHistory})
end)

-- Rejoin delay (countdown sebelum teleport, biar bisa cancel)
local rejoinDelay = tonumber(savedState.rejoinDelay) or 5
savedState.rejoinDelay = rejoinDelay
cfgRow(content, "Delay TP (detik)", 7.5, rejoinDelay, function(v)
    rejoinDelay = math.max(0, math.min(30, v))
    savedState.rejoinDelay = rejoinDelay
    saveState(savedState)
end)

-- PS link input (private server link buat balik setelah bounce ke public)
local psLink = savedState.psLink or ""
local psLinkCode = savedState.psLinkCode or ""

-- Parse PS link code dari URL
local function parsePsLink(link)
    if not link or link == "" then return "" end
    -- Match: privateServerLinkCode=XXX
    local code = link:match("privateServerLinkCode=([^&%s]+)")
    if code then return code end
    -- Match: bare code (just the part after =)
    if link:match("^[%w%-_]+$") and #link >= 20 then return link end
    return ""
end

do
    local r = mk("Frame",{Size=UDim2.new(1,0,0,26), BackgroundColor3=C.Card, BorderSizePixel=0, LayoutOrder=7.7, Parent=content})
    corner(r, 6) stroke(r, C.Dim, 1.1)
    local l = lbl(r, "PS Link", 9, C.Gray) l.Size = UDim2.new(0.25,0,1,0) l.Position = UDim2.new(0,8,0,0)
    local box = mk("TextBox",{
        Size=UDim2.new(0.7,-10,0,20), Position=UDim2.new(0.3,0,0.5,-10),
        BackgroundColor3=C.Panel, Text=psLink, PlaceholderText="paste link / kosong = OFF",
        TextColor3=C.White, PlaceholderColor3=C.Dim,
        Font=Enum.Font.Gotham, TextSize=9, TextScaled=false,
        TextXAlignment=Enum.TextXAlignment.Left, ClearTextOnFocus=false, Parent=r
    })
    corner(box, 5) stroke(box, C.Dim, 1)
    box:GetPropertyChangedSignal("Text"):Connect(function()
        psLink = box.Text
        psLinkCode = parsePsLink(psLink)
        savedState.psLink = psLink
        savedState.psLinkCode = psLinkCode
        saveState(savedState)
        if psLinkCode ~= "" then
            print("[ZenxInv] ✓ PS code OK: "..psLinkCode:sub(1, 12).."...")
        end
    end)
    -- Auto-parse on load
    if psLink ~= "" then
        psLinkCode = parsePsLink(psLink)
        savedState.psLinkCode = psLinkCode
        saveState(savedState)
    end
end

-- Toggle: Bounce via Public → balik ke PS
local bounceMode = savedState.bounceMode or false
local _, bcTog, bcTogStroke, bcStroke = togRow(content, "Bounce via Public", "Public dulu, terus balik ke PS", 7.8)
local function setBounceTog(v)
    bcTog.Text = v and "ON" or "OFF"
    bcTog.BackgroundColor3 = v and C.TDim or C.Panel
    bcTog.TextColor3 = v and C.Teal or C.Gray
    bcTogStroke.Color = v and C.Teal or C.Dim
    bcStroke.Color = v and C.Teal or C.Dim
end
setBounceTog(bounceMode)
bcTog.MouseButton1Click:Connect(function()
    bounceMode = not bounceMode
    savedState.bounceMode = bounceMode
    saveState(savedState)
    setBounceTog(bounceMode)
    print("[ZenxInv] Bounce mode: "..(bounceMode and "ON" or "OFF"))
end)

local _, arTog, arTogStroke, arStroke = togRow(content, "Auto Rejoin", "Rejoin otomatis sesuai interval", 8)
local cdLbl = lbl(content, "Auto Rejoin: OFF", 9, C.Gray, Enum.TextXAlignment.Center)
cdLbl.Size = UDim2.new(1,0,0,20) cdLbl.LayoutOrder=9 cdLbl.BackgroundColor3=C.Panel cdLbl.BackgroundTransparency=0
corner(cdLbl, 6) stroke(cdLbl, C.Dim, 1.1)

-- Server age label (workspace.DistributedGameTime = uptime detik sejak server start)
local ageLbl = lbl(content, "Server age: ?", 9, C.Gray, Enum.TextXAlignment.Center)
ageLbl.Size = UDim2.new(1,0,0,20) ageLbl.LayoutOrder=10
ageLbl.BackgroundColor3=C.Panel ageLbl.BackgroundTransparency=0
corner(ageLbl, 6) stroke(ageLbl, C.Dim, 1.1)

-- Debug label: nampilin info detection
local dbgLbl = lbl(content, "", 8, C.Gray, Enum.TextXAlignment.Center)
dbgLbl.Size = UDim2.new(1,0,0,32) dbgLbl.LayoutOrder=11
dbgLbl.BackgroundColor3=C.Panel dbgLbl.BackgroundTransparency=0
dbgLbl.TextWrapped = true
corner(dbgLbl, 6) stroke(dbgLbl, C.Dim, 1.1)

-- Build debug text dari analysis di atas
local function buildDbgText()
    local lines = {}
    table.insert(lines, "JobId: "..currentJobId:sub(1, 12))
    if rejoinStatus == "fresh" then
        table.insert(lines, "Status: FRESH (gak ada history)")
    elseif rejoinStatus == "new" then
        table.insert(lines, "Status: ✓ BARU (rejoin OK)")
    elseif rejoinStatus == "same" then
        table.insert(lines, "Status: ⚠ LAMA (retry #"..(retryCount or 0)..")")
    end
    return table.concat(lines, "\n")
end
dbgLbl.Text = ""
-- Akan di-update setelah rejoinStatus diset di bawah

-- Debug raw value label
local rawLbl = lbl(content, "", 8, C.Gray, Enum.TextXAlignment.Center)
rawLbl.Size = UDim2.new(1,0,0,16) rawLbl.LayoutOrder=12
rawLbl.BackgroundTransparency = 1
rawLbl.TextSize = 9

local function fmtAge(sec)
    sec = math.floor(sec)
    local h = math.floor(sec / 3600)
    local m = math.floor((sec % 3600) / 60)
    local s = sec % 60
    if h > 0 then
        return string.format("%dj %02dm %02ds", h, m, s)
    elseif m > 0 then
        return string.format("%dm %02ds", m, s)
    else
        return string.format("%ds", s)
    end
end

-- === SERVER HISTORY APPROACH ===
-- Karena DGT executor returns client-time, kita track JobId+timestamp di state file
-- Setiap script load, kalau JobId udah pernah kita liat → kita tau server udah running minimal sejak itu
local serverHistory = savedState.serverHistory or {}
local firstSeen = serverHistory[currentJobId]
if not firstSeen then
    firstSeen = os.time()
    serverHistory[currentJobId] = firstSeen
    savedState.serverHistory = serverHistory
    saveState(savedState)
    print("[ZenxInv] First time liat server "..currentJobId:sub(1,8).." → recorded "..firstSeen)
else
    print("[ZenxInv] Server ini udah pernah ke-record di "..firstSeen.." ("..(os.time()-firstSeen).." detik lalu)")
end

-- Cleanup old entries (>24 jam = anggap server udah mati)
do
    local now = os.time()
    local cleaned = {}
    for jid, ts in pairs(serverHistory) do
        if now - ts < 86400 then cleaned[jid] = ts end
    end
    serverHistory = cleaned
    savedState.serverHistory = cleaned
    saveState(savedState)
end

local function updateServerAge()
    -- Server age = os.time() - firstSeen (minimal age, server mungkin lebih tua)
    local age = os.time() - firstSeen
    local dgt = workspace.DistributedGameTime or 0
    local count = 0
    for _ in pairs(serverHistory) do count = count + 1 end
    ageLbl.Text = "🕒 Server age: "..fmtAge(age).." (min)"
    rawLbl.Text = string.format("[Tracked %d servers | DGT=%.0f]", count, dgt)
    -- Color
    local color = C.Green
    if age > 3600 then color = C.Red
    elseif age > 1800 then color = C.Gold end
    ageLbl.TextColor3 = color
end
updateServerAge()
task.spawn(function()
    while ageLbl.Parent do
        task.wait(1)
        pcall(updateServerAge)
    end
end)

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
    local catTopCounts = {} local catBotCounts = {}
    for i = 1, #CAT_TOP do catTopCounts[i] = 0 end
    for i = 1, #CAT_BOT do catBotCounts[i] = 0 end

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

                -- v3.15: pakai getPetBaseKG (handles cache lookup biar pet age tinggi gak salah kategori)
                local baseKG = getPetBaseKG(item)
                if baseKG then
                    -- v4.0: count for BOTH rows independently
                    for i, c in ipairs(CAT_TOP) do
                        if baseKG >= c.min and baseKG < c.max then
                            catTopCounts[i] = catTopCounts[i] + 1
                        end
                    end
                    for i, c in ipairs(CAT_BOT) do
                        if baseKG >= c.min and baseKG < c.max then
                            catBotCounts[i] = catBotCounts[i] + 1
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

    -- v4.0: render TOP row pills
    for i, lblWidget in ipairs(catTopLabels) do
        local cat = CAT_TOP[i]
        local count = catTopCounts[i]
        -- v4.9: no_text → tetep nama doang (mis "🐘")
        if cat.no_text then
            lblWidget.Text = cat.name
            lblWidget.TextColor3 = cat.color or C.White
        else
            lblWidget.Text = cat.name..": "..count
            lblWidget.TextColor3 = count > 0 and cat.color or C.Gray
        end
    end
    -- v4.0: render BOTTOM row pills
    for i, lblWidget in ipairs(catBotLabels) do
        local cat = CAT_BOT[i]
        local count = catBotCounts[i]
        if cat.no_text then
            lblWidget.Text = cat.name
            lblWidget.TextColor3 = cat.color or C.White
        else
            lblWidget.Text = cat.name..": "..count
            lblWidget.TextColor3 = count > 0 and cat.color or C.Gray
        end
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

-- v3.14: auto refresh tiap 5 detik
task.spawn(function()
    while true do
        task.wait(5)
        pcall(buildInvShow)
    end
end)

-- ============================================
-- REJOIN
-- ============================================
local isAR = false
local arTask = nil

-- Helper: fetch server list, find one different from current AND not in tried list
local function teleportToDifferentServer()
    local req = (syn and syn.request) or http_request or request
    if fluxus and fluxus.request then req = fluxus.request end
    if not req then
        cdLbl.Text = "✗ Executor gak support HTTP — pakai TP biasa"
        cdLbl.TextColor3 = C.Red
        print("[ZenxInv] ✗ no http function")
        task.wait(1.5)
        TS:Teleport(game.PlaceId, player)
        return
    end

    -- Try fetch dengan retry
    local data = nil
    for attempt = 1, 3 do
        cdLbl.Text = "Fetch server list (try "..attempt.."/3)..."
        local url = "https://games.roblox.com/v1/games/"..tostring(game.PlaceId).."/servers/Public?limit=100"
        local ok, resp = pcall(function() return req({Url=url, Method="GET"}) end)
        if ok and resp then
            local body = resp.Body or resp.body or ""
            local status = resp.StatusCode or resp.status_code or 0
            print("[ZenxInv] Fetch attempt "..attempt..": status="..tostring(status).." body_len="..#body)
            if #body > 0 then
                local okd, parsed = pcall(function() return HttpService:JSONDecode(body) end)
                if okd and parsed and parsed.data then
                    data = parsed
                    break
                else
                    print("[ZenxInv] JSON decode fail attempt "..attempt)
                end
            end
        else
            print("[ZenxInv] Fetch fail attempt "..attempt..": "..tostring(resp))
        end
        task.wait(1)
    end

    if not data then
        cdLbl.Text = "✗ Server list fetch GAGAL 3x"
        cdLbl.TextColor3 = C.Red
        print("[ZenxInv] ✗ semua fetch gagal — pakai TP biasa sebagai fallback")
        task.wait(2)
        TS:Teleport(game.PlaceId, player)
        return
    end

    print("[ZenxInv] ✓ Fetched "..#data.data.." servers")

    -- Build set of tried JobIds
    local triedSet = {}
    for _, j in ipairs(savedState.triedJobIds or {}) do triedSet[j] = true end

    local candidates = {}
    for _, s in ipairs(data.data) do
        if s.id ~= currentJobId and not triedSet[s.id] and (s.playing or 0) < (s.maxPlayers or 30) then
            table.insert(candidates, s)
        end
    end
    print("[ZenxInv] Candidates (after filter tried+full): "..#candidates)

    if #candidates == 0 then
        print("[ZenxInv] Semua server udah dicoba — reset list & retry")
        savedState.triedJobIds = {currentJobId}
        saveState(savedState)
        for _, s in ipairs(data.data) do
            if s.id ~= currentJobId and (s.playing or 0) < (s.maxPlayers or 30) then
                table.insert(candidates, s)
            end
        end
    end

    if #candidates == 0 then
        cdLbl.Text = "✗ Gak ada server lain available"
        cdLbl.TextColor3 = C.Red
        task.wait(2)
        TS:Teleport(game.PlaceId, player)
        return
    end

    -- Pick first candidate
    local target = candidates[1]
    cdLbl.Text = string.format("✓ Hop %d/%d players (JobId %s)",
        target.playing or 0, target.maxPlayers or 30, target.id:sub(1, 8))
    cdLbl.TextColor3 = C.Teal
    print(string.format("[ZenxInv] ✓ TeleportToPlaceInstance to %s (%d/%d players)",
        target.id:sub(1,12), target.playing or 0, target.maxPlayers or 30))
    task.wait(0.5)
    TS:TeleportToPlaceInstance(game.PlaceId, target.id, player)
end

-- Save JobId before teleport (so on reload we can compare)
-- Queue current script to auto-rerun after teleport (Delta/Synapse/Krnl support)
local function tryQueueOnTeleport()
    -- Try various executor APIs
    local qot = queueonteleport or queue_on_teleport or (syn and syn.queue_on_teleport)
    if not qot then
        print("[ZenxInv] queueonteleport gak ada di executor — kamu harus re-run manual setelah TP")
        return false
    end
    -- Embed source kode pendek yg re-load script lengkap
    -- IMPORTANT: ganti URL ini ke source script kamu, atau pakai loadfile lokal
    local reloadSrc = [[
        task.wait(2)
        -- Re-run script (executor harus support local file atau URL)
        -- Edit baris ini sesuai cara loading script kamu:
        -- loadstring(game:HttpGet("URL_SCRIPT_KAMU"))()
        print("[ZenxInv] post-teleport queued: silahkan re-run script manual atau set URL")
    ]]
    local ok, err = pcall(function() qot(reloadSrc) end)
    if ok then
        print("[ZenxInv] ✓ queueonteleport set — script akan auto-run setelah TP")
        return true
    else
        print("[ZenxInv] queueonteleport gagal: "..tostring(err))
        return false
    end
end

-- Delay countdown before actual teleport (configurable via savedState.rejoinDelay)
local rejoinCancelled = false
local function markRejoinAndTeleport(useDifferent, isRetry)
    -- 1. Build state
    savedState.lastJobId = currentJobId
    savedState.rejoinTime = os.time()
    if isRetry then
        savedState.retryCount = (savedState.retryCount or 0) + 1
    else
        savedState.retryCount = 0
        savedState.triedJobIds = {currentJobId}
    end

    -- 2. Save state to file
    saveState(savedState)

    -- 3. VERIFY save by reading back
    local verify = loadState()
    if verify and verify.lastJobId == currentJobId then
        print("[ZenxInv] ✓ State saved: lastJobId="..currentJobId:sub(1,12).."... retry="..tostring(savedState.retryCount))
    else
        print("[ZenxInv] ✗ State save FAIL! Detection mungkin gak akan jalan")
    end

    -- 4. Queue auto-rerun
    tryQueueOnTeleport()

    -- 5. Countdown sebelum teleport
    local delaySec = tonumber(savedState.rejoinDelay) or 5
    rejoinCancelled = false
    for i = delaySec, 1, -1 do
        if rejoinCancelled then
            print("[ZenxInv] Rejoin CANCELLED")
            cdLbl.Text = "Rejoin cancelled"
            cdLbl.TextColor3 = C.Gold
            rnBtn.Text = "Rejoin Now"
            return
        end
        cdLbl.Text = "🚀 Rejoin dalam "..i.." detik (klik lagi buat cancel)"
        cdLbl.TextColor3 = C.Teal
        rnBtn.Text = "Cancel ("..i..")"
        task.wait(1)
    end

    -- 6. Teleport
    cdLbl.Text = "Teleporting..."
    if bounceMode and psLinkCode ~= "" then
        -- BOUNCE MODE: set flag biar setelah landing di public, langsung TP ke PS
        savedState.bouncePending = true
        savedState.bouncePsCode = psLinkCode
        saveState(savedState)
        print("[ZenxInv] BOUNCE: TP ke public dulu, lalu balik ke PS")
        TS:Teleport(game.PlaceId, player)  -- public TP
    elseif useDifferent then
        teleportToDifferentServer()
    else
        TS:Teleport(game.PlaceId, player)
    end
end

local rejoinInProgress = false
rnBtn.MouseButton1Click:Connect(function()
    if rejoinInProgress then
        rejoinCancelled = true
        rejoinInProgress = false
        return
    end
    rejoinInProgress = true
    rnBtn.Text = "Rejoining..."
    task.spawn(function()
        -- DEFAULT: pakai TeleportToPlaceInstance ke server beda (biar gak balik ke same server)
        markRejoinAndTeleport(true, false)
        rejoinInProgress = false
    end)
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
    saveState({autoRejoin=true, rejoinMinutes=rejoinMinutes,
               lastJobId=savedState.lastJobId, rejoinTime=savedState.rejoinTime})
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
                -- Save JobId before teleport
                local currentSt = loadState() or {}
                currentSt.lastJobId = currentJobId
                currentSt.rejoinTime = os.time()
                saveState(currentSt)
                tryQueueOnTeleport()
                -- Countdown sebelum TP (juga pakai rejoinDelay)
                local delaySec = rejoinDelay
                for j = delaySec, 1, -1 do
                    if not isAR then return end
                    cdLbl.Text = "🚀 Auto-rejoin dalam "..j.." detik"
                    cdLbl.TextColor3 = C.Gold
                    task.wait(1)
                end
                cdLbl.Text = "Teleporting..."
                TS:Teleport(game.PlaceId, player)
            end
        end
    end)
end

arTog.MouseButton1Click:Connect(function()
    if isAR then stopAR() else startAR() end
end)

-- v3.8: expand/collapse logic
local expanded = false
local function setExpanded(state)
    expanded = state
    -- Hide/show rejoin elements (LayoutOrder >= 5 = rejoin section)
    for _, child in ipairs(content:GetChildren()) do
        if child:IsA("Frame") or child:IsA("TextLabel") or child:IsA("TextButton") then
            local lo = child.LayoutOrder
            if lo and lo >= 5 then
                child.Visible = state
            end
        end
    end
    -- Resize GUI
    main.Size = UDim2.new(0, GUI_W, 0, state and GUI_H_FULL or GUI_H_COMPACT)
    -- Update + button
    expBtn.Text = state and "-" or "+"
    expBtn.BackgroundColor3 = state and C.Panel or C.TDim
    expBtn.TextColor3 = state and C.Gray or C.Teal
    local s = expBtn:FindFirstChildOfClass("UIStroke")
    if s then s.Color = state and C.Dim or C.Teal end
end
setExpanded(false)  -- v3.13: start collapsed (cuma top section)
expBtn.MouseButton1Click:Connect(function() setExpanded(not expanded) end)

-- Auto resume Auto Rejoin
if savedState.autoRejoin == true then
    print("[ZenxInv] resume Auto Rejoin ON")
    task.spawn(function() task.wait(2) startAR() end)
end

-- ===== REJOIN STATUS DISPLAY + AUTO-RETRY =====
-- Update debug label dengan hasil detection
dbgLbl.Text = buildDbgText()
if rejoinStatus == "fresh" then
    dbgLbl.TextColor3 = C.Gray
elseif rejoinStatus == "new" then
    dbgLbl.TextColor3 = C.Green
elseif rejoinStatus == "same" then
    dbgLbl.TextColor3 = C.Red
end

-- Status: fresh (first load) | new (rejoin sukses, server beda) | same (rejoin gagal, server sama)
if rejoinStatus == "new" then
    cdLbl.Text = "✓ Server BARU (rejoin OK)"
    cdLbl.TextColor3 = C.Green
    task.spawn(function()
        task.wait(8)
        if not isAR then cdLbl.Text = "Auto Rejoin: OFF" cdLbl.TextColor3 = C.Gray end
    end)
elseif rejoinStatus == "same" then
    local nextRetry = (retryCount or 0) + 1
    cdLbl.Text = "⚠ Server LAMA — Retry #"..nextRetry
    cdLbl.TextColor3 = C.Red
    local retryDelay = tonumber(savedState.rejoinDelay) or 5
    print("[ZenxInv] Rejoin gagal — auto-retry #"..nextRetry.." dalam "..retryDelay.." detik")
    print("[ZenxInv] Tried so far: "..#triedJobIds.." servers")
    task.spawn(function()
        for j = retryDelay, 1, -1 do
            cdLbl.Text = "⚠ Retry #"..nextRetry.." dalam "..j.." detik"
            task.wait(1)
        end
        markRejoinAndTeleport(true, true)
    end)
end

-- ===== BOUNCE RETURN TO PS =====
-- Kalau script load detect bouncePending, langsung TP balik ke PS
if savedState.bouncePending and savedState.bouncePsCode and savedState.bouncePsCode ~= "" then
    local psCode = savedState.bouncePsCode
    print("[ZenxInv] BOUNCE: landed in public, prep TP back to PS")
    savedState.bouncePending = false
    saveState(savedState)
    cdLbl.Text = "🔁 Bouncing back to PS..."
    cdLbl.TextColor3 = C.Gold
    task.spawn(function()
        local delaySec = tonumber(savedState.rejoinDelay) or 5
        for i = delaySec, 1, -1 do
            cdLbl.Text = "🔁 TP ke PS dalam "..i.." detik..."
            task.wait(1)
        end
        cdLbl.Text = "Teleporting ke PS..."
        tryQueueOnTeleport()
        local ok, err = pcall(function()
            TS:TeleportToPrivateServer(game.PlaceId, psCode, {player})
        end)
        if not ok then
            print("[ZenxInv] ✗ TeleportToPrivateServer fail: "..tostring(err))
            cdLbl.Text = "✗ PS TP fail — code salah?"
            cdLbl.TextColor3 = C.Red
        end
    end)
end

print("==== ZenxInv "..SCRIPT_VERSION.." READY ====")
