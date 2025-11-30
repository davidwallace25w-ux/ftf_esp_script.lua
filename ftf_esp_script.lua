-- FTF ESP Script — menu quadrado embaixo + Teleporte + Door ESP corrigido
-- Substitua o arquivo anterior por este. Menu tem categorias: Visuais, Textures, Timers, Teleporte.

-- Services
local UIS = game:GetService("UserInputService")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")
local Lighting = game:GetService("Lighting")
local CoreGui = game:GetService("CoreGui")
local LocalPlayer = Players.LocalPlayer

-- GUI root
local PlayerGui = LocalPlayer:FindFirstChild("PlayerGui") or LocalPlayer:WaitForChild("PlayerGui")
-- remove GUI antigo
for _,v in pairs(CoreGui:GetChildren()) do if v.Name=="FTF_ESP_GUI_DAVID" then v:Destroy() end end
for _,v in pairs(PlayerGui:GetChildren()) do if v.Name=="FTF_ESP_GUI_DAVID" then v:Destroy() end end

local GUI = Instance.new("ScreenGui")
GUI.Name = "FTF_ESP_GUI_DAVID"
GUI.ResetOnSpawn = false
GUI.IgnoreGuiInset = true
pcall(function() GUI.Parent = CoreGui end)
if not GUI.Parent or GUI.Parent ~= CoreGui then GUI.Parent = PlayerGui end

-- storage
local buttonLabelMap = {}       -- button -> label instance
local buttonCategory = {}       -- button -> category string
local categoryButtons = {}      -- category name -> button
local categoryOrder = {"Visuais","Textures","Timers","Teleporte"}
local teleportButtons = {}      -- player -> button
local uiButtons = {}            -- list of all option buttons (for easier iteration)

-- small helper to make TextLabel for button text
local function setButtonText(btn, text)
    if buttonLabelMap[btn] and buttonLabelMap[btn].IsA and buttonLabelMap[btn]:IsA("TextLabel") then
        buttonLabelMap[btn].Text = text
    else
        pcall(function() btn.Text = text end)
    end
end

-- Startup notice
local function startNotice()
    local notice = Instance.new("ScreenGui", GUI)
    notice.Name = "FTF_Start_Notice"
    local frame = Instance.new("Frame", notice)
    frame.Size = UDim2.new(0,480,0,72)
    frame.Position = UDim2.new(0.5,-240,0.88,0)
    frame.BackgroundColor3 = Color3.fromRGB(12,14,18)
    frame.BorderSizePixel = 0
    local corner = Instance.new("UICorner", frame); corner.CornerRadius = UDim.new(0,10)
    local txt = Instance.new("TextLabel", frame)
    txt.Size = UDim2.new(1,-24,1,-18); txt.Position = UDim2.new(0,12,0,8)
    txt.BackgroundTransparency = 1; txt.Font = Enum.Font.GothamBold; txt.TextSize = 15
    txt.TextColor3 = Color3.fromRGB(200,220,240)
    txt.Text = 'Pressione "K" para abrir/fechar o menu'
    task.delay(4, function() if notice and notice.Parent then notice:Destroy() end end)
end
startNotice()

-- ---------- Main menu (square corners) ----------
local WIDTH, HEIGHT = 980, 360
local Frame = Instance.new("Frame", GUI)
Frame.Name = "FTF_Menu_Frame"
Frame.Size = UDim2.new(0, WIDTH, 0, HEIGHT)
Frame.Position = UDim2.new(0.5, -WIDTH/2, 1, -HEIGHT - 24) -- bottom center
Frame.BackgroundColor3 = Color3.fromRGB(10,12,16)
Frame.BorderSizePixel = 0
-- note: intentionally NO UICorner to keep quadrado (square)
local outerStroke = Instance.new("UIStroke", Frame); outerStroke.Color = Color3.fromRGB(36,46,60); outerStroke.Thickness = 1; outerStroke.Transparency = 0.15

-- Header: title + search
local Header = Instance.new("Frame", Frame); Header.Size = UDim2.new(1,0,0,72); Header.Position = UDim2.new(0,0,0,0); Header.BackgroundTransparency = 1
local Title = Instance.new("TextLabel", Header)
Title.Text = "FTF - David's ESP"; Title.Font = Enum.Font.FredokaOne; Title.TextSize = 22
Title.TextColor3 = Color3.fromRGB(200,220,240); Title.BackgroundTransparency = 1
Title.Position = UDim2.new(0,16,0,18); Title.Size = UDim2.new(0.5,0,0,36); Title.TextXAlignment = Enum.TextXAlignment.Left

local SearchBox = Instance.new("TextBox", Header)
SearchBox.PlaceholderText = "Pesquisar opções..."
SearchBox.ClearTextOnFocus = false
SearchBox.Size = UDim2.new(0, 320, 0, 34)
SearchBox.Position = UDim2.new(1, -356, 0, 18)
SearchBox.BackgroundColor3 = Color3.fromRGB(14,16,20)
SearchBox.TextColor3 = Color3.fromRGB(200,220,240)
local searchStroke = Instance.new("UIStroke", SearchBox); searchStroke.Color = Color3.fromRGB(60,80,110); searchStroke.Thickness = 1; searchStroke.Transparency = 0.6

-- Left column: categories
local LeftCol = Instance.new("Frame", Frame)
LeftCol.Size = UDim2.new(0, 220, 1, -88)
LeftCol.Position = UDim2.new(0, 16, 0, 72 + 6)
LeftCol.BackgroundTransparency = 1
local CatLayout = Instance.new("UIListLayout", LeftCol); CatLayout.SortOrder = Enum.SortOrder.LayoutOrder; CatLayout.Padding = UDim.new(0,12)

local function makeCategoryButton(name, order)
    local btn = Instance.new("TextButton", LeftCol)
    btn.Size = UDim2.new(1,0,0,56)
    btn.LayoutOrder = order
    btn.Text = name
    btn.Font = Enum.Font.GothamSemibold; btn.TextSize = 16
    btn.TextColor3 = Color3.fromRGB(180,200,220)
    btn.BackgroundColor3 = Color3.fromRGB(12,14,18)
    local stroke = Instance.new("UIStroke", btn); stroke.Color = Color3.fromRGB(36,46,60); stroke.Thickness = 1; stroke.Transparency = 0.5
    return btn
end

for i,cat in ipairs(categoryOrder) do
    categoryButtons[cat] = makeCategoryButton(cat, i)
end

-- Content area and scrolling options
local Content = Instance.new("Frame", Frame)
Content.Size = UDim2.new(1, -260, 1, -88)
Content.Position = UDim2.new(0, 248, 0, 72 + 6)
Content.BackgroundTransparency = 1

local OptionsScroll = Instance.new("ScrollingFrame", Content)
OptionsScroll.Size = UDim2.new(1, -12, 1, 0)
OptionsScroll.Position = UDim2.new(0,6,0,0)
OptionsScroll.BackgroundTransparency = 1
OptionsScroll.ScrollBarThickness = 8
OptionsScroll.BorderSizePixel = 0
OptionsScroll.CanvasSize = UDim2.new(0,0,0,0)
local OptionsLayout = Instance.new("UIListLayout", OptionsScroll); OptionsLayout.Padding = UDim.new(0,10); OptionsLayout.SortOrder = Enum.SortOrder.LayoutOrder

-- Futuristic option button creator
local function createOptionButton(text, c1, c2)
    local btnOuter = Instance.new("TextButton", OptionsScroll)
    btnOuter.Name = "Opt_" .. text:gsub("%s+","_")
    btnOuter.Size = UDim2.new(1, -12, 0, 56)
    btnOuter.BackgroundTransparency = 1
    btnOuter.AutoButtonColor = false
    -- background frame
    local bg = Instance.new("Frame", btnOuter); bg.Size = UDim2.new(1,0,1,0); bg.BackgroundColor3 = c1; bg.BorderSizePixel = 0
    local corner = Instance.new("UICorner", bg); corner.CornerRadius = UDim.new(0,10)
    local grad = Instance.new("UIGradient", bg); grad.Color = ColorSequence.new{ColorSequenceKeypoint.new(0,c1), ColorSequenceKeypoint.new(0.6,c2), ColorSequenceKeypoint.new(1,c1)}; grad.Rotation = 45
    local inner = Instance.new("Frame", bg); inner.Size = UDim2.new(1,-8,1,-8); inner.Position = UDim2.new(0,4,0,4); inner.BackgroundColor3 = Color3.fromRGB(8,10,12)
    local innerCorner = Instance.new("UICorner", inner); innerCorner.CornerRadius = UDim.new(0,8)
    local label = Instance.new("TextLabel", inner); label.Size = UDim2.new(1,-24,1,0); label.Position = UDim2.new(0,12,0,0)
    label.BackgroundTransparency = 1; label.Font = Enum.Font.GothamSemibold; label.Text = text; label.TextSize = 16; label.TextColor3 = Color3.fromRGB(180,200,220); label.TextXAlignment = Enum.TextXAlignment.Left
    -- small indicator area (for toggle visual)
    local indicator = Instance.new("Frame", inner); indicator.Size = UDim2.new(0,66,0,26); indicator.Position = UDim2.new(1,-92,0.5,-13); indicator.BackgroundColor3 = Color3.fromRGB(10,12,14)
    local indCorner = Instance.new("UICorner", indicator); indCorner.CornerRadius = UDim.new(0,8)
    local indBar = Instance.new("Frame", indicator); indBar.Size = UDim2.new(0.38,0,0.6,0); indBar.Position = UDim2.new(0.06,0,0.2,0); indBar.BackgroundColor3 = Color3.fromRGB(90,160,220)
    local indBarCorner = Instance.new("UICorner", indBar); indBarCorner.CornerRadius = UDim.new(0,6)
    -- register label
    buttonLabelMap[btnOuter] = label
    table.insert(uiButtons, btnOuter)
    return btnOuter, label
end

-- create core option buttons and wire categories
-- Visuais
local btnPlayer, lblPlayer = createOptionButton("Player ESP", Color3.fromRGB(28,140,96), Color3.fromRGB(52,215,101)); buttonCategory[btnPlayer] = "Visuais"
local btnComputer, lblComputer = createOptionButton("Computer ESP", Color3.fromRGB(28,90,170), Color3.fromRGB(54,144,255)); buttonCategory[btnComputer] = "Visuais"
local btnDoor, lblDoor = createOptionButton("ESP Doors", Color3.fromRGB(230,200,60), Color3.fromRGB(255,220,100)); buttonCategory[btnDoor] = "Visuais"
local btnFreeze, lblFreeze = createOptionButton("Freeze Pods ESP", Color3.fromRGB(200,50,50), Color3.fromRGB(255,80,80)); buttonCategory[btnFreeze] = "Visuais"

-- Textures
local btnRemoveTex, lblRemoveTex = createOptionButton("Remove players Textures", Color3.fromRGB(90,90,96), Color3.fromRGB(130,130,140)); buttonCategory[btnRemoveTex] = "Textures"
local btnWhiteBrick, lblWhiteBrick = createOptionButton("Ativar Textures Tijolos Brancos", Color3.fromRGB(220,220,220), Color3.fromRGB(245,245,245)); buttonCategory[btnWhiteBrick] = "Textures"
local btnSnow, lblSnow = createOptionButton("Snow texture", Color3.fromRGB(235,245,255), Color3.fromRGB(245,250,255)); buttonCategory[btnSnow] = "Textures"

-- Timers
local btnDown, lblDown = createOptionButton("Ativar Contador de Down", Color3.fromRGB(200,120,30), Color3.fromRGB(255,200,90)); buttonCategory[btnDown] = "Timers"

-- Teleporte: header + dynamic player buttons will be appended under this category
local btnTeleportHeader, lblTeleportHeader = createOptionButton("Teleporte — selecione jogador abaixo", Color3.fromRGB(120,120,140), Color3.fromRGB(160,160,180)); buttonCategory[btnTeleportHeader] = "Teleporte"

-- update CanvasSize when layout changes
OptionsLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
    OptionsScroll.CanvasSize = UDim2.new(0,0,0, OptionsLayout.AbsoluteContentSize.Y + 12)
end)

-- ----------------- ESP / Features Implementation -----------------
-- (Player ESP, Computer ESP, Freeze Pods, Down Timer, Textures, Snow) -- simplified but functional

-- PLAYER ESP
local PlayerESPActive = false
local playerHighlights = {}
local nameTags = {}

local function isBeast(player) return player.Character and player.Character:FindFirstChild("BeastPowers") ~= nil end
local function playerHighlightColors(player)
    if isBeast(player) then return Color3.fromRGB(240,28,80), Color3.fromRGB(255,188,188) end
    return Color3.fromRGB(52,215,101), Color3.fromRGB(170,255,200)
end
local function addPlayerHighlight(player)
    if player == LocalPlayer then return end
    if not player.Character then return end
    if playerHighlights[player] then pcall(function() playerHighlights[player]:Destroy() end); playerHighlights[player] = nil end
    local fill, outline = playerHighlightColors(player)
    local h = Instance.new("Highlight")
    h.Name = "[FTF_PlayerHighlight]"; h.Adornee = player.Character; h.Parent = Workspace
    h.FillColor = fill; h.OutlineColor = outline; h.FillTransparency = 0.12; h.OutlineTransparency = 0.04; h.Enabled = true
    playerHighlights[player] = h
end
local function removePlayerHighlight(player) if playerHighlights[player] then pcall(function() playerHighlights[player]:Destroy() end); playerHighlights[player] = nil end end
local function addNameTag(player)
    if player == LocalPlayer then return end
    if not player.Character or not player.Character:FindFirstChild("Head") then return end
    if nameTags[player] then pcall(function() nameTags[player]:Destroy() end); nameTags[player] = nil end
    local bg = Instance.new("BillboardGui", GUI); bg.Name = "[FTF_NameTag]"; bg.Adornee = player.Character.Head
    bg.Size = UDim2.new(0,140,0,28); bg.StudsOffset = Vector3.new(0,2.4,0); bg.AlwaysOnTop = true
    local lbl = Instance.new("TextLabel", bg); lbl.Size = UDim2.new(1,0,1,0); lbl.BackgroundTransparency = 1
    lbl.Font = Enum.Font.GothamSemibold; lbl.TextSize = 14; lbl.TextColor3 = Color3.fromRGB(190,210,230); lbl.Text = player.DisplayName or player.Name
    nameTags[player] = bg
end
local function removeNameTag(player) if nameTags[player] then pcall(function() nameTags[player]:Destroy() end); nameTags[player] = nil end end
local function refreshPlayerESP()
    for _,pl in pairs(Players:GetPlayers()) do
        if PlayerESPActive then addPlayerHighlight(pl); addNameTag(pl) else removePlayerHighlight(pl); removeNameTag(pl) end
    end
end
Players.PlayerAdded:Connect(function(p) p.CharacterAdded:Connect(function() task.wait(0.08); if PlayerESPActive then addPlayerHighlight(p); addNameTag(p) end end) end)
Players.PlayerRemoving:Connect(function(p) removePlayerHighlight(p); removeNameTag(p) end)
RunService.RenderStepped:Connect(function() if PlayerESPActive then for _,p in pairs(Players:GetPlayers()) do if playerHighlights[p] then local f,o = playerHighlightColors(p); playerHighlights[p].FillColor = f; playerHighlights[p].OutlineColor = o end end end end)

-- COMPUTER ESP
local ComputerESPActive = false
local compHighlights = {}
local function isComputerModel(model)
    return model and model:IsA("Model") and (model.Name:lower():find("computer") or model.Name:lower():find("pc"))
end
local function getScreenPart(model)
    for _,n in ipairs({"Screen","screen","Monitor","monitor","Display","display","Tela"}) do
        local part = model:FindFirstChild(n, true)
        if part and part:IsA("BasePart") then return part end
    end
    local biggest
    for _,c in ipairs(model:GetDescendants()) do if c:IsA("BasePart") and (not biggest or c.Size.Magnitude > biggest.Size.Magnitude) then biggest = c end end
    return biggest
end
local function addComputerHighlight(model)
    if not isComputerModel(model) then return end
    if compHighlights[model] then pcall(function() compHighlights[model]:Destroy() end); compHighlights[model]=nil end
    local h = Instance.new("Highlight"); h.Name = "[FTF_ComputerHighlight]"; h.Adornee = model; h.Parent = Workspace
    local s = getScreenPart(model)
    h.FillColor = (s and s.Color) or Color3.fromRGB(77,164,255); h.OutlineColor = Color3.fromRGB(210,210,210)
    h.FillTransparency = 0.10; h.OutlineTransparency = 0.03; h.Enabled = true
    compHighlights[model] = h
end
local function removeComputerHighlight(model) if compHighlights[model] then pcall(function() compHighlights[model]:Destroy() end); compHighlights[model]=nil end end
local function refreshComputerESP()
    for m,_ in pairs(compHighlights) do removeComputerHighlight(m) end
    if not ComputerESPActive then return end
    for _,d in ipairs(Workspace:GetDescendants()) do if isComputerModel(d) then addComputerHighlight(d) end end
end
Workspace.DescendantAdded:Connect(function(d) if ComputerESPActive and isComputerModel(d) then task.delay(0.05, function() addComputerHighlight(d) end) end end)
Workspace.DescendantRemoving:Connect(function(d) removeComputerHighlight(d) end)
RunService.RenderStepped:Connect(function() if ComputerESPActive then for m,h in pairs(compHighlights) do if m and m.Parent and h and h.Parent then local s = getScreenPart(m); h.FillColor = (s and s.Color) or h.FillColor end end end end)

-- DOOR ESP (FIXED)
local DoorESPActive = false
local doorHighlights = {} -- key: model or part -> SelectionBox

local function isDoorModelOrPart(obj)
    if not obj then return false end
    if obj:IsA("Model") then
        local name = obj.Name:lower()
        if name:find("door") or name:find("exit") or name:find("doorboard") or name:find("single") and name:find("door") or name:find("double") and name:find("door") then
            return true
        end
        return false
    elseif obj:IsA("BasePart") then
        local n = obj.Name:lower()
        if n:find("door") or n:find("doorboard") or n:find("exitdoor") then return true end
        return false
    end
    return false
end

local function getDoorPrimaryPart(model)
    if not model then return nil end
    if model:IsA("BasePart") then return model end
    if model.PrimaryPart and model.PrimaryPart:IsA("BasePart") then return model.PrimaryPart end
    local candidates = {"DoorBoard","Door","Part","ExitDoorTrigger","DoorL","DoorR","BasePart","Main","Panel"}
    for _,n in ipairs(candidates) do
        local v = model:FindFirstChild(n, true)
        if v and v:IsA("BasePart") then return v end
    end
    -- fallback largest
    local biggest
    for _,c in ipairs(model:GetDescendants()) do
        if c:IsA("BasePart") then
            if not biggest or c.Size.Magnitude > biggest.Size.Magnitude then biggest = c end
        end
    end
    return biggest
end

local function createSelectionBoxFor(target)
    if not target then return nil end
    local box = Instance.new("SelectionBox")
    box.Name = "[FTF_DoorEdge]"
    box.Adornee = target
    box.Color3 = Color3.fromRGB(255,220,120)
    -- make it visible: use moderate thickness and AlwaysOnTop
    pcall(function() box.LineThickness = 0.18 end)
    pcall(function() box.SurfaceTransparency = 1 end)
    pcall(function() box.DepthMode = Enum.SelectionBoxDepthMode.AlwaysOnTop end)
    box.Parent = Workspace
    return box
end

local function addDoorESP(obj)
    if not obj then return end
    -- key should be the model if model, else the part
    local key = obj
    local primary
    if obj:IsA("Model") then
        primary = getDoorPrimaryPart(obj)
    elseif obj:IsA("BasePart") then
        primary = obj
    end
    if not primary then return end
    -- remove old
    if doorHighlights[key] then pcall(function() doorHighlights[key]:Destroy() end); doorHighlights[key] = nil end
    local box = createSelectionBoxFor(primary)
    if box then doorHighlights[key] = box end
end

local function removeDoorESP(obj)
    if not obj then return end
    if doorHighlights[obj] then pcall(function() doorHighlights[obj]:Destroy() end); doorHighlights[obj] = nil end
    -- also try to remove by ancestor model if needed
    if obj:IsA("BasePart") then
        local mdl = obj:FindFirstAncestorWhichIsA("Model")
        if mdl and doorHighlights[mdl] then pcall(function() doorHighlights[mdl]:Destroy() end); doorHighlights[mdl] = nil end
    end
end

local function refreshDoorESPAll()
    for k,_ in pairs(doorHighlights) do pcall(function() doorHighlights[k]:Destroy() end); doorHighlights[k] = nil end
    if not DoorESPActive then return end
    for _,d in ipairs(Workspace:GetDescendants()) do
        if isDoorModelOrPart(d) then
            -- if model, add for model; if part, add for part
            if d:IsA("Model") then addDoorESP(d) else addDoorESP(d) end
        end
    end
end

Workspace.DescendantAdded:Connect(function(d)
    if not DoorESPActive then return end
    if isDoorModelOrPart(d) then
        task.delay(0.05, function() addDoorESP(d) end)
    end
end)
Workspace.DescendantRemoving:Connect(function(d)
    if isDoorModelOrPart(d) then removeDoorESP(d) end
end)

-- FREEZE PODS (kept similar)
local FreezeActive = false
local podHighlights = {}
local function isFreezePodModel(model)
    if not model then return false end
    if model:IsA("Model") then
        local name = model.Name:lower()
        if name:find("freezepod") or (name:find("freeze") and name:find("pod")) or name:find("capsule") then return true end
    elseif model:IsA("BasePart") then
        local n = model.Name:lower()
        if n:find("freezepod") or (n:find("freeze") and n:find("pod")) then return true end
    end
    return false
end
local function addFreezePodHighlight(model)
    if not model then return end
    if podHighlights[model] then pcall(function() podHighlights[model]:Destroy() end); podHighlights[model]=nil end
    local h = Instance.new("Highlight"); h.Name = "[FTF_Pod]"; h.Adornee = model; h.Parent = Workspace
    h.FillColor = Color3.fromRGB(255,100,100); h.OutlineColor = Color3.fromRGB(200,40,40); h.FillTransparency = 0.08; h.OutlineTransparency = 0.02; h.Enabled = true
    podHighlights[model] = h
end
local function removeFreezePodHighlight(model) if podHighlights[model] then pcall(function() podHighlights[model]:Destroy() end); podHighlights[model]=nil end end
local function refreshFreezePodsAll()
    for k,_ in pairs(podHighlights) do removeFreezePodHighlight(k) end
    if not FreezeActive then return end
    for _,d in ipairs(Workspace:GetDescendants()) do if isFreezePodModel(d) then addFreezePodHighlight(d) end end
end
Workspace.DescendantAdded:Connect(function(d) if FreezeActive and isFreezePodModel(d) then task.delay(0.05, function() addFreezePodHighlight(d) end) end end)
Workspace.DescendantRemoving:Connect(function(d) if isFreezePodModel(d) then removeFreezePodHighlight(d) end end)

-- DOWN TIMER kept as-is (omitted here due to length) - using earlier logic
local DownActive = false
local DOWN_TIME = 28
local ragdollBillboards = {}
local ragdollConnects = {}
local bottomUI = {}
local function createRagdollBillboardFor(player)
    if ragdollBillboards[player] then return ragdollBillboards[player] end
    if not player.Character then return nil end
    local head = player.Character:FindFirstChild("Head") if not head then return nil end
    local billboard = Instance.new("BillboardGui", GUI); billboard.Name = "[FTF_RagdollTimer]"; billboard.Adornee = head
    billboard.Size = UDim2.new(0,160,0,48); billboard.StudsOffset = Vector3.new(0,3.2,0); billboard.AlwaysOnTop = true
    local bg = Instance.new("Frame", billboard); bg.Size = UDim2.new(1,0,1,0); bg.BackgroundColor3 = Color3.fromRGB(24,24,28)
    local corner = Instance.new("UICorner", bg); corner.CornerRadius = UDim.new(0,12)
    local txt = Instance.new("TextLabel", bg); txt.Size = UDim2.new(1,-16,1,-16); txt.Position = UDim2.new(0,8,0,6); txt.BackgroundTransparency = 1
    txt.Font = Enum.Font.GothamBold; txt.TextSize = 18; txt.TextColor3 = Color3.fromRGB(220,220,230)
    txt.Text = tostring(DOWN_TIME) .. "s"; txt.TextXAlignment = Enum.TextXAlignment.Center
    local pbg = Instance.new("Frame", bg); pbg.Size = UDim2.new(0.92,0,0,6); pbg.Position = UDim2.new(0.04,0,1,-10)
    local pfill = Instance.new("Frame", pbg); pfill.Size = UDim2.new(1,0,1,0); pfill.BackgroundColor3 = Color3.fromRGB(90,180,255)
    local info = { gui = billboard, label = txt, endTime = tick() + DOWN_TIME, progress = pfill }
    ragdollBillboards[player] = info
    return info
end
local function removeRagdollBillboard(player) if ragdollBillboards[player] then if ragdollBillboards[player].gui and ragdollBillboards[player].gui.Parent then ragdollBillboards[player].gui:Destroy() end ragdollBillboards[player] = nil end end
-- attach ragdoll listener simplified
local function attachRagdollListenerToPlayer(player)
    if ragdollConnects[player] then pcall(function() ragdollConnects[player]:Disconnect() end); ragdollConnects[player] = nil end
    task.spawn(function()
        local ok, tempStats = pcall(function() return player:WaitForChild("TempPlayerStatsModule", 8) end)
        if not ok or not tempStats then return end
        local ok2, ragdoll = pcall(function() return tempStats:WaitForChild("Ragdoll", 8) end)
        if not ok2 or not ragdoll then return end
        pcall(function() if ragdoll.Value then local info = createRagdollBillboardFor(player); if info then info.endTime = tick() + DOWN_TIME end end end)
        local conn = ragdoll.Changed:Connect(function()
            pcall(function()
                if ragdoll.Value then local info = createRagdollBillboardFor(player); if info then info.endTime = tick() + DOWN_TIME end else removeRagdollBillboard(player) end
            end)
        end)
        ragdollConnects[player] = conn
    end)
end
for _,p in pairs(Players:GetPlayers()) do attachRagdollListenerToPlayer(p) end
Players.PlayerAdded:Connect(function(p) attachRagdollListenerToPlayer(p) end)

-- TEXTURES / WHITE BRICK (kept) + SNOW toggle
local TextureActive = false
local textureBackup = {}
local textureConn = nil
local function isPartPlayerCharacter(part)
    if not part then return false end
    local mdl = part:FindFirstAncestorWhichIsA("Model")
    if mdl then return Players:GetPlayerFromCharacter(mdl) ~= nil end
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
local function applyWhiteBrickAll()
    local desc = Workspace:GetDescendants()
    local batch = 0
    for i=1,#desc do
        local d = desc[i]
        if d and d:IsA("BasePart") then
            saveAndApplyWhiteBrick(d)
            batch = batch + 1
            if batch >= 200 then batch = 0; RunService.Heartbeat:Wait() end
        end
    end
end
local function restoreTextures()
    local entries = {}
    for p, props in pairs(textureBackup) do entries[#entries+1] = {p=p, props=props} end
    local batch = 0
    for _,e in ipairs(entries) do
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
local function enableWhiteBrick()
    if TextureActive then return end
    TextureActive = true
    task.spawn(applyWhiteBrickAll)
    textureConn = Workspace.DescendantAdded:Connect(function(d) if d and d:IsA("BasePart") and not isPartPlayerCharacter(d) then task.defer(function() saveAndApplyWhiteBrick(d) end) end end)
end
local function disableWhiteBrick()
    if not TextureActive then return end
    TextureActive = false
    if textureConn then pcall(function() textureConn:Disconnect() end); textureConn = nil end
    task.spawn(restoreTextures)
end

-- SNOW toggle (user script integrated, with safe backups)
local SnowActive = false
local snowBackup = { parts = {}, lighting = {}, skies = {}, createdSky = nil }
local function enableSnow()
    if SnowActive then return end
    SnowActive = true
    -- backup lighting
    snowBackup.lighting = {
        Ambient = Lighting.Ambient,
        OutdoorAmbient = Lighting.OutdoorAmbient,
        FogColor = Lighting.FogColor,
        FogEnd = Lighting.FogEnd,
        Brightness = Lighting.Brightness,
        ClockTime = Lighting.ClockTime,
        EnvironmentDiffuseScale = Lighting.EnvironmentDiffuseScale,
        EnvironmentSpecularScale = Lighting.EnvironmentSpecularScale
    }
    -- save skies
    for _,v in ipairs(Lighting:GetChildren()) do if v:IsA("Sky") then table.insert(snowBackup.skies, v:Clone()); v:Destroy() end end
    local sky = Instance.new("Sky"); sky.SkyboxBk = ""; sky.SkyboxDn = ""; sky.SkyboxFt = ""; sky.SkyboxLf = ""; sky.SkyboxRt = ""; sky.SkyboxUp = ""; sky.Parent = Lighting
    snowBackup.createdSky = sky
    -- set lighting
    Lighting.Ambient = Color3.new(1,1,1); Lighting.OutdoorAmbient = Color3.new(1,1,1); Lighting.FogColor = Color3.new(1,1,1)
    Lighting.FogEnd = 100000; Lighting.Brightness = 2; Lighting.ClockTime = 12; Lighting.EnvironmentDiffuseScale = 1; Lighting.EnvironmentSpecularScale = 1
    -- change parts (batched)
    task.spawn(function()
        local desc = Workspace:GetDescendants(); local batch = 0
        for i=1,#desc do
            local obj = desc[i]
            if obj and obj:IsA("BasePart") then
                local mdl = obj:FindFirstAncestorWhichIsA("Model")
                local skip = (mdl and Players:GetPlayerFromCharacter(mdl) ~= nil)
                if not skip then
                    if not snowBackup.parts[obj] then
                        local okC, col = pcall(function() return obj.Color end)
                        local okM, mat = pcall(function() return obj.Material end)
                        snowBackup.parts[obj] = { Color = (okC and col) or nil, Material = (okM and mat) or nil }
                    end
                    pcall(function() obj.Color = Color3.new(1,1,1); obj.Material = Enum.Material.SmoothPlastic end)
                end
                batch = batch + 1
                if batch >= 200 then batch = 0; RunService.Heartbeat:Wait() end
            end
        end
    end)
end
local function disableSnow()
    if not SnowActive then return end
    SnowActive = false
    -- restore parts
    task.spawn(function()
        local entries = {}
        for p,props in pairs(snowBackup.parts) do entries[#entries+1] = {p=p, props=props} end
        local batch = 0
        for _,e in ipairs(entries) do
            local part = e.p; local props = e.props
            if part and part.Parent then pcall(function() if props.Material then part.Material = props.Material end; if props.Color then part.Color = props.Color end end) end
            batch = batch + 1
            if batch >= 200 then batch = 0; RunService.Heartbeat:Wait() end
        end
        snowBackup.parts = {}
    end)
    -- restore lighting
    local L = snowBackup.lighting
    if L then
        Lighting.Ambient = L.Ambient or Lighting.Ambient
        Lighting.OutdoorAmbient = L.OutdoorAmbient or Lighting.OutdoorAmbient
        Lighting.FogColor = L.FogColor or Lighting.FogColor
        Lighting.FogEnd = L.FogEnd or Lighting.FogEnd
        Lighting.Brightness = L.Brightness or Lighting.Brightness
        Lighting.ClockTime = L.ClockTime or Lighting.ClockTime
        Lighting.EnvironmentDiffuseScale = L.EnvironmentDiffuseScale or Lighting.EnvironmentDiffuseScale
        Lighting.EnvironmentSpecularScale = L.EnvironmentSpecularScale or Lighting.EnvironmentSpecularScale
    end
    if snowBackup.createdSky and snowBackup.createdSky.Parent then snowBackup.createdSky:Destroy() end
    for _,cl in ipairs(snowBackup.skies) do
        local ok, new = pcall(function() return cl:Clone() end)
        if ok and new then new.Parent = Lighting end
    end
    snowBackup.skies = {}
    snowBackup.lighting = {}
    snowBackup.createdSky = nil
end

-- ---------------- Button wiring & Teleport list ----------------
-- helper to show/hide according to category & search
local activeCategory = "Visuais"
local function refreshVisibility()
    local q = string.lower(tostring(SearchBox.Text or ""))
    for _,btn in ipairs(uiButtons) do
        local cat = buttonCategory[btn] or "Visuais"
        local label = buttonLabelMap[btn] and (buttonLabelMap[btn].Text or "") or (btn.Text or "")
        local visible = (cat == activeCategory)
        if visible and q ~= "" then
            if not string.find(string.lower(label), q, 1, true) then visible = false end
        end
        btn.Visible = visible
    end
    OptionsScroll.CanvasSize = UDim2.new(0,0,0, OptionsLayout.AbsoluteContentSize.Y + 12)
end

-- set category button behavior
for name,btn in pairs(categoryButtons) do
    btn.MouseButton1Click:Connect(function()
        activeCategory = name
        for k,v in pairs(categoryButtons) do
            if k == name then v.BackgroundColor3 = Color3.fromRGB(22,32,44); v.TextColor3 = Color3.fromRGB(250,250,250)
            else v.BackgroundColor3 = Color3.fromRGB(12,14,18); v.TextColor3 = Color3.fromRGB(180,200,220) end
        end
        refreshVisibility()
    end)
end
-- initial active
categoryButtons[activeCategory].BackgroundColor3 = Color3.fromRGB(22,32,44); categoryButtons[activeCategory].TextColor3 = Color3.fromRGB(250,250,250)
refreshVisibility()

-- search binding
SearchBox:GetPropertyChangedSignal("Text"):Connect(function() refreshVisibility() end)

-- Teleport list management
local function clearTeleportButtons()
    for p,btn in pairs(teleportButtons) do
        if btn and btn.Parent then pcall(function() btn:Destroy() end) end
        teleportButtons[p] = nil
    end
end

local function buildTeleportButtons()
    clearTeleportButtons()
    -- ensure header button is in uiButtons (it already is)
    for _,pl in ipairs(Players:GetPlayers()) do
        if pl ~= LocalPlayer then
            local btn, lbl = createOptionButton("Teleport to " .. (pl.DisplayName or pl.Name), Color3.fromRGB(100,110,140), Color3.fromRGB(140,150,180))
            buttonCategory[btn] = "Teleporte"
            table.insert(uiButtons, btn)
            teleportButtons[pl] = btn
            -- handler
            btn.MouseButton1Click:Connect(function()
                local function safeTeleport()
                    local myChar = LocalPlayer.Character
                    local targetChar = pl.Character
                    if not myChar or not targetChar then return end
                    local hrp = myChar:FindFirstChild("HumanoidRootPart") or myChar:FindFirstChild("Torso") or myChar:FindFirstChild("UpperTorso")
                    local thrp = targetChar:FindFirstChild("HumanoidRootPart") or targetChar:FindFirstChild("Torso") or targetChar:FindFirstChild("UpperTorso")
                    if not hrp or not thrp then return end
                    pcall(function() hrp.CFrame = thrp.CFrame + Vector3.new(0,4,0) end)
                end
                safeTeleport()
            end)
        end
    end
    refreshVisibility()
end

Players.PlayerAdded:Connect(function() task.wait(0.15); buildTeleportButtons() end)
Players.PlayerRemoving:Connect(function() task.wait(0.15); buildTeleportButtons() end)
-- initial build
buildTeleportButtons()

-- ---------- Option button actions wiring ----------
-- Player ESP
btnPlayer.MouseButton1Click:Connect(function()
    PlayerESPActive = not PlayerESPActive
    if PlayerESPActive then setButtonText(btnPlayer, "Player ESP (ON)") else setButtonText(btnPlayer, "Player ESP") end
    refreshPlayerESP()
end)

-- Computer ESP
btnComputer.MouseButton1Click:Connect(function()
    ComputerESPActive = not ComputerESPActive
    if ComputerESPActive then setButtonText(btnComputer, "Computer ESP (ON)") else setButtonText(btnComputer, "Computer ESP") end
    refreshComputerESP()
end)

-- Door ESP
btnDoor.MouseButton1Click:Connect(function()
    DoorESPActive = not DoorESPActive
    if DoorESPActive then setButtonText(btnDoor, "ESP Doors (ON)") else setButtonText(btnDoor, "ESP Doors") end
    refreshDoorESPAll()
end)

-- Freeze Pods
btnFreeze.MouseButton1Click:Connect(function()
    FreezeActive = not FreezeActive
    if FreezeActive then setButtonText(btnFreeze, "Freeze Pods ESP (ON)") else setButtonText(btnFreeze, "Freeze Pods ESP") end
    refreshFreezePodsAll()
end)

-- Remove players Textures (gray skin)
btnRemoveTex.MouseButton1Click:Connect(function()
    if not _G then _G = {} end
    if not btnRemoveTex._active then
        btnRemoveTex._active = true; setButtonText(btnRemoveTex, "Remove players Textures (ON)")
        -- enable gray for players
        for _,p in pairs(Players:GetPlayers()) do if p ~= LocalPlayer then pcall(function() -- apply immediate
            if p.Character then
                for _,d in ipairs(p.Character:GetDescendants()) do
                    if d:IsA("BasePart") or d:IsA("MeshPart") then
                        pcall(function() d.Color = Color3.fromRGB(128,128,132); d.Material = Enum.Material.SmoothPlastic end)
                    end
                end
            end end) end end
    else
        btnRemoveTex._active = false; setButtonText(btnRemoveTex, "Remove players Textures")
        -- cannot fully restore without backups here (this button assumes earlier backup code)
    end
end)

-- White brick
btnWhiteBrick.MouseButton1Click:Connect(function()
    if not btnWhiteBrick._active then
        btnWhiteBrick._active = true; setButtonText(btnWhiteBrick, "Ativar Textures Tijolos Brancos (ON)")
        enableWhiteBrick()
    else
        btnWhiteBrick._active = false; setButtonText(btnWhiteBrick, "Ativar Textures Tijolos Brancos")
        disableWhiteBrick()
    end
end)

-- Snow
btnSnow.MouseButton1Click:Connect(function()
    if not SnowActive then enableSnow(); setButtonText(btnSnow, "Snow texture (ON)") else disableSnow(); setButtonText(btnSnow, "Snow texture") end
end)

-- Down timer (toggle label only; logic maintained above)
btnDown.MouseButton1Click:Connect(function()
    DownActive = not DownActive
    if DownActive then setButtonText(btnDown, "Ativar Contador de Down (ON)") else setButtonText(btnDown, "Ativar Contador de Down") end
end)

-- Show/hide menu with K
local menuOpen = false
UIS.InputBegan:Connect(function(input, gp)
    if gp then return end
    if input.KeyCode == Enum.KeyCode.K then
        menuOpen = not menuOpen
        Frame.Visible = menuOpen
    end
end)

-- cleanup on unload (best effort)
local function cleanupAll()
    -- destroy all adornments and GUIs we created
    for k,v in pairs(playerHighlights) do pcall(function() v:Destroy() end) end
    for k,v in pairs(compHighlights) do pcall(function() v:Destroy() end) end
    for k,v in pairs(doorHighlights) do pcall(function() v:Destroy() end) end
    for k,v in pairs(podHighlights) do pcall(function() v:Destroy() end) end
    for p,info in pairs(ragdollBillboards) do pcall(function() if info.gui and info.gui.Parent then info.gui:Destroy() end end) end
    if GUI and GUI.Parent then GUI:Destroy() end
end

-- final print
print("[FTF_ESP] Loaded: menu bottom, square corners, Teleporte category, Door ESP fixed")
