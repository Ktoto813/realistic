-- Realistic Street Soccer Goalkeeper: Autocatch All Balls [Rayfield]
local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()
local plr = game.Players.LocalPlayer
local GK_ACTIVE = false

-- Определение функции автовратаря
local function allGoalkeeper()
    if not (plr.Character and plr.Character:FindFirstChild("HumanoidRootPart")) then return end
    local hrp = plr.Character.HumanoidRootPart

    for _,ball in ipairs(workspace:GetDescendants()) do
        if ball:IsA("BasePart") and ball.Name:lower():find("ball") then
            -- Расстояние до мяча < 35
            local vec = ball.Position - hrp.Position
            if vec.Magnitude < 33 then
                -- Можно изменить на ball.CFrame = hrp.CFrame; Но лучше "лови" мяч командой
                if ball:FindFirstChild("TouchInterest") then
                    firetouchinterest(hrp, ball, 0)
                    task.wait(0.03)
                    firetouchinterest(hrp, ball, 1)
                else
                    ball.Position = hrp.Position + Vector3.new(0,3,0)
                end
            end
        end
    end
end

-- UI - Rayfield
local Window = Rayfield:CreateWindow({
    Name = "Realistic Street Soccer | Goalkeeper Tools",
    LoadingTitle = "RSS Tools",
    LoadingSubtitle = "Rayfield UI Autocatch",
    ConfigurationSaving = {Enabled=false},
    KeySystem = false
})

local tabGK = Window:CreateTab("Goalkeeper")
tabGK:CreateSection("Авто-ловля всех мячей для вратаря!")
tabGK:CreateToggle({
    Name = "Auto Catch ALL Balls (GK)",
    CurrentValue = false,
    Callback = function(val)
        GK_ACTIVE = val
    end
})

Rayfield:Notify({
    Title="Goalkeeper Tools",
    Content="Функция будет ловить ВСЕ мячи поблизости, если стоишь на воротах!",
    Duration=6
})

-- Главный цикл
task.spawn(function()
    while true do
        if GK_ACTIVE then
            pcall(allGoalkeeper)
        end
        task.wait(0.08)
    end
end)