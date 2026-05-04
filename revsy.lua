-- ============= ZENX LVL DEBUG =============
local SCRIPT_VERSION="v8.9"
print("==== [ZenxLvl] SCRIPT MULAI LOAD ("..SCRIPT_VERSION..") ====")
warn("[ZenxLvl] versi: "..SCRIPT_VERSION.." (swap mechanic: friend-7 + gift fixed + target picker w/ cancel)")

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
end)

local debugSg, debugLbl
local _dbgLines = {}
do
    debugSg = Instance.new("ScreenGui")
    debugSg.Name = "ZenxDebug"
    debugSg.DisplayOrder = 99999
    debugSg.ResetOnSpawn = false
    debugSg.IgnoreGuiInset = true
    local parentResult = safeParent(debugSg)
    print("[ZenxLvl] debug GUI parent: "..tostring(parentResult))

    local fr = Instance.new("Frame")
    fr.Size = UDim2.new(0,420,0,360)
    fr.Position = UDim2.new(0,10,1,-370)
    fr.BackgroundColor3 = Color3.fromRGB(0,0,0)
    fr.BackgroundTransparency = 0.15
    fr.BorderSizePixel = 0
    fr.Active = true
    fr.Draggable = true
    fr.Parent = debugSg
    local crn = Instance.new("UICorner") crn.CornerRadius = UDim.new(0,8) crn.Parent = fr
    local strk = Instance.new("UIStroke") strk.Color = Color3.fromRGB(40,200,160) strk.Thickness = 1.5 strk.Parent = fr

    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(1,-30,0,20)
    title.Position = UDim2.new(0,8,0,4)
    title.BackgroundTransparency = 1
    title.Text = "Zenx Debug "..SCRIPT_VERSION.." (parent: "..tostring(parentResult)..")"
    title.TextColor3 = Color3.fromRGB(40,200,160)
    title.Font = Enum.Font.GothamBold
    title.TextSize = 12
    title.TextXAlignment = Enum.TextXAlignment.Left
    title.Parent = fr

    local closeDbg = Instance.new("TextButton")
    closeDbg.Size = UDim2.new(0,20,0,20)
    closeDbg.Position = UDim2.new(1,-24,0,4)
    closeDbg.BackgroundColor3 = Color3.fromRGB(60,30,30)
    closeDbg.Text = "X"
    closeDbg.TextColor3 = Color3.fromRGB(220,80,80)
    closeDbg.Font = Enum.Font.GothamBold
    closeDbg.TextSize = 11
    closeDbg.AutoButtonColor = false
    closeDbg.Parent = fr
    local cc = Instance.new("UICorner") cc.CornerRadius = UDim.new(0,4) cc.Parent = closeDbg
    closeDbg.MouseButton1Click:Connect(function() debugSg:Destroy() end)

    local copyDbg = Instance.new("TextButton")
    copyDbg.Size = UDim2.new(0,52,0,20)
    copyDbg.Position = UDim2.new(1,-80,0,4)
    copyDbg.BackgroundColor3 = Color3.fromRGB(20,60,40)
    copyDbg.Text = "Copy"
    copyDbg.TextColor3 = Color3.fromRGB(40,200,160)
    copyDbg.Font = Enum.Font.GothamBold
    copyDbg.TextSize = 11
    copyDbg.AutoButtonColor = false
    copyDbg.Parent = fr
    local cc2 = Instance.new("UICorner") cc2.CornerRadius = UDim.new(0,4) cc2.Parent = copyDbg

    local clearDbg = Instance.new("TextButton")
    clearDbg.Size = UDim2.new(0,46,0,20)
    clearDbg.Position = UDim2.new(1,-130,0,4)
    clearDbg.BackgroundColor3 = Color3.fromRGB(40,40,40)
    clearDbg.Text = "Clear"
    clearDbg.TextColor3 = Color3.fromRGB(180,180,180)
    clearDbg.Font = Enum.Font.GothamBold
    clearDbg.TextSize = 11
    clearDbg.AutoButtonColor = false
    clearDbg.Parent = fr
    local cc3 = Instance.new("UICorner") cc3.CornerRadius = UDim.new(0,4) cc3.Parent = clearDbg

    local sfDbg = Instance.new("ScrollingFrame")
    sfDbg.Size = UDim2.new(1,-16,1,-30)
    sfDbg.Position = UDim2.new(0,8,0,26)
    sfDbg.BackgroundTransparency = 1
    sfDbg.BorderSizePixel = 0
    sfDbg.ScrollBarThickness = 6
    sfDbg.ScrollBarImageColor3 = Color3.fromRGB(40,200,160)
    sfDbg.AutomaticCanvasSize = Enum.AutomaticSize.Y
    sfDbg.CanvasSize = UDim2.new(0,0,0,0)
    sfDbg.Parent = fr

    debugLbl = Instance.new("TextLabel")
    debugLbl.Size = UDim2.new(1,-6,0,0)
    debugLbl.Position = UDim2.new(0,2,0,0)
    debugLbl.AutomaticSize = Enum.AutomaticSize.Y
    debugLbl.BackgroundTransparency = 1
    debugLbl.Text = "Loading..."
    debugLbl.TextColor3 = Color3.fromRGB(220,220,220)
    debugLbl.Font = Enum.Font.Code
    debugLbl.TextSize = 10
    debugLbl.TextXAlignment = Enum.TextXAlignment.Left
    debugLbl.TextYAlignment = Enum.TextYAlignment.Top
    debugLbl.TextWrapped = true
    debugLbl.Parent = sfDbg

    local copyStatusLbl = Instance.new("TextLabel")
    copyStatusLbl.Size = UDim2.new(0,180,0,16)
    copyStatusLbl.Position = UDim2.new(0,8,0,4)
    copyStatusLbl.BackgroundTransparency = 1
    copyStatusLbl.Text = ""
    copyStatusLbl.TextColor3 = Color3.fromRGB(40,200,160)
    copyStatusLbl.Font = Enum.Font.Gotham
    copyStatusLbl.TextSize = 10
    copyStatusLbl.TextXAlignment = Enum.TextXAlignment.Left
    copyStatusLbl.TextYAlignment = Enum.TextYAlignment.Center
    copyStatusLbl.Parent = fr
    copyStatusLbl.Visible = false

    copyDbg.MouseButton1Click:Connect(function()
        local fullText = table.concat(_dbgLines or {}, "\n")
        if #fullText == 0 then
            copyStatusLbl.Text = "Log kosong"
            copyStatusLbl.TextColor3 = Color3.fromRGB(220,160,80)
            copyStatusLbl.Visible = true
            task.delay(2, function() copyStatusLbl.Visible = false end)
            return
        end
        local clipFn = setclipboard or set_clipboard or toclipboard
        if not clipFn and Clipboard and Clipboard.set then clipFn = Clipboard.set end
        local copied = false
        if clipFn then
            local ok = pcall(clipFn, fullText)
            if ok then
                copied = true
                copyStatusLbl.Text = "Copied "..#_dbgLines.." lines ke clipboard!"
                copyStatusLbl.TextColor3 = Color3.fromRGB(40,200,160)
                copyStatusLbl.Visible = true
                task.delay(3, function() copyStatusLbl.Visible = false end)
            end
        end
        if not copied then
            local modal = Instance.new("Frame")
            modal.Size = UDim2.new(0, 540, 0, 380)
            modal.Position = UDim2.new(0.5, -270, 0.5, -190)
            modal.BackgroundColor3 = Color3.fromRGB(15,15,18)
            modal.BorderSizePixel = 0
            modal.Active = true
            modal.Draggable = true
            modal.ZIndex = 100
            modal.Parent = debugSg
            local mc = Instance.new("UICorner") mc.CornerRadius = UDim.new(0,8) mc.Parent = modal
            local ms = Instance.new("UIStroke") ms.Color = Color3.fromRGB(40,200,160) ms.Thickness = 2 ms.Parent = modal
            local mTitle = Instance.new("TextLabel")
            mTitle.Size = UDim2.new(1,-50,0,28)
            mTitle.Position = UDim2.new(0,12,0,4)
            mTitle.BackgroundTransparency = 1
            mTitle.Text = "Copy Log Manual ("..#_dbgLines.." lines)"
            mTitle.TextColor3 = Color3.fromRGB(40,200,160)
            mTitle.Font = Enum.Font.GothamBold
            mTitle.TextSize = 12
            mTitle.TextXAlignment = Enum.TextXAlignment.Left
            mTitle.ZIndex = 101
            mTitle.Parent = modal
            local mClose = Instance.new("TextButton")
            mClose.Size = UDim2.new(0,28,0,24)
            mClose.Position = UDim2.new(1,-34,0,4)
            mClose.BackgroundColor3 = Color3.fromRGB(60,20,20)
            mClose.Text = "X"
            mClose.TextColor3 = Color3.fromRGB(255,80,80)
            mClose.Font = Enum.Font.GothamBold
            mClose.TextSize = 12
            mClose.AutoButtonColor = false
            mClose.ZIndex = 101
            mClose.Parent = modal
            local mcc = Instance.new("UICorner") mcc.CornerRadius = UDim.new(0,4) mcc.Parent = mClose
            mClose.MouseButton1Click:Connect(function() modal:Destroy() end)
            local hint = Instance.new("TextLabel")
            hint.Size = UDim2.new(1,-16,0,30)
            hint.Position = UDim2.new(0,8,0,32)
            hint.BackgroundTransparency = 1
            hint.Text = "executor lo gak support setclipboard. Tap textbox di bawah, long-press -> Select All -> Copy."
            hint.TextColor3 = Color3.fromRGB(220,160,80)
            hint.Font = Enum.Font.Gotham
            hint.TextSize = 10
            hint.TextXAlignment = Enum.TextXAlignment.Left
            hint.TextWrapped = true
            hint.ZIndex = 101
            hint.Parent = modal
            local sfM = Instance.new("ScrollingFrame")
            sfM.Size = UDim2.new(1,-16,1,-100)
            sfM.Position = UDim2.new(0,8,0,68)
            sfM.BackgroundColor3 = Color3.fromRGB(0,0,0)
            sfM.BorderSizePixel = 0
            sfM.ScrollBarThickness = 6
            sfM.ScrollBarImageColor3 = Color3.fromRGB(40,200,160)
            sfM.AutomaticCanvasSize = Enum.AutomaticSize.Y
            sfM.CanvasSize = UDim2.new(0,0,0,0)
            sfM.ZIndex = 101
            sfM.Parent = modal
            local sfc = Instance.new("UICorner") sfc.CornerRadius = UDim.new(0,4) sfc.Parent = sfM
            local txt = Instance.new("TextBox")
            txt.Size = UDim2.new(1,-12,0,0)
            txt.Position = UDim2.new(0,6,0,4)
            txt.AutomaticSize = Enum.AutomaticSize.Y
            txt.BackgroundTransparency = 1
            txt.Text = fullText
            txt.TextColor3 = Color3.fromRGB(220,220,220)
            txt.Font = Enum.Font.Code
            txt.TextSize = 10
            txt.TextXAlignment = Enum.TextXAlignment.Left
            txt.TextYAlignment = Enum.TextYAlignment.Top
            txt.TextWrapped = true
            txt.MultiLine = true
            txt.ClearTextOnFocus = false
            txt.TextEditable = false
            txt.ZIndex = 102
            txt.Parent = sfM
            local saveBtn = Instance.new("TextButton")
            saveBtn.Size = UDim2.new(0,140,0,24)
            saveBtn.Position = UDim2.new(0,8,1,-30)
            saveBtn.BackgroundColor3 = Color3.fromRGB(40,80,140)
            saveBtn.Text = "Save to .txt File"
            saveBtn.TextColor3 = Color3.fromRGB(225,225,225)
            saveBtn.Font = Enum.Font.GothamBold
            saveBtn.TextSize = 10
            saveBtn.AutoButtonColor = false
            saveBtn.ZIndex = 101
            saveBtn.Parent = modal
            local sbc = Instance.new("UICorner") sbc.CornerRadius = UDim.new(0,4) sbc.Parent = saveBtn
            local saveStatus = Instance.new("TextLabel")
            saveStatus.Size = UDim2.new(1,-160,0,24)
            saveStatus.Position = UDim2.new(0,156,1,-30)
            saveStatus.BackgroundTransparency = 1
            saveStatus.Text = ""
            saveStatus.TextColor3 = Color3.fromRGB(180,180,180)
            saveStatus.Font = Enum.Font.Gotham
            saveStatus.TextSize = 10
            saveStatus.TextXAlignment = Enum.TextXAlignment.Left
            saveStatus.ZIndex = 101
            saveStatus.Parent = modal
            saveBtn.MouseButton1Click:Connect(function()
                if not writefile then
                    saveStatus.Text = "writefile gak ada di executor"
                    saveStatus.TextColor3 = Color3.fromRGB(220,80,80)
                    return
                end
                local fname = "ZenxLog_"..os.date("%Y%m%d_%H%M%S")..".txt"
                local ok, err = pcall(writefile, fname, fullText)
                if ok then
                    saveStatus.Text = "Saved: "..fname
                    saveStatus.TextColor3 = Color3.fromRGB(40,200,160)
                else
                    saveStatus.Text = "FAIL: "..tostring(err):sub(1,30)
                    saveStatus.TextColor3 = Color3.fromRGB(220,80,80)
                end
            end)
            copyStatusLbl.Text = "Modal terbuka - manual copy"
            copyStatusLbl.TextColor3 = Color3.fromRGB(220,160,80)
            copyStatusLbl.Visible = true
            task.delay(3, function() copyStatusLbl.Visible = false end)
        end
    end)

    clearDbg.MouseButton1Click:Connect(function()
        _dbgLines = {}
        if debugLbl then debugLbl.Text = "" end
    end)
end

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
    local l=lbl(row,labelTxt,9,C.White) l.Size=UDim2.new(0.65,0,0,16) l.Position=UDim2.new(0,8,0,4)
    if descTxt then local dl=lbl(row,descTxt,8,C.Dim) dl.Size=UDim2.new(0.75,0,0,11) dl.Position=UDim2.new(0,8,0,19) end
    local tog=btn(row,"OFF",9,C.Panel,C.Gray) tog.Size=UDim2.new(0,44,0,20) tog.Position=UDim2.new(1,-50,0.5,-10)
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
    task.wait(0.03)
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
    local bp=player:FindFirstChild("Backpack") if not bp then return nil end
    for _,item in pairs(bp:GetChildren()) do
        if isPet(item) then
            local u=getPetUUID(item)
            if u and tostring(u)==tostring(uuid) then return item end
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
        dbg("[gift] FAIL: player '"..tostring(targetName).."' gak ada di server")
        return false
    end

    if petUUID then
        -- Step 1: kalau pet di garden, unequip dulu biar balik ke backpack
        local placed = findPlacedPetByUUID(petUUID)
        if placed then
            unequipPet(petUUID)
            task.wait(0.5)
        end

        -- Step 2: hold pet as tool (di character, bukan garden)
        local item = holdPetAsTool(petUUID)
        if not item then
            dbg("[gift] FAIL: gagal hold pet "..tostring(petUUID):sub(1,8).." (gak di backpack/no character)")
            return false
        end
        task.wait(0.4) -- kasih server waktu register tool equip
    end

    -- Step 3: fire GivePet dengan Player Instance
    local ok, err = pcall(function()
        giftRE:FireServer("GivePet", targetPlayer)
    end)
    if not ok then
        dbg("[gift] FireServer error: "..tostring(err))
        return false
    end

    -- Step 4: verify pet hilang dari Backpack DAN Character (3s)
    if petUUID then
        for i = 1, 15 do
            task.wait(0.2)
            if not petStillInBackpack(petUUID) and not petInCharacter(petUUID) then
                dbg("[gift] OK: "..tostring(petUUID):sub(1,8).." -> "..targetPlayer.Name)
                return true
            end
        end
        -- Cleanup: kalau gagal, unequip tool biar gak stuck di tangan
        local hum = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
        if hum then pcall(function() hum:UnequipTools() end) end
        dbg("[gift] WARN: pet "..tostring(petUUID):sub(1,8).." masih ada (target reject?)")
        return false
    end
    return true
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
        local ok2, err2 = pcall(function()
            tradeAddItemRE:FireServer("Pet", u)
        end)
        if ok2 then
            added = added + 1
            dbg("[trade] AddItem "..u:sub(1,9).."... ("..added.."/"..#uuidList..")")
        else
            dbg("[trade] AddItem error: "..tostring(err2))
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

local function getAgeFromUI(uuid)
    if not uuid then return nil end
    local pg=player:FindFirstChild("PlayerGui") if not pg then return nil end
    local activePetUI=pg:FindFirstChild("ActivePetUI") if not activePetUI then return nil end
    local uuidStr=tostring(uuid):gsub("^{",""):gsub("}$","")
    if #uuidStr<10 then return nil end
    for _,d in ipairs(activePetUI:GetDescendants()) do
        if d.Name=="PET_AGE" and d:IsA("TextLabel") then
            local p=d.Parent
            local depth=0
            while p and depth<10 do
                local pn=p.Name:gsub("^{",""):gsub("}$","")
                if pn==uuidStr then
                    local txt=""
                    pcall(function() txt=d.Text end)
                    if txt and #txt>0 then
                        local age=tonumber(txt:match("(%d+)"))
                        if age then return age end
                    end
                end
                p=p.Parent
                depth=depth+1
            end
        end
    end
    return nil
end

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
    local maxKG=getMaxKGForPet(getPetName(item)) if not maxKG then return nil end
    return math.max(1,math.min(100,math.floor(kg*110/maxKG - 10)))
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
local GUI_W=600 local GUI_H=420
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
lbl(TB,"ZENX AUTO LEVELING  "..SCRIPT_VERSION,11,C.Teal).Size=UDim2.new(1,-60,1,0)

local minBtn=btn(TB,"-",13,C.Panel,C.Gray)
minBtn.Size=UDim2.new(0,22,0,22) minBtn.Position=UDim2.new(1,-50,0.5,-11) stroke(minBtn,C.Dim,1.2)
local closeBtn=btn(TB,"X",10,C.RDim,C.Red)
closeBtn.Size=UDim2.new(0,22,0,22) closeBtn.Position=UDim2.new(1,-24,0.5,-11) stroke(closeBtn,C.Red,1.2)

local content=mk("Frame",{Size=UDim2.new(1,0,1,-34),Position=UDim2.new(0,0,0,34),BackgroundTransparency=1,Parent=main})
local tabBar=mk("Frame",{Size=UDim2.new(1,-10,0,26),Position=UDim2.new(0,5,0,4),BackgroundTransparency=1,Parent=content})
mk("UIListLayout",{FillDirection=Enum.FillDirection.Horizontal,Padding=UDim.new(0,2),Parent=tabBar})

local tabNames={"Tim Leveling","Pet ke 100","Swap Skill","Other Setting","Auto Gift"}
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
local statusLbl=lbl(botBar,"Status: Idle",9,C.Gray,Enum.TextXAlignment.Left)
statusLbl.Size=UDim2.new(1,-10,1,0) statusLbl.Position=UDim2.new(0,8,0,0)

local BOT_Y=SCROLL_Y+SCROLL_H+34
local runBtn=btn(content,"RUNNING",10,C.Panel,C.Gray)
runBtn.Size=UDim2.new(0,150,0,26) runBtn.Position=UDim2.new(0,5,0,BOT_Y)
local runStroke=stroke(runBtn,C.Dim,1.5)
local stopBtn=btn(content,"STOP",10,C.Panel,C.Gray)
stopBtn.Size=UDim2.new(0,90,0,26) stopBtn.Position=UDim2.new(0,160,0,BOT_Y)
local stopStroke=stroke(stopBtn,C.Dim,1.5)

local function switchTab(idx)
    for i,b in ipairs(tabBtns) do
        local s=b:FindFirstChildWhichIsA("UIStroke")
        if i==idx then b.TextColor3=C.Teal b.BackgroundColor3=C.TDim if s then s.Color=C.Teal end areas[i].Visible=true
        else b.TextColor3=C.Gray b.BackgroundColor3=C.Card if s then s.Color=C.Dim end areas[i].Visible=false end
    end
end

for i,name in ipairs(tabNames) do
    local b=btn(tabBar,name,8,C.Card,C.Gray)
    b.Size=UDim2.new(0,113,1,0) b.LayoutOrder=i stroke(b,C.Dim,1.1) tabBtns[i]=b
    local ii=i b.MouseButton1Click:Connect(function() switchTab(ii) end)
end

local minimized=false
minBtn.MouseButton1Click:Connect(function()
    minimized=not minimized
    content.Visible=not minimized
    main.Size=minimized and UDim2.new(0,GUI_W,0,34) or UDim2.new(0,GUI_W,0,GUI_H)
    minBtn.Text=minimized and "+" or "-"
end)

local teamPetUUIDs=d.teamPetUUIDs or {}
local teamPetInfoCache=d.teamPetInfoCache or {}

local config=d.config or {equipInterval=5,rejoinMinutes=30}
local targetPetTypes=d.targetPetTypes or {}
local fromAge=d.fromAge or 1
local toAge=d.toAge or 100
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
    if targetPetTypes[getBaseName(name)] then return true end
    return false
end
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
    lbl(cfgCard,"Setting Leveling",9,C.Teal).Size=UDim2.new(1,0,0,13)
    local eqRow=mk("Frame",{Size=UDim2.new(1,0,0,26),BackgroundColor3=C.Card,BorderSizePixel=0,Parent=cfgCard})
    corner(eqRow,5) stroke(eqRow,C.Dim,1)
    lbl(eqRow,"Equip Interval (dtk)",9,C.Gray).Size=UDim2.new(0.6,0,1,0)
    local eqBox=mk("TextBox",{Size=UDim2.new(0,50,0,20),Position=UDim2.new(1,-56,0.5,-10),BackgroundColor3=C.Panel,Text=tostring(config.equipInterval),TextColor3=C.White,Font=Enum.Font.GothamBold,TextSize=10,TextScaled=false,TextXAlignment=Enum.TextXAlignment.Center,ClearTextOnFocus=false,Parent=eqRow})
    corner(eqBox,5) stroke(eqBox,C.Dim,1)
    eqBox:GetPropertyChangedSignal("Text"):Connect(function()
        local v=tonumber(eqBox.Text) if v then config.equipInterval=math.max(1,v) save() end
    end)

    local saRow=mk("Frame",{Size=UDim2.new(1,0,0,28),BackgroundColor3=C.Card,BorderSizePixel=0,LayoutOrder=1,Parent=areas[1]})
    corner(saRow,6) stroke(saRow,C.Dim,1.1)
    lbl(saRow,"Tampilkan semua pet",9,C.Gray).Size=UDim2.new(0.55,0,0,14)
    local saTxt=lbl(saRow,"(bypass filter love)",7,C.Dim) saTxt.Size=UDim2.new(0.55,0,0,11) saTxt.Position=UDim2.new(0,8,0,16)
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

    local scanBtn=btn(areas[1],"Scan Attr Pet (debug)",8,C.Card,C.Gray)
    scanBtn.Size=UDim2.new(1,0,0,20) scanBtn.LayoutOrder=2 stroke(scanBtn,C.Dim,1)
    scanBtn.MouseButton1Click:Connect(function()
        local bp=player:FindFirstChild("Backpack")
        if not bp then dbg("Backpack tidak ada") return end
        dbg("=== SCAN PET ATTRIBUTES ===")
        local cnt=0
        for _,item in pairs(bp:GetChildren()) do
            if isPet(item) and cnt<5 then
                cnt=cnt+1
                dbg("Pet "..cnt..": "..item.Name)
                local attrs=item:GetAttributes()
                local hasAttrs=false
                for k,v in pairs(attrs) do
                    hasAttrs=true
                    dbg("  ["..k.."] = "..tostring(v).." ("..type(v)..")")
                end
                if not hasAttrs then dbg("  (no attributes)") end
            end
        end
        dbg("=== END SCAN. Kasih ke Claude. ===")
    end)

    local scanGardenBtn=btn(areas[1],"Scan Garden (debug)",8,C.Card,C.Gray)
    scanGardenBtn.Size=UDim2.new(1,0,0,20) scanGardenBtn.LayoutOrder=3 stroke(scanGardenBtn,C.Dim,1)
    scanGardenBtn.MouseButton1Click:Connect(function()
        dbg("=== SCAN GARDEN STRUCTURE ===")
        local petsPhys=workspace:FindFirstChild("PetsPhysical")
        if not petsPhys then dbg("PetsPhysical GAK ADA di workspace") return end
        dbg("PetsPhysical children:")
        for _,c in ipairs(petsPhys:GetChildren()) do
            dbg("  ["..c.ClassName.."] "..c.Name)
        end
        local petMover=petsPhys:FindFirstChild("PetMover")
        if petMover then
            dbg("PetMover children ("..#petMover:GetChildren().." items):")
            local n=0
            for _,c in ipairs(petMover:GetChildren()) do
                n=n+1
                if n<=10 then
                    local attrUuid="-"
                    pcall(function() local a=c:GetAttribute("PET_UUID") if a then attrUuid=tostring(a) end end)
                    dbg("  "..n..". ["..c.ClassName.."] "..c.Name.." attr.PET_UUID="..attrUuid)
                end
            end
            if n>10 then dbg("  ... ("..(n-10).." pet lain)") end
        else
            dbg("PetMover GAK ADA di PetsPhysical")
        end
        dbg("=== END SCAN. Kasih ke Claude kalo pickup gagal. ===")
    end)

    local scanUIBtn=btn(areas[1],"Scan UI Age (debug)",8,C.Card,C.Gray)
    scanUIBtn.Size=UDim2.new(1,0,0,20) scanUIBtn.LayoutOrder=4 stroke(scanUIBtn,C.Dim,1)
    scanUIBtn.MouseButton1Click:Connect(function()
        dbg("=== SCAN UI AGE DEBUG ===")
        local pg=player:FindFirstChild("PlayerGui")
        if not pg then dbg("PlayerGui GAK ADA") return end
        local activePetUI=pg:FindFirstChild("ActivePetUI")
        if not activePetUI then dbg("ActivePetUI GAK ADA") return end
        local ageLabels={}
        for _,d in ipairs(activePetUI:GetDescendants()) do
            if d.Name=="PET_AGE" and d:IsA("TextLabel") then
                table.insert(ageLabels,d)
            end
        end
        dbg("Found "..#ageLabels.." PET_AGE TextLabel(s)")
        for i,lbl in ipairs(ageLabels) do
            if i<=10 then
                local txt=""
                pcall(function() txt=lbl.Text end)
                dbg("--- PET_AGE ["..i.."] text='"..txt.."' path="..lbl:GetFullName():sub(-100))
                local p=lbl.Parent
                local depth=0
                while p and p~=activePetUI and depth<8 do
                    dbg("  parent ["..depth.."]: ["..p.ClassName.."] '"..p.Name.."'")
                    p=p.Parent
                    depth=depth+1
                end
            end
        end
        dbg("--- Test currentLevelingUUIDs ---")
        local cnt=0
        for uuid,_ in pairs(currentLevelingUUIDs) do
            cnt=cnt+1
            local age=getAgeFromUI(uuid)
            local nm=getPetNameFromUI(uuid) or "(no nick)"
            local tp=getPetTypeFromUI(uuid) or "(no type)"
            dbg("  uuid="..tostring(uuid):sub(1,16).."... age="..tostring(age).." name='"..nm.."' type='"..tp.."'")
        end
        if cnt==0 then dbg("  (currentLevelingUUIDs kosong, pencet START dulu)") end
        dbg("=== END SCAN UI ===")
    end)

    div(areas[1],1)

    local pickerOpen=false
    local pickRow=mk("Frame",{Size=UDim2.new(1,0,0,30),BackgroundColor3=C.Card,BorderSizePixel=0,LayoutOrder=2,Parent=areas[1]})
    corner(pickRow,6) local pickStroke=stroke(pickRow,C.Dim,1.1)
    local pickLbl=lbl(pickRow,"Pilih Pet Tim  ("..teamCount().." dipilih)",9,C.White)
    pickLbl.Size=UDim2.new(0.8,0,1,0) pickLbl.Position=UDim2.new(0,10,0,0)
    local pickArrow=lbl(pickRow,"v",9,C.Teal,Enum.TextXAlignment.Right)
    pickArrow.Size=UDim2.new(0,20,1,0) pickArrow.Position=UDim2.new(1,-24,0,0)
    local pickBtnCover=mk("TextButton",{Size=UDim2.new(1,0,1,0),BackgroundTransparency=1,Text="",AutoButtonColor=false,Parent=pickRow})

    local picker=mk("Frame",{Size=UDim2.new(1,0,0,0),BackgroundColor3=C.Panel,BorderSizePixel=0,Visible=false,LayoutOrder=3,Parent=areas[1]})
    corner(picker,7) stroke(picker,C.Teal,1.3)
    mk("UIPadding",{PaddingTop=UDim.new(0,4),PaddingLeft=UDim.new(0,4),PaddingRight=UDim.new(0,4),PaddingBottom=UDim.new(0,4),Parent=picker})
    mk("UIListLayout",{SortOrder=Enum.SortOrder.LayoutOrder,Padding=UDim.new(0,3),Parent=picker})

    local pickSearch=mk("TextBox",{Size=UDim2.new(1,0,0,22),BackgroundColor3=C.Card,Text="",PlaceholderText="Cari pet...",PlaceholderColor3=C.Dim,TextColor3=C.White,Font=Enum.Font.Gotham,TextSize=9,TextScaled=false,ClearTextOnFocus=false,LayoutOrder=0,Parent=picker})
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
        lbl(timHdr,"Tim Leveling ("..teamCount().." pet):",9,C.Teal).Size=UDim2.new(1,-10,1,0)
        local i=0
        if teamCount()==0 then
            local e=lbl(areas[1],"Belum ada pet dipilih",8,C.Gray,Enum.TextXAlignment.Center)
            e.Size=UDim2.new(1,0,0,20) e.LayoutOrder=6
        else
            for uuid,_ in pairs(teamPetUUIDs) do
                i=i+1
                local info=teamPetInfoCache[uuid] and teamPetInfoCache[uuid].info or uuid
                local pr=mk("Frame",{Size=UDim2.new(1,0,0,26),BackgroundColor3=C.TDim,BorderSizePixel=0,LayoutOrder=5+i,Parent=areas[1]})
                corner(pr,5) stroke(pr,C.Teal,1.1)
                local nl=lbl(pr,tostring(i)..".",9,C.Teal,Enum.TextXAlignment.Center) nl.Size=UDim2.new(0,24,1,0) nl.Position=UDim2.new(0,2,0,0)
                local il=lbl(pr,info,8,C.White) il.Size=UDim2.new(1,-36,1,0) il.Position=UDim2.new(0,28,0,0)
                local db=btn(pr,"X",8,C.RDim,C.Red) db.Size=UDim2.new(0,18,0,18) db.Position=UDim2.new(1,-22,0.5,-9) stroke(db,C.Red,1)
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
        local rf=btn(areas[1],"Refresh",10,C.Panel,C.White)
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
                            local row=mk("Frame",{Size=UDim2.new(1,0,0,26),BackgroundColor3=inTeam and C.TDim or C.Card,BorderSizePixel=0,LayoutOrder=n,Parent=petPickScroll})
                            corner(row,5) if inTeam then stroke(row,C.Teal,1.1) end
                            local nameLbl=lbl(row,info,8,inTeam and C.Teal or C.White)
                            nameLbl.Size=UDim2.new(0.72,0,1,0) nameLbl.Position=UDim2.new(0,8,0,0)
                            local togBtn=btn(row,inTeam and "ON" or "OFF",8,inTeam and C.TDim or C.Panel,inTeam and C.Teal or C.Gray)
                            togBtn.Size=UDim2.new(0,44,0,20) togBtn.Position=UDim2.new(1,-48,0.5,-10)
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
                    local row=mk("Frame",{Size=UDim2.new(1,0,0,26),BackgroundColor3=C.TDim,BorderSizePixel=0,LayoutOrder=n,Parent=petPickScroll})
                    corner(row,5) stroke(row,C.Teal,1.1)
                    local nl=lbl(row,info,8,C.Teal) nl.Size=UDim2.new(0.72,0,1,0) nl.Position=UDim2.new(0,8,0,0)
                    local tb=btn(row,"ON",8,C.TDim,C.Teal) tb.Size=UDim2.new(0,44,0,20) tb.Position=UDim2.new(1,-48,0.5,-10) stroke(tb,C.Teal,1.1)
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
            local e=lbl(petPickScroll,msg,8,C.Red,Enum.TextXAlignment.Center)
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
    local typeLbl=lbl(typeRow,"Jenis Pet  ("..selCount().." dipilih, 0=semua)",9,C.White)
    typeLbl.Size=UDim2.new(0.8,0,1,0) typeLbl.Position=UDim2.new(0,10,0,0)
    local typeArrow=lbl(typeRow,"v",9,C.Teal,Enum.TextXAlignment.Right)
    typeArrow.Size=UDim2.new(0,20,1,0) typeArrow.Position=UDim2.new(1,-24,0,0)
    local typeBtnCover=mk("TextButton",{Size=UDim2.new(1,0,1,0),BackgroundTransparency=1,Text="",AutoButtonColor=false,Parent=typeRow})
    local typePicker=mk("Frame",{Size=UDim2.new(1,0,0,0),BackgroundColor3=C.Panel,BorderSizePixel=0,Visible=false,LayoutOrder=1,Parent=areas[2]})
    corner(typePicker,7) stroke(typePicker,C.Teal,1.3)
    mk("UIPadding",{PaddingTop=UDim.new(0,4),PaddingLeft=UDim.new(0,4),PaddingRight=UDim.new(0,4),PaddingBottom=UDim.new(0,4),Parent=typePicker})
    mk("UIListLayout",{SortOrder=Enum.SortOrder.LayoutOrder,Padding=UDim.new(0,3),Parent=typePicker})
    local typeSearch=mk("TextBox",{Size=UDim2.new(1,0,0,22),BackgroundColor3=C.Card,Text="",PlaceholderText="Cari jenis pet...",PlaceholderColor3=C.Dim,TextColor3=C.White,Font=Enum.Font.Gotham,TextSize=9,TextScaled=false,ClearTextOnFocus=false,LayoutOrder=0,Parent=typePicker})
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
        lbl(r,labelTxt,9,C.Gray).Size=UDim2.new(0.6,0,1,0)
        local box=mk("TextBox",{Size=UDim2.new(0,50,0,20),Position=UDim2.new(1,-56,0.5,-10),BackgroundColor3=C.Panel,Text=tostring(default),TextColor3=C.White,Font=Enum.Font.GothamBold,TextSize=10,TextScaled=false,TextXAlignment=Enum.TextXAlignment.Center,ClearTextOnFocus=false,Parent=r})
        corner(box,5) stroke(box,C.Dim,1)
        box:GetPropertyChangedSignal("Text"):Connect(function() local v=tonumber(box.Text) if v then onChange(v) save() end end)
    end
    numRow("Dari Age:",3,fromAge,function(v) fromAge=math.max(1,math.min(99,v)) d.fromAge=fromAge end)
    numRow("Sampai Age:",4,toAge,function(v) toAge=math.max(1,math.min(100,v)) d.toAge=toAge end)

    local pcRow=mk("Frame",{Size=UDim2.new(1,0,0,26),BackgroundColor3=C.Card,BorderSizePixel=0,LayoutOrder=5,Parent=areas[2]})
    corner(pcRow,6) stroke(pcRow,C.Dim,1.1)
    lbl(pcRow,"Jumlah Pet (sekaligus):",9,C.Gray).Size=UDim2.new(0.55,0,1,0)
    local pcMin=btn(pcRow,"-",12,C.Panel,C.Gray) pcMin.Size=UDim2.new(0,22,0,20) pcMin.Position=UDim2.new(1,-72,0.5,-10) stroke(pcMin,C.Dim,1.1)
    local pcNum=lbl(pcRow,tostring(maxPetTarget),10,C.White,Enum.TextXAlignment.Center) pcNum.Size=UDim2.new(0,26,1,0) pcNum.Position=UDim2.new(1,-48,0,0) pcNum.Font=Enum.Font.GothamBold
    local pcPlus=btn(pcRow,"+",12,C.Panel,C.Gray) pcPlus.Size=UDim2.new(0,22,0,20) pcPlus.Position=UDim2.new(1,-22,0.5,-10) stroke(pcPlus,C.Dim,1.1)
    pcMin.MouseButton1Click:Connect(function() if maxPetTarget>1 then maxPetTarget=maxPetTarget-1 d.maxPetTarget=maxPetTarget pcNum.Text=tostring(maxPetTarget) save() end end)
    pcPlus.MouseButton1Click:Connect(function() if maxPetTarget<10 then maxPetTarget=maxPetTarget+1 d.maxPetTarget=maxPetTarget pcNum.Text=tostring(maxPetTarget) save() end end)

    div(areas[2],6)
    local qHdr=mk("Frame",{Size=UDim2.new(1,0,0,22),BackgroundColor3=C.Panel,BorderSizePixel=0,LayoutOrder=7,Parent=areas[2]})
    corner(qHdr,5) lbl(qHdr,"Pet target belum jadi (jenis):",9,C.Teal).Size=UDim2.new(1,-10,1,0)

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
        local e=lbl(areas[2],"Tidak ada pet yang cocok",8,C.Red,Enum.TextXAlignment.Center)
        e.Size=UDim2.new(1,0,0,22) e.LayoutOrder=8
    else
        local idx=0
        for _,base in ipairs(sortedBases) do
            idx=idx+1
            local data=agg[base]
            local row=mk("Frame",{Size=UDim2.new(1,0,0,28),BackgroundColor3=C.Card,BorderSizePixel=0,LayoutOrder=7+idx,Parent=areas[2]})
            corner(row,5) stroke(row,C.Dim,1)
            local nl=lbl(row,base,9,C.White) nl.Size=UDim2.new(0.65,0,1,0) nl.Position=UDim2.new(0,10,0,0)
            local cnt=lbl(row,data.count.." pet",9,C.Teal,Enum.TextXAlignment.Right)
            cnt.Size=UDim2.new(0,80,1,0) cnt.Position=UDim2.new(1,-90,0,0)
            cnt.Font=Enum.Font.GothamBold
            if data.mutCount>0 then
                local mut=lbl(row,"("..data.mutCount.." mutasi)",7,C.Gold,Enum.TextXAlignment.Left)
                mut.Size=UDim2.new(0.35,0,0,11) mut.Position=UDim2.new(0,10,0,16)
                nl.Size=UDim2.new(0.65,0,0,16) nl.Position=UDim2.new(0,10,0,2)
            end
        end
        local tot=lbl(areas[2],"Total: "..total.." pet ("..(#sortedBases).." jenis)",9,C.Teal,Enum.TextXAlignment.Center)
        tot.Size=UDim2.new(1,0,0,16) tot.LayoutOrder=7+#sortedBases+1
    end
    div(areas[2],200)
    local rf=btn(areas[2],"Refresh",10,C.Panel,C.White) rf.Size=UDim2.new(1,0,0,22) rf.LayoutOrder=201 stroke(rf,C.Dim,1.2)
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
    lbl(infoCard,"Swap Mechanic: friend-7",10,C.Teal).Size=UDim2.new(1,0,0,14)
    local descLbl=lbl(infoCard,"Toggle ON utk swap. Pet HARUS udah di garden (place manual/via tim).",8,C.Gray)
    descLbl.Size=UDim2.new(1,0,0,22) descLbl.TextWrapped=true

    local saRow=mk("Frame",{Size=UDim2.new(1,0,0,28),BackgroundColor3=C.Card,BorderSizePixel=0,LayoutOrder=1,Parent=areas[3]})
    corner(saRow,6) stroke(saRow,C.Dim,1.1)
    lbl(saRow,"Tampilkan semua pet",9,C.Gray).Size=UDim2.new(0.55,0,0,14)
    local saTxt=lbl(saRow,"(bypass filter love di section Favorit)",7,C.Dim) saTxt.Size=UDim2.new(0.6,0,0,11) saTxt.Position=UDim2.new(0,8,0,16)
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
                if startGlobalPoller then startGlobalPoller() end
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
        local e=lbl(areas[3],"Belum ada pet di Tim Leveling. Pilih dulu di tab 1.",8,C.Gray,Enum.TextXAlignment.Center)
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
        local e=lbl(areas[3],msg,8,C.Gray,Enum.TextXAlignment.Center)
        e.Size=UDim2.new(1,0,0,22) e.LayoutOrder=lo e.TextWrapped=true lo=lo+1
    else
        for _,r in ipairs(favRows) do
            makeRow(areas[3],r,lo) lo=lo+1
        end
    end

    div(areas[3],500)
    local rf=btn(areas[3],"Refresh",9,C.Panel,C.White) rf.Size=UDim2.new(1,0,0,22) rf.LayoutOrder=501 stroke(rf,C.Dim,1.2)
    rf.MouseButton1Click:Connect(function() buildSwapList() end)
    local clr=btn(areas[3],"Clear Semua (matikan)",9,C.RDim,C.Red) clr.Size=UDim2.new(1,0,0,22) clr.LayoutOrder=502 stroke(clr,C.Red,1.2)
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
        lbl(r,labelTxt,9,C.Gray).Size=UDim2.new(0.6,0,1,0)
        local box=mk("TextBox",{Size=UDim2.new(0,56,0,20),Position=UDim2.new(1,-62,0.5,-10),BackgroundColor3=C.Panel,Text=tostring(default),TextColor3=C.White,Font=Enum.Font.GothamBold,TextSize=10,TextScaled=false,TextXAlignment=Enum.TextXAlignment.Center,ClearTextOnFocus=false,Parent=r})
        corner(box,5) stroke(box,C.Dim,1)
        box:GetPropertyChangedSignal("Text"):Connect(function() local v=tonumber(box.Text) if v then onChange(v) save() end end)
    end

    local t1=lbl(areas[4],"LEVELING",9,C.Teal) t1.Size=UDim2.new(1,0,0,14) t1.LayoutOrder=0
    local _,asTog,asTogStroke,asStroke=togRow(areas[4],"Auto Start Leveling","Auto mulai saat script dijalankan",1)
    local function setAsTog(val)
        asTog.Text=val and "ON" or "OFF" asTog.BackgroundColor3=val and C.TDim or C.Panel asTog.TextColor3=val and C.Teal or C.Gray asTogStroke.Color=val and C.Teal or C.Dim asStroke.Color=val and C.Teal or C.Dim
    end
    setAsTog(autoStartEnabled)
    asTog.MouseButton1Click:Connect(function() autoStartEnabled=not autoStartEnabled setAsTog(autoStartEnabled) save() end)

    div(areas[4],2)
    local t2=lbl(areas[4],"REJOIN",9,C.Teal) t2.Size=UDim2.new(1,0,0,14) t2.LayoutOrder=3
    local rnBtn=btn(areas[4],"Rejoin Now",10,C.TDim,C.Teal)
    rnBtn.Size=UDim2.new(1,0,0,24) rnBtn.LayoutOrder=4 stroke(rnBtn,C.Teal,1.5)
    rnBtn.MouseButton1Click:Connect(function() rnBtn.Text="Rejoining..." task.wait(0.5) TS:Teleport(game.PlaceId,player) end)
    cfgRow("Interval (menit)",5,config.rejoinMinutes,function(v)
        config.rejoinMinutes=math.max(1,math.min(120,v)) d.config.rejoinMinutes=config.rejoinMinutes save()
    end)

    local _row
    _row,arTog2,arTogStroke2,arStroke2=togRow(areas[4],"Auto Rejoin","Rejoin otomatis sesuai interval",6)
    cdLbl2=lbl(areas[4],"Auto Rejoin: OFF",9,C.Gray,Enum.TextXAlignment.Center)
    cdLbl2.Size=UDim2.new(1,0,0,20) cdLbl2.LayoutOrder=7 cdLbl2.BackgroundColor3=C.Panel cdLbl2.BackgroundTransparency=0
    corner(cdLbl2,6) stroke(cdLbl2,C.Dim,1.1)

    local function setArTog(val)
        arTog2.Text=val and "ON" or "OFF" arTog2.BackgroundColor3=val and C.TDim or C.Panel arTog2.TextColor3=val and C.Teal or C.Gray arTogStroke2.Color=val and C.Teal or C.Dim arStroke2.Color=val and C.Teal or C.Dim
    end
    setArTog(autoRejoin)

    div(areas[4],8)
    local t3=lbl(areas[4],"ANTI-AFK",9,C.Teal) t3.Size=UDim2.new(1,0,0,14) t3.LayoutOrder=9
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
local function buildAutoGift()
    for _,c in pairs(areas[5]:GetChildren()) do
        if c:IsA("Frame") or c:IsA("TextLabel") or c:IsA("TextButton") then c:Destroy() end
    end

    local ivRow=mk("Frame",{Size=UDim2.new(1,0,0,26),BackgroundColor3=C.Card,BorderSizePixel=0,LayoutOrder=0,Parent=areas[5]})
    corner(ivRow,6) stroke(ivRow,C.Dim,1.1)
    lbl(ivRow,"Interval Send (dtk):",9,C.Gray).Size=UDim2.new(0.6,0,1,0)
    local ivBox=mk("TextBox",{Size=UDim2.new(0,50,0,20),Position=UDim2.new(1,-56,0.5,-10),BackgroundColor3=C.Panel,Text=tostring(sendInterval),TextColor3=C.White,Font=Enum.Font.GothamBold,TextSize=10,TextScaled=false,TextXAlignment=Enum.TextXAlignment.Center,ClearTextOnFocus=false,Parent=ivRow})
    corner(ivBox,5) stroke(ivBox,C.Dim,1)
    ivBox:GetPropertyChangedSignal("Text"):Connect(function() local v=tonumber(ivBox.Text) if v then sendInterval=math.max(5,v) save() end end)

    local function makeCollapsible(title,layoutOrder)
        local hdr=mk("Frame",{Size=UDim2.new(1,0,0,32),BackgroundColor3=C.Card,BorderSizePixel=0,LayoutOrder=layoutOrder,Parent=areas[5]})
        corner(hdr,7) local hdrStroke=stroke(hdr,C.Dim,1.2)
        local titleLbl=lbl(hdr,title,11,C.White) titleLbl.Size=UDim2.new(0.85,0,1,0) titleLbl.Position=UDim2.new(0,12,0,0) titleLbl.Font=Enum.Font.GothamBold
        local arrow=lbl(hdr,"v",11,C.Teal,Enum.TextXAlignment.Right) arrow.Size=UDim2.new(0,24,1,0) arrow.Position=UDim2.new(1,-30,0,0)
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

        -- v8.8: Target inline picker (single select dari list player di server)
        local function trText() return slot.target == "" and "(klik pilih)" or slot.target end
        local trOpen=false
        local trRow=mk("Frame",{Size=UDim2.new(1,0,0,28),BackgroundColor3=C.Card,BorderSizePixel=0,LayoutOrder=1,Parent=parent})
        corner(trRow,6) local trStroke=stroke(trRow,C.Dim,1.1)
        local trLbl=lbl(trRow,"Target: "..trText(),9,C.White) trLbl.Size=UDim2.new(0.85,0,1,0) trLbl.Position=UDim2.new(0,10,0,0)
        local trArrow=lbl(trRow,"v",9,C.Teal,Enum.TextXAlignment.Right) trArrow.Size=UDim2.new(0,20,1,0) trArrow.Position=UDim2.new(1,-24,0,0)
        local trCover=mk("TextButton",{Size=UDim2.new(1,0,1,0),BackgroundTransparency=1,Text="",AutoButtonColor=false,Parent=trRow})
        local trPicker=mk("Frame",{Size=UDim2.new(1,0,0,0),BackgroundColor3=C.BG,BorderSizePixel=0,Visible=false,LayoutOrder=2,Parent=parent})
        corner(trPicker,6) stroke(trPicker,C.Teal,1.2)
        mk("UIPadding",{PaddingTop=UDim.new(0,4),PaddingLeft=UDim.new(0,4),PaddingRight=UDim.new(0,4),PaddingBottom=UDim.new(0,4),Parent=trPicker})
        local trScroll=mk("ScrollingFrame",{Size=UDim2.new(1,0,0,120),BackgroundTransparency=1,ScrollBarThickness=3,ScrollBarImageColor3=C.Teal,CanvasSize=UDim2.new(0,0,0,0),AutomaticCanvasSize=Enum.AutomaticSize.Y,Parent=trPicker})
        mk("UIListLayout",{SortOrder=Enum.SortOrder.LayoutOrder,Padding=UDim.new(0,2),Parent=trScroll})
        local function buildPlayerList()
            for _,c in pairs(trScroll:GetChildren()) do if c:IsA("Frame") or c:IsA("TextLabel") then c:Destroy() end end

            -- v8.9: opsi batalin di paling atas
            local clrSel = slot.target == ""
            local clrRow=mk("Frame",{Size=UDim2.new(1,0,0,22),BackgroundColor3=clrSel and C.RDim or C.Card,BorderSizePixel=0,LayoutOrder=0,Parent=trScroll})
            corner(clrRow,5) if clrSel then stroke(clrRow,C.Red,1.1) else stroke(clrRow,C.Dim,1) end
            local clrLbl=lbl(clrRow,"(Batalin pilihan)",8,clrSel and C.Red or C.Gray) clrLbl.Size=UDim2.new(1,-12,1,0) clrLbl.Position=UDim2.new(0,8,0,0)
            local clrCover=mk("TextButton",{Size=UDim2.new(1,0,1,0),BackgroundTransparency=1,Text="",AutoButtonColor=false,Parent=clrRow})
            clrCover.MouseButton1Click:Connect(function()
                slot.target=""
                trLbl.Text="Target: (klik pilih)"
                save()
                buildPlayerList()
            end)

            local plist = {}
            for _, p in ipairs(Players:GetPlayers()) do
                if p ~= player then table.insert(plist, p.Name) end
            end
            table.sort(plist)
            for i, name in ipairs(plist) do
                local sel = slot.target == name
                local row=mk("Frame",{Size=UDim2.new(1,0,0,22),BackgroundColor3=sel and C.TDim or C.Card,BorderSizePixel=0,LayoutOrder=i,Parent=trScroll})
                corner(row,5) if sel then stroke(row,C.Teal,1.1) end
                local nl=lbl(row,name,8,sel and C.Teal or C.White) nl.Size=UDim2.new(1,-12,1,0) nl.Position=UDim2.new(0,8,0,0)
                local cn=name
                local cover2=mk("TextButton",{Size=UDim2.new(1,0,1,0),BackgroundTransparency=1,Text="",AutoButtonColor=false,Parent=row})
                cover2.MouseButton1Click:Connect(function()
                    -- v8.9: klik nama yg sama = batalin (toggle deselect)
                    if slot.target == cn then
                        slot.target = ""
                        trLbl.Text = "Target: (klik pilih)"
                    else
                        slot.target = cn
                        trLbl.Text = "Target: "..cn
                    end
                    save()
                    buildPlayerList()
                end)
            end
            if #plist == 0 then
                local e=lbl(trScroll,"(belum ada player lain di server)",8,C.Red,Enum.TextXAlignment.Center)
                e.Size=UDim2.new(1,-12,0,22) e.LayoutOrder=1 e.TextWrapped=true
            end
        end
        buildPlayerList()
        trCover.MouseButton1Click:Connect(function()
            trOpen=not trOpen
            trPicker.Visible=trOpen
            trPicker.Size=trOpen and UDim2.new(1,0,0,128) or UDim2.new(1,0,0,0)
            trArrow.Text=trOpen and "^" or "v" trStroke.Color=trOpen and C.Teal or C.Dim
            if trOpen then buildPlayerList() end
        end)

        local function countTypes() local n=0 for _ in pairs(slot.petTypes) do n=n+1 end return n end
        local function countMatching()
            local n=0 local bp=player:FindFirstChild("Backpack")
            if bp then for _,it in pairs(bp:GetChildren()) do if isPet(it) and slot.petTypes[getBaseName(getPetName(it))] then n=n+1 end end end
            return n
        end

        local pickerOpen=false
        local pickRow=mk("Frame",{Size=UDim2.new(1,0,0,28),BackgroundColor3=C.Card,BorderSizePixel=0,LayoutOrder=3,Parent=parent})
        corner(pickRow,6) local pickStroke=stroke(pickRow,C.Dim,1.1)
        local pickLbl=lbl(pickRow,"Pilih Jenis Pet ("..countTypes().." = "..countMatching().." pet)",9,C.White)
        pickLbl.Size=UDim2.new(0.85,0,1,0) pickLbl.Position=UDim2.new(0,10,0,0)
        local pickArrow=lbl(pickRow,"v",9,C.Teal,Enum.TextXAlignment.Right) pickArrow.Size=UDim2.new(0,20,1,0) pickArrow.Position=UDim2.new(1,-24,0,0)
        local pickCover=mk("TextButton",{Size=UDim2.new(1,0,1,0),BackgroundTransparency=1,Text="",AutoButtonColor=false,Parent=pickRow})
        local picker=mk("Frame",{Size=UDim2.new(1,0,0,0),BackgroundColor3=C.BG,BorderSizePixel=0,Visible=false,LayoutOrder=4,Parent=parent})
        corner(picker,6) stroke(picker,C.Teal,1.2)
        mk("UIPadding",{PaddingTop=UDim.new(0,4),PaddingLeft=UDim.new(0,4),PaddingRight=UDim.new(0,4),PaddingBottom=UDim.new(0,4),Parent=picker})
        local typeScroll=mk("ScrollingFrame",{Size=UDim2.new(1,0,0,140),BackgroundTransparency=1,ScrollBarThickness=3,ScrollBarImageColor3=C.Teal,CanvasSize=UDim2.new(0,0,0,0),AutomaticCanvasSize=Enum.AutomaticSize.Y,Parent=picker})
        mk("UIListLayout",{SortOrder=Enum.SortOrder.LayoutOrder,Padding=UDim.new(0,2),Parent=typeScroll})

        local function buildTypeList()
            for _,c in pairs(typeScroll:GetChildren()) do if c:IsA("Frame") then c:Destroy() end end
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
            local n=0
            for _,base in ipairs(sorted) do
                n=n+1 local data=types[base] local sel=slot.petTypes[base]==true
                local row=mk("Frame",{Size=UDim2.new(1,0,0,24),BackgroundColor3=sel and C.TDim or C.Card,BorderSizePixel=0,LayoutOrder=n,Parent=typeScroll})
                corner(row,5) if sel then stroke(row,C.Teal,1.1) end
                local txt=base.." ("..data.count..(data.mut>0 and ", "..data.mut.." mut" or "")..")"
                local nl=lbl(row,txt,8,sel and C.Teal or C.White) nl.Size=UDim2.new(0.72,0,1,0) nl.Position=UDim2.new(0,8,0,0)
                local tb=btn(row,sel and "ON" or "OFF",8,sel and C.TDim or C.Panel,sel and C.Teal or C.Gray)
                tb.Size=UDim2.new(0,44,0,18) tb.Position=UDim2.new(1,-48,0.5,-9)
                local ts=stroke(tb,sel and C.Teal or C.Dim,1.1)
                local cb=base
                tb.MouseButton1Click:Connect(function()
                    if slot.petTypes[cb] then slot.petTypes[cb]=nil else slot.petTypes[cb]=true end
                    local now=slot.petTypes[cb]==true
                    row.BackgroundColor3=now and C.TDim or C.Card
                    local rs=row:FindFirstChildWhichIsA("UIStroke")
                    if now then if rs then rs.Color=C.Teal else stroke(row,C.Teal,1.1) end
                    else if rs then rs:Destroy() end end
                    nl.TextColor3=now and C.Teal or C.White
                    tb.Text=now and "ON" or "OFF" tb.BackgroundColor3=now and C.TDim or C.Panel tb.TextColor3=now and C.Teal or C.Gray ts.Color=now and C.Teal or C.Dim
                    pickLbl.Text="Pilih Jenis Pet ("..countTypes().." = "..countMatching().." pet)"
                    save()
                end)
            end
            if n==0 then local e=lbl(typeScroll,"Backpack kosong",8,C.Red,Enum.TextXAlignment.Center) e.Size=UDim2.new(1,0,0,22) e.LayoutOrder=1 end
        end
        buildTypeList()
        pickCover.MouseButton1Click:Connect(function()
            pickerOpen=not pickerOpen
            picker.Visible=pickerOpen
            picker.Size=pickerOpen and UDim2.new(1,0,0,148) or UDim2.new(1,0,0,0)
            pickArrow.Text=pickerOpen and "^" or "v" pickStroke.Color=pickerOpen and C.Teal or C.Dim
            if pickerOpen then buildTypeList() end
        end)

        -- v8.6: Mutation Filter inline picker (single select, lightweight)
        local function mfText()
            if slot.mutationFilter == "" then return "(Semua mutasi)" end
            if slot.mutationFilter == "__nomut__" then return "[TANPA MUTASI]" end
            return slot.mutationFilter
        end
        local mfOpen=false
        local mfRow=mk("Frame",{Size=UDim2.new(1,0,0,26),BackgroundColor3=C.Card,BorderSizePixel=0,LayoutOrder=5,Parent=parent})
        corner(mfRow,6) local mfStroke=stroke(mfRow,C.Dim,1.1)
        local mfLbl=lbl(mfRow,"Mutasi: "..mfText(),9,C.White) mfLbl.Size=UDim2.new(0.85,0,1,0) mfLbl.Position=UDim2.new(0,10,0,0)
        local mfArrow=lbl(mfRow,"v",9,C.Teal,Enum.TextXAlignment.Right) mfArrow.Size=UDim2.new(0,20,1,0) mfArrow.Position=UDim2.new(1,-24,0,0)
        local mfCover=mk("TextButton",{Size=UDim2.new(1,0,1,0),BackgroundTransparency=1,Text="",AutoButtonColor=false,Parent=mfRow})
        local mfPicker=mk("Frame",{Size=UDim2.new(1,0,0,0),BackgroundColor3=C.BG,BorderSizePixel=0,Visible=false,LayoutOrder=6,Parent=parent})
        corner(mfPicker,6) stroke(mfPicker,C.Teal,1.2)
        mk("UIPadding",{PaddingTop=UDim.new(0,4),PaddingLeft=UDim.new(0,4),PaddingRight=UDim.new(0,4),PaddingBottom=UDim.new(0,4),Parent=mfPicker})
        local mfScroll=mk("ScrollingFrame",{Size=UDim2.new(1,0,0,120),BackgroundTransparency=1,ScrollBarThickness=3,ScrollBarImageColor3=C.Teal,CanvasSize=UDim2.new(0,0,0,0),AutomaticCanvasSize=Enum.AutomaticSize.Y,Parent=mfPicker})
        mk("UIListLayout",{SortOrder=Enum.SortOrder.LayoutOrder,Padding=UDim.new(0,2),Parent=mfScroll})
        local function buildMutationList()
            for _,c in pairs(mfScroll:GetChildren()) do if c:IsA("Frame") then c:Destroy() end end
            local list = {{value="",label="(Semua mutasi)"},{value="__nomut__",label="[TANPA MUTASI]"}}
            for _,prefix in ipairs(MUTATION_PREFIXES) do
                local clean = prefix:gsub("%s+$","")
                if clean ~= "" then table.insert(list,{value=clean,label=clean}) end
            end
            for i,item in ipairs(list) do
                local sel = slot.mutationFilter == item.value
                local row=mk("Frame",{Size=UDim2.new(1,0,0,22),BackgroundColor3=sel and C.TDim or C.Card,BorderSizePixel=0,LayoutOrder=i,Parent=mfScroll})
                corner(row,5) if sel then stroke(row,C.Teal,1.1) end
                local nl=lbl(row,item.label,8,sel and C.Teal or C.White) nl.Size=UDim2.new(1,-12,1,0) nl.Position=UDim2.new(0,8,0,0)
                local cv=item.value
                local cover2=mk("TextButton",{Size=UDim2.new(1,0,1,0),BackgroundTransparency=1,Text="",AutoButtonColor=false,Parent=row})
                cover2.MouseButton1Click:Connect(function()
                    slot.mutationFilter=cv
                    mfLbl.Text="Mutasi: "..mfText()
                    save()
                    buildMutationList()
                end)
            end
        end
        buildMutationList()
        mfCover.MouseButton1Click:Connect(function()
            mfOpen=not mfOpen
            mfPicker.Visible=mfOpen
            mfPicker.Size=mfOpen and UDim2.new(1,0,0,128) or UDim2.new(1,0,0,0)
            mfArrow.Text=mfOpen and "^" or "v" mfStroke.Color=mfOpen and C.Teal or C.Dim
        end)

        local kgRow=mk("Frame",{Size=UDim2.new(1,0,0,26),BackgroundColor3=C.Card,BorderSizePixel=0,LayoutOrder=7,Parent=parent})
        corner(kgRow,6) stroke(kgRow,C.Dim,1.1)
        lbl(kgRow,"KG: -N=bawah, N=atas",9,C.Gray).Size=UDim2.new(0.7,0,1,0)
        local kgBox=mk("TextBox",{Size=UDim2.new(0,60,0,20),Position=UDim2.new(1,-66,0.5,-10),BackgroundColor3=C.Panel,Text=slot.kg,PlaceholderText="-60",PlaceholderColor3=C.Dim,TextColor3=C.White,Font=Enum.Font.GothamBold,TextSize=10,TextScaled=false,TextXAlignment=Enum.TextXAlignment.Center,ClearTextOnFocus=false,Parent=kgRow})
        corner(kgBox,5) stroke(kgBox,C.Dim,1)
        kgBox:GetPropertyChangedSignal("Text"):Connect(function() slot.kg=kgBox.Text save() end)

        local ageRow=mk("Frame",{Size=UDim2.new(1,0,0,26),BackgroundColor3=C.Card,BorderSizePixel=0,LayoutOrder=8,Parent=parent})
        corner(ageRow,6) stroke(ageRow,C.Dim,1.1)
        lbl(ageRow,"Age: -N=bawah, N=atas",9,C.Gray).Size=UDim2.new(0.7,0,1,0)
        local ageBox=mk("TextBox",{Size=UDim2.new(0,60,0,20),Position=UDim2.new(1,-66,0.5,-10),BackgroundColor3=C.Panel,Text=slot.age,PlaceholderText="-100",PlaceholderColor3=C.Dim,TextColor3=C.White,Font=Enum.Font.GothamBold,TextSize=10,TextScaled=false,TextXAlignment=Enum.TextXAlignment.Center,ClearTextOnFocus=false,Parent=ageRow})
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

    sendStatusLbl=lbl(areas[5],"Send: idle",9,C.Gray,Enum.TextXAlignment.Center)
    sendStatusLbl.Size=UDim2.new(1,0,0,18) sendStatusLbl.LayoutOrder=60 sendStatusLbl.BackgroundColor3=C.Panel sendStatusLbl.BackgroundTransparency=0
    corner(sendStatusLbl,5) stroke(sendStatusLbl,C.Dim,1)

    accStatusLbl=lbl(areas[5],"Accept: idle",9,C.Gray,Enum.TextXAlignment.Center)
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
task.spawn(function()
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

    while true do
        for slotIdx=1,3 do
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
                            for _,uuid in ipairs(sendable) do
                                if sendGiftToPlayer(slot.target,uuid) then okCount=okCount+1 end
                                task.wait(0.6)
                            end
                            if sendStatusLbl then
                                sendStatusLbl.Text="Slot "..slotIdx.." gift: "..okCount.."/"..#sendable.." OK"
                                sendStatusLbl.TextColor3=okCount==#sendable and C.Teal or C.Gold
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
-- Trade: SendRequest:OnClientEvent -> RespondRequest(player, true)
-- Gift: hook PetGiftingService:OnClientEvent
-- ============================================
pcall(function()
    if tradeRespondRE then
        local sendReqRE = RS:FindFirstChild("SendRequest", true)
        if sendReqRE and sendReqRE:IsA("RemoteEvent") then
            sendReqRE.OnClientEvent:Connect(function(senderPlayer, ...)
                if autoAccTrade and senderPlayer and typeof(senderPlayer)=="Instance" then
                    task.wait(0.3)
                    pcall(function()
                        tradeRespondRE:FireServer(senderPlayer, true)
                    end)
                    if accStatusLbl then
                        accStatusLbl.Text = "Trade dari "..senderPlayer.Name.." diterima!"
                        accStatusLbl.TextColor3 = C.Teal
                        task.wait(2)
                        if accStatusLbl then accStatusLbl.Text="Accept: idle" accStatusLbl.TextColor3=C.Gray end
                    end
                end
            end)
            dbg("[autoAcc] trade hook installed (SendRequest -> RespondRequest)")
        end
    end

    if giftRE and giftRE:IsA("RemoteEvent") then
        giftRE.OnClientEvent:Connect(function(action, ...)
            if autoAccGift and action then
                local actStr = tostring(action):lower()
                if actStr:find("prompt") or actStr:find("incoming") or actStr:find("offer") then
                    local args = {...}
                    pcall(function()
                        giftRE:FireServer("AcceptGift", table.unpack(args))
                    end)
                    if accStatusLbl then
                        accStatusLbl.Text = "Gift diterima!"
                        accStatusLbl.TextColor3 = C.Teal
                        task.wait(2)
                        if accStatusLbl then accStatusLbl.Text="Accept: idle" accStatusLbl.TextColor3=C.Gray end
                    end
                end
            end
        end)
        dbg("[autoAcc] gift hook installed (PetGiftingService:OnClientEvent)")
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
    for _ in pairs(getFavoriteUUIDs()) do return true end
    return false
end

startTeamKeeper=function()
    if teamKeeperTask then return end
    if not teamKeeperShouldRun() then return end
    teamKeeperTask=task.spawn(function()
        dbg("[teamKeeper] START (handle team + favs via ActivePetUI)")
        while teamKeeperShouldRun() do
            local toCheck={}
            for u in pairs(teamPetUUIDs) do toCheck[u]="tim" end
            for u in pairs(getFavoriteUUIDs()) do
                if not toCheck[u] then toCheck[u]="fav" end
            end
            for uuid,kind in pairs(toCheck) do
                if not isPetInSwap(uuid) and not currentLevelingUUIDs[uuid] then
                    if not isPetEquippedInUI(uuid) then
                        local uuidStr=tostring(uuid)
                        dbg("[teamKeeper] "..kind.." "..uuidStr:sub(1,8).." gak di UI, re-equip")
                        equipPet(uuid)
                        task.wait(0.2)
                    end
                end
            end
            task.wait(2)
        end
        dbg("[teamKeeper] STOP (gak ada team & fav)")
        teamKeeperTask=nil
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

startGlobalPoller=function()
    if pollerTask then return end
    if not pollerShouldRun() then return end
    pollerTask=task.spawn(function()
        dbg("[poller] global poller START")
        local cycles=0
        while pollerShouldRun() do
            cycles=cycles+1
            for uuid,cfg in pairs(swapPerPet) do
                if cfg.enabled and not currentLevelingUUIDs[uuid] then
                    local t=getPetTime(uuid)
                    if t~=nil and t<=0 then
                        local last=lastSwap[uuid] or 0
                        if tick()-last>=1.5 then
                            local info=swapPetInfoCache[uuid] or teamPetInfoCache[uuid]
                            local nm=(info and info.name) or "?"
                            if cycles<=20 then
                                dbg(string.format("[swap] %s Time=%.1f -> SWAP",nm:sub(1,12),t))
                            end
                            swapPet(uuid)
                            lastSwap[uuid]=tick()
                        end
                    end
                end
            end
            if cycles%100==0 then
                local active,ready,idle,skipped=0,0,0,0
                for uuid,cfg in pairs(swapPerPet) do
                    if cfg.enabled then
                        if currentLevelingUUIDs[uuid] then
                            skipped=skipped+1
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
            task.wait(0.05)
        end
        pollerTask=nil
        dbg("[poller] global poller STOP")
    end)
end

local function stopAllSwaps()
    if pollerTask then
        pcall(task.cancel,pollerTask)
        pollerTask=nil
    end
    lastSwap={}
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
    local processed={}
    local removed=0
    local function tryPickup(model)
        if not model or not model:IsA("Model") then return false end
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
        if uuidNoBrace and #uuidNoBrace>=20 and not processed[uuidNoBrace] then
            processed[uuidNoBrace]=true
            pcall(function() unequipPet(uuidNoBrace) end)
            removed=removed+1
            return true
        end
        return false
    end
    local petMover=petsPhys:FindFirstChild("PetMover")
    if petMover then
        for _,m in ipairs(petMover:GetChildren()) do
            if tryPickup(m) then task.wait(0.05) end
        end
    end
    for _,m in ipairs(petsPhys:GetDescendants()) do
        if tryPickup(m) then task.wait(0.05) end
    end
    for _,n in ipairs({"Pets","PlacedPets","ActivePets","PetMover"}) do
        local f=workspace:FindFirstChild(n)
        if f then
            for _,m in ipairs(f:GetDescendants()) do
                if tryPickup(m) then task.wait(0.05) end
            end
        end
    end
    dbg("[pickup] total: "..removed.." pet di-pickup dari garden")
    return removed
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
    for attempt=1,3 do
        local removed=pickupAllGardenPets()
        totalRemoved=totalRemoved+removed
        if removed>0 then
            dbg("[doStart] pickup attempt "..attempt..": "..removed.." pet")
            task.wait(math.min(1.5,0.3+removed*0.05))
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
        task.wait(0.1)
    end
    if teamPlaced>0 then
        dbg("[doStart] tim "..teamPlaced.." pet di-place")
        task.wait(0.3)
    end

    statusLbl.Text="Pasang pet favorit..." statusLbl.TextColor3=C.Gold
    local favPlaced=0
    for uuid in pairs(getFavoriteUUIDs()) do
        equipPet(uuid)
        favPlaced=favPlaced+1
        task.wait(0.1)
    end
    if favPlaced>0 then
        dbg("[doStart] favorit "..favPlaced.." pet di-place")
        task.wait(0.3)
    end

    local queue=getQueue()
    if #queue==0 then
        dbg("[doStart] FAIL: queue kosong")
        statusLbl.Text="Tidak ada pet target!" statusLbl.TextColor3=C.Red
        return
    end

    isRunning=true setRunning(true)
    statusLbl.Text="Berjalan... Q:"..#queue statusLbl.TextColor3=C.Teal

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
                task.wait(0.1)
            end

            if #doneList>0 then
                dbg("[monitor] "..#doneList.." pet selesai, tunggu 0.5s")
                task.wait(0.5)
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

            if slotsUsed==0 and #available==0 then
                doStop("Semua pet selesai Age "..toAge.."!")
                statusLbl.TextColor3=C.Green buildTargetList() break
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
                        task.wait(0.3)
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
                local ageStr=age and (age.."/"..toAge) or ("?/"..toAge)
                table.insert(activeNames,nameStr.." "..ageStr)
            end
            if #activeNames>0 then
                statusLbl.Text="Lvl: "..table.concat(activeNames,", ").." | Q:"..#available
            else
                statusLbl.Text="Tunggu pet target... Q:"..#available
            end
            statusLbl.TextColor3=C.Teal

            task.wait(3)
        end
    end)
end

runBtn.MouseButton1Click:Connect(function() doStart() end)
stopBtn.MouseButton1Click:Connect(function() doStop("Dihentikan") end)

closeBtn.MouseButton1Click:Connect(function()
    local overlay=mk("Frame",{Size=UDim2.new(1,0,1,0),BackgroundColor3=Color3.fromRGB(0,0,0),BackgroundTransparency=0.5,BorderSizePixel=0,ZIndex=10,Parent=main})
    local modal=mk("Frame",{Size=UDim2.new(0,300,0,140),Position=UDim2.new(0.5,-150,0.5,-70),BackgroundColor3=C.Panel,BorderSizePixel=0,ZIndex=11,Parent=overlay})
    corner(modal,10) stroke(modal,C.Red,2)
    local title=lbl(modal,"YAKIN MAU CLOSE?",11,C.Red,Enum.TextXAlignment.Center)
    title.Size=UDim2.new(1,0,0,28) title.Position=UDim2.new(0,0,0,10) title.ZIndex=11
    local msg=lbl(modal,"Semua aktivitas akan dihentikan & GUI ditutup.",8,C.Gray,Enum.TextXAlignment.Center)
    msg.Size=UDim2.new(1,-20,0,40) msg.Position=UDim2.new(0,10,0,40) msg.TextWrapped=true msg.ZIndex=11
    local yaBtn=btn(modal,"YA, CLOSE",10,C.RDim,C.Red)
    yaBtn.Size=UDim2.new(0,120,0,28) yaBtn.Position=UDim2.new(0.5,-130,1,-40) yaBtn.ZIndex=11 stroke(yaBtn,C.Red,1.5)
    local noBtn=btn(modal,"BATAL",10,C.Card,C.White)
    noBtn.Size=UDim2.new(0,120,0,28) noBtn.Position=UDim2.new(0.5,10,1,-40) noBtn.ZIndex=11 stroke(noBtn,C.Dim,1.5)
    noBtn.MouseButton1Click:Connect(function() overlay:Destroy() end)
    yaBtn.MouseButton1Click:Connect(function()
        for _,slot in ipairs(giftSlots) do
            slot.autoSendGift=false slot.autoSendTrade=false slot.autoUnfav=false
        end
        autoAccGift=false autoAccTrade=false
        for _,cfg in pairs(swapPerPet) do
            cfg.enabled=false
        end
        stopAllSwaps()
        if isAR then stopAR() end
        if isRunning then doStop("Closed") end
        save()
        task.wait(0.3)
        sg:Destroy()
        if playerGui:FindFirstChild("ZenxShowBtn") then playerGui.ZenxShowBtn:Destroy() end
        print("[ZenxLvl] Closed - all activity stopped")
    end)
end)

task.wait(1)
if autoRejoin then startAR() end
if autoStartEnabled then doStart() end

do
    local anyEnabled=false
    for _,cfg in pairs(swapPerPet) do
        if cfg.enabled then anyEnabled=true break end
    end
    if anyEnabled then
        dbg("[init] auto-start poller (saved swap-ON)")
        startGlobalPoller()
    end
end

do
    local hasTeam=false
    for _ in pairs(teamPetUUIDs) do hasTeam=true break end
    local hasFavs=false
    for _ in pairs(getFavoriteUUIDs()) do hasFavs=true break end
    if hasTeam or hasFavs then
        dbg("[init] auto-start teamKeeper (team="..tostring(hasTeam)..", favs="..tostring(hasFavs)..")")
        startTeamKeeper()
    end
end

print("ZenxLvl "..SCRIPT_VERSION.." loaded! v8.9: target picker bisa di-batalin (klik nama yg sama / pilih (Batalin pilihan))")
