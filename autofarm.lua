-- Adopt Me Direct Ailments Farm v4
local OrionLib = loadstring(game:HttpGet('https://raw.githubusercontent.com/jensonhirst/Orion/main/source'))()
local Window = OrionLib:MakeWindow({Name = "Adopt Me Auto-Farm", HidePremium = false, SaveConfig = false})

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local LocalPlayer = Players.LocalPlayer

_G.AutoFarm = true

local function safeWait(minSec, maxSec)
    local waitTime = math.random(minSec * 10, maxSec * 10) / 10
    task.wait(waitTime)
end

-- Прямой вызов завершения потребности через Remotes
local function resolveAilment(ailmentName, petId)
    print(">>> ВЫПОЛНЯЕМ ЗАДАЧУ:", tostring(ailmentName), "| Pet ID:", tostring(petId))
    
    pcall(function()
        local api = ReplicatedStorage:FindFirstChild("API")
        if api then
            if api:FindFirstChild("AilmentsServices/AilmentCompleted") then
                api["AilmentsServices/AilmentCompleted"]:FireServer(ailmentName, {["pet_unique"] = petId})
            end
            if api:FindFirstChild("AilmentsServices/ResolveAilment") then
                api["AilmentsServices/ResolveAilment"]:FireServer(petId, ailmentName)
            end
        end
    end)
end

-- Поиск активных задач напрямую
local function processAutoFarm()
    -- Получаем данные через ClientData
    local clientData = nil
    pcall(function()
        for _, v in ipairs(ReplicatedStorage:GetDescendants()) do
            if v:IsA("ModuleScript") and v.Name == "ClientData" then
                clientData = require(v)
                break
            end
        end
    end)

    if not clientData or not clientData.get_data then
        print("[!] Ожидаем подгрузку ClientData...")
        return
    end

    local myData = nil
    pcall(function() myData = clientData.get_data()[LocalPlayer.Name] end)

    if not myData then
        print("[!] Не удалось прочитать данные игрока")
        return
    end

    -- 1. Способ: сканируем глобальный список ailments
    local ailments = myData.ailments
    if ailments and type(ailments) == "table" then
        for petUnique, taskList in pairs(ailments) do
            if type(taskList) == "table" then
                for taskName, _ in pairs(taskList) do
                    if _G.AutoFarm then
                        print(">>> ОБНАРУЖЕНА ЗАДАЧА В AILMENTS:", tostring(taskName))
                        safeWait(1.5, 3)
                        resolveAilment(taskName, petUnique)
                    end
                end
            end
        end
    end

    -- 2. Способ: если задачи лежат прямо под ключами инвентаря
    local inventory = myData.inventory and myData.inventory.pets
    if inventory and type(inventory) == "table" then
        for petUnique, petData in pairs(inventory) do
            if petData.properties and petData.properties.equipped then
                print("[Инфо] Экипирован питомец ID:", tostring(petUnique))
            end
        end
    end
end

-- Основной постоянный цикл
task.spawn(function()
    print("=== АВТОФАРМ v4 ЗАПУЩЕН ===")
    while true do
        if _G.AutoFarm then
            pcall(processAutoFarm)
        end
        task.wait(3)
    end
end)

-- Интерфейс Orion
local FarmTab = Window:MakeTab({Name = "Фарм", PremiumOnly = false})

FarmTab:AddToggle({
    Name = "Запустить Автофарм",
    Default = true,
    Callback = function(Value)
        _G.AutoFarm = Value
        if _G.AutoFarm then
            print("=== Автофарм включен ===")
        else
            print("=== Автофарм выключен ===")
        end
    end
})

OrionLib:Init()
