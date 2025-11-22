-- Realistic Street Soccer: Авто-сэйв для вратаря — клиент сам прыгает в ту сторону, куда летит мяч (Rayfield UI)
-- by kauuuvuv-coder

local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()
local plr = game.Players.LocalPlayer
local GK_ACTIVE = false
local diveDistance = 6           -- длина прыжка в сторону (можно изменить)
local diveSpeed = 0.22           -- скорость движения (чем меньше — быстрее прыжок)
local lastDive = 0
local saveCooldown = 0.6         -- сек, задержка между автосэйвами
local saveRadius = 24            -- Как близко мяч к воротам чтобы сейвить

-- Координаты ворот (примерно, для оптимального сейва! Настроить под свои ворота при необходимости)
local function getGoalPosition()
    -- Попробуем найти ворота по близости к персонажу (или задай вручную):
    local char = plr.Character
    if not char or not char:FindFirstChild("HumanoidRootPart") then return nil end
    local hrp = char.HumanoidRootPart
    local minGoal, minDist = nil, math.huge
    for _,obj in ipairs(workspace:GetDescendants()) do
        if obj:IsA("BasePart") and (obj.Name:lower():find("goal") or obj.Name:lower():find("gate")) then
            local dist = (obj.Position - hrp.Position).Magnitude
            if dist < minDist then minGoal, minDist = obj, dist end
        end
    end
    return minGoal and minGoal.Position or (hrp.Position + Vector3.new(0,0,-15)) -- fallback чуть вперед
end

local function getClosestBallToGoal()
    local goalPos = getGoalPosition() if not goalPos then return nil end
    local nearest, dist = nil, math.huge
    for _,ball in ipairs(workspace:GetDescendants()) do
        if ball:IsA("BasePart") and ball.Name:lower():find("ball") then
            local d = (ball.Position - goalPos).Magnitude
            if d < dist then nearest, dist = ball, d end
        end
    end
    return nearest, dist
end

local function getSideToDive(hrp, goalPos, ball)
    -- Определим где мяч относительно ворот и персонажа
    local g2b = ball.Position - goalPos
    local g2p = hrp.Position - goalPos
    local dot = g2b:Dot(g2p) -- >0 если с одной стороны, <0 если с противоположной (для простого ворот контрола)
    -- Если мяч ближе к боковой линии относительно ворот — прыгаем в ту сторону; если по центру — не двигаемся
    local rel = (ball.Position - hrp.Position)
    local right = (hrp.CFrame.RightVector)
    local side = rel:Dot(right)
    if math.abs(side) < 2 then return "C" end
    return side > 0 and "R" or "L"
end

local function auto_dive()
    if not GK_ACTIVE then return end
    local char = plr.Character
    if not char or not char:FindFirstChild("HumanoidRootPart") then return end
    local hrp = char.HumanoidRootPart
    local ball, dist = getClosestBallToGoal()
    local goalPos = getGoalPosition()
    if not ball or not goalPos then return end
    if dist > saveRadius then return end

    if tick()-lastDive < saveCooldown then return end

    -- анализируем, летит ли мяч к воротам (мяч движется в сторону ворот быстро)
    local v = (ball.AssemblyLinearVelocity or ball.Velocity)
    if v.Magnitude < 4 then return end -- слишком медленно
    local toGoal = (goalPos - ball.Position).Unit
    if v:Dot(toGoal) < 1.5 then return end -- не в сторону ворот

    -- Решаем сторону прыжка
    local diveSide = getSideToDive(hrp, goalPos, ball)
    local dirVec
    if diveSide == "C" then
        dirVec = (goalPos - hrp.Position).Unit    -- прыжок прямо вперёд
    else
        dirVec = hrp.CFrame.RightVector
        if diveSide == "L" then dirVec = -dirVec end
    end
    local targetPos = hrp.Position + dirVec*diveDistance

    lastDive = tick()

    -- Мягко двигаем персонажа в сторону рывка
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
    Name = "Realistic Street Soccer | GK Auto Save",
    LoadingTitle = "RSS GK Auto",
    LoadingSubtitle = "Авто-дайв",
    ConfigurationSaving = {Enabled=false},
    KeySystem = false
})

local tabGK = Window:CreateTab("GK Auto Save")
tabGK:CreateSection("Вратарь автоматически прыгает и отбивает мячи!")
tabGK:CreateToggle({
    Name = "Включить авто-сэйв (клиент прыгает сам!)",
    CurrentValue = false,
    Callback = function(val) GK_ACTIVE = val end
})
tabGK:CreateSlider({
    Name = "Длина прыжка",
    Range = {2, 12},
    Increment = 0.5,
    CurrentValue = diveDistance,
    Callback = function(val) diveDistance = val end
})
tabGK:CreateSlider({
    Name = "Скорость прыжка (меньше — быстрее)",
    Range = {0.10, 0.4},
    Increment = 0.01,
    CurrentValue = diveSpeed,
    Callback = function(val) diveSpeed = val end
})
tabGK:CreateSlider({
    Name = "Чувствительность (радиус)",
    Range = {8, 40},
    Increment = 1,
    CurrentValue = saveRadius,
    Callback = function(val) saveRadius = val end
})
tabGK:CreateSlider({
    Name = "Задержка между прыжками (сек)",
    Range = {0.2, 1.5},
    Increment = 0.01,
    CurrentValue = saveCooldown,
    Callback = function(val) saveCooldown = val end
})
tabGK:CreateParagraph({
    Title = "Инструкция:",
    Content = "Вратарь будет двигаться в нужную сторону и делать автосэйв, когда мяч летит в ворота рядом! Настройте чувствительность, чтобы ловить только опасные удары."
})

Rayfield:Notify({
    Title="GK Auto Save",
    Content="Вратарь сам прыгает в нужную сторону и отбивает мячи, если мяч летит в ворота!",
    Duration=8
})

-- Главный цикл
task.spawn(function()
    while true do
        pcall(auto_dive)
        task.wait(0.05)
    end
end)