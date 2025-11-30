-- FTF ESP Script — consolidated fixed version (patched)
-- Ajustes:
--  - Highlights parentados para Workspace (eles não pertencem a ScreenGui)
--  - Adicionado botão "Ativar Freeze Pods" que cria aura verde arredondada em volta das FreezePods
--  - Desconexão de ragdollConnects e limpeza de ragdollBillboards / bottomUI em PlayerRemoving
--  - Melhor cleanupAll para também limpar texturas/skins/highlights
--  - Pequena reorganização e comentários

-- Services
local UIS = game:GetService("UserInputService")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")
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

-- helper storage to map buttons to their visible label
local buttonLabelMap = {}

-- ---------- Startup notice ----------
local function createStartupNotice(opts)
    opts = opts or {}
    local duration = opts.duration or 6
    local width = opts.width or 380
    local height = opts.height or 68

    local noticeGui = Instance.new("ScreenGui")
    noticeGui.Name = "FTF_StartupNotice_DAVID"
    noticeGui.ResetOnSpawn = false
    noticeGui.Parent = GUI

    local frame = Instance.new("Frame", noticeGui)
    frame.Name = "NoticeFrame"
    frame.Size = UDim2.new(0, width, 0, height)
    frame.Position = UDim2.new(0.5, -width/2, 0.92, 6)
    frame.BackgroundTransparency = 1
    frame.BorderSizePixel = 0

    local panel = Instance.new("Frame", frame)
    panel.Name = "Panel"
    panel.Size = UDim2.new(1, 0, 1, 0)
    panel.BackgroundColor3 = Color3.fromRGB(10,14,20)
    panel.BackgroundTransparency = 0.05
    panel.BorderSizePixel = 0
    local corner = Instance.new("UICorner", panel); corner.CornerRadius = UDim.new(0, 14)
    local stroke = Instance.new("UIStroke", panel); stroke.Color = Color3.fromRGB(55,140,220); stroke.Thickness = 1.2; stroke.Transparency = 0.28

    local iconBg = Instance.new("Frame", panel)
    iconBg.Size = UDim2.new(0, 36, 0, 36)
    iconBg.Position = UDim2.new(0, 16, 0.5, -18)
    iconBg.BackgroundColor3 = Color3.fromRGB(16,20,26)
    local iconCorner = Instance.new("UICorner", iconBg); iconCorner.CornerRadius = UDim.new(0,10)
    local iconLabel = Instance.new("TextLabel", iconBg)
    iconLabel.Size = UDim2.new(1, -6, 1, -6); iconLabel.Position = UDim2.new(0,3,0,3)
    iconLabel.BackgroundTransparency = 1; iconLabel.Font = Enum.Font.FredokaOne; iconLabel.Text = "K"
    iconLabel.TextColor3 = Color3.fromRGB(100,170,220); iconLabel.TextSize = 20

    local txt = Instance.new("TextLabel", panel)
    txt.Size = UDim2.new(1, -96, 1, -8)
    txt.Position = UDim2.new(0, 76, 0, 4)
    txt.BackgroundTransparency = 1
    txt.Font = Enum.Font.GothamBold
    txt.TextSize = 15
    txt.TextColor3 = Color3.fromRGB(180,200,220)
    txt.Text = 'Clique na letra "K" para ativar o menu'
    txt.TextXAlignment = Enum.TextXAlignment.Left
    txt.TextWrapped = true

    local hint = Instance.new("TextLabel", panel)
    hint.Size = UDim2.new(1, -96, 0, 16)
    hint.Position = UDim2.new(0, 76, 1, -22)
    hint.BackgroundTransparency = 1
    hint.Font = Enum.Font.Gotham
    hint.TextSize = 11
    hint.TextColor3 = Color3.fromRGB(120,140,170)
    hint.Text = "Pressione novamente para fechar"
    hint.TextXAlignment = Enum.TextXAlignment.Left

    -- tween in/out
    TweenService:Create(panel, TweenInfo.new(0.55, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {BackgroundTransparency = 0.0}):Play()
    task.delay(duration, function()
        if noticeGui and noticeGui.Parent then noticeGui:Destroy() end
    end)
end
createStartupNotice()

-- ---------- Main menu frame ----------
local gWidth, gHeight = 360, 480 -- aumentei altura para acomodar novo botão
local Frame = Instance.new("Frame", GUI)
Frame.Name = "FTF_Menu_Frame"
Frame.BackgroundColor3 = Color3.fromRGB(8,10,14)
Frame.Size = UDim2.new(0, gWidth, 0, gHeight)
Frame.Position = UDim2.new(0.5, -gWidth/2, 0.17, 0)
Frame.Active = true
Frame.Visible = false
Frame.BorderSizePixel = 0
Frame.ClipsDescendants = true
local aCorner = Instance.new("UICorner", Frame); aCorner.CornerRadius = UDim.new(0,8)

local Accent = Instance.new("Frame", Frame); Accent.Size = UDim2.new(0,8,1,0); Accent.Position = UDim2.new(0,4,0,0)
Accent.BackgroundColor3 = Color3.fromRGB(49,157,255); Accent.BorderSizePixel = 0
local Title = Instance.new("TextLabel", Frame)
Title.Text = "FTF - David's ESP"; Title.Font = Enum.Font.FredokaOne; Title.TextSize = 20
Title.TextColor3 = Color3.fromRGB(170,200,230); Title.Size = UDim2.new(1, -32, 0, 36); Title.Position = UDim2.new(0,28,0,8)
Title.BackgroundTransparency = 1; Title.TextXAlignment = Enum.TextXAlignment.Left

local Line = Instance.new("Frame", Frame)
Line.BackgroundColor3 = Color3.fromRGB(20,28,36); Line.Position = UDim2.new(0,0,0,48); Line.Size = UDim2.new(1,0,0,2)

-- button creator that returns (button, indicator, labelRef)
local function createFuturisticButton(txt, ypos, c1, c2)
    local btnOuter = Instance.new("TextButton", Frame)
    btnOuter.Name = "FuturBtn_"..txt:gsub("%s+","_")
    btnOuter.BackgroundTransparency = 1
    btnOuter.BorderSizePixel = 0
    btnOuter.AutoButtonColor = false
    btnOuter.Size = UDim2.new(1, -36, 0, 50)
    btnOuter.Position = UDim2.new(0, 18, 0, ypos)
    btnOuter.Text = ""
    btnOuter.ClipsDescendants = true

    local bg = Instance.new("Frame", btnOuter); bg.Name = "BG"; bg.Size = UDim2.new(1,0,1,0); bg.BackgroundColor3 = c1; bg.BorderSizePixel = 0
    local corner = Instance.new("UICorner", bg); corner.CornerRadius = UDim.new(0,12)
    local grad = Instance.new("UIGradient", bg); grad.Color = ColorSequence.new{ColorSequenceKeypoint.new(0,c1), ColorSequenceKeypoint.new(0.6,c2), ColorSequenceKeypoint.new(1,c1)}; grad.Rotation=45

    local inner = Instance.new("Frame", bg); inner.Name="Inner"; inner.Size=UDim2.new(1,-8,1,-10); inner.Position=UDim2.new(0,4,0,5)
    inner.BackgroundColor3 = Color3.fromRGB(12,14,18); inner.BorderSizePixel = 0
    local innerCorner = Instance.new("UICorner", inner); innerCorner.CornerRadius = UDim.new(0,10)
    local innerStroke = Instance.new("UIStroke", inner); innerStroke.Color = Color3.fromRGB(28,36,46); innerStroke.Thickness=1; innerStroke.Transparency=0.2

    local shine = Instance.new("Frame", inner); shine.Size = UDim2.new(1,0,0.28,0); shine.BackgroundTransparency = 0.9; shine.BackgroundColor3 = Color3.fromRGB(30,45,60)
    local shineCorner = Instance.new("UICorner", shine); shineCorner.CornerRadius = UDim.new(0,10)

    local label = Instance.new("TextLabel", inner)
    label.Size = UDim2.new(1, -24, 1, -4); label.Position = UDim2.new(0,12,0,2)
    label.BackgroundTransparency = 1; label.Font = Enum.Font.GothamSemibold; label.Text = txt
    label.TextSize = 15; label.TextColor3 = Color3.fromRGB(170,195,215); label.TextXAlignment = Enum.TextXAlignment.Left

    local indicator = Instance.new("Frame", inner); indicator.Size = UDim2.new(0,50,0,26); indicator.Position = UDim2.new(1,-64,0.5,-13)
    indicator.BackgroundColor3 = Color3.fromRGB(10,12,14); indicator.BorderSizePixel = 0
    local indCorner = Instance.new("UICorner", indicator); indCorner.CornerRadius = UDim.new(0,10)
    local indBar = Instance.new("Frame", indicator); indBar.Size = UDim2.new(0.38,0,0.5,0); indBar.Position = UDim2.new(0.06,0,0.25,0)
    indBar.BackgroundColor3 = Color3.fromRGB(90,160,220); local indCorner2 = Instance.new("UICorner", indBar); indCorner2.CornerRadius = UDim.new(0,8)

    -- hover/click animations
    local hoverTweenInfo = TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
    btnOuter.MouseEnter:Connect(function()
        pcall(function()
            TweenService:Create(grad, hoverTweenInfo, {Rotation = 135}):Play()
            TweenService:Create(indBar, hoverTweenInfo, {Size = UDim2.new(0.66,0,0.66,0), Position = UDim2.new(0.16,0,0.17,0)}):Play()
            TweenService:Create(label, hoverTweenInfo, {TextColor3 = Color3.fromRGB(220,235,245)}):Play()
        end)
    end)
    btnOuter.MouseLeave:Connect(function()
        pcall(function()
            TweenService:Create(grad, hoverTweenInfo, {Rotation = 45}):Play()
            TweenService:Create(indBar, hoverTweenInfo, {Size = UDim2.new(0.38,0,0.5,0), Position = UDim2.new(0.06,0,0.25,0)}):Play()
            TweenService:Create(label, hoverTweenInfo, {TextColor3 = Color3.fromRGB(170,195,215)}):Play()
        end)
    end)
    btnOuter.MouseButton1Down:Connect(function() pcall(function() TweenService:Create(inner, TweenInfo.new(0.09), {Position = UDim2.new(0,6,0,6)}):Play() end) end)
    btnOuter.MouseButton1Up:Connect(function() pcall(function() TweenService:Create(inner, TweenInfo.new(0.12), {Position = UDim2.new(0,4,0,5)}):Play() end) end)

    -- store label for updates
    buttonLabelMap[btnOuter] = label

    return btnOuter, indBar, label
end

-- Create buttons (reordered / spacing adjusted to include FreezePods)
local PlayerBtn, PlayerIndicator = createFuturisticButton("Ativar ESP Jogadores", 70, Color3.fromRGB(28,140,96), Color3.fromRGB(52,215,101))
local CompBtn, CompIndicator   = createFuturisticButton("Ativar Destacar Computadores", 136, Color3.fromRGB(28,90,170), Color3.fromRGB(54,144,255))
local FreezeBtn, FreezeIndicator = createFuturisticButton("Ativar Freeze Pods", 202, Color3.fromRGB(40,200,80), Color3.fromRGB(80,255,140))
local DownTimerBtn, DownIndicator = createFuturisticButton("Ativar Contador de Down", 268, Color3.fromRGB(200,120,30), Color3.fromRGB(255,200,90))
local GraySkinBtn, GraySkinIndicator = createFuturisticButton("Ativar Skin Cinza", 334, Color3.fromRGB(80,80,90), Color3.fromRGB(130,130,140))
local TextureBtn, TextureIndicator, TextureLabel = createFuturisticButton("Ativar Texture Tijolos Brancos", 400, Color3.fromRGB(220,220,220), Color3.fromRGB(245,245,245))

-- Close and draggable
local CloseBtn = Instance.new("TextButton", Frame); CloseBtn.Size = UDim2.new(0,36,0,36); CloseBtn.Position = UDim2.new(1,-44,0,8)
CloseBtn.BackgroundTransparency = 1; CloseBtn.Text = "✕"; CloseBtn.Font = Enum.Font.GothamBlack; CloseBtn.TextSize = 18
CloseBtn.TextColor3 = Color3.fromRGB(140,160,180); CloseBtn.AutoButtonColor = false
CloseBtn.MouseButton1Click:Connect(function() Frame.Visible = false end)
local dragging, dragStart, startPos
Frame.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        dragging = true; dragStart = input.Position; startPos = Frame.Position
        input.Changed:Connect(function() if input.UserInputState == Enum.UserInputState.End then dragging = false end end)
    end
end)
Frame.InputChanged:Connect(function(input)
    if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
        local delta = input.Position - dragStart
        Frame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
    end
end)
local MenuOpen = false
UIS.InputBegan:Connect(function(input, gpe) if not gpe and input.KeyCode == Enum.KeyCode.K then MenuOpen = not MenuOpen; Frame.Visible = MenuOpen end end)

-- ========== PLAYER ESP ==========
local PlayerESPActive = false
local playerHighlights = {}
local NameTags = {}

local function isBeast(player)
    return player.Character and player.Character:FindFirstChild("BeastPowers") ~= nil
end
local function HighlightColorForPlayer(player)
    if isBeast(player) then return Color3.fromRGB(240,28,80), Color3.fromRGB(255,188,188) end
    return Color3.fromRGB(52,215,101), Color3.fromRGB(170,255,200)
end
local function AddPlayerHighlight(player)
    if player == LocalPlayer then return end
    if not player.Character then return end
    if playerHighlights[player] then playerHighlights[player]:Destroy(); playerHighlights[player]=nil end
    local fill, outline = HighlightColorForPlayer(player)
    local h = Instance.new("Highlight")
    h.Name = "[FTF_ESP_PlayerAura_DAVID]"; h.Adornee = player.Character
    -- Important: Highlight is not a GUI element, parent to Workspace so it renders correctly
    h.Parent = Workspace
    h.FillColor = fill; h.OutlineColor = outline; h.FillTransparency = 0.19; h.OutlineTransparency = 0.08
    playerHighlights[player] = h
end
local function RemovePlayerHighlight(player) if playerHighlights[player] then pcall(function() playerHighlights[player]:Destroy() end); playerHighlights[player]=nil end end

local function AddNameTag(player)
    if player==LocalPlayer then return end
    if not player.Character or not player.Character:FindFirstChild("Head") then return end
    if NameTags[player] then NameTags[player]:Destroy(); NameTags[player]=nil end
    local billboard = Instance.new("BillboardGui", GUI)
    billboard.Name = "[FTFName]"; billboard.Adornee = player.Character.Head
    billboard.Size = UDim2.new(0,110,0,20); billboard.StudsOffset = Vector3.new(0,2.18,0); billboard.AlwaysOnTop = true
    local text = Instance.new("TextLabel", billboard)
    text.Size = UDim2.new(1,0,1,0); text.BackgroundTransparency = 1; text.Font = Enum.Font.GothamSemibold
    text.TextSize = 13; text.TextColor3 = Color3.fromRGB(190,210,230); text.TextStrokeColor3 = Color3.fromRGB(8,10,14); text.TextStrokeTransparency = 0.6
    text.Text = player.DisplayName or player.Name
    NameTags[player] = billboard
end
local function RemoveNameTag(player) if NameTags[player] then pcall(function() NameTags[player]:Destroy() end); NameTags[player]=nil end end

local function RefreshPlayerESP()
    for _,p in pairs(Players:GetPlayers()) do
        if PlayerESPActive then AddPlayerHighlight(p); AddNameTag(p) else RemovePlayerHighlight(p); RemoveNameTag(p) end
    end
end

Players.PlayerAdded:Connect(function(p)
    p.CharacterAdded:Connect(function() wait(0.08); if PlayerESPActive then AddPlayerHighlight(p); AddNameTag(p) end end)
end)
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

-- ========== COMPUTER ESP ==========
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
    if compHighlights[model] then compHighlights[model]:Destroy(); compHighlights[model]=nil end
    local h = Instance.new("Highlight")
    h.Name = "[FTF_ESP_ComputerAura_DAVID]"; h.Adornee = model
    -- Parent highlight to Workspace so it displays properly
    h.Parent = Workspace
    h.FillColor = getPcColor(model); h.OutlineColor = Color3.fromRGB(210,210,210)
    h.FillTransparency = 0.14; h.OutlineTransparency = 0.08
    compHighlights[model] = h
end
local function RemoveComputerHighlight(model) if compHighlights[model] then pcall(function() compHighlights[model]:Destroy() end); compHighlights[model]=nil end end
local function RefreshComputerESP()
    for m,h in pairs(compHighlights) do if h then h:Destroy() end end; compHighlights = {}
    if not ComputerESPActive then return end
    for _,d in ipairs(Workspace:GetDescendants()) do if isComputerModel(d) then AddComputerHighlight(d) end end
end
Workspace.DescendantAdded:Connect(function(obj) if ComputerESPActive and isComputerModel(obj) then task.delay(0.05, function() AddComputerHighlight(obj) end) end end)
Workspace.DescendantRemoving:Connect(RemoveComputerHighlight)
RunService.RenderStepped:Connect(function() if ComputerESPActive then for m,h in pairs(compHighlights) do if m and m.Parent and h and h.Parent then h.FillColor = getPcColor(m) end end end end)

-- ========== FREEZE PODS AURA ==========
local FreezePodsActive = false
local podHighlights = {}
local podDescendantConn = nil

local function isFreezePodModel(model)
    if not model or not model:IsA("Model") then return false end
    local name = model.Name:lower()
    if name:find("freezepod") or (name:find("freeze") and name:find("pod")) then return true end
    -- fallback: sometimes pods are named "FreezePod" or "Freeze_Pod", try contains both tokens
    return false
end

local function getPodMainPart(model)
    -- prefer a child named BasePart or a part named "BasePart", otherwise pick largest BasePart
    if not model then return nil end
    if model:FindFirstChild("BasePart") and model.BasePart:IsA("BasePart") then return model.BasePart end
    local biggest
    for _,c in ipairs(model:GetDescendants()) do
        if c:IsA("BasePart") then
            if not biggest or c.Size.Magnitude > biggest.Size.Magnitude then biggest = c end
        end
    end
    return biggest
end

local function AddFreezePodHighlight(model)
    if not model or not isFreezePodModel(model) then return end
    if podHighlights[model] then podHighlights[model]:Destroy(); podHighlights[model]=nil end
    local h = Instance.new("Highlight")
    h.Name = "[FTF_ESP_FreezePodAura_DAVID]"
    h.Adornee = model
    h.Parent = Workspace
    h.FillColor = Color3.fromRGB(100,255,140) -- verde claro
    h.OutlineColor = Color3.fromRGB(40,180,70) -- verde escuro
    h.FillTransparency = 0.25
    h.OutlineTransparency = 0.06
    podHighlights[model] = h
end

local function RemoveFreezePodHighlight(model)
    if podHighlights[model] then pcall(function() podHighlights[model]:Destroy() end); podHighlights[model]=nil end
end

local function RefreshFreezePods()
    for m,_ in pairs(podHighlights) do RemoveFreezePodHighlight(m) end
    if not FreezePodsActive then return end
    for _,d in ipairs(Workspace:GetDescendants()) do
        if isFreezePodModel(d) then AddFreezePodHighlight(d) end
    end
end

-- Listen to workspace changes when enabled
local function onPodDescendantAdded(desc)
    if not FreezePodsActive then return end
    if desc and desc:IsA("Model") and isFreezePodModel(desc) then
        task.delay(0.05, function() AddFreezePodHighlight(desc) end)
    end
end

local function onPodDescendantRemoving(desc)
    RemoveFreezePodHighlight(desc)
end

-- ========== RAGDOLL DOWN TIMER (28s) ==========
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
    if ragdollConnects[player] then pcall(function() ragdollConnects[player]:Disconnect() end); ragdollConnects[player] = nil end
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

-- ========== GRAY SKIN ==========
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

-- ========== SAFE WHITE BRICK TEXTURE (toggle) ==========
local TextureActive = false
local textureBackup = {}         -- [part] = {Color, Material}
local textureDescendantConn = nil

local function isPartPlayerCharacter(part)
    if not part then return false end
    local model = part:FindFirstAncestorWhichIsA("Model")
    if model then
        return Players:GetPlayerFromCharacter(model) ~= nil
    end
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
    if desc and desc:IsA("BasePart") and not isPartPlayerCharacter(desc) then
        task.defer(function() saveAndApplyWhiteBrick(desc) end)
    end
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
    TextureIndicator.BackgroundColor3 = Color3.fromRGB(245,245,245)
    TweenService:Create(TextureIndicator, TweenInfo.new(0.18), {Size = UDim2.new(0.78,0,0.72,0), Position = UDim2.new(0.11,0,0.14,0)}):Play()
    setmetatable({}, {__mode = "k"}) -- harmless placeholder
    task.spawn(applyWhiteBrickToAll)
    textureDescendantConn = Workspace.DescendantAdded:Connect(onWorkspaceDescendantAdded)
    -- update visible label
    if buttonLabelMap[TextureBtn] then buttonLabelMap[TextureBtn].Text = "Desativar Texture Tijolos Brancos" end
end

local function disableTextureToggle()
    if not TextureActive then return end
    TextureActive = false
    if textureDescendantConn then pcall(function() textureDescendantConn:Disconnect() end); textureDescendantConn = nil end
    task.spawn(restoreTextures)
    TextureIndicator.BackgroundColor3 = Color3.fromRGB(90,160,220)
    TweenService:Create(TextureIndicator, TweenInfo.new(0.22), {Size = UDim2.new(0.38,0,0.5,0), Position = UDim2.new(0.06,0,0.25,0)}):Play()
    if buttonLabelMap[TextureBtn] then buttonLabelMap[TextureBtn].Text = "Ativar Texture Tijolos Brancos" end
end

-- ========== BUTTON BEHAVIORS (wiring UI) ==========
PlayerBtn.MouseButton1Click:Connect(function()
    PlayerESPActive = not PlayerESPActive; RefreshPlayerESP()
    if PlayerESPActive then PlayerIndicator.BackgroundColor3 = Color3.fromRGB(52,215,101) else PlayerIndicator.BackgroundColor3 = Color3.fromRGB(90,160,220) end
end)

CompBtn.MouseButton1Click:Connect(function()
    ComputerESPActive = not ComputerESPActive; RefreshComputerESP()
    if ComputerESPActive then CompIndicator.BackgroundColor3 = Color3.fromRGB(54,144,255) else CompIndicator.BackgroundColor3 = Color3.fromRGB(90,160,220) end
end)

-- Freeze Pods button
FreezeBtn.MouseButton1Click:Connect(function()
    FreezePodsActive = not FreezePodsActive
    if FreezePodsActive then
        FreezeIndicator.BackgroundColor3 = Color3.fromRGB(80,255,140)
        -- create highlights for existing pods
        RefreshFreezePods()
        -- connect to workspace changes to add future pods
        if not podDescendantConn then
            podDescendantConn = Workspace.DescendantAdded:Connect(onPodDescendantAdded)
            Workspace.DescendantRemoving:Connect(onPodDescendantRemoving)
        end
        if buttonLabelMap[FreezeBtn] then buttonLabelMap[FreezeBtn].Text = "Desativar Freeze Pods" end
    else
        FreezeIndicator.BackgroundColor3 = Color3.fromRGB(90,160,220)
        -- remove highlights
        for m,_ in pairs(podHighlights) do RemoveFreezePodHighlight(m) end
        if podDescendantConn then pcall(function() podDescendantConn:Disconnect() end); podDescendantConn = nil end
        if buttonLabelMap[FreezeBtn] then buttonLabelMap[FreezeBtn].Text = "Ativar Freeze Pods" end
    end
end)

DownTimerBtn.MouseButton1Click:Connect(function()
    DownTimerActive = not DownTimerActive
    if DownTimerActive then DownIndicator.BackgroundColor3 = Color3.fromRGB(255,200,90)
    else DownIndicator.BackgroundColor3 = Color3.fromRGB(90,160,220) end
    if not DownTimerActive then
        for p,_ in pairs(ragdollBillboards) do if ragdollBillboards[p] then removeRagdollBillboard(p) end end
        for p,_ in pairs(bottomUI) do if bottomUI[p] and bottomUI[p].screenGui and bottomUI[p].screenGui.Parent then bottomUI[p].screenGui:Destroy() end bottomUI[p]=nil end
    else
        for _,p in pairs(Players:GetPlayers()) do
            local ok, temp = pcall(function() return p:FindFirstChild("TempPlayerStatsModule") end)
            if ok and temp then local rag = temp:FindFirstChild("Ragdoll"); if rag and rag.Value then attachRagdollListenerToPlayer(p); end end
        end
    end
end)

GraySkinBtn.MouseButton1Click:Connect(function()
    GraySkinActive = not GraySkinActive
    if GraySkinActive then GraySkinIndicator.BackgroundColor3 = Color3.fromRGB(200,200,200); enableGraySkin()
    else GraySkinIndicator.BackgroundColor3 = Color3.fromRGB(90,160,220); disableGraySkin() end
end)

TextureBtn.MouseButton1Click:Connect(function()
    if not TextureActive then enableTextureToggle() else disableTextureToggle() end
end)

-- Cleanup on unload (best effort)
local function cleanupAll()
    if TextureActive then disableTextureToggle() end
    if GraySkinActive then disableGraySkin() end
    for p,_ in pairs(playerHighlights) do RemovePlayerHighlight(p) end
    for p,_ in pairs(NameTags) do RemoveNameTag(p) end
    for m,_ in pairs(compHighlights) do RemoveComputerHighlight(m) end
    -- disconnect ragdoll listeners and remove billboards
    for p,conn in pairs(ragdollConnects) do pcall(function() conn:Disconnect() end); ragdollConnects[p]=nil end
    for p,_ in pairs(ragdollBillboards) do removeRagdollBillboard(p) end
    for p,_ in pairs(bottomUI) do if bottomUI[p] and bottomUI[p].screenGui and bottomUI[p].screenGui.Parent then bottomUI[p].screenGui:Destroy() end bottomUI[p]=nil end
    -- restore any textures still in backup
    if next(textureBackup) ~= nil then restoreTextures() end
    -- remove pod highlights
    for m,_ in pairs(podHighlights) do RemoveFreezePodHighlight(m) end
    if podDescendantConn then pcall(function() podDescendantConn:Disconnect() end); podDescendantConn = nil end
end

-- Bind PlayerRemoving to cleanup for players
Players.PlayerRemoving:Connect(function(p)
    if skinBackup[p] then restoreGrayForPlayer(p); skinBackup[p]=nil end
    if playerHighlights[p] then RemovePlayerHighlight(p) end
    if NameTags[p] then RemoveNameTag(p) end
    if ragdollConnects[p] then pcall(function() ragdollConnects[p]:Disconnect() end); ragdollConnects[p]=nil end
    if ragdollBillboards[p] then removeRagdollBillboard(p) end
    if bottomUI[p] and bottomUI[p].screenGui and bottomUI[p].screenGui.Parent then bottomUI[p].screenGui:Destroy() end bottomUI[p] = nil
    if compHighlights[p] then RemoveComputerHighlight(p) end
    if skinBackup[p] then restoreGrayForPlayer(p); skinBackup[p] = nil end
end)

-- Done: all features wired
print("[FTF_ESP] Loaded successfully")
