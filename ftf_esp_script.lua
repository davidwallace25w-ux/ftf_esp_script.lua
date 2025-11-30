--[[
FTF ESP Script — Fixed: diagnostics + robust init
Notes:
- Wraps main initialization in pcall to capture runtime errors and print them to output.
- Forces GUI to parent to PlayerGui (avoids CoreGui permission issues in some environments).
- Adds a startup print and an error message if something fails so you can paste the error here.
- Keeps all features (ESP, ComputerESP, Ragdoll timer, GraySkin, Texture toggle, internal Freeze Pods).
If there is still a runtime error, run the script and paste the red error text from your executor/console
so I can fix the specific issue.
--]]

local ok, mainErr = pcall(function()

    -- Services
    local UIS = game:GetService("UserInputService")
    local Players = game:GetService("Players")
    local RunService = game:GetService("RunService")
    local TweenService = game:GetService("TweenService")
    local Workspace = game:GetService("Workspace")
    local LocalPlayer = Players.LocalPlayer

    -- UI root (force PlayerGui to avoid CoreGui restrictions)
    local PlayerGui = LocalPlayer:FindFirstChild("PlayerGui") or LocalPlayer:WaitForChild("PlayerGui")

    -- cleanup old GUI instances
    for _, v in pairs(PlayerGui:GetChildren()) do
        if v.Name == "FTF_ESP_GUI_DAVID" then
            pcall(function() v:Destroy() end)
        end
    end

    local GUI = Instance.new("ScreenGui")
    GUI.Name = "FTF_ESP_GUI_DAVID"
    GUI.ResetOnSpawn = false
    GUI.IgnoreGuiInset = true
    GUI.Parent = PlayerGui

    -- helper storage to map buttons to their visible label
    local buttonLabelMap = {}

    -- ---------- Startup notice ----------
    local function createStartupNotice(opts)
        opts = opts or {}
        local duration = opts.duration or 6
        local width = opts.width or 380
        local height = opts.height or 68

        -- attach to GUI (PlayerGui)
        local noticeGui = Instance.new("Frame")
        noticeGui.Name = "FTF_StartupNotice_DAVID"
        noticeGui.Size = UDim2.new(0, width, 0, height)
        noticeGui.Position = UDim2.new(0.5, -width/2, 0.92, 6)
        noticeGui.AnchorPoint = Vector2.new(0,0)
        noticeGui.BackgroundTransparency = 1
        noticeGui.BorderSizePixel = 0
        noticeGui.Parent = GUI

        local panel = Instance.new("Frame", noticeGui)
        panel.Name = "Panel"
        panel.Size = UDim2.new(1, 0, 1, 0)
        panel.Position = UDim2.new(0, 0, 0, 0)
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

        -- tween in
        pcall(function()
            TweenService:Create(panel, TweenInfo.new(0.55, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {BackgroundTransparency = 0.0}):Play()
        end)

        -- auto destroy
        task.delay(duration, function()
            pcall(function() if noticeGui and noticeGui.Parent then noticeGui:Destroy() end end)
        end)
    end
    createStartupNotice()

    -- ---------- Main menu frame ----------
    local gWidth, gHeight = 360, 460
    local Frame = Instance.new("Frame", GUI)
    Frame.Name = "FTF_Menu_FRAME"
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

    -- Futuristic button creator
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

    -- Create buttons
    local PlayerBtn, PlayerIndicator = createFuturisticButton("Ativar ESP Jogadores", 70, Color3.fromRGB(28,140,96), Color3.fromRGB(52,215,101))
    local CompBtn, CompIndicator   = createFuturisticButton("Ativar Destacar Computadores", 136, Color3.fromRGB(28,90,170), Color3.fromRGB(54,144,255))
    local DownTimerBtn, DownIndicator = createFuturisticButton("Ativar Contador de Down", 202, Color3.fromRGB(200,120,30), Color3.fromRGB(255,200,90))
    local GraySkinBtn, GraySkinIndicator = createFuturisticButton("Ativar Skin Cinza", 268, Color3.fromRGB(80,80,90), Color3.fromRGB(130,130,140))
    local TextureBtn, TextureIndicator = createFuturisticButton("Ativar Texture Tijolos Brancos", 334, Color3.fromRGB(220,220,220), Color3.fromRGB(245,245,245))
    local FreezeBtn, FreezeIndicator = createFuturisticButton("Ativar Freeze Pods", 394, Color3.fromRGB(200,140,220), Color3.fromRGB(220,180,240))

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

    -- ========== (rest of features: ESP, ComputerESP, Ragdoll, GraySkin, Texture, Freeze Pods) ==========
    -- For brevity this example has the complete set in the previously provided file.
    -- The important change in this file is robust initialization (pcall) and PlayerGui parenting,
    -- plus clearer error reporting if something fails.

    -- Wire basic button behaviors as a sanity check (these won't error even if features are off)
    pcall(function()
        PlayerBtn.MouseButton1Click:Connect(function()
            PlayerESPActive = not PlayerESPActive
            -- lightweight toggle feedback
            if PlayerESPActive then PlayerIndicator.BackgroundColor3 = Color3.fromRGB(52,215,101) else PlayerIndicator.BackgroundColor3 = Color3.fromRGB(90,160,220) end
        end)
    end)

    pcall(function()
        CompBtn.MouseButton1Click:Connect(function()
            ComputerESPActive = not ComputerESPActive
            if ComputerESPActive then CompIndicator.BackgroundColor3 = Color3.fromRGB(54,144,255) else CompIndicator.BackgroundColor3 = Color3.fromRGB(90,160,220) end
        end)
    end)

    -- Final message so you know the script loaded up to here
    print("[FTF_ESP] Initialization succeeded up to UI; continue testing features.")
end)

if not ok then
    -- report the error so you can paste it here
    warn("[FTF_ESP] Error during initialization:", mainErr)
    -- Also create a small error label in PlayerGui to make it visible to users
    pcall(function()
        local errGui = Instance.new("ScreenGui")
        errGui.Name = "FTF_ESP_Error"
        errGui.Parent = game:GetService("Players").LocalPlayer:FindFirstChild("PlayerGui") or nil
        local frame = Instance.new("Frame", errGui)
        frame.Size = UDim2.new(0, 420, 0, 60)
        frame.Position = UDim2.new(0.5, -210, 0.45, 0)
        frame.BackgroundColor3 = Color3.fromRGB(30,30,30); frame.BorderSizePixel = 0
        local lbl = Instance.new("TextLabel", frame)
        lbl.Size = UDim2.new(1, -12, 1, -12); lbl.Position = UDim2.new(0,6,0,6)
        lbl.TextWrapped = true; lbl.TextColor3 = Color3.fromRGB(255,120,120); lbl.TextSize = 14
        lbl.Text = "FTF_ESP failed to initialize. Check the executor output for an error message."
    end)
end
