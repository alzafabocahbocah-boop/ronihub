-- ============= ZENX LVL DEBUG =============
local SCRIPT_VERSION="v12.78"
print("==== [ZenxLvl] SCRIPT MULAI LOAD ("..SCRIPT_VERSION..") ====")
warn("[ZenxLvl] versi: "..SCRIPT_VERSION.." (misc rewrite v1.4 IIFE+M78)")

local RS = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local HS = game:GetService("HttpService")
local TS = game:GetService("TeleportService")
local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui",10)
print("[ZenxLvl] step 1 OK - services loaded")

-- ============= MULTI-PARENT GUI HELPER =============
local function safeParent(scrgui)
    local ok1=pcall(function()
        if gethui then scrgui.Parent=gethui() end
    end)
    if ok1 and scrgui.Parent then return "gethui()" end
    if playerGui then
        local ok2=pcall(function() scrgui.Parent=playerGui end)
        if ok2 and scrgui.Parent then return "PlayerGui" end
    end
    local ok3=pcall(function() scrgui.Parent=game:GetService("CoreGui") end)
    if ok3 and scrgui.Parent then return "CoreGui" end
    return nil
end

local function getGuiContainer()
    if gethui then
        local ok,h=pcall(function() return gethui() end)
        if ok and h then return h end
    end
    return playerGui or game:GetService("CoreGui")
end

local guiContainer=getGuiContainer()
pcall(function()
    if guiContainer:FindFirstChild("ZenxLvlGui") then guiContainer.ZenxLvlGui:Destroy() end
    if guiContainer:FindFirstChild("ZenxShowBtn") then guiContainer.ZenxShowBtn:Destroy() end
    if guiContainer:FindFirstChild("ZenxDebug") then guiContainer.ZenxDebug:Destroy() end
    if guiContainer:FindFirstChild("ZenxLogo") then guiContainer.ZenxLogo:Destroy() end
end)

local debugSg, debugLbl
local _dbgLines = {}
-- v9.9: debug GUI dihapus (print ke console aja)

local function dbg(msg)
    print("[ZenxDbg] "..msg)
    table.insert(_dbgLines, "> "..msg)
    while #_dbgLines > 500 do table.remove(_dbgLines, 1) end
    if debugLbl then
        local startIdx = math.max(1, #_dbgLines - 100)
        local visible = {}
        for i = startIdx, #_dbgLines do table.insert(visible, _dbgLines[i]) end
        debugLbl.Text = table.concat(visible, "\n")
    end
end
dbg("Step 1 OK: services + playerGui")

-- ===== REMOTES (LEVELING/SWAP) =====
local equipRE = nil
local getCooldownRF = nil
for _,v in pairs(RS:GetDescendants()) do
    if v.Name=="PetsService" and (v:IsA("RemoteEvent") or v:IsA("RemoteFunction")) then
        equipRE=v
    end
    if v.Name=="GetPetCooldown" and v:IsA("RemoteFunction") then
        getCooldownRF=v
    end
end
local gameEvents = RS:WaitForChild("GameEvents",10)
if not gameEvents then
    warn("[ZenxLvl] GameEvents folder TIDAK ditemukan di ReplicatedStorage. Beberapa fitur mungkin tidak jalan.")
    gameEvents = Instance.new("Folder")
end
local petLeadRE = gameEvents:WaitForChild("PetLeadService_RE",5)
if not petLeadRE then
    warn("[ZenxLvl] PetLeadService_RE TIDAK ditemukan. Cari alternatif...")
    for _,n in ipairs({"PetService_RE","PetsService_RE","PetActionService_RE","PetService"}) do
        local r=gameEvents:FindFirstChild(n)
        if r and (r:IsA("RemoteEvent") or r:IsA("RemoteFunction")) then
            petLeadRE=r print("[ZenxLvl] Pakai fallback remote: "..n) break
        end
    end
    if not petLeadRE then
        warn("[ZenxLvl] Tidak ada remote pet ketemu. Fitur leveling/swap tidak akan jalan, tapi GUI tetap loaded.")
        petLeadRE=Instance.new("RemoteEvent")
    end
end
if not equipRE then equipRE = petLeadRE end
dbg("Step 2 OK: remotes ("..tostring(equipRE.Name)..", "..tostring(petLeadRE.Name)..", CD="..(getCooldownRF and "OK" or "no")..")")

local DATA_FILE="ZenxLvlData.json"
local function loadData()
    local ok,content=pcall(readfile,DATA_FILE)
    if ok and content and content~="" then
        local ok2,parsed=pcall(function() return HS:JSONDecode(content) end)
        if ok2 and parsed then return parsed end
    end
    return nil
end
local function saveToFile(data)
    local ok,encoded=pcall(function() return HS:JSONEncode(data) end)
    if ok then pcall(writefile,DATA_FILE,encoded) end
end

local loaded=loadData()
if not getgenv().ZenxData then
    getgenv().ZenxData=loaded or {
        config={equipInterval=5,rejoinMinutes=30},
        targetPetTypes={},
        fromAge=1,toAge=100,maxPetTarget=1,
        autoStartEnabled=false,autoRejoin=false,
        autoAccGift=false,autoAccTrade=false,
    }
elseif loaded then
    for k,v in pairs(loaded) do getgenv().ZenxData[k]=v end
end
local d=getgenv().ZenxData
dbg("Step 3 OK: data loaded")

-- v11.6: toAge declared EARLY (sebelum donesLbl spawn + _doBuildInvShow function)
-- biar ke-capture sebagai upvalue, bukan global nil
local toAge=d.toAge or 100

-- v11.5: declare toAge SEBELUM function definitions yg pakai (donesLbl, _doBuildInvShow)
-- biar ke-capture sebagai upvalue/local, bukan global nil

if not d.swapPerPetVersion or d.swapPerPetVersion < 9 then
    d.swapPerPet = d.swapPerPet or {}
    if d.swapPerPet then
        for uuid,cfg in pairs(d.swapPerPet) do
            d.swapPerPet[uuid]={enabled=cfg.enabled==true}
        end
    end
    d.swapConfig = nil
    d.swapPerPetVersion = 9
end

local C={
    BG=Color3.fromRGB(15,15,15),Panel=Color3.fromRGB(21,21,21),Card=Color3.fromRGB(25,25,25),
    White=Color3.fromRGB(225,225,225),Gray=Color3.fromRGB(120,120,120),Dim=Color3.fromRGB(55,55,55),
    Green=Color3.fromRGB(70,190,90),Red=Color3.fromRGB(200,60,60),RDim=Color3.fromRGB(35,10,10),
    Gold=Color3.fromRGB(220,160,0),Blue=Color3.fromRGB(80,150,255),
    Teal=Color3.fromRGB(40,200,160),TDim=Color3.fromRGB(8,30,24),
}

local function mk(cls,props)
    local o=Instance.new(cls) for k,v in pairs(props) do o[k]=v end return o
end
local function corner(p,r) return mk("UICorner",{CornerRadius=UDim.new(0,r or 7),Parent=p}) end
local function stroke(p,col,th) return mk("UIStroke",{Color=col or C.Teal,Thickness=th or 1.5,Parent=p}) end
local function lbl(p,txt,ts,col,xa)
    local l=mk("TextLabel",{BackgroundTransparency=1,Text=txt,TextColor3=col or C.White,
        Font=Enum.Font.GothamBold,TextSize=ts or 11,TextScaled=false,
        TextXAlignment=xa or Enum.TextXAlignment.Left,Parent=p}) return l
end
local function btn(p,txt,ts,bg,tc)
    local b=mk("TextButton",{BackgroundColor3=bg or C.Card,Text=txt,TextColor3=tc or C.White,
        Font=Enum.Font.GothamBold,TextSize=ts or 11,TextScaled=false,AutoButtonColor=false,Parent=p})
    corner(b,7) return b
end
local function div(parent,lo)
    return mk("Frame",{Size=UDim2.new(1,0,0,1),BackgroundColor3=C.Dim,BorderSizePixel=0,LayoutOrder=lo,Parent=parent})
end
local function togRow(parent,labelTxt,descTxt,lo)
    local row=mk("Frame",{Size=UDim2.new(1,0,0,32),BackgroundColor3=C.Card,BorderSizePixel=0,LayoutOrder=lo,Parent=parent})
    corner(row,6) local rowStroke=stroke(row,C.Dim,1.1)
    local l=lbl(row,labelTxt,11,C.White) l.Size=UDim2.new(0.65,0,0,16) l.Position=UDim2.new(0,8,0,4)
    if descTxt then local dl=lbl(row,descTxt,10,C.Dim) dl.Size=UDim2.new(0.75,0,0,11) dl.Position=UDim2.new(0,8,0,19) end
    local tog=btn(row,"OFF",11,C.Panel,C.Gray) tog.Size=UDim2.new(0,44,0,20) tog.Position=UDim2.new(1,-50,0.5,-10)
    local togStroke=stroke(tog,C.Dim,1.1)
    return row,tog,togStroke,rowStroke
end

local function isPet(item) return item:FindFirstChild("PetToolLocal") or item:FindFirstChild("PetToolServer") end
local function isFavorite(item)
    for _,attr in ipairs({"Loved","IsLoved","Heart","Hearted","Liked","IsLiked","IsHeart","Love","HeartIcon","Favorited","Favourited","Favorite","Favourite","IsFavorited","IsFavourited"}) do
        local v=item:GetAttribute(attr)
        if v==true then return true end
    end
    local d=item:GetAttribute("d")
    if d==true then return true end
    return false
end
local function getAge(item)
    for _,pat in ipairs({"%[Age%s+(%d+)%]","%[Age(%d+)%]"}) do
        local f=item.Name:match(pat) if f then return tonumber(f) end
    end return nil
end
local function getPetName(item) return item.Name:match("^(.-)%s*%[") or item.Name end
local function getKG(item) return tonumber(item.Name:match("%[([%d%.]+)%s*[Kk][Gg]%]")) end
local function getPetUUID(item) return item:GetAttribute("PET_UUID") end

local function fmtUUID(uuid)
    local s=tostring(uuid)
    if s:sub(1,1)~="{" then s="{"..s.."}" end
    return s
end

-- ===== EQUIP / UNEQUIP =====
local function equipPet(uuid)
    local u=fmtUUID(uuid)
    pcall(function() equipRE:FireServer("EquipPet",u,nil) end)
    pcall(function() petLeadRE:FireServer("EquipPet",u,nil) end)
end
local function unequipPet(uuid)
    local u=fmtUUID(uuid)
    pcall(function() equipRE:FireServer("UnequipPet",u) end)
    pcall(function() petLeadRE:FireServer("UnequipPet",u) end)
end

-- ===== SWAP MECHANIC (FRIEND-7 PERSIS) =====
local function swapPet(uuid)
    local u=fmtUUID(uuid)
    pcall(function() equipRE:FireServer("UnequipPet",u) end)
    task.wait(0.02)
    pcall(function() equipRE:FireServer("EquipPet",u,nil) end)
end

local function getCooldownRaw(uuid)
    if not getCooldownRF then return nil end
    local u=fmtUUID(uuid)
    local ok,res=pcall(function() return getCooldownRF:InvokeServer(u) end)
    if not ok then return nil end
    return res
end

local function getPetTime(uuid)
    local res=getCooldownRaw(uuid)
    if type(res)~="table" then return nil end
    if next(res)==nil then return nil end
    local sub=res[1]
    if type(sub)~="table" then return nil end
    if type(sub.Time)=="number" then return sub.Time end
    return nil
end

-- ============================================
-- HELPER PLACED PET / AGE
-- ============================================
local function findPlacedPetByUUID(uuid)
    local uuidStr=tostring(uuid)
    local uuidBracket=uuidStr
    if uuidBracket:sub(1,1)~="{" then uuidBracket="{"..uuidBracket.."}" end
    local petsPhys=workspace:FindFirstChild("PetsPhysical")
    if petsPhys then
        local petMover=petsPhys:FindFirstChild("PetMover")
        if petMover then
            local m=petMover:FindFirstChild(uuidBracket) or petMover:FindFirstChild(uuidStr)
            if m then return m end
            for _,child in ipairs(petMover:GetChildren()) do
                if child.Name==uuidBracket or child.Name==uuidStr then return child end
            end
        end
    end
    for _,n in ipairs({"Pets","PlacedPets","ActivePets"}) do
        local f=workspace:FindFirstChild(n)
        if f then
            for _,m in ipairs(f:GetDescendants()) do
                if m:GetAttribute("PET_UUID")==uuid or m.Name==uuidBracket or m.Name==uuidStr then return m end
            end
        end
    end
    for _,m in ipairs(workspace:GetDescendants()) do
        if m:IsA("Model") and (m.Name==uuidBracket or m.Name==uuidStr) then return m end
        local ok,uid=pcall(function() return m:GetAttribute("PET_UUID") end)
        if ok and uid==uuid then return m end
    end
    return nil
end

local function getPlacedPetAge(placedModel)
    if not placedModel then return nil end
    local modelName=placedModel.Name
    local uuidStr=modelName:gsub("^{",""):gsub("}$","")
    if #uuidStr>=20 then
        local pg=player:FindFirstChild("PlayerGui")
        local activePetUI=pg and pg:FindFirstChild("ActivePetUI")
        if activePetUI then
            local petFrame=activePetUI:FindFirstChild("{"..uuidStr.."}",true) or activePetUI:FindFirstChild(uuidStr,true)
            if petFrame then
                local ageLbl=petFrame:FindFirstChild("PET_AGE",true)
                if ageLbl then
                    local txt=""
                    pcall(function() txt=ageLbl.Text end)
                    local age=tonumber((txt or ""):match("(%d+)"))
                    if age then return age end
                end
            end
        end
    end
    for _,attr in ipairs({"Age","Level","PetAge","PetLevel","CurrentAge","CurrentLevel","AGE"}) do
        local v=placedModel:GetAttribute(attr)
        if type(v)=="number" then return v end
    end
    for _,d in ipairs(placedModel:GetDescendants()) do
        if (d:IsA("IntValue") or d:IsA("NumberValue")) then
            if d.Name=="Age" or d.Name=="Level" or d.Name=="PetAge" or d.Name=="PetLevel" then
                return d.Value
            end
        end
    end
    return nil
end

local function findPetInBackpack(uuid)
    -- v12.21: cek Backpack DAN Character (pet equipped pindah ke Character)
    local locations = {player:FindFirstChild("Backpack"), player.Character}
    for _, loc in ipairs(locations) do
        if loc then
            for _,item in pairs(loc:GetChildren()) do
                if isPet(item) then
                    local u=getPetUUID(item)
                    if u and tostring(u)==tostring(uuid) then return item end
                end
            end
        end
    end
    return nil
end

-- ============================================
-- GIFT/TRADE REMOTES (FIXED v8.2 - verified dari debug log temen)
-- Path: GameEvents.PetGiftingService, GameEvents.TradeEvents.{SendRequest,AddItem,RespondRequest}
-- Action: "GivePet" + Player Instance (BUKAN string username!)
-- Trade: 2-step SendRequest -> AddItem (bisa multi-pet)
-- ============================================
local giftRE = nil
local tradeSendReqRE = nil
local tradeAddItemRE = nil
local tradeRespondRE = nil
do
    local ge = RS:FindFirstChild("GameEvents")
    if ge then
        giftRE = ge:FindFirstChild("PetGiftingService")
        local te = ge:FindFirstChild("TradeEvents")
        if te then
            tradeSendReqRE = te:FindFirstChild("SendRequest")
            tradeAddItemRE = te:FindFirstChild("AddItem")
            tradeRespondRE = te:FindFirstChild("RespondRequest")
        end
    end
    if not giftRE then giftRE = RS:FindFirstChild("PetGiftingService", true) end
    if not tradeSendReqRE then tradeSendReqRE = RS:FindFirstChild("SendRequest", true) end
    if not tradeAddItemRE then tradeAddItemRE = RS:FindFirstChild("AddItem", true) end
    if not tradeRespondRE then tradeRespondRE = RS:FindFirstChild("RespondRequest", true) end
end
dbg("[remotes] gift="..(giftRE and "OK" or "FAIL").." tradeSend="..(tradeSendReqRE and "OK" or "FAIL").." tradeAdd="..(tradeAddItemRE and "OK" or "FAIL").." tradeResp="..(tradeRespondRE and "OK" or "FAIL"))

local function findPlayerByName(username)
    if not username or username == "" then return nil end
    username = username:lower()
    for _, p in ipairs(Players:GetPlayers()) do
        if p.Name:lower() == username or p.DisplayName:lower() == username then
            return p
        end
    end
    for _, p in ipairs(Players:GetPlayers()) do
        if p.Name:lower():find(username, 1, true) then return p end
    end
    return nil
end

local function petStillInBackpack(uuid)
    return findPetInBackpack(uuid) ~= nil
end

-- ===== GIFT (FIXED v8.7: hold pet as TOOL, bukan place di garden) =====
-- Workflow: 
--   1. Kalau pet di garden -> unequip dulu (balik ke backpack)
--   2. Humanoid:EquipTool(petTool) -> pet pindah dari Backpack ke Character (di-pegang)
--   3. Fire GivePet("GivePet", PlayerInstance) -> server gift pet yg lagi di-pegang
--   4. Verify pet hilang dari Backpack DAN Character

local function holdPetAsTool(uuid)
    local item = findPetInBackpack(uuid)
    if not item then return nil end
    local char = player.Character
    if not char then return nil end
    local hum = char:FindFirstChildOfClass("Humanoid")
    -- Method 1: Humanoid:EquipTool (proper way)
    if hum then
        local ok = pcall(function() hum:EquipTool(item) end)
        if ok then return item end
    end
    -- Method 2: direct reparent fallback
    if item:IsA("Tool") then
        pcall(function() item.Parent = char end)
        return item
    end
    return nil
end

local function petInCharacter(uuid)
    local char = player.Character if not char then return false end
    for _, it in ipairs(char:GetChildren()) do
        if it:IsA("Tool") then
            local u = it:GetAttribute("PET_UUID")
            if u and tostring(u) == tostring(uuid) then return true end
        end
    end
    return false
end

local function sendGiftToPlayer(targetName, petUUID)
    if not giftRE then
        dbg("[gift] FAIL: PetGiftingService remote gak ketemu")
        return false
    end
    local targetPlayer = findPlayerByName(targetName)
    if not targetPlayer then
        dbg("[gift] FAIL: player gak ada di server")
        return false
    end
    if not petUUID then
        pcall(function() giftRE:FireServer("GivePet", targetPlayer) end)
        return true
    end
    local u = fmtUUID(petUUID)
    local short = tostring(petUUID):sub(1,8)
    local placed = findPlacedPetByUUID(petUUID)
    if placed then
        unequipPet(petUUID)
        task.wait(0.15)
    end
    if not findPetInBackpack(petUUID) then
        dbg("[gift] FAIL: pet "..short.." gak di backpack")
        return false
    end
    -- Try direct pattern dulu (no hold, avoid Steve)
    pcall(function() giftRE:FireServer("GivePet", targetPlayer, u) end)
    task.wait(0.4)
    if not petStillInBackpack(petUUID) then
        dbg("[gift] OK direct: "..short.." -> "..targetPlayer.Name)
        return true
    end
    pcall(function() giftRE:FireServer("GivePet", u, targetPlayer) end)
    task.wait(0.4)
    if not petStillInBackpack(petUUID) then
        dbg("[gift] OK reverse: "..short.." -> "..targetPlayer.Name)
        return true
    end
    -- Fallback: hold-as-tool method
    local item = holdPetAsTool(petUUID)
    if item then
        task.wait(0.15)
        if petInCharacter(petUUID) then
            pcall(function() giftRE:FireServer("GivePet", targetPlayer) end)
            for i = 1, 5 do
                task.wait(0.15)
                if not petStillInBackpack(petUUID) and not petInCharacter(petUUID) then
                    dbg("[gift] OK fallback: "..short.." -> "..targetPlayer.Name)
                    return true
                end
            end
            local hum = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
            if hum then pcall(function() hum:UnequipTools() end) end
        end
    end
    dbg("[gift] FAIL: "..short)
    return false
end

-- ===== TRADE (PERSIS dari log: SendRequest -> AddItem looped) =====
local function sendTradeToPlayer(targetName, petUUIDs)
    if not tradeSendReqRE or not tradeAddItemRE then
        dbg("[trade] FAIL: TradeEvents remote gak ketemu")
        return false
    end
    local targetPlayer = findPlayerByName(targetName)
    if not targetPlayer then
        dbg("[trade] FAIL: player '"..tostring(targetName).."' gak ada di server")
        return false
    end

    local uuidList = {}
    if type(petUUIDs) == "string" then
        table.insert(uuidList, petUUIDs)
    elseif type(petUUIDs) == "table" then
        for _, u in ipairs(petUUIDs) do table.insert(uuidList, u) end
    end

    local ok1, err1 = pcall(function()
        tradeSendReqRE:FireServer(targetPlayer)
    end)
    if not ok1 then
        dbg("[trade] SendRequest error: "..tostring(err1))
        return false
    end
    dbg("[trade] SendRequest -> "..targetPlayer.Name)

    task.wait(0.8)

    local added = 0
    for _, uuid in ipairs(uuidList) do
        local u = fmtUUID(uuid)
        -- Multi-type: try Pet, Ticket, Item
        local fired = false
        for _, t in ipairs({"Pet","Ticket","Item"}) do
            local ok2 = pcall(function() tradeAddItemRE:FireServer(t, u) end)
            if ok2 then fired = true break end
        end
        if fired then
            added = added + 1
            dbg("[trade] AddItem "..u:sub(1,9).."... ("..added.."/"..#uuidList..")")
        end
        task.wait(0.4)
    end

    dbg("[trade] DONE: "..added.."/"..#uuidList.." pet -> "..targetPlayer.Name)
    return added > 0
end

local function unfavoritePet(uuid)
    local u=fmtUUID(uuid)
    local actions={"UnfavoritePet","UnfavouritePet","ToggleFavorite","ToggleFavourite","SetFavorite","SetFavourite","Unfavorite","Unfavourite","Unfav","Unlove","ToggleLove","SetLove","ToggleHeart"}
    for _,act in ipairs(actions) do
        pcall(function() equipRE:FireServer(act,u) end)
        pcall(function() petLeadRE:FireServer(act,u) end)
        pcall(function() equipRE:FireServer(act,u,false) end)
        pcall(function() petLeadRE:FireServer(act,u,false) end)
    end
end

local function passKgFilter(item,filterStr)
    if filterStr==nil or filterStr=="" or filterStr=="0" then return true end
    local n=tonumber(filterStr) if not n then return true end
    local kg=getKG(item) if not kg then return true end
    if n<0 and kg>(-n) then return false end
    if n>0 and kg<n then return false end
    return true
end
local function passAgeFilter(item,filterStr)
    if filterStr==nil or filterStr=="" or filterStr=="0" then return true end
    local n=tonumber(filterStr) if not n then return true end
    local age=getAgeFromKG(item) if not age then return true end
    if n<0 and age>(-n) then return false end
    if n>0 and age<n then return false end
    return true
end

local MUTATION_PREFIXES={
    "Everchanted ","Enchanted ","Shiny ","Rainbow ","Wet ",
    "Chocolate ","Zombified ","Disco ","Gold ","Frozen ",
    "Lunar ","Plasma ","Angelic ","Corrupt ","Crystal ",
    "Verdant ","Blazing ","Icy ","Storm ","Shadow ",
    "Celestial ","Infernal ","Ancient ","Mythic ","Divine ",
    "Venom ","Mimic ","Cosmic ","Galactic ","Stellar ",
    "Toxic ","Radiant ","Mystic ","Phantom ","Spectral ",
    "Eldritch ","Primal ","Ethereal ","Astral ","Chromatic ",
    "Prismatic ","Volcanic ","Glacial ","Tempest ","Solar ",
    -- v12.19: tambahan mutation baru
    "Nightmare ","Dreadbound ","Ghostly ","Diamond ","Bearded ",
    "Glimmering ","Sparkling ","Inverted ","Bloodlust ","Dawn ",
    "Twilight ","Eclipse ","Aurora ","Frostbite ","Inferno ",
    "Emerald ","Ruby ","Sapphire ","Amethyst ","Obsidian ",
    "Crimson ","Azure ","Emerald ","Topaz ","Onyx ",
    "Demonic ","Holy ","Cursed ","Blessed ","Chaotic ",
    "Pristine ","Pure ","Tainted ","Corrupted ","Hallowed ",
    "Hellfire ","Starlight ","Moonlight ","Sunlight ","Voidborn ",
    "Skybound ","Earthbound ","Seabound ","Cloudborn ","Nightborn ",
    "GIANT ","Mega ","Mini ","Tiny ","Huge ",
    "Royal ","Imperial ","Noble ","Common ","Rare ",
    "Epic ","Legendary ","Mythical ","Exotic ","Festive ",
}
function getBaseName(name)
    local result=name
    local changed=true
    while changed do
        changed=false
        for _,prefix in ipairs(MUTATION_PREFIXES) do
            if result:sub(1,#prefix)==prefix then
                result=result:sub(#prefix+1)
                changed=true
                break
            end
        end
    end
    return result
end

local maxKGCache={}
local function buildMaxKGCache()
    maxKGCache={}
    local bp=player:FindFirstChild("Backpack") if not bp then return end
    for _,item in pairs(bp:GetChildren()) do
        if isPet(item) then
            local name=getPetName(item)
            local age=getAge(item) local kg=getKG(item)
            if age and kg and age>0 then
                local maxKG=kg*110/(age+10)
                if not maxKGCache[name] then maxKGCache[name]=maxKG end
                local base=getBaseName(name)
                if not maxKGCache[base] then maxKGCache[base]=maxKG end
            end
        end
    end
end
local function getMaxKGForPet(name)
    if maxKGCache[name] then return maxKGCache[name] end
    local base=getBaseName(name)
    if maxKGCache[base] then return maxKGCache[base] end
    for k,v in pairs(maxKGCache) do
        if name:lower():find(k:lower(),1,true) or k:lower():find(base:lower(),1,true) then return v end
    end
    return nil
end

-- v12.52: IIFE pattern - cache via closure, GAK nambah top-level locals
local getAgeFromUI = (function()
    local cache={}
    local lastScan=0
    local function rebuild()
        cache={}
        local pg=player:FindFirstChild("PlayerGui") if not pg then return end
        for _,sg in ipairs(pg:GetChildren()) do
            local ok=false
            pcall(function() ok=sg:IsA("ScreenGui") or sg:IsA("Frame") or sg:IsA("Folder") end)
            if ok then
                for _,d in ipairs(sg:GetDescendants()) do
                    if d:IsA("TextLabel") then
                        local txt=""
                        pcall(function() txt=d.Text or "" end)
                        local age=nil
                        if d.Name=="PET_AGE" then age=tonumber(txt:match("(%d+)"))
                        else age=tonumber(txt:match("[Aa][Gg][Ee][^%d]*(%d+)")) end
                        if age and age>0 and age<=200 then
                            local p=d.Parent local depth=0
                            while p and depth<12 do
                                local pn=p.Name:gsub("^{",""):gsub("}$","")
                                if #pn>=32 and pn:find("-") then
                                    cache[pn]=age break
                                end
                                p=p.Parent depth=depth+1
                            end
                        end
                    end
                end
            end
        end
        lastScan=tick()
    end
    return function(uuid)
        if not uuid then return nil end
        if tick()-lastScan > 3 then pcall(rebuild) end
        local uuidStr=tostring(uuid):gsub("^{",""):gsub("}$","")
        if #uuidStr<10 then return nil end
        return cache[uuidStr]
    end
end)()

local function getPetTypeFromUI(uuid)
    if not uuid then return nil end
    local pg=player:FindFirstChild("PlayerGui") if not pg then return nil end
    local activePetUI=pg:FindFirstChild("ActivePetUI") if not activePetUI then return nil end
    local uuidStr=tostring(uuid):gsub("^{",""):gsub("}$","")
    for _,d in ipairs(activePetUI:GetDescendants()) do
        if d.Name=="PET_TYPE" and d:IsA("TextLabel") then
            local p=d.Parent
            local depth=0
            while p and depth<10 do
                local pn=p.Name:gsub("^{",""):gsub("}$","")
                if pn==uuidStr then
                    local txt=""
                    pcall(function() txt=d.Text end)
                    if txt and #txt>0 then return txt end
                end
                p=p.Parent
                depth=depth+1
            end
        end
    end
    return nil
end

local function getPetNameFromUI(uuid)
    if not uuid then return nil end
    local pg=player:FindFirstChild("PlayerGui") if not pg then return nil end
    local activePetUI=pg:FindFirstChild("ActivePetUI") if not activePetUI then return nil end
    local uuidStr=tostring(uuid):gsub("^{",""):gsub("}$","")
    for _,d in ipairs(activePetUI:GetDescendants()) do
        if d.Name=="PET_NAME" and d:IsA("TextLabel") then
            local p=d.Parent
            local depth=0
            while p and depth<10 do
                local pn=p.Name:gsub("^{",""):gsub("}$","")
                if pn==uuidStr then
                    local txt=""
                    pcall(function() txt=d.Text end)
                    if txt and #txt>0 then return txt end
                end
                p=p.Parent
                depth=depth+1
            end
        end
    end
    return nil
end

function getAgeFromKG(item)
    if not item then return nil end
    local uuid=getPetUUID(item)
    if uuid then
        local uiAge=getAgeFromUI(uuid)
        if uiAge then return uiAge end
    end
    local age=getAge(item) if age then return age end
    local kg=getKG(item) if not kg then return nil end
    local maxKG=getMaxKGForPet(getPetName(item))
    if maxKG then
        return math.max(1,math.min(100,math.floor(kg*110/maxKG - 10)))
    end
    -- v12.13: smart fallback untuk pet mutasi tanpa cache hit
    -- KG gede (>=20) = pet udah maxed/age tinggi, KG kecil = pet baru
    if kg >= 20 then return 100 end
    return 1
end

local function getAgeByUUID(uuid)
    if not uuid then return nil end
    local ui=getAgeFromUI(uuid)
    if ui then return ui end
    local item=findPetInBackpack(uuid)
    if item then return getAgeFromKG(item) end
    return nil
end

local function getPetInfo(item)
    local name=getPetName(item)
    local age=getAgeFromKG(item)
    local kg=getKG(item)
    local info=name
    if age then info=info.." | Age "..age end
    if kg then info=info.." | "..kg.."kg" end
    return info
end

-- GUI 600x420
local GUI_W=460 local GUI_H=360  -- v12.56: lebih kecil (font tetep)
local sg=Instance.new("ScreenGui")
sg.Name="ZenxLvlGui" sg.DisplayOrder=999 sg.ResetOnSpawn=false
local mainParentResult=safeParent(sg)
dbg("Step 4 OK: ScreenGui parent="..tostring(mainParentResult))
local main=mk("Frame",{
    Size=UDim2.new(0,GUI_W,0,GUI_H),Position=UDim2.new(0.5,-GUI_W/2,0.5,-GUI_H/2),
    BackgroundColor3=C.BG,BorderSizePixel=0,Active=true,Draggable=true,Parent=sg
})
corner(main,10) stroke(main,C.Teal,2)

local TB=mk("Frame",{Size=UDim2.new(1,0,0,34),BackgroundColor3=C.Panel,BorderSizePixel=0,Parent=main})
corner(TB,10)
mk("Frame",{Size=UDim2.new(1,0,0,1.5),Position=UDim2.new(0,0,1,-1.5),BackgroundColor3=C.Teal,BorderSizePixel=0,Parent=TB})
lbl(TB,"ZENX AUTO LEVELING  "..SCRIPT_VERSION,13,C.Teal).Size=UDim2.new(1,-60,1,0)

local minBtn=btn(TB,"-",15,C.Panel,C.Gray)
minBtn.Size=UDim2.new(0,22,0,22) minBtn.Position=UDim2.new(1,-50,0.5,-11) stroke(minBtn,C.Dim,1.2)
local closeBtn=btn(TB,"X",12,C.RDim,C.Red)
closeBtn.Size=UDim2.new(0,22,0,22) closeBtn.Position=UDim2.new(1,-24,0.5,-11) stroke(closeBtn,C.Red,1.2)

-- v10.9: left sidebar + content area
local SIDEBAR_W = 80
local leftSidebar = mk("Frame", {
    Size = UDim2.new(0, SIDEBAR_W, 1, -44),
    Position = UDim2.new(0, 5, 0, 39),
    BackgroundColor3 = C.Panel,
    BorderSizePixel = 0,
    Parent = main
})
corner(leftSidebar, 7)
stroke(leftSidebar, C.Dim, 1.2)
mk("UIPadding", {PaddingTop=UDim.new(0,6), PaddingBottom=UDim.new(0,6), PaddingLeft=UDim.new(0,4), PaddingRight=UDim.new(0,4), Parent=leftSidebar})
mk("UIListLayout", {SortOrder=Enum.SortOrder.LayoutOrder, Padding=UDim.new(0, 4), Parent=leftSidebar})

local sectionBtns = {}
local function makeSidebarBtn(name, idx)
    local b = btn(leftSidebar, name, 11, C.Card, C.Gray)
    b.Size = UDim2.new(1, 0, 0, 44)
    b.LayoutOrder = idx
    b.TextWrapped = true
    stroke(b, C.Dim, 1.1)
    sectionBtns[idx] = b
    return b
end
local upLvlBtn = makeSidebarBtn("UP LVL", 1)
local invShowBtn = makeSidebarBtn("Inventory Show", 2)
local miscBtn = makeSidebarBtn("Misc", 3)
local giftBtn = makeSidebarBtn("Auto Gift", 4)  -- v12.77: pindah dari tab ke sidebar

local content=mk("Frame",{Size=UDim2.new(1,-(SIDEBAR_W+15),1,-34),Position=UDim2.new(0,SIDEBAR_W+10,0,34),BackgroundTransparency=1,Parent=main})
local tabBar=mk("Frame",{Size=UDim2.new(1,-10,0,26),Position=UDim2.new(0,5,0,4),BackgroundTransparency=1,Parent=content})
mk("UIListLayout",{FillDirection=Enum.FillDirection.Horizontal,Padding=UDim.new(0,2),Parent=tabBar})

local tabNames={"Tim Leveling","Pet ke 100","Swap Skill","Other Setting"}  -- v12.77: Auto Gift dipindah ke sidebar
local tabBtns={}

local function makeScroll(yPos,height)
    local s=mk("ScrollingFrame",{
        Size=UDim2.new(1,-10,0,height),Position=UDim2.new(0,5,0,yPos),
        BackgroundTransparency=1,ScrollBarThickness=3,ScrollBarImageColor3=C.Teal,
        CanvasSize=UDim2.new(0,0,0,0),AutomaticCanvasSize=Enum.AutomaticSize.Y,
        Visible=false,Parent=content
    })
    mk("UIListLayout",{SortOrder=Enum.SortOrder.LayoutOrder,Padding=UDim.new(0,3),Parent=s})
    mk("UIPadding",{PaddingTop=UDim.new(0,4),PaddingLeft=UDim.new(0,3),PaddingRight=UDim.new(0,3),Parent=s})
    return s
end

local SCROLL_Y=34
local SCROLL_H=GUI_H-34-68
local areas={} for i=1,5 do areas[i]=makeScroll(SCROLL_Y,SCROLL_H) end

local botBar=mk("Frame",{Size=UDim2.new(1,-10,0,26),Position=UDim2.new(0,5,0,SCROLL_Y+SCROLL_H+4),BackgroundColor3=C.Panel,BorderSizePixel=0,Parent=content})
corner(botBar,7) stroke(botBar,C.Dim,1.2)
local statusLbl=lbl(botBar,"Status: Idle",11,C.Gray,Enum.TextXAlignment.Left)
statusLbl.Size=UDim2.new(1,-10,1,0) statusLbl.Position=UDim2.new(0,8,0,0)

local BOT_Y=SCROLL_Y+SCROLL_H+34
local runBtn=btn(content,"RUNNING",12,C.Panel,C.Gray)
runBtn.Size=UDim2.new(0,150,0,26) runBtn.Position=UDim2.new(0,5,0,BOT_Y)
local runStroke=stroke(runBtn,C.Dim,1.5)
local stopBtn=btn(content,"STOP",12,C.Panel,C.Gray)
stopBtn.Size=UDim2.new(0,90,0,26) stopBtn.Position=UDim2.new(0,160,0,BOT_Y)
local stopStroke=stroke(stopBtn,C.Dim,1.5)

-- v10.1: dones counter sebagai stat card prominent di kanan tombol RUN/STOP
local donesPanel = mk("Frame", {
    Size = UDim2.new(0, 215, 0, 26),
    Position = UDim2.new(0, 255, 0, BOT_Y),
    BackgroundColor3 = C.Panel,
    BorderSizePixel = 0,
    Parent = content
})
corner(donesPanel, 7)
stroke(donesPanel, C.Teal, 1.3)

local donesLbl = lbl(donesPanel, "Total:0 Jadi:0 Kurang:0", 12, C.Teal, Enum.TextXAlignment.Center)
donesLbl.Size = UDim2.new(1, -10, 1, 0)
donesLbl.Position = UDim2.new(0, 5, 0, 0)
donesLbl.Font = Enum.Font.GothamBold



local currentTab = 1
local function switchTab(idx)
    currentTab = idx
    for i,b in ipairs(tabBtns) do
        local s=b:FindFirstChildWhichIsA("UIStroke")
        if i==idx then b.TextColor3=C.Teal b.BackgroundColor3=C.TDim if s then s.Color=C.Teal end areas[i].Visible=true
        else b.TextColor3=C.Gray b.BackgroundColor3=C.Card if s then s.Color=C.Dim end areas[i].Visible=false end
    end
end

-- v10.9: Inventory Show section - listing semua pet di backpack
local invShowGroup = mk("Frame",{Size=UDim2.new(1,0,1,0),BackgroundTransparency=1,Visible=false,Parent=content})

-- v12.22: MISC section - Auto Buy/Feed/Collect (sidebar 3)
local miscGroup = mk("Frame",{Size=UDim2.new(1,0,1,0),BackgroundTransparency=1,Visible=false,Parent=content})

local invHeader = mk("Frame",{Size=UDim2.new(1,-10,0,26),Position=UDim2.new(0,5,0,4),BackgroundColor3=C.Panel,BorderSizePixel=0,Parent=invShowGroup})
corner(invHeader, 7) stroke(invHeader, C.Dim, 1.2)
local invHeaderLbl = lbl(invHeader, "Inventory Pet (loading...)", 11, C.Teal, Enum.TextXAlignment.Left)
invHeaderLbl.Size = UDim2.new(1, -100, 1, 0) invHeaderLbl.Position = UDim2.new(0, 8, 0, 0) invHeaderLbl.Font = Enum.Font.GothamBold

local invRefreshBtn = btn(invHeader, "Refresh", 11, C.TDim, C.Teal)
invRefreshBtn.Size = UDim2.new(0, 80, 0, 20) invRefreshBtn.Position = UDim2.new(1, -86, 0.5, -10)
stroke(invRefreshBtn, C.Teal, 1.2)

-- v11.1: stats bar showing pet count per KG range
local statsBar = mk("Frame", {
    Size = UDim2.new(1, -10, 0, 24),
    Position = UDim2.new(0, 5, 0, 34),
    BackgroundTransparency = 1,
    Parent = invShowGroup
})
mk("UIListLayout", {FillDirection=Enum.FillDirection.Horizontal, Padding=UDim.new(0, 3), HorizontalAlignment=Enum.HorizontalAlignment.Left, Parent=statsBar})

local kgRanges = {{1,2},{2,3},{3,4},{4,5},{5,6},{6,7}}
local kgPills = {}
for i, r in ipairs(kgRanges) do
    local pill = mk("Frame", {Size=UDim2.new(0, 68, 1, 0), BackgroundColor3=C.Card, BorderSizePixel=0, LayoutOrder=i, Parent=statsBar})
    corner(pill, 5) stroke(pill, C.Dim, 1)
    local pl = lbl(pill, r[1].."-"..r[2].."kg: 0", 11, C.Gray, Enum.TextXAlignment.Center)
    pl.Size = UDim2.new(1, 0, 1, 0)
    pl.Font = Enum.Font.GothamBold
    kgPills[i] = pl
end

-- v11.8: invScroll dihapus (gak perlu pet list, cuma total + pills)

local function _doBuildInvShow()
    print("[invShow] start")
    local bp = player:FindFirstChild("Backpack")
    if not bp then
        invHeaderLbl.Text = "Backpack gak ada"
        return
    end
    print("[invShow] bp ok, kids="..#bp:GetChildren())

    -- v11.3: rebuild maxKG cache dulu (untuk pet yg gak punya [Age N] di nama)
    pcall(buildMaxKGCache)

    local petsList = {}
    local minBase, maxBase, sumBase, baseCount = math.huge, 0, 0, 0
    local nilBaseCount = 0
    for _, item in pairs(bp:GetChildren()) do
        if isPet(item) then
            local fullName = getPetName(item)
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
            else
                nilBaseCount = nilBaseCount + 1
            end
            table.insert(petsList, {name=fullName, age=age or 0, kg=kg or 0, baseKG=baseKG, fav=fav})
        end
    end
    table.sort(petsList, function(a,b)
        if a.age ~= b.age then return a.age > b.age end
        return a.kg > b.kg
    end)

    local doneCount = 0
    local rangeCounts = {0,0,0,0,0,0}
    local outOfRangeCount = 0
    for _,p in ipairs(petsList) do
        if p.age >= toAge then doneCount = doneCount + 1 end
        if p.baseKG then
            local matched = false
            for ri, r in ipairs(kgRanges) do
                if p.baseKG >= r[1] and p.baseKG < r[2] then
                    rangeCounts[ri] = rangeCounts[ri] + 1
                    matched = true
                    break
                end
            end
            if not matched then outOfRangeCount = outOfRangeCount + 1 end
        end
    end

    -- v11.7: cuma total pet, gak perlu diagnostic
    invHeaderLbl.Text = "Total: "..#petsList.." pet"

    for i, lblWidget in ipairs(kgPills) do
        local r = kgRanges[i]
        lblWidget.Text = r[1].."-"..r[2].."kg: "..rangeCounts[i]
        lblWidget.TextColor3 = rangeCounts[i] > 0 and C.Teal or C.Gray
    end

    print("[invShow] done, "..#petsList.." pets counted")
end

-- Wrapper dengan pcall biar error visible di header
local function buildInvShow()
    local ok, err = pcall(_doBuildInvShow)
    if not ok then
        local errStr = tostring(err)
        print("[invShow] ERROR: "..errStr)
        invHeaderLbl.Text = "ERR: "..errStr:sub(1,90)
        invHeaderLbl.TextColor3 = C.Red
    end
end

invRefreshBtn.MouseButton1Click:Connect(buildInvShow)

-- Section switching (UP LVL vs Inventory Show)
local currentSection = 1
local function switchSection(idx)
    currentSection = idx
    for i, b in ipairs(sectionBtns) do
        local s = b:FindFirstChildWhichIsA("UIStroke")
        if i == idx then b.TextColor3=C.Teal b.BackgroundColor3=C.TDim if s then s.Color=C.Teal end
        else b.TextColor3=C.Gray b.BackgroundColor3=C.Card if s then s.Color=C.Dim end end
    end
    -- Hide everything first
    tabBar.Visible = false
    for _, a in ipairs(areas) do a.Visible = false end
    botBar.Visible = false
    runBtn.Visible = false
    stopBtn.Visible = false
    donesPanel.Visible = false
    invShowGroup.Visible = false
    miscGroup.Visible = false

    if idx == 1 then
        -- UP LVL
        tabBar.Visible = true
        botBar.Visible = true
        runBtn.Visible = true
        stopBtn.Visible = true
        donesPanel.Visible = true
        switchTab(currentTab)
    elseif idx == 2 then
        -- Inventory Show
        invShowGroup.Visible = true
        invHeaderLbl.TextColor3 = C.Teal
        buildInvShow()
    elseif idx == 3 then
        -- Misc
        miscGroup.Visible = true
    elseif idx == 4 then
        -- v12.77: Auto Gift (was tab 5, now sidebar 4)
        if areas[5] then areas[5].Visible = true end
    end
end

upLvlBtn.MouseButton1Click:Connect(function() switchSection(1) end)
invShowBtn.MouseButton1Click:Connect(function() switchSection(2) end)
miscBtn.MouseButton1Click:Connect(function() switchSection(3) end)
giftBtn.MouseButton1Click:Connect(function() switchSection(4) end)  -- v12.77

for i,name in ipairs(tabNames) do
    local b=btn(tabBar,name,10,C.Card,C.Gray)
    b.Size=UDim2.new(0,88,1,0) b.LayoutOrder=i stroke(b,C.Dim,1.1) tabBtns[i]=b
    local ii=i b.MouseButton1Click:Connect(function() switchTab(ii) end)
end

-- v10.9: default sidebar = UP LVL
switchSection(1)

-- v9.8: Tekan "-" -> kotak kecil ijo neon dengan logo Z (bukan bar memanjang)
local NEON_GREEN = Color3.fromRGB(57, 255, 100)
local NEON_DARK = Color3.fromRGB(0, 120, 40)

-- Mini Z button overlay (cuma visible pas minimized)
local miniZBtn = Instance.new("TextButton")
miniZBtn.Name = "MiniZBtn"
miniZBtn.Size = UDim2.new(1, 0, 1, 0)
miniZBtn.BackgroundTransparency = 1
miniZBtn.Text = "Z"
miniZBtn.TextColor3 = Color3.fromRGB(0, 0, 0)
miniZBtn.Font = Enum.Font.GothamBold
miniZBtn.TextSize = 42
miniZBtn.Visible = false
miniZBtn.AutoButtonColor = false
miniZBtn.ZIndex = 10
miniZBtn.Parent = main

local minimized=false
local savedMainPos = nil  -- v12.24: simpan posisi sebelum minimize
local function setMinimized(state)
    minimized = state
    local mainStroke = main:FindFirstChildOfClass("UIStroke")
    if state then
        -- v12.24: simpan posisi GUI sebelum minimize
        savedMainPos = main.Position
        TB.Visible = false
        content.Visible = false
        leftSidebar.Visible = false
        -- v12.24: lebih kecil (44x44, was 56x56)
        main.Size = UDim2.new(0, 44, 0, 44)
        -- v12.24: fixed position di atas tombol Shop (gak bisa di-drag)
        main.Position = UDim2.new(0, 18, 0.5, -22)
        main.Active = false
        main.Draggable = false
        main.BackgroundColor3 = NEON_GREEN
        if mainStroke then mainStroke.Color = NEON_DARK end
        miniZBtn.TextSize = 30  -- v12.24: dari 42 -> 30 (cocok ukuran 44x44)
        miniZBtn.Visible = true
    else
        TB.Visible = true
        content.Visible = true
        leftSidebar.Visible = true
        main.Size = UDim2.new(0, GUI_W, 0, GUI_H)
        -- v12.24: restore posisi dan draggable
        if savedMainPos then main.Position = savedMainPos end
        main.Active = true
        main.Draggable = true
        main.BackgroundColor3 = C.BG
        if mainStroke then mainStroke.Color = C.Teal end
        miniZBtn.Visible = false
    end
    minBtn.Text = state and "+" or "-"
end

minBtn.MouseButton1Click:Connect(function() setMinimized(not minimized) end)
miniZBtn.MouseButton1Click:Connect(function() setMinimized(false) end)

local teamPetUUIDs=d.teamPetUUIDs or {}
local teamPetInfoCache=d.teamPetInfoCache or {}

local config=d.config or {equipInterval=5,rejoinMinutes=30}
local targetPetTypes=d.targetPetTypes or {}
local fromAge=d.fromAge or 1
local maxPetTarget=d.maxPetTarget or 1
local autoStartEnabled=d.autoStartEnabled or false
local autoRejoin=d.autoRejoin or false
local autoAccGift=d.autoAccGift or false
local autoAccTrade=d.autoAccTrade or false
local autoSendGift=d.autoSendGift or false
local autoSendTrade=d.autoSendTrade or false
local sendInterval=d.sendInterval or 30
local giftSlots=d.giftSlots or {
    {target="",petTypes={},mutationFilter="",kg="",age="",includeFav=false,autoSendGift=false,autoSendTrade=false,autoUnfav=false},
    {target="",petTypes={},mutationFilter="",kg="",age="",includeFav=false,autoSendGift=false,autoSendTrade=false,autoUnfav=false},
    {target="",petTypes={},mutationFilter="",kg="",age="",includeFav=false,autoSendGift=false,autoSendTrade=false,autoUnfav=false},
}
for i=1,3 do
    if not giftSlots[i] then giftSlots[i]={target="",petTypes={},mutationFilter="",kg="",age="",includeFav=false,autoSendGift=false,autoSendTrade=false,autoUnfav=false} end
    giftSlots[i].petTypes=giftSlots[i].petTypes or {}
    giftSlots[i].target=giftSlots[i].target or ""
    giftSlots[i].kg=giftSlots[i].kg or ""
    giftSlots[i].age=giftSlots[i].age or ""
    giftSlots[i].mutationFilter=giftSlots[i].mutationFilter or ""
end
local antiAfk=(d.antiAfk~=false)
local showAllPets=d.showAllPets or false
local isRunning=false
local mainTask=nil local monitorTask=nil
local isAR=false local arTask=nil
local arTog2,arTogStroke2,arStroke2,cdLbl2
local currentLevelingUUIDs={}
local completedPets={}

local swapPerPet=d.swapPerPet or {}
local swapPetInfoCache=d.swapPetInfoCache or {}
local showAllPetsSwap=d.showAllPetsSwap or false
local pollerTask=nil
local lastSwap={}

local buildSwapList
local buildTimList

local function save()
    d.config=config d.targetPetTypes=targetPetTypes
    d.fromAge=fromAge d.toAge=toAge d.maxPetTarget=maxPetTarget
    d.autoStartEnabled=autoStartEnabled d.autoRejoin=autoRejoin
    d.autoAccGift=autoAccGift d.autoAccTrade=autoAccTrade
    d.sendInterval=sendInterval
    d.giftSlots=giftSlots
    d.antiAfk=antiAfk d.showAllPets=showAllPets d.showAllPetsSwap=showAllPetsSwap
    d.swapPerPet=swapPerPet d.swapPetInfoCache=swapPetInfoCache
    d.teamPetUUIDs=teamPetUUIDs d.teamPetInfoCache=teamPetInfoCache
    saveToFile(d)
end

local function teamCount() local n=0 for _ in pairs(teamPetUUIDs) do n=n+1 end return n end
local function selCount() local n=0 for _ in pairs(targetPetTypes) do n=n+1 end return n end
local function isTargetPet(name)
    if selCount()==0 then return true end
    if targetPetTypes[name] then return true end
    -- v12.19: cek getBaseName (strip mutation prefix)
    local baseName = getBaseName(name)
    if targetPetTypes[baseName] then return true end
    -- v12.19: substring fallback - kalo nama target ada di pet name
    -- (handle mutation prefix yg blm ke-list)
    local nameLower = name:lower()
    for targetName, _ in pairs(targetPetTypes) do
        local targetLower = targetName:lower()
        -- exact word match (biar gak too lenient - cuma match kalo target name muncul as substring)
        if nameLower:find(targetLower, 1, true) then return true end
    end
    return false
end

-- v12.20: count task.spawn moved AFTER isTargetPet (fix scope issue)
task.spawn(function()
    while donesLbl and donesLbl.Parent and not scriptShutdown do
        -- v12.18: 3 stats - cek BACKPACK + GARDEN (pet equipped)
        -- Tanpa filter team (pet team yg lagi level harus tetep ke-count)
        -- Pakai dedupe by UUID biar gak double-count
        local total = 0
        local done = 0
        local remaining = 0
        local seenUUIDs = {}

        -- Backpack pets
        local bp = player:FindFirstChild("Backpack")
        if bp then
            for _, item in pairs(bp:GetChildren()) do
                if isPet(item) then
                    local name = getPetName(item)
                    local uuid = getPetUUID(item)
                    local uuidStr = uuid and tostring(uuid) or nil
                    if isTargetPet(name) and not isFavorite(item) then
                        if not (uuidStr and seenUUIDs[uuidStr]) then
                            if uuidStr then seenUUIDs[uuidStr] = true end
                            total = total + 1
                            local age = getAgeFromKG(item)
                            if age and age >= toAge then
                                done = done + 1
                            else
                                remaining = remaining + 1
                            end
                        end
                    end
                end
            end
        end

        -- Garden/equipped pets (ActivePetUI - source of truth untuk pet equipped)
        local pg = player:FindFirstChild("PlayerGui")
        local activePetUI = pg and pg:FindFirstChild("ActivePetUI")
        if activePetUI then
            for _, d in ipairs(activePetUI:GetDescendants()) do
                if d:IsA("Frame") or d:IsA("ImageLabel") then
                    local n = d.Name:gsub("^{",""):gsub("}$","")
                    if #n >= 20 and n:find("-") then  -- looks like UUID
                        if not seenUUIDs[n] then
                            -- check if has PET_AGE child (it's a pet frame)
                            local ageLbl = d:FindFirstChild("PET_AGE", true)
                            if ageLbl then
                                seenUUIDs[n] = true
                                -- Get name from UI
                                local petTypeLbl = d:FindFirstChild("PET_NAME", true) or d:FindFirstChild("PET_TYPE", true)
                                local petName = petTypeLbl and petTypeLbl.Text or ""
                                if petName == "" or isTargetPet(petName) then
                                    total = total + 1
                                    local txt = ""
                                    pcall(function() txt = ageLbl.Text end)
                                    local age = tonumber((txt or ""):match("(%d+)"))
                                    if age and age >= toAge then
                                        done = done + 1
                                    else
                                        remaining = remaining + 1
                                    end
                                end
                            end
                        end
                    end
                end
            end
        end

        if donesLbl and donesLbl.Parent then
            donesLbl.Text = "Total:"..total.." Jadi:"..done.." Kurang:"..remaining
            if total == 0 then
                donesLbl.TextColor3 = C.Gray
            elseif remaining == 0 then
                donesLbl.TextColor3 = C.Green
            else
                donesLbl.TextColor3 = C.Teal
            end
        end
        task.wait(2)
    end
end)
local function getTeamPetInfo(uuid)
    if teamPetInfoCache[uuid] then return teamPetInfoCache[uuid] end
    local item=findPetInBackpack(uuid)
    if item then
        local rec={name=getPetName(item),info=getPetInfo(item)}
        teamPetInfoCache[uuid]=rec
        return rec
    end
    return {name="Unknown",info="Unknown pet"}
end

-- forward declarations needed by tab builders
local startTeamKeeper
local stopTeamKeeper
local teamKeeperShouldRun
local startGlobalPoller

-- ============================================
-- TAB 1: TIM LEVELING
-- ============================================
buildTimList=function()
    for _,c in pairs(areas[1]:GetChildren()) do
        if c:IsA("Frame") or c:IsA("TextButton") or c:IsA("TextLabel") then c:Destroy() end
    end
    buildMaxKGCache()

    local cfgCard=mk("Frame",{Size=UDim2.new(1,0,0,52),BackgroundColor3=C.Panel,BorderSizePixel=0,LayoutOrder=0,Parent=areas[1]})
    corner(cfgCard,7) stroke(cfgCard,C.Teal,1.2)
    mk("UIListLayout",{SortOrder=Enum.SortOrder.LayoutOrder,Padding=UDim.new(0,3),Parent=cfgCard})
    mk("UIPadding",{PaddingTop=UDim.new(0,5),PaddingLeft=UDim.new(0,5),PaddingRight=UDim.new(0,5),PaddingBottom=UDim.new(0,5),Parent=cfgCard})
    lbl(cfgCard,"Setting Leveling",11,C.Teal).Size=UDim2.new(1,0,0,13)
    local eqRow=mk("Frame",{Size=UDim2.new(1,0,0,26),BackgroundColor3=C.Card,BorderSizePixel=0,Parent=cfgCard})
    corner(eqRow,5) stroke(eqRow,C.Dim,1)
    lbl(eqRow,"Equip Interval (dtk)",11,C.Gray).Size=UDim2.new(0.6,0,1,0)
    local eqBox=mk("TextBox",{Size=UDim2.new(0,50,0,20),Position=UDim2.new(1,-56,0.5,-10),BackgroundColor3=C.Panel,Text=tostring(config.equipInterval),TextColor3=C.White,Font=Enum.Font.GothamBold,TextSize=14,TextScaled=false,TextXAlignment=Enum.TextXAlignment.Center,ClearTextOnFocus=false,Parent=eqRow})
    corner(eqBox,5) stroke(eqBox,C.Dim,1)
    eqBox:GetPropertyChangedSignal("Text"):Connect(function()
        local v=tonumber(eqBox.Text) if v then config.equipInterval=math.max(1,v) save() end
    end)

    local saRow=mk("Frame",{Size=UDim2.new(1,0,0,28),BackgroundColor3=C.Card,BorderSizePixel=0,LayoutOrder=1,Parent=areas[1]})
    corner(saRow,6) stroke(saRow,C.Dim,1.1)
    lbl(saRow,"Tampilkan semua pet",11,C.Gray).Size=UDim2.new(0.55,0,0,14)
    local saTxt=lbl(saRow,"(bypass filter love)",9,C.Dim) saTxt.Size=UDim2.new(0.55,0,0,11) saTxt.Position=UDim2.new(0,8,0,16)
    local saTog=btn(saRow,showAllPets and "ON" or "OFF",9,showAllPets and C.TDim or C.Panel,showAllPets and C.Teal or C.Gray)
    saTog.Size=UDim2.new(0,44,0,20) saTog.Position=UDim2.new(1,-50,0.5,-10)
    local saTogStroke=stroke(saTog,showAllPets and C.Teal or C.Dim,1.1)
    saTog.MouseButton1Click:Connect(function()
        showAllPets=not showAllPets save()
        saTog.Text=showAllPets and "ON" or "OFF"
        saTog.BackgroundColor3=showAllPets and C.TDim or C.Panel
        saTog.TextColor3=showAllPets and C.Teal or C.Gray
        saTogStroke.Color=showAllPets and C.Teal or C.Dim
        buildTimList()
    end)

    div(areas[1],1)

    local pickerOpen=false
    local pickRow=mk("Frame",{Size=UDim2.new(1,0,0,30),BackgroundColor3=C.Card,BorderSizePixel=0,LayoutOrder=2,Parent=areas[1]})
    corner(pickRow,6) local pickStroke=stroke(pickRow,C.Dim,1.1)
    local pickLbl=lbl(pickRow,"Pilih Pet Tim  ("..teamCount().." dipilih)",11,C.White)
    pickLbl.Size=UDim2.new(0.8,0,1,0) pickLbl.Position=UDim2.new(0,10,0,0)
    local pickArrow=lbl(pickRow,"v",11,C.Teal,Enum.TextXAlignment.Right)
    pickArrow.Size=UDim2.new(0,20,1,0) pickArrow.Position=UDim2.new(1,-24,0,0)
    local pickBtnCover=mk("TextButton",{Size=UDim2.new(1,0,1,0),BackgroundTransparency=1,Text="",AutoButtonColor=false,Parent=pickRow})

    local picker=mk("Frame",{Size=UDim2.new(1,0,0,0),BackgroundColor3=C.Panel,BorderSizePixel=0,Visible=false,LayoutOrder=3,Parent=areas[1]})
    corner(picker,7) stroke(picker,C.Teal,1.3)
    mk("UIPadding",{PaddingTop=UDim.new(0,4),PaddingLeft=UDim.new(0,4),PaddingRight=UDim.new(0,4),PaddingBottom=UDim.new(0,4),Parent=picker})
    mk("UIListLayout",{SortOrder=Enum.SortOrder.LayoutOrder,Padding=UDim.new(0,3),Parent=picker})

    local pickSearch=mk("TextBox",{Size=UDim2.new(1,0,0,22),BackgroundColor3=C.Card,Text="",PlaceholderText="Cari pet...",PlaceholderColor3=C.Dim,TextColor3=C.White,Font=Enum.Font.Gotham,TextSize=13,TextScaled=false,ClearTextOnFocus=false,LayoutOrder=0,Parent=picker})
    corner(pickSearch,5) stroke(pickSearch,C.Dim,1) mk("UIPadding",{PaddingLeft=UDim.new(0,6),Parent=pickSearch})

    local petPickScroll=mk("ScrollingFrame",{Size=UDim2.new(1,0,0,150),BackgroundTransparency=1,ScrollBarThickness=3,ScrollBarImageColor3=C.Teal,CanvasSize=UDim2.new(0,0,0,0),AutomaticCanvasSize=Enum.AutomaticSize.Y,LayoutOrder=1,Parent=picker})
    mk("UIListLayout",{SortOrder=Enum.SortOrder.LayoutOrder,Padding=UDim.new(0,2),Parent=petPickScroll})

    local updatePreview
    local buildPickerContent

    local function syncSwapTab()
        if buildSwapList then pcall(buildSwapList) end
    end

    updatePreview=function()
        for _,c in pairs(areas[1]:GetChildren()) do
            if (c:IsA("Frame") or c:IsA("TextLabel")) and c.LayoutOrder>=4 then c:Destroy() end
        end
        div(areas[1],4)
        local timHdr=mk("Frame",{Size=UDim2.new(1,0,0,22),BackgroundColor3=C.Panel,BorderSizePixel=0,LayoutOrder=5,Parent=areas[1]})
        corner(timHdr,5)
        lbl(timHdr,"Tim Leveling ("..teamCount().." pet):",11,C.Teal).Size=UDim2.new(1,-10,1,0)
        local i=0
        if teamCount()==0 then
            local e=lbl(areas[1],"Belum ada pet dipilih",10,C.Gray,Enum.TextXAlignment.Center)
            e.Size=UDim2.new(1,0,0,20) e.LayoutOrder=6
        else
            for uuid,_ in pairs(teamPetUUIDs) do
                i=i+1
                local info=teamPetInfoCache[uuid] and teamPetInfoCache[uuid].info or uuid
                -- v12.25: preview row di-bump
                local pr=mk("Frame",{Size=UDim2.new(1,0,0,32),BackgroundColor3=C.TDim,BorderSizePixel=0,LayoutOrder=5+i,Parent=areas[1]})
                corner(pr,5) stroke(pr,C.Teal,1.1)
                local nl=lbl(pr,tostring(i)..".",13,C.Teal,Enum.TextXAlignment.Center) nl.Size=UDim2.new(0,24,1,0) nl.Position=UDim2.new(0,2,0,0)
                local il=lbl(pr,info,12,C.White) il.Size=UDim2.new(1,-40,1,0) il.Position=UDim2.new(0,28,0,0)
                local db=btn(pr,"X",12,C.RDim,C.Red) db.Size=UDim2.new(0,22,0,22) db.Position=UDim2.new(1,-26,0.5,-11) stroke(db,C.Red,1)
                local cu=uuid
                db.MouseButton1Click:Connect(function()
                    teamPetUUIDs[cu]=nil pickLbl.Text="Pilih Pet Tim  ("..teamCount().." dipilih)"
                    buildPickerContent(pickSearch.Text) updatePreview()
                    syncSwapTab()
                    save()
                    if teamKeeperShouldRun and not teamKeeperShouldRun() then if stopTeamKeeper then stopTeamKeeper() end end
                end)
            end
        end
        div(areas[1],100)
        local rf=btn(areas[1],"Refresh",12,C.Panel,C.White)
        rf.Size=UDim2.new(1,0,0,24) rf.LayoutOrder=101 stroke(rf,C.Dim,1.2)
        rf.MouseButton1Click:Connect(function()
            buildMaxKGCache()
            buildPickerContent(pickSearch.Text)
            updatePreview()
            syncSwapTab()
        end)
    end

    buildPickerContent=function(filter)
        filter=filter or ""
        for _,c in pairs(petPickScroll:GetChildren()) do if c:IsA("Frame") then c:Destroy() end end
        local bp=player:FindFirstChild("Backpack")
        local n=0 local shown={} local favCount=0
        if bp then
            for _,item in pairs(bp:GetChildren()) do
                if isPet(item) and (showAllPets or isFavorite(item)) then
                    favCount=favCount+1
                    local uuid=getPetUUID(item)
                    if uuid then
                        local uuidStr=tostring(uuid)
                        local name=getPetName(item)
                        local show=filter=="" or name:lower():find(filter:lower(),1,true)
                        if show then
                            shown[uuidStr]=true n=n+1
                            local info=getPetInfo(item)
                            teamPetInfoCache[uuidStr]={name=name,info=info}
                            local inTeam=teamPetUUIDs[uuidStr]==true
                            -- v12.25: row 26->34, font 8->12 (lebih jelas)
                            local row=mk("Frame",{Size=UDim2.new(1,0,0,34),BackgroundColor3=inTeam and C.TDim or C.Card,BorderSizePixel=0,LayoutOrder=n,Parent=petPickScroll})
                            corner(row,5) if inTeam then stroke(row,C.Teal,1.1) end
                            local nameLbl=lbl(row,info,12,inTeam and C.Teal or C.White)
                            nameLbl.Size=UDim2.new(0.72,0,1,0) nameLbl.Position=UDim2.new(0,8,0,0)
                            local togBtn=btn(row,inTeam and "ON" or "OFF",12,inTeam and C.TDim or C.Panel,inTeam and C.Teal or C.Gray)
                            togBtn.Size=UDim2.new(0,52,0,24) togBtn.Position=UDim2.new(1,-56,0.5,-12)
                            local togStroke=stroke(togBtn,inTeam and C.Teal or C.Dim,1.1)
                            local cu=uuidStr
                            togBtn.MouseButton1Click:Connect(function()
                                if teamPetUUIDs[cu] then teamPetUUIDs[cu]=nil else teamPetUUIDs[cu]=true end
                                local nowIn=teamPetUUIDs[cu]==true
                                row.BackgroundColor3=nowIn and C.TDim or C.Card
                                local rs=row:FindFirstChildWhichIsA("UIStroke")
                                if nowIn then if rs then rs.Color=C.Teal else stroke(row,C.Teal,1.1) end
                                else if rs then rs:Destroy() end end
                                nameLbl.TextColor3=nowIn and C.Teal or C.White
                                togBtn.Text=nowIn and "ON" or "OFF"
                                togBtn.BackgroundColor3=nowIn and C.TDim or C.Panel
                                togBtn.TextColor3=nowIn and C.Teal or C.Gray
                                togStroke.Color=nowIn and C.Teal or C.Dim
                                pickLbl.Text="Pilih Pet Tim  ("..teamCount().." dipilih)"
                                updatePreview()
                                syncSwapTab()
                                save()
                                if nowIn then if startTeamKeeper then startTeamKeeper() end else
                                    if teamKeeperShouldRun and not teamKeeperShouldRun() then if stopTeamKeeper then stopTeamKeeper() end end
                                end
                            end)
                        end
                    end
                end
            end
        end
        for uuid,_ in pairs(teamPetUUIDs) do
            if not shown[uuid] and teamPetInfoCache[uuid] then
                local name=teamPetInfoCache[uuid].name
                local show=filter=="" or name:lower():find(filter:lower(),1,true)
                if show then
                    n=n+1
                    local info=teamPetInfoCache[uuid].info.." (di garden)"
                    -- v12.25: garden row juga di-bump
                    local row=mk("Frame",{Size=UDim2.new(1,0,0,34),BackgroundColor3=C.TDim,BorderSizePixel=0,LayoutOrder=n,Parent=petPickScroll})
                    corner(row,5) stroke(row,C.Teal,1.1)
                    local nl=lbl(row,info,12,C.Teal) nl.Size=UDim2.new(0.72,0,1,0) nl.Position=UDim2.new(0,8,0,0)
                    local tb=btn(row,"ON",12,C.TDim,C.Teal) tb.Size=UDim2.new(0,52,0,24) tb.Position=UDim2.new(1,-56,0.5,-12) stroke(tb,C.Teal,1.1)
                    local cu=uuid
                    tb.MouseButton1Click:Connect(function()
                        teamPetUUIDs[cu]=nil pickLbl.Text="Pilih Pet Tim  ("..teamCount().." dipilih)"
                        buildPickerContent(pickSearch.Text) updatePreview()
                        syncSwapTab()
                        save()
                        if teamKeeperShouldRun and not teamKeeperShouldRun() then if stopTeamKeeper then stopTeamKeeper() end end
                    end)
                end
            end
        end
        if n==0 then
            local msg=favCount==0 and "Belum ada pet di-love. Tekan icon love di pet game dulu." or "Tidak ada pet love yg cocok"
            local e=lbl(petPickScroll,msg,10,C.Red,Enum.TextXAlignment.Center)
            e.Size=UDim2.new(1,0,0,30) e.LayoutOrder=1
            e.TextWrapped=true
        end
    end

    buildPickerContent("") updatePreview()
    pickSearch:GetPropertyChangedSignal("Text"):Connect(function() buildPickerContent(pickSearch.Text) end)
    pickBtnCover.MouseButton1Click:Connect(function()
        pickerOpen=not pickerOpen
        picker.Visible=pickerOpen
        picker.Size=pickerOpen and UDim2.new(1,0,0,185) or UDim2.new(1,0,0,0)
        pickArrow.Text=pickerOpen and "^" or "v"
        pickStroke.Color=pickerOpen and C.Teal or C.Dim
    end)
end

-- ============================================
-- TAB 2: PET KE 100
-- ============================================
local function buildTargetList()
    for _,c in pairs(areas[2]:GetChildren()) do
        if c:IsA("Frame") or c:IsA("TextButton") or c:IsA("TextLabel") then c:Destroy() end
    end
    buildMaxKGCache()
    local bp=player:FindFirstChild("Backpack")
    local petNames={} local nameSet={}
    if bp then
        for _,item in pairs(bp:GetChildren()) do
            if isPet(item) then
                local name=getPetName(item)
                if not nameSet[name] then nameSet[name]=true table.insert(petNames,name) end
            end
        end
        table.sort(petNames,function(a,b) return a<b end)
    end

    local typePickerOpen=false
    local typeRow=mk("Frame",{Size=UDim2.new(1,0,0,30),BackgroundColor3=C.Card,BorderSizePixel=0,LayoutOrder=0,Parent=areas[2]})
    corner(typeRow,6) local typeStroke=stroke(typeRow,C.Dim,1.1)
    local typeLbl=lbl(typeRow,"Jenis Pet  ("..selCount().." dipilih, 0=semua)",11,C.White)
    typeLbl.Size=UDim2.new(0.8,0,1,0) typeLbl.Position=UDim2.new(0,10,0,0)
    local typeArrow=lbl(typeRow,"v",11,C.Teal,Enum.TextXAlignment.Right)
    typeArrow.Size=UDim2.new(0,20,1,0) typeArrow.Position=UDim2.new(1,-24,0,0)
    local typeBtnCover=mk("TextButton",{Size=UDim2.new(1,0,1,0),BackgroundTransparency=1,Text="",AutoButtonColor=false,Parent=typeRow})
    local typePicker=mk("Frame",{Size=UDim2.new(1,0,0,0),BackgroundColor3=C.Panel,BorderSizePixel=0,Visible=false,LayoutOrder=1,Parent=areas[2]})
    corner(typePicker,7) stroke(typePicker,C.Teal,1.3)
    mk("UIPadding",{PaddingTop=UDim.new(0,4),PaddingLeft=UDim.new(0,4),PaddingRight=UDim.new(0,4),PaddingBottom=UDim.new(0,4),Parent=typePicker})
    mk("UIListLayout",{SortOrder=Enum.SortOrder.LayoutOrder,Padding=UDim.new(0,3),Parent=typePicker})
    local typeSearch=mk("TextBox",{Size=UDim2.new(1,0,0,22),BackgroundColor3=C.Card,Text="",PlaceholderText="Cari jenis pet...",PlaceholderColor3=C.Dim,TextColor3=C.White,Font=Enum.Font.Gotham,TextSize=13,TextScaled=false,ClearTextOnFocus=false,LayoutOrder=0,Parent=typePicker})
    corner(typeSearch,5) stroke(typeSearch,C.Dim,1) mk("UIPadding",{PaddingLeft=UDim.new(0,6),Parent=typeSearch})
    local typeScroll=mk("ScrollingFrame",{Size=UDim2.new(1,0,0,120),BackgroundTransparency=1,ScrollBarThickness=3,ScrollBarImageColor3=C.Teal,CanvasSize=UDim2.new(0,0,0,0),AutomaticCanvasSize=Enum.AutomaticSize.Y,LayoutOrder=1,Parent=typePicker})
    mk("UIListLayout",{SortOrder=Enum.SortOrder.LayoutOrder,Padding=UDim.new(0,2),Parent=typeScroll})

    local function buildTypePicker(filter)
        filter=filter or ""
        for _,c in pairs(typeScroll:GetChildren()) do if c:IsA("Frame") then c:Destroy() end end
        local n=0
        n=n+1
        local allSel=selCount()==0
        local allRow=mk("Frame",{Size=UDim2.new(1,0,0,24),BackgroundColor3=allSel and C.TDim or C.Card,BorderSizePixel=0,LayoutOrder=n,Parent=typeScroll})
        corner(allRow,5) if allSel then stroke(allRow,C.Teal,1.1) end
        lbl(allRow,"(Semua Pet)",8,allSel and C.Teal or C.White).Size=UDim2.new(0.72,0,1,0)
        local allBtn=btn(allRow,allSel and "ON" or "OFF",8,allSel and C.TDim or C.Panel,allSel and C.Teal or C.Gray)
        allBtn.Size=UDim2.new(0,44,0,18) allBtn.Position=UDim2.new(1,-48,0.5,-9) stroke(allBtn,allSel and C.Teal or C.Dim,1.1)
        allBtn.MouseButton1Click:Connect(function()
            targetPetTypes={} save() typeLbl.Text="Jenis Pet  (0 dipilih, 0=semua)"
            buildTypePicker(typeSearch.Text) buildTargetList()
        end)
        for _,pname in ipairs(petNames) do
            local show=filter=="" or pname:lower():find(filter:lower(),1,true)
            if show then
                n=n+1
                local isSel=targetPetTypes[pname]==true
                local row=mk("Frame",{Size=UDim2.new(1,0,0,24),BackgroundColor3=isSel and C.TDim or C.Card,BorderSizePixel=0,LayoutOrder=n,Parent=typeScroll})
                corner(row,5) if isSel then stroke(row,C.Teal,1.1) end
                local nameLbl=lbl(row,pname,8,isSel and C.Teal or C.White)
                nameLbl.Size=UDim2.new(0.72,0,1,0) nameLbl.Position=UDim2.new(0,8,0,0)
                local togBtn=btn(row,isSel and "ON" or "OFF",8,isSel and C.TDim or C.Panel,isSel and C.Teal or C.Gray)
                togBtn.Size=UDim2.new(0,44,0,18) togBtn.Position=UDim2.new(1,-48,0.5,-9)
                local togStroke=stroke(togBtn,isSel and C.Teal or C.Dim,1.1)
                local cp=pname
                togBtn.MouseButton1Click:Connect(function()
                    if targetPetTypes[cp] then targetPetTypes[cp]=nil else targetPetTypes[cp]=true end
                    local nowSel=targetPetTypes[cp]==true
                    row.BackgroundColor3=nowSel and C.TDim or C.Card
                    local rs=row:FindFirstChildWhichIsA("UIStroke")
                    if nowSel then if rs then rs.Color=C.Teal else stroke(row,C.Teal,1.1) end
                    else if rs then rs:Destroy() end end
                    nameLbl.TextColor3=nowSel and C.Teal or C.White
                    togBtn.Text=nowSel and "ON" or "OFF"
                    togBtn.BackgroundColor3=nowSel and C.TDim or C.Panel
                    togBtn.TextColor3=nowSel and C.Teal or C.Gray
                    togStroke.Color=nowSel and C.Teal or C.Dim
                    typeLbl.Text="Jenis Pet  ("..selCount().." dipilih, 0=semua)"
                    save() buildTargetList()
                end)
            end
        end
    end
    buildTypePicker("")
    typeSearch:GetPropertyChangedSignal("Text"):Connect(function() buildTypePicker(typeSearch.Text) end)
    typeBtnCover.MouseButton1Click:Connect(function()
        typePickerOpen=not typePickerOpen
        typePicker.Visible=typePickerOpen
        typePicker.Size=typePickerOpen and UDim2.new(1,0,0,160) or UDim2.new(1,0,0,0)
        typeArrow.Text=typePickerOpen and "^" or "v"
        typeStroke.Color=typePickerOpen and C.Teal or C.Dim
    end)

    div(areas[2],2)
    local function numRow(labelTxt,lo,default,onChange)
        local r=mk("Frame",{Size=UDim2.new(1,0,0,26),BackgroundColor3=C.Card,BorderSizePixel=0,LayoutOrder=lo,Parent=areas[2]})
        corner(r,6) stroke(r,C.Dim,1.1)
        lbl(r,labelTxt,11,C.Gray).Size=UDim2.new(0.6,0,1,0)
        local box=mk("TextBox",{Size=UDim2.new(0,50,0,20),Position=UDim2.new(1,-56,0.5,-10),BackgroundColor3=C.Panel,Text=tostring(default),TextColor3=C.White,Font=Enum.Font.GothamBold,TextSize=14,TextScaled=false,TextXAlignment=Enum.TextXAlignment.Center,ClearTextOnFocus=false,Parent=r})
        corner(box,5) stroke(box,C.Dim,1)
        box:GetPropertyChangedSignal("Text"):Connect(function() local v=tonumber(box.Text) if v then onChange(v) save() end end)
    end
    numRow("Dari Age:",3,fromAge,function(v) fromAge=math.max(1,math.min(99,v)) d.fromAge=fromAge end)
    numRow("Sampai Age:",4,toAge,function(v) toAge=math.max(1,math.min(100,v)) d.toAge=toAge end)

    local pcRow=mk("Frame",{Size=UDim2.new(1,0,0,26),BackgroundColor3=C.Card,BorderSizePixel=0,LayoutOrder=5,Parent=areas[2]})
    corner(pcRow,6) stroke(pcRow,C.Dim,1.1)
    lbl(pcRow,"Jumlah Pet (sekaligus):",11,C.Gray).Size=UDim2.new(0.55,0,1,0)
    local pcMin=btn(pcRow,"-",14,C.Panel,C.Gray) pcMin.Size=UDim2.new(0,22,0,20) pcMin.Position=UDim2.new(1,-72,0.5,-10) stroke(pcMin,C.Dim,1.1)
    local pcNum=lbl(pcRow,tostring(maxPetTarget),12,C.White,Enum.TextXAlignment.Center) pcNum.Size=UDim2.new(0,26,1,0) pcNum.Position=UDim2.new(1,-48,0,0) pcNum.Font=Enum.Font.GothamBold
    local pcPlus=btn(pcRow,"+",14,C.Panel,C.Gray) pcPlus.Size=UDim2.new(0,22,0,20) pcPlus.Position=UDim2.new(1,-22,0.5,-10) stroke(pcPlus,C.Dim,1.1)
    pcMin.MouseButton1Click:Connect(function() if maxPetTarget>1 then maxPetTarget=maxPetTarget-1 d.maxPetTarget=maxPetTarget pcNum.Text=tostring(maxPetTarget) save() end end)
    pcPlus.MouseButton1Click:Connect(function() if maxPetTarget<10 then maxPetTarget=maxPetTarget+1 d.maxPetTarget=maxPetTarget pcNum.Text=tostring(maxPetTarget) save() end end)

    div(areas[2],6)
    local qHdr=mk("Frame",{Size=UDim2.new(1,0,0,22),BackgroundColor3=C.Panel,BorderSizePixel=0,LayoutOrder=7,Parent=areas[2]})
    corner(qHdr,5) lbl(qHdr,"Pet target belum jadi (jenis):",11,C.Teal).Size=UDim2.new(1,-10,1,0)

    local agg={}
    local total=0
    if bp then
        for _,item in pairs(bp:GetChildren()) do
            if isPet(item) then
                local uuid=getPetUUID(item)
                local uuidStr=uuid and tostring(uuid) or ""
                if uuid and not teamPetUUIDs[uuidStr] then
                    local name=getPetName(item)
                    local age=getAgeFromKG(item)
                    if isTargetPet(name) then
                        if age==nil or (age>=fromAge and age<toAge) then
                            local base=getBaseName(name)
                            if not agg[base] then agg[base]={count=0,mutCount=0} end
                            agg[base].count=agg[base].count+1
                            if name~=base then agg[base].mutCount=agg[base].mutCount+1 end
                            total=total+1
                        end
                    end
                end
            end
        end
    end
    local sortedBases={}
    for b,_ in pairs(agg) do table.insert(sortedBases,b) end
    table.sort(sortedBases,function(a,b) return agg[a].count>agg[b].count end)

    if total==0 then
        local e=lbl(areas[2],"Tidak ada pet yang cocok",10,C.Red,Enum.TextXAlignment.Center)
        e.Size=UDim2.new(1,0,0,22) e.LayoutOrder=8
    else
        local idx=0
        for _,base in ipairs(sortedBases) do
            idx=idx+1
            local data=agg[base]
            local row=mk("Frame",{Size=UDim2.new(1,0,0,28),BackgroundColor3=C.Card,BorderSizePixel=0,LayoutOrder=7+idx,Parent=areas[2]})
            corner(row,5) stroke(row,C.Dim,1)
            local nl=lbl(row,base,11,C.White) nl.Size=UDim2.new(0.65,0,1,0) nl.Position=UDim2.new(0,10,0,0)
            local cnt=lbl(row,data.count.." pet",11,C.Teal,Enum.TextXAlignment.Right)
            cnt.Size=UDim2.new(0,80,1,0) cnt.Position=UDim2.new(1,-90,0,0)
            cnt.Font=Enum.Font.GothamBold
            if data.mutCount>0 then
                local mut=lbl(row,"("..data.mutCount.." mutasi)",9,C.Gold,Enum.TextXAlignment.Left)
                mut.Size=UDim2.new(0.35,0,0,11) mut.Position=UDim2.new(0,10,0,16)
                nl.Size=UDim2.new(0.65,0,0,16) nl.Position=UDim2.new(0,10,0,2)
            end
        end
        local tot=lbl(areas[2],"Total: "..total.." pet ("..(#sortedBases).." jenis)",11,C.Teal,Enum.TextXAlignment.Center)
        tot.Size=UDim2.new(1,0,0,16) tot.LayoutOrder=7+#sortedBases+1
    end
    div(areas[2],200)
    local rf=btn(areas[2],"Refresh",12,C.Panel,C.White) rf.Size=UDim2.new(1,0,0,22) rf.LayoutOrder=201 stroke(rf,C.Dim,1.2)
    rf.MouseButton1Click:Connect(function() buildMaxKGCache() buildTargetList() end)
end

-- ============================================
-- TAB 3: SWAP SKILL
-- ============================================
buildSwapList=function()
    for _,c in pairs(areas[3]:GetChildren()) do
        if c:IsA("Frame") or c:IsA("TextButton") or c:IsA("TextLabel") then c:Destroy() end
    end

    local infoCard=mk("Frame",{Size=UDim2.new(1,0,0,52),BackgroundColor3=C.Panel,BorderSizePixel=0,LayoutOrder=0,Parent=areas[3]})
    corner(infoCard,7) stroke(infoCard,C.Teal,1.2)
    mk("UIPadding",{PaddingTop=UDim.new(0,5),PaddingLeft=UDim.new(0,8),PaddingRight=UDim.new(0,8),PaddingBottom=UDim.new(0,5),Parent=infoCard})
    mk("UIListLayout",{SortOrder=Enum.SortOrder.LayoutOrder,Padding=UDim.new(0,2),Parent=infoCard})
    lbl(infoCard,"Swap Mechanic: friend-7",12,C.Teal).Size=UDim2.new(1,0,0,14)
    local descLbl=lbl(infoCard,"Toggle ON utk swap. Pet HARUS udah di garden (place manual/via tim).",10,C.Gray)
    descLbl.Size=UDim2.new(1,0,0,22) descLbl.TextWrapped=true

    local saRow=mk("Frame",{Size=UDim2.new(1,0,0,28),BackgroundColor3=C.Card,BorderSizePixel=0,LayoutOrder=1,Parent=areas[3]})
    corner(saRow,6) stroke(saRow,C.Dim,1.1)
    lbl(saRow,"Tampilkan semua pet",11,C.Gray).Size=UDim2.new(0.55,0,0,14)
    local saTxt=lbl(saRow,"(bypass filter love di section Favorit)",9,C.Dim) saTxt.Size=UDim2.new(0.6,0,0,11) saTxt.Position=UDim2.new(0,8,0,16)
    local saTog=btn(saRow,showAllPetsSwap and "ON" or "OFF",9,showAllPetsSwap and C.TDim or C.Panel,showAllPetsSwap and C.Teal or C.Gray)
    saTog.Size=UDim2.new(0,44,0,20) saTog.Position=UDim2.new(1,-50,0.5,-10)
    local saTogStroke=stroke(saTog,showAllPetsSwap and C.Teal or C.Dim,1.1)
    saTog.MouseButton1Click:Connect(function()
        showAllPetsSwap=not showAllPetsSwap save()
        buildSwapList()
    end)

    div(areas[3],2)

    local timRows={}
    local favRows={}
    local seen={}
    local bp=player:FindFirstChild("Backpack")
    local favCountTotal=0

    if bp then
        for _,item in pairs(bp:GetChildren()) do
            if isPet(item) then
                local uuid=getPetUUID(item)
                if uuid then
                    local uuidStr=tostring(uuid)
                    local name=getPetName(item)
                    local info=getPetInfo(item)
                    local isFav=isFavorite(item)
                    local inTim=teamPetUUIDs[uuidStr]==true
                    if isFav then favCountTotal=favCountTotal+1 end

                    swapPetInfoCache[uuidStr]={name=name,info=info}

                    if inTim then
                        seen[uuidStr]=true
                        table.insert(timRows,{uuid=uuidStr,info=info,isFav=isFav})
                    elseif showAllPetsSwap or isFav then
                        seen[uuidStr]=true
                        table.insert(favRows,{uuid=uuidStr,info=info,isFav=isFav})
                    end
                end
            end
        end
    end

    for uuid,_ in pairs(teamPetUUIDs) do
        if not seen[uuid] then
            seen[uuid]=true
            local cached=teamPetInfoCache[uuid] or swapPetInfoCache[uuid]
            local info=(cached and cached.info or uuid:sub(1,8).."...").." (di garden)"
            table.insert(timRows,{uuid=uuid,info=info,isFav=false})
        end
    end

    for uuid,cfg in pairs(swapPerPet) do
        if cfg.enabled and not seen[uuid] then
            local cached=swapPetInfoCache[uuid] or teamPetInfoCache[uuid]
            local info=(cached and cached.info or uuid:sub(1,8).."...").." (di garden)"
            table.insert(favRows,{uuid=uuid,info=info,isFav=false})
        end
    end

    local function makeRow(parent,r,layoutOrder)
        local uuid=r.uuid
        if not swapPerPet[uuid] then swapPerPet[uuid]={enabled=false} end
        local ps=swapPerPet[uuid]

        local row=mk("Frame",{Size=UDim2.new(1,0,0,28),BackgroundColor3=ps.enabled and C.TDim or C.Card,BorderSizePixel=0,LayoutOrder=layoutOrder,Parent=parent})
        corner(row,5) if ps.enabled then stroke(row,C.Teal,1.2) end
        local infoTxt=r.info
        if r.isFav then infoTxt=string.char(0xE2,0x99,0xA5).." "..infoTxt end
        local pl=lbl(row,infoTxt,9,ps.enabled and C.White or C.Gray) pl.Size=UDim2.new(0.69,0,1,0) pl.Position=UDim2.new(0,8,0,0)

        local cu1=uuid
        local selTog=btn(row,ps.enabled and "ON" or "OFF",9,ps.enabled and C.TDim or C.Panel,ps.enabled and C.Teal or C.Gray)
        selTog.Size=UDim2.new(0.26,0,0,20) selTog.Position=UDim2.new(0.72,2,0.5,-10)
        local selStroke=stroke(selTog,ps.enabled and C.Teal or C.Dim,1.1)
        selTog.MouseButton1Click:Connect(function()
            local p=swapPerPet[cu1] if not p then return end
            p.enabled=not p.enabled
            if p.enabled then
                selTog.Text="ON" selTog.BackgroundColor3=C.TDim selTog.TextColor3=C.Teal selStroke.Color=C.Teal
                row.BackgroundColor3=C.TDim
                local rs=row:FindFirstChildWhichIsA("UIStroke")
                if rs then rs.Color=C.Teal else stroke(row,C.Teal,1.2) end
                pl.TextColor3=C.White
            else
                selTog.Text="OFF" selTog.BackgroundColor3=C.Panel selTog.TextColor3=C.Gray selStroke.Color=C.Dim
                row.BackgroundColor3=C.Card
                local rs=row:FindFirstChildWhichIsA("UIStroke")
                if rs then rs:Destroy() end
                pl.TextColor3=C.Gray
            end
            save()
            if p.enabled then
                -- v10.4: auto-equip pet ke garden biar cooldown ke-track (gak nunggu START)
                pcall(function() equipPet(p.uuid) end)
                if startGlobalPoller then startGlobalPoller() end
                startSwapKeeper()
            end
        end)
    end

    local function makeSectionHeader(title,count,enabledCount,layoutOrder,color)
        local h=mk("Frame",{Size=UDim2.new(1,0,0,22),BackgroundColor3=C.Panel,BorderSizePixel=0,LayoutOrder=layoutOrder,Parent=areas[3]})
        corner(h,5) stroke(h,color or C.Teal,1.2)
        lbl(h,title.." ("..count.." pet, "..enabledCount.." ON)",9,color or C.Teal).Size=UDim2.new(1,-10,1,0)
    end

    local function countEnabled(rows)
        local n=0
        for _,r in ipairs(rows) do
            if swapPerPet[r.uuid] and swapPerPet[r.uuid].enabled then n=n+1 end
        end
        return n
    end

    local lo=3
    makeSectionHeader("Pet Tim Leveling",#timRows,countEnabled(timRows),lo,C.Gold) lo=lo+1
    if #timRows==0 then
        local e=lbl(areas[3],"Belum ada pet di Tim Leveling. Pilih dulu di tab 1.",10,C.Gray,Enum.TextXAlignment.Center)
        e.Size=UDim2.new(1,0,0,22) e.LayoutOrder=lo lo=lo+1
    else
        for _,r in ipairs(timRows) do
            makeRow(areas[3],r,lo) lo=lo+1
        end
    end

    mk("Frame",{Size=UDim2.new(1,0,0,8),BackgroundTransparency=1,LayoutOrder=lo,Parent=areas[3]}) lo=lo+1
    div(areas[3],lo) lo=lo+1

    makeSectionHeader("Pet Favorit (bukan tim)",#favRows,countEnabled(favRows),lo,C.Teal) lo=lo+1
    if #favRows==0 then
        local msg=favCountTotal==0 and "Belum ada pet di-love. Tekan icon love di pet game dulu." or "Tidak ada pet favorit di luar Tim Leveling"
        local e=lbl(areas[3],msg,10,C.Gray,Enum.TextXAlignment.Center)
        e.Size=UDim2.new(1,0,0,22) e.LayoutOrder=lo e.TextWrapped=true lo=lo+1
    else
        for _,r in ipairs(favRows) do
            makeRow(areas[3],r,lo) lo=lo+1
        end
    end

    div(areas[3],500)
    local rf=btn(areas[3],"Refresh",11,C.Panel,C.White) rf.Size=UDim2.new(1,0,0,22) rf.LayoutOrder=501 stroke(rf,C.Dim,1.2)
    rf.MouseButton1Click:Connect(function() buildSwapList() end)
    local clr=btn(areas[3],"Clear Semua (matikan)",11,C.RDim,C.Red) clr.Size=UDim2.new(1,0,0,22) clr.LayoutOrder=502 stroke(clr,C.Red,1.2)
    clr.MouseButton1Click:Connect(function()
        for uuid,cfg in pairs(swapPerPet) do
            cfg.enabled=false
        end
        save() buildSwapList()
    end)
end

-- ============================================
-- TAB 4: OTHER SETTING
-- ============================================
local function buildOtherSetting()
    for _,c in pairs(areas[4]:GetChildren()) do
        if c:IsA("Frame") or c:IsA("TextLabel") then c:Destroy() end
    end
    local function cfgRow(labelTxt,lo,default,onChange)
        local r=mk("Frame",{Size=UDim2.new(1,0,0,26),BackgroundColor3=C.Card,BorderSizePixel=0,LayoutOrder=lo,Parent=areas[4]})
        corner(r,6) stroke(r,C.Dim,1.1)
        lbl(r,labelTxt,11,C.Gray).Size=UDim2.new(0.6,0,1,0)
        local box=mk("TextBox",{Size=UDim2.new(0,56,0,20),Position=UDim2.new(1,-62,0.5,-10),BackgroundColor3=C.Panel,Text=tostring(default),TextColor3=C.White,Font=Enum.Font.GothamBold,TextSize=14,TextScaled=false,TextXAlignment=Enum.TextXAlignment.Center,ClearTextOnFocus=false,Parent=r})
        corner(box,5) stroke(box,C.Dim,1)
        box:GetPropertyChangedSignal("Text"):Connect(function() local v=tonumber(box.Text) if v then onChange(v) save() end end)
    end

    local t1=lbl(areas[4],"LEVELING",11,C.Teal) t1.Size=UDim2.new(1,0,0,14) t1.LayoutOrder=0
    local _,asTog,asTogStroke,asStroke=togRow(areas[4],"Auto Start Leveling","Auto mulai saat script dijalankan",1)
    local function setAsTog(val)
        asTog.Text=val and "ON" or "OFF" asTog.BackgroundColor3=val and C.TDim or C.Panel asTog.TextColor3=val and C.Teal or C.Gray asTogStroke.Color=val and C.Teal or C.Dim asStroke.Color=val and C.Teal or C.Dim
    end
    setAsTog(autoStartEnabled)
    asTog.MouseButton1Click:Connect(function() autoStartEnabled=not autoStartEnabled setAsTog(autoStartEnabled) save() end)

    div(areas[4],2)
    local t2=lbl(areas[4],"REJOIN",11,C.Teal) t2.Size=UDim2.new(1,0,0,14) t2.LayoutOrder=3
    local rnBtn=btn(areas[4],"Rejoin Now",12,C.TDim,C.Teal)
    rnBtn.Size=UDim2.new(1,0,0,24) rnBtn.LayoutOrder=4 stroke(rnBtn,C.Teal,1.5)
    rnBtn.MouseButton1Click:Connect(function() rnBtn.Text="Rejoining..." task.wait(0.5) TS:Teleport(game.PlaceId,player) end)
    cfgRow("Interval (menit)",5,config.rejoinMinutes,function(v)
        config.rejoinMinutes=math.max(1,math.min(120,v)) d.config.rejoinMinutes=config.rejoinMinutes save()
    end)

    local _row
    _row,arTog2,arTogStroke2,arStroke2=togRow(areas[4],"Auto Rejoin","Rejoin otomatis sesuai interval",6)
    cdLbl2=lbl(areas[4],"Auto Rejoin: OFF",11,C.Gray,Enum.TextXAlignment.Center)
    cdLbl2.Size=UDim2.new(1,0,0,20) cdLbl2.LayoutOrder=7 cdLbl2.BackgroundColor3=C.Panel cdLbl2.BackgroundTransparency=0
    corner(cdLbl2,6) stroke(cdLbl2,C.Dim,1.1)

    local function setArTog(val)
        arTog2.Text=val and "ON" or "OFF" arTog2.BackgroundColor3=val and C.TDim or C.Panel arTog2.TextColor3=val and C.Teal or C.Gray arTogStroke2.Color=val and C.Teal or C.Dim arStroke2.Color=val and C.Teal or C.Dim
    end
    setArTog(autoRejoin)

    div(areas[4],8)
    local t3=lbl(areas[4],"ANTI-AFK",11,C.Teal) t3.Size=UDim2.new(1,0,0,14) t3.LayoutOrder=9
    local _,afkTog,afkTogStroke,afkStroke=togRow(areas[4],"Anti-AFK","Cegah kick AFK 20menit (auto)",10)
    local function setAfkTog(v)
        afkTog.Text=v and "ON" or "OFF" afkTog.BackgroundColor3=v and C.TDim or C.Panel afkTog.TextColor3=v and C.Teal or C.Gray afkTogStroke.Color=v and C.Teal or C.Dim afkStroke.Color=v and C.Teal or C.Dim
    end
    setAfkTog(antiAfk)
    afkTog.MouseButton1Click:Connect(function() antiAfk=not antiAfk setAfkTog(antiAfk) save() end)
end

-- ============================================
-- TAB 5: AUTO GIFT
-- ============================================
local accStatusLbl=nil
local sendStatusLbl=nil

-- v12.79: Modal picker helper — floating popup overlay (replaces inline expanding pickers)
-- usage: showPickerModal({title=, items={{value=,label=,selected=}}, multi=, onSelect=, emptyText=})
local function showPickerModal(opts)
    local backdrop=mk("Frame",{Size=UDim2.new(1,0,1,0),Position=UDim2.new(0,0,0,0),BackgroundColor3=Color3.new(0,0,0),BackgroundTransparency=0.45,BorderSizePixel=0,ZIndex=100,Parent=main})
    local function close()
        if backdrop and backdrop.Parent then backdrop:Destroy() end
        if opts.onClose then opts.onClose() end
    end
    local backBtn=mk("TextButton",{Size=UDim2.new(1,0,1,0),BackgroundTransparency=1,Text="",AutoButtonColor=false,ZIndex=100,Parent=backdrop})
    backBtn.MouseButton1Click:Connect(close)

    local box=mk("Frame",{Size=UDim2.new(0.85,0,0.78,0),Position=UDim2.new(0.5,0,0.5,0),AnchorPoint=Vector2.new(0.5,0.5),BackgroundColor3=C.BG,BorderSizePixel=0,ZIndex=101,Parent=backdrop})
    corner(box,8) stroke(box,C.Teal,1.5)
    -- click guard biar klik di dalam box gak nutup modal
    mk("TextButton",{Size=UDim2.new(1,0,1,0),BackgroundTransparency=1,Text="",AutoButtonColor=false,ZIndex=101,Parent=box})

    local titleBar=mk("Frame",{Size=UDim2.new(1,0,0,32),BackgroundColor3=C.Panel,BorderSizePixel=0,ZIndex=102,Parent=box})
    corner(titleBar,7)
    local titleLbl=lbl(titleBar,opts.title or "Pilih",15,C.Teal,Enum.TextXAlignment.Left)
    titleLbl.Size=UDim2.new(1,-42,1,0) titleLbl.Position=UDim2.new(0,12,0,0) titleLbl.Font=Enum.Font.GothamBold titleLbl.ZIndex=103
    local closeBtn=btn(titleBar,"X",14,C.Panel,C.Red)
    closeBtn.Size=UDim2.new(0,28,0,24) closeBtn.Position=UDim2.new(1,-32,0.5,-12) closeBtn.Font=Enum.Font.GothamBold closeBtn.ZIndex=103
    closeBtn.MouseButton1Click:Connect(close)

    local searchBox=mk("TextBox",{Size=UDim2.new(1,-16,0,30),Position=UDim2.new(0,8,0,38),BackgroundColor3=C.Panel,Text="",PlaceholderText="Search...",PlaceholderColor3=C.Dim,TextColor3=C.White,Font=Enum.Font.Gotham,TextSize=14,TextXAlignment=Enum.TextXAlignment.Left,ClearTextOnFocus=false,ZIndex=102,Parent=box})
    corner(searchBox,6) stroke(searchBox,C.Dim,1)
    mk("UIPadding",{PaddingLeft=UDim.new(0,8),PaddingRight=UDim.new(0,8),Parent=searchBox})

    local list=mk("ScrollingFrame",{Size=UDim2.new(1,-12,1,-78),Position=UDim2.new(0,6,0,74),BackgroundTransparency=1,ScrollBarThickness=4,ScrollBarImageColor3=C.Teal,CanvasSize=UDim2.new(0,0,0,0),AutomaticCanvasSize=Enum.AutomaticSize.Y,ZIndex=102,Parent=box})
    mk("UIListLayout",{SortOrder=Enum.SortOrder.LayoutOrder,Padding=UDim.new(0,3),Parent=list})
    mk("UIPadding",{PaddingTop=UDim.new(0,4),PaddingLeft=UDim.new(0,4),PaddingRight=UDim.new(0,4),PaddingBottom=UDim.new(0,4),Parent=list})

    local function renderItems(filter)
        for _,c in pairs(list:GetChildren()) do if c:IsA("Frame") or c:IsA("TextLabel") then c:Destroy() end end
        filter=(filter or ""):lower()
        local count=0
        for _,item in ipairs(opts.items or {}) do
            local txt=item.label or item.value or "?"
            if filter=="" or txt:lower():find(filter,1,true) then
                count=count+1
                local sel=item.selected
                local row=mk("Frame",{Size=UDim2.new(1,0,0,32),BackgroundColor3=sel and C.TDim or C.Card,BorderSizePixel=0,LayoutOrder=count,ZIndex=103,Parent=list})
                corner(row,5) if sel then stroke(row,C.Teal,1.1) end
                local nl=lbl(row,txt,14,sel and C.Teal or C.White) nl.Size=UDim2.new(1,-12,1,0) nl.Position=UDim2.new(0,10,0,0) nl.ZIndex=104
                local cover=mk("TextButton",{Size=UDim2.new(1,0,1,0),BackgroundTransparency=1,Text="",AutoButtonColor=false,ZIndex=104,Parent=row})
                local cap=item
                cover.MouseButton1Click:Connect(function()
                    cap.selected = not cap.selected
                    if opts.onSelect then opts.onSelect(cap.value, cap.selected) end
                    if opts.multi then
                        renderItems(searchBox.Text)
                    else
                        close()
                    end
                end)
            end
        end
        if count==0 then
            local e=lbl(list,opts.emptyText or "(kosong)",13,C.Gray,Enum.TextXAlignment.Center)
            e.Size=UDim2.new(1,-12,0,28) e.LayoutOrder=1 e.ZIndex=103
        end
    end
    renderItems("")
    searchBox:GetPropertyChangedSignal("Text"):Connect(function() renderItems(searchBox.Text) end)
end

local function buildAutoGift()
    for _,c in pairs(areas[5]:GetChildren()) do
        if c:IsA("Frame") or c:IsA("TextLabel") or c:IsA("TextButton") then c:Destroy() end
    end

    local ivRow=mk("Frame",{Size=UDim2.new(1,0,0,26),BackgroundColor3=C.Card,BorderSizePixel=0,LayoutOrder=0,Parent=areas[5]})
    corner(ivRow,6) stroke(ivRow,C.Dim,1.1)
    lbl(ivRow,"Interval Send (dtk):",11,C.Gray).Size=UDim2.new(0.6,0,1,0)
    local ivBox=mk("TextBox",{Size=UDim2.new(0,50,0,20),Position=UDim2.new(1,-56,0.5,-10),BackgroundColor3=C.Panel,Text=tostring(sendInterval),TextColor3=C.White,Font=Enum.Font.GothamBold,TextSize=14,TextScaled=false,TextXAlignment=Enum.TextXAlignment.Center,ClearTextOnFocus=false,Parent=ivRow})
    corner(ivBox,5) stroke(ivBox,C.Dim,1)
    ivBox:GetPropertyChangedSignal("Text"):Connect(function() local v=tonumber(ivBox.Text) if v then sendInterval=math.max(5,v) save() end end)

    local function makeCollapsible(title,layoutOrder)
        local hdr=mk("Frame",{Size=UDim2.new(1,0,0,32),BackgroundColor3=C.Card,BorderSizePixel=0,LayoutOrder=layoutOrder,Parent=areas[5]})
        corner(hdr,7) local hdrStroke=stroke(hdr,C.Dim,1.2)
        local titleLbl=lbl(hdr,title,13,C.White) titleLbl.Size=UDim2.new(0.85,0,1,0) titleLbl.Position=UDim2.new(0,12,0,0) titleLbl.Font=Enum.Font.GothamBold
        local arrow=lbl(hdr,"v",13,C.Teal,Enum.TextXAlignment.Right) arrow.Size=UDim2.new(0,24,1,0) arrow.Position=UDim2.new(1,-30,0,0)
        local cover=mk("TextButton",{Size=UDim2.new(1,0,1,0),BackgroundTransparency=1,Text="",AutoButtonColor=false,Parent=hdr})
        local content=mk("Frame",{Size=UDim2.new(1,0,0,0),BackgroundColor3=C.Panel,BorderSizePixel=0,Visible=false,LayoutOrder=layoutOrder+1,ClipsDescendants=true,AutomaticSize=Enum.AutomaticSize.None,Parent=areas[5]})
        corner(content,7) stroke(content,C.Dim,1)
        mk("UIListLayout",{SortOrder=Enum.SortOrder.LayoutOrder,Padding=UDim.new(0,3),Parent=content})
        mk("UIPadding",{PaddingTop=UDim.new(0,5),PaddingLeft=UDim.new(0,5),PaddingRight=UDim.new(0,5),PaddingBottom=UDim.new(0,5),Parent=content})
        local open=false
        cover.MouseButton1Click:Connect(function()
            open=not open
            content.Visible=open
            if open then
                content.AutomaticSize=Enum.AutomaticSize.Y
                arrow.Text="^" hdrStroke.Color=C.Teal
            else
                content.AutomaticSize=Enum.AutomaticSize.None
                content.Size=UDim2.new(1,0,0,0)
                arrow.Text="v" hdrStroke.Color=C.Dim
            end
        end)
        return content
    end

    local function buildGiftContent(slotIdx,parent)
        local slot=giftSlots[slotIdx]

        -- v12.79: Target picker → modal popup
        local function trText() return slot.target == "" and "(klik pilih)" or slot.target end
        local trRow=mk("Frame",{Size=UDim2.new(1,0,0,32),BackgroundColor3=C.Card,BorderSizePixel=0,LayoutOrder=1,Parent=parent})
        corner(trRow,6) local trStroke=stroke(trRow,C.Dim,1.1)
        local trLbl=lbl(trRow,"Target: "..trText(),13,C.White) trLbl.Size=UDim2.new(0.85,0,1,0) trLbl.Position=UDim2.new(0,10,0,0)
        local trIcon=lbl(trRow,">",14,C.Teal,Enum.TextXAlignment.Right) trIcon.Size=UDim2.new(0,20,1,0) trIcon.Position=UDim2.new(1,-24,0,0)
        local trCover=mk("TextButton",{Size=UDim2.new(1,0,1,0),BackgroundTransparency=1,Text="",AutoButtonColor=false,Parent=trRow})
        trCover.MouseButton1Click:Connect(function()
            local items={{value="",label="(Batalin pilihan)",selected=(slot.target=="")}}
            local plist={}
            for _,p in ipairs(Players:GetPlayers()) do
                if p ~= player then table.insert(plist,p.Name) end
            end
            table.sort(plist)
            for _,name in ipairs(plist) do
                table.insert(items,{value=name,label=name,selected=(slot.target==name)})
            end
            showPickerModal({
                title="Pilih Target Player (Gift "..slotIdx..")",
                items=items, multi=false,
                emptyText="(belum ada player lain di server)",
                onSelect=function(value,_)
                    slot.target=value
                    trLbl.Text="Target: "..(value=="" and "(klik pilih)" or value)
                    trStroke.Color=(value=="" and C.Dim or C.Teal)
                    save()
                end,
            })
        end)

        local function countTypes() local n=0 for _ in pairs(slot.petTypes) do n=n+1 end return n end
        local function countMatching()
            local n=0 local bp=player:FindFirstChild("Backpack")
            if bp then for _,it in pairs(bp:GetChildren()) do if isPet(it) and slot.petTypes[getBaseName(getPetName(it))] then n=n+1 end end end
            return n
        end

        -- v12.79: Pet Type picker → modal popup (multi-select)
        local pickRow=mk("Frame",{Size=UDim2.new(1,0,0,32),BackgroundColor3=C.Card,BorderSizePixel=0,LayoutOrder=3,Parent=parent})
        corner(pickRow,6) local pickStroke=stroke(pickRow,C.Dim,1.1)
        local pickLbl=lbl(pickRow,"Pilih Jenis Pet ("..countTypes().." = "..countMatching().." pet)",13,C.White)
        pickLbl.Size=UDim2.new(0.85,0,1,0) pickLbl.Position=UDim2.new(0,10,0,0)
        local pickIcon=lbl(pickRow,">",14,C.Teal,Enum.TextXAlignment.Right) pickIcon.Size=UDim2.new(0,20,1,0) pickIcon.Position=UDim2.new(1,-24,0,0)
        local pickCover=mk("TextButton",{Size=UDim2.new(1,0,1,0),BackgroundTransparency=1,Text="",AutoButtonColor=false,Parent=pickRow})
        pickCover.MouseButton1Click:Connect(function()
            local types={}
            local bp=player:FindFirstChild("Backpack")
            if bp then
                for _,it in pairs(bp:GetChildren()) do
                    if isPet(it) then
                        local name=getPetName(it) local base=getBaseName(name)
                        if not types[base] then types[base]={count=0,mut=0} end
                        types[base].count=types[base].count+1
                        if name~=base then types[base].mut=types[base].mut+1 end
                    end
                end
            end
            local sorted={} for b,_ in pairs(types) do table.insert(sorted,b) end
            table.sort(sorted,function(a,b) return types[a].count>types[b].count end)
            local items={}
            for _,base in ipairs(sorted) do
                local data=types[base]
                local labelTxt=base.." ("..data.count..(data.mut>0 and ", "..data.mut.." mut" or "")..")"
                table.insert(items,{value=base,label=labelTxt,selected=(slot.petTypes[base]==true)})
            end
            showPickerModal({
                title="Pilih Jenis Pet (Gift "..slotIdx..", multi)",
                items=items, multi=true,
                emptyText="Backpack kosong",
                onSelect=function(value,isSelected)
                    if isSelected then slot.petTypes[value]=true else slot.petTypes[value]=nil end
                    pickLbl.Text="Pilih Jenis Pet ("..countTypes().." = "..countMatching().." pet)"
                    pickStroke.Color=(countTypes()>0 and C.Teal or C.Dim)
                    save()
                end,
            })
        end)

        -- v12.79: Mutation Filter picker → modal popup
        local function mfText()
            if slot.mutationFilter == "" then return "(Semua mutasi)" end
            if slot.mutationFilter == "__nomut__" then return "[TANPA MUTASI]" end
            return slot.mutationFilter
        end
        local mfRow=mk("Frame",{Size=UDim2.new(1,0,0,30),BackgroundColor3=C.Card,BorderSizePixel=0,LayoutOrder=5,Parent=parent})
        corner(mfRow,6) local mfStroke=stroke(mfRow,C.Dim,1.1)
        local mfLbl=lbl(mfRow,"Mutasi: "..mfText(),13,C.White) mfLbl.Size=UDim2.new(0.85,0,1,0) mfLbl.Position=UDim2.new(0,10,0,0)
        local mfIcon=lbl(mfRow,">",14,C.Teal,Enum.TextXAlignment.Right) mfIcon.Size=UDim2.new(0,20,1,0) mfIcon.Position=UDim2.new(1,-24,0,0)
        local mfCover=mk("TextButton",{Size=UDim2.new(1,0,1,0),BackgroundTransparency=1,Text="",AutoButtonColor=false,Parent=mfRow})
        mfCover.MouseButton1Click:Connect(function()
            local items={
                {value="",label="(Semua mutasi)",selected=(slot.mutationFilter=="")},
                {value="__nomut__",label="[TANPA MUTASI]",selected=(slot.mutationFilter=="__nomut__")},
            }
            for _,prefix in ipairs(MUTATION_PREFIXES) do
                local clean=prefix:gsub("%s+$","")
                if clean ~= "" then
                    table.insert(items,{value=clean,label=clean,selected=(slot.mutationFilter==clean)})
                end
            end
            showPickerModal({
                title="Pilih Mutation Filter (Gift "..slotIdx..")",
                items=items, multi=false,
                onSelect=function(value,_)
                    slot.mutationFilter=value
                    mfLbl.Text="Mutasi: "..mfText()
                    mfStroke.Color=(value=="" and C.Dim or C.Teal)
                    save()
                end,
            })
        end)

        local kgRow=mk("Frame",{Size=UDim2.new(1,0,0,26),BackgroundColor3=C.Card,BorderSizePixel=0,LayoutOrder=8,Parent=parent})
        corner(kgRow,6) stroke(kgRow,C.Dim,1.1)
        lbl(kgRow,"KG: -N=bawah, N=atas",11,C.Gray).Size=UDim2.new(0.7,0,1,0)
        local kgBox=mk("TextBox",{Size=UDim2.new(0,60,0,20),Position=UDim2.new(1,-66,0.5,-10),BackgroundColor3=C.Panel,Text=slot.kg,PlaceholderText="-60",PlaceholderColor3=C.Dim,TextColor3=C.White,Font=Enum.Font.GothamBold,TextSize=14,TextScaled=false,TextXAlignment=Enum.TextXAlignment.Center,ClearTextOnFocus=false,Parent=kgRow})
        corner(kgBox,5) stroke(kgBox,C.Dim,1)
        kgBox:GetPropertyChangedSignal("Text"):Connect(function() slot.kg=kgBox.Text save() end)

        local ageRow=mk("Frame",{Size=UDim2.new(1,0,0,26),BackgroundColor3=C.Card,BorderSizePixel=0,LayoutOrder=7,Parent=parent})
        corner(ageRow,6) stroke(ageRow,C.Dim,1.1)
        lbl(ageRow,"Age: -N=bawah, N=atas",11,C.Gray).Size=UDim2.new(0.7,0,1,0)
        local ageBox=mk("TextBox",{Size=UDim2.new(0,60,0,20),Position=UDim2.new(1,-66,0.5,-10),BackgroundColor3=C.Panel,Text=slot.age,PlaceholderText="-100",PlaceholderColor3=C.Dim,TextColor3=C.White,Font=Enum.Font.GothamBold,TextSize=14,TextScaled=false,TextXAlignment=Enum.TextXAlignment.Center,ClearTextOnFocus=false,Parent=ageRow})
        corner(ageBox,5) stroke(ageBox,C.Dim,1)
        ageBox:GetPropertyChangedSignal("Text"):Connect(function() slot.age=ageBox.Text save() end)

        local _,fvTog,fvTS,fvSS=togRow(parent,"Kirim pet di-love juga","Default OFF: skip pet love",9)
        local function setFv(v) fvTog.Text=v and "ON" or "OFF" fvTog.BackgroundColor3=v and C.TDim or C.Panel fvTog.TextColor3=v and C.Teal or C.Gray fvTS.Color=v and C.Teal or C.Dim fvSS.Color=v and C.Teal or C.Dim end
        setFv(slot.includeFav)
        fvTog.MouseButton1Click:Connect(function() slot.includeFav=not slot.includeFav setFv(slot.includeFav) save() end)

        local _,sgTog,sgTS,sgSS=togRow(parent,"Auto Send Gift","Kirim gift otomatis",10)
        local function setSg(v) sgTog.Text=v and "ON" or "OFF" sgTog.BackgroundColor3=v and C.TDim or C.Panel sgTog.TextColor3=v and C.Teal or C.Gray sgTS.Color=v and C.Teal or C.Dim sgSS.Color=v and C.Teal or C.Dim end
        setSg(slot.autoSendGift)
        sgTog.MouseButton1Click:Connect(function() slot.autoSendGift=not slot.autoSendGift setSg(slot.autoSendGift) save() end)

        local _,stTog,stTS,stSS=togRow(parent,"Auto Send Trade","Kirim trade otomatis",11)
        local function setSt(v) stTog.Text=v and "ON" or "OFF" stTog.BackgroundColor3=v and C.TDim or C.Panel stTog.TextColor3=v and C.Teal or C.Gray stTS.Color=v and C.Teal or C.Dim stSS.Color=v and C.Teal or C.Dim end
        setSt(slot.autoSendTrade)
        stTog.MouseButton1Click:Connect(function() slot.autoSendTrade=not slot.autoSendTrade setSt(slot.autoSendTrade) save() end)

        local _,uvTog,uvTS,uvSS=togRow(parent,"Auto Unfav Pet","Auto unlove pet match filter",12)
        local function setUv(v) uvTog.Text=v and "ON" or "OFF" uvTog.BackgroundColor3=v and C.TDim or C.Panel uvTog.TextColor3=v and C.Teal or C.Gray uvTS.Color=v and C.Teal or C.Dim uvSS.Color=v and C.Teal or C.Dim end
        setUv(slot.autoUnfav)
        uvTog.MouseButton1Click:Connect(function() slot.autoUnfav=not slot.autoUnfav setUv(slot.autoUnfav) save() end)
    end

    for i=1,3 do
        local content=makeCollapsible("Gift "..i,i*10)
        buildGiftContent(i,content)
    end

    local accContent=makeCollapsible("Auto Accept Gift / Trade",50)
    local _,agTog,agTS,agSS=togRow(accContent,"Auto Accept Gift","Auto terima gift masuk",1)
    agTog.Text=autoAccGift and "ON" or "OFF" agTog.BackgroundColor3=autoAccGift and C.TDim or C.Panel agTog.TextColor3=autoAccGift and C.Teal or C.Gray agTS.Color=autoAccGift and C.Teal or C.Dim agSS.Color=autoAccGift and C.Teal or C.Dim
    agTog.MouseButton1Click:Connect(function()
        autoAccGift=not autoAccGift
        if autoAccGift then agTog.Text="ON" agTog.BackgroundColor3=C.TDim agTog.TextColor3=C.Teal agTS.Color=C.Teal agSS.Color=C.Teal
        else agTog.Text="OFF" agTog.BackgroundColor3=C.Panel agTog.TextColor3=C.Gray agTS.Color=C.Dim agSS.Color=C.Dim end
        save()
    end)

    local _,atTog,atTS,atSS=togRow(accContent,"Auto Accept Trade","Auto terima trade masuk",2)
    atTog.Text=autoAccTrade and "ON" or "OFF" atTog.BackgroundColor3=autoAccTrade and C.TDim or C.Panel atTog.TextColor3=autoAccTrade and C.Teal or C.Gray atTS.Color=autoAccTrade and C.Teal or C.Dim atSS.Color=autoAccTrade and C.Teal or C.Dim
    atTog.MouseButton1Click:Connect(function()
        autoAccTrade=not autoAccTrade
        if autoAccTrade then atTog.Text="ON" atTog.BackgroundColor3=C.TDim atTog.TextColor3=C.Teal atTS.Color=C.Teal atSS.Color=C.Teal
        else atTog.Text="OFF" atTog.BackgroundColor3=C.Panel atTog.TextColor3=C.Gray atTS.Color=C.Dim atSS.Color=C.Dim end
        save()
    end)

    sendStatusLbl=lbl(areas[5],"Send: idle",11,C.Gray,Enum.TextXAlignment.Center)
    sendStatusLbl.Size=UDim2.new(1,0,0,18) sendStatusLbl.LayoutOrder=60 sendStatusLbl.BackgroundColor3=C.Panel sendStatusLbl.BackgroundTransparency=0
    corner(sendStatusLbl,5) stroke(sendStatusLbl,C.Dim,1)

    accStatusLbl=lbl(areas[5],"Accept: idle",11,C.Gray,Enum.TextXAlignment.Center)
    accStatusLbl.Size=UDim2.new(1,0,0,18) accStatusLbl.LayoutOrder=61 accStatusLbl.BackgroundColor3=C.Panel accStatusLbl.BackgroundTransparency=0
    corner(accStatusLbl,5) stroke(accStatusLbl,C.Dim,1)
end

buildTimList() buildTargetList() buildSwapList() buildOtherSetting() buildAutoGift()
switchTab(1)
dbg("Step 5 OK: GUI READY! Klik tab di atas. Tutup debug ini -> klik X.")

-- ============================================
-- AUTO REJOIN
-- ============================================
local function stopAR()
    isAR=false
    if arTask then task.cancel(arTask) arTask=nil end
    autoRejoin=false save()
    if arTog2 then arTog2.Text="OFF" arTog2.BackgroundColor3=C.Panel arTog2.TextColor3=C.Gray arTogStroke2.Color=C.Dim arStroke2.Color=C.Dim end
    if cdLbl2 then cdLbl2.Text="Auto Rejoin: OFF" end
end

local function startAR()
    isAR=true autoRejoin=true save()
    arTog2.Text="ON" arTog2.BackgroundColor3=C.TDim arTog2.TextColor3=C.Teal arTogStroke2.Color=C.Teal arStroke2.Color=C.Teal
    arTask=task.spawn(function()
        while isAR do
            local mins=d.config.rejoinMinutes or 30
            for i=mins*60,1,-1 do
                if not isAR then return end
                cdLbl2.Text=string.format("Rejoin dalam: %02d:%02d",math.floor(i/60),i%60)
                task.wait(1)
            end
            if isAR then
                cdLbl2.Text="Rejoining..."
                task.wait(0.5)
                TS:Teleport(game.PlaceId,player)
            end
        end
    end)
end

arTog2.MouseButton1Click:Connect(function()
    if isAR then stopAR() else startAR() end
end)

-- ============================================
-- ANTI-AFK
-- ============================================
do
    local VirtualUser=nil
    pcall(function() VirtualUser=game:GetService("VirtualUser") end)
    if VirtualUser then
        player.Idled:Connect(function()
            if not antiAfk then return end
            pcall(function()
                VirtualUser:CaptureController()
                VirtualUser:ClickButton2(Vector2.new())
            end)
            print("[ZenxAFK] anti-afk triggered (idle detected)")
        end)
        print("[ZenxAFK] Anti-AFK hook installed")
    else
        warn("[ZenxAFK] VirtualUser tidak tersedia di executor ini")
    end
end

-- ============================================
-- AUTO SEND LOOP (FIXED v8.2: trade pakai array, bukan single uuid)
-- ============================================
local scriptShutdown = false
local autoSendTask = nil
local connections = {}  -- track event connections biar bisa disconnect pas close
autoSendTask = task.spawn(function()
    local function getPetsForSlot(slot)
        local list={}
        local bp=player:FindFirstChild("Backpack")
        if bp then
            for _,item in pairs(bp:GetChildren()) do
                if isPet(item) then
                    local fullName = getPetName(item)
                    local base = getBaseName(fullName)
                    if slot.petTypes[base] then
                        local mf = slot.mutationFilter or ""
                        local mfPass
                        if mf == "" then mfPass = true
                        elseif mf == "__nomut__" then mfPass = (base == fullName)
                        else mfPass = fullName:find(mf, 1, true) ~= nil end
                        if mfPass and passKgFilter(item,slot.kg) and passAgeFilter(item,slot.age) then
                            local uuid=getPetUUID(item)
                            if uuid then table.insert(list,{uuid=tostring(uuid),fav=isFavorite(item)}) end
                        end
                    end
                end
            end
        end
        return list
    end

    while not scriptShutdown do
        for slotIdx=1,3 do
            if scriptShutdown then break end
            local slot=giftSlots[slotIdx]
            if slot and slot.target~="" and (slot.autoSendGift or slot.autoSendTrade or slot.autoUnfav) then
                local matched=getPetsForSlot(slot)
                if #matched>0 then
                    if slot.autoUnfav then
                        local unfavCount=0
                        for _,pet in ipairs(matched) do
                            if pet.fav then
                                unfavoritePet(pet.uuid)
                                print("[ZenxUnfav] slot "..slotIdx.." unfav "..pet.uuid)
                                unfavCount=unfavCount+1
                                task.wait(0.2)
                            end
                        end
                        if unfavCount>0 and sendStatusLbl then
                            sendStatusLbl.Text="Slot "..slotIdx.." unfav "..unfavCount.." pet" sendStatusLbl.TextColor3=C.Gold
                            task.wait(0.8)
                        end
                        matched=getPetsForSlot(slot)
                    end

                    local sendable={}
                    for _,pet in ipairs(matched) do
                        if slot.includeFav or (not pet.fav) then
                            table.insert(sendable,pet.uuid)
                        end
                    end

                    if #sendable>0 then
                        if slot.autoSendGift then
                            if sendStatusLbl then sendStatusLbl.Text="Slot "..slotIdx..": gift "..#sendable.." -> "..slot.target sendStatusLbl.TextColor3=C.Teal end
                            local okCount=0
                            local sentCount=0
                            for _,uuid in ipairs(sendable) do
                                if not slot.autoSendGift then break end
                                if sendGiftToPlayer(slot.target,uuid) then okCount=okCount+1 end
                                sentCount = sentCount + 1
                                task.wait(0.2)
                            end
                            if sendStatusLbl then
                                sendStatusLbl.Text="Slot "..slotIdx.." gift: "..okCount.."/"..sentCount.." OK"
                                sendStatusLbl.TextColor3=okCount==sentCount and C.Teal or C.Gold
                            end
                        end
                        if slot.autoSendTrade then
                            if sendStatusLbl then sendStatusLbl.Text="Slot "..slotIdx..": trade "..#sendable.." pet -> "..slot.target sendStatusLbl.TextColor3=C.Teal end
                            sendTradeToPlayer(slot.target, sendable)
                        end
                    end
                end
                task.wait(1)
            end
        end
        task.wait(math.max(5,sendInterval))
    end
end)

-- ============================================
-- AUTO ACCEPT HOOKS (FIXED v8.2)
-- ============================================
;(function()  -- v12.78 misc IIFE-wrapped (zero main-chunk locals contribution)

-- ============================================
-- v12.78b: MISC SECTION - rewrite from testbed v1.4 (compact: state in single table)
-- ============================================

-- All state packed into ONE local table biar gak makan local-count budget
local M78 = {
    -- Toggles (loaded dari saved data)
    autoBuyEgg = d.autoBuyEgg or false,
    autoBuySeed = d.autoBuySeed or false,
    autoBuyGear = d.autoBuyGear or false,
    autoFeedPet = d.autoFeedPet or false,
    autoCollect = d.autoCollect or false,
    feedThresholdPct = d.feedThresholdPct or 70, -- legacy, gak dipake lagi tp tetep di-load biar gak break
    feedCycleMin = d.feedCycleMin or 15,
    feedDuration = 20,
    feedMode = "idle",
    feedNextStartAt = 0,
    feedEndAt = 0,
    -- Hidden defaults
    miscBuyInterval = 5,
    feedCooldown = 5,
    feedMaxPerTick = 10,
    feedInterval = 1,
    collectInterval = 0.5,
    backpackLimit = 200,
    -- v12.79: collect cycle (mirip feed)
    collectCycleMin = 15,
    collectDuration = 20,
    collectMode = "idle",
    collectNextStartAt = 0,
    collectEndAt = 0,
    collectMaxDist = 0,
    collectMatch = "Collect",
    -- Runtime state
    petFeedState = {},
    feedTotalPets = 0,
    feedHungry = 0,
    feedTotalFed = 0,
    lastFood = "-",
    promptsCache = {},
    promptsCacheT = 0,
    promptsConfigured = setmetatable({}, {__mode = "k"}),
    lastBpFruits = 0,
    lastBpTotal = 0,
    lastPromptCount = 0,
    collectTotalFired = 0,
    buySeedFired = 0,
    buyGearFired = 0,
    buyEggFired = 0,
    statusLbl = nil,
    -- Item lists
    SEEDS = {"Carrot","Strawberry","Blueberry","Tomato","Watermelon","Pumpkin","Apple","Bamboo","Coconut","Cactus","Dragon Fruit","Mango","Grape","Pepper","Mushroom","Beanstalk","Pineapple","Peach","Sugar Apple","Cocoa","Banana","Lily","Bell Pepper","Prickly Pear","Loquat","Feijoa","Cherry","Rose","Lemon"},
    GEARS = {"Watering Can","Trowel","Recall Wrench","Basic Sprinkler","Advanced Sprinkler","Godly Sprinkler","Master Sprinkler","Magnifying Glass","Tanning Mirror","Cleaning Spray","Favorite Tool","Harvest Tool","Friendship Pot","Trading Ticket","Lightning Rod","Star Caller","Night Staff","Chocolate Sprinkler","Honey Sprinkler","Nectar Staff","Levelup Lollipop"},
    EGGS = {"Common Egg","Uncommon Egg","Rare Egg","Legendary Egg","Mythical Egg","Bug Egg","Night Egg","Premium Night Egg","Bee Egg","Anti Bee Egg","Common Summer Egg","Rare Summer Egg","Paradise Egg","Oasis Egg","Dinosaur Egg","Primal Egg","Zen Egg","Gourmet Egg"},
}

-- Remote refs into M78 (1 local for table access scope)
do
    local ge = RS:FindFirstChild("GameEvents")
    if ge then
        M78.buySeedRE = ge:FindFirstChild("BuySeedStock")
        M78.buyGearRE = ge:FindFirstChild("BuyGearStock")
        M78.buyEggRE = ge:FindFirstChild("BuyPetEgg") or ge:FindFirstChild("BuyEgg") or ge:FindFirstChild("BuyEggStock")
        M78.feedRE = ge:FindFirstChild("ActivePetService")
    end
    dbg("[misc78] remotes seed="..(M78.buySeedRE and "OK" or "MISS").." gear="..(M78.buyGearRE and "OK" or "MISS").." egg="..(M78.buyEggRE and "OK" or "MISS").." feed="..(M78.feedRE and "OK" or "MISS"))
end

-- ---- Helpers (assigned to M78 to avoid creating new locals) ----
M78.isFruit = function(t)
    if not t:IsA("Tool") then return false end
    if t:FindFirstChild("PetToolLocal") or t:FindFirstChild("PetToolServer") then return false end
    local n = t.Name
    local gearKW = {"Shovel","Sprinkler","Watering","Trowel","Wrench","Spray","Mirror","Magnifying","Tool","Pot","Ticket","Rod","Staff","Lollipop","Caller","Crate","Basket","Rake"}
    for _, kw in ipairs(gearKW) do
        if n:find(kw, 1, true) then return false end
    end
    return n:match("%[[%d%.]+%s*[Kk][Gg]%]") ~= nil
end

M78.isFav = function(t)
    for _, attr in ipairs({"Favorited","IsFavorite","Favorite","Loved","IsLoved"}) do
        local fav = false
        pcall(function() fav = t:GetAttribute(attr) == true end)
        if fav then return true end
    end
    return false
end

M78.isFood = function(t)
    return M78.isFruit(t) and not M78.isFav(t)
end

M78.countBp = function()
    local bp = player:FindFirstChild("Backpack")
    if not bp then return 0, 0 end
    local fruits, total = 0, 0
    for _, item in ipairs(bp:GetChildren()) do
        total = total + 1
        if M78.isFruit(item) then fruits = fruits + 1 end
    end
    return fruits, total
end

M78.getPlacedPets = function()
    local pets = {}
    local pg = player:FindFirstChild("PlayerGui")
    local apui = pg and pg:FindFirstChild("ActivePetUI")
    if not apui then return pets end
    for _, frame in ipairs(apui:GetDescendants()) do
        local n = frame.Name or ""
        local clean = n:gsub("[{}]", "")
        if #clean >= 32 and clean:find("-") and not pets[clean] then
            local hasAge = false
            pcall(function()
                if frame:FindFirstChild("PET_AGE", true) then hasAge = true end
            end)
            if hasAge then
                local hunger, maxHunger
                for _, dd in ipairs(frame:GetDescendants()) do
                    if dd:IsA("TextLabel") then
                        local t = dd.Text or ""
                        local cur, mx = t:match("([%d%.]+)%s*/%s*([%d%.]+)%s*HGR")
                        if cur and mx then
                            hunger = tonumber(cur)
                            maxHunger = tonumber(mx)
                            break
                        end
                    end
                end
                pets[clean] = { hunger = hunger, maxHunger = maxHunger }
            end
        end
    end
    return pets
end

M78.pickFood = function()
    local char = player.Character
    if not char then return nil end
    for _, item in ipairs(char:GetChildren()) do
        if M78.isFood(item) then return item end
    end
    local hum = char:FindFirstChildOfClass("Humanoid")
    if not hum then return nil end
    local bp = player:FindFirstChild("Backpack")
    if not bp then return nil end
    local foods = {}
    for _, item in ipairs(bp:GetChildren()) do
        if M78.isFood(item) then
            local kg = tonumber(item.Name:match("%[([%d%.]+)%s*[Kk][Gg]%]")) or 0
            table.insert(foods, { tool = item, kg = kg })
        end
    end
    if #foods == 0 then return nil end
    table.sort(foods, function(a, b) return a.kg < b.kg end)
    pcall(function() hum:EquipTool(foods[1].tool) end)
    task.wait(0.1)
    for _, item in ipairs(char:GetChildren()) do
        if item == foods[1].tool then return item end
    end
    return nil
end

M78.setStatus = function(text, color)
    if M78.statusLbl then
        M78.statusLbl.Text = text
        M78.statusLbl.TextColor3 = color or C.Teal
    end
end

-- ---- UI Build ----
do
    local miscHdr = mk("Frame",{Size=UDim2.new(1,-10,0,30),Position=UDim2.new(0,5,0,4),BackgroundColor3=C.Panel,BorderSizePixel=0,Parent=miscGroup})
    corner(miscHdr, 7) stroke(miscHdr, C.Teal, 1.3)
    local hl = lbl(miscHdr, "MISC AUTO TASKS", 14, C.Teal, Enum.TextXAlignment.Center)
    hl.Size = UDim2.new(1,0,1,0)
    hl.Font = Enum.Font.GothamBold

    local miscScroll = mk("ScrollingFrame",{
        Size=UDim2.new(1,-10,1,-72),Position=UDim2.new(0,5,0,38),
        BackgroundTransparency=1,ScrollBarThickness=4,ScrollBarImageColor3=C.Teal,
        CanvasSize=UDim2.new(0,0,0,0),AutomaticCanvasSize=Enum.AutomaticSize.Y,
        Parent=miscGroup
    })
    mk("UIListLayout",{SortOrder=Enum.SortOrder.LayoutOrder,Padding=UDim.new(0,5),Parent=miscScroll})
    mk("UIPadding",{PaddingTop=UDim.new(0,4),PaddingLeft=UDim.new(0,3),PaddingRight=UDim.new(0,3),Parent=miscScroll})

    local function miscTogRow(labelTxt, descTxt, lo, key)
        local row = mk("Frame",{Size=UDim2.new(1,0,0,42), BackgroundColor3=C.Card, BorderSizePixel=0, LayoutOrder=lo, Parent=miscScroll})
        corner(row, 7)
        local rowStroke = stroke(row, C.Dim, 1.2)
        local l = lbl(row, labelTxt, 14, C.White)
        l.Size = UDim2.new(0.65,0,0,18) l.Position = UDim2.new(0,12,0,5)
        l.Font = Enum.Font.GothamBold
        if descTxt then
            local dl = lbl(row, descTxt, 12, C.Gray)
            dl.Size = UDim2.new(0.75,0,0,14) dl.Position = UDim2.new(0,12,0,23)
        end
        local tog = btn(row, "OFF", 13, C.Panel, C.Gray)
        tog.Size = UDim2.new(0,56,0,26) tog.Position = UDim2.new(1,-66,0.5,-13)
        tog.Font = Enum.Font.GothamBold
        local togStroke = stroke(tog, C.Dim, 1.2)
        local function refresh()
            local on = M78[key]
            tog.Text = on and "ON" or "OFF"
            tog.BackgroundColor3 = on and C.TDim or C.Panel
            tog.TextColor3 = on and C.Teal or C.Gray
            togStroke.Color = on and C.Teal or C.Dim
            rowStroke.Color = on and C.Teal or C.Dim
        end
        refresh()
        tog.MouseButton1Click:Connect(function()
            M78[key] = not M78[key]
            d[key] = M78[key]
            save()
            refresh()
        end)
        return row
    end

    miscTogRow("Auto Buy Egg", "Beli egg otomatis di toko", 1, "autoBuyEgg")
    miscTogRow("Auto Buy Seed", "Beli seed otomatis di Sam", 2, "autoBuySeed")
    miscTogRow("Auto Buy Gear", "Beli gear (sprinkler, water can, dll)", 3, "autoBuyGear")
    miscTogRow("Auto Feed Pet", "Feed pet kalo hunger di bawah threshold", 4, "autoFeedPet")

    local thRow = mk("Frame",{Size=UDim2.new(1,0,0,32),BackgroundColor3=C.Card,BorderSizePixel=0,LayoutOrder=5,Parent=miscScroll})
    corner(thRow,6) stroke(thRow,C.Dim,1.1)
    lbl(thRow,"Feed Cycle (menit) - aktif 20s tiap N menit",11,C.Gray).Size=UDim2.new(0.7,0,1,0)
    local thBox=mk("TextBox",{Size=UDim2.new(0,50,0,22),Position=UDim2.new(1,-58,0.5,-11),BackgroundColor3=C.Panel,Text=tostring(M78.feedCycleMin),TextColor3=C.White,Font=Enum.Font.GothamBold,TextSize=14,TextScaled=false,TextXAlignment=Enum.TextXAlignment.Center,ClearTextOnFocus=false,Parent=thRow})
    corner(thBox,5) stroke(thBox,C.Dim,1)
    thBox:GetPropertyChangedSignal("Text"):Connect(function()
        local v = tonumber(thBox.Text)
        if v then
            M78.feedCycleMin = math.max(1, math.min(120, v))
            d.feedCycleMin = M78.feedCycleMin
            -- Reset cycle: kalo lagi idle, restart timer dgn nilai baru
            if M78.feedMode == "idle" then M78.feedNextStartAt = 0 end
            save()
        end
    end)

    miscTogRow("Auto Collect Fruit", "Panen semua buah di kebun (auto-pause kalo bp full)", 6, "autoCollect")

    M78.statusLbl = lbl(miscGroup, "Misc: idle", 13, C.Gray, Enum.TextXAlignment.Center)
    M78.statusLbl.Size = UDim2.new(1,-10,0,26)
    M78.statusLbl.Position = UDim2.new(0,5,1,-30)
    M78.statusLbl.BackgroundColor3 = C.Panel
    M78.statusLbl.BackgroundTransparency = 0
    M78.statusLbl.Font = Enum.Font.GothamBold
    corner(M78.statusLbl, 6) stroke(M78.statusLbl, C.Dim, 1.1)
end

-- ---- Loops ----
-- Buy Seed
task.spawn(function()
    while not scriptShutdown do
        if M78.autoBuySeed and M78.buySeedRE then
            for _, name in ipairs(M78.SEEDS) do
                pcall(function() M78.buySeedRE:FireServer("Shop", name) end)
                M78.buySeedFired = M78.buySeedFired + 1
            end
            M78.setStatus("Buy seed: total "..M78.buySeedFired, C.Teal)
        end
        task.wait(M78.miscBuyInterval)
    end
end)

-- Buy Gear
task.spawn(function()
    while not scriptShutdown do
        if M78.autoBuyGear and M78.buyGearRE then
            for _, name in ipairs(M78.GEARS) do
                pcall(function() M78.buyGearRE:FireServer(name) end)
                M78.buyGearFired = M78.buyGearFired + 1
            end
            M78.setStatus("Buy gear: total "..M78.buyGearFired, C.Teal)
        end
        task.wait(M78.miscBuyInterval)
    end
end)

-- Buy Egg
task.spawn(function()
    while not scriptShutdown do
        if M78.autoBuyEgg and M78.buyEggRE then
            for _, name in ipairs(M78.EGGS) do
                local ok = pcall(function() M78.buyEggRE:FireServer(name) end)
                if not ok then pcall(function() M78.buyEggRE:FireServer("Shop", name) end) end
                M78.buyEggFired = M78.buyEggFired + 1
            end
            M78.setStatus("Buy egg: total "..M78.buyEggFired, C.Teal)
        end
        task.wait(M78.miscBuyInterval)
    end
end)

-- Feed loop
-- v12.79: Cycle-based feed - tiap feedCycleMin menit, aktif feedDuration detik, feed semua pet
M78.feedAllPets = function()
    if not M78.feedRE then return 0 end
    local pets = M78.getPlacedPets()
    local count = 0
    for uuid, _ in pairs(pets) do
        local food = M78.pickFood()
        if not food then
            M78.lastFood = "NO FOOD"
            break
        end
        M78.lastFood = food.Name:sub(1, 18)
        pcall(function() M78.feedRE:FireServer("Feed", "{"..uuid.."}") end)
        count = count + 1
        M78.feedTotalFed = M78.feedTotalFed + 1
        task.wait(0.05)
    end
    M78.feedTotalPets = count
    return count
end

task.spawn(function()
    while not scriptShutdown do
        if M78.autoFeedPet then
            local now = tick()
            if M78.feedMode == "idle" then
                -- Kalo feedNextStartAt belum di-set atau udah lewat, mulai cycle
                if M78.feedNextStartAt <= 0 or now >= M78.feedNextStartAt then
                    M78.feedMode = "feeding"
                    M78.feedEndAt = now + M78.feedDuration
                    M78.setStatus("Feed: cycle MULAI ("..M78.feedDuration.."s)", C.Teal)
                else
                    -- Display countdown ke next cycle
                    local secLeft = math.ceil(M78.feedNextStartAt - now)
                    local mins = math.floor(secLeft / 60)
                    local secs = secLeft % 60
                    M78.setStatus(string.format("Feed: idle, next %02d:%02d (total fed:%d)", mins, secs, M78.feedTotalFed), C.Gray)
                end
            elseif M78.feedMode == "feeding" then
                if now >= M78.feedEndAt then
                    -- Cycle selesai
                    M78.feedMode = "idle"
                    M78.feedNextStartAt = now + (M78.feedCycleMin * 60)
                    M78.setStatus(string.format("Feed: SELESAI cycle. Next %dm (total fed:%d)", M78.feedCycleMin, M78.feedTotalFed), C.Green)
                else
                    -- Lagi dalam window 20s, feed semua pet
                    local fed = M78.feedAllPets()
                    local secLeft = math.ceil(M78.feedEndAt - now)
                    if fed > 0 then
                        M78.setStatus("Feed: "..fed.." pet ("..secLeft.."s left, food:"..M78.lastFood..")", C.Teal)
                    elseif M78.lastFood == "NO FOOD" then
                        M78.setStatus("Feed: NO FOOD di backpack ("..secLeft.."s left)", C.Gold)
                    else
                        M78.setStatus("Feed: 0 pet ditemukan ("..secLeft.."s left)", C.Gold)
                    end
                end
            end
        else
            -- Toggle off → reset cycle, ready to start when toggled on
            M78.feedMode = "idle"
            M78.feedNextStartAt = 0
        end
        task.wait(1)
    end
end)

-- Collect loop
M78.refreshPrompts = function()
    M78.promptsCache = {}
    pcall(function()
        for _, dd in ipairs(workspace:GetDescendants()) do
            if dd:IsA("ProximityPrompt") then
                local at = dd.ActionText or ""
                if M78.collectMatch == "" or at:find(M78.collectMatch, 1, true) then
                    table.insert(M78.promptsCache, dd)
                end
            end
        end
    end)
    M78.promptsCacheT = tick()
end

-- v12.79: Cycle-based collect - tiap collectCycleMin menit, aktif collectDuration detik
task.spawn(function()
    while not scriptShutdown do
        if M78.autoCollect then
            local now = tick()
            if M78.collectMode == "idle" then
                if M78.collectNextStartAt <= 0 or now >= M78.collectNextStartAt then
                    M78.collectMode = "collecting"
                    M78.collectEndAt = now + M78.collectDuration
                    -- Force refresh prompts pas mulai cycle baru
                    M78.promptsCacheT = 0
                    M78.setStatus("Collect: cycle MULAI ("..M78.collectDuration.."s)", C.Teal)
                else
                    local secLeft = math.ceil(M78.collectNextStartAt - now)
                    local mins = math.floor(secLeft / 60)
                    local secs = secLeft % 60
                    M78.setStatus(string.format("Collect: idle, next %02d:%02d (total:%d)", mins, secs, M78.collectTotalFired), C.Gray)
                end
            elseif M78.collectMode == "collecting" then
                if now >= M78.collectEndAt then
                    M78.collectMode = "idle"
                    M78.collectNextStartAt = now + (M78.collectCycleMin * 60)
                    M78.setStatus(string.format("Collect: SELESAI cycle. Next %dm (total:%d)", M78.collectCycleMin, M78.collectTotalFired), C.Green)
                else
                    -- Lagi dalam window, sweep prompts
                    local fruitsBefore = M78.countBp()
                    if (tick() - M78.promptsCacheT) > 3 then M78.refreshPrompts() end
                    local fired = 0
                    for _, dd in ipairs(M78.promptsCache) do
                        if dd.Parent then
                            if not M78.promptsConfigured[dd] then
                                pcall(function()
                                    dd.MaxActivationDistance = 1000
                                    dd.HoldDuration = 0
                                end)
                                M78.promptsConfigured[dd] = true
                            end
                            pcall(function()
                                if fireproximityprompt then fireproximityprompt(dd)
                                else dd:InputHoldBegin() dd:InputHoldEnd() end
                            end)
                            fired = fired + 1
                        end
                    end
                    M78.lastPromptCount = fired

                    task.wait(0.15)
                    local fruitsAfter = M78.countBp()
                    local gained = math.max(0, fruitsAfter - fruitsBefore)
                    M78.collectTotalFired = M78.collectTotalFired + gained
                    local secLeft = math.ceil(M78.collectEndAt - now)
                    if gained > 0 then
                        M78.setStatus("Collect: +"..gained.." ("..secLeft.."s left, total:"..M78.collectTotalFired..", bp:"..fruitsAfter..")", C.Green)
                    else
                        M78.setStatus("Collect: 0 gained ("..secLeft.."s left, fired:"..fired..")", C.Gray)
                    end
                end
            end
        else
            M78.collectMode = "idle"
            M78.collectNextStartAt = 0
        end
        task.wait(1)
    end
end)

-- ============================================
-- END v12.78b MISC SECTION (1 main local: M78)
-- ============================================

end)()  -- end v12.78 misc IIFE

-- Gift: GiftPet (uuid, name, sender) -> AcceptPetGift(true, uuid) (CONFIRMED v12.10)
-- Trade: SendRequest (tradeID, sender, ts) -> RespondRequest(tradeID, true) (CONFIRMED v12.10)
-- ============================================
pcall(function()
    -- v12.10: PRECISE gift accept (path: GameEvents.GiftPet, GameEvents.AcceptPetGift)
    local ge = RS:FindFirstChild("GameEvents")
    if not ge then dbg("[autoAcc] FATAL no GameEvents") return end

    local giftPetRE = ge:FindFirstChild("GiftPet")
    local acceptPetGiftRE = ge:FindFirstChild("AcceptPetGift")

    if giftPetRE and giftPetRE:IsA("RemoteEvent") and acceptPetGiftRE and acceptPetGiftRE:IsA("RemoteEvent") then
        local giftAccCount = 0
        local conn = giftPetRE.OnClientEvent:Connect(function(petUUID, petName, senderUsername)
            if not autoAccGift then return end
            local short = tostring(petUUID):sub(1,8)

            -- v12.14: FAST gift accept - INSTANT fire (sebelum proses lainnya)
            -- Plus task.spawn biar handler langsung return, gak block event berikutnya
            -- Plus retry 2x dengan jarak kecil buat handle packet drop
            pcall(function() acceptPetGiftRE:FireServer(true, petUUID) end)  -- fire #1 INSTANT
            task.spawn(function()
                task.wait(0.05)
                pcall(function() acceptPetGiftRE:FireServer(true, petUUID) end)  -- fire #2 backup
            end)

            -- Update counter + status (non-blocking)
            task.spawn(function()
                giftAccCount = giftAccCount + 1
                dbg("[autoAcc-gift] FAST #"..giftAccCount.." "..short.." from "..tostring(senderUsername))
                if accStatusLbl then
                    accStatusLbl.Text = "Gift accept #"..giftAccCount.." ("..tostring(senderUsername)..")"
                    accStatusLbl.TextColor3 = C.Teal
                    local myCount = giftAccCount
                    task.delay(1.5, function()  -- v12.14: 2.5s -> 1.5s (lebih snappy)
                        if accStatusLbl and giftAccCount == myCount then
                            accStatusLbl.Text="Accept: idle" accStatusLbl.TextColor3=C.Gray
                        end
                    end)
                end
            end)
        end)
        table.insert(connections, conn)
        dbg("[autoAcc] gift hook FAST installed (instant fire + 50ms retry)")
    else
        dbg("[autoAcc] WARN: GiftPet/AcceptPetGift gak ketemu (path: GameEvents direct)")
    end

    -- v12.10: PRECISE trade accept (multi-stage with tradeID)
    -- Stage 1: SendRequest(tradeID, sender, ts) -> RespondRequest(tradeID, true)
    -- Stage 2/3: UpdateTradeState -> try Accept(tradeID), Confirm(tradeID)
    local te = ge:FindFirstChild("TradeEvents")
    if te then
        local sendReqRE = te:FindFirstChild("SendRequest")
        local respondReqRE = te:FindFirstChild("RespondRequest")
        local acceptRE = te:FindFirstChild("Accept")
        local confirmRE = te:FindFirstChild("Confirm")

        local lastTradeID = nil
        local tradeAccCount = 0
        local spamRunning = false

        -- v12.11: Auto-confirm spammer (jalan tiap 3 detik selama trade window visible)
        -- Pakai firesignal Activated (signal yg game pakai - 2 connections) + brute force remote
        local function findTradeAcceptBtn()
            local pg = player:FindFirstChild("PlayerGui")
            local tui = pg and pg:FindFirstChild("TradingUI")
            local lt = tui and tui:FindFirstChild("LiveTrade")
            if not lt or not lt.Visible then return nil, nil end
            local opts = lt:FindFirstChild("Options")
            local acc = opts and opts:FindFirstChild("Accept")
            return acc, lt
        end

        local function spamConfirm()
            local btn, lt = findTradeAcceptBtn()
            if not btn then return false end

            -- Fire Activated signal (yg game pakai)
            if firesignal then
                pcall(function() firesignal(btn.Activated) end)
            end
            if getconnections then
                pcall(function()
                    for _, c in ipairs(getconnections(btn.Activated)) do
                        pcall(function() c:Fire() end)
                    end
                end)
            end

            -- Brute force fire remote (kalo Activated gak cukup, ini backup)
            if lastTradeID then
                if confirmRE then pcall(function() confirmRE:FireServer(lastTradeID) end) end
                if acceptRE then pcall(function() acceptRE:FireServer(lastTradeID) end) end
            end
            return true
        end

        local function startSpammer()
            if spamRunning then return end
            spamRunning = true
            task.spawn(function()
                local iter = 0
                while autoAccTrade and spamRunning do
                    iter = iter + 1
                    local stillTrade = spamConfirm()
                    if not stillTrade then
                        -- Trade window closed, stop spamming
                        if iter > 1 then dbg("[autoAcc-trade] spammer stop (window closed)") end
                        break
                    end
                    if iter == 1 then
                        dbg("[autoAcc-trade] spammer started")
                        if accStatusLbl then
                            accStatusLbl.Text = "Trade auto-confirm spam"
                            accStatusLbl.TextColor3 = C.Teal
                        end
                    end
                    task.wait(3)
                end
                spamRunning = false
            end)
        end

        for _, r in ipairs(te:GetChildren()) do
            if r:IsA("RemoteEvent") then
                local lname = r.Name:lower()
                if not (lname:find("history") or lname:find("inventory")) then
                    local conn = r.OnClientEvent:Connect(function(...)
                        if not autoAccTrade then return end
                        local args = {...}

                        -- Extract tradeID dari arg[1]
                        if type(args[1]) == "string" and #args[1] > 20 and args[1]:find("-") then
                            lastTradeID = args[1]
                        end

                        if lname:find("cancel") or lname:find("reject") or lname:find("decline") then
                            spamRunning = false  -- stop spam kalo trade dibatalin
                            return
                        end

                        -- Stage 1: SendRequest -> RespondRequest(tradeID, true)
                        if r == sendReqRE and respondReqRE and lastTradeID then
                            local ok = pcall(function() respondReqRE:FireServer(lastTradeID, true) end)
                            if ok then
                                tradeAccCount = tradeAccCount + 1
                                dbg("[autoAcc-trade] RespondRequest("..lastTradeID:sub(1,8)..", true)")
                                if accStatusLbl then
                                    accStatusLbl.Text = "Trade accept #"..tradeAccCount
                                    accStatusLbl.TextColor3 = C.Teal
                                end
                                -- Start spammer (akan auto-stop kalo window close)
                                task.delay(2, startSpammer)
                            end
                            return
                        end

                        -- Other trade events: trigger spammer kalo blm jalan
                        if r.Name == "UpdateTradeState" then
                            startSpammer()
                        end
                    end)
                    table.insert(connections, conn)
                end
            end
        end
        dbg("[autoAcc] trade hook PRECISE installed (Activated firesignal + 3s spam)")
    else
        dbg("[autoAcc] WARN: TradeEvents folder gak ketemu")
    end
end)

-- ============================================
-- LOGIC UTAMA
-- ============================================
local function setRunning(state)
    if state then
        runBtn.BackgroundColor3=Color3.fromRGB(30,30,30) runBtn.TextColor3=C.Teal runStroke.Color=C.Teal
        stopBtn.BackgroundColor3=C.Panel stopBtn.TextColor3=C.Gray stopStroke.Color=C.Dim
    else
        runBtn.BackgroundColor3=C.Panel runBtn.TextColor3=C.Gray runStroke.Color=C.Dim
        stopBtn.BackgroundColor3=Color3.fromRGB(30,30,30) stopBtn.TextColor3=C.White stopStroke.Color=C.Dim
    end
end

local function isPetInSwap(uuid)
    local ps=swapPerPet[uuid]
    return ps~=nil and ps.enabled==true
end

local function isPetEquippedInUI(uuid)
    local pg=player:FindFirstChild("PlayerGui") if not pg then return false end
    local activePetUI=pg:FindFirstChild("ActivePetUI") if not activePetUI then return false end
    local uuidStr=tostring(uuid):gsub("^{",""):gsub("}$","")
    if #uuidStr<10 then return false end
    for _,d in ipairs(activePetUI:GetDescendants()) do
        if d.Name=="PET_AGE" and d:IsA("TextLabel") then
            local p=d.Parent
            local depth=0
            while p and depth<10 do
                local pn=p.Name:gsub("^{",""):gsub("}$","")
                if pn==uuidStr then return true end
                p=p.Parent
                depth=depth+1
            end
        end
    end
    return false
end

local function getFavoriteUUIDs()
    local favs={}
    local bp=player:FindFirstChild("Backpack")
    if not bp then return favs end
    for _,item in pairs(bp:GetChildren()) do
        if isPet(item) and isFavorite(item) then
            local uuid=getPetUUID(item)
            if uuid then
                local uuidStr=tostring(uuid)
                if not teamPetUUIDs[uuidStr] then
                    favs[uuidStr]=true
                end
            end
        end
    end
    return favs
end

local function equipTeam()
    for uuid,_ in pairs(teamPetUUIDs) do
        if not isPetInSwap(uuid) then
            if not isPetEquippedInUI(uuid) then
                equipPet(uuid)
                task.wait(0.1)
            end
        end
    end
end

local function unequipTeam()
    for uuid,_ in pairs(teamPetUUIDs) do
        unequipPet(uuid) task.wait(0.1)
    end
end

-- ============================================
-- TEAM KEEPER
-- ============================================
local teamKeeperTask=nil

teamKeeperShouldRun=function()
    for _ in pairs(teamPetUUIDs) do return true end
    return false
end

startTeamKeeper=function()
    if teamKeeperTask then return end
    if not teamKeeperShouldRun() then return end
    teamKeeperTask=task.spawn(function()
        dbg("[teamKeeper] START (handle TIM only via ActivePetUI)")
        while teamKeeperShouldRun() do
            for uuid,_ in pairs(teamPetUUIDs) do
                if not isPetInSwap(uuid) and not currentLevelingUUIDs[uuid] then
                    if not isPetEquippedInUI(uuid) then
                        local uuidStr=tostring(uuid)
                        dbg("[teamKeeper] tim "..uuidStr:sub(1,8).." gak di UI, re-equip")
                        equipPet(uuid)
                        task.wait(0.1)
                    end
                end
            end
            task.wait(0.5)
        end
        dbg("[teamKeeper] STOP (gak ada team)")
        teamKeeperTask=nil
    end)
end

-- v10.4: swap keeper - re-equip swap pet yg ke-pickup manual (gak perlu START)
local swapKeeperTask=nil
local function swapKeeperShouldRun()
    for _,cfg in pairs(swapPerPet) do
        if cfg.enabled then return true end
    end
    return false
end
local function startSwapKeeper()
    if swapKeeperTask then return end
    if not swapKeeperShouldRun() then return end
    swapKeeperTask=task.spawn(function()
        dbg("[swapKeeper] START (re-equip swap pet yg ke-pickup)")
        while swapKeeperShouldRun() do
            for uuid,cfg in pairs(swapPerPet) do
                if cfg.enabled and not currentLevelingUUIDs[uuid] then
                    if not isPetEquippedInUI(uuid) then
                        local uuidStr=tostring(uuid)
                        dbg("[swapKeeper] swap "..uuidStr:sub(1,8).." gak di UI, re-equip")
                        pcall(function() equipPet(uuid) end)
                        task.wait(0.1)
                    end
                end
            end
            task.wait(0.5)
        end
        dbg("[swapKeeper] STOP")
        swapKeeperTask=nil
    end)
end

stopTeamKeeper=function()
    if teamKeeperTask then
        pcall(task.cancel,teamKeeperTask)
        teamKeeperTask=nil
        dbg("[teamKeeper] STOP (manual)")
    end
end

_G.ZenxStartTeamKeeper=startTeamKeeper
_G.ZenxStopTeamKeeper=stopTeamKeeper

-- ============================================
-- GLOBAL POLLER (FRIEND-7)
-- ============================================
local function pollerShouldRun()
    for _,cfg in pairs(swapPerPet) do
        if cfg.enabled then return true end
    end
    return false
end

-- v10.6: adaptive parallel - sleep proportional ke cooldown remaining
-- Jadi pet yg cooldown masih lama (5s) gak invoke server tiap 25ms; cuma rapid polling pas mendekati 0
local checkingPet = {}
local nextCheckAt = {}  -- per-uuid: tick() kapan boleh check lagi

startGlobalPoller=function()
    if pollerTask then return end
    if not pollerShouldRun() then return end
    pollerTask=task.spawn(function()
        dbg("[poller] global poller START (adaptive parallel)")
        local cycles=0
        while pollerShouldRun() do
            cycles=cycles+1
            local now = tick()
            for uuid,cfg in pairs(swapPerPet) do
                if cfg.enabled and not currentLevelingUUIDs[uuid] and not checkingPet[uuid] then
                    -- Skip kalo belum waktunya check (adaptive)
                    if not nextCheckAt[uuid] or now >= nextCheckAt[uuid] then
                        checkingPet[uuid] = true
                        task.spawn(function()
                            local t = getPetTime(uuid)
                            if t == nil then
                                -- Pet belum di-track (mungkin baru di-equip); cek lagi 0.3s
                                nextCheckAt[uuid] = tick() + 0.3
                            elseif t <= 0 then
                                local last = lastSwap[uuid] or 0
                                if tick() - last >= 0.25 then
                                    local info = swapPetInfoCache[uuid] or teamPetInfoCache[uuid]
                                    local nm = (info and info.name) or "?"
                                    if cycles <= 20 then
                                        dbg(string.format("[swap] %s Time=%.1f -> SWAP", nm:sub(1,12), t))
                                    end
                                    swapPet(uuid)
                                    lastSwap[uuid] = tick()
                                end
                                nextCheckAt[uuid] = tick() + 0.05
                            elseif t > 2 then
                                -- v12.15: max sleep 4 -> 2 detik (lebih responsive)
                                nextCheckAt[uuid] = tick() + math.min(t * 0.6, 2)
                            elseif t > 0.5 then
                                -- Mendekati - polling 100ms
                                nextCheckAt[uuid] = tick() + 0.1
                            else
                                -- Hampir 0 - rapid polling 30ms biar miss ke-deteksi cepet
                                nextCheckAt[uuid] = tick() + 0.03
                            end
                            checkingPet[uuid] = nil
                        end)
                    end
                end
            end
            if cycles%500==0 then
                local active,ready,idle,skipped=0,0,0,0
                for uuid,cfg in pairs(swapPerPet) do
                    if cfg.enabled then
                        if currentLevelingUUIDs[uuid] then skipped=skipped+1
                        else
                            local t=getPetTime(uuid)
                            if t==nil then idle=idle+1
                            elseif t<=0 then ready=ready+1
                            else active=active+1 end
                        end
                    end
                end
                dbg(string.format("[alive] cycle=%d active=%d ready=%d idle=%d skip=%d",cycles,active,ready,idle,skipped))
            end
            task.wait(0.015) -- main loop 15ms (cuma dispatch, kerjaan berat di task.spawn)
        end
        pollerTask=nil
        checkingPet={}
        nextCheckAt={}
        dbg("[poller] global poller STOP")
    end)
end

local function stopAllSwaps()
    if pollerTask then
        pcall(task.cancel,pollerTask)
        pollerTask=nil
    end
    lastSwap={}
    checkingPet={}
    nextCheckAt={}
end

local function startSwapForPet(uuid)
    startGlobalPoller()
end

local function stopSwapForPet(uuid)
    lastSwap[uuid]=nil
end

_G.ZenxStartSwap=startSwapForPet
_G.ZenxStopSwap=stopSwapForPet

local function getQueue()
    local queue={}
    local bp=player:FindFirstChild("Backpack") if not bp then return queue end
    for _,item in pairs(bp:GetChildren()) do
        if isPet(item) then
            local uuid=getPetUUID(item)
            local uuidStr=uuid and tostring(uuid) or ""
            if uuid and not teamPetUUIDs[uuidStr] then
                if not currentLevelingUUIDs[uuidStr] and not completedPets[uuidStr] and not isFavorite(item) then
                    local name=getPetName(item)
                    if isTargetPet(name) then
                        local age=getAgeFromKG(item)
                        if age==nil or (age>=fromAge and age<toAge) then
                            table.insert(queue,item)
                        end
                    end
                end
            end
        end
    end
    return queue
end

local function doStop(reason)
    isRunning=false
    if mainTask then task.cancel(mainTask) mainTask=nil end
    if monitorTask then task.cancel(monitorTask) monitorTask=nil end
    statusLbl.Text="Unequip..." statusLbl.TextColor3=C.Gray
    for uuid,_ in pairs(currentLevelingUUIDs) do
        if not (swapPerPet[uuid] and swapPerPet[uuid].enabled) then
            pcall(function() unequipPet(uuid) end)
        end
        task.wait(0.05)
    end
    currentLevelingUUIDs={}
    for uuid,_ in pairs(teamPetUUIDs) do
        if not (swapPerPet[uuid] and swapPerPet[uuid].enabled) then
            unequipPet(uuid)
            task.wait(0.1)
        end
    end
    setRunning(false)
    statusLbl.Text=reason or "Dihentikan" statusLbl.TextColor3=C.Gray
    buildTargetList()
end

local function pickupAllGardenPets()
    local petsPhys=workspace:FindFirstChild("PetsPhysical")
    if not petsPhys then
        dbg("[pickup] PetsPhysical gak ada di workspace")
        return 0
    end

    -- v12.79 OPTIMIZED: collect all UUIDs first (no firing), then rapid-fire batch
    local uuids={}
    local seen={}
    local function extractUUID(model)
        if not model or not model:IsA("Model") then return end
        local modelName=model.Name
        local uuidNoBrace=nil
        local attrUuid=nil
        pcall(function() attrUuid=model:GetAttribute("PET_UUID") end)
        if attrUuid then
            uuidNoBrace=tostring(attrUuid):gsub("^{",""):gsub("}$","")
        elseif modelName:sub(1,1)=="{" and modelName:sub(-1)=="}" then
            uuidNoBrace=modelName:sub(2,-2)
        elseif #modelName>=30 and modelName:match("^[%w%-]+$") then
            uuidNoBrace=modelName
        end
        if uuidNoBrace and #uuidNoBrace>=20 and not seen[uuidNoBrace] then
            seen[uuidNoBrace]=true
            table.insert(uuids,uuidNoBrace)
        end
    end

    -- Scan: PetsPhysical udah includes PetMover descendants (gak perlu loop terpisah)
    for _,m in ipairs(petsPhys:GetDescendants()) do extractUUID(m) end
    -- Fallback containers (jaga-jaga kalo struktur game berubah)
    for _,n in ipairs({"Pets","PlacedPets","ActivePets"}) do
        local f=workspace:FindFirstChild(n)
        if f then for _,m in ipairs(f:GetDescendants()) do extractUUID(m) end end
    end

    -- Rapid fire: unequip semua tanpa wait per-pet
    for _,uuid in ipairs(uuids) do
        pcall(function() unequipPet(uuid) end)
    end

    -- Single wait for server processing - tightened for speed (was 0.15+0.01N cap 0.5)
    if #uuids>0 then
        task.wait(math.min(0.25, 0.08+#uuids*0.005))
    end

    dbg("[pickup] total: "..#uuids.." pet di-pickup dari garden (rapid-fire)")
    return #uuids
end

local function doStart()
    dbg("[doStart] dipanggil")
    currentLevelingUUIDs={}
    completedPets={}
    if isRunning then dbg("[doStart] sudah running, skip") return end
    if next(teamPetUUIDs)==nil then dbg("[doStart] FAIL: pilih tim dulu") statusLbl.Text="Pilih tim leveling dulu!" statusLbl.TextColor3=C.Red return end
    buildMaxKGCache()

    statusLbl.Text="Membersihkan garden..." statusLbl.TextColor3=C.Gold
    local totalRemoved=0
    -- v12.79: 3 attempts -> 2, inter-wait 0.2 -> 0.1
    for attempt=1,2 do
        local removed=pickupAllGardenPets()
        totalRemoved=totalRemoved+removed
        if removed>0 then
            dbg("[doStart] pickup attempt "..attempt..": "..removed.." pet")
            task.wait(0.1)
        else
            if attempt>1 then dbg("[doStart] garden bersih setelah "..(attempt-1).." attempt") end
            break
        end
    end
    if totalRemoved>0 then
        dbg("[doStart] TOTAL pickup: "..totalRemoved.." pet")
    else
        dbg("[doStart] garden udah kosong, gak ada yg di-pickup")
    end

    statusLbl.Text="Pasang tim leveling..." statusLbl.TextColor3=C.Gold
    local teamPlaced=0
    for uuid,_ in pairs(teamPetUUIDs) do
        equipPet(uuid)
        teamPlaced=teamPlaced+1
        task.wait(0.02) -- v12.79: was 0.05
    end
    if teamPlaced>0 then
        dbg("[doStart] tim "..teamPlaced.." pet di-place")
        task.wait(0.15) -- v12.79: was 0.3
    end

    local queue=getQueue()
    -- v12.12: jangan bail out kalo queue kosong, tetep mulai dgn "wait" mode
    -- main loop akan handle empty queue (display "Tunggu pet target...")
    isRunning=true setRunning(true)
    if #queue==0 then
        dbg("[doStart] queue kosong, mulai dgn wait mode")
        statusLbl.Text="Mulai... tunggu pet target..." statusLbl.TextColor3=C.Gold
    else
        statusLbl.Text="Berjalan... Q:"..#queue statusLbl.TextColor3=C.Teal
    end

    local teamCnt=0
    for _ in pairs(teamPetUUIDs) do teamCnt=teamCnt+1 end
    local swapCnt=0
    for _,cfg in pairs(swapPerPet) do
        if cfg.enabled then swapCnt=swapCnt+1 end
    end
    dbg("[doStart] team="..teamCnt.." swap-enabled="..swapCnt)
    if swapCnt==0 then
        dbg("[doStart] NO swap pets")
    else
        startGlobalPoller()
    end

    mainTask=task.spawn(function()
        while isRunning do equipTeam() task.wait(1) end
    end)

    monitorTask=task.spawn(function()
        local equipTime={}
        local lastRecheck={}
        local SAFETY_TIMEOUT=10*60
        while isRunning do
            local doneList={}
            for uuid,_ in pairs(currentLevelingUUIDs) do
                if not equipTime[uuid] then equipTime[uuid]=tick() end
                local age=getAgeFromUI(uuid)
                local source=age and "ui" or nil
                local item=nil
                local placed=nil
                if not age then
                    item=findPetInBackpack(uuid)
                    placed=findPlacedPetByUUID(uuid)
                    if item then
                        age=getAgeFromKG(item)
                        if age then source="tool" end
                    end
                    if not age and placed then
                        age=getPlacedPetAge(placed)
                        if age then source="placed" end
                    end
                end
                if age and age>=toAge then
                    dbg("[monitor] "..uuid:sub(1,8).." age "..age..">="..toAge.." ("..source..") -> done")
                    completedPets[uuid]=true
                    table.insert(doneList,uuid)
                else
                    if not age then
                        if not item then item=findPetInBackpack(uuid) end
                        if not placed then placed=findPlacedPetByUUID(uuid) end
                        if (not item) and (not placed) then
                            dbg("[monitor] "..uuid:sub(1,8).." beneran ilang -> drop")
                            table.insert(doneList,uuid)
                        end
                    end
                    local elapsed=tick()-equipTime[uuid]
                    if elapsed > SAFETY_TIMEOUT then
                        dbg("[monitor] "..uuid:sub(1,8).." SAFETY TIMEOUT >10 menit, force drop")
                        table.insert(doneList,uuid)
                    end
                    if not age and elapsed > 60 then
                        local lastRC=lastRecheck[uuid] or 0
                        if (tick()-lastRC) > 60 then
                            dbg("[monitor] "..uuid:sub(1,8).." age unknown >60s, fallback recheck")
                            lastRecheck[uuid]=tick()
                            pcall(function() unequipPet(uuid) end)
                            task.wait(0.5)
                            local recheckItem=findPetInBackpack(uuid)
                            if recheckItem then
                                local newAge=getAgeFromKG(recheckItem)
                                if newAge and newAge>=toAge then
                                    dbg("[monitor] "..uuid:sub(1,8).." age "..newAge.." (recheck) -> done")
                                    completedPets[uuid]=true
                                    table.insert(doneList,uuid)
                                else
                                    pcall(function() equipPet(uuid) end)
                                end
                            else
                                pcall(function() equipPet(uuid) end)
                            end
                        end
                    end
                end
            end

            for _,uuid in ipairs(doneList) do
                pcall(function() unequipPet(uuid) end)
                currentLevelingUUIDs[uuid]=nil
                equipTime[uuid]=nil
                lastRecheck[uuid]=nil
                task.wait(0.03)
            end

            if #doneList>0 then
                dbg("[monitor] "..#doneList.." pet selesai, tunggu 0.05s")
                task.wait(0.05)
            end

            local slotsUsed=0
            for _ in pairs(currentLevelingUUIDs) do slotsUsed=slotsUsed+1 end
            local slotsFree=maxPetTarget-slotsUsed

            local queue2=getQueue()
            local available={}
            for _,pet in ipairs(queue2) do
                local uuid=getPetUUID(pet)
                if uuid and not currentLevelingUUIDs[tostring(uuid)] then
                    table.insert(available,pet)
                end
            end

            -- v12.15: jangan auto-stop, tetep waiting mode (gak doStop lagi)
            -- biar user trade pet baru, queue refresh otomatis level lagi
            if slotsUsed==0 and #available==0 then
                statusLbl.Text="Semua pet selesai Age "..toAge.."! (waiting...)"
                statusLbl.TextColor3=C.Green
                -- gak break, lanjut loop terus
            end

            if slotsFree>0 and #available>0 then
                local toEquip=math.min(slotsFree,#available)
                dbg("[monitor] EQUIP "..toEquip.." pet baru")
                for i=1,toEquip do
                    if not isRunning then break end
                    local uuid=getPetUUID(available[i])
                    if uuid then
                        local petName=getPetName(available[i])
                        dbg("[monitor]   -> equip "..petName.." uuid="..tostring(uuid):sub(1,8))
                        equipPet(uuid)
                        currentLevelingUUIDs[tostring(uuid)]=true
                    end
                end
            elseif #doneList>0 then
                dbg("[monitor] gak equip baru: slotFree="..slotsFree..", queue="..#available)
            end

            local activeNames={}
            for uuid,_ in pairs(currentLevelingUUIDs) do
                local nameStr=getPetNameFromUI(uuid)
                if not nameStr or nameStr=="" then nameStr=getPetTypeFromUI(uuid) end
                if not nameStr then
                    local item=findPetInBackpack(uuid)
                    if item then nameStr=getPetName(item) end
                end
                if not nameStr then
                    local cached=teamPetInfoCache[uuid] or swapPetInfoCache[uuid]
                    nameStr=(cached and cached.name) or uuid:sub(1,8)
                end
                local age=getAgeFromUI(uuid)
                if not age then
                    local item=findPetInBackpack(uuid)
                    if item then age=getAgeFromKG(item) end
                end
                if not age then
                    local placed=findPlacedPetByUUID(uuid)
                    if placed then age=getPlacedPetAge(placed) end
                end
                if not age then
                    -- v12.21: KG estimate dari item di Backpack ATAU Character
                    local item=findPetInBackpack(uuid)
                    if item then
                        local kg=getKG(item)
                        if kg then
                            -- Pakai cache maxKG kalo ada
                            local maxKG = getMaxKGForPet(getPetName(item))
                            if maxKG and maxKG > 0 then
                                age = math.max(1, math.min(100, math.floor(kg * 11 / maxKG - 10)))
                            elseif kg >= 20 then
                                age = 100
                            else
                                age = 1
                            end
                        end
                    end
                end
                if not age then
                    -- v12.21: last resort - get KG from placed model name (kalo nama-nya bukan UUID)
                    local placed=findPlacedPetByUUID(uuid)
                    if placed and placed.Name and not placed.Name:find("-") then
                        local kg = tonumber(placed.Name:match("%[([%d%.]+)%s*[Kk][Gg]%]"))
                        if kg and kg >= 20 then age = 100
                        elseif kg then age = 1 end
                    end
                end
                local ageStr=age and (age.."/"..toAge) or ("?/"..toAge)
                table.insert(activeNames,nameStr.." "..ageStr)
            end
            if #activeNames>0 then
                statusLbl.Text="Lvl: "..table.concat(activeNames,", ").." | Q:"..#available
            else
                statusLbl.Text="Tunggu pet target... Q:"..#available
            end
            statusLbl.TextColor3=C.Teal

            task.wait(0.15)  -- v12.15: 0.25 -> 0.15 (lebih snappy)
        end
    end)
end

runBtn.MouseButton1Click:Connect(function() doStart() end)
stopBtn.MouseButton1Click:Connect(function() doStop("Dihentikan") end)

closeBtn.MouseButton1Click:Connect(function()
    local overlay=mk("Frame",{Size=UDim2.new(1,0,1,0),BackgroundColor3=Color3.fromRGB(0,0,0),BackgroundTransparency=0.5,BorderSizePixel=0,ZIndex=10,Parent=main})
    local modal=mk("Frame",{Size=UDim2.new(0,300,0,140),Position=UDim2.new(0.5,-150,0.5,-70),BackgroundColor3=C.Panel,BorderSizePixel=0,ZIndex=11,Parent=overlay})
    corner(modal,10) stroke(modal,C.Red,2)
    local title=lbl(modal,"YAKIN MAU CLOSE?",13,C.Red,Enum.TextXAlignment.Center)
    title.Size=UDim2.new(1,0,0,28) title.Position=UDim2.new(0,0,0,10) title.ZIndex=11
    local msg=lbl(modal,"Semua aktivitas akan dihentikan & GUI ditutup.",10,C.Gray,Enum.TextXAlignment.Center)
    msg.Size=UDim2.new(1,-20,0,40) msg.Position=UDim2.new(0,10,0,40) msg.TextWrapped=true msg.ZIndex=11
    local yaBtn=btn(modal,"YA, CLOSE",12,C.RDim,C.Red)
    yaBtn.Size=UDim2.new(0,120,0,28) yaBtn.Position=UDim2.new(0.5,-130,1,-40) yaBtn.ZIndex=11 stroke(yaBtn,C.Red,1.5)
    local noBtn=btn(modal,"BATAL",12,C.Card,C.White)
    noBtn.Size=UDim2.new(0,120,0,28) noBtn.Position=UDim2.new(0.5,10,1,-40) noBtn.ZIndex=11 stroke(noBtn,C.Dim,1.5)
    noBtn.MouseButton1Click:Connect(function() overlay:Destroy() end)
    yaBtn.MouseButton1Click:Connect(function()
        -- v10.8: COMPLETE shutdown - kill semua task & connection
        scriptShutdown = true

        -- 1. Reset semua toggle state
        for _,slot in ipairs(giftSlots) do
            slot.autoSendGift=false slot.autoSendTrade=false slot.autoUnfav=false
        end
        autoAccGift=false autoAccTrade=false
        for _,cfg in pairs(swapPerPet) do
            cfg.enabled=false
        end

        -- 2. Cancel semua background task
        stopAllSwaps()
        if teamKeeperTask then pcall(task.cancel, teamKeeperTask) teamKeeperTask=nil end
        if swapKeeperTask then pcall(task.cancel, swapKeeperTask) swapKeeperTask=nil end
        if autoSendTask then pcall(task.cancel, autoSendTask) autoSendTask=nil end
        if isAR then stopAR() end
        if isRunning then doStop("Closed") end

        -- 3. Disconnect semua event connection
        for _, conn in ipairs(connections) do
            pcall(function() conn:Disconnect() end)
        end
        connections = {}

        save()
        task.wait(0.2)
        sg:Destroy()
        if playerGui:FindFirstChild("ZenxShowBtn") then playerGui.ZenxShowBtn:Destroy() end
        print("[ZenxLvl] Closed - SEMUA fitur dimatikan (task cancelled, connections disconnected)")
    end)
end)

task.wait(1)
if autoRejoin then startAR() end
if autoStartEnabled then doStart() end

do
    -- v10.4: auto-equip semua swap pet yg saved ON (sblm nunggu START)
    local enabledList={}
    for uuid,cfg in pairs(swapPerPet) do
        if cfg.enabled then table.insert(enabledList, uuid) end
    end
    if #enabledList>0 then
        dbg("[init] auto-equip "..#enabledList.." swap pet + start poller (saved swap-ON)")
        task.spawn(function()
            for _,uuid in ipairs(enabledList) do
                pcall(function() equipPet(uuid) end)
                task.wait(0.05)
            end
        end)
        startGlobalPoller()
        startSwapKeeper()
    end
end

do
    local hasTeam=false
    for _ in pairs(teamPetUUIDs) do hasTeam=true break end
    if hasTeam then
        dbg("[init] auto-start teamKeeper (team only)")
        startTeamKeeper()
    end
end

-- v10.5: pas first load, langsung minimize jadi kotak Z (klik buat expand)
setMinimized(true)

print("ZenxLvl "..SCRIPT_VERSION.." loaded! v12.78: Misc rewrite IIFE+M78")
