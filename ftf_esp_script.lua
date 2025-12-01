```lua name=ftf_esp_script.lua
-- FTF ESP Script — Complete final script
-- Features:
--  - Player / Computer / Freeze Pod / Door ESP (enable/disable with full cleanup)
--  - Remove player textures (gray skin), White Brick texture, Snow texture (toggleable, restore)
--  - Down ragdoll timer (toggleable)
--  - Teleport list (dynamic) in a Teleport tab
--  - Modern UI: non-blocking centered loading panel, toast hint, minimize icon (image), mobile toggle
--  - Menu toggle with keyboard "K" (PC). Minimize icon opens menu when clicked.
-- NOTE: Set ICON_IMAGE_ID to your uploaded Roblox asset id for the minimized icon image.

-- ===== CONFIG =====
local ICON_IMAGE_ID = "" -- set to your rbasset id string, e.g. "1234567890"
-- ==================

-- Services
local UIS = game:GetService("UserInputService")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")
local Lighting = game:GetService("Lighting")
local CoreGui = game:GetService("CoreGui")

local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:FindFirstChild("PlayerGui") or LocalPlayer:WaitForChild("PlayerGui")

-- Clean previous GUIs
for _,v in pairs(CoreGui:GetChildren()) do if v.Name == "FTF_ESP_GUI_DAVID" then pcall(function() v:Destroy() end) end end
for _,v in pairs(PlayerGui:GetChildren()) do if v.Name == "FTF_ESP_GUI_DAVID" then pcall(function() v:Destroy() end) end end

-- Root GUI
local GUI = Instance.new("ScreenGui")
GUI.Name = "FTF_ESP_GUI_DAVID"
GUI.ResetOnSpawn = false
GUI.IgnoreGuiInset = true
pcall(function() GUI.Parent = CoreGui end)
if not GUI.Parent or GUI.Parent ~= CoreGui then GUI.Parent = PlayerGui end

local function safeDestroy(obj)
    if obj and obj.Parent then
        pcall(function() obj:Destroy() end)
    end
end

-- ============================================================================
-- CORE FEATURE IMPLEMENTATIONS (full cleanup on disable)
-- ============================================================================

-- PLAYER ESP
local PlayerESPActive = false
local playerHighlights = {}
local playerNameTags = {}
local playerAddedConn, playerRemovingConn

local function isBeast(player)
    return player and player.Character and player.Character:FindFirstChild("BeastPowers") ~= nil
end

local function createPlayerHighlight(player)
    if not player or player == LocalPlayer then return end
    if not player.Character then return end
    if playerHighlights[player] then safeDestroy(playerHighlights[player]); playerHighlights[player] = nil end
    local fill, outline = Color3.fromRGB(52,215,101), Color3.fromRGB(170,255,200)
    if isBeast(player) then fill, outline = Color3.fromRGB(240,28,80), Color3.fromRGB(255,188,188) end
    local h = Instance.new("Highlight")
    h.Name = "[FTF_ESP_PlayerAura_DAVID]"
    h.Adornee = player.Character
    h.Parent = Workspace
    h.FillColor = fill
    h.OutlineColor = outline
    h.FillTransparency = 0.12
    h.OutlineTransparency = 0.04
    h.Enabled = true
    playerHighlights[player] = h
end

local function removePlayerHighlight(player)
    if playerHighlights[player] then safeDestroy(playerHighlights[player]); playerHighlights[player] = nil end
end

local function createPlayerNameTag(player)
    if not player or player == LocalPlayer then return end
    if not player.Character or not player.Character:FindFirstChild("Head") then return end
    if playerNameTags[player] then safeDestroy(playerNameTags[player]); playerNameTags[player] = nil end
    local billboard = Instance.new("BillboardGui")
    billboard.Name = "[FTFName]"
    billboard.Adornee = player.Character.Head
    billboard.Size = UDim2.new(0,110,0,20)
    billboard.StudsOffset = Vector3.new(0,2.18,0)
    billboard.AlwaysOnTop = true
    billboard.Parent = GUI
    local label = Instance.new("TextLabel", billboard)
    label.Size = UDim2.new(1,0,1,0)
    label.BackgroundTransparency = 1
    label.Font = Enum.Font.GothamSemibold
    label.TextSize = 13
    label.TextColor3 = Color3.fromRGB(190,210,230)
    label.Text = player.DisplayName or player.Name
    label.TextXAlignment = Enum.TextXAlignment.Center
    playerNameTags[player] = billboard
end

local function removePlayerNameTag(player)
    if playerNameTags[player] then safeDestroy(playerNameTags[player]); playerNameTags[player] = nil end
end

local function enablePlayerESP()
    if PlayerESPActive then return end
    PlayerESPActive = true
    for _,p in ipairs(Players:GetPlayers()) do
        if p ~= LocalPlayer then createPlayerHighlight(p); createPlayerNameTag(p) end
    end
    if not playerAddedConn then
        playerAddedConn = Players.PlayerAdded:Connect(function(p)
            p.CharacterAdded:Connect(function() task.wait(0.08); if PlayerESPActive then createPlayerHighlight(p); createPlayerNameTag(p) end end)
            if PlayerESPActive and p.Character then createPlayerHighlight(p); createPlayerNameTag(p) end
        end)
    end
    if not playerRemovingConn then
        playerRemovingConn = Players.PlayerRemoving:Connect(function(p) removePlayerHighlight(p); removePlayerNameTag(p) end)
    end
end

local function disablePlayerESP()
    if not PlayerESPActive then return end
    PlayerESPActive = false
    for p,h in pairs(playerHighlights) do safeDestroy(h); playerHighlights[p] = nil end
    for p,b in pairs(playerNameTags) do safeDestroy(b); playerNameTags[p] = nil end
    if playerAddedConn then pcall(function() playerAddedConn:Disconnect() end); playerAddedConn = nil end
    if playerRemovingConn then pcall(function() playerRemovingConn:Disconnect() end); playerRemovingConn = nil end
end

local function TogglePlayerESP() if PlayerESPActive then disablePlayerESP() else enablePlayerESP() end end

-- COMPUTER ESP
local ComputerESPActive = false
local compHighlights = {}
local compDescAddedConn, compDescRemovingConn

local function isComputerModel(model)
    return model and model:IsA("Model") and (model.Name:lower():find("computer") or model.Name:lower():find("pc"))
end

local function addComputerHighlight(model)
    if not model then return end
    if compHighlights[model] then safeDestroy(compHighlights[model]); compHighlights[model] = nil end
    local h = Instance.new("Highlight")
    h.Name = "[FTF_ESP_ComputerAura_DAVID]"
    h.Adornee = model
    h.Parent = Workspace
    h.FillColor = Color3.fromRGB(77,164,255)
    h.OutlineColor = Color3.fromRGB(210,210,210)
    h.FillTransparency = 0.10
    h.OutlineTransparency = 0.03
    h.Enabled = true
    compHighlights[model] = h
end

local function removeComputerHighlight(model)
    if compHighlights[model] then safeDestroy(compHighlights[model]); compHighlights[model] = nil end
end

local function enableComputerESP()
    if ComputerESPActive then return end
    ComputerESPActive = true
    for _,d in ipairs(Workspace:GetDescendants()) do if isComputerModel(d) then addComputerHighlight(d) end end
    if not compDescAddedConn then
        compDescAddedConn = Workspace.DescendantAdded:Connect(function(obj)
            if not ComputerESPActive then return end
            if isComputerModel(obj) then task.delay(0.05, function() addComputerHighlight(obj) end) end
            if obj:IsA("BasePart") then local mdl = obj:FindFirstAncestorWhichIsA("Model"); if mdl and isComputerModel(mdl) then task.delay(0.05, function() addComputerHighlight(mdl) end) end end
        end)
    end
    if not compDescRemovingConn then compDescRemovingConn = Workspace.DescendantRemoving:Connect(function(obj) removeComputerHighlight(obj) end) end
end

local function disableComputerESP()
    if not ComputerESPActive then return end
    ComputerESPActive = false
    for m,h in pairs(compHighlights) do safeDestroy(h); compHighlights[m] = nil end
    if compDescAddedConn then pcall(function() compDescAddedConn:Disconnect() end); compDescAddedConn = nil end
    if compDescRemovingConn then pcall(function() compDescRemovingConn:Disconnect() end); compDescRemovingConn = nil end
end

local function ToggleComputerESP() if ComputerESPActive then disableComputerESP() else enableComputerESP() end end

-- FREEZE PODS
local FreezePodsActive = false
local podHighlights = {}
local podDescAddedConn, podDescRemovingConn

local function isFreezePodModel(model)
    if not model or not model:IsA("Model") then return false end
    local name = model.Name:lower()
    if name:find("freezepod") then return true end
    if name:find("freeze") and name:find("pod") then return true end
    if name:find("freeze") and name:find("capsule") then return true end
    return false
end

local function addPodHighlight(model)
    if not model then return end
    if podHighlights[model] then safeDestroy(podHighlights[model]); podHighlights[model] = nil end
    local h = Instance.new("Highlight")
    h.Name = "[FTF_ESP_FreezePodAura_DAVID]"
    h.Adornee = model
    h.Parent = Workspace
    h.FillColor = Color3.fromRGB(255,100,100)
    h.OutlineColor = Color3.fromRGB(200,40,40)
    h.FillTransparency = 0.08
    h.OutlineTransparency = 0.02
    h.Enabled = true
    podHighlights[model] = h
end

local function removePodHighlight(model)
    if podHighlights[model] then safeDestroy(podHighlights[model]); podHighlights[model] = nil end
end

local function enableFreezePodsESP()
    if FreezePodsActive then return end
    FreezePodsActive = true
    for _,d in ipairs(Workspace:GetDescendants()) do if isFreezePodModel(d) then addPodHighlight(d) end end
    if not podDescAddedConn then
        podDescAddedConn = Workspace.DescendantAdded:Connect(function(desc)
            if not FreezePodsActive then return end
            if isFreezePodModel(desc) then task.delay(0.05, function() addPodHighlight(desc) end) end
            if desc:IsA("BasePart") then local mdl = desc:FindFirstAncestorWhichIsA("Model"); if mdl and isFreezePodModel(mdl) then task.delay(0.05, function() addPodHighlight(mdl) end) end end
        end)
    end
    if not podDescRemovingConn then podDescRemovingConn = Workspace.DescendantRemoving:Connect(function(desc) removePodHighlight(desc) end) end
end

local function disableFreezePodsESP()
    if not FreezePodsActive then return end
    FreezePodsActive = false
    for m,h in pairs(podHighlights) do safeDestroy(h); podHighlights[m] = nil end
    if podDescAddedConn then pcall(function() podDescAddedConn:Disconnect() end); podDescAddedConn = nil end
    if podDescRemovingConn then pcall(function() podDescRemovingConn:Disconnect() end); podDescRemovingConn = nil end
end

local function ToggleFreezePodsESP() if FreezePodsActive then disableFreezePodsESP() else enableFreezePodsESP() end end

-- DOOR AURA
local DoorESPActive = false
local doorHighlights = {}
local doorDescAddedConn, doorDescRemovingConn

local function isDoorModel(model)
    if not model or not model:IsA("Model") then return false end
    local name = model.Name:lower()
    if name:find("door") then return true end
    if name:find("exitdoor") then return true end
    if name:find("single") and name:find("door") then return true end
    if name:find("double") and name:find("door") then return true end
    return false
end

local function addDoorAura(model)
    if not model then return end
    if doorHighlights[model] then safeDestroy(doorHighlights[model]); doorHighlights[model] = nil end
    local h = Instance.new("Highlight")
    h.Name = "[FTF_ESP_DoorAura_DAVID]"
    h.Adornee = model
    h.Parent = Workspace
    h.FillTransparency = 1
    h.OutlineTransparency = 0
    h.OutlineColor = Color3.fromRGB(255,230,120)
    h.Enabled = true
    doorHighlights[model] = h
end

local function removeDoorAura(model)
    if doorHighlights[model] then safeDestroy(doorHighlights[model]); doorHighlights[model] = nil end
end

local function enableDoorESP()
    if DoorESPActive then return end
    DoorESPActive = true
    for _,d in ipairs(Workspace:GetDescendants()) do if d:IsA("Model") and isDoorModel(d) then addDoorAura(d) end end
    if not doorDescAddedConn then
        doorDescAddedConn = Workspace.DescendantAdded:Connect(function(desc)
            if not DoorESPActive then return end
            if desc:IsA("Model") and isDoorModel(desc) then task.delay(0.04, function() addDoorAura(desc) end) end
            if desc:IsA("BasePart") then local mdl = desc:FindFirstAncestorWhichIsA("Model"); if mdl and isDoorModel(mdl) then task.delay(0.04, function() addDoorAura(mdl) end) end end
        end)
    end
    if not doorDescRemovingConn then
        doorDescRemovingConn = Workspace.DescendantRemoving:Connect(function(desc)
            if desc:IsA("Model") and doorHighlights[desc] then removeDoorAura(desc) end
            if desc:IsA("BasePart") then local mdl = desc:FindFirstAncestorWhichIsA("Model"); if mdl and doorHighlights[mdl] then removeDoorAura(mdl) end end
        end)
    end
end

local function disableDoorESP()
    if not DoorESPActive then return end
    DoorESPActive = false
    for m,h in pairs(doorHighlights) do safeDestroy(h); doorHighlights[m] = nil end
    if doorDescAddedConn then pcall(function() doorDescAddedConn:Disconnect() end); doorDescAddedConn = nil end
    if doorDescRemovingConn then pcall(function() doorDescRemovingConn:Disconnect() end); doorDescRemovingConn = nil end
end

local function ToggleDoorESP() if DoorESPActive then disableDoorESP() else enableDoorESP() end end

-- DOWN TIMER (Ragdoll)
local DownTimerActive = false
local DOWN_TIME = 28
local ragdollBillboards = {}
local ragdollConnects = {}
local bottomUI = {}

local function createRagdollBillboardFor(player)
    if ragdollBillboards[player] then return ragdollBillboards[player] end
    if not player.Character then return nil end
    local head = player.Character:FindFirstChild("Head"); if not head then return nil end
    local billboard = Instance.new("BillboardGui", GUI)
    billboard.Name = "[FTF_RagdollTimer]"
    billboard.Adornee = head
    billboard.Size = UDim2.new(0,140,0,44)
    billboard.StudsOffset = Vector3.new(0,3.2,0)
    billboard.AlwaysOnTop = true
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

local function removeRagdollBillboard(player)
    if ragdollBillboards[player] then if ragdollBillboards[player].gui and ragdollBillboards[player].gui.Parent then safeDestroy(ragdollBillboards[player].gui) end ragdollBillboards[player] = nil end
end

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
            if bottomUI[player] then if bottomUI[player].screenGui and bottomUI[player].screenGui.Parent then safeDestroy(bottomUI[player].screenGui) end bottomUI[player] = nil end
        else
            local remaining = info.endTime - now
            if remaining <= 0 then
                removeRagdollBillboard(player)
                if bottomUI[player] then if bottomUI[player].screenGui and bottomUI[player].screenGui.Parent then safeDestroy(bottomUI[player].screenGui) end bottomUI[player] = nil end
            else
                if info.label and info.label.Parent then info.label.Text = string.format("%.2f", remaining); info.label.TextColor3 = remaining <= 5 and Color3.fromRGB(255,90,90) or Color3.fromRGB(220,220,230) end
                if info.progress and info.progress.Parent then local frac = math.clamp(remaining / DOWN_TIME, 0, 1); info.progress.Size = UDim2.new(frac,0,1,0); if frac > 0.5 then info.progress.BackgroundColor3 = Color3.fromRGB(90,180,255) elseif frac > 0.15 then info.progress.BackgroundColor3 = Color3.fromRGB(240,200,60) else info.progress.BackgroundColor3 = Color3.fromRGB(255,90,90) end end
                if bottomUI[player] then bottomUI[player].timerLabel.Text = string.format("%.2f", remaining) end
            end
        end
    end
end)

local function attachRagdollListenerToPlayer(player)
    if ragdollConnects[player] then pcall(function() ragdollConnects[player]:Disconnect() end); ragdollConnects[player] = nil end
    task.spawn(function()
        local ok, tempStats = pcall(function() return player:WaitForChild("TempPlayerStatsModule", 8) end)
        if not ok or not tempStats then return end
        local ok2, ragdoll = pcall(function() return tempStats:WaitForChild("Ragdoll", 8) end)
        if not ok2 or not ragdoll then return end
        pcall(function() if ragdoll.Value and DownTimerActive then local info = createRagdollBillboardFor(player); if info then info.endTime = tick() + DOWN_TIME; updateBottomRightFor(player, info.endTime) end end end)
        local conn = ragdoll.Changed:Connect(function()
            pcall(function()
                if ragdoll.Value then
                    if DownTimerActive then local info = createRagdollBillboardFor(player); if info then info.endTime = tick() + DOWN_TIME; updateBottomRightFor(player, info.endTime) end end
                else
                    removeRagdollBillboard(player)
                end
            end)
        end)
        ragdollConnects[player] = conn
    end)
end

for _,p in pairs(Players:GetPlayers()) do attachRagdollListenerToPlayer(p) end
Players.PlayerAdded:Connect(function(p) attachRagdollListenerToPlayer(p); p.CharacterAdded:Connect(function() task.wait(0.06); if ragdollBillboards[p] then removeRagdollBillboard(p); if DownTimerActive then createRagdollBillboardFor(p) end end end) end)

local function ToggleDownTimer()
    DownTimerActive = not DownTimerActive
    if DownTimerActive then
        for _,p in pairs(Players:GetPlayers()) do
            local ok, temp = pcall(function() return p:FindFirstChild("TempPlayerStatsModule") end)
            if ok and temp then
                local rag = temp:FindFirstChild("Ragdoll")
                if rag and rag.Value then local info = createRagdollBillboardFor(p); if info then info.endTime = tick() + DOWN_TIME; updateBottomRightFor(p, info.endTime) end end
            end
        end
    else
        for p,_ in pairs(ragdollBillboards) do if ragdollBillboards[p] then removeRagdollBillboard(p) end end
        for p,_ in pairs(bottomUI) do if bottomUI[p] and bottomUI[p].screenGui and bottomUI[p].screenGui.Parent then safeDestroy(bottomUI[p].screenGui) end bottomUI[p] = nil end
    end
end

-- GRAY SKIN
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
    if GraySkinActive then return end
    GraySkinActive = true
    for _,p in pairs(Players:GetPlayers()) do
        if p ~= LocalPlayer then applyGrayToCharacter(p) end
        if not grayConns[p] then
            grayConns[p] = p.CharacterAdded:Connect(function() task.wait(0.06); if GraySkinActive then applyGrayToCharacter(p) end end)
        end
    end
    if not grayConns._playerAddedConn then
        grayConns._playerAddedConn = Players.PlayerAdded:Connect(function(p) if p ~= LocalPlayer and GraySkinActive then if p.Character then applyGrayToCharacter(p) end; if not grayConns[p] then grayConns[p] = p.CharacterAdded:Connect(function() task.wait(0.06); if GraySkinActive then applyGrayToCharacter(p) end end) end end end)
    end
end

local function disableGraySkin()
    if not GraySkinActive then return end
    GraySkinActive = false
    for p,_ in pairs(skinBackup) do pcall(function() restoreGrayForPlayer(p) end) end
    skinBackup = {}
    for k,conn in pairs(grayConns) do pcall(function() conn:Disconnect() end); grayConns[k] = nil end
end

local function ToggleGraySkin() if GraySkinActive then disableGraySkin() else enableGraySkin() end end

-- WHITE BRICK TEXTURE
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

local function ToggleTexture() if TextureActive then disableTextureToggle() else enableTextureToggle() end end

-- SNOW TEXTURE (toggleable)
local SnowActive = false
local snowBackupParts = {}
local snowPartConn = nil
local snowLightingBackup = nil
local snowSkyBackup = {}
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
    backupLighting()
    for _,v in pairs(Lighting:GetChildren()) do
        if v:IsA("Sky") then
            pcall(function() table.insert(snowSkyBackup, v:Clone()) end)
            pcall(function() v:Destroy() end)
        end
    end
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
    local sky = Instance.new("Sky")
    sky.SkyboxBk = ""; sky.SkyboxDn = ""; sky.SkyboxFt = ""; sky.SkyboxLf = ""; sky.SkyboxRt = ""; sky.SkyboxUp = ""
    sky.Parent = Lighting
    createdSnowSky = sky
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
    if snowPartConn then pcall(function() snowPartConn:Disconnect() end); snowPartConn = nil end
    for part, props in pairs(snowBackupParts) do
        if part and part.Parent then
            pcall(function()
                if props.Material then part.Material = props.Material end
                if props.Color then part.Color = props.Color end
            end)
        end
    end
    snowBackupParts = {}
    if createdSnowSky and createdSnowSky.Parent then pcall(function() createdSnowSky:Destroy() end) end
    createdSnowSky = nil
    for _,cloneSky in ipairs(snowSkyBackup) do if cloneSky then pcall(function() cloneSky.Parent = Lighting end) end end
    snowSkyBackup = {}
    restoreLighting()
end

local function ToggleSnow() if SnowActive then disableSnowTexture() else enableSnowTexture() end end

-- ============================================================================
-- UI: Non-blocking loading panel + toast + minimized icon + mobile toggle + menu
-- ============================================================================

-- Loading center panel only (no full-screen gray overlay)
local LoadingPanel = Instance.new("Frame", GUI)
LoadingPanel.Name = "FTF_LoadingPanel"
LoadingPanel.Size = UDim2.new(0, 420, 0, 120)
LoadingPanel.Position = UDim2.new(0.5, -210, 0.45, -60)
LoadingPanel.BackgroundColor3 = Color3.fromRGB(18,18,20)
LoadingPanel.BorderSizePixel = 0
local lpCorner = Instance.new("UICorner", LoadingPanel); lpCorner.CornerRadius = UDim.new(0,14)
local lpStroke = Instance.new("UIStroke", LoadingPanel); lpStroke.Color = Color3.fromRGB(40,40,48); lpStroke.Thickness = 1; lpStroke.Transparency = 0.3

local lpTitle = Instance.new("TextLabel", LoadingPanel)
lpTitle.Size = UDim2.new(1, -40, 0, 36); lpTitle.Position = UDim2.new(0, 20, 0, 14)
lpTitle.BackgroundTransparency = 1; lpTitle.Font = Enum.Font.FredokaOne; lpTitle.TextSize = 20
lpTitle.TextColor3 = Color3.fromRGB(220,220,230); lpTitle.Text = "Loading FTF hub - By David"; lpTitle.TextXAlignment = Enum.TextXAlignment.Left

local lpSub = Instance.new("TextLabel", LoadingPanel)
lpSub.Size = UDim2.new(1, -40, 0, 18); lpSub.Position = UDim2.new(0, 20, 0, 56)
lpSub.BackgroundTransparency = 1; lpSub.Font = Enum.Font.Gotham; lpSub.TextSize = 12
lpSub.TextColor3 = Color3.fromRGB(170,170,180); lpSub.Text = "Initializing..."; lpSub.TextXAlignment = Enum.TextXAlignment.Left

local spinner = Instance.new("Frame", LoadingPanel)
spinner.Size = UDim2.new(0, 40, 0, 40); spinner.Position = UDim2.new(1, -64, 0, 20)
spinner.BackgroundColor3 = Color3.fromRGB(24,24,26)
local spCorner = Instance.new("UICorner", spinner); spCorner.CornerRadius = UDim.new(0,10)
local inner = Instance.new("Frame", spinner)
inner.Size = UDim2.new(0, 24, 0, 24); inner.Position = UDim2.new(0.5, -12, 0.5, -12)
inner.BackgroundColor3 = Color3.fromRGB(60,160,255)
local innerCorner = Instance.new("UICorner", inner); innerCorner.CornerRadius = UDim.new(0,8)
local spinTween = TweenService:Create(spinner, TweenInfo.new(1.2, Enum.EasingStyle.Linear, Enum.EasingDirection.InOut, -1, true), {Rotation = 360})
spinTween:Play()

-- Toast
local Toast = Instance.new("Frame", GUI)
Toast.Name = "FTF_Toast"
Toast.Size = UDim2.new(0, 360, 0, 46)
Toast.Position = UDim2.new(0.5, -180, 0.02, 0)
Toast.BackgroundColor3 = Color3.fromRGB(20,20,22)
Toast.BorderSizePixel = 0
Toast.Visible = false
local toastCorner = Instance.new("UICorner", Toast); toastCorner.CornerRadius = UDim.new(0,12)
local toastLabel = Instance.new("TextLabel", Toast)
toastLabel.Size = UDim2.new(1, -48, 1, 0); toastLabel.Position = UDim2.new(0, 12, 0, 0)
toastLabel.BackgroundTransparency = 1; toastLabel.Font = Enum.Font.GothamSemibold; toastLabel.TextSize = 14
toastLabel.TextColor3 = Color3.fromRGB(220,220,220); toastLabel.Text = "Use the letter K on your keyboard to open the MENU."; toastLabel.TextXAlignment = Enum.TextXAlignment.Left
local toastClose = Instance.new("TextButton", Toast)
toastClose.Size = UDim2.new(0, 28, 0, 28); toastClose.Position = UDim2.new(1, -40, 0.5, -14)
toastClose.Text = "✕"; toastClose.Font = Enum.Font.Gotham; toastClose.TextSize = 16; toastClose.BackgroundColor3 = Color3.fromRGB(16,16,16)
local tcCorner = Instance.new("UICorner", toastClose); tcCorner.CornerRadius = UDim.new(0,8)
toastClose.MouseButton1Click:Connect(function() Toast.Visible = false end)

-- Minimized icon (ImageButton)
local MinimizedIcon = Instance.new("ImageButton", GUI)
MinimizedIcon.Name = "FTF_MinimizedIcon"
MinimizedIcon.Size = UDim2.new(0, 56, 0, 56)
MinimizedIcon.Position = UDim2.new(0.02, 0, 0.06, 0)
MinimizedIcon.BackgroundColor3 = Color3.fromRGB(24,24,26)
MinimizedIcon.BorderSizePixel = 0
MinimizedIcon.Visible = false
MinimizedIcon.AutoButtonColor = true
local miCorner = Instance.new("UICorner", MinimizedIcon); miCorner.CornerRadius = UDim.new(0,12)
local miStroke = Instance.new("UIStroke", MinimizedIcon); miStroke.Color = Color3.fromRGB(30,80,130); miStroke.Transparency = 0.7
if ICON_IMAGE_ID ~= "" then MinimizedIcon.Image = "rbxassetid://"..tostring(ICON_IMAGE_ID) end

-- Mobile quick open button
local MobileToggle = Instance.new("TextButton", GUI)
MobileToggle.Name = "FTF_MobileToggle"
MobileToggle.Size = UDim2.new(0, 56, 0, 56)
MobileToggle.Position = UDim2.new(0.02, 68, 0.06, 0)
MobileToggle.BackgroundColor3 = Color3.fromRGB(24,24,26)
MobileToggle.BorderSizePixel = 0
MobileToggle.Text = "☰"
MobileToggle.Font = Enum.Font.GothamBold
MobileToggle.TextColor3 = Color3.fromRGB(220,220,220)
MobileToggle.Visible = UIS.TouchEnabled and true or false
local mtCorner = Instance.new("UICorner", MobileToggle); mtCorner.CornerRadius = UDim.new(0,12)
local mtStroke = Instance.new("UIStroke", MobileToggle); mtStroke.Color = Color3.fromRGB(30,80,130); mtStroke.Transparency = 0.75

-- Main menu (tabs, search, toggles)
local MENU_WIDTH = 520
local MENU_HEIGHT = 380

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
TitleLbl.Size = UDim2.new(0,260,0,24)
TitleLbl.TextXAlignment = Enum.TextXAlignment.Left

local SearchBox = Instance.new("TextBox", TitleBar)
SearchBox.Size = UDim2.new(0, 220, 0, 28)
SearchBox.Position = UDim2.new(1, -240, 0, 10)
SearchBox.BackgroundColor3 = Color3.fromRGB(26,26,26)
SearchBox.TextColor3 = Color3.fromRGB(200,200,200)
SearchBox.PlaceholderText = ""
SearchBox.Text = ""
SearchBox.ClearTextOnFocus = true
local sbCorner = Instance.new("UICorner", SearchBox); sbCorner.CornerRadius = UDim.new(0,8)
local sbPadding = Instance.new("UIPadding", SearchBox); sbPadding.PaddingLeft = UDim.new(0,10)

-- Minimize button in titlebar (minimizes to icon)
local MinimizeBtn = Instance.new("TextButton", TitleBar)
MinimizeBtn.Text = "—"
MinimizeBtn.Font = Enum.Font.GothamBold
MinimizeBtn.TextSize = 20
MinimizeBtn.BackgroundTransparency = 1
MinimizeBtn.Size = UDim2.new(0,36,0,36)
MinimizeBtn.Position = UDim2.new(1,-92,0,6)
MinimizeBtn.TextColor3 = Color3.fromRGB(200,200,200)
MinimizeBtn.AutoButtonColor = false

-- Close/hide button (no minimized icon shown)
local CloseBtn = Instance.new("TextButton", TitleBar)
CloseBtn.Text = "✕"
CloseBtn.Font = Enum.Font.GothamBold
CloseBtn.TextSize = 18
CloseBtn.BackgroundTransparency = 1
CloseBtn.Size = UDim2.new(0,36,0,36)
CloseBtn.Position = UDim2.new(1,-44,0,6)
CloseBtn.TextColor3 = Color3.fromRGB(200,200,200)
CloseBtn.AutoButtonColor = false

-- Tabs
local TabsParent = Instance.new("Frame", MainFrame)
TabsParent.Size = UDim2.new(1, -24, 0, 44)
TabsParent.Position = UDim2.new(0,12,0,56)
TabsParent.BackgroundTransparency = 1

local tabNames = {"ESP","Textures","Timers","Teleport"}
local tabPadding = 10
local tabCount = #tabNames
local tabAvailableWidth = MENU_WIDTH - 24
local tabWidth = math.max(80, math.floor((tabAvailableWidth - (tabPadding * (tabCount - 1))) / tabCount))
local Tabs = {}
for i,name in ipairs(tabNames) do
    local x = (i-1) * (tabWidth + tabPadding)
    local t = Instance.new("TextButton", TabsParent)
    t.Size = UDim2.new(0, tabWidth, 0, 34)
    t.Position = UDim2.new(0, x, 0, 4)
    t.Text = name
    t.Font = Enum.Font.GothamSemibold
    t.TextSize = 14
    t.TextColor3 = Color3.fromRGB(200,200,200)
    t.BackgroundColor3 = Color3.fromRGB(28,28,28)
    t.AutoButtonColor = false
    local c = Instance.new("UICorner", t); c.CornerRadius = UDim.new(0,12)
    Tabs[name] = t
end

local TabESP = Tabs["ESP"]
local TabTextures = Tabs["Textures"]
local TabTimers = Tabs["Timers"]
local TabTeleport = Tabs["Teleport"]

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

-- UI helpers (toggle & button)
local function createToggleItem(parent, labelText, initial, onToggle)
    local item = Instance.new("Frame", parent)
    item.Size = UDim2.new(0.95, 0, 0, 44)
    item.BackgroundColor3 = Color3.fromRGB(28,28,28)
    item.BorderSizePixel = 0
    local itemCorner = Instance.new("UICorner", item); itemCorner.CornerRadius = UDim.new(0,10)
    local lbl = Instance.new("TextLabel", item)
    lbl.Size = UDim2.new(1, -120, 1, 0); lbl.Position = UDim2.new(0,12,0,0)
    lbl.BackgroundTransparency = 1; lbl.Font = Enum.Font.Gotham; lbl.TextSize = 14; lbl.TextColor3 = Color3.fromRGB(210,210,210)
    lbl.TextXAlignment = Enum.TextXAlignment.Left; lbl.Text = labelText
    local sw = Instance.new("TextButton", item); sw.Size = UDim2.new(0,88,0,28); sw.Position = UDim2.new(1, -100, 0.5, -14)
    sw.BackgroundColor3 = Color3.fromRGB(38,38,38); sw.AutoButtonColor = false
    local swCorner = Instance.new("UICorner", sw); swCorner.CornerRadius = UDim.new(0,16)
    local swBg = Instance.new("Frame", sw); swBg.Size = UDim2.new(1, -8, 1, -8); swBg.Position = UDim2.new(0,4,0,4); swBg.BackgroundColor3 = Color3.fromRGB(60,60,60)
    local swBgCorner = Instance.new("UICorner", swBg); swBgCorner.CornerRadius = UDim.new(0,14)
    local toggleDot = Instance.new("Frame", swBg); toggleDot.Size = UDim2.new(0,20,0,20)
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
        pcall(function() onToggle() end)
        updateVisual(not state)
    end)
    updateVisual(state)
    return item, function(newState) updateVisual(newState) end, function() return state end, lbl
end

local function createButtonItem(parent, labelText, buttonText, callback)
    local item = Instance.new("Frame", parent)
    item.Size = UDim2.new(0.95, 0, 0, 44)
    item.BackgroundColor3 = Color3.fromRGB(28,28,28); item.BorderSizePixel = 0
    local itemCorner = Instance.new("UICorner", item); itemCorner.CornerRadius = UDim.new(0,10)
    local lbl = Instance.new("TextLabel", item)
    lbl.Size = UDim2.new(1, -120, 1, 0); lbl.Position = UDim2.new(0,12,0,0)
    lbl.BackgroundTransparency = 1; lbl.Font = Enum.Font.Gotham; lbl.TextSize = 14; lbl.TextColor3 = Color3.fromRGB(210,210,210)
    lbl.TextXAlignment = Enum.TextXAlignment.Left; lbl.Text = labelText
    local btn = Instance.new("TextButton", item)
    btn.Size = UDim2.new(0,88,0,28); btn.Position = UDim2.new(1, -100, 0.5, -14)
    btn.BackgroundColor3 = Color3.fromRGB(38,120,190); btn.AutoButtonColor = false
    local btnCorner = Instance.new("UICorner", btn); btnCorner.CornerRadius = UDim.new(0,12)
    btn.Font = Enum.Font.GothamBold; btn.TextSize = 14; btn.TextColor3 = Color3.fromRGB(240,240,240); btn.Text = buttonText
    btn.MouseButton1Click:Connect(function() pcall(callback) end)
    return item, lbl, btn
end

-- Categories mapping
local Categories = {
    ["ESP"] = {
        { label = "ESP Players", get = function() return PlayerESPActive end, toggle = function() TogglePlayerESP() end },
        { label = "ESP PCs", get = function() return ComputerESPActive end, toggle = function() ToggleComputerESP() end },
        { label = "ESP Freeze Pods", get = function() return FreezePodsActive end, toggle = function() ToggleFreezePodsESP() end },
        { label = "ESP Exit Doors", get = function() return DoorESPActive end, toggle = function() ToggleDoorESP() end },
    },
    ["Textures"] = {
        { label = "Remove players Textures", get = function() return GraySkinActive end, toggle = function() ToggleGraySkin() end },
        { label = "Ativar Textures Tijolos Brancos", get = function() return TextureActive end, toggle = function() ToggleTexture() end },
        { label = "Snow texture", get = function() return SnowActive end, toggle = function() ToggleSnow() end },
    },
    ["Timers"] = {
        { label = "Ativar Contador de Down", get = function() return DownTimerActive end, toggle = function() ToggleDownTimer() end },
    },
}

-- Build content
local currentCategory = "ESP"
local function clearContent()
    for _,v in pairs(ContentScroll:GetChildren()) do if v:IsA("Frame") then v:Destroy() end end
end

local function buildCategory(name, filter)
    filter = (filter or ""):lower()
    clearContent()
    if name == "Teleport" then
        local order = 1
        local players = Players:GetPlayers()
        table.sort(players, function(a,b) return ((a.DisplayName or ""):lower()..a.Name:lower()) < ((b.DisplayName or ""):lower()..b.Name:lower()) end)
        for _,pl in ipairs(players) do
            if pl ~= LocalPlayer then
                local display = (pl.DisplayName or pl.Name) .. " (" .. pl.Name .. ")"
                if filter == "" or display:lower():find(filter) then
                    local item, lbl, btn = createButtonItem(ContentScroll, display, "Teleport", function()
                        local myChar = LocalPlayer.Character; local targetChar = pl.Character
                        if not myChar or not targetChar then return end
                        local hrp = myChar:FindFirstChild("HumanoidRootPart") or myChar:FindFirstChild("Torso") or myChar:FindFirstChild("UpperTorso")
                        local thrp = targetChar:FindFirstChild("HumanoidRootPart") or targetChar:FindFirstChild("Torso") or targetChar:FindFirstChild("UpperTorso")
                        if not hrp or not thrp then return end
                        pcall(function() hrp.CFrame = thrp.CFrame + Vector3.new(0,4,0) end)
                    end)
                    item.LayoutOrder = order; order = order + 1
                end
            end
        end
    else
        local items = Categories[name] or {}
        local order = 1
        for _,entry in ipairs(items) do
            if filter == "" or entry.label:lower():find(filter) then
                local ok, state = pcall(function() return entry.get() end)
                state = ok and state or false
                local item, setVisual = createToggleItem(ContentScroll, entry.label, state, function()
                    pcall(function() entry.toggle() end)
                    local ok2, newState = pcall(function() return entry.get() end)
                    if ok2 and setVisual then pcall(function() setVisual(newState) end) end
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

SearchBox:GetPropertyChangedSignal("Text"):Connect(function() buildCategory(currentCategory, SearchBox.Text) end)
Players.PlayerAdded:Connect(function() if currentCategory == "Teleport" then task.delay(0.06, function() buildCategory("Teleport", SearchBox.Text) end) end end)
Players.PlayerRemoving:Connect(function() if currentCategory == "Teleport" then task.delay(0.06, function() buildCategory("Teleport", SearchBox.Text) end) end end)

-- Draggable main frame
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

-- Minimize behavior: hide MainFrame and show MinimizedIcon
MinimizeBtn.MouseButton1Click:Connect(function()
    MainFrame.Visible = false
    MinimizedIcon.Visible = true
end)

-- Restore from minimized icon
MinimizedIcon.MouseButton1Click:Connect(function()
    MainFrame.Visible = true
    MinimizedIcon.Visible = false
end)

-- Close: hide menu without showing icon
CloseBtn.MouseButton1Click:Connect(function()
    MainFrame.Visible = false
end)

-- Mobile toggle
MobileToggle.MouseButton1Click:Connect(function()
    MainFrame.Visible = not MainFrame.Visible
    if MainFrame.Visible then MinimizedIcon.Visible = false end
end)

-- Keyboard K toggles menu (PC). Opening via K hides minimized icon.
local menuOpen = false
UIS.InputBegan:Connect(function(input, gpe)
    if gpe then return end
    if input.UserInputType == Enum.UserInputType.Keyboard and input.KeyCode == Enum.KeyCode.K then
        menuOpen = not menuOpen
        MainFrame.Visible = menuOpen
        if menuOpen then MinimizedIcon.Visible = false end
    end
end)

-- Show toast & finish loading after short delay
local function finishLoading()
    spinTween:Cancel()
    safeDestroy(LoadingPanel)
    Toast.Visible = true
    TweenService:Create(Toast, TweenInfo.new(0.28, Enum.EasingStyle.Quad), {Position = UDim2.new(0.5, -180, 0.02, 0)}):Play()
    task.delay(8, function()
        if Toast and Toast.Parent then
            TweenService:Create(Toast, TweenInfo.new(0.24, Enum.EasingStyle.Quad), {Position = UDim2.new(0.5, -180, -0.08, 0)}):Play()
            task.delay(0.26, function() if Toast and Toast.Parent then Toast.Visible = false end end)
        end
    end)
end

-- Initial build
setActiveTabVisual(TabESP)
buildCategory("ESP", "")

-- Finish loading: show menu and remove loading panel
task.spawn(function()
    task.wait(1.15)
    MainFrame.Visible = true
    menuOpen = true
    finishLoading()
end)

-- Expose toggles for external use/debug
_G.FTF = _G.FTF or {}
_G.FTF.TogglePlayerESP = TogglePlayerESP
_G.FTF.ToggleComputerESP = ToggleComputerESP
_G.FTF.ToggleFreezePodsESP = ToggleFreezePodsESP
_G.FTF.ToggleDoorESP = ToggleDoorESP
_G.FTF.ToggleTexture = ToggleTexture
_G.FTF.ToggleSnow = ToggleSnow
_G.FTF.ToggleGraySkin = ToggleGraySkin
_G.FTF.ToggleDownTimer = ToggleDownTimer
_G.FTF.DisableAllESP = function() disablePlayerESP(); disableComputerESP(); disableFreezePodsESP(); disableDoorESP() end

print("[FTF_ESP] Complete script loaded — loading panel shown, menu ready.")
```
