-- FTF ESP Script — ajustes solicitados
-- Alterações principais:
--  - Removei o botão rápido "Teleport" ao lado da search (conforme pedido).
--  - Removi a janela externa de Teleport (agora Teleport é apenas uma aba no menu, ajustada para caber).
--  - Adicionei "Snow texture" na aba Textures como toggle (ativa/desativa).
--     - Ao ativar: altera BaseParts e Lighting como no script que você forneceu; salva backups.
--     - Ao desativar: restaura propriedades salvas e restaura Skies removidos.
--  - A lista de Teleport (aba Teleport) já é dinâmica e atualiza quando alguém entra/sai.
--  - Garantia: nada do Teleport ficará maior que o menu — tudo dentro da aba.

-- Services
local UIS = game:GetService("UserInputService")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")
local Lighting = game:GetService("Lighting")
local CoreGui = game:GetService("CoreGui")
local LocalPlayer = Players.LocalPlayer

-- UI root
local PlayerGui = LocalPlayer:FindFirstChild("PlayerGui") or LocalPlayer:WaitForChild("PlayerGui")
-- cleanup old
for _,v in pairs(CoreGui:GetChildren()) do if v.Name=="FTF_ESP_GUI_DAVID" then v:Destroy() end end
for _,v in pairs(PlayerGui:GetChildren()) do if v.Name=="FTF_ESP_GUI_DAVID" then v:Destroy() end end

local GUI = Instance.new("ScreenGui")
GUI.Name = "FTF_ESP_GUI_DAVID"
GUI.ResetOnSpawn = false
GUI.IgnoreGuiInset = true
pcall(function() GUI.Parent = CoreGui end)
if not GUI.Parent or GUI.Parent ~= CoreGui then GUI.Parent = PlayerGui end

-- =====================================================================
-- CORE LOGIC (ESP, Computers, Doors, Freeze Pods, Timers, Texture)
-- (kept similar to previous version)
-- =====================================================================

-- PLAYER ESP
local PlayerESPActive = false
local playerHighlights = {}
local NameTags = {}
local function isBeast(player) return player.Character and player.Character:FindFirstChild("BeastPowers") ~= nil end
local function HighlightColorForPlayer(player)
    if isBeast(player) then return Color3.fromRGB(240,28,80), Color3.fromRGB(255,188,188) end
    return Color3.fromRGB(52,215,101), Color3.fromRGB(170,255,200)
end
local function AddPlayerHighlight(player)
    if player == LocalPlayer then return end
    if not player.Character then return end
    if playerHighlights[player] then pcall(function() playerHighlights[player]:Destroy() end) end
    local fill, outline = HighlightColorForPlayer(player)
    local h = Instance.new("Highlight")
    h.Name = "[FTF_ESP_PlayerAura_DAVID]"; h.Adornee = player.Character
    h.Parent = Workspace
    h.FillColor = fill; h.OutlineColor = outline; h.FillTransparency = 0.12; h.OutlineTransparency = 0.04
    h.Enabled = true
    playerHighlights[player] = h
end
local function RemovePlayerHighlight(player) if playerHighlights[player] then pcall(function() playerHighlights[player]:Destroy() end) end playerHighlights[player]=nil end

local function AddNameTag(player)
    if player==LocalPlayer then return end
    if not player.Character or not player.Character:FindFirstChild("Head") then return end
    if NameTags[player] then pcall(function() NameTags[player]:Destroy() end) end
    local billboard = Instance.new("BillboardGui", GUI)
    billboard.Name = "[FTFName]"; billboard.Adornee = player.Character.Head
    billboard.Size = UDim2.new(0,110,0,20); billboard.StudsOffset = Vector3.new(0,2.18,0); billboard.AlwaysOnTop = true
    local text = Instance.new("TextLabel", billboard)
    text.Size = UDim2.new(1,0,1,0); text.BackgroundTransparency = 1; text.Font = Enum.Font.GothamSemibold
    text.TextSize = 13; text.TextColor3 = Color3.fromRGB(190,210,230); text.TextStrokeColor3 = Color3.fromRGB(8,10,14); text.TextStrokeTransparency = 0.6
    text.Text = player.DisplayName or player.Name
    NameTags[player] = billboard
end
local function RemoveNameTag(player) if NameTags[player] then pcall(function() NameTags[player]:Destroy() end) end NameTags[player]=nil end

local function RefreshPlayerESP()
    for _,p in pairs(Players:GetPlayers()) do
        if PlayerESPActive then AddPlayerHighlight(p); AddNameTag(p) else RemovePlayerHighlight(p); RemoveNameTag(p) end
    end
end
Players.PlayerAdded:Connect(function(p) p.CharacterAdded:Connect(function() wait(0.08); if PlayerESPActive then AddPlayerHighlight(p); AddNameTag(p) end end) end)
Players.PlayerRemoving:Connect(function(p) RemovePlayerHighlight(p); RemoveNameTag(p) end)
RunService.RenderStepped:Connect(function()
    if PlayerESPActive then
        for _,p in pairs(Players:GetPlayers()) do
            if playerHighlights[p] then
                local fill, outline = HighlightColorForPlayer(p)
                playerHighlights[p].FillColor = fill
                playerHighlights[p].OutlineColor = outline
            end
        end
    end
end)

-- COMPUTER ESP
local ComputerESPActive = false
local compHighlights = {}
local function isComputerModel(model)
    return model and model:IsA("Model") and (model.Name:lower():find("computer") or model.Name:lower():find("pc"))
end
local function getScreenPart(model)
    for _,name in ipairs({"Screen","screen","Monitor","monitor","Display","display","Tela"}) do
        if model:FindFirstChild(name) and model[name]:IsA("BasePart") then return model[name] end
    end
    local biggest
    for _,c in ipairs(model:GetChildren()) do if c:IsA("BasePart") and (not biggest or c.Size.Magnitude > biggest.Size.Magnitude) then biggest = c end end
    return biggest
end
local function getPcColor(model)
    local s = getScreenPart(model)
    if not s then return Color3.fromRGB(77,164,255) end
    return s.Color
end
local function AddComputerHighlight(model)
    if not isComputerModel(model) then return end
    if compHighlights[model] then pcall(function() compHighlights[model]:Destroy() end) end
    local h = Instance.new("Highlight")
    h.Name = "[FTF_ESP_ComputerAura_DAVID]"; h.Adornee = model
    h.Parent = Workspace
    h.FillColor = getPcColor(model); h.OutlineColor = Color3.fromRGB(210,210,210)
    h.FillTransparency = 0.10; h.OutlineTransparency = 0.03
    h.Enabled = true
    compHighlights[model] = h
end
local function RemoveComputerHighlight(model) if compHighlights[model] then pcall(function() compHighlights[model]:Destroy() end) end compHighlights[model]=nil end
local function RefreshComputerESP()
    for m,h in pairs(compHighlights) do if h then h:Destroy() end end; compHighlights = {}
    if not ComputerESPActive then return end
    for _,d in ipairs(Workspace:GetDescendants()) do if isComputerModel(d) then AddComputerHighlight(d) end end
end
Workspace.DescendantAdded:Connect(function(obj) if ComputerESPActive and isComputerModel(obj) then task.delay(0.05, function() AddComputerHighlight(obj) end) end end)
Workspace.DescendantRemoving:Connect(RemoveComputerHighlight)
RunService.RenderStepped:Connect(function() if ComputerESPActive then for m,h in pairs(compHighlights) do if m and m.Parent and h and h.Parent then h.FillColor = getPcColor(m) end end end end)

-- DOOR ESP
local DoorESPActive = false
local doorHighlights = {}
local doorDescendantAddConn, doorDescendantRemConn = nil, nil
local function isDoorModel(model)
    if not model or not model:IsA("Model") then return false end
    local name = model.Name:lower()
    if name:find("door") then return true end
    if name:find("exitdoor") then return true end
    if name:find("single") and name:find("door") then return true end
    if name:find("double") and name:find("door") then return true end
    return false
end
local function getDoorPrimaryPart(model)
    if not model then return nil end
    local candidates = {"DoorBoard","Door", "Part", "ExitDoorTrigger", "DoorL", "DoorR", "BasePart"}
    for _,n in ipairs(candidates) do
        local v = model:FindFirstChild(n, true)
        if v and v:IsA("BasePart") then return v end
    end
    local biggest
    for _,c in ipairs(model:GetDescendants()) do
        if c:IsA("BasePart") and (not biggest or c.Size.Magnitude > biggest.Size.Magnitude) then biggest = c end
    end
    return biggest
end
local function AddDoorHighlight(model)
    if not model or not isDoorModel(model) then return end
    if doorHighlights[model] then pcall(function() doorHighlights[model]:Destroy() end) end
    local primary = getDoorPrimaryPart(model)
    if not primary then return end
    local box = Instance.new("SelectionBox")
    box.Name = "[FTF_ESP_DoorEdge_DAVID]"; box.Adornee = primary
    pcall(function() box.Color3 = Color3.fromRGB(255,230,120) end)
    pcall(function() box.Color = Color3.fromRGB(255,230,120) end)
    pcall(function() box.LineThickness = 0.01 end)
    box.Parent = Workspace
    doorHighlights[model] = box
end
local function RemoveDoorHighlight(model) if doorHighlights[model] then pcall(function() doorHighlights[model]:Destroy() end) end doorHighlights[model]=nil end
local function RefreshDoorESP()
    for m,_ in pairs(doorHighlights) do RemoveDoorHighlight(m) end
    if not DoorESPActive then return end
    for _,d in ipairs(Workspace:GetDescendants()) do if isDoorModel(d) then AddDoorHighlight(d) end end
end
local function onDoorDescendantAdded(desc)
    if not DoorESPActive then return end
    if not desc then return end
    if desc:IsA("Model") and isDoorModel(desc) then task.delay(0.04, function() AddDoorHighlight(desc) end)
    elseif desc:IsA("BasePart") then local mdl = desc:FindFirstAncestorWhichIsA("Model"); if mdl and isDoorModel(mdl) then task.delay(0.04, function() AddDoorHighlight(mdl) end) end end
end
local function onDoorDescendantRemoving(desc)
    if not desc then return end
    if desc:IsA("Model") and isDoorModel(desc) then RemoveDoorHighlight(desc)
    elseif desc:IsA("BasePart") then local mdl = desc:FindFirstAncestorWhichIsA("Model"); if mdl and isDoorModel(mdl) then RemoveDoorHighlight(mdl) end end
end

-- FREEZE PODS
local FreezePodsActive = false
local podHighlights = {}
local podDescendantAddConn, podDescendantRemConn = nil, nil
local function isFreezePodModel(model)
    if not model or not model:IsA("Model") then return false end
    local name = model.Name:lower()
    if name:find("freezepod") then return true end
    if name:find("freeze") and name:find("pod") then return true end
    if name:find("freeze") and name:find("capsule") then return true end
    return false
end
local function AddFreezePodHighlight(model)
    if not model or not isFreezePodModel(model) then return end
    if podHighlights[model] then pcall(function() podHighlights[model]:Destroy() end) end
    local h = Instance.new("Highlight"); h.Name = "[FTF_ESP_FreezePodAura_DAVID]"; h.Adornee = model; h.Parent = Workspace
    h.FillColor = Color3.fromRGB(255,100,100); h.OutlineColor = Color3.fromRGB(200,40,40)
    h.FillTransparency = 0.08; h.OutlineTransparency = 0.02; h.Enabled = true
    podHighlights[model] = h
end
local function RemoveFreezePodHighlight(model) if podHighlights[model] then pcall(function() podHighlights[model]:Destroy() end) end podHighlights[model]=nil end
local function RefreshFreezePods()
    for m,_ in pairs(podHighlights) do RemoveFreezePodHighlight(m) end
    if not FreezePodsActive then return end
    for _,d in ipairs(Workspace:GetDescendants()) do if isFreezePodModel(d) then AddFreezePodHighlight(d) end end
end
local function onPodDescendantAdded(desc)
    if not FreezePodsActive then return end
    if desc and (desc:IsA("Model") or desc:IsA("Folder")) and isFreezePodModel(desc) then task.delay(0.05, function() AddFreezePodHighlight(desc) end)
    elseif desc and desc:IsA("BasePart") then local mdl = desc:FindFirstAncestorWhichIsA("Model"); if mdl and isFreezePodModel(mdl) then task.delay(0.05, function() AddFreezePodHighlight(mdl) end) end end
end
local function onPodDescendantRemoving(desc)
    if desc and desc:IsA("Model") and isFreezePodModel(desc) then RemoveFreezePodHighlight(desc)
    elseif desc and desc:IsA("BasePart") then local mdl = desc:FindFirstAncestorWhichIsA("Model"); if mdl and isFreezePodModel(mdl) then RemoveFreezePodHighlight(mdl) end end
end

-- DOWN TIMER
local DownTimerActive = false
local DOWN_TIME = 28
local ragdollBillboards = {}
local ragdollConnects = {}
local bottomUI = {}
local function createRagdollBillboardFor(player)
    if ragdollBillboards[player] then return ragdollBillboards[player] end
    if not player.Character then return nil end
    local head = player.Character:FindFirstChild("Head") if not head then return nil end
    local billboard = Instance.new("BillboardGui", GUI); billboard.Name = "[FTF_RagdollTimer]"; billboard.Adornee = head
    billboard.Size = UDim2.new(0,140,0,44); billboard.StudsOffset = Vector3.new(0,3.2,0); billboard.AlwaysOnTop = true
    local bg = Instance.new("Frame", billboard); bg.Size = UDim2.new(1,0,1,0); bg.BackgroundColor3 = Color3.fromRGB(24,24,28)
    local corner = Instance.new("UICorner", bg); corner.CornerRadius = UDim.new(0,12)
    local txt = Instance.new("TextLabel", bg); txt.Size = UDim2.new(1,-16,1,-16); txt.Position = UDim2.new(0,8,0,6)
    txt.BackgroundTransparency = 1; txt.Font = Enum.Font.GothamBold; txt.TextSize = 18; txt.TextColor3 = Color3.fromRGB(220,220,230)
    txt.Text = tostring(DOWN_TIME) .. "s"; txt.TextXAlignment = Enum.TextXAlignment.Center
    local pbg = Instance.new("Frame", bg); pbg.Size = UDim2.new(0.92,0,0,6); pbg.Position = UDim2.new(0.04,0,1,-10)
    local pfill = Instance.new("Frame", pbg); pfill.Size = UDim2.new(1,0,1,0); pfill.BackgroundColor3 = Color3.fromRGB(90,180,255)
    local info = { gui = billboard, label = txt, endTime = tick() + DOWN_TIME, progress = pfill }
    ragdollBillboards[player] = info
    return info
end
local function removeRagdollBillboard(player) if ragdollBillboards[player] then if ragdollBillboards[player].gui and ragdollBillboards[player].gui.Parent then ragdollBillboards[player].gui:Destroy() end ragdollBillboards[player] = nil end end
local function updateBottomRightFor(player, endTime)
    if player == LocalPlayer then return end
    if not bottomUI[player] then
        local gui = Instance.new("ScreenGui"); gui.Name = "FTF_Ragdoll_UI"; gui.Parent = PlayerGui
        local frame = Instance.new("Frame", gui); frame.Size = UDim2.new(0,200,0,50); frame.BackgroundTransparency = 1
        local nameLabel = Instance.new("TextLabel", frame); nameLabel.Size = UDim2.new(1,0,0.5,0); nameLabel.BackgroundTransparency = 1; nameLabel.TextScaled = true; nameLabel.Text = player.Name
        local timerLabel = Instance.new("TextLabel", frame); timerLabel.Size = UDim2.new(1,0,0.5,0); timerLabel.Position = UDim2.new(0,0,0.5,0); timerLabel.BackgroundTransparency = 1; timerLabel.TextScaled = true; timerLabel.Text = tostring(DOWN_TIME)
        frame.Position = UDim2.new(1,-220,1,-60)
        bottomUI[player] = { screenGui = gui, frame = frame, timerLabel = timerLabel }
    end
    bottomUI[player].timerLabel.Text = string.format("%.2f", math.max(0, endTime - tick()))
end
RunService.Heartbeat:Connect(function()
    if not DownTimerActive then return end
    local now = tick()
    for player, info in pairs(ragdollBillboards) do
        if not player or not player.Parent or not info or not info.gui then
            removeRagdollBillboard(player)
            if bottomUI[player] then if bottomUI[player].screenGui and bottomUI[player].screenGui.Parent then bottomUI[player].screenGui:Destroy() end bottomUI[player]=nil end
        else
            local remaining = info.endTime - now
            if remaining <= 0 then removeRagdollBillboard(player); if bottomUI[player] then if bottomUI[player].screenGui and bottomUI[player].screenGui.Parent then bottomUI[player].screenGui:Destroy() end bottomUI[player]=nil end
            else
                if info.label and info.label.Parent then info.label.Text = string.format("%.2f", remaining); if remaining <= 5 then info.label.TextColor3 = Color3.fromRGB(255,90,90) else info.label.TextColor3 = Color3.fromRGB(220,220,230) end end
                if info.progress and info.progress.Parent then local frac = math.clamp(remaining / DOWN_TIME, 0, 1); info.progress.Size = UDim2.new(frac,0,1,0); if frac > 0.5 then info.progress.BackgroundColor3 = Color3.fromRGB(90,180,255) elseif frac > 0.15 then info.progress.BackgroundColor3 = Color3.fromRGB(240,200,60) else info.progress.BackgroundColor3 = Color3.fromRGB(255,90,90) end end
                if bottomUI[player] then bottomUI[player].timerLabel.Text = string.format("%.2f", remaining) end
            end
        end
    end
end)
local function attachRagdollListenerToPlayer(player)
    if ragdollConnects[player] then pcall(function() ragdollConnects[player]:Disconnect() end) end
    task.spawn(function()
        local ok, tempStats = pcall(function() return player:WaitForChild("TempPlayerStatsModule", 8) end)
        if not ok or not tempStats then return end
        local ok2, ragdoll = pcall(function() return tempStats:WaitForChild("Ragdoll", 8) end)
        if not ok2 or not ragdoll then return end
        pcall(function() if ragdoll.Value then local info = createRagdollBillboardFor(player); if info then info.endTime = tick() + DOWN_TIME; updateBottomRightFor(player, info.endTime) end end end)
        local conn = ragdoll.Changed:Connect(function() pcall(function() if ragdoll.Value then local info = createRagdollBillboardFor(player); if info then info.endTime = tick() + DOWN_TIME; updateBottomRightFor(player, info.endTime) end else removeRagdollBillboard(player) end end) end)
        ragdollConnects[player] = conn
    end)
end
Players.PlayerAdded:Connect(function(p) attachRagdollListenerToPlayer(p); p.CharacterAdded:Connect(function() wait(0.06); if ragdollBillboards[p] then removeRagdollBillboard(p); createRagdollBillboardFor(p) end end) end)
for _,p in pairs(Players:GetPlayers()) do attachRagdollListenerToPlayer(p) end

-- GRAY SKIN (Remove players Textures)
local GraySkinActive = false
local skinBackup = {}
local grayConns = {}
local function storePartOriginal(part, store)
    if not part or (not part:IsA("BasePart") and not part:IsA("MeshPart")) then return end
    if store[part] then return end
    local okC, col = pcall(function() return part.Color end)
    local okM, mat = pcall(function() return part.Material end)
    store[part] = { Color = (okC and col) or nil, Material = (okM and mat) or nil }
end
local function applyGrayToCharacter(player)
    if not player or not player.Character then return end
    local map = skinBackup[player] or {}
    skinBackup[player] = map
    for _,obj in ipairs(player.Character:GetDescendants()) do
        if obj:IsA("BasePart") or obj:IsA("MeshPart") then
            storePartOriginal(obj, map)
            pcall(function() obj.Color = Color3.fromRGB(128,128,132); obj.Material = Enum.Material.SmoothPlastic end)
        elseif obj:IsA("Accessory") then
            local handle = obj:FindFirstChild("Handle")
            if handle and handle:IsA("BasePart") then
                storePartOriginal(handle, map)
                pcall(function() handle.Color = Color3.fromRGB(128,128,132); handle.Material = Enum.Material.SmoothPlastic end)
            end
        end
    end
end
local function restoreGrayForPlayer(player)
    local map = skinBackup[player]; if not map then return end
    for part, props in pairs(map) do
        if part and part.Parent then
            pcall(function() if props.Material then part.Material = props.Material end; if props.Color then part.Color = props.Color end end)
        end
    end
    skinBackup[player] = nil
end
local function enableGraySkin()
    GraySkinActive = true
    for _,p in pairs(Players:GetPlayers()) do
        if p ~= LocalPlayer then applyGrayToCharacter(p) end
        if not grayConns[p] then
            grayConns[p] = p.CharacterAdded:Connect(function() wait(0.06); if GraySkinActive then applyGrayToCharacter(p) end end)
        end
    end
    if not grayConns._playerAddedConn then
        grayConns._playerAddedConn = Players.PlayerAdded:Connect(function(p) if p ~= LocalPlayer and GraySkinActive then if p.Character then applyGrayToCharacter(p) end; if not grayConns[p] then grayConns[p] = p.CharacterAdded:Connect(function() wait(0.06); if GraySkinActive then applyGrayToCharacter(p) end end) end end end)
    end
end
local function disableGraySkin()
    GraySkinActive = false
    for p,_ in pairs(skinBackup) do pcall(function() restoreGrayForPlayer(p) end) end
    skinBackup = {}
    for k,conn in pairs(grayConns) do pcall(function() conn:Disconnect() end); grayConns[k]=nil end
end
Players.PlayerRemoving:Connect(function(p) if skinBackup[p] then restoreGrayForPlayer(p); skinBackup[p]=nil end; if grayConns[p] then pcall(function() grayConns[p]:Disconnect() end); grayConns[p]=nil end end)

-- WHITE BRICK TEXTURE (existing)
local TextureActive = false
local textureBackup = {}
local textureDescendantConn = nil
local function isPartPlayerCharacter(part)
    if not part then return false end
    local model = part:FindFirstAncestorWhichIsA("Model")
    if model then return Players:GetPlayerFromCharacter(model) ~= nil end
    return false
end
local function saveAndApplyWhiteBrick(part)
    if not part or not part:IsA("BasePart") then return end
    if isPartPlayerCharacter(part) then return end
    if textureBackup[part] then return end
    local okC, col = pcall(function() return part.Color end)
    local okM, mat = pcall(function() return part.Material end)
    textureBackup[part] = { Color = (okC and col) or nil, Material = (okM and mat) or nil }
    pcall(function() part.Material = Enum.Material.Brick; part.Color = Color3.fromRGB(255,255,255) end)
end
local function applyWhiteBrickToAll()
    local desc = Workspace:GetDescendants()
    local batch = 0
    for i = 1, #desc do
        local d = desc[i]
        if d and d:IsA("BasePart") then
            saveAndApplyWhiteBrick(d)
            batch = batch + 1
            if batch >= 200 then batch = 0; RunService.Heartbeat:Wait() end
        end
    end
end
local function onWorkspaceDescendantAdded(desc)
    if not TextureActive then return end
    if desc and desc:IsA("BasePart") and not isPartPlayerCharacter(desc) then task.defer(function() saveAndApplyWhiteBrick(desc) end) end
end
local function restoreTextures()
    local entries = {}
    for p, props in pairs(textureBackup) do entries[#entries+1] = {p=p, props=props} end
    local batch = 0
    for _, e in ipairs(entries) do
        local part = e.p; local props = e.props
        if part and part.Parent then
            pcall(function()
                if props.Material then part.Material = props.Material end
                if props.Color then part.Color = props.Color end
            end)
        end
        batch = batch + 1
        if batch >= 200 then batch = 0; RunService.Heartbeat:Wait() end
    end
    textureBackup = {}
end
local function enableTextureToggle()
    if TextureActive then return end
    TextureActive = true
    task.spawn(applyWhiteBrickToAll)
    textureDescendantConn = Workspace.DescendantAdded:Connect(onWorkspaceDescendantAdded)
end
local function disableTextureToggle()
    if not TextureActive then return end
    TextureActive = false
    if textureDescendantConn then pcall(function() textureDescendantConn:Disconnect() end); textureDescendantConn = nil end
    task.spawn(restoreTextures)
end

-- =====================================================================
-- SNOW TEXTURE (new)
-- - runs the provided code, but saves backups so it can be toggled off
-- =====================================================================
local SnowActive = false
local snowBackupParts = {}      -- [part] = {Color, Material}
local snowPartConn = nil
local snowLightingBackup = nil  -- table of lighting properties
local snowSkyBackup = {}        -- original Sky instances (clones saved)
local createdSnowSky = nil

local function backupLighting()
    local ok, amb = pcall(function() return Lighting.Ambient end)
    local ok2, outAmb = pcall(function() return Lighting.OutdoorAmbient end)
    local ok3, fogc = pcall(function() return Lighting.FogColor end)
    local ok4, foge = pcall(function() return Lighting.FogEnd end)
    local ok5, bright = pcall(function() return Lighting.Brightness end)
    local ok6, clock = pcall(function() return Lighting.ClockTime end)
    local ok7, envDiff = pcall(function() return Lighting.EnvironmentDiffuseScale end)
    local ok8, envSpec = pcall(function() return Lighting.EnvironmentSpecularScale end)
    snowLightingBackup = {
        Ambient = (ok and amb) or nil,
        OutdoorAmbient = (ok2 and outAmb) or nil,
        FogColor = (ok3 and fogc) or nil,
        FogEnd = (ok4 and foge) or nil,
        Brightness = (ok5 and bright) or nil,
        ClockTime = (ok6 and clock) or nil,
        EnvironmentDiffuseScale = (ok7 and envDiff) or nil,
        EnvironmentSpecularScale = (ok8 and envSpec) or nil,
    }
end

local function restoreLighting()
    if not snowLightingBackup then return end
    pcall(function() if snowLightingBackup.Ambient then Lighting.Ambient = snowLightingBackup.Ambient end end)
    pcall(function() if snowLightingBackup.OutdoorAmbient then Lighting.OutdoorAmbient = snowLightingBackup.OutdoorAmbient end end)
    pcall(function() if snowLightingBackup.FogColor then Lighting.FogColor = snowLightingBackup.FogColor end end)
    pcall(function() if snowLightingBackup.FogEnd then Lighting.FogEnd = snowLightingBackup.FogEnd end end)
    pcall(function() if snowLightingBackup.Brightness then Lighting.Brightness = snowLightingBackup.Brightness end end)
    pcall(function() if snowLightingBackup.ClockTime then Lighting.ClockTime = snowLightingBackup.ClockTime end end)
    pcall(function() if snowLightingBackup.EnvironmentDiffuseScale then Lighting.EnvironmentDiffuseScale = snowLightingBackup.EnvironmentDiffuseScale end end)
    pcall(function() if snowLightingBackup.EnvironmentSpecularScale then Lighting.EnvironmentSpecularScale = snowLightingBackup.EnvironmentSpecularScale end end)
    snowLightingBackup = nil
end

local function enableSnowTexture()
    if SnowActive then return end
    SnowActive = true
    -- backup lighting
    backupLighting()
    -- backup existing Sky instances (clone them)
    for _,v in pairs(Lighting:GetChildren()) do
        if v:IsA("Sky") then
            pcall(function() table.insert(snowSkyBackup, v:Clone()) end)
            pcall(function() v:Destroy() end)
        end
    end
    -- apply to all existing BaseParts
    for _, obj in pairs(Workspace:GetDescendants()) do
        if obj:IsA("BasePart") then
            local okC, col = pcall(function() return obj.Color end)
            local okM, mat = pcall(function() return obj.Material end)
            if not snowBackupParts[obj] then
                snowBackupParts[obj] = { Color = (okC and col) or nil, Material = (okM and mat) or nil }
            end
            pcall(function() obj.Color = Color3.new(1,1,1); obj.Material = Enum.Material.SmoothPlastic end)
        end
    end
    -- adjust lighting
    pcall(function()
        Lighting.Ambient = Color3.new(1,1,1)
        Lighting.OutdoorAmbient = Color3.new(1,1,1)
        Lighting.FogColor = Color3.new(1,1,1)
        Lighting.FogEnd = 100000
        Lighting.Brightness = 2
        Lighting.ClockTime = 12
        Lighting.EnvironmentDiffuseScale = 1
        Lighting.EnvironmentSpecularScale = 1
    end)
    -- create an empty sky like your script
    local sky = Instance.new("Sky")
    sky.SkyboxBk = ""
    sky.SkyboxDn = ""
    sky.SkyboxFt = ""
    sky.SkyboxLf = ""
    sky.SkyboxRt = ""
    sky.SkyboxUp = ""
    sky.Parent = Lighting
    createdSnowSky = sky
    -- connect to future added parts to apply snow (and backup their original props)
    snowPartConn = Workspace.DescendantAdded:Connect(function(desc)
        if not SnowActive then return end
        if desc and desc:IsA("BasePart") then
            if not snowBackupParts[desc] then
                local okC, col = pcall(function() return desc.Color end)
                local okM, mat = pcall(function() return desc.Material end)
                snowBackupParts[desc] = { Color = (okC and col) or nil, Material = (okM and mat) or nil }
            end
            pcall(function() desc.Color = Color3.new(1,1,1); desc.Material = Enum.Material.SmoothPlastic end)
        end
    end)
end

local function disableSnowTexture()
    if not SnowActive then return end
    SnowActive = false
    -- disconnect descendants connection
    if snowPartConn then pcall(function() snowPartConn:Disconnect() end); snowPartConn = nil end
    -- restore parts
    for part, props in pairs(snowBackupParts) do
        if part and part.Parent then
            pcall(function()
                if props.Material then part.Material = props.Material end
                if props.Color then part.Color = props.Color end
            end)
        end
    end
    snowBackupParts = {}
    -- remove created snow sky
    if createdSnowSky and createdSnowSky.Parent then pcall(function() createdSnowSky:Destroy() end) end
    createdSnowSky = nil
    -- restore previous skies
    for _,cloneSky in ipairs(snowSkyBackup) do
        if cloneSky then
            pcall(function() cloneSky.Parent = Lighting end)
        end
    end
    snowSkyBackup = {}
    -- restore lighting
    restoreLighting()
end

-- =====================================================================
-- UI: organized menu (Lemon-like). Teleport tab lives inside the menu.
-- =====================================================================

local MENU_WIDTH = 420
local MENU_HEIGHT = 360

local MainFrame = Instance.new("Frame", GUI)
MainFrame.Name = "FTF_Main"
MainFrame.Size = UDim2.new(0, MENU_WIDTH, 0, MENU_HEIGHT)
MainFrame.Position = UDim2.new(0.5, -MENU_WIDTH/2, 0.08, 0)
MainFrame.BackgroundColor3 = Color3.fromRGB(18,18,18)
MainFrame.BorderSizePixel = 0
MainFrame.Visible = false
local mfCorner = Instance.new("UICorner", MainFrame); mfCorner.CornerRadius = UDim.new(0,12)

-- Title bar
local TitleBar = Instance.new("Frame", MainFrame)
TitleBar.Size = UDim2.new(1, 0, 0, 48)
TitleBar.Position = UDim2.new(0,0,0,0)
TitleBar.BackgroundTransparency = 1

local TitleLbl = Instance.new("TextLabel", TitleBar)
TitleLbl.Text = "FTF - David's ESP"
TitleLbl.Font = Enum.Font.GothamBold
TitleLbl.TextSize = 16
TitleLbl.TextColor3 = Color3.fromRGB(220,220,220)
TitleLbl.BackgroundTransparency = 1
TitleLbl.Position = UDim2.new(0,12,0,12)
TitleLbl.Size = UDim2.new(0,220,0,24)
TitleLbl.TextXAlignment = Enum.TextXAlignment.Left

-- Search box (blank placeholder)
local SearchBox = Instance.new("TextBox", TitleBar)
SearchBox.Size = UDim2.new(0, 180, 0, 28)
SearchBox.Position = UDim2.new(1, -188, 0, 10)
SearchBox.BackgroundColor3 = Color3.fromRGB(26,26,26)
SearchBox.TextColor3 = Color3.fromRGB(200,200,200)
SearchBox.PlaceholderText = "" -- blank
SearchBox.Text = ""
SearchBox.ClearTextOnFocus = true
local sbCorner = Instance.new("UICorner", SearchBox); sbCorner.CornerRadius = UDim.new(0,8)
local sbPadding = Instance.new("UIPadding", SearchBox); sbPadding.PaddingLeft = UDim.new(0,10)

-- Close button
local CloseBtn = Instance.new("TextButton", TitleBar)
CloseBtn.Text = "✕"; CloseBtn.Font = Enum.Font.GothamBold; CloseBtn.TextSize = 18
CloseBtn.BackgroundTransparency = 1; CloseBtn.Size = UDim2.new(0,36,0,36); CloseBtn.Position = UDim2.new(1,-44,0,6)
CloseBtn.TextColor3 = Color3.fromRGB(200,200,200)
CloseBtn.MouseButton1Click:Connect(function() MainFrame.Visible = false end)

-- Tabs (pills)
local TabsParent = Instance.new("Frame", MainFrame)
TabsParent.Size = UDim2.new(1, -24, 0, 44)
TabsParent.Position = UDim2.new(0,12,0,56)
TabsParent.BackgroundTransparency = 1

local function createTab(name, x)
    local t = Instance.new("TextButton", TabsParent)
    t.Size = UDim2.new(0, 100, 0, 34)
    t.Position = UDim2.new(0, x, 0, 4)
    t.Text = name
    t.Font = Enum.Font.GothamSemibold
    t.TextSize = 14
    t.TextColor3 = Color3.fromRGB(200,200,200)
    t.BackgroundColor3 = Color3.fromRGB(28,28,28)
    t.AutoButtonColor = false
    local c = Instance.new("UICorner", t); c.CornerRadius = UDim.new(0,12)
    return t
end

local TabESP = createTab("ESP", 0)
local TabTextures = createTab("Textures", 114)
local TabTimers = createTab("Timers", 228)
local TabTeleport = createTab("Teleport", 342)

-- Content ScrollingFrame
local ContentScroll = Instance.new("ScrollingFrame", MainFrame)
ContentScroll.Name = "ContentScroll"
ContentScroll.Size = UDim2.new(1, -24, 1, -120)
ContentScroll.Position = UDim2.new(0,12,0,112)
ContentScroll.BackgroundTransparency = 1
ContentScroll.BorderSizePixel = 0
ContentScroll.ScrollBarImageColor3 = Color3.fromRGB(75,75,75)
ContentScroll.ScrollBarThickness = 8
local contentLayout = Instance.new("UIListLayout", ContentScroll)
contentLayout.SortOrder = Enum.SortOrder.LayoutOrder
contentLayout.Padding = UDim.new(0,10)
contentLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
contentLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
    ContentScroll.CanvasSize = UDim2.new(0,0,0, contentLayout.AbsoluteContentSize.Y + 18)
end)

-- Toggle item creator
local function createToggleItem(parent, labelText, initial, callback)
    local item = Instance.new("Frame", parent)
    item.Size = UDim2.new(0.95, 0, 0, 44)
    item.BackgroundColor3 = Color3.fromRGB(28,28,28)
    item.BorderSizePixel = 0
    local itemCorner = Instance.new("UICorner", item); itemCorner.CornerRadius = UDim.new(0,10)

    local lbl = Instance.new("TextLabel", item)
    lbl.Size = UDim2.new(1, -120, 1, 0)
    lbl.Position = UDim2.new(0,12,0,0)
    lbl.BackgroundTransparency = 1
    lbl.Font = Enum.Font.Gotham
    lbl.TextSize = 14
    lbl.TextColor3 = Color3.fromRGB(210,210,210)
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.Text = labelText

    local sw = Instance.new("TextButton", item)
    sw.Size = UDim2.new(0,88,0,28)
    sw.Position = UDim2.new(1, -100, 0.5, -14)
    sw.BackgroundColor3 = Color3.fromRGB(38,38,38)
    sw.AutoButtonColor = false
    local swCorner = Instance.new("UICorner", sw); swCorner.CornerRadius = UDim.new(0,16)

    local swBg = Instance.new("Frame", sw)
    swBg.Size = UDim2.new(1, -8, 1, -8)
    swBg.Position = UDim2.new(0,4,0,4)
    swBg.BackgroundColor3 = Color3.fromRGB(60,60,60)
    local swBgCorner = Instance.new("UICorner", swBg); swBgCorner.CornerRadius = UDim.new(0,14)

    local toggleDot = Instance.new("Frame", swBg)
    toggleDot.Size = UDim2.new(0,20,0,20)
    toggleDot.Position = UDim2.new(initial and 1 or 0, initial and -22 or 2, 0.5, -10)
    toggleDot.BackgroundColor3 = initial and Color3.fromRGB(120,200,120) or Color3.fromRGB(180,180,180)
    local dotCorner = Instance.new("UICorner", toggleDot); dotCorner.CornerRadius = UDim.new(0,10)

    local state = initial or false
    local function updateVisual(s)
        state = s
        local targetPos = s and UDim2.new(1, -22, 0.5, -10) or UDim2.new(0, 2, 0.5, -10)
        TweenService:Create(toggleDot, TweenInfo.new(0.15), {Position = targetPos}):Play()
        toggleDot.BackgroundColor3 = s and Color3.fromRGB(120,200,120) or Color3.fromRGB(160,160,160)
        swBg.BackgroundColor3 = s and Color3.fromRGB(35,90,35) or Color3.fromRGB(60,60,60)
    end

    sw.MouseButton1Click:Connect(function()
        updateVisual(not state)
        pcall(function() callback(state) end) -- pass old state
    end)

    updateVisual(state)
    return item, function(newState) updateVisual(newState) end, function() return state end, lbl
end

-- Button item (for teleport entries)
local function createButtonItem(parent, labelText, buttonText, callback)
    local item = Instance.new("Frame", parent)
    item.Size = UDim2.new(0.95, 0, 0, 44)
    item.BackgroundColor3 = Color3.fromRGB(28,28,28)
    item.BorderSizePixel = 0
    local itemCorner = Instance.new("UICorner", item); itemCorner.CornerRadius = UDim.new(0,10)

    local lbl = Instance.new("TextLabel", item)
    lbl.Size = UDim2.new(1, -120, 1, 0)
    lbl.Position = UDim2.new(0,12,0,0)
    lbl.BackgroundTransparency = 1
    lbl.Font = Enum.Font.Gotham
    lbl.TextSize = 14
    lbl.TextColor3 = Color3.fromRGB(210,210,210)
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.Text = labelText

    local btn = Instance.new("TextButton", item)
    btn.Size = UDim2.new(0,88,0,28)
    btn.Position = UDim2.new(1, -100, 0.5, -14)
    btn.BackgroundColor3 = Color3.fromRGB(38,120,190)
    btn.AutoButtonColor = false
    local btnCorner = Instance.new("UICorner", btn); btnCorner.CornerRadius = UDim.new(0,12)
    btn.Font = Enum.Font.GothamBold
    btn.TextSize = 14
    btn.TextColor3 = Color3.fromRGB(240,240,240)
    btn.Text = buttonText

    btn.MouseButton1Click:Connect(function()
        pcall(callback)
    end)

    return item, lbl, btn
end

-- Categories mapping
local Categories = {
    ["ESP"] = {
        { label = "ESP Players",      get = function() return PlayerESPActive end,    toggle = function(_) PlayerESPActive = not PlayerESPActive; RefreshPlayerESP(); end },
        { label = "ESP PCs",          get = function() return ComputerESPActive end, toggle = function(_) ComputerESPActive = not ComputerESPActive; RefreshComputerESP(); end },
        { label = "ESP Freeze Pods",  get = function() return FreezePodsActive end,   toggle = function(_) FreezePodsActive = not FreezePodsActive; RefreshFreezePods(); end },
        { label = "ESP Exit Doors",   get = function() return DoorESPActive end,     toggle = function(_) DoorESPActive = not DoorESPActive; if DoorESPActive then RefreshDoorESP(); if not doorDescendantAddConn then doorDescendantAddConn = Workspace.DescendantAdded:Connect(onDoorDescendantAdded) end; if not doorDescendantRemConn then doorDescendantRemConn = Workspace.DescendantRemoving:Connect(onDoorDescendantRemoving) end else for m,_ in pairs(doorHighlights) do RemoveDoorHighlight(m) end; if doorDescendantAddConn then pcall(function() doorDescendantAddConn:Disconnect() end); doorDescendantAddConn=nil end; if doorDescendantRemConn then pcall(function() doorDescendantRemConn:Disconnect() end); doorDescendantRemConn=nil end end end },
    },
    ["Textures"] = {
        { label = "Remove players Textures", get = function() return GraySkinActive end, toggle = function(_) GraySkinActive = not GraySkinActive; if GraySkinActive then enableGraySkin() else disableGraySkin() end end },
        { label = "Ativar Textures Tijolos Brancos", get = function() return TextureActive end, toggle = function(_) if not TextureActive then enableTextureToggle() else disableTextureToggle() end end },
        { label = "Snow texture", get = function() return SnowActive end, toggle = function(_) if not SnowActive then enableSnowTexture() else disableSnowTexture() end end },
    },
    ["Timers"] = {
        { label = "Ativar Contador de Down", get = function() return DownTimerActive end, toggle = function(_) DownTimerActive = not DownTimerActive; if not DownTimerActive then for p,_ in pairs(ragdollBillboards) do if ragdollBillboards[p] then removeRagdollBillboard(p) end end; for p,_ in pairs(bottomUI) do if bottomUI[p] and bottomUI[p].screenGui and bottomUI[p].screenGui.Parent then bottomUI[p].screenGui:Destroy() end bottomUI[p]=nil end else for _,p in pairs(Players:GetPlayers()) do local ok, temp = pcall(function() return p:FindFirstChild("TempPlayerStatsModule") end); if ok and temp then local rag = temp:FindFirstChild("Ragdoll"); if rag and rag.Value then attachRagdollListenerToPlayer(p); end end end end end },
    },
}

-- Build content
local currentCategory = "ESP"
local function clearContent()
    for _,v in pairs(ContentScroll:GetChildren()) do
        if v:IsA("Frame") then v:Destroy() end
    end
end

local function buildCategory(name, filter)
    filter = (filter or ""):lower()
    clearContent()
    if name == "Teleport" then
        local order = 1
        local players = Players:GetPlayers()
        table.sort(players, function(a,b) return ( (a.DisplayName or ""):lower()..a.Name:lower()) < ((b.DisplayName or ""):lower()..b.Name:lower()) end)
        for _,pl in ipairs(players) do
            if pl ~= LocalPlayer then
                local display = (pl.DisplayName or pl.Name) .. " (" .. pl.Name .. ")"
                if filter == "" or display:lower():find(filter) then
                    local item, lbl, btn = createButtonItem(ContentScroll, display, "Teleport", function()
                        local myChar = LocalPlayer.Character
                        local targetChar = pl.Character
                        if not myChar or not targetChar then return end
                        local hrp = myChar:FindFirstChild("HumanoidRootPart") or myChar:FindFirstChild("Torso") or myChar:FindFirstChild("UpperTorso")
                        local thrp = targetChar:FindFirstChild("HumanoidRootPart") or targetChar:FindFirstChild("Torso") or targetChar:FindFirstChild("UpperTorso")
                        if not hrp or not thrp then return end
                        pcall(function() hrp.CFrame = thrp.CFrame + Vector3.new(0,4,0) end)
                    end)
                    item.LayoutOrder = order
                    order = order + 1
                end
            end
        end
    else
        local items = Categories[name] or {}
        local order = 1
        for _,entry in ipairs(items) do
            if filter == "" or entry.label:lower():find(filter) then
                local state = false
                pcall(function() state = entry.get() end)
                local item, setVisual = createToggleItem(ContentScroll, entry.label, state, function(oldState)
                    pcall(function() entry.toggle(oldState) end)
                    local newState = nil
                    pcall(function() newState = entry.get() end)
                    if newState ~= nil then setVisual(newState) end
                end)
                item.LayoutOrder = order
                order = order + 1
            end
        end
    end
end

-- Tab visuals and handlers
local function setActiveTabVisual(activeTab)
    TabESP.BackgroundColor3 = (activeTab == TabESP) and Color3.fromRGB(34,34,34) or Color3.fromRGB(28,28,28)
    TabTextures.BackgroundColor3 = (activeTab == TabTextures) and Color3.fromRGB(34,34,34) or Color3.fromRGB(28,28,28)
    TabTimers.BackgroundColor3 = (activeTab == TabTimers) and Color3.fromRGB(34,34,34) or Color3.fromRGB(28,28,28)
    TabTeleport.BackgroundColor3 = (activeTab == TabTeleport) and Color3.fromRGB(34,34,34) or Color3.fromRGB(28,28,28)
end

TabESP.MouseButton1Click:Connect(function() currentCategory = "ESP"; setActiveTabVisual(TabESP); buildCategory("ESP", SearchBox.Text) end)
TabTextures.MouseButton1Click:Connect(function() currentCategory = "Textures"; setActiveTabVisual(TabTextures); buildCategory("Textures", SearchBox.Text) end)
TabTimers.MouseButton1Click:Connect(function() currentCategory = "Timers"; setActiveTabVisual(TabTimers); buildCategory("Timers", SearchBox.Text) end)
TabTeleport.MouseButton1Click:Connect(function() currentCategory = "Teleport"; setActiveTabVisual(TabTeleport); buildCategory("Teleport", SearchBox.Text) end)

-- Search behavior (filters current tab)
SearchBox:GetPropertyChangedSignal("Text"):Connect(function()
    buildCategory(currentCategory, SearchBox.Text)
end)

-- Ensure Teleport tab updates when players join/leave
Players.PlayerAdded:Connect(function()
    if currentCategory == "Teleport" then task.delay(0.06, function() buildCategory("Teleport", SearchBox.Text) end) end
end)
Players.PlayerRemoving:Connect(function()
    if currentCategory == "Teleport" then task.delay(0.06, function() buildCategory("Teleport", SearchBox.Text) end) end
end)

-- initial build
setActiveTabVisual(TabESP)
buildCategory("ESP", "")

-- draggable
local dragging, dragStart, startPos = false, nil, nil
MainFrame.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        dragging = true; dragStart = input.Position; startPos = MainFrame.Position
        input.Changed:Connect(function() if input.UserInputState == Enum.UserInputState.End then dragging = false end end)
    end
end)
MainFrame.InputChanged:Connect(function(input)
    if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
        local delta = input.Position - dragStart
        MainFrame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
    end
end)

-- toggle opening with K
local menuOpen = false
UIS.InputBegan:Connect(function(input, gpe) if not gpe and input.KeyCode == Enum.KeyCode.K then menuOpen = not menuOpen; MainFrame.Visible = menuOpen end end)

-- =====================================================================
-- Cleanup function (ensure snow and other listeners are cleaned)
-- =====================================================================
local function cleanupAll()
    if TextureActive then disableTextureToggle() end
    if GraySkinActive then disableGraySkin() end
    if SnowActive then disableSnowTexture() end
    for p,_ in pairs(playerHighlights) do RemovePlayerHighlight(p) end
    for p,_ in pairs(NameTags) do RemoveNameTag(p) end
    for m,_ in pairs(compHighlights) do RemoveComputerHighlight(m) end
    for m,_ in pairs(doorHighlights) do RemoveDoorHighlight(m) end
    for m,_ in pairs(podHighlights) do RemoveFreezePodHighlight(m) end
    for p,conn in pairs(ragdollConnects) do pcall(function() conn:Disconnect() end); ragdollConnects[p]=nil end
    for p,_ in pairs(ragdollBillboards) do removeRagdollBillboard(p) end
    for p,_ in pairs(bottomUI) do if bottomUI[p] and bottomUI[p].screenGui and bottomUI[p].screenGui.Parent then bottomUI[p].screenGui:Destroy() end bottomUI[p]=nil end
    if next(textureBackup) ~= nil then restoreTextures() end
    if doorDescendantAddConn then pcall(function() doorDescendantAddConn:Disconnect() end); doorDescendantAddConn = nil end
    if doorDescendantRemConn then pcall(function() doorDescendantRemConn:Disconnect() end); doorDescendantRemConn = nil end
    if podDescendantAddConn then pcall(function() podDescendantAddConn:Disconnect() end); podDescendantAddConn = nil end
    if podDescendantRemConn then pcall(function() podDescendantRemConn:Disconnect() end); podDescendantRemConn = nil end
    if textureDescendantConn then pcall(function() textureDescendantConn:Disconnect() end); textureDescendantConn = nil end
    if snowPartConn then pcall(function() snowPartConn:Disconnect() end); snowPartConn = nil end
    if MainFrame and MainFrame.Parent then pcall(function() MainFrame:Destroy() end) end
    if GUI and GUI.Parent then pcall(function() GUI:Destroy() end) end
end

Players.PlayerRemoving:Connect(function(p)
    if skinBackup[p] then restoreGrayForPlayer(p); skinBackup[p]=nil end
    if playerHighlights[p] then RemovePlayerHighlight(p) end
    if NameTags[p] then RemoveNameTag(p) end
    if ragdollConnects[p] then pcall(function() ragdollConnects[p]:Disconnect() end); ragdollConnects[p]=nil end
    if ragdollBillboards[p] then removeRagdollBillboard(p) end
    if bottomUI[p] and bottomUI[p].screenGui and bottomUI[p].screenGui.Parent then bottomUI[p].screenGui:Destroy() end bottomUI[p] = nil
    if compHighlights[p] then RemoveComputerHighlight(p) end
    if skinBackup[p] then restoreGrayForPlayer(p); skinBackup[p] = nil end
    if currentCategory == "Teleport" then task.delay(0.05, function() buildCategory("Teleport", SearchBox.Text) end) end
end)

print("[FTF_ESP] Atualizado: removido quick-teleport, Teleport dentro do menu, Snow texture adicionada")
