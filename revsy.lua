-- ============================================
--   ZENX HUB V2.0 | GROW A GARDEN
--   Full Script - Gift Slots + Auto Accept + 60kg Fix
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
-- THEME
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

local function mk(cls,props)
    local o=Instance.new(cls)
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
    local l=mk("TextLabel",{
        BackgroundTransparency=1,Text=txt,
        TextColor3=col or C.White,Font=Enum.Font.GothamBold,
        TextSize=ts or 11,TextScaled=false,
        TextXAlignment=xa or Enum.TextXAlignment.Left,Parent=p
    })
    return l
end
local function btn(p,txt,ts,bg,tc)
    local b=mk("TextButton",{
        BackgroundColor3=bg or C.Card,Text=txt,
        TextColor3=tc or C.White,Font=Enum.Font.GothamBold,
        TextSize=ts or 11,TextScaled=false,
        AutoButtonColor=false,Parent=p
    })
    corner(b,7)
    return b
end
local function secHead(parent,txt,order)
    local l=lbl(parent,txt,10,C.Gray,Enum.TextXAlignment.Left)
    l.Size=UDim2.new(1,-4,0,16)
    l.LayoutOrder=order
    return l
end
local function divLine(parent,order)
    local d=mk("Frame",{
        Size=UDim2.new(1,-4,0,1),
        BackgroundColor3=C.Dim,
        BorderSizePixel=0,LayoutOrder=order,Parent=parent
    })
    return d
end

-- ============================================
-- DATA PET GAG
-- ============================================
local ALL_PETS = {
    "Ant","Bee","Beetle","Butterfly","Cat","Chicken","Chipmunk",
    "Crow","Dog","Duck","Frog","Goose","Guinea Pig","Hamster",
    "Hedgehog","Ladybug","Mouse","Owl","Pigeon","Rabbit","Rooster",
    "Snail","Squirrel","Turtle","Worm","Brown Mouse","Giant Ant",
    "Red Giant Ant","Bat","Mole","Barn Owl","Bear Bee","Capybara",
    "Chimpanzee","Crocodile","Donkey","Ferret","Flamingo","Goat",
    "Gorilla","Hippo","Jerboa","Llama","Mallard","Marmot","Meerkat",
    "Messenger Pigeon","Monkey","Moose","Orchid Mantis","Orange Tabby",
    "Ostrich","Otter","Oxpecker","Pack Bee","Panda","Parrot","Pig",
    "Praying Mantis","Raccoon","Sheep","Spring Bee","Toucan","Weasel",
    "Axolotl","Pancake Mole","Mochi Mouse","Marshmallow Lamb",
    "Albino Peacock","Beaver","Blue Whale","Cheetah","Eagle","Fox",
    "Giant Scorpion","Goblin Gardener","Golden Piggy","Hazehound",
    "Hootsie Roll","Koi","Lyrebird","Mimic Octopus","Night Owl","Nyala",
    "Orangutan","Pack Mule","Peacock","Peryton","Red Fox","Red Panda",
    "Ruby Squid","Seal","Swan","UFO Seal","Mantis Shrimp",
    "Lobster Thermidor","Lemon Lion","Luminous Sprite","Kodama","Kiwi","Kappa",
    "Brontosaurus","Cerberus","Chimera","Diamond Panther","Disco Bee",
    "Dragonfly","Easter Bunny","Kitsune","Lion","Lioness","Moon Cat",
    "Phoenix","Queen Bee","Space Squirrel","Tiger","T-Rex","Triceratops",
    "White Tiger","Wind Wyvern","Spinosaurus","Dilophosaurus","Velociraptor",
    "Pterodactyl","Ankylosaurus","Stegosaurus","Parasaurolophus",
    "Pachycephalosaurus","Blood Hedgehog","French Fry Ferret","Golem",
    "Headless Horseman","Mummy","Nightcrawler","Ascended Dragonfly",
    "Diamond Dragonfly","Corrupt Kitsune","Disco Dragonfly","Nightmare Koi",
    "Venom Mimic Octopus","Black Swan","Blue Lobster","Calico","Elephant",
    "Giraffe","Hippopotamus","Leopard","Puma","Rhino","Snow Leopard","Zebra",
    "Mizuchi","Maneki-neko","New Year's Bird","New Year's Chimp",
    "New Year's Dragon","Nihonzaru","Nutcracker","Penguin","Polar Bear",
    "Porcupine","Quokka","Raccoon Dog","Ram","Raven","Red Deer","Reindeer",
    "Robin","Samoyed","Sea Horse","Sea Otter","Shiba Inu","Sloth",
    "Snow Rabbit","Snowy Owl","Spider","Starfish","Stork","Tapir","Toad",
    "Turkey","Walrus","Warthog","Wolf","Wolverine","Wombat","Woodpecker",
    "Yak","Alpaca","Armadillo","Bison","Boar","Buffalo","Camel","Caribou",
    "Cassowary","Cobra","Condor","Coyote","Crane","Dingo","Echidna","Elk",
    "Emu","Falcon","Fennec Fox","Gazelle","Gecko","Gopher","Grizzly Bear",
    "Hare","Hawk","Heron","Hyena","Iguana","Impala","Jaguar","Kangaroo",
    "Koala","Komodo Dragon","Lemur","Lynx","Manatee","Manta Ray","Mongoose",
    "Monitor Lizard","Narwhal","Okapi","Werewolf","Vampire Bat","Ghost",
    "Witch Cat","Pumpkin Rat","Krampus","Mistletoad","Tanchozuru","Lich","Junkbot",
}

local petSet={}
local PETS={}
for _,v in ipairs(ALL_PETS) do
    if not petSet[v] then petSet[v]=true table.insert(PETS,v) end
end
table.sort(PETS)

-- ============================================
-- DATA MUTASI GAG
-- ============================================
local ALL_MUTATIONS = {
    "(Semua / Tidak ada filter)",
    "Tiny","Jumbo","Mega","Huge","Giant","Titanic",
    "Rainbow","Golden","Shiny","Gilded","Prismatic","Crystal",
    "Luminous","Glimmering","Aurora","Disco","Choc","Spotty",
    "Gilded Choc","Azure","Umbral","Ghostly","Verdant","Plasma","Mirage",
    "Frozen","Burnt","Fried","Cooked","Peppermint","Venom",
    "Radioactive","Corrupted","Nightmare","Windstruck","Stormcharged",
    "Blitzshock","Subzero","Lightcycle","Flaming","Infernal","Molten",
    "Scorched","Glacial","Pollinated","Aromatic","Lush","Bloom",
    "Everchanted","Tranquil","Dawnbound","Heavenly","Cloudtouched",
    "HoneyGlazed","Moonlit","Paradisal","Ornamented","Ascended",
    "Shadowbound","Abyssal","Necrotic","Maelstrom","Astral","Celestial",
    "Warped","Twisted","Gloom","Moonbled","Slashbound","Friendbound",
    "Beanbound","Graceful","Enchanted","Gourmet","Spooky","Brainrot",
    "Fortune","Sandy","Ceramic","Contagion","Alienlike","Foxfire",
    "Jackpot","Junkshock","AncientAmber","Enlightened","Corrosive",
    "Gnomed","Infected","Zombified","Acidic","Eclipsed","Static",
    "Bloodlit","Drenched","Boil","OilBoil","Cyclonic","Meteoric",
    "Galactic","Voidtouched","Chakra","Desolate","Blackout",
}

local mutSet={}
local MUTATIONS={}
for _,v in ipairs(ALL_MUTATIONS) do
    if not mutSet[v] then mutSet[v]=true table.insert(MUTATIONS,v) end
end

-- ============================================
-- PARSE PET (Fix: age=nil kalau tidak ada [Age X])
-- ============================================
local function parsePet(item)
    local name=item:GetAttribute("f") or ""
    if name=="" then
        name=item.Name:match("^(.-)%s*%[") or item.Name
        name=name:gsub("%s+$","")
    end
    local kg=tonumber(item.Name:match("%[([%d%.]+)%s*[Kk][Gg]%]"))
    local age=nil
    for _,pat in ipairs({"%[Age%s+(%d+)%]","%[Age(%d+)%]","Age%s+(%d+)"}) do
        local f=item.Name:match(pat)
        if f then age=tonumber(f) break end
    end
    -- age=nil kalau tidak ada [Age X] di nama
    local fav=item:GetAttribute("d")==true
    local mutation="(Semua / Tidak ada filter)"
    for _,mut in ipairs(MUTATIONS) do
        if mut~="(Semua / Tidak ada filter)" and item.Name:find(mut,1,true) then
            mutation=mut break
        end
    end
    return name,kg,age,fav,mutation
end

local function isPet(item)
    return item:FindFirstChild("PetToolLocal") or item:FindFirstChild("PetToolServer")
end

-- ============================================
-- LOGO Z
-- ============================================
local LogoGui=mk("ScreenGui",{Name="ZenxHubLogo",ResetOnSpawn=false,Parent=playerGui})
local LogoBtn=mk("TextButton",{
    Size=UDim2.new(0,46,0,46),Position=UDim2.new(0,12,0.5,-23),
    BackgroundColor3=C.BG,Text="Z",TextColor3=C.Acc,
    Font=Enum.Font.GothamBold,TextSize=20,TextScaled=false,
    Active=true,Draggable=true,Visible=false,ZIndex=10,Parent=LogoGui
})
corner(LogoBtn,11) stroke(LogoBtn,C.Acc,2)
LogoBtn.MouseEnter:Connect(function() LogoBtn.BackgroundColor3=C.ADim end)
LogoBtn.MouseLeave:Connect(function() LogoBtn.BackgroundColor3=C.BG end)

-- ============================================
-- MAIN GUI
-- ============================================
local ScreenGui=mk("ScreenGui",{Name="ZenxHub",ResetOnSpawn=false,Parent=playerGui})

local Main=mk("Frame",{
    Size=UDim2.new(0,580,0,400),
    Position=UDim2.new(0.5,-290,0.5,-200),
    BackgroundColor3=C.BG,BorderSizePixel=0,
    Active=true,Draggable=true,Parent=ScreenGui
})
corner(Main,11) stroke(Main,C.Acc,2)

-- Resize
local RH=btn(Main,"◢",9,C.ADim,C.Acc)
RH.Size=UDim2.new(0,16,0,16) RH.Position=UDim2.new(1,-17,1,-17) RH.ZIndex=10
local resizing,rsStart,szStart=false,Vector2.new(),Vector2.new()
RH.MouseButton1Down:Connect(function()
    resizing=true rsStart=UIS:GetMouseLocation()
    szStart=Vector2.new(Main.AbsoluteSize.X,Main.AbsoluteSize.Y)
end)
UIS.InputChanged:Connect(function(i)
    if resizing and i.UserInputType==Enum.UserInputType.MouseMovement then
        local d=UIS:GetMouseLocation()-rsStart
        Main.Size=UDim2.new(0,math.max(500,szStart.X+d.X),0,math.max(360,szStart.Y+d.Y))
    end
end)
UIS.InputEnded:Connect(function(i)
    if i.UserInputType==Enum.UserInputType.MouseButton1 then resizing=false end
end)

-- TITLE BAR
local TB=mk("Frame",{Size=UDim2.new(1,0,0,36),BackgroundColor3=C.Panel,BorderSizePixel=0,Parent=Main})
corner(TB,11)
mk("Frame",{Size=UDim2.new(1,0,0,1.5),Position=UDim2.new(0,0,1,-1.5),BackgroundColor3=C.Acc,BorderSizePixel=0,Parent=TB})

local ZBadge=mk("TextLabel",{
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

-- SIDEBAR
local Sidebar=mk("Frame",{
    Size=UDim2.new(0,145,1,-36),Position=UDim2.new(0,0,0,36),
    BackgroundColor3=C.Side,BorderSizePixel=0,Parent=Main
})
mk("Frame",{
    Size=UDim2.new(0,1.5,1,0),Position=UDim2.new(1,-1.5,0,0),
    BackgroundColor3=C.Acc,BackgroundTransparency=0.7,
    BorderSizePixel=0,Parent=Sidebar
})

-- Kotak 60kg+
local PCBtn=mk("TextButton",{
    Size=UDim2.new(1,-16,0,58),Position=UDim2.new(0,8,0,8),
    BackgroundColor3=C.Panel,Text="",AutoButtonColor=false,
    ZIndex=2,Parent=Sidebar
})
corner(PCBtn,9)
local pcStroke=stroke(PCBtn,C.Gold,1.8)

local pcIco=lbl(PCBtn,"🐾",16,C.Gold)
pcIco.Size=UDim2.new(0,26,0,26) pcIco.Position=UDim2.new(0,5,0.5,-13)
pcIco.TextXAlignment=Enum.TextXAlignment.Center pcIco.ZIndex=3

local pcTitle=lbl(PCBtn,"60kg+ Age 100",9,C.Gray)
pcTitle.Size=UDim2.new(0,90,0,16) pcTitle.Position=UDim2.new(0,35,0,6) pcTitle.ZIndex=3

local PetCountNum=lbl(PCBtn,"0",18,C.Gold)
PetCountNum.Size=UDim2.new(0,90,0,24) PetCountNum.Position=UDim2.new(0,35,0,26)
PetCountNum.Font=Enum.Font.GothamBold PetCountNum.ZIndex=3

local sideData={{text="AUTO LVL",y=74},{text="MISC",y=116},{text="AUTO GIFT",y=158}}
local sideBtns={}
local pcActive=false

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
    b.Size=UDim2.new(1,-16,0,34) b.Position=UDim2.new(0,8,0,data.y)
    b.TextXAlignment=Enum.TextXAlignment.Center
    stroke(b,C.Dim,1.2) sideBtns[i]=b
end

-- CONTENT AREA
local CONTENT_X=147
local CONTENT_Y=38
local TAB_H=30

local TabBar=mk("Frame",{
    Size=UDim2.new(1,-CONTENT_X-4,0,TAB_H),
    Position=UDim2.new(0,CONTENT_X+2,0,CONTENT_Y+2),
    BackgroundTransparency=1,Visible=false,Parent=Main
})
mk("UIListLayout",{FillDirection=Enum.FillDirection.Horizontal,
    SortOrder=Enum.SortOrder.LayoutOrder,Padding=UDim.new(0,4),Parent=TabBar})

local function makeArea()
    local a=mk("ScrollingFrame",{
        Size=UDim2.new(1,-CONTENT_X-6,1,-CONTENT_Y-TAB_H-46),
        Position=UDim2.new(0,CONTENT_X+3,0,CONTENT_Y+TAB_H+4),
        BackgroundTransparency=1,ScrollBarThickness=3,
        ScrollBarImageColor3=C.Acc,CanvasSize=UDim2.new(0,0,0,0),
        AutomaticCanvasSize=Enum.AutomaticSize.Y,
        Visible=false,Parent=Main
    })
    mk("UIListLayout",{SortOrder=Enum.SortOrder.LayoutOrder,Padding=UDim.new(0,4),Parent=a})
    mk("UIPadding",{PaddingTop=UDim.new(0,4),PaddingLeft=UDim.new(0,3),PaddingRight=UDim.new(0,5),Parent=a})
    return a
end

local LvlArea=makeArea()
local SwapArea=makeArea()
local MiscArea=makeArea()
local GiftArea=makeArea()
local PetListArea=makeArea()

-- Bottom bar
local BotBar=mk("Frame",{
    Size=UDim2.new(1,-CONTENT_X-4,0,38),
    Position=UDim2.new(0,CONTENT_X+2,1,-42),
    BackgroundColor3=C.Panel,BorderSizePixel=0,Parent=Main
})
corner(BotBar,7) stroke(BotBar,C.Acc,1.3)

local RunBtn=btn(BotBar,"⚡ RUNNING",11,C.ADim,C.Acc)
RunBtn.Size=UDim2.new(0,112,0,26) RunBtn.Position=UDim2.new(0,6,0.5,-13)
stroke(RunBtn,C.Acc,1.8)

local StopBtn=btn(BotBar,"STOP",11,C.RDim,C.Red)
StopBtn.Size=UDim2.new(0,72,0,26) StopBtn.Position=UDim2.new(0,122,0.5,-13)
stroke(StopBtn,C.Red,1.8)

-- AUTO LVL TABS
local lvlTabNames={"Auto Leveling","Auto Swap"}
local lvlTabBtns={}
local lvlAreas={LvlArea,SwapArea}
local activeLvlTab=1

local function switchLvlTab(idx)
    activeLvlTab=idx
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
    b.Size=UDim2.new(0,100,1,0) b.LayoutOrder=i
    stroke(b,C.Dim,1.2) lvlTabBtns[i]=b
    local ii=i
    b.MouseButton1Click:Connect(function() switchLvlTab(ii) end)
end

local function hideAll()
    TabBar.Visible=false
    LvlArea.Visible=false SwapArea.Visible=false
    MiscArea.Visible=false GiftArea.Visible=false
    PetListArea.Visible=false
end

local function switchSide(idx)
    hideAll() resetSideBtns()
    local b=sideBtns[idx]
    b.TextColor3=C.Acc b.BackgroundColor3=C.ADim
    local s=b:FindFirstChildWhichIsA("UIStroke")
    if s then s.Color=C.Acc s.Thickness=1.8 end
    if idx==1 then TabBar.Visible=true switchLvlTab(activeLvlTab)
    elseif idx==2 then MiscArea.Visible=true
    elseif idx==3 then GiftArea.Visible=true
    end
end

for i,b in ipairs(sideBtns) do
    local ii=i
    b.MouseButton1Click:Connect(function() switchSide(ii) end)
end

PCBtn.MouseButton1Click:Connect(function()
    hideAll() resetSideBtns()
    PetListArea.Visible=true pcActive=true
    pcStroke.Color=C.Acc pcStroke.Thickness=2.2
end)

-- ============================================
-- 60KG+ PET LIST (Fix: age=nil → kg>=60)
-- ============================================
local function buildPetList()
    for _,c in pairs(PetListArea:GetChildren()) do
        if c:IsA("Frame") or c:IsA("TextLabel") then c:Destroy() end
    end
    local bp=player:FindFirstChild("Backpack")
    if not bp then return 0 end

    local groups={}
    for _,item in pairs(bp:GetChildren()) do
        if not isPet(item) then continue end
        local name,kg,age=parsePet(item)
        if not kg then continue end
        if not groups[name] then groups[name]={done=0,notDone=0} end

        local isDone
        if age then
            isDone=(kg*110/(age+10))>=60
        else
            isDone=kg>=60
        end

        if isDone then groups[name].done=groups[name].done+1
        else groups[name].notDone=groups[name].notDone+1 end
    end

    local sortedNames={}
    for name in pairs(groups) do table.insert(sortedNames,name) end
    table.sort(sortedNames)

    local n=1
    local totalDone=0

    local doneList={}
    for _,name in ipairs(sortedNames) do
        if groups[name].done>0 then
            table.insert(doneList,name)
            totalDone=totalDone+groups[name].done
        end
    end

    if #doneList>0 then
        local h=lbl(PetListArea,"✅ Sudah 60kg+ Age 100 ("..totalDone..")",9,C.Green)
        h.Size=UDim2.new(1,-4,0,16) h.LayoutOrder=n n=n+1
        for _,name in ipairs(doneList) do
            local card=mk("Frame",{Size=UDim2.new(1,-4,0,28),BackgroundColor3=C.Card,BorderSizePixel=0,LayoutOrder=n,Parent=PetListArea})
            corner(card,6) stroke(card,C.Gold,1.3)
            local ico=lbl(card,"🐾",10,C.Gold)
            ico.Size=UDim2.new(0,22,1,0) ico.Position=UDim2.new(0,3,0,0) ico.TextXAlignment=Enum.TextXAlignment.Center
            local nl=lbl(card,name,10,C.White)
            nl.Size=UDim2.new(0.65,0,1,0) nl.Position=UDim2.new(0,26,0,0)
            local cl=lbl(card,groups[name].done.." pet",10,C.Acc,Enum.TextXAlignment.Right)
            cl.Size=UDim2.new(0.28,0,1,0) cl.Position=UDim2.new(0.71,0,0,0)
            n=n+1
        end
    end

    local notDoneList={}
    for _,name in ipairs(sortedNames) do
        if groups[name].notDone>0 then table.insert(notDoneList,name) end
    end

    if #notDoneList>0 then
        mk("Frame",{Size=UDim2.new(1,-4,0,4),BackgroundTransparency=1,LayoutOrder=n,Parent=PetListArea}) n=n+1
        local h2=lbl(PetListArea,"⏳ Belum 60kg+ Age 100 ("..#notDoneList.." jenis)",9,C.Gray)
        h2.Size=UDim2.new(1,-4,0,16) h2.LayoutOrder=n n=n+1
        for _,name in ipairs(notDoneList) do
            local card=mk("Frame",{Size=UDim2.new(1,-4,0,28),BackgroundColor3=C.Card,BorderSizePixel=0,LayoutOrder=n,Parent=PetListArea})
            corner(card,6) stroke(card,C.Dim,1.2)
            local ico=lbl(card,"🐾",10,C.Gray)
            ico.Size=UDim2.new(0,22,1,0) ico.Position=UDim2.new(0,3,0,0) ico.TextXAlignment=Enum.TextXAlignment.Center
            local nl=lbl(card,name,10,C.White)
            nl.Size=UDim2.new(0.65,0,1,0) nl.Position=UDim2.new(0,26,0,0)
            local cl=lbl(card,groups[name].notDone.." pet",10,C.Gray,Enum.TextXAlignment.Right)
            cl.Size=UDim2.new(0.28,0,1,0) cl.Position=UDim2.new(0.71,0,0,0)
            n=n+1
        end
    end

    -- Tabel ringkasan
    if next(groups) then
        mk("Frame",{Size=UDim2.new(1,-4,0,6),BackgroundTransparency=1,LayoutOrder=n,Parent=PetListArea}) n=n+1
        local hSum=lbl(PetListArea,"📊 Ringkasan Total",9,C.Acc) hSum.Size=UDim2.new(1,-4,0,16) hSum.LayoutOrder=n n=n+1
        local tHeader=mk("Frame",{Size=UDim2.new(1,-4,0,20),BackgroundColor3=C.Panel,BorderSizePixel=0,LayoutOrder=n,Parent=PetListArea})
        corner(tHeader,5)
        local hN=lbl(tHeader,"Nama Pet",9,C.Acc) hN.Size=UDim2.new(0.55,0,1,0) hN.Position=UDim2.new(0,6,0,0)
        local hD=lbl(tHeader,"✅",9,C.Acc,Enum.TextXAlignment.Center) hD.Size=UDim2.new(0.2,0,1,0) hD.Position=UDim2.new(0.55,0,0,0)
        local hNd=lbl(tHeader,"⏳",9,C.Acc,Enum.TextXAlignment.Center) hNd.Size=UDim2.new(0.22,0,1,0) hNd.Position=UDim2.new(0.77,0,0,0)
        n=n+1
        for _,name in ipairs(sortedNames) do
            local data=groups[name]
            local row=mk("Frame",{Size=UDim2.new(1,-4,0,22),BackgroundColor3=C.Card,BorderSizePixel=0,LayoutOrder=n,Parent=PetListArea})
            corner(row,5) stroke(row,data.notDone==0 and C.Gold or C.Dim,1.2)
            local rN=lbl(row,name,9,C.White) rN.Size=UDim2.new(0.55,0,1,0) rN.Position=UDim2.new(0,6,0,0)
            local rD=lbl(row,tostring(data.done),9,data.done>0 and C.Gold or C.Gray,Enum.TextXAlignment.Center) rD.Size=UDim2.new(0.2,0,1,0) rD.Position=UDim2.new(0.55,0,0,0)
            local rNd=lbl(row,tostring(data.notDone),9,data.notDone>0 and C.Red or C.Gray,Enum.TextXAlignment.Center) rNd.Size=UDim2.new(0.22,0,1,0) rNd.Position=UDim2.new(0.77,0,0,0)
            n=n+1
        end
        local tA,tNd=0,0
        for _,data in pairs(groups) do tA=tA+data.done tNd=tNd+data.notDone end
        local tF=mk("Frame",{Size=UDim2.new(1,-4,0,22),BackgroundColor3=C.Panel,BorderSizePixel=0,LayoutOrder=n,Parent=PetListArea})
        corner(tF,5) stroke(tF,C.Acc,1.2)
        local fN=lbl(tF,"TOTAL",9,C.Acc) fN.Size=UDim2.new(0.55,0,1,0) fN.Position=UDim2.new(0,6,0,0)
        local fD=lbl(tF,tostring(tA),9,C.Gold,Enum.TextXAlignment.Center) fD.Size=UDim2.new(0.2,0,1,0) fD.Position=UDim2.new(0.55,0,0,0)
        local fNd=lbl(tF,tostring(tNd),9,tNd>0 and C.Red or C.Green,Enum.TextXAlignment.Center) fNd.Size=UDim2.new(0.22,0,1,0) fNd.Position=UDim2.new(0.77,0,0,0)
    end

    if #doneList==0 and #notDoneList==0 then
        local info=lbl(PetListArea,"⚠️ Tidak ada pet di inventory",10,C.Red,Enum.TextXAlignment.Center)
        info.Size=UDim2.new(1,-4,0,30) info.BackgroundColor3=C.RDim info.BackgroundTransparency=0
        info.LayoutOrder=1 corner(info,6)
    end
    return totalDone
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
local isLeveling=false
local levelTask=nil
local selLvlPets={}

secHead(LvlArea,"Target Level:",1)
local lvlTargetF=mk("Frame",{Size=UDim2.new(1,-4,0,32),BackgroundColor3=C.Card,BorderSizePixel=0,LayoutOrder=2,Parent=LvlArea})
corner(lvlTargetF,7) stroke(lvlTargetF,C.Dim,1.3)

local lvlFromL=lbl(lvlTargetF,"Dari:",10,C.Gray) lvlFromL.Size=UDim2.new(0,30,1,0) lvlFromL.Position=UDim2.new(0,6,0,0)
local lvlFromBox=mk("TextBox",{Size=UDim2.new(0,44,0,22),Position=UDim2.new(0,38,0.5,-11),BackgroundColor3=C.Panel,Text="1",TextColor3=C.Gold,Font=Enum.Font.GothamBold,TextSize=11,TextScaled=false,TextXAlignment=Enum.TextXAlignment.Center,ClearTextOnFocus=false,Parent=lvlTargetF})
corner(lvlFromBox,5) stroke(lvlFromBox,C.Dim,1.2)
local lvlToL=lbl(lvlTargetF,"→",10,C.Gray,Enum.TextXAlignment.Center) lvlToL.Size=UDim2.new(0,16,1,0) lvlToL.Position=UDim2.new(0,86,0,0)
local lvlToBox=mk("TextBox",{Size=UDim2.new(0,44,0,22),Position=UDim2.new(0,106,0.5,-11),BackgroundColor3=C.Panel,Text="100",TextColor3=C.Gold,Font=Enum.Font.GothamBold,TextSize=11,TextScaled=false,TextXAlignment=Enum.TextXAlignment.Center,ClearTextOnFocus=false,Parent=lvlTargetF})
corner(lvlToBox,5) stroke(lvlToBox,C.Dim,1.2)

local lvlPresets={{txt="0→50",from=1,to=50},{txt="0→100",from=1,to=100},{txt="50→100",from=50,to=100}}
local lvlPresetF=mk("Frame",{Size=UDim2.new(1,-4,0,26),BackgroundTransparency=1,BorderSizePixel=0,LayoutOrder=3,Parent=LvlArea})
mk("UIListLayout",{FillDirection=Enum.FillDirection.Horizontal,Padding=UDim.new(0,4),Parent=lvlPresetF})
for _,p in ipairs(lvlPresets) do
    local pb=btn(lvlPresetF,p.txt,10,C.Panel,C.Gray) pb.Size=UDim2.new(0,68,1,0) stroke(pb,C.Dim,1.2)
    local pp=p pb.MouseButton1Click:Connect(function() lvlFromBox.Text=tostring(pp.from) lvlToBox.Text=tostring(pp.to) end)
end

secHead(LvlArea,"Pilih Pet:",4)
local lvlSearchF=mk("Frame",{Size=UDim2.new(1,-4,0,26),BackgroundColor3=C.Card,BorderSizePixel=0,LayoutOrder=5,Parent=LvlArea})
corner(lvlSearchF,6) stroke(lvlSearchF,C.Dim,1.2)
local lvlSearchBox=mk("TextBox",{Size=UDim2.new(1,-8,1,-4),Position=UDim2.new(0,4,0,2),BackgroundTransparency=1,Text="",PlaceholderText="Cari pet...",PlaceholderColor3=C.Dim,TextColor3=C.White,Font=Enum.Font.Gotham,TextSize=10,TextScaled=false,TextXAlignment=Enum.TextXAlignment.Left,ClearTextOnFocus=false,Parent=lvlSearchF})

local lvlPetScroll=mk("ScrollingFrame",{Size=UDim2.new(1,-4,0,100),BackgroundColor3=C.Panel,BorderSizePixel=0,ScrollBarThickness=3,ScrollBarImageColor3=C.Acc,CanvasSize=UDim2.new(0,0,0,0),AutomaticCanvasSize=Enum.AutomaticSize.Y,LayoutOrder=6,Parent=LvlArea})
corner(lvlPetScroll,6) stroke(lvlPetScroll,C.Dim,1.2)
mk("UIListLayout",{SortOrder=Enum.SortOrder.LayoutOrder,Padding=UDim.new(0,2),Parent=lvlPetScroll})
mk("UIPadding",{PaddingTop=UDim.new(0,3),PaddingLeft=UDim.new(0,3),PaddingRight=UDim.new(0,3),Parent=lvlPetScroll})

local lvlSelDisplay=lbl(LvlArea,"Dipilih: 0 pet",10,C.Acc,Enum.TextXAlignment.Center)
lvlSelDisplay.Size=UDim2.new(1,-4,0,16) lvlSelDisplay.LayoutOrder=7

local function buildLvlPetList(filter)
    for _,c in pairs(lvlPetScroll:GetChildren()) do if c:IsA("TextButton") then c:Destroy() end end
    local bp3=player:FindFirstChild("Backpack") if not bp3 then return end
    local n=0
    for _,item in pairs(bp3:GetChildren()) do
        if isPet(item) then
            local name,kg,age,fav=parsePet(item)
            local show=filter=="" or name:lower():find(filter:lower(),1,true)
            if show then
                n=n+1
                local isSel=selLvlPets[item]==true
                local displayAge=age and ("[Age "..age.."]") or "[Age ?]"
                local b=btn(lvlPetScroll,(isSel and "✔ " or "  ")..name.." "..displayAge,10,isSel and C.ADim or C.Card,isSel and C.Acc or C.White)
                b.Size=UDim2.new(1,-4,0,22) b.LayoutOrder=n b.TextXAlignment=Enum.TextXAlignment.Left
                mk("UIPadding",{PaddingLeft=UDim.new(0,6),Parent=b})
                if fav then local fi=lbl(b,"⭐",9,C.Gold,Enum.TextXAlignment.Right) fi.Size=UDim2.new(0,18,1,0) fi.Position=UDim2.new(1,-20,0,0) end
                b.MouseButton1Click:Connect(function()
                    if selLvlPets[item] then
                        selLvlPets[item]=nil b.BackgroundColor3=C.Card b.TextColor3=C.White b.Text="  "..name.." "..displayAge
                    else
                        selLvlPets[item]=true b.BackgroundColor3=C.ADim b.TextColor3=C.Acc b.Text="✔ "..name.." "..displayAge
                    end
                    local cnt=0 for _ in pairs(selLvlPets) do cnt=cnt+1 end
                    lvlSelDisplay.Text="Dipilih: "..cnt.." pet"
                end)
            end
        end
    end
end

buildLvlPetList("")
lvlSearchBox:GetPropertyChangedSignal("Text"):Connect(function() buildLvlPetList(lvlSearchBox.Text) end)

local lvlStatusLbl=lbl(LvlArea,"Status: Idle",10,C.Gray,Enum.TextXAlignment.Center)
lvlStatusLbl.Size=UDim2.new(1,-4,0,16) lvlStatusLbl.LayoutOrder=8

local lvlStartBtn=btn(LvlArea,"▶ Start Auto Leveling",11,C.ADim,C.Acc)
lvlStartBtn.Size=UDim2.new(1,-4,0,30) lvlStartBtn.LayoutOrder=9
stroke(lvlStartBtn,C.Acc,1.8)

local lvlStopBtn=btn(LvlArea,"■ Stop",11,C.RDim,C.Red)
lvlStopBtn.Size=UDim2.new(1,-4,0,26) lvlStopBtn.LayoutOrder=10
lvlStopBtn.Visible=false stroke(lvlStopBtn,C.Red,1.5)

local function doLeveling()
    local toLvl=tonumber(lvlToBox.Text) or 100
    local levelRemote=RS:FindFirstChild("LevelPet",true) or RS:FindFirstChild("AgePet",true) or RS:FindFirstChild("FeedPet",true)
    for item in pairs(selLvlPets) do
        if not isLeveling then break end
        if not item.Parent then continue end
        local name,_,age=parsePet(item)
        local currentAge=age or 1
        if currentAge>=toLvl then
            local pr=RS:FindFirstChild("PickupPet",true) or RS:FindFirstChild("CollectPet",true)
            if pr then pcall(function() if pr:IsA("RemoteEvent") then pr:FireServer(item) else pr:InvokeServer(item) end end) end
            lvlStatusLbl.Text="✅ "..name.." sudah age "..currentAge
            continue
        end
        lvlStatusLbl.Text="⏳ "..name.." | Age "..currentAge.."/"..toLvl
        if levelRemote then pcall(function() if levelRemote:IsA("RemoteEvent") then levelRemote:FireServer(item) else levelRemote:InvokeServer(item) end end) end
        task.wait(0.5)
    end
end

lvlStartBtn.MouseButton1Click:Connect(function()
    if isLeveling then return end
    local cnt=0 for _ in pairs(selLvlPets) do cnt=cnt+1 end
    if cnt==0 then lvlStatusLbl.Text="⚠️ Pilih pet dulu!" lvlStatusLbl.TextColor3=C.Red task.wait(2) lvlStatusLbl.TextColor3=C.Gray return end
    isLeveling=true lvlStartBtn.Visible=false lvlStopBtn.Visible=true
    lvlStatusLbl.Text="▶ Leveling berjalan..."
    levelTask=task.spawn(function() while isLeveling do doLeveling() task.wait(1) end end)
end)

lvlStopBtn.MouseButton1Click:Connect(function()
    isLeveling=false if levelTask then task.cancel(levelTask) levelTask=nil end
    lvlStartBtn.Visible=true lvlStopBtn.Visible=false
    lvlStatusLbl.Text="■ Dihentikan" lvlStatusLbl.TextColor3=C.Gray
end)

-- ============================================
-- AUTO SWAP
-- ============================================
local swapSettings={} local isSwapping=false local swapTask=nil

secHead(SwapArea,"Pet Favorit (Auto Swap):",1)
local swapNote=lbl(SwapArea,"Hanya pet favorit",9,C.Gray) swapNote.Size=UDim2.new(1,-4,0,14) swapNote.LayoutOrder=2
local swapRefBtn=btn(SwapArea,"🔄 Refresh Pet Favorit",10,C.Panel,C.White)
swapRefBtn.Size=UDim2.new(1,-4,0,26) swapRefBtn.LayoutOrder=3 stroke(swapRefBtn,C.Dim,1.3)

local swapPetFrame=mk("Frame",{Size=UDim2.new(1,-4,0,0),BackgroundTransparency=1,AutomaticSize=Enum.AutomaticSize.Y,LayoutOrder=4,Parent=SwapArea})
mk("UIListLayout",{SortOrder=Enum.SortOrder.LayoutOrder,Padding=UDim.new(0,4),Parent=swapPetFrame})

local swapStatusLbl=lbl(SwapArea,"Status: Idle",10,C.Gray,Enum.TextXAlignment.Center)
swapStatusLbl.Size=UDim2.new(1,-4,0,16) swapStatusLbl.LayoutOrder=10
local swapStartBtn=btn(SwapArea,"▶ Start Auto Swap",11,C.ADim,C.Acc)
swapStartBtn.Size=UDim2.new(1,-4,0,28) swapStartBtn.LayoutOrder=11 stroke(swapStartBtn,C.Acc,1.8)
local swapStopBtn=btn(SwapArea,"■ Stop",11,C.RDim,C.Red)
swapStopBtn.Size=UDim2.new(1,-4,0,24) swapStopBtn.LayoutOrder=12 swapStopBtn.Visible=false stroke(swapStopBtn,C.Red,1.5)

local function buildSwapList()
    for _,c in pairs(swapPetFrame:GetChildren()) do if c:IsA("Frame") then c:Destroy() end end
    swapSettings={}
    local bp3=player:FindFirstChild("Backpack") if not bp3 then return end
    local n=0
    for _,item in pairs(bp3:GetChildren()) do
        if isPet(item) then
            local name,_,age,fav=parsePet(item)
            if fav then
                n=n+1
                if not swapSettings[name] then swapSettings[name]={delayPickup=1,delayEquip=1,item=item} end
                local card=mk("Frame",{Size=UDim2.new(1,0,0,56),BackgroundColor3=C.Card,BorderSizePixel=0,LayoutOrder=n,Parent=swapPetFrame})
                corner(card,7) stroke(card,C.Acc,1.2)
                local displayAge=age and ("[Age "..age.."]") or "[Age ?]"
                local nl=lbl(card,"⭐ "..name.." "..displayAge,10,C.Acc) nl.Size=UDim2.new(1,-4,0,18) nl.Position=UDim2.new(0,6,0,2)
                local dpRow=mk("Frame",{Size=UDim2.new(1,-8,0,17),Position=UDim2.new(0,4,0,22),BackgroundTransparency=1,Parent=card})
                lbl(dpRow,"Delay Pickup:",9,C.Gray).Size=UDim2.new(0,80,1,0)
                local dpBox=mk("TextBox",{Size=UDim2.new(0,38,1,-2),Position=UDim2.new(0,82,0,1),BackgroundColor3=C.Panel,Text="1",TextColor3=C.Gold,Font=Enum.Font.Gotham,TextSize=10,TextScaled=false,TextXAlignment=Enum.TextXAlignment.Center,ClearTextOnFocus=false,Parent=dpRow})
                corner(dpBox,4) stroke(dpBox,C.Dim,1)
                local dpU=lbl(dpRow,"dtk",9,C.Gray) dpU.Size=UDim2.new(0,24,1,0) dpU.Position=UDim2.new(0,124,0,0)
                local deRow=mk("Frame",{Size=UDim2.new(1,-8,0,17),Position=UDim2.new(0,4,0,38),BackgroundTransparency=1,Parent=card})
                lbl(deRow,"Delay Equip:",9,C.Gray).Size=UDim2.new(0,80,1,0)
                local deBox=mk("TextBox",{Size=UDim2.new(0,38,1,-2),Position=UDim2.new(0,82,0,1),BackgroundColor3=C.Panel,Text="1",TextColor3=C.Gold,Font=Enum.Font.Gotham,TextSize=10,TextScaled=false,TextXAlignment=Enum.TextXAlignment.Center,ClearTextOnFocus=false,Parent=deRow})
                corner(deBox,4) stroke(deBox,C.Dim,1)
                local deU=lbl(deRow,"dtk",9,C.Gray) deU.Size=UDim2.new(0,24,1,0) deU.Position=UDim2.new(0,124,0,0)
                dpBox:GetPropertyChangedSignal("Text"):Connect(function() local v=tonumber(dpBox.Text) if v then swapSettings[name].delayPickup=v end end)
                deBox:GetPropertyChangedSignal("Text"):Connect(function() local v=tonumber(deBox.Text) if v then swapSettings[name].delayEquip=v end end)
            end
        end
    end
    if n==0 then local e=lbl(swapPetFrame,"⚠️ Tidak ada pet favorit",10,C.Red,Enum.TextXAlignment.Center) e.Size=UDim2.new(1,0,0,26) end
end

swapRefBtn.MouseButton1Click:Connect(function() swapRefBtn.Text="⏳ Loading..." task.wait(0.3) buildSwapList() swapRefBtn.Text="🔄 Refresh Pet Favorit" end)

local function doSwap()
    local eqR=RS:FindFirstChild("EquipPet",true)
    local pkR=RS:FindFirstChild("PickupPet",true) or RS:FindFirstChild("UnequipPet",true)
    for name,data in pairs(swapSettings) do
        if not isSwapping then break end
        local item=data.item if not item or not item.Parent then continue end
        swapStatusLbl.Text="🔄 Swap: "..name
        task.wait(data.delayPickup or 1)
        if pkR then pcall(function() if pkR:IsA("RemoteEvent") then pkR:FireServer(item) else pkR:InvokeServer(item) end end) end
        task.wait(data.delayEquip or 1)
        if eqR then pcall(function() if eqR:IsA("RemoteEvent") then eqR:FireServer(item) else eqR:InvokeServer(item) end end) end
    end
end

swapStartBtn.MouseButton1Click:Connect(function()
    if isSwapping then return end
    if next(swapSettings)==nil then swapStatusLbl.Text="⚠️ Tidak ada pet favorit!" swapStatusLbl.TextColor3=C.Red task.wait(2) swapStatusLbl.TextColor3=C.Gray return end
    isSwapping=true swapStartBtn.Visible=false swapStopBtn.Visible=true
    swapStatusLbl.Text="▶ Auto Swap berjalan..."
    swapTask=task.spawn(function() while isSwapping do doSwap() task.wait(0.5) end end)
end)
swapStopBtn.MouseButton1Click:Connect(function()
    isSwapping=false if swapTask then task.cancel(swapTask) swapTask=nil end
    swapStartBtn.Visible=true swapStopBtn.Visible=false swapStatusLbl.Text="■ Dihentikan"
end)
buildSwapList()

-- ============================================
-- MISC - REJOIN
-- ============================================
local isAR=false local arTask=nil local arMin=cfg.rejoinMinutes or 30
local function doRejoin() TS:Teleport(game.PlaceId,player) end

secHead(MiscArea,"REJOIN SETTINGS",0)
local rnBtn=btn(MiscArea,"⚡ Rejoin Now",11,C.GDim,C.Green)
rnBtn.Size=UDim2.new(1,-4,0,30) rnBtn.LayoutOrder=1 stroke(rnBtn,C.Green,1.8)
rnBtn.MouseButton1Click:Connect(function() rnBtn.Text="⏳ Rejoining..." task.wait(1) doRejoin() end)

local setF=mk("Frame",{Size=UDim2.new(1,-4,0,32),BackgroundColor3=C.Card,BorderSizePixel=0,LayoutOrder=2,Parent=MiscArea})
corner(setF,7) stroke(setF,C.Dim,1.3)
local setL=lbl(setF,"Interval",10,C.Gray) setL.Size=UDim2.new(0.4,0,1,0) setL.Position=UDim2.new(0,8,0,0)
local minBox=mk("TextBox",{Size=UDim2.new(0,60,0,22),Position=UDim2.new(0.42,0,0.5,-11),BackgroundColor3=C.Panel,Text=tostring(arMin),TextColor3=C.Gold,Font=Enum.Font.GothamBold,TextSize=11,TextScaled=false,TextXAlignment=Enum.TextXAlignment.Center,ClearTextOnFocus=false,Parent=setF})
corner(minBox,5) stroke(minBox,C.Dim,1.2)
local mU=lbl(setF,"menit",10,C.Gray) mU.Size=UDim2.new(0,40,1,0) mU.Position=UDim2.new(0.42,64,0,0)
minBox:GetPropertyChangedSignal("Text"):Connect(function()
    local v=tonumber(minBox.Text) if v then arMin=math.max(1,math.min(120,v)) saveSettings({rejoinMinutes=arMin,autoRejoin=isAR}) end
end)

local autoF=mk("Frame",{Size=UDim2.new(1,-4,0,32),BackgroundColor3=C.Card,BorderSizePixel=0,LayoutOrder=3,Parent=MiscArea})
corner(autoF,7) local arStroke=stroke(autoF,C.Dim,1.3)
local arL=lbl(autoF,"Auto Rejoin",11,C.White) arL.Size=UDim2.new(0.6,0,1,0) arL.Position=UDim2.new(0,8,0,0)
local togBtn=btn(autoF,"OFF",10,C.RDim,C.Red) togBtn.Size=UDim2.new(0,48,0,20) togBtn.Position=UDim2.new(1,-54,0.5,-10)
local togStroke=stroke(togBtn,C.Red,1.3)
local cdLbl=lbl(MiscArea,"Auto Rejoin: OFF",10,C.Gray,Enum.TextXAlignment.Center)
cdLbl.Size=UDim2.new(1,-4,0,22) cdLbl.LayoutOrder=4 cdLbl.BackgroundColor3=C.Panel cdLbl.BackgroundTransparency=0
corner(cdLbl,6) stroke(cdLbl,C.Dim,1.2)

local function startAR()
    isAR=true togBtn.Text="ON" togBtn.BackgroundColor3=C.GDim togBtn.TextColor3=C.Green
    togStroke.Color=C.Green arStroke.Color=C.Green arStroke.Thickness=1.8
    arTask=task.spawn(function()
        while isAR do
            for i=arMin*60,1,-1 do if not isAR then break end cdLbl.Text=string.format("Rejoin dalam: %02d:%02d",math.floor(i/60),i%60) task.wait(1) end
            if isAR then cdLbl.Text="🔄 Rejoining..." task.wait(1) doRejoin() end
        end
    end)
end
local function stopAR()
    isAR=false togBtn.Text="OFF" togBtn.BackgroundColor3=C.RDim togBtn.TextColor3=C.Red
    togStroke.Color=C.Red arStroke.Color=C.Dim arStroke.Thickness=1.3
    cdLbl.Text="Auto Rejoin: OFF" if arTask then task.cancel(arTask) arTask=nil end
end
togBtn.MouseButton1Click:Connect(function() if isAR then stopAR() else startAR() end saveSettings({rejoinMinutes=arMin,autoRejoin=isAR}) end)

-- ============================================
-- AUTO GIFT - Helper functions
-- ============================================
local petGiftingService = RS:FindFirstChild("PetGiftingService",true)

-- Refresh remote saat dibutuhkan
local function getGiftRemote()
    if not petGiftingService or not petGiftingService.Parent then
        petGiftingService = RS:FindFirstChild("PetGiftingService",true)
    end
    return petGiftingService
end

-- Hitung pet yang cocok dengan filter slot
local function countSlotPets(slot)
    local bp3=player:FindFirstChild("Backpack")
    if not bp3 then return 0,{} end
    local items={}
    for _,item in pairs(bp3:GetChildren()) do
        if isPet(item) then
            local name,kg,age,fav,mutation=parsePet(item)
            if not kg then continue end
            if slot.skipFav and fav then continue end
            if slot.petType~="(Semua Pet)" and name~=slot.petType then continue end
            if slot.mutation~="(Semua / Tidak ada filter)" and mutation~=slot.mutation then continue end
            -- KG check
            local kgCheck = age and (kg*110/(age+10)) or kg
            local kgPass = slot.kgMode=="below" and kgCheck<slot.kgVal or kgCheck>=slot.kgVal
            if not kgPass then continue end
            -- Age check
            if age and slot.ageMode then
                local agePass = slot.ageMode=="below" and age<slot.ageVal or age>=slot.ageVal
                if not agePass then continue end
            end
            table.insert(items,item)
        end
    end
    return #items,items
end

-- ============================================
-- AUTO GIFT - Build slot UI
-- ============================================
secHead(GiftArea,"AUTO GIFT PET",0)

-- State per slot
local giftSlots = {}
for i=1,4 do
    giftSlots[i] = {
        target    = nil,
        petType   = "(Semua Pet)",
        mutation  = "(Semua / Tidak ada filter)",
        kgVal     = 1,
        kgMode    = "below",
        ageVal    = 1,
        ageMode   = "below",
        skipFav   = true,
        running   = false,
        slotTask  = nil,
        expanded  = false,
    }
end

local slotFrames = {}

local function makeDropdown(parent, defaultTxt, itemList, searchable, onSelect)
    local wrapper = mk("Frame",{
        Size=UDim2.new(1,0,0,0),
        BackgroundTransparency=1,
        AutomaticSize=Enum.AutomaticSize.Y,
        Parent=parent
    })

    local dropBtn2=btn(wrapper,defaultTxt,9,C.Panel,C.White)
    dropBtn2.Size=UDim2.new(1,0,0,24)
    dropBtn2.TextXAlignment=Enum.TextXAlignment.Left
    mk("UIPadding",{PaddingLeft=UDim.new(0,8),Parent=dropBtn2})
    stroke(dropBtn2,C.Dim,1.1)
    local arr=lbl(dropBtn2,"▾",10,C.Gray,Enum.TextXAlignment.Right)
    arr.Size=UDim2.new(0,18,1,0) arr.Position=UDim2.new(1,-20,0,0)

    local pickerFrame=mk("Frame",{
        Size=UDim2.new(1,0,0,0),
        BackgroundColor3=C.Panel,BorderSizePixel=0,
        AutomaticSize=Enum.AutomaticSize.Y,
        Visible=false,Parent=wrapper
    })
    corner(pickerFrame,6) stroke(pickerFrame,C.Acc,1.2)
    mk("UIPadding",{PaddingTop=UDim.new(0,3),PaddingLeft=UDim.new(0,4),PaddingRight=UDim.new(0,4),PaddingBottom=UDim.new(0,3),Parent=pickerFrame})

    local searchBox2=nil
    if searchable then
        searchBox2=mk("TextBox",{
            Size=UDim2.new(1,0,0,22),
            BackgroundColor3=C.Card,Text="",
            PlaceholderText="Cari...",PlaceholderColor3=C.Dim,
            TextColor3=C.White,Font=Enum.Font.Gotham,
            TextSize=9,TextScaled=false,ClearTextOnFocus=false,
            Parent=pickerFrame
        })
        corner(searchBox2,5) stroke(searchBox2,C.Dim,1)
        mk("UIPadding",{PaddingLeft=UDim.new(0,6),Parent=searchBox2})
    end

    local pickerScroll=mk("ScrollingFrame",{
        Size=UDim2.new(1,0,0,90),
        BackgroundTransparency=1,
        ScrollBarThickness=3,ScrollBarImageColor3=C.Acc,
        CanvasSize=UDim2.new(0,0,0,0),
        AutomaticCanvasSize=Enum.AutomaticSize.Y,
        Parent=pickerFrame
    })
    mk("UIListLayout",{SortOrder=Enum.SortOrder.LayoutOrder,Padding=UDim.new(0,2),Parent=pickerScroll})
    mk("UIListLayout",{SortOrder=Enum.SortOrder.LayoutOrder,Padding=UDim.new(0,2),Parent=pickerFrame})

    local isOpen=false
    local currentLabel=defaultTxt

    local function buildList(filter)
        for _,c in pairs(pickerScroll:GetChildren()) do if c:IsA("TextButton") then c:Destroy() end end
        local n=0
        for _,itm in ipairs(itemList) do
            local show = not filter or filter=="" or tostring(itm):lower():find(filter:lower(),1,true)
            if show then
                n=n+1
                local isSel = tostring(itm)==currentLabel
                local b2=btn(pickerScroll,tostring(itm),9,isSel and C.ADim or C.Card,isSel and C.Acc or C.White)
                b2.Size=UDim2.new(1,-4,0,22) b2.LayoutOrder=n b2.TextXAlignment=Enum.TextXAlignment.Left
                mk("UIPadding",{PaddingLeft=UDim.new(0,6),Parent=b2})
                b2.MouseButton1Click:Connect(function()
                    currentLabel=tostring(itm)
                    dropBtn2.Text=currentLabel
                    pickerFrame.Visible=false isOpen=false
                    buildList(searchBox2 and searchBox2.Text or "")
                    onSelect(itm)
                end)
            end
        end
    end

    buildList("")
    if searchBox2 then
        searchBox2:GetPropertyChangedSignal("Text"):Connect(function() buildList(searchBox2.Text) end)
    end

    dropBtn2.MouseButton1Click:Connect(function()
        isOpen=not isOpen pickerFrame.Visible=isOpen
    end)

    return wrapper, dropBtn2, function(v) currentLabel=v dropBtn2.Text=v buildList("") end
end

-- Row helper
local function formRow2(parent, labelTxt, height)
    local row=mk("Frame",{
        Size=UDim2.new(1,-4,0,height or 30),
        BackgroundColor3=C.Card,BorderSizePixel=0,
        Parent=parent
    })
    corner(row,6) stroke(row,C.Dim,1.1)
    local l=lbl(row,labelTxt,9,C.Gray)
    l.Size=UDim2.new(0.4,0,1,0) l.Position=UDim2.new(0,8,0,0)
    return row
end

-- Buat 4 slot gift
for slotIdx=1,4 do
    local slot=giftSlots[slotIdx]

    -- Header slot (bisa diklik untuk expand)
    local slotHeader=btn(GiftArea,"Gift "..slotIdx.."  ▶",10,C.Card,C.White)
    slotHeader.Size=UDim2.new(1,-4,0,30) slotHeader.LayoutOrder=slotIdx*20
    slotHeader.TextXAlignment=Enum.TextXAlignment.Left
    mk("UIPadding",{PaddingLeft=UDim.new(0,10),Parent=slotHeader})
    local slotStroke=stroke(slotHeader,C.Dim,1.2)

    -- Status label di kanan header
    local slotStatus=lbl(slotHeader,"OFF",9,C.Gray,Enum.TextXAlignment.Right)
    slotStatus.Size=UDim2.new(0,40,1,0) slotStatus.Position=UDim2.new(1,-44,0,0)

    -- Body slot (collapsible)
    local slotBody=mk("Frame",{
        Size=UDim2.new(1,-4,0,0),
        BackgroundColor3=C.Panel,BorderSizePixel=0,
        AutomaticSize=Enum.AutomaticSize.Y,
        Visible=false,
        LayoutOrder=slotIdx*20+1,
        Parent=GiftArea
    })
    corner(slotBody,7) stroke(slotBody,C.Acc,1.3)
    mk("UIPadding",{PaddingTop=UDim.new(0,6),PaddingLeft=UDim.new(0,6),PaddingRight=UDim.new(0,6),PaddingBottom=UDim.new(0,6),Parent=slotBody})
    mk("UIListLayout",{SortOrder=Enum.SortOrder.LayoutOrder,Padding=UDim.new(0,4),Parent=slotBody})

    slotFrames[slotIdx]={header=slotHeader,body=slotBody,status=slotStatus,stroke=slotStroke}

    -- Toggle expand
    slotHeader.MouseButton1Click:Connect(function()
        slot.expanded=not slot.expanded
        slotBody.Visible=slot.expanded
        slotHeader.Text="Gift "..slotIdx.."  "..(slot.expanded and "▼" or "▶")
    end)

    -- ---- CONTENT DALAM SLOT ----

    -- Target Player
    local tRow=formRow2(slotBody,"Target")
    local playerList={"(Belum dipilih)"}
    for _,p in pairs(Players:GetPlayers()) do
        if p.Name~=player.Name then table.insert(playerList,p.Name) end
    end
    local _,tBtn,tSetVal=makeDropdown(tRow,"(Belum dipilih)",playerList,false,function(v)
        slot.target = v=="(Belum dipilih)" and nil or v
    end)
    tBtn.Size=UDim2.new(0.58,0,0,22) tBtn.Position=UDim2.new(0.41,0,0.5,-11)

    -- Refresh player
    local rfSlotBtn=btn(slotBody,"🔄 Refresh Player",9,C.Panel,C.Gray)
    rfSlotBtn.Size=UDim2.new(1,0,0,22) rfSlotBtn.LayoutOrder=2
    stroke(rfSlotBtn,C.Dim,1)
    rfSlotBtn.MouseButton1Click:Connect(function()
        playerList={"(Belum dipilih)"}
        for _,p in pairs(Players:GetPlayers()) do
            if p.Name~=player.Name then table.insert(playerList,p.Name) end
        end
        tSetVal("(Belum dipilih)") slot.target=nil
    end)

    -- Pet Type
    local pRow=formRow2(slotBody,"Pet Type")
    local petListWithAll={"(Semua Pet)"}
    for _,v in ipairs(PETS) do table.insert(petListWithAll,v) end
    local _,pBtn2,pSetVal=makeDropdown(pRow,"(Semua Pet)",petListWithAll,true,function(v)
        slot.petType=v
    end)
    pBtn2.Size=UDim2.new(0.58,0,0,22) pBtn2.Position=UDim2.new(0.41,0,0.5,-11)

    -- Mutation Filter
    local mRow=formRow2(slotBody,"Mutasi")
    local _,mBtn2,mSetVal=makeDropdown(mRow,"(Semua)",MUTATIONS,true,function(v)
        slot.mutation=v
    end)
    mBtn2.Size=UDim2.new(0.58,0,0,22) mBtn2.Position=UDim2.new(0.41,0,0.5,-11)

    -- Age filter
    local ageRow2=formRow2(slotBody,"Age")
    local aModeBtn=btn(ageRow2,"−",12,C.RDim,C.Red)
    aModeBtn.Size=UDim2.new(0,22,0,20) aModeBtn.Position=UDim2.new(0.41,0,0.5,-10)
    local aMS=stroke(aModeBtn,C.Red,1.1)
    local aBox=mk("TextBox",{Size=UDim2.new(0,50,0,20),Position=UDim2.new(0.41,26,0.5,-10),BackgroundColor3=C.Panel,Text="1",TextColor3=C.Gold,Font=Enum.Font.GothamBold,TextSize=10,TextScaled=false,TextXAlignment=Enum.TextXAlignment.Center,ClearTextOnFocus=false,Parent=ageRow2})
    corner(aBox,4) stroke(aBox,C.Dim,1)
    local aDesc=lbl(ageRow2,"< 1",8,C.Gray,Enum.TextXAlignment.Right) aDesc.Size=UDim2.new(0,40,1,0) aDesc.Position=UDim2.new(1,-44,0,0)
    local function updASlot()
        if slot.ageMode=="below" then
            aModeBtn.Text="−" aModeBtn.BackgroundColor3=C.RDim aModeBtn.TextColor3=C.Red aMS.Color=C.Red aDesc.Text="< "..slot.ageVal
        else
            aModeBtn.Text="+" aModeBtn.BackgroundColor3=C.GDim aModeBtn.TextColor3=C.Green aMS.Color=C.Green aDesc.Text="≥ "..slot.ageVal
        end
    end
    aModeBtn.MouseButton1Click:Connect(function() slot.ageMode=slot.ageMode=="below" and "above" or "below" updASlot() end)
    aBox:GetPropertyChangedSignal("Text"):Connect(function() local v=tonumber(aBox.Text) if v then slot.ageVal=v updASlot() end end)

    -- KG filter
    local kgRow2=formRow2(slotBody,"KG (age 100)")
    local kModeBtn=btn(kgRow2,"−",12,C.RDim,C.Red)
    kModeBtn.Size=UDim2.new(0,22,0,20) kModeBtn.Position=UDim2.new(0.41,0,0.5,-10)
    local kMS=stroke(kModeBtn,C.Red,1.1)
    local kBox=mk("TextBox",{Size=UDim2.new(0,50,0,20),Position=UDim2.new(0.41,26,0.5,-10),BackgroundColor3=C.Panel,Text="1",TextColor3=C.Gold,Font=Enum.Font.GothamBold,TextSize=10,TextScaled=false,TextXAlignment=Enum.TextXAlignment.Center,ClearTextOnFocus=false,Parent=kgRow2})
    corner(kBox,4) stroke(kBox,C.Dim,1)
    local kDesc=lbl(kgRow2,"< 1kg",8,C.Gray,Enum.TextXAlignment.Right) kDesc.Size=UDim2.new(0,44,1,0) kDesc.Position=UDim2.new(1,-48,0,0)
    local function updKSlot()
        if slot.kgMode=="below" then
            kModeBtn.Text="−" kModeBtn.BackgroundColor3=C.RDim kModeBtn.TextColor3=C.Red kMS.Color=C.Red kDesc.Text="< "..slot.kgVal.."kg"
        else
            kModeBtn.Text="+" kModeBtn.BackgroundColor3=C.GDim kModeBtn.TextColor3=C.Green kMS.Color=C.Green kDesc.Text="≥ "..slot.kgVal.."kg"
        end
    end
    kModeBtn.MouseButton1Click:Connect(function() slot.kgMode=slot.kgMode=="below" and "above" or "below" updKSlot() end)
    kBox:GetPropertyChangedSignal("Text"):Connect(function() local v=tonumber(kBox.Text) if v then slot.kgVal=v updKSlot() end end)

    -- Skip favorit
    local favRow2=formRow2(slotBody,"Skip Favorit")
    local favTog2=btn(favRow2,"ON",9,C.GDim,C.Green)
    favTog2.Size=UDim2.new(0,40,0,20) favTog2.Position=UDim2.new(1,-44,0.5,-10)
    local favTS2=stroke(favTog2,C.Green,1.1)
    favTog2.MouseButton1Click:Connect(function()
        slot.skipFav=not slot.skipFav
        if slot.skipFav then favTog2.Text="ON" favTog2.BackgroundColor3=C.GDim favTog2.TextColor3=C.Green favTS2.Color=C.Green
        else favTog2.Text="OFF" favTog2.BackgroundColor3=C.RDim favTog2.TextColor3=C.Red favTS2.Color=C.Red end
    end)

    -- Preview
    local prevLbl=lbl(slotBody,"0 pet siap di-gift",9,C.Gray,Enum.TextXAlignment.Center)
    prevLbl.Size=UDim2.new(1,0,0,14)

    local function updateSlotPreview()
        local cnt,_=countSlotPets(slot)
        prevLbl.Text=cnt.." pet siap di-gift"
        prevLbl.TextColor3=cnt>0 and C.Acc or C.Gray
    end

    aModeBtn.MouseButton1Click:Connect(updateSlotPreview)
    aBox:GetPropertyChangedSignal("Text"):Connect(updateSlotPreview)
    kModeBtn.MouseButton1Click:Connect(updateSlotPreview)
    kBox:GetPropertyChangedSignal("Text"):Connect(updateSlotPreview)
    favTog2.MouseButton1Click:Connect(updateSlotPreview)

    -- Start/Stop button
    local slotStartBtn=btn(slotBody,"▶ Start Gift "..slotIdx,10,C.ADim,C.Acc)
    slotStartBtn.Size=UDim2.new(1,0,0,28)
    stroke(slotStartBtn,C.Acc,1.8)

    local slotStopBtn=btn(slotBody,"■ Stop",10,C.RDim,C.Red)
    slotStopBtn.Size=UDim2.new(1,0,0,24)
    slotStopBtn.Visible=false stroke(slotStopBtn,C.Red,1.5)

    slotStartBtn.MouseButton1Click:Connect(function()
        if slot.running then return end
        if not slot.target then
            prevLbl.Text="⚠️ Pilih player dulu!" prevLbl.TextColor3=C.Red
            task.wait(2) updateSlotPreview() return
        end
        local tp=Players:FindFirstChild(slot.target)
        if not tp then
            prevLbl.Text="⚠️ Player tidak ditemukan!" prevLbl.TextColor3=C.Red
            task.wait(2) updateSlotPreview() return
        end
        local cnt,toGift=countSlotPets(slot)
        if cnt==0 then
            prevLbl.Text="⚠️ Tidak ada pet cocok!" prevLbl.TextColor3=C.Red
            task.wait(2) updateSlotPreview() return
        end

        local gr=getGiftRemote()
        if not gr then
            prevLbl.Text="⚠️ Remote tidak ditemukan!" prevLbl.TextColor3=C.Red
            task.wait(2) updateSlotPreview() return
        end

        local char=player.Character
        if not char then return end

        slot.running=true
        slotStartBtn.Visible=false slotStopBtn.Visible=true
        slotStatus.Text="ON" slotStatus.TextColor3=C.Green
        slotStroke.Color=C.Green

        slot.slotTask=task.spawn(function()
            local ok2,fail=0,0
            for _,item in pairs(toGift) do
                if not slot.running then break end
                if not item or not item.Parent then continue end
                local oldPar=item.Parent
                item.Parent=char
                task.wait(0.3)
                local r=pcall(function() gr:FireServer("GivePet",tp) end)
                if r then ok2=ok2+1 else pcall(function() item.Parent=oldPar end) fail=fail+1 end
                task.wait(0.5)
            end
            slot.running=false
            slotStartBtn.Visible=true slotStopBtn.Visible=false
            slotStatus.Text="OFF" slotStatus.TextColor3=C.Gray slotStroke.Color=C.Dim
            prevLbl.Text=string.format("✅ %d berhasil  ❌ %d gagal",ok2,fail)
            prevLbl.TextColor3=ok2>0 and C.Green or C.Red
            task.wait(3) updateSlotPreview()
        end)
    end)

    slotStopBtn.MouseButton1Click:Connect(function()
        slot.running=false
        if slot.slotTask then task.cancel(slot.slotTask) slot.slotTask=nil end
        slotStartBtn.Visible=true slotStopBtn.Visible=false
        slotStatus.Text="OFF" slotStatus.TextColor3=C.Gray slotStroke.Color=C.Dim
        prevLbl.Text="■ Dihentikan" updateSlotPreview()
    end)
end

-- ============================================
-- AUTO ACCEPT GIFT & TRADE
-- ============================================
divLine(GiftArea, 100)

local acceptHead=btn(GiftArea,"Auto Accept Gift / Trade  ▶",10,C.Card,C.White)
acceptHead.Size=UDim2.new(1,-4,0,30) acceptHead.LayoutOrder=101
acceptHead.TextXAlignment=Enum.TextXAlignment.Left
mk("UIPadding",{PaddingLeft=UDim.new(0,10),Parent=acceptHead})
stroke(acceptHead,C.Dim,1.2)

local acceptBody=mk("Frame",{
    Size=UDim2.new(1,-4,0,0),BackgroundColor3=C.Panel,BorderSizePixel=0,
    AutomaticSize=Enum.AutomaticSize.Y,Visible=false,LayoutOrder=102,Parent=GiftArea
})
corner(acceptBody,7) stroke(acceptBody,C.Acc,1.3)
mk("UIPadding",{PaddingTop=UDim.new(0,6),PaddingLeft=UDim.new(0,6),PaddingRight=UDim.new(0,6),PaddingBottom=UDim.new(0,6),Parent=acceptBody})
mk("UIListLayout",{SortOrder=Enum.SortOrder.LayoutOrder,Padding=UDim.new(0,4),Parent=acceptBody})

local acceptExpanded=false
acceptHead.MouseButton1Click:Connect(function()
    acceptExpanded=not acceptExpanded
    acceptBody.Visible=acceptExpanded
    acceptHead.Text="Auto Accept Gift / Trade  "..(acceptExpanded and "▼" or "▶")
end)

-- Auto Accept Trade
local autoTrade=false
local tradeRow=formRow2(acceptBody,"Auto Accept Trade")
tradeRow.Parent=acceptBody tradeRow.LayoutOrder=1
local tradeTog=btn(tradeRow,"OFF",9,C.RDim,C.Red)
tradeTog.Size=UDim2.new(0,44,0,20) tradeTog.Position=UDim2.new(1,-48,0.5,-10)
local tradeTS=stroke(tradeTog,C.Red,1.1)
tradeTog.MouseButton1Click:Connect(function()
    autoTrade=not autoTrade
    if autoTrade then tradeTog.Text="ON" tradeTog.BackgroundColor3=C.GDim tradeTog.TextColor3=C.Green tradeTS.Color=C.Green
    else tradeTog.Text="OFF" tradeTog.BackgroundColor3=C.RDim tradeTog.TextColor3=C.Red tradeTS.Color=C.Red end
end)

-- Auto Accept Gift
local autoGift=false
local giftAccRow=formRow2(acceptBody,"Auto Accept Gift")
giftAccRow.Parent=acceptBody giftAccRow.LayoutOrder=2
local giftAccTog=btn(giftAccRow,"OFF",9,C.RDim,C.Red)
giftAccTog.Size=UDim2.new(0,44,0,20) giftAccTog.Position=UDim2.new(1,-48,0.5,-10)
local giftAccTS=stroke(giftAccTog,C.Red,1.1)
giftAccTog.MouseButton1Click:Connect(function()
    autoGift=not autoGift
    if autoGift then giftAccTog.Text="ON" giftAccTog.BackgroundColor3=C.GDim giftAccTog.TextColor3=C.Green giftAccTS.Color=C.Green
    else giftAccTog.Text="OFF" giftAccTog.BackgroundColor3=C.RDim giftAccTog.TextColor3=C.Red giftAccTS.Color=C.Red end
end)

local accStatusLbl=lbl(acceptBody,"Status: Menunggu...",9,C.Gray,Enum.TextXAlignment.Center)
accStatusLbl.Size=UDim2.new(1,0,0,14) accStatusLbl.LayoutOrder=3

-- Hook untuk auto accept
pcall(function()
    hookmetamethod(game,"__namecall",function(self,...)
        local method=getnamecallmethod()
        if method=="FireServer" or method=="InvokeServer" then
            local name=self.Name
            -- Auto Accept Gift
            if autoGift and (name:find("Gift") or name:find("gift")) then
                local args={...}
                -- Cari remote accept gift
                local acceptRemote=RS:FindFirstChild("AcceptGift",true)
                    or RS:FindFirstChild("GiftAccept",true)
                if acceptRemote then
                    pcall(function() acceptRemote:FireServer(table.unpack(args)) end)
                    accStatusLbl.Text="🎁 Gift diterima!"
                    accStatusLbl.TextColor3=C.Green
                end
            end
            -- Auto Accept Trade
            if autoTrade and (name:find("Trade") or name:find("trade")) then
                local acceptTradeRemote=RS:FindFirstChild("AcceptTrade",true)
                    or RS:FindFirstChild("TradeAccept",true)
                if acceptTradeRemote then
                    pcall(function() acceptTradeRemote:FireServer() end)
                    accStatusLbl.Text="🤝 Trade diterima!"
                    accStatusLbl.TextColor3=C.Green
                end
            end
        end
        return self[method](self,...)
    end)
end)

-- Hook GiftPrompted untuk auto accept gift yang masuk
pcall(function()
    local giftPrompted=RS:FindFirstChild("GameEvents",true)
    if giftPrompted then
        local giftFolder=giftPrompted:FindFirstChild("Gift")
        if giftFolder then
            local giftPromptedRE=giftFolder:FindFirstChild("GiftPrompted")
            if giftPromptedRE then
                giftPromptedRE.OnClientEvent:Connect(function(...)
                    if autoGift then
                        local acceptR=giftFolder:FindFirstChild("AcceptGift")
                            or giftFolder:FindFirstChild("ConfirmGift")
                        if acceptR then
                            task.wait(0.2)
                            pcall(function() acceptR:FireServer(...) end)
                            accStatusLbl.Text="🎁 Gift otomatis diterima!"
                            accStatusLbl.TextColor3=C.Green
                        end
                    end
                end)
            end
        end
    end
end)

-- Hook TradeEvents untuk auto accept trade
pcall(function()
    local gameEventsFolder=RS:FindFirstChild("GameEvents")
    if gameEventsFolder then
        local tradeFolder=gameEventsFolder:FindFirstChild("TradeEvents")
        if tradeFolder then
            for _,child in pairs(tradeFolder:GetChildren()) do
                if child:IsA("RemoteEvent") and child.Name:find("Request") then
                    child.OnClientEvent:Connect(function(...)
                        if autoTrade then
                            local acceptR=tradeFolder:FindFirstChild("AcceptTrade")
                                or tradeFolder:FindFirstChild("ReplyTrade")
                            if acceptR then
                                task.wait(0.2)
                                pcall(function() acceptR:FireServer(true,...) end)
                                accStatusLbl.Text="🤝 Trade otomatis diterima!"
                                accStatusLbl.TextColor3=C.Green
                            end
                        end
                    end)
                end
            end
        end
    end
end)

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
    for _,slot in ipairs(giftSlots) do
        slot.running=false
        if slot.slotTask then task.cancel(slot.slotTask) end
    end
    if playerGui:FindFirstChild("ZenxHub") then playerGui.ZenxHub:Destroy() end
    if playerGui:FindFirstChild("ZenxHubLogo") then playerGui.ZenxHubLogo:Destroy() end
end)

if cfg.autoRejoin==true then task.wait(1) startAR() end

switchSide(1)
print("[ZenxHub] "..username.." | v2.0 Loaded! 🌱")
