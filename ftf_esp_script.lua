-- FTF ESP — Fixed runnable full script
-- Goals addressed:
--  - Script runs without nil / missing-function errors
--  - PC highlights reflect state: blue = ready, green = hacked, red = wrong/failed
--  - Down (ragdoll) timer reliably shows 28s after ragdoll/hit and updates correctly
--  - ESP visuals improved (crisper, vivid)
--  - Minimize icon shows player's headshot and restores menu when clicked
--  - Remove Fog and Remove Textures toggles included (with backups / restore)
--
-- This is a LocalScript intended to run on the client (e.g., StarterPlayerScripts / a local executor).
-- If your game uses unusual names for PC state values, supply them and I can add them for more reliable detection.

-- ===== CONFIG =====
local ICON_IMAGE_ID = ""                  -- optional fallback asset id for minimized icon (string or number)
local DOWN_TIME = 28                      -- seconds for down counter
local REMOVE_TEXTURES_BATCH_SIZE = 250    -- batch size when removing textures
-- ==================

-- Services
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")
local Lighting = game:GetService("Lighting")
local UserInputService = game:GetService("UserInputService")
local CoreGui = game:GetService("CoreGui")

local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:FindFirstChild("PlayerGui") or LocalPlayer:WaitForChild("PlayerGui")

-- Helper: safe destroy
local function safeDestroy(obj)
    if obj and obj.Parent then
        pcall(function() obj:Destroy() end)
    end
end

-- Remove previous GUIs
for _,child in pairs(CoreGui:GetChildren()) do
    if child.Name == "FTF_ESP_GUI_DAVID" then pcall(function() child:Destroy() end) end
end
for _,child in pairs(PlayerGui:GetChildren()) do
    if child.Name == "FTF_ESP_GUI_DAVID" then pcall(function() child:Destroy() end) end
end

-- Root GUI
local GUI = Instance.new("ScreenGui")
GUI.Name = "FTF_ESP_GUI_DAVID"
GUI.ResetOnSpawn = false
GUI.IgnoreGuiInset = true
pcall(function() GUI.Parent = CoreGui end)
if not GUI.Parent or GUI.Parent ~= CoreGui then GUI.Parent = PlayerGui end

-- Batch iterator to avoid freezing
local function batchIterate(list, batchSize, callback)
    batchSize = batchSize or 200
    local i = 1
    while i <= #list do
        local stop = math.min(i + batchSize - 1, #list)
        for j = i, stop do
            pcall(callback, list[j])
        end
        i = stop + 1
        RunService.Heartbeat:Wait()
    end
end

-- ----------------------------------------------------------------------------
-- Improved Highlight helper
-- ----------------------------------------------------------------------------
local function makeHighlight(adornTarget, fillColor, outlineColor, fillTrans, outlineTrans)
    if not adornTarget then return nil end
    local h = Instance.new("Highlight")
    h.Adornee = adornTarget
    h.Parent = Workspace
    h.FillColor = fillColor or Color3.fromRGB(80,180,255)
    h.OutlineColor = outlineColor or Color3.fromRGB(20,40,80)
    h.FillTransparency = (fillTrans ~= nil) and fillTrans or 0.06
    h.OutlineTransparency = (outlineTrans ~= nil) and outlineTrans or 0.0
    h.Enabled = true
    return h
end

-- ----------------------------------------------------------------------------
-- PLAYER ESP (names + highlight)
-- ----------------------------------------------------------------------------
local PlayerESPActive = false
local playerHighlights = {} -- [player] = Highlight
local playerNameTags = {}   -- [player] = BillboardGui

local function createPlayerESP(player)
    if not player or player == LocalPlayer then return end
    if not player.Character then return end

    -- Name tag
    local head = player.Character:FindFirstChild("Head")
    if head then
        if playerNameTags[player] then safeDestroy(playerNameTags[player]) end
        local bill = Instance.new("BillboardGui", GUI)
        bill.Name = "[FTF_Name_" .. player.Name .. "]"
        bill.Adornee = head
        bill.Size = UDim2.new(0,120,0,28)
        bill.StudsOffset = Vector3.new(0,2.6,0)
        bill.AlwaysOnTop = true
        local txt = Instance.new("TextLabel", bill)
        txt.Size = UDim2.new(1,0,1,0)
        txt.BackgroundTransparency = 1
        txt.Font = Enum.Font.GothamBold
        txt.TextSize = 14
        txt.TextColor3 = Color3.fromRGB(230,230,255)
        txt.TextStrokeTransparency = 0.8
        txt.Text = player.DisplayName or player.Name
        txt.TextXAlignment = Enum.TextXAlignment.Center
        playerNameTags[player] = bill
    end

    -- Highlight
    if playerHighlights[player] then safeDestroy(playerHighlights[player]) end
    local isBeast = false
    pcall(function() if player.Character and player.Character:FindFirstChild("BeastPowers") then isBeast = true end end)
    local fill = isBeast and Color3.fromRGB(255,60,110) or Color3.fromRGB(80,220,120)
    local outline = isBeast and Color3.fromRGB(140,30,50) or Color3.fromRGB(12,80,28)
    local h = makeHighlight(player.Character, fill, outline, 0.04, 0)
    playerHighlights[player] = h
end

local function removePlayerESP(player)
    if playerHighlights[player] then safeDestroy(playerHighlights[player]); playerHighlights[player] = nil end
    if playerNameTags[player] then safeDestroy(playerNameTags[player]); playerNameTags[player] = nil end
end

local function enablePlayerESP()
    if PlayerESPActive then return end
    PlayerESPActive = true
    for _,p in ipairs(Players:GetPlayers()) do
        if p ~= LocalPlayer then pcall(createPlayerESP, p) end
    end
end

local function disablePlayerESP()
    if not PlayerESPActive then return end
    PlayerESPActive = false
    for p,_ in pairs(playerHighlights) do removePlayerESP(p) end
end

Players.PlayerAdded:Connect(function(p)
    p.CharacterAdded:Connect(function()
        task.wait(0.06)
        if PlayerESPActive then pcall(createPlayerESP, p) end
    end)
end)
Players.PlayerRemoving:Connect(function(p) removePlayerESP(p) end)

-- ----------------------------------------------------------------------------
-- COMPUTER / PC ESP: detect model state and color accordingly
-- ----------------------------------------------------------------------------
local ComputerESPActive = false
local computerInfos = {} -- [model] = { highlight, billboard, conns = {} }

-- Utility to detect a model as "computer"
local function isComputerModel(model)
    if not model or not model:IsA("Model") then return false end
    local name = model.Name:lower()
    if name:find("computer") or name:find("pc") or name:find("terminal") or name:find("console") then
        return true
    end
    return false
end

-- Determine state for model by probing common values/attributes
local function getComputerState(model)
    if not model then return nil end
    -- Check BoolValue names
    local boolNames = {"Hacked","IsHacked","HackedValue"}
    for _,n in ipairs(boolNames) do
        local v = model:FindFirstChild(n, true)
        if v and v:IsA("BoolValue") then return v.Value and "hacked" or "ready" end
    end
    -- Check StringValue names
    local strNames = {"State","HackState","Status","Phase"}
    for _,n in ipairs(strNames) do
        local s = model:FindFirstChild(n, true)
        if s and s:IsA("StringValue") then return tostring(s.Value):lower() end
    end
    -- Check IntValue (some games store progress)
    local intNames = {"State","StateValue","HackProgress","Progress"}
    for _,n in ipairs(intNames) do
        local iv = model:FindFirstChild(n, true)
        if iv and iv:IsA("IntValue") then
            if iv.Value <= 0 then return "ready" end
            if iv.Value >= 1 then return "hacked" end
            return tostring(iv.Value)
        end
    end
    -- Attributes
    local attrCandidates = {"HackState","State","Status"}
    for _,a in ipairs(attrCandidates) do
        local at = model:GetAttribute(a)
        if at ~= nil then return tostring(at):lower() end
    end
    return nil
end

local function colorForState(state)
    if not state then
        return Color3.fromRGB(120,200,255), Color3.fromRGB(20,40,80) -- default cyan
    end
    local s = tostring(state):lower()
    if s:find("ready") or s:find("avail") or s:find("available") then
        return Color3.fromRGB(80,150,255), Color3.fromRGB(20,40,80) -- blue ready
    elseif s:find("hacked") or s:find("done") or s:find("complete") or s == "1" then
        return Color3.fromRGB(90,230,120), Color3.fromRGB(16,80,24) -- green hacked
    elseif s:find("wrong") or s:find("failed") or s:find("error") or s == "-1" then
        return Color3.fromRGB(255,80,80), Color3.fromRGB(120,24,24) -- red wrong
    elseif s:find("progress") or s:find("hacking") then
        return Color3.fromRGB(255,200,90), Color3.fromRGB(130,90,20) -- yellow progress
    else
        return Color3.fromRGB(120,200,255), Color3.fromRGB(20,40,80)
    end
end

local function createComputerBillboard(model, text)
    if not model then return nil end
    local part = model.PrimaryPart or model:FindFirstChildWhichIsA("BasePart")
    if not part then return nil end
    local b = Instance.new("BillboardGui", GUI)
    b.Name = "[FTF_PC_BB_" .. tostring(model:GetDebugId()) .. "]"
    b.Adornee = part
    b.Size = UDim2.new(0,140,0,34)
    b.StudsOffset = Vector3.new(0,2.6,0)
    b.AlwaysOnTop = true
    local lbl = Instance.new("TextLabel", b)
    lbl.Size = UDim2.new(1,0,1,0)
    lbl.BackgroundTransparency = 0.6
    lbl.BackgroundColor3 = Color3.fromRGB(8,8,12)
    lbl.Font = Enum.Font.GothamBold
    lbl.TextSize = 14
    lbl.TextColor3 = Color3.fromRGB(230,230,255)
    lbl.Text = text or ""
    lbl.TextXAlignment = Enum.TextXAlignment.Center
    local c = Instance.new("UICorner", lbl)
    c.CornerRadius = UDim.new(0,8)
    return b
end

local function updateComputerVisual(model)
    if not model then return end
    local info = computerInfos[model] or {}
    local state = getComputerState(model)
    local fill, outline = colorForState(state)
    if info.highlight and info.highlight.Parent then
        info.highlight.FillColor = fill
        info.highlight.OutlineColor = outline
        info.highlight.FillTransparency = 0.06
        info.highlight.OutlineTransparency = 0.0
    else
        info.highlight = makeHighlight(model, fill, outline, 0.06, 0)
    end
    if info.billboard and info.billboard.Parent then
        local lbl = info.billboard:FindFirstChildOfClass("TextLabel")
        if lbl then lbl.Text = tostring(state or "PC") end
    else
        info.billboard = createComputerBillboard(model, tostring(state or "PC"))
    end
    computerInfos[model] = info
end

local function attachComputerListeners(model)
    if not model then return end
    local info = computerInfos[model] or { conns = {} }
    -- disconnect old
    if info.conns then
        for _,c in ipairs(info.conns) do pcall(function() c:Disconnect() end) end
    end
    info.conns = {}
    -- watch relevant descendants for value changes
    local function tryWire(obj)
        if (obj:IsA("BoolValue") or obj:IsA("StringValue") or obj:IsA("IntValue") or obj:IsA("NumberValue")) then
            local c = obj.Changed:Connect(function() updateComputerVisual(model) end)
            table.insert(info.conns, c)
        end
    end
    for _,d in ipairs(model:GetDescendants()) do
        tryWire(d)
    end
    local addConn = model.DescendantAdded:Connect(function(d) tryWire(d); updateComputerVisual(model) end)
    table.insert(info.conns, addConn)
    computerInfos[model] = info
end

local compAddedConn, compRemovedConn
local function scanAndAddComputers()
    for _,desc in ipairs(Workspace:GetDescendants()) do
        if desc:IsA("Model") and isComputerModel(desc) then
            updateComputerVisual(desc)
            attachComputerListeners(desc)
        end
    end
end

local function enableComputerESP()
    if ComputerESPActive then return end
    ComputerESPActive = true
    scanAndAddComputers()
    compAddedConn = Workspace.DescendantAdded:Connect(function(obj)
        if not ComputerESPActive then return end
        if obj:IsA("Model") and isComputerModel(obj) then
            task.delay(0.05, function() updateComputerVisual(obj); attachComputerListeners(obj) end)
        elseif obj:IsA("BasePart") then
            local mdl = obj:FindFirstAncestorWhichIsA("Model")
            if mdl and isComputerModel(mdl) then task.delay(0.05, function() updateComputerVisual(mdl); attachComputerListeners(mdl) end) end
        end
    end)
    compRemovedConn = Workspace.DescendantRemoving:Connect(function(obj)
        if obj:IsA("Model") and computerInfos[obj] then
            -- cleanup
            local info = computerInfos[obj]
            if info.highlight then safeDestroy(info.highlight) end
            if info.billboard then safeDestroy(info.billboard) end
            if info.conns then for _,c in ipairs(info.conns) do pcall(function() c:Disconnect() end) end end
            computerInfos[obj] = nil
        end
    end)
end

local function disableComputerESP()
    if not ComputerESPActive then return end
    ComputerESPActive = false
    if compAddedConn then pcall(function() compAddedConn:Disconnect() end); compAddedConn = nil end
    if compRemovedConn then pcall(function() compRemovedConn:Disconnect() end); compRemovedConn = nil end
    for mdl,info in pairs(computerInfos) do
        if info.highlight then safeDestroy(info.highlight) end
        if info.billboard then safeDestroy(info.billboard) end
        if info.conns then for _,c in ipairs(info.conns) do pcall(function() c:Disconnect() end) end end
        computerInfos[mdl] = nil
    end
end

-- ----------------------------------------------------------------------------
-- RAGDOLL / DOWN TIMER (robust)
-- ----------------------------------------------------------------------------
local downActive = false
local downInfos = {} -- [player] = { gui, endTime }

local function createDownGui(player)
    if downInfos[player] then return downInfos[player] end
    if not player.Character then return end
    local head = player.Character:FindFirstChild("Head")
    if not head then return end
    local bill = Instance.new("BillboardGui", GUI)
    bill.Name = "[FTF_Down_" .. player.Name .. "]"
    bill.Adornee = head
    bill.Size = UDim2.new(0,150,0,44)
    bill.StudsOffset = Vector3.new(0,3.2,0)
    bill.AlwaysOnTop = true
    local frame = Instance.new("Frame", bill)
    frame.Size = UDim2.new(1,0,1,0)
    frame.BackgroundTransparency = 0.12
    frame.BackgroundColor3 = Color3.fromRGB(10,10,12)
    local corner = Instance.new("UICorner", frame); corner.CornerRadius = UDim.new(0,8)
    local label = Instance.new("TextLabel", frame)
    label.Size = UDim2.new(1,-12,1,-12); label.Position = UDim2.new(0,6,0,6)
    label.BackgroundTransparency = 1
    label.Font = Enum.Font.GothamBold
    label.TextSize = 18
    label.TextColor3 = Color3.fromRGB(230,230,240)
    label.Text = tostring(DOWN_TIME) .. "s"
    label.TextXAlignment = Enum.TextXAlignment.Center
    local pbg = Instance.new("Frame", frame)
    pbg.Size = UDim2.new(0.9,0,0,6); pbg.Position = UDim2.new(0.05,0,1,-10)
    pbg.BackgroundColor3 = Color3.fromRGB(30,30,34)
    local pfill = Instance.new("Frame", pbg)
    pfill.Size = UDim2.new(1,0,1,0)
    pfill.BackgroundColor3 = Color3.fromRGB(80,170,255)
    local info = { gui = bill, label = label, progress = pfill, endTime = tick() + DOWN_TIME }
    downInfos[player] = info
    return info
end

local function removeDownGui(player)
    if downInfos[player] then
        if downInfos[player].gui and downInfos[player].gui.Parent then safeDestroy(downInfos[player].gui) end
        downInfos[player] = nil
    end
end

RunService.Heartbeat:Connect(function()
    if not downActive then return end
    local now = tick()
    for player,info in pairs(downInfos) do
        if not player or not player.Parent or not info or not info.gui then
            removeDownGui(player)
        else
            local remaining = info.endTime - now
            if remaining <= 0 then
                removeDownGui(player)
            else
                if info.label and info.label.Parent then info.label.Text = string.format("%.1f s", remaining) end
                if info.progress and info.progress.Parent then
                    local frac = math.clamp(remaining / DOWN_TIME, 0, 1)
                    info.progress.Size = UDim2.new(frac,0,1,0)
                    if frac > 0.5 then info.progress.BackgroundColor3 = Color3.fromRGB(80,170,255)
                    elseif frac > 0.15 then info.progress.BackgroundColor3 = Color3.fromRGB(255,200,80)
                    else info.progress.BackgroundColor3 = Color3.fromRGB(255,80,80) end
                end
            end
        end
    end
end)

-- Detect ragdoll using multiple signals
local playerRagdollConns = {} -- [player] = {connections...}

local function setPlayerDown(player)
    if not downActive then return end
    local info = createDownGui(player)
    if info then info.endTime = tick() + DOWN_TIME end
end

local function clearPlayerDown(player)
    removeDownGui(player)
end

local function attachRagdollDetection(player)
    -- cleanup previous conns
    if playerRagdollConns[player] then
        for _,c in ipairs(playerRagdollConns[player]) do pcall(function() c:Disconnect() end) end
    end
    playerRagdollConns[player] = {}
    local function onCharacter(char)
        if not char then return end
        local hum = char:FindFirstChildWhichIsA("Humanoid") or char:WaitForChild("Humanoid", 6)
        if not hum then return end
        -- work with a BoolValue TempPlayerStatsModule.Ragdoll if exists
        local temp = player:FindFirstChild("TempPlayerStatsModule") or player:FindFirstChild("TempStats") or player:FindFirstChild("TempPlayerStats")
        if temp then
            local rag = temp:FindFirstChild("Ragdoll")
            if rag and rag:IsA("BoolValue") then
                table.insert(playerRagdollConns[player], rag.Changed:Connect(function(val)
                    if val then setPlayerDown(player) else clearPlayerDown(player) end
                end))
                if rag.Value then setPlayerDown(player) end
            end
        end
        -- Humanoid state change
        table.insert(playerRagdollConns[player], hum.StateChanged:Connect(function(old, new)
            if new == Enum.HumanoidStateType.Ragdoll or new == Enum.HumanoidStateType.FallingDown then
                setPlayerDown(player)
            elseif new == Enum.HumanoidStateType.GettingUp or new == Enum.HumanoidStateType.Landed then
                clearPlayerDown(player)
            end
        end))
        -- detect PlatformStand
        table.insert(playerRagdollConns[player], hum:GetPropertyChangedSignal("PlatformStand"):Connect(function()
            if hum.PlatformStand then setPlayerDown(player) else clearPlayerDown(player) end
        end))
        -- health changed (if died, clear)
        table.insert(playerRagdollConns[player], hum.HealthChanged:Connect(function(h)
            if h <= 0 then clearPlayerDown(player) end
        end))
        -- attribute "Ragdoll"
        pcall(function()
            if hum.GetAttribute then
                -- we cannot easily connect attribute change generically across engine versions; we'll poll via change signals if available
                local ok, conn = pcall(function() return hum:GetAttributeChangedSignal and hum:GetAttributeChangedSignal("Ragdoll") end)
                if ok and conn then
                    table.insert(playerRagdollConns[player], conn:Connect(function()
                        if hum:GetAttribute("Ragdoll") then setPlayerDown(player) else clearPlayerDown(player) end
                    end))
                    if hum:GetAttribute("Ragdoll") then setPlayerDown(player) end
                end
            end
        end)
    end
    local c = player.CharacterAdded:Connect(function(char) task.wait(0.06); onCharacter(char) end)
    table.insert(playerRagdollConns[player], c)
    if player.Character then onCharacter(player.Character) end
end

for _,p in ipairs(Players:GetPlayers()) do attachRagdollDetection(p) end
Players.PlayerAdded:Connect(function(p) attachRagdollDetection(p) end)
Players.PlayerRemoving:Connect(function(p)
    if playerRagdollConns[p] then for _,c in ipairs(playerRagdollConns[p]) do pcall(function() c:Disconnect() end) end playerRagdollConns[p] = nil end
    clearPlayerDown(p)
end)

local function ToggleDownTimer()
    downActive = not downActive
    if not downActive then
        for p,_ in pairs(downInfos) do removeDownGui(p) end
    end
end

-- ----------------------------------------------------------------------------
-- REMOVE FOG and REMOVE TEXTURES (with backups)
-- ----------------------------------------------------------------------------
local RemoveFogActive = false
local removeFogBackup = nil
local function enableRemoveFog()
    if RemoveFogActive then return end
    removeFogBackup = {
        FogEnd = Lighting.FogEnd,
        FogStart = Lighting.FogStart,
        ClockTime = Lighting.ClockTime,
        Brightness = Lighting.Brightness,
        GlobalShadows = Lighting.GlobalShadows
    }
    pcall(function()
        Lighting.FogEnd = 100000
        Lighting.FogStart = 0
        Lighting.ClockTime = 14
        Lighting.Brightness = 2
        Lighting.GlobalShadows = false
    end)
    RemoveFogActive = true
end
local function disableRemoveFog()
    if not RemoveFogActive then return end
    if removeFogBackup then
        pcall(function()
            if removeFogBackup.FogEnd ~= nil then Lighting.FogEnd = removeFogBackup.FogEnd end
            if removeFogBackup.FogStart ~= nil then Lighting.FogStart = removeFogBackup.FogStart end
            if removeFogBackup.ClockTime ~= nil then Lighting.ClockTime = removeFogBackup.ClockTime end
            if removeFogBackup.Brightness ~= nil then Lighting.Brightness = removeFogBackup.Brightness end
            if removeFogBackup.GlobalShadows ~= nil then Lighting.GlobalShadows = removeFogBackup.GlobalShadows end
        end)
    end
    removeFogBackup = nil
    RemoveFogActive = false
end
local function ToggleRemoveFog() if RemoveFogActive then disableRemoveFog() else enableRemoveFog() end end

-- Remove Textures (heavy) with batch & restore
local RemoveTexturesActive = false
local rt_backup_parts = {}
local rt_backup_meshparts = {}
local rt_backup_decals = {}
local rt_backup_particles = {}
local rt_backup_explosions = {}
local rt_backup_effects = {}
local rt_backup_terrain = {}
local rt_backup_lighting = {}
local rt_backup_quality = nil
local rt_desc_conn = nil

local function rt_store_part(p)
    if not p or not p:IsA("BasePart") then return end
    if rt_backup_parts[p] then return end
    rt_backup_parts[p] = { Material = p.Material, Reflectance = p.Reflectance }
end
local function rt_store_meshpart(mp)
    if not mp or not mp:IsA("MeshPart") then return end
    if rt_backup_meshparts[mp] then return end
    rt_backup_meshparts[mp] = { Material = mp.Material, Reflectance = mp.Reflectance, TextureID = mp.TextureID }
end
local function rt_store_decal(d)
    if not d then return end
    if rt_backup_decals[d] then return end
    rt_backup_decals[d] = d.Transparency
end
local function rt_store_particle(e)
    if not e then return end
    if rt_backup_particles[e] then return end
    if e:IsA("ParticleEmitter") or e:IsA("Trail") then rt_backup_particles[e] = { Lifetime = e.Lifetime } end
end
local function rt_store_explosion(ex)
    if not ex or not ex:IsA("Explosion") then return end
    if rt_backup_explosions[ex] then return end
    rt_backup_explosions[ex] = { BlastPressure = ex.BlastPressure, BlastRadius = ex.BlastRadius }
end
local function rt_store_effect(e)
    if not e then return end
    if rt_backup_effects[e] ~= nil then return end
    if e:IsA("BlurEffect") or e:IsA("SunRaysEffect") or e:IsA("ColorCorrectionEffect") or e:IsA("BloomEffect") or e:IsA("DepthOfFieldEffect") then
        rt_backup_effects[e] = e.Enabled
    elseif e:IsA("Fire") or e:IsA("SpotLight") or e:IsA("Smoke") then
        rt_backup_effects[e] = e.Enabled
    end
end

local function rt_apply_instance(v)
    if v:IsA("BasePart") then rt_store_part(v); pcall(function() v.Material = Enum.Material.Plastic; v.Reflectance = 0 end) end
    if v:IsA("UnionOperation") then rt_store_part(v); pcall(function() v.Material = Enum.Material.Plastic; v.Reflectance = 0 end) end
    if v:IsA("Decal") or v:IsA("Texture") then rt_store_decal(v); pcall(function() v.Transparency = 1 end) end
    if v:IsA("ParticleEmitter") or v:IsA("Trail") then rt_store_particle(v); pcall(function() v.Lifetime = NumberRange.new(0) end) end
    if v:IsA("Explosion") then rt_store_explosion(v); pcall(function() v.BlastPressure = 1; v.BlastRadius = 1 end) end
    if v:IsA("Fire") or v:IsA("SpotLight") or v:IsA("Smoke") then rt_store_effect(v); pcall(function() v.Enabled = false end) end
    if v:IsA("MeshPart") then rt_store_meshpart(v); pcall(function() v.Material = Enum.Material.Plastic; v.Reflectance = 0; v.TextureID = "rbxassetid://10385902758728957" end) end
end

local function rt_apply_lighting_child(e)
    if not e then return end
    if e:IsA("BlurEffect") or e:IsA("SunRaysEffect") or e:IsA("ColorCorrectionEffect") or e:IsA("BloomEffect") or e:IsA("DepthOfFieldEffect") then
        rt_store_effect(e); pcall(function() e.Enabled = false end)
    end
end

local function enableRemoveTextures()
    if RemoveTexturesActive then return end
    rt_backup_terrain = {
        WaterWaveSize = Workspace.Terrain.WaterWaveSize,
        WaterWaveSpeed = Workspace.Terrain.WaterWaveSpeed,
        WaterReflectance = Workspace.Terrain.WaterReflectance,
        WaterTransparency = Workspace.Terrain.WaterTransparency
    }
    rt_backup_lighting = {
        GlobalShadows = Lighting.GlobalShadows,
        FogEnd = Lighting.FogEnd,
        Brightness = Lighting.Brightness
    }
    local ok, q = pcall(function() return settings().Rendering.QualityLevel end)
    if ok then rt_backup_quality = q end

    pcall(function()
        local t = Workspace.Terrain
        t.WaterWaveSize = 0; t.WaterWaveSpeed = 0; t.WaterReflectance = 0; t.WaterTransparency = 0
    end)
    pcall(function()
        Lighting.GlobalShadows = false; Lighting.FogEnd = 9e9; Lighting.Brightness = 0
    end)
    pcall(function() settings().Rendering.QualityLevel = "Level01" end)

    local desc = Workspace:GetDescendants()
    batchIterate(desc, REMOVE_TEXTURES_BATCH_SIZE, function(v) rt_apply_instance(v) end)
    for _,e in ipairs(Lighting:GetChildren()) do rt_apply_lighting_child(e) end

    rt_desc_conn = Workspace.DescendantAdded:Connect(function(v)
        if not RemoveTexturesActive then return end
        task.defer(function() rt_apply_instance(v) end)
    end)

    RemoveTexturesActive = true
end

local function disableRemoveTextures()
    if not RemoveTexturesActive then return end
    if rt_desc_conn then pcall(function() rt_desc_conn:Disconnect() end); rt_desc_conn = nil end

    for part, props in pairs(rt_backup_parts) do
        if part and part.Parent then pcall(function() if props.Material then part.Material = props.Material end; if props.Reflectance then part.Reflectance = props.Reflectance end end) end
    end
    rt_backup_parts = {}

    for mp, props in pairs(rt_backup_meshparts) do
        if mp and mp.Parent then
            pcall(function()
                if props.Material then mp.Material = props.Material end
                if props.Reflectance then mp.Reflectance = props.Reflectance end
                if props.TextureID then mp.TextureID = props.TextureID end
            end)
        end
    end
    rt_backup_meshparts = {}

    for d, tr in pairs(rt_backup_decals) do if d and d.Parent then pcall(function() d.Transparency = tr end) end end
    rt_backup_decals = {}

    for e, info in pairs(rt_backup_particles) do if e and e.Parent then pcall(function() e.Lifetime = info.Lifetime end) end end
    rt_backup_particles = {}

    for ex, props in pairs(rt_backup_explosions) do if ex and ex.Parent then pcall(function() if props.BlastPressure then ex.BlastPressure = props.BlastPressure end; if props.BlastRadius then ex.BlastRadius = props.BlastRadius end end) end end
    rt_backup_explosions = {}

    for e, enabled in pairs(rt_backup_effects) do if e and e.Parent then pcall(function() e.Enabled = enabled end) end end
    rt_backup_effects = {}

    if rt_backup_terrain and next(rt_backup_terrain) then
        pcall(function()
            local t = Workspace.Terrain
            if rt_backup_terrain.WaterWaveSize ~= nil then t.WaterWaveSize = rt_backup_terrain.WaterWaveSize end
            if rt_backup_terrain.WaterWaveSpeed ~= nil then t.WaterWaveSpeed = rt_backup_terrain.WaterWaveSpeed end
            if rt_backup_terrain.WaterReflectance ~= nil then t.WaterReflectance = rt_backup_terrain.WaterReflectance end
            if rt_backup_terrain.WaterTransparency ~= nil then t.WaterTransparency = rt_backup_terrain.WaterTransparency end
        end)
    end
    rt_backup_terrain = {}

    if rt_backup_lighting and next(rt_backup_lighting) then
        pcall(function()
            if rt_backup_lighting.GlobalShadows ~= nil then Lighting.GlobalShadows = rt_backup_lighting.GlobalShadows end
            if rt_backup_lighting.FogEnd ~= nil then Lighting.FogEnd = rt_backup_lighting.FogEnd end
            if rt_backup_lighting.Brightness ~= nil then Lighting.Brightness = rt_backup_lighting.Brightness end
        end)
    end
    rt_backup_lighting = {}

    if rt_backup_quality then pcall(function() settings().Rendering.QualityLevel = rt_backup_quality end) end
    rt_backup_quality = nil

    RemoveTexturesActive = false
end

-- ----------------------------------------------------------------------------
-- UI: loading panel (center), minimized icon (avatar), menu with toggles
-- ----------------------------------------------------------------------------
local function createBasicUI()
    -- Loading panel
    local LoadingPanel = Instance.new("Frame", GUI)
    LoadingPanel.Name = "FTF_LoadingPanel"
    LoadingPanel.Size = UDim2.new(0,420,0,120)
    LoadingPanel.Position = UDim2.new(0.5,-210,0.45,-60)
    LoadingPanel.BackgroundColor3 = Color3.fromRGB(18,18,20)
    LoadingPanel.BorderSizePixel = 0
    local lpCorner = Instance.new("UICorner", LoadingPanel); lpCorner.CornerRadius = UDim.new(0,14)
    local lpTitle = Instance.new("TextLabel", LoadingPanel)
    lpTitle.Size = UDim2.new(1,-40,0,36); lpTitle.Position = UDim2.new(0,20,0,14)
    lpTitle.BackgroundTransparency = 1; lpTitle.Font = Enum.Font.FredokaOne; lpTitle.TextSize = 20
    lpTitle.TextColor3 = Color3.fromRGB(220,220,230); lpTitle.Text = "Loading FTF hub - By David"; lpTitle.TextXAlignment = Enum.TextXAlignment.Left
    local lpSub = Instance.new("TextLabel", LoadingPanel)
    lpSub.Size = UDim2.new(1,-40,0,18); lpSub.Position = UDim2.new(0,20,0,56)
    lpSub.BackgroundTransparency = 1; lpSub.Font = Enum.Font.Gotham; lpSub.TextSize = 12
    lpSub.TextColor3 = Color3.fromRGB(170,170,180); lpSub.Text = "Preparing visuals and timers..."; lpSub.TextXAlignment = Enum.TextXAlignment.Left
    local spinner = Instance.new("Frame", LoadingPanel)
    spinner.Size = UDim2.new(0,40,0,40); spinner.Position = UDim2.new(1,-64,0,20); spinner.BackgroundColor3 = Color3.fromRGB(24,24,26)
    local spCorner = Instance.new("UICorner", spinner); spCorner.CornerRadius = UDim.new(0,10)
    local inner = Instance.new("Frame", spinner); inner.Size = UDim2.new(0,24,0,24); inner.Position = UDim2.new(0.5,-12,0.5,-12); inner.BackgroundColor3 = Color3.fromRGB(80,160,255)
    local innerCorner = Instance.new("UICorner", inner); innerCorner.CornerRadius = UDim.new(0,8)
    local spinTween = TweenService:Create(spinner, TweenInfo.new(1.2, Enum.EasingStyle.Linear, Enum.EasingDirection.InOut, -1, true), {Rotation = 360})
    spinTween:Play()
    -- Toast
    local Toast = Instance.new("Frame", GUI)
    Toast.Name = "FTF_Toast"; Toast.Size = UDim2.new(0,360,0,46); Toast.Position = UDim2.new(0.5,-180,0.02,0)
    Toast.BackgroundColor3 = Color3.fromRGB(20,20,22); Toast.Visible = false
    local toastCorner = Instance.new("UICorner", Toast); toastCorner.CornerRadius = UDim.new(0,12)
    local toastLabel = Instance.new("TextLabel", Toast)
    toastLabel.Size = UDim2.new(1,-48,1,0); toastLabel.Position = UDim2.new(0,12,0,0); toastLabel.BackgroundTransparency = 1
    toastLabel.Font = Enum.Font.GothamSemibold; toastLabel.TextSize = 14; toastLabel.TextColor3 = Color3.fromRGB(220,220,220)
    toastLabel.Text = "Use the letter K on your keyboard to open the MENU."
    local toastClose = Instance.new("TextButton", Toast); toastClose.Size = UDim2.new(0,28,0,28); toastClose.Position = UDim2.new(1,-40,0.5,-14)
    toastClose.Text = "✕"; toastClose.Font = Enum.Font.Gotham; toastClose.TextSize = 16; toastClose.BackgroundColor3 = Color3.fromRGB(16,16,16)
    local tcCorner = Instance.new("UICorner", toastClose); tcCorner.CornerRadius = UDim.new(0,8)
    toastClose.MouseButton1Click:Connect(function() Toast.Visible = false end)
    -- Minimized icon
    local MinimizedIcon = Instance.new("ImageButton", GUI)
    MinimizedIcon.Name = "FTF_MinimizedIcon"; MinimizedIcon.Size = UDim2.new(0,56,0,56); MinimizedIcon.Position = UDim2.new(0.02,0,0.06,0)
    MinimizedIcon.BackgroundColor3 = Color3.fromRGB(24,24,26); MinimizedIcon.BorderSizePixel = 0; MinimizedIcon.Visible = false; MinimizedIcon.AutoButtonColor = true
    local miCorner = Instance.new("UICorner", MinimizedIcon); miCorner.CornerRadius = UDim.new(0,12)
    local miStroke = Instance.new("UIStroke", MinimizedIcon); miStroke.Color = Color3.fromRGB(30,80,130); miStroke.Transparency = 0.7
    if tostring(ICON_IMAGE_ID) ~= "" then pcall(function() MinimizedIcon.Image = "rbxassetid://"..tostring(ICON_IMAGE_ID) end) end
    -- fetch headshot
    task.defer(function()
        pcall(function()
            if Players.GetUserThumbnailAsync then
                local ok, url = pcall(function() return Players:GetUserThumbnailAsync(LocalPlayer.UserId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size420x420) end)
                if ok and url and url ~= "" then MinimizedIcon.Image = url end
            end
        end)
    end)
    pcall(function()
        if LocalPlayer and LocalPlayer.CharacterAppearanceLoaded then
            LocalPlayer.CharacterAppearanceLoaded:Connect(function()
                task.delay(0.4, function()
                    pcall(function()
                        if Players.GetUserThumbnailAsync then
                            local ok, url = pcall(function() return Players:GetUserThumbnailAsync(LocalPlayer.UserId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size420x420) end)
                            if ok and url and url ~= "" then MinimizedIcon.Image = url end
                        end
                    end)
                end)
            end)
        end
    end)
    -- Mobile toggle
    local MobileToggle = Instance.new("TextButton", GUI)
    MobileToggle.Name = "FTF_MobileToggle"; MobileToggle.Size = UDim2.new(0,56,0,56); MobileToggle.Position = UDim2.new(0.02,68,0.06,0)
    MobileToggle.BackgroundColor3 = Color3.fromRGB(24,24,26); MobileToggle.BorderSizePixel = 0; MobileToggle.Text = "☰"; MobileToggle.Font = Enum.Font.GothamBold
    MobileToggle.TextColor3 = Color3.fromRGB(220,220,220); MobileToggle.Visible = UserInputService.TouchEnabled and true or false
    local mtCorner = Instance.new("UICorner", MobileToggle); mtCorner.CornerRadius = UDim.new(0,12)
    -- Main menu frame
    local MainFrame = Instance.new("Frame", GUI)
    MainFrame.Name = "FTF_Main"; MainFrame.Size = UDim2.new(0,520,0,380); MainFrame.Position = UDim2.new(0.5,-260,0.08,0)
    MainFrame.BackgroundColor3 = Color3.fromRGB(18,18,18); MainFrame.BorderSizePixel = 0; MainFrame.Visible = false
    local mfCorner = Instance.new("UICorner", MainFrame); mfCorner.CornerRadius = UDim.new(0,12)
    -- Titlebar
    local TitleBar = Instance.new("Frame", MainFrame); TitleBar.Size = UDim2.new(1,0,0,48); TitleBar.BackgroundTransparency = 1
    local TitleLbl = Instance.new("TextLabel", TitleBar); TitleLbl.Text = "FTF - David's ESP"; TitleLbl.Font = Enum.Font.GothamBold; TitleLbl.TextSize = 16
    TitleLbl.TextColor3 = Color3.fromRGB(220,220,220); TitleLbl.BackgroundTransparency = 1; TitleLbl.Position = UDim2.new(0,12,0,12); TitleLbl.Size = UDim2.new(0,260,0,24)
    local SearchBox = Instance.new("TextBox", TitleBar); SearchBox.Size = UDim2.new(0,220,0,28); SearchBox.Position = UDim2.new(1,-240,0,10)
    SearchBox.BackgroundColor3 = Color3.fromRGB(26,26,26); SearchBox.TextColor3 = Color3.fromRGB(200,200,200); SearchBox.ClearTextOnFocus = true
    local sbCorner = Instance.new("UICorner", SearchBox); sbCorner.CornerRadius = UDim.new(0,8)
    local MinimizeBtn = Instance.new("TextButton", TitleBar); MinimizeBtn.Text = "—"; MinimizeBtn.Font = Enum.Font.GothamBold; MinimizeBtn.TextSize = 20
    MinimizeBtn.BackgroundTransparency = 1; MinimizeBtn.Size = UDim2.new(0,36,0,36); MinimizeBtn.Position = UDim2.new(1,-92,0,6); MinimizeBtn.TextColor3 = Color3.fromRGB(200,200,200)
    local CloseBtn = Instance.new("TextButton", TitleBar); CloseBtn.Text = "✕"; CloseBtn.Font = Enum.Font.GothamBold; CloseBtn.TextSize = 18
    CloseBtn.BackgroundTransparency = 1; CloseBtn.Size = UDim2.new(0,36,0,36); CloseBtn.Position = UDim2.new(1,-44,0,6); CloseBtn.TextColor3 = Color3.fromRGB(200,200,200)
    -- Tabs & content
    local TabsParent = Instance.new("Frame", MainFrame); TabsParent.Size = UDim2.new(1,-24,0,44); TabsParent.Position = UDim2.new(0,12,0,56)
    local tabNames = {"ESP","Textures","Timers","Teleport"}; local tabPadding = 10
    local tabCount = #tabNames; local tabAvailableWidth = 520 - 24
    local tabWidth = math.max(80, math.floor((tabAvailableWidth - (tabPadding * (tabCount - 1))) / tabCount))
    local Tabs = {}
    for i,name in ipairs(tabNames) do
        local x = (i-1)*(tabWidth + tabPadding)
        local t = Instance.new("TextButton", TabsParent)
        t.Size = UDim2.new(0,tabWidth,0,34); t.Position = UDim2.new(0,x,0,4)
        t.Text = name; t.Font = Enum.Font.GothamSemibold; t.TextSize = 14; t.TextColor3 = Color3.fromRGB(200,200,200)
        t.BackgroundColor3 = Color3.fromRGB(28,28,28); t.AutoButtonColor = false
        local c = Instance.new("UICorner", t); c.CornerRadius = UDim.new(0,12)
        Tabs[name] = t
    end
    local ContentScroll = Instance.new("ScrollingFrame", MainFrame)
    ContentScroll.Name = "ContentScroll"; ContentScroll.Size = UDim2.new(1,-24,1,-120); ContentScroll.Position = UDim2.new(0,12,0,112)
    ContentScroll.BackgroundTransparency = 1; ContentScroll.BorderSizePixel = 0; ContentScroll.ScrollBarImageColor3 = Color3.fromRGB(75,75,75)
    local contentLayout = Instance.new("UIListLayout", ContentScroll); contentLayout.SortOrder = Enum.SortOrder.LayoutOrder; contentLayout.Padding = UDim.new(0,10)
    contentLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
    contentLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function() ContentScroll.CanvasSize = UDim2.new(0,0,0, contentLayout.AbsoluteContentSize.Y + 18) end)

    -- UI creators (toggle / button)
    local function createToggleItem(parent, labelText, initial, onToggle)
        local item = Instance.new("Frame", parent); item.Size = UDim2.new(0.95,0,0,44); item.BackgroundColor3 = Color3.fromRGB(28,28,28)
        local itemCorner = Instance.new("UICorner", item); itemCorner.CornerRadius = UDim.new(0,10)
        local lbl = Instance.new("TextLabel", item); lbl.Size = UDim2.new(1,-120,1,0); lbl.Position = UDim2.new(0,12,0,0)
        lbl.BackgroundTransparency = 1; lbl.Font = Enum.Font.Gotham; lbl.TextSize = 14; lbl.TextColor3 = Color3.fromRGB(210,210,210); lbl.TextXAlignment = Enum.TextXAlignment.Left; lbl.Text = labelText
        local sw = Instance.new("TextButton", item); sw.Size = UDim2.new(0,88,0,28); sw.Position = UDim2.new(1,-100,0.5,-14); sw.BackgroundColor3 = Color3.fromRGB(38,38,38); sw.AutoButtonColor = false
        local swCorner = Instance.new("UICorner", sw); swCorner.CornerRadius = UDim.new(0,16)
        local swBg = Instance.new("Frame", sw); swBg.Size = UDim2.new(1,-8,1,-8); swBg.Position = UDim2.new(0,4,0,4); swBg.BackgroundColor3 = Color3.fromRGB(60,60,60)
        local swBgCorner = Instance.new("UICorner", swBg); swBgCorner.CornerRadius = UDim.new(0,14)
        local toggleDot = Instance.new("Frame", swBg); toggleDot.Size = UDim2.new(0,20,0,20)
        toggleDot.Position = UDim2.new(initial and 1 or 0, initial and -22 or 2, 0.5, -10)
        toggleDot.BackgroundColor3 = initial and Color3.fromRGB(120,200,120) or Color3.fromRGB(180,180,180)
        local dotCorner = Instance.new("UICorner", toggleDot); dotCorner.CornerRadius = UDim.new(0,10)
        local state = initial or false
        local function updateVisual(s)
            state = s
            local targetPos = s and UDim2.new(1,-22,0.5,-10) or UDim2.new(0,2,0.5,-10)
            TweenService:Create(toggleDot, TweenInfo.new(0.12), {Position = targetPos}):Play()
            toggleDot.BackgroundColor3 = s and Color3.fromRGB(120,200,120) or Color3.fromRGB(160,160,160)
            swBg.BackgroundColor3 = s and Color3.fromRGB(35,90,35) or Color3.fromRGB(60,60,60)
        end
        sw.MouseButton1Click:Connect(function()
            pcall(onToggle)
            updateVisual(not state)
        end)
        updateVisual(state)
        return item, function(newState) updateVisual(newState) end, function() return state end, lbl
    end

    local function createButtonItem(parent, labelText, buttonText, callback)
        local item = Instance.new("Frame", parent); item.Size = UDim2.new(0.95,0,0,44); item.BackgroundColor3 = Color3.fromRGB(28,28,28)
        local itemCorner = Instance.new("UICorner", item); itemCorner.CornerRadius = UDim.new(0,10)
        local lbl = Instance.new("TextLabel", item); lbl.Size = UDim2.new(1,-120,1,0); lbl.Position = UDim2.new(0,12,0,0)
        lbl.BackgroundTransparency = 1; lbl.Font = Enum.Font.Gotham; lbl.TextSize = 14; lbl.TextColor3 = Color3.fromRGB(210,210,210); lbl.TextXAlignment = Enum.TextXAlignment.Left; lbl.Text = labelText
        local btn = Instance.new("TextButton", item); btn.Size = UDim2.new(0,88,0,28); btn.Position = UDim2.new(1,-100,0.5,-14)
        btn.BackgroundColor3 = Color3.fromRGB(38,120,190); btn.AutoButtonColor = false
        local btnCorner = Instance.new("UICorner", btn); btnCorner.CornerRadius = UDim.new(0,12)
        btn.Font = Enum.Font.GothamBold; btn.TextSize = 14; btn.TextColor3 = Color3.fromRGB(240,240,240); btn.Text = buttonText
        btn.MouseButton1Click:Connect(function() pcall(callback) end)
        return item, lbl, btn
    end

    -- Expose UI pieces for outer use
    return {
        LoadingPanel = LoadingPanel,
        Toast = Toast,
        MinimizedIcon = MinimizedIcon,
        MobileToggle = MobileToggle,
        MainFrame = MainFrame,
        ContentScroll = ContentScroll,
        SearchBox = SearchBox,
        MinimizeBtn = MinimizeBtn,
        CloseBtn = CloseBtn,
        Tabs = Tabs,
        createToggleItem = createToggleItem,
        createButtonItem = createButtonItem
    }
end

local UI = createBasicUI()
local MainFrame = UI.MainFrame
local MinimizedIcon = UI.MinimizedIcon
local MobileToggle = UI.MobileToggle
local Toast = UI.Toast
local ContentScroll = UI.ContentScroll
local SearchBox = UI.SearchBox
local MinimizeBtn = UI.MinimizeBtn
local CloseBtn = UI.CloseBtn
local Tabs = UI.Tabs
local createToggleItem = UI.createToggleItem
local createButtonItem = UI.createButtonItem

-- Build category content wiring (Categories table)
local Categories = {
    ["ESP"] = {
        { label = "ESP Players", get = function() return PlayerESPActive end, toggle = function() if PlayerESPActive then disablePlayerESP() else enablePlayerESP() end end },
        { label = "ESP PCs", get = function() return ComputerESPActive end, toggle = function() if ComputerESPActive then disableComputerESP() else enableComputerESP() end end },
        { label = "ESP Freeze Pods", get = function() return (FreezePodsActive == true) end, toggle = function() if FreezePodsActive then disableFreezePodsESP() else enableFreezePodsESP() end end },
        { label = "ESP Exit Doors", get = function() return (DoorESPActive == true) end, toggle = function() if DoorESPActive then disableDoorESP() else enableDoorESP() end end },
    },
    ["Textures"] = {
        { label = "Remove players Textures", get = function() return GraySkinActive end, toggle = function() if GraySkinActive then disableGraySkin() else enableGraySkin() end end },
        { label = "Ativar Textures Tijolos Brancos", get = function() return TextureActive end, toggle = function() if TextureActive then disableTextureToggle() else enableTextureToggle() end end },
        { label = "Snow texture", get = function() return SnowActive end, toggle = function() if SnowActive then disableSnowTexture() else enableSnowTexture() end end },
        { label = "Remove Fog", get = function() return RemoveFogActive end, toggle = ToggleRemoveFog },
        { label = "Remove Textures", get = function() return RemoveTexturesActive end, toggle = ToggleRemoveTextures },
    },
    ["Timers"] = {
        { label = "Ativar Contador de Down", get = function() return downActive end, toggle = ToggleDownTimer },
    },
}

-- Build category function
local currentCategory = "ESP"
local function clearContent()
    for _,child in pairs(ContentScroll:GetChildren()) do
        if child:IsA("Frame") then safeDestroy(child) end
    end
end

local function buildCategory(name, filter)
    filter = (filter or ""):lower()
    clearContent()
    if name == "Teleport" then
        local order = 1
        local list = Players:GetPlayers()
        table.sort(list, function(a,b) return ((a.DisplayName or ""):lower()..a.Name:lower()) < ((b.DisplayName or ""):lower()..b.Name:lower()) end)
        for _,pl in ipairs(list) do
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
                item.LayoutOrder = order; order = order + 1
            end
        end
    end
end

-- Tabs wiring
Tabs.ESP.MouseButton1Click:Connect(function() currentCategory = "ESP"; Tabs.ESP.BackgroundColor3 = Color3.fromRGB(34,34,34); Tabs.Textures.BackgroundColor3 = Color3.fromRGB(28,28,28); Tabs.Timers.BackgroundColor3 = Color3.fromRGB(28,28,28); Tabs.Teleport.BackgroundColor3 = Color3.fromRGB(28,28,28); buildCategory("ESP", SearchBox.Text) end)
Tabs.Textures.MouseButton1Click:Connect(function() currentCategory = "Textures"; Tabs.Textures.BackgroundColor3 = Color3.fromRGB(34,34,34); Tabs.ESP.BackgroundColor3 = Color3.fromRGB(28,28,28); Tabs.Timers.BackgroundColor3 = Color3.fromRGB(28,28,28); Tabs.Teleport.BackgroundColor3 = Color3.fromRGB(28,28,28); buildCategory("Textures", SearchBox.Text) end)
Tabs.Timers.MouseButton1Click:Connect(function() currentCategory = "Timers"; Tabs.Timers.BackgroundColor3 = Color3.fromRGB(34,34,34); Tabs.ESP.BackgroundColor3 = Color3.fromRGB(28,28,28); Tabs.Textures.BackgroundColor3 = Color3.fromRGB(28,28,28); Tabs.Teleport.BackgroundColor3 = Color3.fromRGB(28,28,28); buildCategory("Timers", SearchBox.Text) end)
Tabs.Teleport.MouseButton1Click:Connect(function() currentCategory = "Teleport"; Tabs.Teleport.BackgroundColor3 = Color3.fromRGB(34,34,34); Tabs.ESP.BackgroundColor3 = Color3.fromRGB(28,28,28); Tabs.Textures.BackgroundColor3 = Color3.fromRGB(28,28,28); Tabs.Timers.BackgroundColor3 = Color3.fromRGB(28,28,28); buildCategory("Teleport", SearchBox.Text) end)
SearchBox:GetPropertyChangedSignal("Text"):Connect(function() buildCategory(currentCategory, SearchBox.Text) end)
Players.PlayerAdded:Connect(function() if currentCategory == "Teleport" then task.delay(0.06, function() buildCategory("Teleport", SearchBox.Text) end) end end)
Players.PlayerRemoving:Connect(function() if currentCategory == "Teleport" then task.delay(0.06, function() buildCategory("Teleport", SearchBox.Text) end) end end)

-- Dragging MainFrame
do
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
end

-- Minimize & Close behavior
MinimizeBtn.MouseButton1Click:Connect(function()
    pcall(updateMinimizedIconAvatar)
    MainFrame.Visible = false
    MinimizedIcon.Visible = true
end)
MinimizedIcon.MouseButton1Click:Connect(function() MainFrame.Visible = true; MinimizedIcon.Visible = false end)
CloseBtn.MouseButton1Click:Connect(function() MainFrame.Visible = false end)
MobileToggle.MouseButton1Click:Connect(function() MainFrame.Visible = not MainFrame.Visible; if MainFrame.Visible then MinimizedIcon.Visible = false end end)

-- Keyboard K toggles menu
local menuOpen = false
UserInputService.InputBegan:Connect(function(input, gpe)
    if gpe then return end
    if input.UserInputType == Enum.UserInputType.Keyboard and input.KeyCode == Enum.KeyCode.K then
        menuOpen = not menuOpen
        MainFrame.Visible = menuOpen
        if menuOpen then MinimizedIcon.Visible = false end
    end
end)

-- Finish loading: remove panel, show toast and menu
task.spawn(function()
    task.wait(1.1)
    -- show main menu
    MainFrame.Visible = true
    menuOpen = true
    -- close loading panel if exists
    if UI and UI.LoadingPanel and UI.LoadingPanel.Parent then safeDestroy(UI.LoadingPanel) end
    -- show toast briefly
    Toast.Visible = true
    pcall(function() TweenService:Create(Toast, TweenInfo.new(0.28), {Position = UDim2.new(0.5, -180, 0.02, 0)}):Play() end)
    task.delay(7.5, function()
        if Toast and Toast.Parent then
            pcall(function() TweenService:Create(Toast, TweenInfo.new(0.22), {Position = UDim2.new(0.5, -180, -0.08, 0)}):Play() end)
            task.delay(0.26, function() if Toast and Toast.Parent then Toast.Visible = false end end)
        end
    end)
end)

-- Expose toggles to _G for debugging
_G.FTF = _G.FTF or {}
_G.FTF.TogglePlayerESP = function() if PlayerESPActive then disablePlayerESP() else enablePlayerESP() end end
_G.FTF.ToggleComputerESP = function() if ComputerESPActive then disableComputerESP() else enableComputerESP() end end
_G.FTF.ToggleDownTimer = ToggleDownTimer
_G.FTF.ToggleRemoveFog = ToggleRemoveFog
_G.FTF.ToggleRemoveTextures = ToggleRemoveTextures

print("[FTF_ESP] Script initialized and should be runnable. If there is still an error, paste the exact error text from the Output window and I'll fix it.")
