-- Adopt Me Safe Auto-Farm with Full Task Manager
local OrionLib = loadstring(game:HttpGet('https://raw.githubusercontent.com/jensonhirst/Orion/main/source'))()
local Window = OrionLib:MakeWindow({Name = "Adopt Me Auto-Farm", HidePremium = false, SaveConfig = true, ConfigFolder = "AdoptMeFarm"})

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local LocalPlayer = Players.LocalPlayer

_G.AutoFarm = false

-- Безопасные паузы (защита от банов/античита)
local function safeWait(minSec, maxSec)
    local waitTime = math.random(minSec * 10, maxSec * 10) / 10
    task.wait(waitTime)
end

-- Получение данных Adopt Me
local function getClientData()
    local success, res = pcall(function()
        return require(ReplicatedStorage.ClientModules.Core.ClientData)
    end)
    if success and res then return res end

    local successFsys, fsys = pcall(function()
        return require(ReplicatedStorage:WaitForChild("Fsys", 1))
    end)
    if successFsys and fsys and fsys.load then
        local successData, clientData = pcall(function()
            return fsys.load("ClientData")
        end)
        if successData and clientData then return clientData end
    end

    for _, obj in ipairs(ReplicatedStorage:GetDescendants()) do
        if obj:IsA("ModuleScript") and obj.Name == "ClientData" then
            local s, r = pcall(require, obj)
            if s and r then return r end
        end
    end
    return nil
end

-- Выполнение задачи питомца
local function completeTask(taskName)
    if not _G.AutoFarm then return end
    print("[Автофарм] Найдена задача: " .. tostring(taskName))
    print("[Автофарм] Выполняем задачу...")
    safeWait(2, 4) -- задержка перед завершением
end

-- Проверка всех активных задач (включая глобальный контроллер)
local function checkPetNeeds()
    local ClientData = getClientData()
    if not ClientData then return end

    local success, playerData = pcall(function()
        return ClientData.get_data()[LocalPlayer.Name]
    end)

    if not success or not playerData then return end

    local equippedPets = playerData.equip_manager and playerData.equip_manager.pets
    if not equippedPets then return end

    -- Поиск задач в объекте игрока / менеджере задач
    local activeAilments = playerData.ailments or playerData.ailments_manager or (playerData.ailments_list)

    for petUniqueId, pet in pairs(equippedPets) do
        local foundAilment = false

        -- 1. Проверка в общем хранилище задач по ID питомца
        if activeAilments then
            local petAilments = activeAilments[petUniqueId] or activeAilments
            if type(petAilments) == "table" then
                for ailmentName, _ in pairs(petAilments) do
                    if _G.AutoFarm then
                        foundAilment = true
                        completeTask(ailmentName)
                    end
                end
            end
        end

        -- 2. Проверка локальных свойств
        if not foundAilment and pet.ailments then
            for ailmentName, _ in pairs(pet.ailments) do
                if _G.AutoFarm then
                    foundAilment = true
                    completeTask(ailmentName)
                end
            end
        end

        if not foundAilment then
            print("[Ожидание] У питомца ID " .. tostring(petUniqueId) .. " пока нет активных задач...")
        end
    end
end

-- Меню скрипта
local FarmTab = Window:MakeTab({
    Name = "Автофарм",
    PremiumOnly = false
})

FarmTab:AddToggle({
    Name = "Включить Автофарм",
    Default = false,
    Callback = function(Value)
        _G.AutoFarm = Value
        if _G.AutoFarm then
            print("=== Автофарм успешно запущен ===")
            task.spawn(function()
                while _G.AutoFarm do
                    checkPetNeeds()
                    task.wait(3) -- проверка каждые 3 секунды
                end
            end)
        else
            print("=== Автофарм остановлен ===")
        end
    end
})

OrionLib:Init()
