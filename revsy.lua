-- ============================================
--   ZENX HUB V2.0 | GROW A GARDEN
--   Visual Ringan + Semua Fitur
-- ============================================

local Players = game:GetService("Players")
local UIS = game:GetService("UserInputService")
local HS = game:GetService("HttpService")
local RS = game:GetService("ReplicatedStorage")
local TS = game:GetService("TeleportService")
local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- ============================================
-- SAVE / LOAD
-- ============================================
local username = player.Name
local SAVE_FILE = "zenxhub_"..username..".json"
local defaultSettings = {rejoinMinutes=30, autoRejoin=false}

local function saveSettings(s)
    pcall(function() writefile(SAVE_FILE, HS:JSONEncode(s)) end)
end
local function loadSettings()
    local ok,r = pcall(function()
        if isfile(SAVE_FILE) then return HS:JSONDecode(readfile(SAVE_FILE)) end
    end)
    if ok and r then return r end
    return defaultSettings
end
local cfg = loadSettings()

if playerGui:FindFirstChild("ZenxHub") then playerGui.ZenxHub:Destroy() end
if playerGui:FindFirstChild("ZenxHubLogo") then playerGui.ZenxHubLogo:Destroy() end

-- ============================================
-- THEME (ringan)
-- ============================================
local C = {
    BG    = Color3.fromRGB(15,15,15),
    Side  = Color3.fromRGB(19,19,19),
    Card  = Color3.fromRGB(25,25,25),
    Panel = Color3.fromRGB(21,21,21),
    Acc   = Color3.fromRGB(220,175,0),
    ADim  = Color3.fromRGB(32,28,0),
    White = Color3.fromRGB(225,225,225),
    Gray  = Color3.fromRGB(120,120,120),
    Dim   = Color3.fromRGB(55,55,55),
    Green = Color3.fromRGB(70,190,90),
    GDim  = Color3.fromRGB(12,30,16),
    Red   = Color3.fromRGB(200,60,60),
    RDim  = Color3.fromRGB(35,10,10),
    Gold  = Color3.fromRGB(220,160,0),
}

local function mk(cls, props)
    local o = Instance.new(cls)
    for k,v in pairs(props) do o[k]=v end
    return o
end
local function corner(p,r)
    return mk("UICorner",{CornerRadius=UDim.new(0,r or 7),Parent=p})
end
local function stroke(p,col,th)
    return mk("UIStroke",{Color=col or C.Acc,Thickness=th or 1.5,Parent=p})
end
local function lbl(p,txt,ts,col,xa)
    local l = mk("TextLabel",{
        BackgroundTransparency=1, Text=txt,
        TextColor3=col or C.White, Font=Enum.Font.GothamBold,
        TextSize=ts or 11, TextScaled=false,
        TextXAlignment=xa or Enum.TextXAlignment.Left, Parent=p
    })
    return l
end
local function btn(p,txt,ts,bg,tc)
    local b = mk("TextButton",{
        BackgroundColor3=bg or C.Card, Text=txt,
        TextColor3=tc or C.White, Font=Enum.Font.GothamBold,
        TextSize=ts or 11, TextScaled=false,
        AutoButtonColor=false, Parent=p
    })
    corner(b,7)
    return b
end
local function tbox(p,ph,ts)
    local t = mk("TextBox",{
        BackgroundColor3=C.Panel, Text="",
        PlaceholderText=ph or "", PlaceholderColor3=C.Dim,
        TextColor3=C.White, Font=Enum.Font.Gotham,
        TextSize=ts or 11, TextScaled=false,
        TextXAlignment=Enum.TextXAlignment.Left,
        ClearTextOnFocus=false, Parent=p
    })
    corner(t,6)
    stroke(t,C.Dim,1.2)
    return t
end
local function scrollArea(parent, x, y, w, h)
    local a = mk("ScrollingFrame",{
        Size=UDim2.new(w or 1,-4,h or 1,-34),
        Position=UDim2.new(x or 0,2,y or 0,34),
        BackgroundTransparency=1,
        ScrollBarThickness=3,
        ScrollBarImageColor3=C.Acc,
        CanvasSize=UDim2.new(0,0,0,0),
        AutomaticCanvasSize=Enum.AutomaticSize.Y,
        Visible=false, Parent=parent
    })
    mk("UIListLayout",{SortOrder=Enum.SortOrder.LayoutOrder,Padding=UDim.new(0,4),Parent=a})
    mk("UIPadding",{PaddingTop=UDim.new(0,4),PaddingLeft=UDim.new(0,3),PaddingRight=UDim.new(0,5),Parent=a})
    return a
end
local function secHead(parent,txt,order)
    local l = lbl(parent,txt,10,C.Gray,Enum.TextXAlignment.Left)
    l.Size = UDim2.new(1,-4,0,16)
    l.LayoutOrder = order
    return l
end
local function divLine(parent,order)
    local d = mk("Frame",{
        Size=UDim2.new(1,-4,0,1),
        BackgroundColor3=C.Dim,
        BorderSizePixel=0,
        LayoutOrder=order,
        Parent=parent
    })
    return d
end

-- ============================================
-- DATA PET GAG (lengkap)
-- ============================================
local ALL_PETS = {
    -- Common
    "Ant","Bee","Beetle","Butterfly","Cat","Chicken","Chipmunk",
    "Crow","Dog","Duck","Frog","Goose","Guinea Pig","Hamster",
    "Hedgehog","Ladybug","Mouse","Owl","Pigeon","Rabbit","Rooster",
    "Snail","Squirrel","Turtle","Worm","Brown Mouse","Giant Ant",
    "Red Giant Ant","Bat","Mole",
    -- Uncommon
    "Barn Owl","Bear Bee","Capybara","Chimpanzee","Crocodile",
    "Donkey","Ferret","Flamingo","Goat","Gorilla","Hippo",
    "Jerboa","Llama","Mallard","Marmot","Meerkat","Messenger Pigeon",
    "Monkey","Moose","Orchid Mantis","Orange Tabby","Ostrich",
    "Otter","Oxpecker","Pack Bee","Panda","Parrot","Pig",
    "Praying Mantis","Raccoon","Sheep","Spring Bee","Toucan",
    "Weasel","Axolotl","Pancake Mole","Mochi Mouse","Marshmallow Lamb",
    -- Rare
    "Albino Peacock","Beaver","Blue Whale","Cheetah","Eagle",
    "Fox","Giant Scorpion","Goblin Gardener","Golden Piggy",
    "Hazehound","Hootsie Roll","Koi","Lyrebird","Mimic Octopus",
    "Night Owl","Nyala","Orangutan","Pack Mule","Peacock","Peryton",
    "Red Fox","Red Panda","Ruby Squid","Seal","Swan","UFO Seal",
    "Mantis Shrimp","Marmot","Lobster Thermidor","Lemon Lion",
    "Luminous Sprite","Kodama","Kiwi","Kappa",
    -- Legendary
    "Brontosaurus","Cerberus","Chimera","Diamond Panther",
    "Disco Bee","Dragonfly","Easter Bunny","Giant Scorpion",
    "Kitsune","Lion","Lioness","Moon Cat","Phoenix","Queen Bee",
    "Space Squirrel","Tiger","T-Rex","Triceratops","White Tiger",
    "Wind Wyvern","Spinosaurus","Dilophosaurus","Velociraptor",
    "Pterodactyl","Ankylosaurus","Stegosaurus","Parasaurolophus",
    "Pachycephalosaurus","Blood Hedgehog","French Fry Ferret",
    "Golem","Headless Horseman","Mummy","Nightcrawler",
    "Ascended Dragonfly","Diamond Dragonfly","Corrupt Kitsune",
    "Disco Dragonfly","Nightmare Koi","Venom Mimic Octopus",
    -- Mythical/Divine
    "Black Swan","Blue Lobster","Calico","Elephant","Giraffe",
    "Hippopotamus","Kodama","Leopard","Moose","Ostrich","Panda",
    "Puma","Rhino","Snow Leopard","Zebra","Mizuchi","Maneki-neko",
    "Mandrake","Mallard","Meerkat","Monk","New Year's Bird",
    "New Year's Chimp","New Year's Dragon","Nihonzaru","Nutcracker",
    "Orchid Mantis","Orangutan","Pack Mule","Panda","Penguin",
    "Polar Bear","Porcupine","Quokka","Rabbit","Raccoon Dog",
    "Ram","Raven","Red Deer","Reindeer","Rhino","Roadrunner",
    "Robin","Rooster","Samoyed","Sea Horse","Sea Otter","Seal",
    "Sheep","Shiba Inu","Sloth","Snow Leopard","Snow Rabbit",
    "Snowy Owl","Spider","Starfish","Stork","Swan","Tapir",
    "Toad","Toucan","Turkey","Turtle","Walrus","Warthog",
    "Weasel","Wolf","Wolverine","Wombat","Woodpecker","Yak",
    "Zebra","Alpaca","Armadillo","Bison","Boar","Buffalo",
    "Camel","Caribou","Cassowary","Cheetah","Cobra","Condor",
    "Coyote","Crane","Crocodile","Dingo","Eagle","Echidna",
    "Elk","Emu","Falcon","Fennec Fox","Gazelle","Gecko",
    "Gopher","Grizzly Bear","Hare","Hawk","Hedgehog","Heron",
    "Hyena","Iguana","Impala","Jaguar","Kangaroo","Koala",
    "Komodo Dragon","Lemur","Lynx","Manatee","Manta Ray",
    "Meerkat","Mongoose","Monitor Lizard","Narwhal","Okapi",
    -- Event/Special
    "Brontosaurus","Headless Horseman","Mummy","Werewolf",
    "Vampire Bat","Ghost","Witch Cat","Pumpkin Rat","Krampus",
    "Nutcracker","Mistletoad","Hootsie Roll","Lobster Thermidor",
    "Pancake Mole","Tanchozuru","Kappa","Mizuchi","Kodama",
    "Maneki-neko","New Year's Dragon","Nihonzaru","Luminous Sprite",
    "Lemon Lion","Mantis Shrimp","Mochi Mouse","Marshmallow Lamb",
    "Junkbot","Mallard","Moose","Night Owl","Nightcrawler",
    "Orchid Mantis","Pack Mule","Pancake Mole","Penguin",
    "Peacock","Peryton","Phoenix","Polar Bear","Porcupine",
    "Quokka","Ram","Reindeer","Robin","Samoyed","Sea Horse",
    "Shiba Inu","Sloth","Snowy Owl","Stork","Tapir","Toad",
    "Turkey","Walrus","Warthog","Wombat","Woodpecker","Yak",
    "Lich","Cerberus","Wind Wyvern","Chimera","Kitsune",
    "Corrupt Kitsune","Ascended Dragonfly","Diamond Dragonfly",
    "Disco Dragonfly","Blood Hedgehog","French Fry Ferret",
    "Golem","Nightmare Koi","Venom Mimic Octopus","UFO Seal",
    "Ruby Squid","Diamond Panther","Giant Scorpion","Blue Whale",
    "Moon Cat","Space Squirrel","Queen Bee","Disco Bee",
    "Bear Bee","Pack Bee","Spring Bee","Dragonfly","Butterfly",
    "Ladybug","Praying Mantis","Giant Ant","Red Giant Ant",
    "Brown Mouse","Mole","Bat","Crow","Pigeon","Owl","Duck",
    "Goose","Flamingo","Swan","Black Swan","Eagle","Hawk",
    "Falcon","Condor","Crane","Heron","Stork","Robin",
    "Woodpecker","Toucan","Parrot","Lyrebird","Peacock",
}

-- Bersihkan duplikat dan sort
local petSet = {}
local PETS = {}
for _,v in ipairs(ALL_PETS) do
    if not petSet[v] then petSet[v]=true table.insert(PETS,v) end
end
table.sort(PETS)

-- ============================================
-- DATA MUTASI PET GAG (lengkap)
-- ============================================
local ALL_MUTATIONS = {
    "(Semua / Tidak ada filter)",
    -- Size mutations
    "Tiny","Jumbo","Mega","Huge","Giant","Titanic",
    -- Color/Visual mutations
    "Rainbow","Golden","Shiny","Gilded","Prismatic","Crystal",
    "Luminous","Glimmering","Aurora","Disco","Choc","Spotty",
    "Gilded Choc","Black","White","Silver","Azure","Umbral",
    "Ghostly","Verdant","Plasma","Mirage",
    -- Elemental mutations
    "Frozen","Burnt","Fried","Cooked","Peppermint","Venom",
    "Radioactive","Corrupted","Nightmare","Windstruck",
    "Stormcharged","Blitzshock","Subzero","Lightcycle",
    "Flaming","Infernal","Molten","Scorched","Glacial",
    -- Nature mutations
    "Pollinated","Aromatic","Verdant","Lush","Bloom",
    "Everchanted","Tranquil","Dawnbound","Heavenly",
    "Cloudtouched","HoneyGlazed","Moonlit","Paradisal",
    -- Dark/Mystic mutations
    "Ornamented","Ascended","Dawnbound","Shadowbound",
    "Abyssal","Necrotic","Maelstrom","Astral","Celestial",
    "Warped","Twisted","Gloom","Moonbled","Slashbound",
    "Friendbound","Beanbound","Graceful","Enchanted",
    "Gourmet","Spooky","Brainrot","Fortune","Sandy",
    "Ceramic","Contagion","Alienlike","Foxfire",
    "Jackpot","Junkshock","AncientAmber","Enlightened",
    "Corrosive","Gnomed","Infected","Zombified","Acidic",
    "Eclipsed","Static","Bloodlit","Twisted","Drenched",
    "Boil","OilBoil","Sauce","Pasta","Meatball","Gourmet",
    "Cyclonic","Meteoric","Galactic","Voidtouched",
    "HarmonisedChakra","FoxfireChakra","Chakra","Desolate",
    "Blackout","Luminous2","Umbral2","Azure2","Flaming2",
}

-- Bersihkan duplikat mutasi
local mutSet = {}
local MUTATIONS = {}
for _,v in ipairs(ALL_MUTATIONS) do
    if not mutSet[v] then mutSet[v]=true table.insert(MUTATIONS,v) end
end

-- ============================================
-- PARSE PET
-- ============================================
local function parsePet(item)
    local name = item:GetAttribute("f") or ""
    if name == "" then
        name = item.Name:match("^(.-)%s*%[") or item.Name
        name = name:gsub("%s+$","")
    end
    local kg = tonumber(item.Name:match("%[([%d%.]+)%s*[Kk][Gg]%]"))
    local age = nil
    for _,pat in ipairs({"%[Age%s+(%d+)%]","%[Age(%d+)%]","Age%s+(%d+)"}) do
        local f = item.Name:match(pat)
        if f then age=tonumber(f) break end
    end
    local fav = item:GetAttribute("d") == true
    local mutation = "(Semua / Tidak ada filter)"
    for _,mut in ipairs(MUTATIONS) do
        if mut ~= "(Semua / Tidak ada filter)" and item.Name:find(mut,1,true) then
            mutation = mut break
        end
    end
    return name, kg, age or 1, fav, mutation
end

local function isPet(item)
    return item:FindFirstChild("PetToolLocal") or item:FindFirstChild("PetToolServer")
end

local function petValid60(item)
    if not isPet(item) then return false,nil end
    local name,kg,age = parsePet(item)
    if not kg then return false,name end
    return (kg*110/(age+10))>=60, name
end

-- ============================================
-- LOGO Z
-- ============================================
local LogoGui = mk("ScreenGui",{Name="ZenxHubLogo",ResetOnSpawn=false,Parent=playerGui})
local LogoBtn = mk("TextButton",{
    Size=UDim2.new(0,46,0,46),
    Position=UDim2.new(0,12,0.5,-23),
    BackgroundColor3=C.BG, Text="Z",
    TextColor3=C.Acc, Font=Enum.Font.GothamBold,
    TextSize=20, TextScaled=false,
    Active=true, Draggable=true,
    Visible=false, ZIndex=10, Parent=LogoGui
})
corner(LogoBtn,11) stroke(LogoBtn,C.Acc,2)
LogoBtn.MouseEnter:Connect(function() LogoBtn.BackgroundColor3=C.ADim end)
LogoBtn.MouseLeave:Connect(function() LogoBtn.BackgroundColor3=C.BG end)

-- ============================================
-- MAIN GUI
-- ============================================
local ScreenGui = mk("ScreenGui",{Name="ZenxHub",ResetOnSpawn=false,Parent=playerGui})

local Main = mk("Frame",{
    Size=UDim2.new(0,720,0,500),
    Position=UDim2.new(0.5,-360,0.5,-250),
    BackgroundColor3=C.BG, BorderSizePixel=0,
    Active=true, Draggable=true, Parent=ScreenGui
})
corner(Main,11) stroke(Main,C.Acc,2)

-- Resize handle
local RH = btn(Main,"◢",9,C.ADim,C.Acc)
RH.Size=UDim2.new(0,16,0,16)
RH.Position=UDim2.new(1,-17,1,-17)
RH.ZIndex=10
local resizing,rsStart,szStart=false,Vector2.new(),Vector2.new()
RH.MouseButton1Down:Connect(function()
    resizing=true
    rsStart=UIS:GetMouseLocation()
    szStart=Vector2.new(Main.AbsoluteSize.X,Main.AbsoluteSize.Y)
end)
UIS.InputChanged:Connect(function(i)
    if resizing and i.UserInputType==Enum.UserInputType.MouseMovement then
        local d=UIS:GetMouseLocation()-rsStart
        Main.Size=UDim2.new(0,math.max(540,szStart.X+d.X),0,math.max(400,szStart.Y+d.Y))
    end
end)
UIS.InputEnded:Connect(function(i)
    if i.UserInputType==Enum.UserInputType.MouseButton1 then resizing=false end
end)

-- ============================================
-- TITLE BAR
-- ============================================
local TB = mk("Frame",{
    Size=UDim2.new(1,0,0,36),
    BackgroundColor3=C.Panel,
    BorderSizePixel=0, Parent=Main
})
corner(TB,11)
mk("Frame",{Size=UDim2.new(1,0,0,1.5),Position=UDim2.new(0,0,1,-1.5),BackgroundColor3=C.Acc,BorderSizePixel=0,Parent=TB})

local ZBadge = mk("TextLabel",{
    Size=UDim2.new(0,24,0,24),Position=UDim2.new(0,7,0.5,-12),
    BackgroundColor3=C.ADim,Text="Z",TextColor3=C.Acc,
    Font=Enum.Font.GothamBold,TextSize=12,TextScaled=false,
    TextXAlignment=Enum.TextXAlignment.Center,Parent=TB
})
corner(ZBadge,6) stroke(ZBadge,C.Acc,1.3)

local TT=lbl(TB,"ZENX HUB",12,C.Acc)
TT.Size=UDim2.new(0,90,1,0) TT.Position=UDim2.new(0,36,0,0)
TT.TextXAlignment=Enum.TextXAlignment.Left

local UT=lbl(TB,"· "..username,10,C.Gray)
UT.Size=UDim2.new(0,180,1,0) UT.Position=UDim2.new(0,128,0,0)
UT.TextXAlignment=Enum.TextXAlignment.Left

local MinBtn=btn(TB,"−",14,C.ADim,C.Acc)
MinBtn.Size=UDim2.new(0,24,0,24) MinBtn.Position=UDim2.new(1,-54,0.5,-12)
stroke(MinBtn,C.Acc,1.3)

local CloseBtn=btn(TB,"✕",11,C.RDim,C.Red)
CloseBtn.Size=UDim2.new(0,24,0,24) CloseBtn.Position=UDim2.new(1,-27,0.5,-12)
stroke(CloseBtn,C.Red,1.3)

-- ============================================
-- SIDEBAR (posisi manual, tanpa UIListLayout)
-- ============================================
local Sidebar = mk("Frame",{
    Size=UDim2.new(0,145,1,-36),
    Position=UDim2.new(0,0,0,36),
    BackgroundColor3=C.Side,
    BorderSizePixel=0, Parent=Main
})
mk("Frame",{
    Size=UDim2.new(0,1.5,1,0),Position=UDim2.new(1,-1.5,0,0),
    BackgroundColor3=C.Acc,BackgroundTransparency=0.7,
    BorderSizePixel=0,Parent=Sidebar
})

-- Kotak 60kg+ di ATAS sidebar
local PCBtn = mk("TextButton",{
    Size=UDim2.new(1,-16,0,58),
    Position=UDim2.new(0,8,0,8),
    BackgroundColor3=C.Panel,Text="",
    AutoButtonColor=false,ZIndex=2,Parent=Sidebar
})
corner(PCBtn,9)
local pcStroke = stroke(PCBtn,C.Gold,1.8)

local pcIco=lbl(PCBtn,"🐾",16,C.Gold)
pcIco.Size=UDim2.new(0,26,0,26) pcIco.Position=UDim2.new(0,5,0.5,-13)
pcIco.TextXAlignment=Enum.TextXAlignment.Center pcIco.ZIndex=3

local pcTitle=lbl(PCBtn,"60kg+ Age 100",9,C.Gray)
pcTitle.Size=UDim2.new(0,90,0,16) pcTitle.Position=UDim2.new(0,35,0,6) pcTitle.ZIndex=3

local PetCountNum=lbl(PCBtn,"0",18,C.Gold)
PetCountNum.Size=UDim2.new(0,90,0,24) PetCountNum.Position=UDim2.new(0,35,0,24)
PetCountNum.Font=Enum.Font.GothamBold PetCountNum.ZIndex=3

-- Sidebar buttons posisi manual (di bawah kotak 60kg+)
local sideData = {
    {text="AUTO LVL",   y=74},
    {text="MISC",       y=116},
    {text="AUTO GIFT",  y=158},
}
local sideBtns = {}
local pcActive = false

local function resetSideBtns()
    for _,b in ipairs(sideBtns) do
        b.TextColor3=C.Gray b.BackgroundColor3=C.Card
        local s=b:FindFirstChildWhichIsA("UIStroke")
        if s then s.Color=C.Dim s.Thickness=1.2 end
    end
    pcStroke.Color=C.Gold pcStroke.Thickness=1.8
    pcActive=false
end

for i,data in ipairs(sideData) do
    local b=btn(Sidebar,data.text,11,C.Card,C.Gray)
    b.Size=UDim2.new(1,-16,0,34)
    b.Position=UDim2.new(0,8,0,data.y)
    b.TextXAlignment=Enum.TextXAlignment.Center
    stroke(b,C.Dim,1.2)
    sideBtns[i]=b
end

-- ============================================
-- CONTENT AREA (kanan sidebar, bawah title)
-- X=147 agar tidak overlap sidebar
-- ============================================
local CONTENT_X = 147
local CONTENT_Y = 38
local TAB_H = 30

-- Tab bar (khusus AUTO LVL)
local TabBar = mk("Frame",{
    Size=UDim2.new(1,-CONTENT_X-4,0,TAB_H),
    Position=UDim2.new(0,CONTENT_X+2,0,CONTENT_Y+2),
    BackgroundTransparency=1, Visible=false, Parent=Main
})
mk("UIListLayout",{
    FillDirection=Enum.FillDirection.Horizontal,
    SortOrder=Enum.SortOrder.LayoutOrder,
    Padding=UDim.new(0,4),Parent=TabBar
})

-- Scroll areas
local function makeArea()
    local a = mk("ScrollingFrame",{
        Size=UDim2.new(1,-CONTENT_X-6,1,-CONTENT_Y-TAB_H-46),
        Position=UDim2.new(0,CONTENT_X+3,0,CONTENT_Y+TAB_H+4),
        BackgroundTransparency=1,
        ScrollBarThickness=3,
        ScrollBarImageColor3=C.Acc,
        CanvasSize=UDim2.new(0,0,0,0),
        AutomaticCanvasSize=Enum.AutomaticSize.Y,
        Visible=false, Parent=Main
    })
    mk("UIListLayout",{SortOrder=Enum.SortOrder.LayoutOrder,Padding=UDim.new(0,4),Parent=a})
    mk("UIPadding",{PaddingTop=UDim.new(0,4),PaddingLeft=UDim.new(0,3),PaddingRight=UDim.new(0,5),Parent=a})
    return a
end

-- Areas per tab AUTO LVL
local LvlArea  = makeArea()  -- Auto Leveling
local SwapArea = makeArea()  -- Auto Swap
local MiscArea = makeArea()
local GiftArea = makeArea()
local PetListArea = makeArea()

-- Bottom bar
local BotBar = mk("Frame",{
    Size=UDim2.new(1,-CONTENT_X-4,0,38),
    Position=UDim2.new(0,CONTENT_X+2,1,-42),
    BackgroundColor3=C.Panel, BorderSizePixel=0, Parent=Main
})
corner(BotBar,7) stroke(BotBar,C.Acc,1.3)

local RunBtn=btn(BotBar,"⚡ RUNNING",11,C.ADim,C.Acc)
RunBtn.Size=UDim2.new(0,112,0,26) RunBtn.Position=UDim2.new(0,6,0.5,-13)
stroke(RunBtn,C.Acc,1.8)

local StopBtn=btn(BotBar,"STOP",11,C.RDim,C.Red)
StopBtn.Size=UDim2.new(0,72,0,26) StopBtn.Position=UDim2.new(0,122,0.5,-13)
stroke(StopBtn,C.Red,1.8)

-- ============================================
-- AUTO LVL TABS
-- ============================================
local lvlTabNames = {"Auto Leveling","Auto Swap"}
local lvlTabBtns = {}
local lvlAreas = {LvlArea, SwapArea}
local activeLvlTab = 1

local function switchLvlTab(idx)
    activeLvlTab = idx
    for i,b in ipairs(lvlTabBtns) do
        local s=b:FindFirstChildWhichIsA("UIStroke")
        if i==idx then
            b.TextColor3=C.Acc b.BackgroundColor3=C.ADim
            if s then s.Color=C.Acc end
            lvlAreas[i].Visible=true
        else
            b.TextColor3=C.Gray b.BackgroundColor3=C.Card
            if s then s.Color=C.Dim end
            lvlAreas[i].Visible=false
        end
    end
end

for i,name in ipairs(lvlTabNames) do
    local b=btn(TabBar,name,10,C.Card,C.Gray)
    b.Size=UDim2.new(0,100,1,0)
    b.LayoutOrder=i
    stroke(b,C.Dim,1.2)
    lvlTabBtns[i]=b
    local ii=i
    b.MouseButton1Click:Connect(function() switchLvlTab(ii) end)
end

-- ============================================
-- HIDE ALL
-- ============================================
local function hideAll()
    TabBar.Visible=false
    LvlArea.Visible=false
    SwapArea.Visible=false
    MiscArea.Visible=false
    GiftArea.Visible=false
    PetListArea.Visible=false
end

-- ============================================
-- SWITCH SIDEBAR
-- ============================================
local function switchSide(idx)
    hideAll()
    resetSideBtns()
    local b=sideBtns[idx]
    b.TextColor3=C.Acc b.BackgroundColor3=C.ADim
    local s=b:FindFirstChildWhichIsA("UIStroke")
    if s then s.Color=C.Acc s.Thickness=1.8 end

    if idx==1 then
        TabBar.Visible=true
        switchLvlTab(activeLvlTab)
    elseif idx==2 then
        MiscArea.Visible=true
    elseif idx==3 then
        GiftArea.Visible=true
    end
end

for i,b in ipairs(sideBtns) do
    local ii=i
    b.MouseButton1Click:Connect(function() switchSide(ii) end)
end

PCBtn.MouseButton1Click:Connect(function()
    hideAll()
    resetSideBtns()
    PetListArea.Visible=true
    pcActive=true
    pcStroke.Color=C.Acc pcStroke.Thickness=2.2
end)

-- ============================================
-- 60KG+ PET LIST
-- ============================================
local function buildPetList()
    for _,c in pairs(PetListArea:GetChildren()) do
        if c:IsA("Frame") or c:IsA("TextLabel") then c:Destroy() end
    end
    local bp=player:FindFirstChild("Backpack")
    if not bp then return 0 end
    local groups={}
    for _,item in pairs(bp:GetChildren()) do
        local ok,name=petValid60(item)
        if ok and name and name~="" then
            groups[name]=(groups[name] or 0)+1
        end
    end
    local n,total=1,0
    for name,count in pairs(groups) do
        total=total+count
        local card=mk("Frame",{
            Size=UDim2.new(1,-4,0,30),
            BackgroundColor3=C.Card,
            BorderSizePixel=0,LayoutOrder=n,Parent=PetListArea
        })
        corner(card,6) stroke(card,C.Gold,1.3)
        local ico=lbl(card,"🐾",11,C.Gold)
        ico.Size=UDim2.new(0,22,1,0) ico.Position=UDim2.new(0,4,0,0)
        ico.TextXAlignment=Enum.TextXAlignment.Center
        local nl=lbl(card,name,10,C.White)
        nl.Size=UDim2.new(0.62,0,1,0) nl.Position=UDim2.new(0,28,0,0)
        local cl=lbl(card,count.." pet",10,C.Acc,Enum.TextXAlignment.Right)
        cl.Size=UDim2.new(0.3,0,1,0) cl.Position=UDim2.new(0.69,0,0,0)
        n=n+1
    end
    if total==0 then
        local info=lbl(PetListArea,"⚠️ Tidak ada pet 60kg+",10,C.Red,Enum.TextXAlignment.Center)
        info.Size=UDim2.new(1,-4,0,30)
        info.BackgroundColor3=C.RDim info.BackgroundTransparency=0
        info.LayoutOrder=1 corner(info,6)
    end
    return total
end

local function updatePetCount()
    local n=buildPetList()
    PetCountNum.Text=tostring(n)
    PetCountNum.TextColor3=n>0 and C.Gold or C.Red
end

updatePetCount()
local bp2=player:WaitForChild("Backpack")
bp2.ChildAdded:Connect(function() task.wait(0.3) updatePetCount() end)
bp2.ChildRemoved:Connect(function() task.wait(0.3) updatePetCount() end)
task.spawn(function()
    while task.wait(5) do
        if not ScreenGui.Parent then break end
        updatePetCount()
    end
end)

-- ============================================
-- AUTO LEVELING
-- ============================================
local isLeveling = false
local levelTask  = nil
local selLvlPets = {}  -- {[itemRef]=true}
local lvlTarget  = 100

-- Header
secHead(LvlArea,"Target Level:",1)

local lvlTargetF=mk("Frame",{
    Size=UDim2.new(1,-4,0,32),
    BackgroundColor3=C.Card,BorderSizePixel=0,
    LayoutOrder=2,Parent=LvlArea
})
corner(lvlTargetF,7) stroke(lvlTargetF,C.Dim,1.3)

local lvlFromL=lbl(lvlTargetF,"Dari:",10,C.Gray)
lvlFromL.Size=UDim2.new(0,30,1,0) lvlFromL.Position=UDim2.new(0,6,0,0)

local lvlFromBox=mk("TextBox",{
    Size=UDim2.new(0,44,0,22),Position=UDim2.new(0,38,0.5,-11),
    BackgroundColor3=C.Panel,Text="1",
    TextColor3=C.Gold,Font=Enum.Font.GothamBold,
    TextSize=11,TextScaled=false,
    TextXAlignment=Enum.TextXAlignment.Center,
    ClearTextOnFocus=false,Parent=lvlTargetF
})
corner(lvlFromBox,5) stroke(lvlFromBox,C.Dim,1.2)

local lvlToL=lbl(lvlTargetF,"→",10,C.Gray,Enum.TextXAlignment.Center)
lvlToL.Size=UDim2.new(0,16,1,0) lvlToL.Position=UDim2.new(0,86,0,0)

local lvlToBox=mk("TextBox",{
    Size=UDim2.new(0,44,0,22),Position=UDim2.new(0,106,0.5,-11),
    BackgroundColor3=C.Panel,Text="100",
    TextColor3=C.Gold,Font=Enum.Font.GothamBold,
    TextSize=11,TextScaled=false,
    TextXAlignment=Enum.TextXAlignment.Center,
    ClearTextOnFocus=false,Parent=lvlTargetF
})
corner(lvlToBox,5) stroke(lvlToBox,C.Dim,1.2)

local lvlPresets = {
    {txt="0→50",  from=1,  to=50},
    {txt="0→100", from=1,  to=100},
    {txt="50→100",from=50, to=100},
}
local lvlPresetF=mk("Frame",{
    Size=UDim2.new(1,-4,0,26),
    BackgroundTransparency=1,BorderSizePixel=0,
    LayoutOrder=3,Parent=LvlArea
})
mk("UIListLayout",{
    FillDirection=Enum.FillDirection.Horizontal,
    Padding=UDim.new(0,4),Parent=lvlPresetF
})
for _,p in ipairs(lvlPresets) do
    local pb=btn(lvlPresetF,p.txt,10,C.Panel,C.Gray)
    pb.Size=UDim2.new(0,68,1,0)
    stroke(pb,C.Dim,1.2)
    local pp=p
    pb.MouseButton1Click:Connect(function()
        lvlFromBox.Text=tostring(pp.from)
        lvlToBox.Text=tostring(pp.to)
    end)
end

-- Pilih pet untuk leveling (semua pet di backpack)
secHead(LvlArea,"Pilih Pet (klik untuk pilih):",4)

local lvlSearchF=mk("Frame",{
    Size=UDim2.new(1,-4,0,26),
    BackgroundColor3=C.Card,BorderSizePixel=0,
    LayoutOrder=5,Parent=LvlArea
})
corner(lvlSearchF,6) stroke(lvlSearchF,C.Dim,1.2)

local lvlSearchBox=mk("TextBox",{
    Size=UDim2.new(1,-8,1,-4),Position=UDim2.new(0,4,0,2),
    BackgroundTransparency=1,Text="",
    PlaceholderText="Cari pet...",PlaceholderColor3=C.Dim,
    TextColor3=C.White,Font=Enum.Font.Gotham,
    TextSize=10,TextScaled=false,
    TextXAlignment=Enum.TextXAlignment.Left,
    ClearTextOnFocus=false,Parent=lvlSearchF
})

local lvlPetScroll=mk("ScrollingFrame",{
    Size=UDim2.new(1,-4,0,100),
    BackgroundColor3=C.Panel,BorderSizePixel=0,
    ScrollBarThickness=3,ScrollBarImageColor3=C.Acc,
    CanvasSize=UDim2.new(0,0,0,0),
    AutomaticCanvasSize=Enum.AutomaticSize.Y,
    LayoutOrder=6,Parent=LvlArea
})
corner(lvlPetScroll,6) stroke(lvlPetScroll,C.Dim,1.2)
mk("UIListLayout",{SortOrder=Enum.SortOrder.LayoutOrder,Padding=UDim.new(0,2),Parent=lvlPetScroll})
mk("UIPadding",{PaddingTop=UDim.new(0,3),PaddingLeft=UDim.new(0,3),PaddingRight=UDim.new(0,3),Parent=lvlPetScroll})

local lvlSelDisplay=lbl(LvlArea,"Dipilih: 0 pet",10,C.Acc,Enum.TextXAlignment.Center)
lvlSelDisplay.Size=UDim2.new(1,-4,0,16)
lvlSelDisplay.LayoutOrder=7

local function buildLvlPetList(filter)
    for _,c in pairs(lvlPetScroll:GetChildren()) do
        if c:IsA("TextButton") then c:Destroy() end
    end
    local bp3=player:FindFirstChild("Backpack")
    if not bp3 then return end
    local n=0
    for _,item in pairs(bp3:GetChildren()) do
        if isPet(item) then
            local name,kg,age,fav=parsePet(item)
            local show=filter=="" or name:lower():find(filter:lower(),1,true)
            if show then
                n=n+1
                local isSelected=selLvlPets[item]==true
                local b=btn(lvlPetScroll,(isSelected and "✔ " or "  ")..name.." [Age "..age.."]",10,
                    isSelected and C.ADim or C.Card,
                    isSelected and C.Acc or C.White)
                b.Size=UDim2.new(1,-4,0,22)
                b.LayoutOrder=n
                b.TextXAlignment=Enum.TextXAlignment.Left
                mk("UIPadding",{PaddingLeft=UDim.new(0,6),Parent=b})

                -- Fav indicator
                if fav then
                    local fi=lbl(b,"⭐",9,C.Gold,Enum.TextXAlignment.Right)
                    fi.Size=UDim2.new(0,18,1,0) fi.Position=UDim2.new(1,-20,0,0)
                end

                b.MouseButton1Click:Connect(function()
                    if selLvlPets[item] then
                        selLvlPets[item]=nil
                        b.BackgroundColor3=C.Card b.TextColor3=C.White
                        b.Text="  "..name.." [Age "..age.."]"
                    else
                        selLvlPets[item]=true
                        b.BackgroundColor3=C.ADim b.TextColor3=C.Acc
                        b.Text="✔ "..name.." [Age "..age.."]"
                    end
                    local cnt=0
                    for _ in pairs(selLvlPets) do cnt=cnt+1 end
                    lvlSelDisplay.Text="Dipilih: "..cnt.." pet"
                end)
            end
        end
    end
end

buildLvlPetList("")
lvlSearchBox:GetPropertyChangedSignal("Text"):Connect(function()
    buildLvlPetList(lvlSearchBox.Text)
end)

-- Status + tombol start
local lvlStatusLbl=lbl(LvlArea,"Status: Idle",10,C.Gray,Enum.TextXAlignment.Center)
lvlStatusLbl.Size=UDim2.new(1,-4,0,16)
lvlStatusLbl.LayoutOrder=8

local lvlStartBtn=btn(LvlArea,"▶ Start Auto Leveling",11,C.ADim,C.Acc)
lvlStartBtn.Size=UDim2.new(1,-4,0,30)
lvlStartBtn.LayoutOrder=9
stroke(lvlStartBtn,C.Acc,1.8)

local lvlStopBtn=btn(LvlArea,"■ Stop",11,C.RDim,C.Red)
lvlStopBtn.Size=UDim2.new(1,-4,0,26)
lvlStopBtn.LayoutOrder=10
lvlStopBtn.Visible=false
stroke(lvlStopBtn,C.Red,1.5)

local function doLeveling()
    local fromLvl = tonumber(lvlFromBox.Text) or 1
    local toLvl   = tonumber(lvlToBox.Text) or 100

    -- Cari remote leveling
    local levelRemote = RS:FindFirstChild("LevelPet",true)
        or RS:FindFirstChild("AgePet",true)
        or RS:FindFirstChild("FeedPet",true)

    for item in pairs(selLvlPets) do
        if not isLeveling then break end
        if not item.Parent then continue end

        local _,_,age = parsePet(item)
        if age >= toLvl then
            -- Auto pickup kalau sudah sesuai target
            local pickupRemote = RS:FindFirstChild("PickupPet",true)
                or RS:FindFirstChild("CollectPet",true)
            if pickupRemote then
                pcall(function()
                    if pickupRemote:IsA("RemoteEvent") then pickupRemote:FireServer(item)
                    else pickupRemote:InvokeServer(item) end
                end)
            end
            lvlStatusLbl.Text="✅ "..parsePet(item).." sudah age "..age
            continue
        end

        lvlStatusLbl.Text="⏳ Leveling: "..(parsePet(item)).." | Age "..age.."/"..toLvl

        if levelRemote then
            pcall(function()
                if levelRemote:IsA("RemoteEvent") then levelRemote:FireServer(item)
                else levelRemote:InvokeServer(item) end
            end)
        end
        task.wait(0.5)
    end
end

lvlStartBtn.MouseButton1Click:Connect(function()
    if isLeveling then return end
    local cnt=0 for _ in pairs(selLvlPets) do cnt=cnt+1 end
    if cnt==0 then
        lvlStatusLbl.Text="⚠️ Pilih pet dulu!"
        lvlStatusLbl.TextColor3=C.Red
        task.wait(2) lvlStatusLbl.TextColor3=C.Gray
        return
    end
    isLeveling=true
    lvlStartBtn.Visible=false lvlStopBtn.Visible=true
    lvlStatusLbl.Text="▶ Leveling berjalan..."
    levelTask=task.spawn(function()
        while isLeveling do
            doLeveling()
            task.wait(1)
        end
    end)
end)

lvlStopBtn.MouseButton1Click:Connect(function()
    isLeveling=false
    if levelTask then task.cancel(levelTask) levelTask=nil end
    lvlStartBtn.Visible=true lvlStopBtn.Visible=false
    lvlStatusLbl.Text="■ Dihentikan"
    lvlStatusLbl.TextColor3=C.Gray
end)

-- ============================================
-- AUTO SWAP
-- ============================================
local swapSettings = {}  -- {[petName]={delayPickup=1,delayEquip=1}}
local isSwapping = false
local swapTask = nil

secHead(SwapArea,"Pet Favorit (Auto Swap):",1)
local swapNote=lbl(SwapArea,"Hanya pet favorit yang bisa dipilih",9,C.Gray,Enum.TextXAlignment.Left)
swapNote.Size=UDim2.new(1,-4,0,14) swapNote.LayoutOrder=2

local swapRefreshBtn=btn(SwapArea,"🔄 Refresh Pet Favorit",10,C.Panel,C.White)
swapRefreshBtn.Size=UDim2.new(1,-4,0,26) swapRefreshBtn.LayoutOrder=3
stroke(swapRefreshBtn,C.Dim,1.3)

local swapPetFrame=mk("Frame",{
    Size=UDim2.new(1,-4,0,0),
    BackgroundTransparency=1,
    AutomaticSize=Enum.AutomaticSize.Y,
    LayoutOrder=4,Parent=SwapArea
})
mk("UIListLayout",{SortOrder=Enum.SortOrder.LayoutOrder,Padding=UDim.new(0,4),Parent=swapPetFrame})

local swapStatusLbl=lbl(SwapArea,"Status: Idle",10,C.Gray,Enum.TextXAlignment.Center)
swapStatusLbl.Size=UDim2.new(1,-4,0,16) swapStatusLbl.LayoutOrder=10

local swapStartBtn=btn(SwapArea,"▶ Start Auto Swap",11,C.ADim,C.Acc)
swapStartBtn.Size=UDim2.new(1,-4,0,28) swapStartBtn.LayoutOrder=11
stroke(swapStartBtn,C.Acc,1.8)

local swapStopBtn=btn(SwapArea,"■ Stop",11,C.RDim,C.Red)
swapStopBtn.Size=UDim2.new(1,-4,0,24) swapStopBtn.LayoutOrder=12
swapStopBtn.Visible=false
stroke(swapStopBtn,C.Red,1.5)

local function buildSwapList()
    for _,c in pairs(swapPetFrame:GetChildren()) do
        if c:IsA("Frame") then c:Destroy() end
    end
    swapSettings={}
    local bp3=player:FindFirstChild("Backpack")
    if not bp3 then return end
    local n=0
    for _,item in pairs(bp3:GetChildren()) do
        if isPet(item) then
            local name,_,age,fav=parsePet(item)
            if fav then
                n=n+1
                if not swapSettings[name] then
                    swapSettings[name]={delayPickup=1,delayEquip=1,item=item}
                end

                local card=mk("Frame",{
                    Size=UDim2.new(1,0,0,58),
                    BackgroundColor3=C.Card,BorderSizePixel=0,
                    LayoutOrder=n,Parent=swapPetFrame
                })
                corner(card,7) stroke(card,C.Acc,1.2)

                local nl=lbl(card,"⭐ "..name.." [Age "..age.."]",10,C.Acc)
                nl.Size=UDim2.new(1,-4,0,18) nl.Position=UDim2.new(0,6,0,2)

                -- Delay pickup row
                local dpRow=mk("Frame",{
                    Size=UDim2.new(1,-8,0,18),
                    Position=UDim2.new(0,4,0,22),
                    BackgroundTransparency=1,Parent=card
                })
                lbl(dpRow,"Delay Pickup:",9,C.Gray).Size=UDim2.new(0,80,1,0)
                local dpBox=mk("TextBox",{
                    Size=UDim2.new(0,40,1,-2),Position=UDim2.new(0,82,0,1),
                    BackgroundColor3=C.Panel,Text="1",
                    TextColor3=C.Gold,Font=Enum.Font.Gotham,
                    TextSize=10,TextScaled=false,
                    TextXAlignment=Enum.TextXAlignment.Center,
                    ClearTextOnFocus=false,Parent=dpRow
                })
                corner(dpBox,4) stroke(dpBox,C.Dim,1)
                lbl(dpRow,"detik",9,C.Gray).Size=UDim2.new(0,30,1,0)
                lbl(dpRow,"detik",9,C.Gray).Position=UDim2.new(0,126,0,0)

                -- Delay equip row
                local deRow=mk("Frame",{
                    Size=UDim2.new(1,-8,0,18),
                    Position=UDim2.new(0,4,0,40),
                    BackgroundTransparency=1,Parent=card
                })
                lbl(deRow,"Delay Equip:",9,C.Gray).Size=UDim2.new(0,80,1,0)
                local deBox=mk("TextBox",{
                    Size=UDim2.new(0,40,1,-2),Position=UDim2.new(0,82,0,1),
                    BackgroundColor3=C.Panel,Text="1",
                    TextColor3=C.Gold,Font=Enum.Font.Gotham,
                    TextSize=10,TextScaled=false,
                    TextXAlignment=Enum.TextXAlignment.Center,
                    ClearTextOnFocus=false,Parent=deRow
                })
                corner(deBox,4) stroke(deBox,C.Dim,1)
                lbl(deRow,"detik",9,C.Gray).Size=UDim2.new(0,30,1,0)
                lbl(deRow,"detik",9,C.Gray).Position=UDim2.new(0,126,0,0)

                dpBox:GetPropertyChangedSignal("Text"):Connect(function()
                    local v=tonumber(dpBox.Text)
                    if v then swapSettings[name].delayPickup=v end
                end)
                deBox:GetPropertyChangedSignal("Text"):Connect(function()
                    local v=tonumber(deBox.Text)
                    if v then swapSettings[name].delayEquip=v end
                end)
            end
        end
    end
    if n==0 then
        local e=lbl(swapPetFrame,"⚠️ Tidak ada pet favorit",10,C.Red,Enum.TextXAlignment.Center)
        e.Size=UDim2.new(1,0,0,26)
    end
end

swapRefreshBtn.MouseButton1Click:Connect(function()
    swapRefreshBtn.Text="⏳ Loading..."
    task.wait(0.3) buildSwapList()
    swapRefreshBtn.Text="🔄 Refresh Pet Favorit"
end)

local function doSwap()
    local equipRemote = RS:FindFirstChild("EquipPet",true)
    local pickupRemote = RS:FindFirstChild("PickupPet",true)
        or RS:FindFirstChild("UnequipPet",true)

    for name,data in pairs(swapSettings) do
        if not isSwapping then break end
        local item=data.item
        if not item or not item.Parent then continue end

        swapStatusLbl.Text="🔄 Swap: "..name
        task.wait(data.delayPickup or 1)

        if pickupRemote then
            pcall(function()
                if pickupRemote:IsA("RemoteEvent") then pickupRemote:FireServer(item)
                else pickupRemote:InvokeServer(item) end
            end)
        end

        task.wait(data.delayEquip or 1)

        if equipRemote then
            pcall(function()
                if equipRemote:IsA("RemoteEvent") then equipRemote:FireServer(item)
                else equipRemote:InvokeServer(item) end
            end)
        end
    end
end

swapStartBtn.MouseButton1Click:Connect(function()
    if isSwapping then return end
    if next(swapSettings)==nil then
        swapStatusLbl.Text="⚠️ Tidak ada pet favorit!"
        swapStatusLbl.TextColor3=C.Red
        task.wait(2) swapStatusLbl.TextColor3=C.Gray
        return
    end
    isSwapping=true
    swapStartBtn.Visible=false swapStopBtn.Visible=true
    swapStatusLbl.Text="▶ Auto Swap berjalan..."
    swapTask=task.spawn(function()
        while isSwapping do
            doSwap()
            task.wait(0.5)
        end
    end)
end)

swapStopBtn.MouseButton1Click:Connect(function()
    isSwapping=false
    if swapTask then task.cancel(swapTask) swapTask=nil end
    swapStartBtn.Visible=true swapStopBtn.Visible=false
    swapStatusLbl.Text="■ Dihentikan"
end)

buildSwapList()

-- ============================================
-- MISC - REJOIN
-- ============================================
local isAR=false
local arTask=nil
local arMin=cfg.rejoinMinutes or 30

local function doRejoin() TS:Teleport(game.PlaceId,player) end

secHead(MiscArea,"REJOIN SETTINGS",0)

local rnBtn=btn(MiscArea,"⚡ Rejoin Now",11,C.GDim,C.Green)
rnBtn.Size=UDim2.new(1,-4,0,30) rnBtn.LayoutOrder=1
stroke(rnBtn,C.Green,1.8)
rnBtn.MouseButton1Click:Connect(function()
    rnBtn.Text="⏳ Rejoining..." task.wait(1) doRejoin()
end)

local setF=mk("Frame",{
    Size=UDim2.new(1,-4,0,32),
    BackgroundColor3=C.Card,BorderSizePixel=0,
    LayoutOrder=2,Parent=MiscArea
})
corner(setF,7) stroke(setF,C.Dim,1.3)

lbl(setF,"Interval",10,C.Gray).Size=UDim2.new(0.4,0,1,0)
local minBox=mk("TextBox",{
    Size=UDim2.new(0,60,0,22),Position=UDim2.new(0.42,0,0.5,-11),
    BackgroundColor3=C.Panel,Text=tostring(arMin),
    TextColor3=C.Gold,Font=Enum.Font.GothamBold,
    TextSize=11,TextScaled=false,
    TextXAlignment=Enum.TextXAlignment.Center,
    ClearTextOnFocus=false,Parent=setF
})
corner(minBox,5) stroke(minBox,C.Dim,1.2)
lbl(setF,"menit",10,C.Gray).Position=UDim2.new(0.42,64,0,0)
lbl(setF,"menit",10,C.Gray).Size=UDim2.new(0,40,1,0)
minBox:GetPropertyChangedSignal("Text"):Connect(function()
    local v=tonumber(minBox.Text)
    if v then arMin=math.max(1,math.min(120,v))
        saveSettings({rejoinMinutes=arMin,autoRejoin=isAR}) end
end)

local autoF=mk("Frame",{
    Size=UDim2.new(1,-4,0,32),
    BackgroundColor3=C.Card,BorderSizePixel=0,
    LayoutOrder=3,Parent=MiscArea
})
corner(autoF,7)
local arStroke=stroke(autoF,C.Dim,1.3)
lbl(autoF,"Auto Rejoin",11,C.White).Size=UDim2.new(0.6,0,1,0)
local arL=lbl(autoF,"Auto Rejoin",11,C.White)
arL.Size=UDim2.new(0.6,0,1,0) arL.Position=UDim2.new(0,8,0,0)

local togBtn=btn(autoF,"OFF",10,C.RDim,C.Red)
togBtn.Size=UDim2.new(0,48,0,20) togBtn.Position=UDim2.new(1,-54,0.5,-10)
local togStroke=stroke(togBtn,C.Red,1.3)

local cdLbl=lbl(MiscArea,"Auto Rejoin: OFF",10,C.Gray,Enum.TextXAlignment.Center)
cdLbl.Size=UDim2.new(1,-4,0,22) cdLbl.LayoutOrder=4
cdLbl.BackgroundColor3=C.Panel cdLbl.BackgroundTransparency=0
corner(cdLbl,6) stroke(cdLbl,C.Dim,1.2)

local function startAR()
    isAR=true togBtn.Text="ON"
    togBtn.BackgroundColor3=C.GDim togBtn.TextColor3=C.Green
    togStroke.Color=C.Green arStroke.Color=C.Green arStroke.Thickness=1.8
    arTask=task.spawn(function()
        while isAR do
            for i=arMin*60,1,-1 do
                if not isAR then break end
                cdLbl.Text=string.format("Rejoin dalam: %02d:%02d",math.floor(i/60),i%60)
                task.wait(1)
            end
            if isAR then cdLbl.Text="🔄 Rejoining..." task.wait(1) doRejoin() end
        end
    end)
end
local function stopAR()
    isAR=false togBtn.Text="OFF"
    togBtn.BackgroundColor3=C.RDim togBtn.TextColor3=C.Red
    togStroke.Color=C.Red arStroke.Color=C.Dim arStroke.Thickness=1.3
    cdLbl.Text="Auto Rejoin: OFF"
    if arTask then task.cancel(arTask) arTask=nil end
end
togBtn.MouseButton1Click:Connect(function()
    if isAR then stopAR() else startAR() end
    saveSettings({rejoinMinutes=arMin,autoRejoin=isAR})
end)

-- ============================================
-- AUTO GIFT
-- ============================================
local selTarget  = nil
local selPetNames= {}
local selMutation= "(Semua / Tidak ada filter)"
local giftKgVal  = 60
local giftKgMode = "below"
local giftAgeVal = 100
local giftAgeMode= "below"
local skipFav    = true
local plCards    = {}

secHead(GiftArea,"AUTO GIFT PET",0)

-- Pilih player
secHead(GiftArea,"👤 Player Tujuan:",1)
local rfBtn=btn(GiftArea,"🔄 Refresh Player",10,C.Panel,C.White)
rfBtn.Size=UDim2.new(1,-4,0,26) rfBtn.LayoutOrder=2
stroke(rfBtn,C.Dim,1.3)

local plFrame=mk("Frame",{
    Size=UDim2.new(1,-4,0,0),BackgroundTransparency=1,
    AutomaticSize=Enum.AutomaticSize.Y,
    LayoutOrder=3,Parent=GiftArea
})
mk("UIListLayout",{SortOrder=Enum.SortOrder.LayoutOrder,Padding=UDim.new(0,2),Parent=plFrame})

divLine(GiftArea,4)

-- Pilih pet GAG
secHead(GiftArea,"🐾 Pilih Pet:",5)

local gSearchF=mk("Frame",{
    Size=UDim2.new(1,-4,0,26),
    BackgroundColor3=C.Card,BorderSizePixel=0,
    LayoutOrder=6,Parent=GiftArea
})
corner(gSearchF,6) stroke(gSearchF,C.Dim,1.2)
local gSearchBox=mk("TextBox",{
    Size=UDim2.new(1,-8,1,-4),Position=UDim2.new(0,4,0,2),
    BackgroundTransparency=1,Text="",
    PlaceholderText="Cari nama pet...",PlaceholderColor3=C.Dim,
    TextColor3=C.White,Font=Enum.Font.Gotham,
    TextSize=10,TextScaled=false,ClearTextOnFocus=false,Parent=gSearchF
})

local gPetScroll=mk("ScrollingFrame",{
    Size=UDim2.new(1,-4,0,100),
    BackgroundColor3=C.Panel,BorderSizePixel=0,
    ScrollBarThickness=3,ScrollBarImageColor3=C.Acc,
    CanvasSize=UDim2.new(0,0,0,0),
    AutomaticCanvasSize=Enum.AutomaticSize.Y,
    LayoutOrder=7,Parent=GiftArea
})
corner(gPetScroll,6) stroke(gPetScroll,C.Dim,1.2)
mk("UIListLayout",{SortOrder=Enum.SortOrder.LayoutOrder,Padding=UDim.new(0,2),Parent=gPetScroll})
mk("UIPadding",{PaddingTop=UDim.new(0,3),PaddingLeft=UDim.new(0,3),PaddingRight=UDim.new(0,3),Parent=gPetScroll})

local gSelPetLbl=lbl(GiftArea,"Dipilih: (belum ada)",9,C.Acc,Enum.TextXAlignment.Center)
gSelPetLbl.Size=UDim2.new(1,-4,0,14) gSelPetLbl.LayoutOrder=8

local gPetBtns={}
local function buildGiftPetList(filter)
    for _,c in pairs(gPetScroll:GetChildren()) do
        if c:IsA("TextButton") then c:Destroy() end
    end
    gPetBtns={}
    local n=0
    for _,petName in ipairs(PETS) do
        local show=filter=="" or petName:lower():find(filter:lower(),1,true)
        if show then
            n=n+1
            local isSel=selPetNames[petName]==true

            -- Hitung di inventory
            local bp3=player:FindFirstChild("Backpack")
            local cnt=0
            if bp3 then
                for _,item in pairs(bp3:GetChildren()) do
                    local nm=parsePet(item)
                    if nm==petName then cnt=cnt+1 end
                end
            end

            local b=btn(gPetScroll,(isSel and "✔ " or "  ")..petName..(cnt>0 and " ("..cnt..")" or ""),
                10,isSel and C.ADim or C.Card,isSel and C.Acc or C.White)
            b.Size=UDim2.new(1,-4,0,22)
            b.LayoutOrder=n
            b.TextXAlignment=Enum.TextXAlignment.Left
            mk("UIPadding",{PaddingLeft=UDim.new(0,5),Parent=b})
            gPetBtns[petName]=b

            b.MouseButton1Click:Connect(function()
                if selPetNames[petName] then
                    selPetNames[petName]=nil
                    b.BackgroundColor3=C.Card b.TextColor3=C.White
                    b.Text="  "..petName..(cnt>0 and " ("..cnt..")" or "")
                else
                    selPetNames[petName]=true
                    b.BackgroundColor3=C.ADim b.TextColor3=C.Acc
                    b.Text="✔ "..petName..(cnt>0 and " ("..cnt..")" or "")
                end
                local names={}
                for n2 in pairs(selPetNames) do table.insert(names,n2) end
                gSelPetLbl.Text=#names>0 and ("Dipilih: "..table.concat(names,", ")) or "Dipilih: (belum ada)"
            end)
        end
    end
end
buildGiftPetList("")
gSearchBox:GetPropertyChangedSignal("Text"):Connect(function()
    buildGiftPetList(gSearchBox.Text)
end)

divLine(GiftArea,9)

-- Pilih mutasi (list + search)
secHead(GiftArea,"✨ Filter Mutasi:",10)

local mSearchF=mk("Frame",{
    Size=UDim2.new(1,-4,0,26),
    BackgroundColor3=C.Card,BorderSizePixel=0,
    LayoutOrder=11,Parent=GiftArea
})
corner(mSearchF,6) stroke(mSearchF,C.Dim,1.2)
local mSearchBox=mk("TextBox",{
    Size=UDim2.new(1,-8,1,-4),Position=UDim2.new(0,4,0,2),
    BackgroundTransparency=1,Text="",
    PlaceholderText="Cari mutasi...",PlaceholderColor3=C.Dim,
    TextColor3=C.White,Font=Enum.Font.Gotham,
    TextSize=10,TextScaled=false,ClearTextOnFocus=false,Parent=mSearchF
})

local mScroll=mk("ScrollingFrame",{
    Size=UDim2.new(1,-4,0,80),
    BackgroundColor3=C.Panel,BorderSizePixel=0,
    ScrollBarThickness=3,ScrollBarImageColor3=C.Acc,
    CanvasSize=UDim2.new(0,0,0,0),
    AutomaticCanvasSize=Enum.AutomaticSize.Y,
    LayoutOrder=12,Parent=GiftArea
})
corner(mScroll,6) stroke(mScroll,C.Dim,1.2)
mk("UIListLayout",{SortOrder=Enum.SortOrder.LayoutOrder,Padding=UDim.new(0,2),Parent=mScroll})
mk("UIPadding",{PaddingTop=UDim.new(0,3),PaddingLeft=UDim.new(0,3),PaddingRight=UDim.new(0,3),Parent=mScroll})

local gSelMutLbl=lbl(GiftArea,"Mutasi: Semua",9,C.Acc,Enum.TextXAlignment.Center)
gSelMutLbl.Size=UDim2.new(1,-4,0,14) gSelMutLbl.LayoutOrder=13

local mutBtns={}
local function buildMutList(filter)
    for _,c in pairs(mScroll:GetChildren()) do
        if c:IsA("TextButton") then c:Destroy() end
    end
    mutBtns={}
    local n=0
    for _,mut in ipairs(MUTATIONS) do
        local show=filter=="" or mut:lower():find(filter:lower(),1,true)
        if show then
            n=n+1
            local isSel=mut==selMutation
            local b=btn(mScroll,(isSel and "✔ " or "  ")..mut,10,
                isSel and C.ADim or C.Card,isSel and C.Acc or C.White)
            b.Size=UDim2.new(1,-4,0,22)
            b.LayoutOrder=n
            b.TextXAlignment=Enum.TextXAlignment.Left
            mk("UIPadding",{PaddingLeft=UDim.new(0,5),Parent=b})
            mutBtns[mut]=b

            b.MouseButton1Click:Connect(function()
                -- Reset semua
                for m2,b2 in pairs(mutBtns) do
                    b2.BackgroundColor3=C.Card b2.TextColor3=C.White
                    b2.Text="  "..m2
                end
                selMutation=mut
                b.BackgroundColor3=C.ADim b.TextColor3=C.Acc
                b.Text="✔ "..mut
                gSelMutLbl.Text="Mutasi: "..(mut=="(Semua / Tidak ada filter)" and "Semua" or mut)
            end)
        end
    end
end
buildMutList("")
mSearchBox:GetPropertyChangedSignal("Text"):Connect(function()
    buildMutList(mSearchBox.Text)
end)

divLine(GiftArea,14)

-- Filter KG
secHead(GiftArea,"⚖️ Filter KG:",15)
local kgF=mk("Frame",{
    Size=UDim2.new(1,-4,0,30),
    BackgroundColor3=C.Card,BorderSizePixel=0,
    LayoutOrder=16,Parent=GiftArea
})
corner(kgF,7) stroke(kgF,C.Dim,1.3)

local kgModeBtn=btn(kgF,"−",14,C.RDim,C.Red)
kgModeBtn.Size=UDim2.new(0,26,0,22) kgModeBtn.Position=UDim2.new(0,4,0.5,-11)
local kgMS=stroke(kgModeBtn,C.Red,1.3)

local kgBox=mk("TextBox",{
    Size=UDim2.new(0,56,0,22),Position=UDim2.new(0,34,0.5,-11),
    BackgroundColor3=C.Panel,Text="60",
    TextColor3=C.Gold,Font=Enum.Font.GothamBold,
    TextSize=11,TextScaled=false,
    TextXAlignment=Enum.TextXAlignment.Center,
    ClearTextOnFocus=false,Parent=kgF
})
corner(kgBox,5) stroke(kgBox,C.Dim,1.2)

lbl(kgF,"kg",9,C.Gray).Size=UDim2.new(0,18,1,0)
local kgUL=lbl(kgF,"kg",9,C.Gray)
kgUL.Size=UDim2.new(0,18,1,0) kgUL.Position=UDim2.new(0,94,0,0)

local kgDescL=lbl(kgF,"Gift pet < 60kg",8,C.Gray,Enum.TextXAlignment.Right)
kgDescL.Size=UDim2.new(0,120,1,0) kgDescL.Position=UDim2.new(1,-124,0,0)

local function updKg()
    if giftKgMode=="below" then
        kgModeBtn.Text="−" kgModeBtn.BackgroundColor3=C.RDim
        kgModeBtn.TextColor3=C.Red kgMS.Color=C.Red
        kgDescL.Text="Gift pet < "..giftKgVal.."kg"
    else
        kgModeBtn.Text="+" kgModeBtn.BackgroundColor3=C.GDim
        kgModeBtn.TextColor3=C.Green kgMS.Color=C.Green
        kgDescL.Text="Gift pet ≥ "..giftKgVal.."kg"
    end
end
kgModeBtn.MouseButton1Click:Connect(function()
    giftKgMode=giftKgMode=="below" and "above" or "below" updKg()
end)
kgBox:GetPropertyChangedSignal("Text"):Connect(function()
    local v=tonumber(kgBox.Text) if v then giftKgVal=v updKg() end
end)

-- Filter Age
secHead(GiftArea,"📅 Filter Age:",17)
local ageF=mk("Frame",{
    Size=UDim2.new(1,-4,0,30),
    BackgroundColor3=C.Card,BorderSizePixel=0,
    LayoutOrder=18,Parent=GiftArea
})
corner(ageF,7) stroke(ageF,C.Dim,1.3)

local ageModeBtn=btn(ageF,"−",14,C.RDim,C.Red)
ageModeBtn.Size=UDim2.new(0,26,0,22) ageModeBtn.Position=UDim2.new(0,4,0.5,-11)
local ageMS=stroke(ageModeBtn,C.Red,1.3)

local ageBox=mk("TextBox",{
    Size=UDim2.new(0,56,0,22),Position=UDim2.new(0,34,0.5,-11),
    BackgroundColor3=C.Panel,Text="100",
    TextColor3=C.Gold,Font=Enum.Font.GothamBold,
    TextSize=11,TextScaled=false,
    TextXAlignment=Enum.TextXAlignment.Center,
    ClearTextOnFocus=false,Parent=ageF
})
corner(ageBox,5) stroke(ageBox,C.Dim,1.2)

local ageUL=lbl(ageF,"age",9,C.Gray)
ageUL.Size=UDim2.new(0,24,1,0) ageUL.Position=UDim2.new(0,94,0,0)

local ageDescL=lbl(ageF,"Gift age < 100",8,C.Gray,Enum.TextXAlignment.Right)
ageDescL.Size=UDim2.new(0,120,1,0) ageDescL.Position=UDim2.new(1,-124,0,0)

local function updAge()
    if giftAgeMode=="below" then
        ageModeBtn.Text="−" ageModeBtn.BackgroundColor3=C.RDim
        ageModeBtn.TextColor3=C.Red ageMS.Color=C.Red
        ageDescL.Text="Gift age < "..giftAgeVal
    else
        ageModeBtn.Text="+" ageModeBtn.BackgroundColor3=C.GDim
        ageModeBtn.TextColor3=C.Green ageMS.Color=C.Green
        ageDescL.Text="Gift age ≥ "..giftAgeVal
    end
end
ageModeBtn.MouseButton1Click:Connect(function()
    giftAgeMode=giftAgeMode=="below" and "above" or "below" updAge()
end)
ageBox:GetPropertyChangedSignal("Text"):Connect(function()
    local v=tonumber(ageBox.Text) if v then giftAgeVal=v updAge() end
end)

-- Skip favorit
local favF=mk("Frame",{
    Size=UDim2.new(1,-4,0,28),
    BackgroundColor3=C.Card,BorderSizePixel=0,
    LayoutOrder=19,Parent=GiftArea
})
corner(favF,7) stroke(favF,C.ADim,1.3)

lbl(favF,"⭐ Skip Pet Favorit",10,C.White).Size=UDim2.new(0.65,0,1,0)
local favL=lbl(favF,"⭐ Skip Pet Favorit",10,C.White)
favL.Size=UDim2.new(0.65,0,1,0) favL.Position=UDim2.new(0,8,0,0)

local favTog=btn(favF,"ON",10,C.GDim,C.Green)
favTog.Size=UDim2.new(0,44,0,20) favTog.Position=UDim2.new(1,-50,0.5,-10)
local favTS=stroke(favTog,C.Green,1.3)

favTog.MouseButton1Click:Connect(function()
    skipFav=not skipFav
    if skipFav then
        favTog.Text="ON" favTog.BackgroundColor3=C.GDim
        favTog.TextColor3=C.Green favTS.Color=C.Green
    else
        favTog.Text="OFF" favTog.BackgroundColor3=C.RDim
        favTog.TextColor3=C.Red favTS.Color=C.Red
    end
end)

divLine(GiftArea,20)

-- Preview
local previewF=mk("Frame",{
    Size=UDim2.new(1,-4,0,0),BackgroundTransparency=1,
    AutomaticSize=Enum.AutomaticSize.Y,
    LayoutOrder=21,Parent=GiftArea
})
mk("UIListLayout",{SortOrder=Enum.SortOrder.LayoutOrder,Padding=UDim.new(0,2),Parent=previewF})

local function countGiftPets()
    local bp3=player:FindFirstChild("Backpack")
    if not bp3 then return 0,{} end
    local items={}
    for _,item in pairs(bp3:GetChildren()) do
        if isPet(item) then
            local name,kg,age,fav,mutation=parsePet(item)
            if not kg then continue end
            if skipFav and fav then continue end
            local petNames={}
            for n in pairs(selPetNames) do table.insert(petNames,n) end
            if #petNames>0 then
                local match=false
                for _,pn in ipairs(petNames) do if name==pn then match=true break end end
                if not match then continue end
            end
            if selMutation~="(Semua / Tidak ada filter)" and mutation~=selMutation then continue end
            local kgPass=giftKgMode=="below" and kg<giftKgVal or kg>=giftKgVal
            local agePass=giftAgeMode=="below" and age<giftAgeVal or age>=giftAgeVal
            if kgPass and agePass then table.insert(items,item) end
        end
    end
    return #items,items
end

local function updatePreview()
    for _,c in pairs(previewF:GetChildren()) do
        if c:IsA("Frame") then c:Destroy() end
    end
    local cnt,items=countGiftPets()
    local byName={}
    for _,item in ipairs(items) do
        local name=parsePet(item)
        byName[name]=(byName[name] or 0)+1
    end
    for name,n in pairs(byName) do
        local row=mk("Frame",{
            Size=UDim2.new(1,0,0,24),
            BackgroundColor3=C.Card,BorderSizePixel=0,Parent=previewF
        })
        corner(row,5)
        local nl=lbl(row,"🎁 "..name,9,C.White)
        nl.Size=UDim2.new(0.7,0,1,0) nl.Position=UDim2.new(0,5,0,0)
        local cl=lbl(row,n.." siap",9,C.Acc,Enum.TextXAlignment.Right)
        cl.Size=UDim2.new(0.28,0,1,0) cl.Position=UDim2.new(0.71,0,0,0)
    end
    if cnt==0 then
        local e=lbl(previewF,"Preview: tidak ada pet yang cocok",9,C.Gray,Enum.TextXAlignment.Center)
        e.Size=UDim2.new(1,0,0,20)
    end
end

local gStLbl=lbl(GiftArea,"Target: -",9,C.Gray,Enum.TextXAlignment.Center)
gStLbl.Size=UDim2.new(1,-4,0,16) gStLbl.LayoutOrder=22

local giftBtn=btn(GiftArea,"🎁 Gift Sekarang",11,C.ADim,C.Acc)
giftBtn.Size=UDim2.new(1,-4,0,30) giftBtn.LayoutOrder=23
stroke(giftBtn,C.Acc,1.8)

kgModeBtn.MouseButton1Click:Connect(updatePreview)
kgBox:GetPropertyChangedSignal("Text"):Connect(updatePreview)
ageModeBtn.MouseButton1Click:Connect(updatePreview)
ageBox:GetPropertyChangedSignal("Text"):Connect(updatePreview)
favTog.MouseButton1Click:Connect(updatePreview)

local function loadPlayers()
    for _,c in pairs(plFrame:GetChildren()) do
        if c:IsA("TextButton") or c:IsA("TextLabel") then c:Destroy() end
    end
    plCards={} selTarget=nil gStLbl.Text="Target: -"
    local all=Players:GetPlayers()
    local n=0
    for _,p in pairs(all) do
        if p.Name~=player.Name then
            n=n+1
            local c=btn(plFrame,"👤 "..p.Name,10,C.Card,C.White)
            c.Size=UDim2.new(1,0,0,24) c.LayoutOrder=n
            c.TextXAlignment=Enum.TextXAlignment.Left
            mk("UIPadding",{PaddingLeft=UDim.new(0,7),Parent=c})
            stroke(c,C.Dim,1.1)
            plCards[p.Name]=c
            c.MouseButton1Click:Connect(function()
                for _,cc in pairs(plCards) do
                    cc.BackgroundColor3=C.Card
                    local s=cc:FindFirstChildWhichIsA("UIStroke")
                    if s then s.Color=C.Dim s.Thickness=1.1 end
                end
                c.BackgroundColor3=C.ADim
                local s=c:FindFirstChildWhichIsA("UIStroke")
                if s then s.Color=C.Acc s.Thickness=1.6 end
                selTarget=p.Name gStLbl.Text="Target: "..p.Name
            end)
        end
    end
    if n==0 then
        local e=lbl(plFrame,"⚠️ Tidak ada player lain",10,C.Red,Enum.TextXAlignment.Center)
        e.Size=UDim2.new(1,0,0,22)
    end
end

rfBtn.MouseButton1Click:Connect(function()
    rfBtn.Text="⏳ Loading..." task.wait(0.3)
    loadPlayers() buildGiftPetList(gSearchBox.Text) updatePreview()
    rfBtn.Text="🔄 Refresh Player"
end)

giftBtn.MouseButton1Click:Connect(function()
    if not selTarget then
        gStLbl.Text="⚠️ Pilih player dulu!" gStLbl.TextColor3=C.Red
        task.wait(2) gStLbl.Text="Target: -" gStLbl.TextColor3=C.Gray return
    end
    local tp=Players:FindFirstChild(selTarget)
    if not tp then
        gStLbl.Text="⚠️ Player tidak ditemukan!" gStLbl.TextColor3=C.Red
        task.wait(2) gStLbl.Text="Target: "..selTarget gStLbl.TextColor3=C.Gray return
    end
    local cnt,toGift=countGiftPets()
    if cnt==0 then
        gStLbl.Text="⚠️ Tidak ada pet yang cocok!" gStLbl.TextColor3=C.Red
        task.wait(2) gStLbl.Text="Target: "..selTarget gStLbl.TextColor3=C.Gray return
    end
    giftBtn.Text="⏳ Gifting "..cnt.." pet..."
    local ok2,fail=0,0
    for _,item in pairs(toGift) do
        local gr=RS:FindFirstChild("GiftPet",true)
            or RS:FindFirstChild("SendPet",true)
            or RS:FindFirstChild("GivePet",true)
        if gr then
            local r=pcall(function()
                if gr:IsA("RemoteEvent") then gr:FireServer(item,tp)
                else gr:InvokeServer(item,tp) end
            end)
            if r then ok2=ok2+1 else fail=fail+1 end
        else fail=fail+1 end
        task.wait(0.3)
    end
    giftBtn.Text="🎁 Gift Sekarang"
    gStLbl.Text=string.format("✅ %d berhasil  ❌ %d gagal",ok2,fail)
    gStLbl.TextColor3=ok2>0 and C.Green or C.Red
    task.wait(3)
    gStLbl.Text="Target: "..selTarget gStLbl.TextColor3=C.Gray
    buildGiftPetList(gSearchBox.Text) updatePreview()
end)

loadPlayers()
updKg() updAge() updatePreview()

Players.PlayerAdded:Connect(function() task.wait(1) loadPlayers() end)
Players.PlayerRemoving:Connect(function() task.wait(0.5) loadPlayers() end)

-- ============================================
-- MINIMISE + DESTROY
-- ============================================
MinBtn.MouseButton1Click:Connect(function()
    ScreenGui.Enabled=false LogoBtn.Visible=true
end)
LogoBtn.MouseButton1Click:Connect(function()
    ScreenGui.Enabled=true LogoBtn.Visible=false
end)
CloseBtn.MouseButton1Click:Connect(function()
    isLeveling=false isSwapping=false isAR=false
    if levelTask then task.cancel(levelTask) end
    if swapTask then task.cancel(swapTask) end
    if arTask then task.cancel(arTask) end
    if playerGui:FindFirstChild("ZenxHub") then playerGui.ZenxHub:Destroy() end
    if playerGui:FindFirstChild("ZenxHubLogo") then playerGui.ZenxHubLogo:Destroy() end
end)

if cfg.autoRejoin==true then task.wait(1) startAR() end

switchSide(1)
print("[ZenxHub] "..username.." | v2.0 Loaded! 🌱")
