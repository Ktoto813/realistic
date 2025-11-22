-- Realistic Street Soccer Goalkeeper Side Dive (Q/E to dive and block the ball) [Rayfield]
local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()
local plr = game.Players.LocalPlayer
local GK_ACTIVE = false
local diveDistance = 6           -- длина прыжка в сторону (можно изменить)
local diveSpeed = 0.22           -- скорость (чем меньше, тем резче рывок, не ставь меньше 0.14)
local lastDive = 0

local function closestBall()
    local char = plr.Character
    if not char or not char:FindFirstChild("HumanoidRootPart") then return nil end
    local hrp = char.HumanoidRootPart
    local nearest, dist = nil, math.huge
    for _,ball in ipairs(workspace:GetDescendants()) do
        if ball:IsA("BasePart") and ball.Name:lower():find("ball") then
            local d = (hrp.Position - ball.Position).Magnitude
            if d < dist then
                nearest = ball
                dist = d
            end
        end
    end
    return nearest, dist
end

local function dive(side) -- 'L' или 'R'
    if not GK_ACTIVE then return end
    local char = plr.Character
    if not char or not char:FindFirstChild("HumanoidRootPart") then return end
    local hrp = char.HumanoidRootPart
    -- Позиция ворот, чтобы разрешить только около ворот!
    local ball = closestBall()
    if not ball then return end

    -- Рассчёт направления к мячу, side=Q/E
    local dirVec = CFrame.new(hrp.Position, ball.Position).RightVector.Unit
    if side == "L" then dirVec = -dirVec end
    -- двигаемся вбок и немного в сторону мяча (X/Z ± Y)
    local targetPos = hrp.Position + dirVec*diveDistance

    -- Уменьшаем задержку между прыжками
    if tick()-lastDive < 0.5 then return end
    lastDive = tick()

    -- Движение рывком
    local N = 10
    for i=1,N do
        local t = i/N
        hrp.CFrame = hrp.CFrame:Lerp(CFrame.new(targetPos.X, hrp.Position.Y, targetPos.Z), t)
        hrp.Velocity = Vector3.new(0,0,0)
        task.wait(diveSpeed/N)
    end
end

-- UI - Rayfield
local Window = Rayfield:CreateWindow({
    Name = "Realistic Street Soccer | GK Side Save",
    LoadingTitle = "RSS GK Side Save",
    LoadingSubtitle = "Rayfield UI",
    ConfigurationSaving = {Enabled=false},
    KeySystem = false
})

local tabGK = Window:CreateTab("Goalkeeper Side Save")
tabGK:CreateSection("Q/E чтобы прыгнуть вбок и отбить мяч")
tabGK:CreateToggle({
    Name = "Вкл. сайд-сэйвы (Q/E)",
    CurrentValue = false,
    Callback = function(val)
        GK_ACTIVE = val
    end
})
tabGK:CreateParagraph({
    Title = "Как пользоваться:",
    Content = "1. Встань на позицию ворот.\n2. Наведи камеру на поле.\n3. Жми Q — прыжок влево; E — вправо (по отношению к воротам)\n4. Персонаж оттолкнётся вбок, чтобы отбить мяч телом."
})
tabGK:CreateSlider({
    Name = "Длина прыжка",
    Range = {3, 12},
    Increment = 0.5,
    CurrentValue = diveDistance,
    Callback = function(val) diveDistance = val end
})
tabGK:CreateSlider({
    Name = "Скорость прыжка (меньше — быстрее)",
    Range = {0.14, 0.4},
    Increment = 0.01,
    CurrentValue = diveSpeed,
    Callback = function(val) diveSpeed = val end
})

Rayfield:Notify({
    Title="GK Side Save",
    Content="Вкл. сайд-сэйвы в Rayfield, теперь Q или E = отбить мяч влево/вправо!",
    Duration=7
})

-- Управление (Q/E)
local UIS = game:GetService("UserInputService")
UIS.InputBegan:Connect(function(input, gp)
    if not GK_ACTIVE or gp then return end
    if input.KeyCode == Enum.KeyCode.Q then
        dive("L")
    elseif input.KeyCode == Enum.KeyCode.E then
        dive("R")
    end
end)