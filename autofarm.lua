-- Adopt Me Working Auto-Farm (Auto-Start & Direct Resolve)
local OrionLib = loadstring(game:HttpGet('https://raw.githubusercontent.com/jensonhirst/Orion/main/source'))()
local Window = OrionLib:MakeWindow({Name = "Adopt Me Auto-Farm", HidePremium = false, SaveConfig = false})

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local LocalPlayer = Players.LocalPlayer

_G.AutoFarm = true -- Включаем сразу при запуске!

local function safeWait(minSec, maxSec)
    local waitTime = math.random(minSec * 10, maxSec * 10) / 10
    task.wait(waitTime)
end

-- Безопасное получение ClientData
local function getClientData()
    local success, res = pcall(function()
        return require(ReplicatedStorage.ClientModules.Core.ClientData)
    end)
    if success and res then return res end

    for _, obj in ipairs(ReplicatedStorage:GetDescendants()) do
        if obj:IsA("ModuleScript") and obj.Name == "ClientData" then
            local s, r = pcall(require, obj)
            if s and r then return r end
        end
    end
    return nil
end

-- Закрытие задачи напрямую через сетевые события и внутренние функции
local function fireTask(ailmentName, petUniqueId)
    print(">>> ПЫТАЕМСЯ ЗАКРЫТЬ ЗАДАЧУ:", tostring(ailmentName))
    
    -- Вызов 1: Через AilmentsClient (если доступен через ClientModules)
    pcall(function()
        local ailmentsMod = require(ReplicatedStorage.ClientModules.Core.ClientData)
        if ailmentsMod and ailmentsMod.get_data then
            local data = ailmentsMod.get_data()[LocalPlayer.Name]
            if data and data.ailments then
                data.ailments[petUniqueId] = nil -- Локальный сброс для интерфейса
            end
        end
    end)

    -- Вызов 2: Через RemoteEvent в API
    pcall(function()
        local api = ReplicatedStorage:FindFirstChild("API")
        if api then
            if api:FindFirstChild("AilmentsServices/AilmentCompleted") then
                api["AilmentsServices/AilmentCompleted"]:FireServer(ailmentName, {["pet_unique"] = petUniqueId})
            end
            if api:FindFirstChild("AilmentsServices/ResolveAilment") then
                api["AilmentsServices/ResolveAilment"]:FireServer(petUniqueId, ailmentName)
            end
        end
    end)
end

local function scanAndComplete()
    local clientData = getClientData()
    if not clientData then 
        print("[!] Ожидание загрузки ClientData...")
        return 
    end

    local playerData = nil
    pcall(function() playerData = clientData.get_data()[LocalPlayer.Name] end)
    if not playerData or not playerData.equip_manager or not playerData.equip_manager.pets then 
        print("[!] Нет экипированного питомца...")
        return 
    end

    for petUniqueId, _ in pairs(playerData.equip_manager.pets) do
        local ailmentsList = {}

        -- Сканирование через playerData.ailments
        if playerData.ailments then
            local pAilments = playerData.ailments[petUniqueId] or playerData.ailments
            if type(pAilments) == "table" then
                for aName, _ in pairs(pAilments) do
                    table.insert(ailmentsList, tostring(aName))
                end
            end
        end

        if #ailmentsList > 0 then
            for _, taskName in ipairs(ailmentsList) do
                if _G.AutoFarm then
                    print(">>> НАЙДЕНА ЗАДАЧА:", taskName)
                    safeWait(1.5, 3)
                    fireTask(taskName, petUniqueId)
                end
            end
        else
            print("[АВТОФАРМ] Активных задач пока нет. Сканируем...")
        end
    end
end

-- Автоматический запуск цикла фарма
task.spawn(function()
    print("=== АВТОФАРМ УСПЕШНО ЗАПУЩЕН ===")
    while true do
        if _G.AutoFarm then
            scanAndComplete()
        end
        task.wait(3)
    end
end)

-- Интерфейс управления
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
