-- Realistic Street Soccer: Бот-вратарь (автоматический сейв) [Rayfield UI]
-- by kauuuvuv-coder

local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()
local plr = game.Players.LocalPlayer
local GK_ACTIVE = false
local diveDistance = 6           -- Длина прыжка в сторону
local diveSpeed = 0.21           -- Скорость (меньше — быстрее)
local saveRadius = 22            -- Радиус реакции на мяч
local saveCooldown = 0.7         -- Задержка между автосэйвами
local lastDive = 0

-- Получение координат ворот (ищем ближайший объект с "goal" или "gate" в имени)
local function getGoalPosition()
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
    return minGoal and minGoal.Position or (hrp.Position + Vector3.new(0,0,-13))
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
    local right = hrp.CFrame.RightVector
    local rel = (ball.Position - hrp.Position)
    local side = rel:Dot(right)
    if math.abs(side) < 2 then return "C" end
    return side > 0 and "R" or "L"
end

local function auto_goalkeeper()
    if not GK_ACTIVE then return end
    local char = plr.Character
    if not char or not char:FindFirstChild("HumanoidRootPart") then return end
    local hrp = char.HumanoidRootPart
    local ball, dist = getClosestBallToGoal()
    local goalPos = getGoalPosition()
    if not ball or not goalPos then return end
    if dist > saveRadius then return end
    if tick()-lastDive < saveCooldown then return end

    -- Проверим летит ли мяч на ворота
    local v = (ball.AssemblyLinearVelocity or ball.Velocity)
    if v.Magnitude < 4 then return end
    local toGoal = (goalPos - ball.Position).Unit
    if v:Dot(toGoal) < 1.3 then return end

    -- Выбираем сторону прыжка
    local diveSide = getSideToDive(hrp, goalPos, ball)
    local dirVec
    if diveSide == "C" then
        dirVec = (goalPos - hrp.Position).Unit
    else
        dirVec = hrp.CFrame.RightVector
        if diveSide == "L" then dirVec = -dirVec end
    end
    local targetPos = hrp.Position + dirVec*diveDistance
    lastDive = tick()

    -- Прыжок в сторону (мягко, чтобы не кикнуло)
    local N = 10
    for i=1,N do
        local t = i/N
        hrp.CFrame = hrp.CFrame:Lerp(CFrame.new(targetPos.X, hrp.Position.Y, targetPos.Z), t)
        hrp.Velocity = Vector3.new(0,0,0)
        task.wait(diveSpeed/N)
    end
end

-- Rayfield UI
local Window = Rayfield:CreateWindow({
    Name = "Realistic Street Soccer | GK Bot",
    LoadingTitle = "GK Bot",
    LoadingSubtitle = "Авто-сэйвит ворота",
    ConfigurationSaving = {Enabled=false},
    KeySystem = false
})

local tabGK = Window:CreateTab("Вратарь БОТ")
tabGK:CreateSection("Полный автомат: Прыгай и сейвь ворота как PRO!")
tabGK:CreateToggle({
    Name = "Включить вратаря-бота (Авто-сэйв)",
    CurrentValue = false,
    Callback = function(val) GK_ACTIVE = val end
})
tabGK:CreateSlider({
    Name = "Длина прыжка",
    Range = {3, 14},
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
    Name = "Чувствительность (радиус сэйва)",
    Range = {8, 42},
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
    Content = "Когда бот включён, он сам прыгает и отбивает мячи, летящие в ворота!\nМеняй длину/скорость, если надо ловить крутые удары."
})

Rayfield:Notify({
    Title="GK Bot",
    Content="Вратарь-бот сам прыгает и сейвит ворота при угрозе!",
    Duration=7
})

-- Главный цикл
task.spawn(function()
    while true do
        pcall(auto_goalkeeper)
        task.wait(0.045)
    end
end)