local RS = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local TS = game:GetService("TeleportService")
local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

if playerGui:FindFirstChild("ZenxLvlGui") then playerGui.ZenxLvlGui:Destroy() end
if playerGui:FindFirstChild("ZenxShowBtn") then playerGui.ZenxShowBtn:Destroy() end

local petsService = RS:FindFirstChild("PetsService",true)

if not getgenv().ZenxData then
    getgenv().ZenxData={
        swapPerPet={},
        swapConfig={swapDelay=0.1,pickupDelay=0.6,placeDelay=0},
        config={equipInterval=5,rejoinMinutes=30},
        targetPetType="(Semua Pet)",
        fromAge=1,toAge=100,maxPetTarget=1,
        autoStartEnabled=false,autoAccGift=false,autoAccTrade=false,
    }
end
local d=getgenv().ZenxData

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
local function getAge(item)
    for _,pat in ipairs({"%[Age%s+(%d+)%]","%[Age(%d+)%]"}) do
        local f=item.Name:match(pat) if f then return tonumber(f) end
    end return nil
end
local function getPetName(item) return item.Name:match("^(.-)%s*%[") or item.Name end
local function getKG(item) return tonumber(item.Name:match("%[([%d%.]+)%s*[Kk][Gg]%]")) end
local function getPetUUID(item) return item:GetAttribute("PET_UUID") end
local function getNameKey(item)
    local kg=getKG(item)
    return getPetName(item)..(kg and ("|"..tostring(kg)) or "")
end

-- GUI 400x720
local GUI_W=400 local GUI_H=720
local sg=mk("ScreenGui",{Name="ZenxLvlGui",DisplayOrder=999,ResetOnSpawn=false,Parent=playerGui})
local main=mk("Frame",{Size=UDim2.new(0,GUI_W,0,GUI_H),Position=UDim2.new(0.5,-GUI_W/2,0.5,-GUI_H/2),
    BackgroundColor3=C.BG,BorderSizePixel=0,Active=true,Draggable=true,Parent=sg})
corner(main,10) stroke(main,C.Teal,2)

-- Titlebar
local TB=mk("Frame",{Size=UDim2.new(1,0,0,34),BackgroundColor3=C.Panel,BorderSizePixel=0,Parent=main})
corner(TB,10)
mk("Frame",{Size=UDim2.new(1,0,0,1.5),Position=UDim2.new(0,0,1,-1.5),BackgroundColor3=C.Teal,BorderSizePixel=0,Parent=TB})
local TT=lbl(TB,"ZENX AUTO LEVELING",11,C.Teal) TT.Size=UDim2.new(1,-80,1,0) TT.Position=UDim2.new(0,10,0,0)

local minBtn=btn(TB,"−",13,C.Panel,C.Gray)
minBtn.Size=UDim2.new(0,22,0,22) minBtn.Position=UDim2.new(1,-50,0.5,-11) stroke(minBtn,C.Dim,1.2)

local hideBtn=btn(TB,"✕",10,C.RDim,C.Red)
hideBtn.Size=UDim2.new(0,22,0,22) hideBtn.Position=UDim2.new(1,-24,0.5,-11) stroke(hideBtn,C.Red,1.2)

-- Content
local content=mk("Frame",{Size=UDim2.new(1,0,1,-34),Position=UDim2.new(0,0,0,34),BackgroundTransparency=1,Parent=main})

-- Tabs
local tabBar=mk("Frame",{Size=UDim2.new(1,-10,0,26),Position=UDim2.new(0,5,0,4),BackgroundTransparency=1,Parent=content})
mk("UIListLayout",{FillDirection=Enum.FillDirection.Horizontal,Padding=UDim.new(0,2),Parent=tabBar})

local tabNames={"Tim Leveling","Pet ke 100","Swap Skill","Other Setting"}
local tabBtns={}

local function makeScroll(yPos,height)
    local s=mk("ScrollingFrame",{Size=UDim2.new(1,-10,0,height),Position=UDim2.new(0,5,0,yPos),
        BackgroundTransparency=1,ScrollBarThickness=3,ScrollBarImageColor3=C.Teal,
        CanvasSize=UDim2.new(0,0,0,0),AutomaticCanvasSize=Enum.AutomaticSize.Y,Visible=false,Parent=content})
    mk("UIListLayout",{SortOrder=Enum.SortOrder.LayoutOrder,Padding=UDim.new(0,3),Parent=s})
    mk("UIPadding",{PaddingTop=UDim.new(0,4),PaddingLeft=UDim.new(0,3),PaddingRight=UDim.new(0,3),Parent=s})
    return s
end

local SCROLL_Y=34
local SCROLL_H=GUI_H-34-70 -- sisakan untuk statusbar dan tombol
local areas={} for i=1,4 do areas[i]=makeScroll(SCROLL_Y,SCROLL_H) end

local botBar=mk("Frame",{Size=UDim2.new(1,-10,0,28),Position=UDim2.new(0,5,0,SCROLL_Y+SCROLL_H+4),BackgroundColor3=C.Panel,BorderSizePixel=0,Parent=content})
corner(botBar,7) stroke(botBar,C.Dim,1.2)
local statusLbl=lbl(botBar,"Status: Idle",9,C.Gray,Enum.TextXAlignment.Left)
statusLbl.Size=UDim2.new(1,-10,1,0) statusLbl.Position=UDim2.new(0,8,0,0)

local BOT_Y=SCROLL_Y+SCROLL_H+36
local runBtn=btn(content,"▶ RUNNING",10,C.Panel,C.Gray)
runBtn.Size=UDim2.new(0,170,0,26) runBtn.Position=UDim2.new(0,5,0,BOT_Y)
local runStroke=stroke(runBtn,C.Dim,1.5)
local stopBtn=btn(content,"■ STOP",10,C.Panel,C.Gray)
stopBtn.Size=UDim2.new(0,100,0,26) stopBtn.Position=UDim2.new(0,180,0,BOT_Y)
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
    b.Size=UDim2.new(0,93,1,0) b.LayoutOrder=i stroke(b,C.Dim,1.1) tabBtns[i]=b
    local ii=i b.MouseButton1Click:Connect(function() switchTab(ii) end)
end

-- Minimize
local minimized=false
minBtn.MouseButton1Click:Connect(function()
    minimized=not minimized
    content.Visible=not minimized
    main.Size=minimized and UDim2.new(0,GUI_W,0,34) or UDim2.new(0,GUI_W,0,GUI_H)
    minBtn.Text=minimized and "+" or "−"
end)

-- Hide (sembunyikan, bisa dibuka lagi)
hideBtn.MouseButton1Click:Connect(function()
    main.Visible=false
    local showSg=mk("ScreenGui",{Name="ZenxShowBtn",DisplayOrder=998,ResetOnSpawn=false,Parent=playerGui})
    local showBtn=btn(showSg,"ZenxLvl",9,C.TDim,C.Teal)
    showBtn.Size=UDim2.new(0,70,0,22) showBtn.Position=UDim2.new(0,5,0.5,-11)
    stroke(showBtn,C.Teal,1.5)
    showBtn.MouseButton1Click:Connect(function()
        main.Visible=true showSg:Destroy()
    end)
end)

-- DATA
local teamPets={}
local swapPerPet=d.swapPerPet
local swapConfig=d.swapConfig
local config=d.config
local targetPetType=d.targetPetType
local fromAge=d.fromAge
local toAge=d.toAge
local maxPetTarget=d.maxPetTarget
local autoStartEnabled=d.autoStartEnabled
local autoAccGift=d.autoAccGift
local autoAccTrade=d.autoAccTrade
local isRunning=false
local mainTask=nil local monitorTask=nil local swapTask=nil
local isAR=false local arTask=nil
local accStatus=nil
local arTog2,arTogStroke2,arStroke2,cdLbl2

local function save()
    d.swapPerPet=swapPerPet d.swapConfig=swapConfig d.config=config
    d.targetPetType=targetPetType d.fromAge=fromAge d.toAge=toAge
    d.maxPetTarget=maxPetTarget d.autoStartEnabled=autoStartEnabled
    d.autoAccGift=autoAccGift d.autoAccTrade=autoAccTrade
end

-- ============================================
-- TAB 1: TIM LEVELING
-- ============================================
local function buildTimList()
    for _,c in pairs(areas[1]:GetChildren()) do
        if c:IsA("Frame") or c:IsA("TextButton") or c:IsA("TextLabel") then c:Destroy() end
    end
    lbl(areas[1],"Pilih pet favorit ⭐ untuk tim leveling:",9,C.Gray).Size=UDim2.new(1,0,0,14)
    local bp=player:FindFirstChild("Backpack") if not bp then return end
    local n=0 local favCount=0
    for _,item in pairs(bp:GetChildren()) do
        if isPet(item) and item:GetAttribute("d")==true then
            favCount=favCount+1 n=n+1
            local inTeam=false
            for _,t in ipairs(teamPets) do if t==item then inTeam=true break end end
            local age=getAge(item) local kg=getKG(item)
            local name=getPetName(item)
            local info=age and (" | Age "..age) or ""
            if kg then info=info.." | "..kg.."kg" end
            local card=mk("Frame",{Size=UDim2.new(1,0,0,26),BackgroundColor3=inTeam and C.TDim or C.Card,BorderSizePixel=0,LayoutOrder=n,Parent=areas[1]})
            corner(card,6) if inTeam then stroke(card,C.Teal,1.3) end
            local ico=lbl(card,"⭐",9,C.Gold) ico.Size=UDim2.new(0,18,1,0) ico.Position=UDim2.new(0,4,0,0) ico.TextXAlignment=Enum.TextXAlignment.Center
            local nl=lbl(card,name..info,9,inTeam and C.Teal or C.White) nl.Size=UDim2.new(0.8,0,1,0) nl.Position=UDim2.new(0,24,0,0)
            local chk=lbl(card,inTeam and "✔" or "",10,C.Teal,Enum.TextXAlignment.Right) chk.Size=UDim2.new(0,18,1,0) chk.Position=UDim2.new(1,-22,0,0)
            local cb=mk("TextButton",{Size=UDim2.new(1,0,1,0),BackgroundTransparency=1,Text="",AutoButtonColor=false,Parent=card})
            cb.MouseButton1Click:Connect(function()
                local found=false
                for i,t in ipairs(teamPets) do if t==item then table.remove(teamPets,i) found=true break end end
                if not found then table.insert(teamPets,item) end
                buildTimList()
            end)
        end
    end
    if favCount==0 then
        local e=lbl(areas[1],"⚠️ Tidak ada pet favorit di backpack",9,C.Red,Enum.TextXAlignment.Center)
        e.Size=UDim2.new(1,0,0,22) e.LayoutOrder=1
    end
    local info2=lbl(areas[1],"Tim: "..#teamPets.." pet dipilih",9,C.Teal,Enum.TextXAlignment.Center)
    info2.Size=UDim2.new(1,0,0,14) info2.LayoutOrder=n+2
    div(areas[1],n+3)
    local rf=btn(areas[1],"🔄 Refresh",10,C.Panel,C.White)
    rf.Size=UDim2.new(1,0,0,24) rf.LayoutOrder=n+4 stroke(rf,C.Dim,1.2)
    rf.MouseButton1Click:Connect(function() teamPets={} buildTimList() end)
end

-- ============================================
-- TAB 2: PET KE 100
-- ============================================
local function buildTargetList()
    for _,c in pairs(areas[2]:GetChildren()) do
        if c:IsA("Frame") or c:IsA("TextButton") or c:IsA("TextLabel") then c:Destroy() end
    end
    local bp=player:FindFirstChild("Backpack")
    local petNames={"(Semua Pet)"} local nameSet={}
    if bp then
        for _,item in pairs(bp:GetChildren()) do
            if isPet(item) then
                local name=getPetName(item)
                if not nameSet[name] then nameSet[name]=true table.insert(petNames,name) end
            end
        end
        table.sort(petNames,function(a,b)
            if a=="(Semua Pet)" then return true end
            if b=="(Semua Pet)" then return false end
            return a<b
        end)
    end
    lbl(areas[2],"Pilih jenis pet yang mau di-level:",9,C.Gray).Size=UDim2.new(1,0,0,14)
    local typeRow=mk("Frame",{Size=UDim2.new(1,0,0,26),BackgroundColor3=C.Card,BorderSizePixel=0,LayoutOrder=1,Parent=areas[2]})
    corner(typeRow,6) stroke(typeRow,C.Dim,1.1)
    lbl(typeRow,"Jenis Pet:",9,C.Gray).Size=UDim2.new(0.35,0,1,0)
    local typeBtn=btn(typeRow,targetPetType,9,C.Panel,C.White)
    typeBtn.Size=UDim2.new(0.62,0,0,20) typeBtn.Position=UDim2.new(0.37,0,0.5,-10)
    typeBtn.TextXAlignment=Enum.TextXAlignment.Left
    mk("UIPadding",{PaddingLeft=UDim.new(0,6),Parent=typeBtn}) stroke(typeBtn,C.Dim,1)
    local typePicker=mk("Frame",{Size=UDim2.new(1,0,0,0),BackgroundColor3=C.Panel,BorderSizePixel=0,Visible=false,LayoutOrder=2,Parent=areas[2]})
    corner(typePicker,6) stroke(typePicker,C.Blue,1.2)
    mk("UIPadding",{PaddingTop=UDim.new(0,3),PaddingLeft=UDim.new(0,4),PaddingRight=UDim.new(0,4),PaddingBottom=UDim.new(0,3),Parent=typePicker})
    mk("UIListLayout",{SortOrder=Enum.SortOrder.LayoutOrder,Padding=UDim.new(0,2),Parent=typePicker})
    local searchBox=mk("TextBox",{Size=UDim2.new(1,0,0,22),BackgroundColor3=C.Card,Text="",PlaceholderText="Cari jenis pet...",PlaceholderColor3=C.Dim,TextColor3=C.White,Font=Enum.Font.Gotham,TextSize=9,TextScaled=false,ClearTextOnFocus=false,LayoutOrder=0,Parent=typePicker})
    corner(searchBox,5) stroke(searchBox,C.Dim,1) mk("UIPadding",{PaddingLeft=UDim.new(0,6),Parent=searchBox})
    local petScroll=mk("ScrollingFrame",{Size=UDim2.new(1,0,0,80),BackgroundTransparency=1,ScrollBarThickness=3,ScrollBarImageColor3=C.Teal,CanvasSize=UDim2.new(0,0,0,0),AutomaticCanvasSize=Enum.AutomaticSize.Y,LayoutOrder=1,Parent=typePicker})
    mk("UIListLayout",{SortOrder=Enum.SortOrder.LayoutOrder,Padding=UDim.new(0,2),Parent=petScroll})
    local typeOpen=false
    local function buildPetPicker(filter)
        for _,c in pairs(petScroll:GetChildren()) do if c:IsA("TextButton") then c:Destroy() end end
        local n=0
        for _,pname in ipairs(petNames) do
            local show=filter=="" or pname:lower():find(filter:lower(),1,true)
            if show then
                n=n+1
                local isSel=targetPetType==pname
                local b=btn(petScroll,pname,9,isSel and C.TDim or C.Card,isSel and C.Teal or C.White)
                b.Size=UDim2.new(1,-4,0,20) b.LayoutOrder=n b.TextXAlignment=Enum.TextXAlignment.Left
                mk("UIPadding",{PaddingLeft=UDim.new(0,6),Parent=b})
                b.MouseButton1Click:Connect(function()
                    targetPetType=pname d.targetPetType=pname typeBtn.Text=pname
                    typePicker.Visible=false typeOpen=false typePicker.Size=UDim2.new(1,0,0,0)
                    buildTargetList()
                end)
            end
        end
    end
    buildPetPicker("")
    searchBox:GetPropertyChangedSignal("Text"):Connect(function() buildPetPicker(searchBox.Text) end)
    typeBtn.MouseButton1Click:Connect(function()
        typeOpen=not typeOpen typePicker.Visible=typeOpen
        typePicker.Size=typeOpen and UDim2.new(1,0,0,130) or UDim2.new(1,0,0,0)
    end)
    div(areas[2],3)
    local function numRow2(labelTxt,lo,default,onChange)
        local r=mk("Frame",{Size=UDim2.new(1,0,0,26),BackgroundColor3=C.Card,BorderSizePixel=0,LayoutOrder=lo,Parent=areas[2]})
        corner(r,6) stroke(r,C.Dim,1.1)
        lbl(r,labelTxt,9,C.Gray).Size=UDim2.new(0.55,0,1,0)
        local box=mk("TextBox",{Size=UDim2.new(0,44,0,20),Position=UDim2.new(1,-50,0.5,-10),BackgroundColor3=C.Panel,Text=tostring(default),TextColor3=C.White,Font=Enum.Font.GothamBold,TextSize=10,TextScaled=false,TextXAlignment=Enum.TextXAlignment.Center,ClearTextOnFocus=false,Parent=r})
        corner(box,5) stroke(box,C.Dim,1)
        box:GetPropertyChangedSignal("Text"):Connect(function() local v=tonumber(box.Text) if v then onChange(v) save() end end)
    end
    numRow2("Dari Age:",4,fromAge,function(v) fromAge=math.max(1,math.min(99,v)) d.fromAge=fromAge end)
    numRow2("Sampai Age:",5,toAge,function(v) toAge=math.max(1,math.min(100,v)) d.toAge=toAge end)
    local pcRow=mk("Frame",{Size=UDim2.new(1,0,0,26),BackgroundColor3=C.Card,BorderSizePixel=0,LayoutOrder=6,Parent=areas[2]})
    corner(pcRow,6) stroke(pcRow,C.Dim,1.1)
    lbl(pcRow,"Jumlah Pet (sekaligus):",9,C.Gray).Size=UDim2.new(0.55,0,1,0)
    local pcMin=btn(pcRow,"−",12,C.Panel,C.Gray) pcMin.Size=UDim2.new(0,20,0,18) pcMin.Position=UDim2.new(1,-68,0.5,-9) stroke(pcMin,C.Dim,1.1)
    local pcNum=lbl(pcRow,tostring(maxPetTarget),10,C.White,Enum.TextXAlignment.Center) pcNum.Size=UDim2.new(0,22,1,0) pcNum.Position=UDim2.new(1,-46,0,0) pcNum.Font=Enum.Font.GothamBold
    local pcPlus=btn(pcRow,"+",12,C.Panel,C.Gray) pcPlus.Size=UDim2.new(0,20,0,18) pcPlus.Position=UDim2.new(1,-22,0.5,-9) stroke(pcPlus,C.Dim,1.1)
    pcMin.MouseButton1Click:Connect(function() if maxPetTarget>1 then maxPetTarget=maxPetTarget-1 d.maxPetTarget=maxPetTarget pcNum.Text=tostring(maxPetTarget) save() end end)
    pcPlus.MouseButton1Click:Connect(function() if maxPetTarget<10 then maxPetTarget=maxPetTarget+1 d.maxPetTarget=maxPetTarget pcNum.Text=tostring(maxPetTarget) save() end end)
    div(areas[2],7)
    local rf=btn(areas[2],"🔄 Refresh",10,C.Panel,C.White)
    rf.Size=UDim2.new(1,0,0,22) rf.LayoutOrder=8 stroke(rf,C.Dim,1.2)
    rf.MouseButton1Click:Connect(function() buildTargetList() end)
end

-- ============================================
-- TAB 3: SWAP SKILL CONFIG
-- ============================================
local function buildSwapList()
    for _,c in pairs(areas[3]:GetChildren()) do
        if c:IsA("Frame") or c:IsA("TextButton") or c:IsA("TextLabel") then c:Destroy() end
    end
    local delayCard=mk("Frame",{Size=UDim2.new(1,0,0,118),BackgroundColor3=C.Panel,BorderSizePixel=0,LayoutOrder=0,Parent=areas[3]})
    corner(delayCard,7) stroke(delayCard,C.Teal,1.2)
    mk("UIListLayout",{SortOrder=Enum.SortOrder.LayoutOrder,Padding=UDim.new(0,2),Parent=delayCard})
    mk("UIPadding",{PaddingTop=UDim.new(0,5),PaddingLeft=UDim.new(0,5),PaddingRight=UDim.new(0,5),PaddingBottom=UDim.new(0,5),Parent=delayCard})
    lbl(delayCard,"Global Delay",9,C.Teal).Size=UDim2.new(1,0,0,13)
    local function numRowG(parent,labelTxt,descTxt,default,lo,onChange)
        local r=mk("Frame",{Size=UDim2.new(1,0,0,26),BackgroundColor3=C.Card,BorderSizePixel=0,LayoutOrder=lo,Parent=parent})
        corner(r,6) stroke(r,C.Dim,1.1)
        local ll=lbl(r,labelTxt,9,C.White) ll.Size=UDim2.new(0.5,0,0,14) ll.Position=UDim2.new(0,8,0,1)
        local dl=lbl(r,descTxt,7,C.Dim) dl.Size=UDim2.new(0.6,0,0,11) dl.Position=UDim2.new(0,8,0,14)
        local box=mk("TextBox",{Size=UDim2.new(0,56,0,20),Position=UDim2.new(1,-62,0.5,-10),BackgroundColor3=C.Panel,Text=tostring(default),TextColor3=C.White,Font=Enum.Font.GothamBold,TextSize=10,TextScaled=false,TextXAlignment=Enum.TextXAlignment.Center,ClearTextOnFocus=false,Parent=r})
        corner(box,5) stroke(box,C.Dim,1)
        box:GetPropertyChangedSignal("Text"):Connect(function() local v=tonumber(box.Text) if v then onChange(math.max(0,v)) save() end end)
    end
    numRowG(delayCard,"Swap Delay","Min delay between swaps",swapConfig.swapDelay,1,function(v) swapConfig.swapDelay=v end)
    numRowG(delayCard,"Pickup Delay","Delay setelah skill sebelum pickup",swapConfig.pickupDelay,2,function(v) swapConfig.pickupDelay=v end)
    numRowG(delayCard,"Place Delay","Delay setelah pickup sebelum place",swapConfig.placeDelay,3,function(v) swapConfig.placeDelay=v end)
    local applyBtn=btn(delayCard,"Apply Global ke Semua Pet",9,C.TDim,C.Teal)
    applyBtn.Size=UDim2.new(1,0,0,20) applyBtn.LayoutOrder=4 stroke(applyBtn,C.Teal,1.2)
    applyBtn.MouseButton1Click:Connect(function()
        for _,ps in pairs(swapPerPet) do ps.pickup=swapConfig.pickupDelay ps.place=swapConfig.placeDelay end
        save() buildSwapList()
    end)
    local searchBox=mk("TextBox",{Size=UDim2.new(1,0,0,24),BackgroundColor3=C.Panel,Text="",PlaceholderText="Search pet name...",PlaceholderColor3=C.Dim,TextColor3=C.White,Font=Enum.Font.Gotham,TextSize=9,TextScaled=false,ClearTextOnFocus=false,LayoutOrder=1,Parent=areas[3]})
    corner(searchBox,6) stroke(searchBox,C.Dim,1.1) mk("UIPadding",{PaddingLeft=UDim.new(0,8),Parent=searchBox})
    div(areas[3],2)
    local thead=mk("Frame",{Size=UDim2.new(1,0,0,18),BackgroundColor3=C.Panel,BorderSizePixel=0,LayoutOrder=3,Parent=areas[3]})
    corner(thead,5)
    lbl(thead,"PET",8,C.Gray).Size=UDim2.new(0.38,0,1,0)
    local thPk=lbl(thead,"Pickup",8,C.Gray,Enum.TextXAlignment.Center) thPk.Size=UDim2.new(0.19,0,1,0) thPk.Position=UDim2.new(0.38,0,0,0)
    local thPl=lbl(thead,"Place",8,C.Gray,Enum.TextXAlignment.Center) thPl.Size=UDim2.new(0.19,0,1,0) thPl.Position=UDim2.new(0.57,0,0,0)
    local thOn=lbl(thead,"ON/OFF",8,C.Gray,Enum.TextXAlignment.Center) thOn.Size=UDim2.new(0.24,0,1,0) thOn.Position=UDim2.new(0.76,0,0,0)
    local function buildSwapPetList(filter)
        for _,c in pairs(areas[3]:GetChildren()) do
            if c:IsA("Frame") and c.LayoutOrder>=4 then c:Destroy() end
        end
        local bp=player:FindFirstChild("Backpack")
        local n=3 local total=0
        if bp then
            for _,item in pairs(bp:GetChildren()) do
                if isPet(item) and item:GetAttribute("d")==true then
                    local nameKey=getNameKey(item)
                    local name=getPetName(item)
                    local age=getAge(item) local kg=getKG(item)
                    local show=filter=="" or name:lower():find(filter:lower(),1,true)
                    if show then
                        total=total+1 n=n+1
                        if not swapPerPet[nameKey] then
                            swapPerPet[nameKey]={pickup=swapConfig.pickupDelay,place=swapConfig.placeDelay,enabled=false}
                        end
                        local ps=swapPerPet[nameKey]
                        local petInfo=name
                        if age then petInfo=petInfo.." | Age "..age end
                        if kg then petInfo=petInfo.." | "..kg.."kg" end
                        local row=mk("Frame",{Size=UDim2.new(1,0,0,28),BackgroundColor3=ps.enabled and C.TDim or C.Card,BorderSizePixel=0,LayoutOrder=n,Parent=areas[3]})
                        corner(row,5) if ps.enabled then stroke(row,C.Teal,1.2) end
                        local petLbl=lbl(row,petInfo,8,ps.enabled and C.White or C.Gray)
                        petLbl.Size=UDim2.new(0.37,0,1,0) petLbl.Position=UDim2.new(0,2,0,0)
                        local pkBox=mk("TextBox",{Size=UDim2.new(0.17,0,0,18),Position=UDim2.new(0.38,2,0.5,-9),BackgroundColor3=C.Panel,Text=tostring(ps.pickup),TextColor3=C.White,Font=Enum.Font.Gotham,TextSize=9,TextScaled=false,TextXAlignment=Enum.TextXAlignment.Center,ClearTextOnFocus=false,Parent=row})
                        corner(pkBox,4) stroke(pkBox,C.Dim,1)
                        pkBox:GetPropertyChangedSignal("Text"):Connect(function() local v=tonumber(pkBox.Text) if v then ps.pickup=math.max(0,v) save() end end)
                        local plBox=mk("TextBox",{Size=UDim2.new(0.17,0,0,18),Position=UDim2.new(0.57,2,0.5,-9),BackgroundColor3=C.Panel,Text=tostring(ps.place),TextColor3=C.White,Font=Enum.Font.Gotham,TextSize=9,TextScaled=false,TextXAlignment=Enum.TextXAlignment.Center,ClearTextOnFocus=false,Parent=row})
                        corner(plBox,4) stroke(plBox,C.Dim,1)
                        plBox:GetPropertyChangedSignal("Text"):Connect(function() local v=tonumber(plBox.Text) if v then ps.place=math.max(0,v) save() end end)
                        local selTog=btn(row,ps.enabled and "ON" or "OFF",8,ps.enabled and C.TDim or C.Panel,ps.enabled and C.Teal or C.Gray)
                        selTog.Size=UDim2.new(0.22,0,0,18) selTog.Position=UDim2.new(0.77,2,0.5,-9)
                        local selStroke=stroke(selTog,ps.enabled and C.Teal or C.Dim,1.1)
                        selTog.MouseButton1Click:Connect(function()
                            ps.enabled=not ps.enabled
                            if ps.enabled then
                                selTog.Text="ON" selTog.BackgroundColor3=C.TDim selTog.TextColor3=C.Teal selStroke.Color=C.Teal
                                row.BackgroundColor3=C.TDim
                                local rs=row:FindFirstChildWhichIsA("UIStroke") if rs then rs.Color=C.Teal else stroke(row,C.Teal,1.2) end
                            else
                                selTog.Text="OFF" selTog.BackgroundColor3=C.Panel selTog.TextColor3=C.Gray selStroke.Color=C.Dim
                                row.BackgroundColor3=C.Card
                                local rs=row:FindFirstChildWhichIsA("UIStroke") if rs then rs:Destroy() end
                            end
                            save()
                        end)
                    end
                end
            end
        end
        if total==0 then
            local e=lbl(areas[3],"Tidak ada pet favorit di backpack",8,C.Red,Enum.TextXAlignment.Center)
            e.Size=UDim2.new(1,0,0,22) e.LayoutOrder=4
        end
        div(areas[3],200)
        local rf=btn(areas[3],"Refresh",9,C.Panel,C.White) rf.Size=UDim2.new(1,0,0,22) rf.LayoutOrder=201 stroke(rf,C.Dim,1.2)
        rf.MouseButton1Click:Connect(function() buildSwapPetList(searchBox.Text) end)
        local clr=btn(areas[3],"Clear Semua",9,C.RDim,C.Red) clr.Size=UDim2.new(1,0,0,22) clr.LayoutOrder=202 stroke(clr,C.Red,1.2)
        clr.MouseButton1Click:Connect(function()
            for _,ps in pairs(swapPerPet) do ps.enabled=false end
            save() buildSwapPetList(searchBox.Text)
        end)
    end
    buildSwapPetList("")
    searchBox:GetPropertyChangedSignal("Text"):Connect(function() buildSwapPetList(searchBox.Text) end)
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
    cfgRow("Equip Interval (dtk)",1,config.equipInterval,function(v) config.equipInterval=math.max(1,v) end)
    local _,asTog,asTogStroke,asStroke2=togRow(areas[4],"Auto Start Leveling","Auto mulai saat script dijalankan",2)
    asTog.Text=autoStartEnabled and "ON" or "OFF" asTog.BackgroundColor3=autoStartEnabled and C.TDim or C.Panel asTog.TextColor3=autoStartEnabled and C.Teal or C.Gray asTogStroke.Color=autoStartEnabled and C.Teal or C.Dim asStroke2.Color=autoStartEnabled and C.Teal or C.Dim
    asTog.MouseButton1Click:Connect(function()
        autoStartEnabled=not autoStartEnabled d.autoStartEnabled=autoStartEnabled
        if autoStartEnabled then asTog.Text="ON" asTog.BackgroundColor3=C.TDim asTog.TextColor3=C.Teal asTogStroke.Color=C.Teal asStroke2.Color=C.Teal
        else asTog.Text="OFF" asTog.BackgroundColor3=C.Panel asTog.TextColor3=C.Gray asTogStroke.Color=C.Dim asStroke2.Color=C.Dim end
        save()
    end)

    div(areas[4],3)
    local t2=lbl(areas[4],"REJOIN",9,C.Teal) t2.Size=UDim2.new(1,0,0,14) t2.LayoutOrder=4
    local rnBtn=btn(areas[4],"Rejoin Now",10,C.TDim,C.Teal)
    rnBtn.Size=UDim2.new(1,0,0,24) rnBtn.LayoutOrder=5 stroke(rnBtn,C.Teal,1.5)
    rnBtn.MouseButton1Click:Connect(function() rnBtn.Text="Rejoining..." task.wait(0.5) TS:Teleport(game.PlaceId,player) end)
    cfgRow("Interval (menit)",6,config.rejoinMinutes,function(v) config.rejoinMinutes=math.max(1,math.min(120,v)) end)

    local _row
    _row,arTog2,arTogStroke2,arStroke2=togRow(areas[4],"Auto Rejoin","Rejoin otomatis sesuai interval, tetap ON",7)

    cdLbl2=lbl(areas[4],"Auto Rejoin: OFF",9,C.Gray,Enum.TextXAlignment.Center)
    cdLbl2.Size=UDim2.new(1,0,0,20) cdLbl2.LayoutOrder=8
    cdLbl2.BackgroundColor3=C.Panel cdLbl2.BackgroundTransparency=0
    corner(cdLbl2,6) stroke(cdLbl2,C.Dim,1.1)

    div(areas[4],9)
    local t3=lbl(areas[4],"AUTO ACCEPT",9,C.Teal) t3.Size=UDim2.new(1,0,0,14) t3.LayoutOrder=10
    local _,agTog,agTogStroke,agStroke=togRow(areas[4],"Auto Accept Gift","Auto terima gift masuk",11)
    agTog.Text=autoAccGift and "ON" or "OFF" agTog.BackgroundColor3=autoAccGift and C.TDim or C.Panel agTog.TextColor3=autoAccGift and C.Teal or C.Gray agTogStroke.Color=autoAccGift and C.Teal or C.Dim agStroke.Color=autoAccGift and C.Teal or C.Dim
    agTog.MouseButton1Click:Connect(function()
        autoAccGift=not autoAccGift d.autoAccGift=autoAccGift
        if autoAccGift then agTog.Text="ON" agTog.BackgroundColor3=C.TDim agTog.TextColor3=C.Teal agTogStroke.Color=C.Teal agStroke.Color=C.Teal
        else agTog.Text="OFF" agTog.BackgroundColor3=C.Panel agTog.TextColor3=C.Gray agTogStroke.Color=C.Dim agStroke.Color=C.Dim end
        save()
    end)
    local _,atTog,atTogStroke,atStroke=togRow(areas[4],"Auto Accept Trade","Auto terima trade masuk",12)
    atTog.Text=autoAccTrade and "ON" or "OFF" atTog.BackgroundColor3=autoAccTrade and C.TDim or C.Panel atTog.TextColor3=autoAccTrade and C.Teal or C.Gray atTogStroke.Color=autoAccTrade and C.Teal or C.Dim atStroke.Color=autoAccTrade and C.Teal or C.Dim
    atTog.MouseButton1Click:Connect(function()
        autoAccTrade=not autoAccTrade d.autoAccTrade=autoAccTrade
        if autoAccTrade then atTog.Text="ON" atTog.BackgroundColor3=C.TDim atTog.TextColor3=C.Teal atTogStroke.Color=C.Teal atStroke.Color=C.Teal
        else atTog.Text="OFF" atTog.BackgroundColor3=C.Panel atTog.TextColor3=C.Gray atTogStroke.Color=C.Dim atStroke.Color=C.Dim end
        save()
    end)
    accStatus=lbl(areas[4],"Menunggu...",9,C.Gray,Enum.TextXAlignment.Center)
    accStatus.Size=UDim2.new(1,0,0,14) accStatus.LayoutOrder=13
    accStatus.BackgroundColor3=C.Panel accStatus.BackgroundTransparency=0
    corner(accStatus,5)
end

buildTimList() buildTargetList() buildSwapList() buildOtherSetting()
switchTab(1)

-- ============================================
-- AUTO REJOIN — tetap ON, loop terus
-- ============================================
local function stopAR()
    isAR=false
    if arTask then task.cancel(arTask) arTask=nil end
    if arTog2 then
        arTog2.Text="OFF" arTog2.BackgroundColor3=C.Panel arTog2.TextColor3=C.Gray
        arTogStroke2.Color=C.Dim arStroke2.Color=C.Dim
    end
    if cdLbl2 then cdLbl2.Text="Auto Rejoin: OFF" end
end

local function startAR()
    isAR=true
    arTog2.Text="ON" arTog2.BackgroundColor3=C.TDim arTog2.TextColor3=C.Teal
    arTogStroke2.Color=C.Teal arStroke2.Color=C.Teal
    arTask=task.spawn(function()
        while isAR do
            local mins=config.rejoinMinutes or 30
            for i=mins*60,1,-1 do
                if not isAR then return end
                cdLbl2.Text=string.format("Rejoin dalam: %02d:%02d",math.floor(i/60),i%60)
                task.wait(1)
            end
            if isAR then
                cdLbl2.Text="Rejoining..."
                task.wait(0.5)
                TS:Teleport(game.PlaceId,player)
                -- Setelah rejoin, loop countdown lagi (toggle tetap ON)
            end
        end
    end)
end

arTog2.MouseButton1Click:Connect(function()
    if isAR then stopAR() else startAR() end
end)

-- ============================================
-- AUTO ACCEPT HOOKS
-- ============================================
pcall(function()
    local giftPrompted=RS:FindFirstChild("GiftPrompted",true)
    if giftPrompted then
        giftPrompted.OnClientEvent:Connect(function(a,b,c,d2)
            if autoAccGift then
                local acceptR=RS:FindFirstChild("AcceptGift",true) or RS:FindFirstChild("ConfirmGift",true)
                if acceptR then task.wait(0.2) pcall(function() acceptR:FireServer(a,b,c,d2) end)
                if accStatus then accStatus.Text="Gift diterima!" accStatus.TextColor3=C.Teal task.wait(2) if accStatus then accStatus.Text="Menunggu..." accStatus.TextColor3=C.Gray end end end
            end
        end)
    end
    local sendRequest=RS:FindFirstChild("SendRequest",true)
    if sendRequest then
        sendRequest.OnClientEvent:Connect(function(tradeId)
            if autoAccTrade then
                local respondR=RS:FindFirstChild("RespondRequest",true)
                if respondR then task.wait(0.2) pcall(function() respondR:FireServer(tradeId,true) end)
                if accStatus then accStatus.Text="Trade diterima!" accStatus.TextColor3=C.Teal task.wait(2) if accStatus then accStatus.Text="Menunggu..." accStatus.TextColor3=C.Gray end end end
            end
        end)
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

local function equipTeam()
    if not petsService then return end
    for _,item in ipairs(teamPets) do
        if item and item.Parent then
            local uuid=getPetUUID(item)
            if uuid then pcall(function() petsService:FireServer("EquipPet",tostring(uuid)) end) end
            task.wait(0.3)
        end
    end
end

local function unequipAll()
    if not petsService then return end
    for _,item in ipairs(teamPets) do
        if item then
            local uuid=getPetUUID(item)
            if uuid then pcall(function() petsService:FireServer("UnequipPet",tostring(uuid)) end) end
            task.wait(0.1)
        end
    end
    local bp=player:FindFirstChild("Backpack")
    if bp then
        for _,item in pairs(bp:GetChildren()) do
            if isPet(item) then
                local nameKey=getNameKey(item)
                local ps=swapPerPet[nameKey]
                if ps and ps.enabled then
                    local uuid=getPetUUID(item)
                    if uuid then pcall(function() petsService:FireServer("UnequipPet",tostring(uuid)) end) end
                    task.wait(0.05)
                end
            end
        end
    end
end

local function getQueue()
    local queue={}
    local bp=player:FindFirstChild("Backpack") if not bp then return queue end
    for _,item in pairs(bp:GetChildren()) do
        if isPet(item) then
            local name=getPetName(item)
            if targetPetType~="(Semua Pet)" and name~=targetPetType then continue end
            local age=getAge(item)
            if age and age>=fromAge and age<toAge then table.insert(queue,item) end
        end
    end
    return queue
end

local function doStop(reason)
    isRunning=false
    if mainTask then task.cancel(mainTask) mainTask=nil end
    if monitorTask then task.cancel(monitorTask) monitorTask=nil end
    if swapTask then task.cancel(swapTask) swapTask=nil end
    statusLbl.Text="Unequip..." statusLbl.TextColor3=C.Gray
    unequipAll()
    setRunning(false)
    statusLbl.Text=reason or "Dihentikan" statusLbl.TextColor3=C.Gray
    buildTargetList()
end

local function doStart()
    if isRunning then return end
    if #teamPets==0 then statusLbl.Text="Pilih tim leveling dulu!" statusLbl.TextColor3=C.Red return end
    local queue=getQueue()
    if #queue==0 then statusLbl.Text="Tidak ada pet target!" statusLbl.TextColor3=C.Red return end
    if not petsService then statusLbl.Text="PetsService tidak ada!" statusLbl.TextColor3=C.Red return end

    isRunning=true setRunning(true)
    statusLbl.Text="Berjalan..." statusLbl.TextColor3=C.Teal

    mainTask=task.spawn(function()
        while isRunning do equipTeam() task.wait(config.equipInterval) end
    end)

    swapTask=task.spawn(function()
        while isRunning do
            local bp=player:FindFirstChild("Backpack")
            if bp then
                for _,item in pairs(bp:GetChildren()) do
                    if not isRunning then break end
                    if isPet(item) then
                        local nameKey=getNameKey(item)
                        local ps=swapPerPet[nameKey]
                        if ps and ps.enabled then
                            local uuid=getPetUUID(item)
                            if uuid then
                                local uuidStr=tostring(uuid)
                                local name=getPetName(item)
                                if ps.pickup>0 then task.wait(ps.pickup) end
                                statusLbl.Text="Pickup: "..name statusLbl.TextColor3=C.Gray
                                pcall(function() petsService:FireServer("UnequipPet",uuidStr) end)
                                if ps.place>0 then task.wait(ps.place) end
                                statusLbl.Text="Place: "..name statusLbl.TextColor3=C.Teal
                                pcall(function() petsService:FireServer("EquipPet",uuidStr) end)
                                task.wait(swapConfig.swapDelay)
                            end
                        end
                    end
                end
            end
            task.wait(0.05)
        end
    end)

    monitorTask=task.spawn(function()
        while isRunning do
            local queue2=getQueue()
            if #queue2==0 then
                doStop("Semua pet selesai Age "..toAge.."!")
                statusLbl.TextColor3=C.Green buildTargetList() break
            end

            local batch={}
            for i,pet in ipairs(queue2) do
                if i>maxPetTarget then break end
                table.insert(batch,pet)
            end

            local batchUUIDs={}
            for _,pet in ipairs(batch) do
                local uuid=getPetUUID(pet)
                if uuid then batchUUIDs[tostring(uuid)]=true end
            end

            local bp=player:FindFirstChild("Backpack")
            if bp then
                for _,item in pairs(bp:GetChildren()) do
                    if isPet(item) then
                        local age=getAge(item)
                        local name=getPetName(item)
                        local uuid=getPetUUID(item)
                        if uuid and age and age>=fromAge and age<toAge then
                            if targetPetType=="(Semua Pet)" or name==targetPetType then
                                if not batchUUIDs[tostring(uuid)] then
                                    pcall(function() petsService:FireServer("UnequipPet",tostring(uuid)) end)
                                end
                            end
                        end
                    end
                end
            end

            for _,pet in ipairs(batch) do
                if not isRunning then break end
                local uuid=getPetUUID(pet)
                if uuid then
                    pcall(function() petsService:FireServer("EquipPet",tostring(uuid)) end)
                    task.wait(0.2)
                end
            end

            while isRunning do
                local allDone=true
                local info=""
                for _,pet in ipairs(batch) do
                    if pet and pet.Parent then
                        local age=getAge(pet)
                        if age and age<toAge then
                            allDone=false
                            info=getPetName(pet).." Age "..(age or 0).."/"..toAge
                            break
                        end
                    end
                end
                if allDone then break end
                statusLbl.Text=info.." | Sisa "..#getQueue().." | Batch "..#batch
                statusLbl.TextColor3=C.Teal
                task.wait(2)
            end

            for _,pet in ipairs(batch) do
                local uuid=getPetUUID(pet)
                if uuid then
                    pcall(function() petsService:FireServer("UnequipPet",tostring(uuid)) end)
                    task.wait(0.1)
                end
            end
            task.wait(0.5)
        end
    end)
end

runBtn.MouseButton1Click:Connect(function() doStart() end)
stopBtn.MouseButton1Click:Connect(function() doStop("Dihentikan") end)

if autoStartEnabled then task.wait(1) doStart() end

print("ZenxLvl loaded! PetsService: "..(petsService and "✅" or "❌"))
