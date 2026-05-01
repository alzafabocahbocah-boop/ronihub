-- ZENX DIAGNOSTIC TOOL
-- Cara pake:
-- 1. Place 1 pet di garden (pet apa aja, yg punya skill)
-- 2. Jalankan script ini
-- 3. Klik "PICK PET" di GUI yg muncul, klik pet yg di-place
-- 4. Klik "START WATCH"
-- 5. Tunggu pet ngeskill 1-2 kali (biarin aja, jangan diapa-apain)
-- 6. Klik "STOP & DUMP"
-- 7. Screenshot debug overlay (kotak hitam) yg muncul -- kasih ke Claude

local Players=game:GetService("Players")
local player=Players.LocalPlayer
local guiContainer=(gethui and gethui()) or player:WaitForChild("PlayerGui")

pcall(function()
    if guiContainer:FindFirstChild("ZenxDiagGui") then guiContainer.ZenxDiagGui:Destroy() end
    if guiContainer:FindFirstChild("ZenxDiagOut") then guiContainer.ZenxDiagOut:Destroy() end
end)

local sg=Instance.new("ScreenGui")
sg.Name="ZenxDiagGui" sg.DisplayOrder=99999 sg.IgnoreGuiInset=true sg.ResetOnSpawn=false
sg.Parent=guiContainer

local main=Instance.new("Frame")
main.Size=UDim2.new(0,300,0,180) main.Position=UDim2.new(0,20,0,80)
main.BackgroundColor3=Color3.fromRGB(15,15,15) main.BorderSizePixel=0
main.Active=true main.Draggable=true main.Parent=sg
local crn=Instance.new("UICorner") crn.CornerRadius=UDim.new(0,8) crn.Parent=main
local strk=Instance.new("UIStroke") strk.Color=Color3.fromRGB(220,160,0) strk.Thickness=2 strk.Parent=main

local title=Instance.new("TextLabel")
title.Size=UDim2.new(1,-30,0,24) title.Position=UDim2.new(0,10,0,4)
title.BackgroundTransparency=1 title.Text="ZENX DIAGNOSTIC"
title.TextColor3=Color3.fromRGB(220,160,0) title.Font=Enum.Font.GothamBold title.TextSize=13
title.TextXAlignment=Enum.TextXAlignment.Left title.Parent=main

local status=Instance.new("TextLabel")
status.Size=UDim2.new(1,-20,0,30) status.Position=UDim2.new(0,10,0,30)
status.BackgroundColor3=Color3.fromRGB(25,25,25) status.BorderSizePixel=0
status.Text="Status: pilih pet dulu" status.TextColor3=Color3.fromRGB(200,200,200)
status.Font=Enum.Font.Gotham status.TextSize=10 status.TextWrapped=true
status.Parent=main
local sc=Instance.new("UICorner") sc.CornerRadius=UDim.new(0,5) sc.Parent=status

local function mkBtn(txt,y,col)
    local b=Instance.new("TextButton")
    b.Size=UDim2.new(1,-20,0,28) b.Position=UDim2.new(0,10,0,y)
    b.BackgroundColor3=Color3.fromRGB(30,30,30)
    b.Text=txt b.TextColor3=col or Color3.fromRGB(220,220,220)
    b.Font=Enum.Font.GothamBold b.TextSize=11 b.AutoButtonColor=false
    b.Parent=main
    local c=Instance.new("UICorner") c.CornerRadius=UDim.new(0,5) c.Parent=b
    local s=Instance.new("UIStroke") s.Color=Color3.fromRGB(60,60,60) s.Thickness=1 s.Parent=b
    return b
end

local pickBtn=mkBtn("1. PICK PET (klik pet di workspace)",66,Color3.fromRGB(80,150,255))
local startBtn=mkBtn("2. START WATCH",100,Color3.fromRGB(70,190,90))
local stopBtn=mkBtn("3. STOP & DUMP",134,Color3.fromRGB(220,160,0))

-- Output overlay
local outSg=Instance.new("ScreenGui")
outSg.Name="ZenxDiagOut" outSg.DisplayOrder=99998 outSg.IgnoreGuiInset=true outSg.ResetOnSpawn=false
outSg.Parent=guiContainer

local outFr=Instance.new("Frame")
outFr.Size=UDim2.new(0,520,0,460) outFr.Position=UDim2.new(1,-540,0,80)
outFr.BackgroundColor3=Color3.fromRGB(0,0,0) outFr.BackgroundTransparency=0.1
outFr.BorderSizePixel=0 outFr.Active=true outFr.Draggable=true outFr.Parent=outSg
local oc=Instance.new("UICorner") oc.CornerRadius=UDim.new(0,8) oc.Parent=outFr
local os=Instance.new("UIStroke") os.Color=Color3.fromRGB(220,160,0) os.Thickness=1.5 os.Parent=outFr

local outTitle=Instance.new("TextLabel")
outTitle.Size=UDim2.new(1,-30,0,22) outTitle.Position=UDim2.new(0,10,0,5)
outTitle.BackgroundTransparency=1 outTitle.Text="DIAGNOSTIC OUTPUT (kasih ke Claude)"
outTitle.TextColor3=Color3.fromRGB(220,160,0) outTitle.Font=Enum.Font.GothamBold outTitle.TextSize=12
outTitle.TextXAlignment=Enum.TextXAlignment.Left outTitle.Parent=outFr

local outScroll=Instance.new("ScrollingFrame")
outScroll.Size=UDim2.new(1,-16,1,-32) outScroll.Position=UDim2.new(0,8,0,28)
outScroll.BackgroundTransparency=1 outScroll.ScrollBarThickness=4
outScroll.ScrollBarImageColor3=Color3.fromRGB(220,160,0)
outScroll.CanvasSize=UDim2.new(0,0,0,0) outScroll.AutomaticCanvasSize=Enum.AutomaticSize.Y
outScroll.Parent=outFr

local outLbl=Instance.new("TextLabel")
outLbl.Size=UDim2.new(1,-8,0,0) outLbl.AutomaticSize=Enum.AutomaticSize.Y
outLbl.BackgroundTransparency=1 outLbl.Text="(belum mulai)"
outLbl.TextColor3=Color3.fromRGB(220,220,220) outLbl.Font=Enum.Font.Code outLbl.TextSize=10
outLbl.TextXAlignment=Enum.TextXAlignment.Left outLbl.TextYAlignment=Enum.TextYAlignment.Top
outLbl.TextWrapped=true outLbl.Parent=outScroll

local outLines={}
local function out(s)
    table.insert(outLines,s)
    outLbl.Text=table.concat(outLines,"\n")
    print("[ZenxDiag] "..s)
end

-- Picker via Mouse target
local selectedModel=nil
local pickConn=nil
pickBtn.MouseButton1Click:Connect(function()
    if pickConn then pickConn:Disconnect() pickConn=nil end
    status.Text="Klik pet di garden... (mouse harus aktif)"
    local mouse=player:GetMouse()
    pickConn=mouse.Button1Down:Connect(function()
        local target=mouse.Target
        if not target then return end
        local m=target
        while m and m.Parent do
            if m:IsA("Model") then break end
            m=m.Parent
        end
        if not m or not m:IsA("Model") then status.Text="Bukan model, coba lagi" return end
        selectedModel=m
        status.Text="Selected: "..m.Name:sub(1,30).." ("..m:GetFullName():gsub(".*Workspace%.","ws."):sub(1,40)..")"
        out("=== PET SELECTED ===")
        out("Path: "..m:GetFullName())
        out("Name: "..m.Name)
        out("ClassName: "..m.ClassName)
        out("")
        out("=== INITIAL ATTRIBUTES ===")
        local attrCount=0
        for k,v in pairs(m:GetAttributes()) do
            attrCount=attrCount+1
            out("  ["..k.."]="..tostring(v).." ("..type(v)..")")
        end
        if attrCount==0 then out("  (no attrs on model itself)") end
        out("")
        out("=== CHILDREN ===")
        for _,c in ipairs(m:GetChildren()) do
            out("  "..c.Name.." :: "..c.ClassName)
        end
        out("")
        out("=== KEY DESCENDANTS (attrs only) ===")
        for _,desc in ipairs(m:GetDescendants()) do
            local da=desc:GetAttributes()
            local has=false for _ in pairs(da) do has=true break end
            if has and desc~=m then
                out("[ "..desc:GetFullName():gsub(m:GetFullName(),"~").." ]")
                for k,v in pairs(da) do
                    out("  ."..k.."="..tostring(v).." ("..type(v)..")")
                end
            end
        end
        out("")
        if pickConn then pickConn:Disconnect() pickConn=nil end
    end)
end)

local connections={}
local watchStart=0
local changeLog={}

startBtn.MouseButton1Click:Connect(function()
    if not selectedModel or not selectedModel.Parent then status.Text="Pilih pet dulu (atau pet ke-destroy)" return end
    for _,c in ipairs(connections) do pcall(function() c:Disconnect() end) end
    connections={}
    changeLog={}
    watchStart=tick()
    status.Text="WATCHING... biarin pet skill 1-2x. Pencet STOP setelah itu."
    out("=== START WATCH @ "..os.date("%X").." ===")

    local function logChange(category,detail)
        local t=tick()-watchStart
        local entry=string.format("[%6.2fs] %s | %s",t,category,detail)
        table.insert(changeLog,entry)
        if #changeLog<=200 then out(entry) end
    end

    -- Watch attribute changes on model + descendants
    local function hookAttrs(inst,prefix)
        local conn=inst.AttributeChanged:Connect(function(attrName)
            local v=inst:GetAttribute(attrName)
            logChange("ATTR",prefix..attrName.."="..tostring(v))
        end)
        table.insert(connections,conn)
    end
    hookAttrs(selectedModel,"")
    for _,desc in ipairs(selectedModel:GetDescendants()) do
        hookAttrs(desc,desc.Name..":")
    end

    -- Watch new descendants
    local addConn=selectedModel.DescendantAdded:Connect(function(d)
        logChange("ADD",d.Name.." ("..d.ClassName..") @ "..d.Parent.Name)
        hookAttrs(d,d.Name..":")
        if d:IsA("ParticleEmitter") or d:IsA("Beam") or d:IsA("Sound") or d:IsA("Trail") then
            -- effects = strong skill signal
        end
    end)
    table.insert(connections,addConn)

    local remConn=selectedModel.DescendantRemoving:Connect(function(d)
        if d:IsA("ParticleEmitter") or d:IsA("Beam") or d:IsA("Sound") or d:IsA("Trail") then
            logChange("REM",d.Name.." ("..d.ClassName..")")
        end
    end)
    table.insert(connections,remConn)

    -- Hook Animator
    for _,desc in ipairs(selectedModel:GetDescendants()) do
        if desc:IsA("Animator") then
            local ac=desc.AnimationPlayed:Connect(function(track)
                local nm,id,len,looped="?","?",0,true
                pcall(function()
                    if track.Animation then
                        nm=track.Animation.Name
                        id=tostring(track.Animation.AnimationId or "?")
                    end
                    len=track.Length or 0
                    looped=track.Looped
                end)
                logChange("ANIM",string.format("name=%s len=%.1f loop=%s id=%s",nm:sub(1,20),len,tostring(looped),id:sub(-8)))
            end)
            table.insert(connections,ac)
        end
    end
end)

stopBtn.MouseButton1Click:Connect(function()
    for _,c in ipairs(connections) do pcall(function() c:Disconnect() end) end
    connections={}
    if pickConn then pickConn:Disconnect() pickConn=nil end
    out("")
    out("=== STOP @ "..os.date("%X").." ===")
    out("Total events captured: "..#changeLog)
    if #changeLog==0 then
        out("(GAK ADA event ke-capture - pet gak skill, atau attribute gak ke-monitor)")
        out("Solusi: tunggu lebih lama, atau pet kamu emang gak punya skill")
    else
        out("")
        out("=== TOP unique attribute changes ===")
        local counts={}
        for _,e in ipairs(changeLog) do
            local cat=e:match("|%s(%w+)%s|%s([^=]+)")
            if cat then counts[cat]=(counts[cat] or 0)+1 end
        end
        for k,v in pairs(counts) do out("  "..k..": "..v.." times") end
    end
    status.Text="Done. Screenshot kotak kuning dump output."
end)

print("[ZenxDiag] loaded. Pencet 1->2->3 sesuai urutan.")
