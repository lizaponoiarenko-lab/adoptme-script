-- Adopt Me Auto-Farm v5 (Anti-Cache & Debug)
local OrionLib = loadstring(game:HttpGet('https://raw.githubusercontent.com/lizaponoiarenko-lab/adoptme-script/main/autofarm.lua?v=9999'))()
local Window = OrionLib:MakeWindow({Name = "Adopt Me Auto-Farm v5", HidePremium = false, SaveConfig = false})

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local LocalPlayer = Players.LocalPlayer

_G.AutoFarm = true

print("=== АВТОФАРМ v5 УСПЕШНО СТАРТОВАЛ ===")

-- Функция отправки запроса на выполнение задачи
local function resolveAilment(ailmentName, petId)
    print(">>> ПЫТАЕМСЯ ЗАКРЫТЬ ЗАДАЧУ:", tostring(ailmentName), "| Pet ID:", tostring(petId))
    pcall(function()
        local api = ReplicatedStorage:FindFirstChild("API")
        if api then
            if api:FindFirstChild("AilmentsServices/AilmentCompleted") then
                api["AilmentsServices/AilmentCompleted"]:FireServer(ailmentName, {["pet_unique"] = petId})
            elseif api:FindFirstChild("AilmentsServices/ResolveAilment") then
                api["AilmentsServices/ResolveAilment"]:FireServer(petId, ailmentName)
            end
        end
    end)
end

-- Сканирование задач с отладочным выводом
local function processAutoFarm()
    pcall(function()
        local clientData = nil
        for _, v in ipairs(ReplicatedStorage:GetDescendants()) do
            if v:IsA("ModuleScript") and v.Name == "ClientData" then
                local s, res = pcall(require, v)
                if s and res then
                    clientData = res
                    break
                end
            end
        end

        if not clientData or not clientData.get_data then
            print("[v5 Debug] ClientData еще не найден...")
            return
        end

        local myData = clientData.get_data()[LocalPlayer.Name]
        if not myData then
            print("[v5 Debug] Данные игрока пока не загружены...")
            return
        end

        local ailments = myData.ailments
        if ailments and type(ailments) == "table" then
            local foundAny = false
            for petUnique, taskList in pairs(ailments) do
                if type(taskList) == "table" then
                    for taskName, _ in pairs(taskList) do
                        foundAny = true
                        if _G.AutoFarm then
                            print(">>> НАЙДЕНА ЗАДАЧА:", tostring(taskName), "у питомца ID:", tostring(petUnique))
                            task.wait(1)
                            resolveAilment(taskName, petUnique)
                        end
                    end
                end
            end
            if not foundAny then
                print("[v5] Таблица ailments пуста — ждем задачу у питомца...")
            end
        else
            print("[v5] Ключ ailments у игрока отсутствует.")
        end
    end)
end

-- Цикл выполнения
task.spawn(function()
    while true do
        if _G.AutoFarm then
            processAutoFarm()
        end
        task.wait(3)
    end
end)

-- Интерфейс
local FarmTab = Window:MakeTab({Name = "Фарм", PremiumOnly = false})
FarmTab:AddToggle({
    Name = "Запустить Автофарм",
    Default = true,
    Callback = function(Value)
        _G.AutoFarm = Value
        print("Статус автофарма изменен:", Value)
    end
})

OrionLib:Init()
