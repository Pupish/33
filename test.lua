-- // Загрузчик UI-библиотеки (OrionLib)
-- Удалить OrionLib и всё, что с ним связано
-- // Простое меню и ESP/Аимбот для Xeno (Drawing API)
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local Mouse = LocalPlayer:GetMouse()
local RunService = game:GetService("RunService")
local UIS = game:GetService("UserInputService")
local Camera = workspace.CurrentCamera

-- // UI и TweenService (раньше, чтобы screenGui был доступен)
local TweenService = game:GetService("TweenService")
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "ESP_Notifications"
screenGui.Parent = game:GetService("CoreGui")

-- // Настройки по умолчанию
local settings = {
    espEnabled = false,
    aimbotEnabled = false,
    aimbotFOV = 100,
    aimbotSmooth = 0.2,
    aimbotKey = Enum.KeyCode.E,
    showBox = true,
    showHealth = true,
    showDistance = true,
    showName = true,
    headHitboxOffset = 0,
    bodyHitboxOffset = 0,
    headHitboxScale = 1,
    bodyHitboxScale = 1,
    headHitboxEnlarger = false,
    headHitboxSize = 5,
    bodyHitboxEnlarger = false,
    bodyHitboxSize = 5,
    spinbotEnabled = false,
    spinbotSpeed = 5,
    coreblockHitboxEnlarger = false,
    coreblockHitboxSize = 5,
}

local menuOpen = false
local menuIndex = 1
local menuItems = {
    {name = "ESP", key = "espEnabled", type = "bool"},
    {name = "Aimbot", key = "aimbotEnabled", type = "bool"},
    {name = "FOV", key = "aimbotFOV", type = "int", min = 30, max = 300, step = 5},
    {name = "Smooth", key = "aimbotSmooth", type = "float", min = 0.05, max = 1, step = 0.01},
    {name = "Aimbot Key", key = "aimbotKey", type = "key"},
    {name = "Box", key = "showBox", type = "bool"},
    {name = "HealthBar", key = "showHealth", type = "bool"},
    {name = "Distance", key = "showDistance", type = "bool"},
    {name = "Name", key = "showName", type = "bool"},
}

-- // Функция для вычисления размера текста
local function getTextSize(text, size, font)
    local t = Drawing.new("Text")
    t.Text = text
    t.Size = size or 16
    t.Font = font or 2
    t.Visible = false
    local bounds = t.TextBounds
    t:Remove()
    return bounds
end

-- // Центрирование текста
local function centerText(textObj, centerX, y)
    textObj.Position = Vector2.new(centerX - textObj.TextBounds.X/2, y)
end

-- // Вспомогательные функции
local function getClosestPlayer()
    local closest, dist = nil, math.huge
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character and player.Character:FindFirstChild("HumanoidRootPart") and player.Character:FindFirstChild("Humanoid") and player.Character.Humanoid.Health > 0 then
            local pos, onScreen = Camera:WorldToViewportPoint(player.Character.HumanoidRootPart.Position)
            if onScreen then
                local mag = (Vector2.new(pos.X, pos.Y) - Vector2.new(Mouse.X, Mouse.Y)).Magnitude
                if mag < settings.aimbotFOV and mag < dist then
                    closest = player
                    dist = mag
                end
            end
        end
    end
    return closest
end

local function getTargetPart(char)
    if settings.aimbotTarget == "Head" and char:FindFirstChild("Head") then
        return char.Head
    elseif char:FindFirstChild("HumanoidRootPart") then
        return char.HumanoidRootPart
    elseif char:FindFirstChild("Torso") then
        return char.Torso
    end
    return nil
end

-- // Для аимбота: Raycast проверка видимости цели
-- (удалить функцию isTargetVisible и вызовы)

-- // Аимбот с учетом увеличенного хитбокса (теперь всегда в центр головы/тела)
RunService.RenderStepped:Connect(function()
    if settings.aimbotEnabled and aiming then
        local target = getClosestPlayer()
        if target and target.Character then
            local part = getTargetPart(target.Character)
            if part then
                local aimPos = part.Position
                if settings.aimbotTarget == "Head" and part:IsA("BasePart") then
                    local offset = settings.headHitboxOffset
                    aimPos = part.Position + Vector3.new(0, part.Size.Y/2 + offset, 0)
                elseif settings.aimbotTarget == "HumanoidRootPart" and part:IsA("BasePart") then
                    local offset = settings.bodyHitboxOffset
                    aimPos = part.Position + Vector3.new(0, offset, 0)
                end
                local pos = Camera:WorldToViewportPoint(aimPos)
                local mousePos = Vector2.new(Mouse.X, Mouse.Y)
                local targetPos = Vector2.new(pos.X, pos.Y)
                local move = (targetPos - mousePos) * settings.aimbotSmooth
                pcall(function() mousemoverel(move.X, move.Y) end)
            end
        end
    end
end)

UIS.InputBegan:Connect(function(input, gpe)
    if gpe then return end
    if input.KeyCode == settings.aimbotKey then
        aiming = true
    end
end)
UIS.InputEnded:Connect(function(input, gpe)
    if gpe then return end
    if input.KeyCode == settings.aimbotKey then
        aiming = false
    end
end)

-- // ESP
local espObjects = {}
function ClearESP()
    for _,v in pairs(espObjects) do
        for _,obj in pairs(v) do
            if obj and obj.Remove then obj:Remove() end
        end
    end
    espObjects = {}
end

function DrawESP(player)
    if not player.Character or not player.Character:FindFirstChild("HumanoidRootPart") then return end
    local box = Drawing.new("Square")
    box.Visible = false
    box.Color = Color3.fromRGB(0,255,0)
    box.Thickness = 2
    box.Filled = true
    box.Transparency = 0.18
    local boxOutline = Drawing.new("Square")
    boxOutline.Visible = false
    boxOutline.Color = Color3.fromRGB(0,255,0)
    boxOutline.Thickness = 2
    boxOutline.Filled = false
    local healthBar = Drawing.new("Line")
    healthBar.Visible = false
    healthBar.Color = Color3.fromRGB(255,0,0)
    healthBar.Thickness = 4
    local nameText = Drawing.new("Text")
    nameText.Visible = false
    nameText.Size = 16
    nameText.Color = Color3.fromRGB(255,255,255)
    nameText.Outline = true
    local distText = Drawing.new("Text")
    distText.Visible = false
    distText.Size = 14
    distText.Color = Color3.fromRGB(0,255,255)
    distText.Outline = true
    espObjects[player] = {box, boxOutline, healthBar, nameText, distText}
end

-- // Увеличение хитбокса головы (Head) и тела (HumanoidRootPart) для других игроков
local defaultHeadProps = {}
local defaultBodyProps = {}
RunService.RenderStepped:Connect(function()
    -- Head
    if settings.headHitboxEnlarger then
        for _,v in ipairs(Players:GetPlayers()) do
            if v ~= LocalPlayer and v.Character and v.Character:FindFirstChild("Head") then
                local head = v.Character.Head
                pcall(function()
                    if not defaultHeadProps[head] then
                        defaultHeadProps[head] = {
                            Size = head.Size,
                            Transparency = head.Transparency,
                            BrickColor = head.BrickColor,
                            Material = head.Material,
                            CanCollide = head.CanCollide
                        }
                    end
                    head.Size = Vector3.new(settings.headHitboxSize, settings.headHitboxSize, settings.headHitboxSize)
                    head.Transparency = 0.7
                    head.BrickColor = BrickColor.new("Really blue")
                    head.Material = Enum.Material.Neon
                    head.CanCollide = false
                end)
            end
        end
    else
        for _,v in ipairs(Players:GetPlayers()) do
            if v ~= LocalPlayer and v.Character and v.Character:FindFirstChild("Head") then
                local head = v.Character.Head
                if defaultHeadProps[head] then
                    pcall(function()
                        head.Size = defaultHeadProps[head].Size
                        head.Transparency = defaultHeadProps[head].Transparency
                        head.BrickColor = defaultHeadProps[head].BrickColor
                        head.Material = defaultHeadProps[head].Material
                        head.CanCollide = defaultHeadProps[head].CanCollide
                    end)
                    defaultHeadProps[head] = nil
                end
            end
        end
    end
    -- Body (HumanoidRootPart)
    if settings.bodyHitboxEnlarger then
        for _,v in ipairs(Players:GetPlayers()) do
            if v ~= LocalPlayer and v.Character and v.Character:FindFirstChild("HumanoidRootPart") then
                local body = v.Character.HumanoidRootPart
                pcall(function()
                    if not defaultBodyProps[body] then
                        defaultBodyProps[body] = {
                            Size = body.Size,
                            Transparency = body.Transparency,
                            BrickColor = body.BrickColor,
                            Material = body.Material,
                            CanCollide = body.CanCollide
                        }
                    end
                    body.Size = Vector3.new(settings.bodyHitboxSize, settings.bodyHitboxSize, settings.bodyHitboxSize)
                    body.Transparency = 0.7
                    body.BrickColor = BrickColor.new("Really red")
                    body.Material = Enum.Material.Neon
                    body.CanCollide = false
                end)
            end
        end
    else
        for _,v in ipairs(Players:GetPlayers()) do
            if v ~= LocalPlayer and v.Character and v.Character:FindFirstChild("HumanoidRootPart") then
                local body = v.Character.HumanoidRootPart
                if defaultBodyProps[body] then
                    pcall(function()
                        body.Size = defaultBodyProps[body].Size
                        body.Transparency = defaultBodyProps[body].Transparency
                        body.BrickColor = defaultBodyProps[body].BrickColor
                        body.Material = defaultBodyProps[body].Material
                        body.CanCollide = defaultBodyProps[body].CanCollide
                    end)
                    defaultBodyProps[body] = nil
                end
            end
        end
    end
end)

-- // Spinbot (вращение персонажа)
RunService.RenderStepped:Connect(function(dt)
    if settings.spinbotEnabled and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
        local hrp = LocalPlayer.Character.HumanoidRootPart
        hrp.CFrame = hrp.CFrame * CFrame.Angles(0, math.rad(settings.spinbotSpeed), 0)
    end
end)

-- // Увеличение хитбокса Coreblock (LowerTorso/UpperTorso) для других игроков
local defaultCoreblockProps = {}
RunService.RenderStepped:Connect(function()
    if settings.coreblockHitboxEnlarger then
        for _,v in ipairs(Players:GetPlayers()) do
            if v ~= LocalPlayer and v.Character then
                local torso = v.Character:FindFirstChild("LowerTorso") or v.Character:FindFirstChild("UpperTorso")
                if torso then
                    pcall(function()
                        if not defaultCoreblockProps[torso] then
                            defaultCoreblockProps[torso] = {
                                Size = torso.Size,
                                Transparency = torso.Transparency,
                                BrickColor = torso.BrickColor,
                                Material = torso.Material,
                                CanCollide = torso.CanCollide
                            }
                        end
                        torso.Size = Vector3.new(settings.coreblockHitboxSize, settings.coreblockHitboxSize, settings.coreblockHitboxSize)
                        torso.Transparency = 0.7
                        torso.BrickColor = BrickColor.new("Lime green")
                        torso.Material = Enum.Material.Neon
                        torso.CanCollide = false
                    end)
                end
            end
        end
    else
        for _,v in ipairs(Players:GetPlayers()) do
            if v ~= LocalPlayer and v.Character then
                local torso = v.Character:FindFirstChild("LowerTorso") or v.Character:FindFirstChild("UpperTorso")
                if torso and defaultCoreblockProps[torso] then
                    pcall(function()
                        torso.Size = defaultCoreblockProps[torso].Size
                        torso.Transparency = defaultCoreblockProps[torso].Transparency
                        torso.BrickColor = defaultCoreblockProps[torso].BrickColor
                        torso.Material = defaultCoreblockProps[torso].Material
                        torso.CanCollide = defaultCoreblockProps[torso].CanCollide
                    end)
                    defaultCoreblockProps[torso] = nil
                end
            end
        end
    end
end)

-- // UI-меню ESP/Аимбота (добавить spinbot)
local espMenu = nil
local function showESPMenu()
    if espMenu then espMenu:Destroy() espMenu = nil end
    espMenu = Instance.new("Frame")
    espMenu.Name = "ESPMenu"
    espMenu.Size = UDim2.new(0, 420, 0, 520)
    espMenu.Position = UDim2.new(0.5, -210, 0.5, -260)
    espMenu.BackgroundColor3 = Color3.fromRGB(30, 34, 50)
    espMenu.BorderSizePixel = 0
    espMenu.Parent = screenGui
    espMenu.ZIndex = 200
    espMenu.Active = true
    espMenu.Draggable = true

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0.08, 0)
    corner.Parent = espMenu

    local shadow = Instance.new("Frame")
    shadow.Size = UDim2.new(1, 12, 1, 12)
    shadow.Position = UDim2.new(0, -6, 0, -6)
    shadow.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    shadow.BackgroundTransparency = 0.7
    shadow.BorderSizePixel = 0
    shadow.ZIndex = 199
    shadow.Parent = espMenu
    local shadowCorner = Instance.new("UICorner")
    shadowCorner.CornerRadius = UDim.new(0.08, 0)
    shadowCorner.Parent = shadow

    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(1, 0, 0.13, 0)
    title.Position = UDim2.new(0, 0, 0, 0)
    title.BackgroundTransparency = 1
    title.Text = "ESP & AIMBOT"
    title.TextColor3 = Color3.fromRGB(255, 255, 255)
    title.TextStrokeTransparency = 0.7
    title.TextScaled = true
    title.Font = Enum.Font.GothamBold
    title.Parent = espMenu
    title.ZIndex = 201

    local closeBtn = Instance.new("TextButton")
    closeBtn.Size = UDim2.new(0.13, 0, 0.13, 0)
    closeBtn.Position = UDim2.new(0.87, 0, 0, 0)
    closeBtn.BackgroundColor3 = Color3.fromRGB(255, 60, 60)
    closeBtn.Text = "X"
    closeBtn.TextScaled = true
    closeBtn.Font = Enum.Font.GothamBold
    closeBtn.TextColor3 = Color3.fromRGB(255,255,255)
    closeBtn.Parent = espMenu
    closeBtn.ZIndex = 202
    local closeCorner = Instance.new("UICorner")
    closeCorner.CornerRadius = UDim.new(0.5, 0)
    closeCorner.Parent = closeBtn
    closeBtn.MouseButton1Click:Connect(function()
        espMenu:Destroy()
        espMenu = nil
    end)

    -- Контейнер для элементов
    local content = Instance.new("Frame")
    content.Size = UDim2.new(1, 0, 0.87, 0)
    content.Position = UDim2.new(0, 0, 0.13, 0)
    content.BackgroundTransparency = 1
    content.Parent = espMenu
    content.ZIndex = 201

    local layout = Instance.new("UIListLayout")
    layout.Padding = UDim.new(0, 10)
    layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
    layout.SortOrder = Enum.SortOrder.LayoutOrder
    layout.Parent = content

    -- Универсальный Toggle
    local function createToggle(text, settingKey)
        local toggle = Instance.new("TextButton")
        toggle.Size = UDim2.new(0.92, 0, 0, 38)
        toggle.BackgroundColor3 = settings[settingKey] and Color3.fromRGB(80, 200, 120) or Color3.fromRGB(60, 70, 100)
        toggle.Text = text .. ": " .. (settings[settingKey] and "ON" or "OFF")
        toggle.TextScaled = true
        toggle.Font = Enum.Font.GothamBold
        toggle.TextColor3 = Color3.fromRGB(255,255,255)
        toggle.ZIndex = 202
        local btnCorner = Instance.new("UICorner")
        btnCorner.CornerRadius = UDim.new(0.25, 0)
        btnCorner.Parent = toggle
        toggle.Parent = content
        toggle.MouseButton1Click:Connect(function()
            settings[settingKey] = not settings[settingKey]
            toggle.Text = text .. ": " .. (settings[settingKey] and "ON" or "OFF")
            toggle.BackgroundColor3 = settings[settingKey] and Color3.fromRGB(80, 200, 120) or Color3.fromRGB(60, 70, 100)
        end)
    end

    -- Слайдер
    local function createSlider(text, settingKey, min, max, step)
        local frame = Instance.new("Frame")
        frame.Size = UDim2.new(0.92, 0, 0, 38)
        frame.BackgroundColor3 = Color3.fromRGB(60, 70, 100)
        frame.ZIndex = 202
        frame.Parent = content
        local corner = Instance.new("UICorner")
        corner.CornerRadius = UDim.new(0.25, 0)
        corner.Parent = frame
        local label = Instance.new("TextLabel")
        label.Size = UDim2.new(0.5, 0, 1, 0)
        label.Position = UDim2.new(0, 0, 0, 0)
        label.BackgroundTransparency = 1
        label.Text = text .. ": " .. tostring(settings[settingKey])
        label.TextScaled = true
        label.Font = Enum.Font.GothamBold
        label.TextColor3 = Color3.fromRGB(255,255,255)
        label.ZIndex = 203
        label.Parent = frame
        local input = Instance.new("TextBox")
        input.Size = UDim2.new(0.5, 0, 1, 0)
        input.Position = UDim2.new(0.5, 0, 0, 0)
        input.BackgroundColor3 = Color3.fromRGB(80, 120, 200)
        input.Text = tostring(settings[settingKey])
        input.TextScaled = true
        input.Font = Enum.Font.GothamBold
        input.TextColor3 = Color3.fromRGB(255,255,255)
        input.ZIndex = 203
        input.Parent = frame
        input.FocusLost:Connect(function()
            local val = tonumber(input.Text)
            if val and val >= min and val <= max then
                val = math.floor(val/step+0.5)*step
                settings[settingKey] = val
                label.Text = text .. ": " .. tostring(val)
                input.Text = tostring(val)
            else
                input.Text = tostring(settings[settingKey])
            end
        end)
    end

    -- Дропдаун
    local function createDropdown(text, settingKey, options)
        local frame = Instance.new("Frame")
        frame.Size = UDim2.new(0.92, 0, 0, 38)
        frame.BackgroundColor3 = Color3.fromRGB(60, 70, 100)
        frame.ZIndex = 202
        frame.Parent = content
        local corner = Instance.new("UICorner")
        corner.CornerRadius = UDim.new(0.25, 0)
        corner.Parent = frame
        local label = Instance.new("TextLabel")
        label.Size = UDim2.new(0.5, 0, 1, 0)
        label.Position = UDim2.new(0, 0, 0, 0)
        label.BackgroundTransparency = 1
        label.Text = text .. ": " .. tostring(settings[settingKey])
        label.TextScaled = true
        label.Font = Enum.Font.GothamBold
        label.TextColor3 = Color3.fromRGB(255,255,255)
        label.ZIndex = 203
        label.Parent = frame
        local btn = Instance.new("TextButton")
        btn.Size = UDim2.new(0.5, 0, 1, 0)
        btn.Position = UDim2.new(0.5, 0, 0, 0)
        btn.BackgroundColor3 = Color3.fromRGB(80, 120, 200)
        btn.Text = "Изм."
        btn.TextScaled = true
        btn.Font = Enum.Font.GothamBold
        btn.TextColor3 = Color3.fromRGB(255,255,255)
        btn.ZIndex = 203
        btn.Parent = frame
        btn.MouseButton1Click:Connect(function()
            local idx = table.find(options, settings[settingKey]) or 1
            idx = idx % #options + 1
            settings[settingKey] = options[idx]
            label.Text = text .. ": " .. tostring(settings[settingKey])
        end)
    end

    -- KeyBind
    local function createKeyBind(text, settingKey)
        local frame = Instance.new("Frame")
        frame.Size = UDim2.new(0.92, 0, 0, 38)
        frame.BackgroundColor3 = Color3.fromRGB(60, 70, 100)
        frame.ZIndex = 202
        frame.Parent = content
        local corner = Instance.new("UICorner")
        corner.CornerRadius = UDim.new(0.25, 0)
        corner.Parent = frame
        local label = Instance.new("TextLabel")
        label.Size = UDim2.new(0.5, 0, 1, 0)
        label.Position = UDim2.new(0, 0, 0, 0)
        label.BackgroundTransparency = 1
        label.Text = text .. ": " .. tostring(settings[settingKey]):gsub("Enum.KeyCode.", "")
        label.TextScaled = true
        label.Font = Enum.Font.GothamBold
        label.TextColor3 = Color3.fromRGB(255,255,255)
        label.ZIndex = 203
        label.Parent = frame
        local btn = Instance.new("TextButton")
        btn.Size = UDim2.new(0.5, 0, 1, 0)
        btn.Position = UDim2.new(0.5, 0, 0, 0)
        btn.BackgroundColor3 = Color3.fromRGB(80, 120, 200)
        btn.Text = "Изм."
        btn.TextScaled = true
        btn.Font = Enum.Font.GothamBold
        btn.TextColor3 = Color3.fromRGB(255,255,255)
        btn.ZIndex = 203
        btn.Parent = frame
        btn.MouseButton1Click:Connect(function()
            label.Text = text .. ": ..."
            local conn; conn = UIS.InputBegan:Connect(function(inp, g)
                if not g and inp.UserInputType == Enum.UserInputType.Keyboard then
                    settings[settingKey] = inp.KeyCode
                    label.Text = text .. ": " .. tostring(settings[settingKey]):gsub("Enum.KeyCode.", "")
                    conn:Disconnect()
                end
            end)
        end)
    end

    -- Элементы меню   espEnabled
    createToggle("Esp", "espEnabled")
    createToggle("Head Hitbox Enlarger", "headHitboxEnlarger")
    createSlider("Head Hitbox Size", "headHitboxSize", 1, 5, 0.1)
    createToggle("Body Hitbox Enlarger", "bodyHitboxEnlarger")
    createSlider("Body Hitbox Size", "bodyHitboxSize", 1,35, 0.1)  
    createToggle("Box", "showBox")
    createToggle("HealthBar", "showHealth")
    createToggle("Distance", "showDistance")
    createToggle("Name", "showName")
    createToggle("Spinbot", "spinbotEnabled")
    createSlider("Spin Speed", "spinbotSpeed", 1, 50, 1)
    createToggle("Coreblock Hitbox Enlarger", "coreblockHitboxEnlarger")
    createSlider("Coreblock Hitbox Size", "coreblockHitboxSize", 2, 25, 0.1)
end

-- Открытие/закрытие меню по RightShift
UIS.InputBegan:Connect(function(input, gpe)
    if gpe then return end
    if input.KeyCode == Enum.KeyCode.RightShift then
        if espMenu and espMenu.Parent then
            espMenu:Destroy() espMenu = nil
        else
            showESPMenu()
        end
    end
end)

-- // ESP: ник и дистанция чуть выше головы
RunService.RenderStepped:Connect(function()
    if not settings.espEnabled then
        ClearESP()
        return
    end
    for _,player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character and player.Character:FindFirstChild("HumanoidRootPart") and player.Character:FindFirstChild("Humanoid") and player.Character.Humanoid.Health > 0 then
            if not espObjects[player] then DrawESP(player) end
            local hrp = player.Character.HumanoidRootPart
            local hum = player.Character.Humanoid
            local head = player.Character:FindFirstChild("Head")
            local root = player.Character:FindFirstChild("HumanoidRootPart")
            local pos, onScreen = Camera:WorldToViewportPoint(hrp.Position)
            -- BoundingBox для Strucid
            local sizeY, sizeX, centerX, centerY = 60, 30, pos.X, pos.Y
            if player.Character and player.Character:IsA("Model") then
                local cf, sz = player.Character:GetBoundingBox()
                -- Верхняя и нижняя точки
                local top3d = (cf.Position + Vector3.new(0, sz.Y/2, 0))
                local bottom3d = (cf.Position - Vector3.new(0, sz.Y/2, 0))
                local top2d = Camera:WorldToViewportPoint(top3d)
                local bottom2d = Camera:WorldToViewportPoint(bottom3d)
                sizeY = math.abs(top2d.Y - bottom2d.Y)
                sizeX = sz.X * (sizeY/sz.Y)
                centerX = (top2d.X + bottom2d.X) / 2
                centerY = (top2d.Y + bottom2d.Y) / 2
            end
            local box, boxOutline, healthBar, nameText, distText = unpack(espObjects[player])
            if onScreen then
                -- Бокс
                if settings.showBox then
                    box.Visible = true
                    boxOutline.Visible = true
                    box.Size = Vector2.new(sizeX, sizeY)
                    box.Position = Vector2.new(centerX - sizeX/2, centerY - sizeY/2)
                    boxOutline.Size = box.Size
                    boxOutline.Position = box.Position
                else
                    box.Visible = false
                    boxOutline.Visible = false
                end
                -- Полоска здоровья
                if settings.showHealth then
                    healthBar.Visible = true
                    local hum = player.Character:FindFirstChild("Humanoid")
                    local healthPerc = hum and math.clamp(hum.Health / math.max(1, hum.MaxHealth), 0, 1) or 1
                    local barHeight = math.max(sizeY, 20)
                    healthBar.From = Vector2.new(centerX - sizeX/2 - 10, centerY - barHeight/2)
                    healthBar.To = Vector2.new(centerX - sizeX/2 - 10, centerY - barHeight/2 + barHeight * healthPerc)
                    healthBar.Thickness = 8
                    healthBar.Transparency = 0
                    healthBar.Color = Color3.fromRGB(255 - (255 * healthPerc), 255 * healthPerc, 40)
                else
                    healthBar.Visible = false
                end
                -- Имя и дистанция (центрирование, выше головы)
                if settings.showName then
                    nameText.Visible = true
                    local headPos = head and Camera:WorldToViewportPoint(head.Position) or pos
                    nameText.Text = player.Name
                    if settings.showDistance then
                        distText.Visible = true
                        local dist = (hrp.Position - Camera.CFrame.Position).Magnitude
                        distText.Text = string.format("%.0fм", dist)
                        centerText(distText, headPos.X, headPos.Y - 52)
                        centerText(nameText, headPos.X, headPos.Y - 32)
                    else
                        distText.Visible = false
                        centerText(nameText, headPos.X, headPos.Y - 32)
                    end
                else
                    nameText.Visible = false
                    distText.Visible = false
                end
            else
                box.Visible = false
                boxOutline.Visible = false
                healthBar.Visible = false
                nameText.Visible = false
                distText.Visible = false
            end
        end
    end
    -- Очищение залипших ESP
    for player, objs in pairs(espObjects) do
        if not player.Parent or not player.Character or not player.Character:FindFirstChild("HumanoidRootPart") or not player.Character:FindFirstChild("Humanoid") or player.Character.Humanoid.Health <= 0 then
            for _,obj in pairs(objs) do
                if obj and obj.Remove then obj:Remove() end
            end
            espObjects[player] = nil
        end
    end
end)

-- // Уведомления (UI)
local notificationQueue = {}
local activeNotifications = {}

local function notification(text, time)
    time = time or 2.5

    local notif = Instance.new("Frame")
    notif.Size = UDim2.new(0, 320, 0, 60)
    notif.Position = UDim2.new(0, -340, 0, 30)
    notif.BackgroundColor3 = Color3.fromRGB(40, 120, 255)
    notif.BackgroundTransparency = 0.08
    notif.BorderSizePixel = 0
    notif.Parent = screenGui
    notif.ZIndex = 1000

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0.18, 0)
    corner.Parent = notif

    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, -20, 1, -20)
    label.Position = UDim2.new(0, 10, 0, 10)
    label.BackgroundTransparency = 1
    label.Text = tostring(text)
    label.TextColor3 = Color3.fromRGB(255,255,255)
    label.TextScaled = true
    label.Font = Enum.Font.GothamBold
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Parent = notif
    label.ZIndex = 1001

    table.insert(notificationQueue, notif)

    local function updatePositions()
        for i, notification in ipairs(notificationQueue) do
            if notification and notification.Parent then
                local targetY = 30 + (i - 1) * 70 -- 70 пикселей между уведомлениями
                local tween = TweenService:Create(notification, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
                    Position = UDim2.new(0, 20, 0, targetY)
                })
                tween:Play()
            end
        end
    end

    local function removeFromQueue(notificationToRemove)
        for i, notification in ipairs(notificationQueue) do
            if notification == notificationToRemove then
                table.remove(notificationQueue, i)
                break
            end
        end
        updatePositions()
    end

    local tweenIn = TweenService:Create(notif, TweenInfo.new(0.4, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
        Position = UDim2.new(0, 20, 0, 30 + (#notificationQueue - 1) * 70)
    })
    tweenIn:Play()

    spawn(function()
        task.wait(time)

        local tweenOut = TweenService:Create(notif, TweenInfo.new(0.4, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
            Position = UDim2.new(0, -340, 0, notif.Position.Y.Offset)
        })
        tweenOut:Play()
        tweenOut.Completed:Wait()
        removeFromQueue(notif)
        notif:Destroy()
    end)
end

notification("Скрипт успешно загружен!", 3)
