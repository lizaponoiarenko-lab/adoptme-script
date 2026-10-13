-- Adopt Me Full Auto-Farm with Remote Completion
local OrionLib = loadstring(game:HttpGet('https://raw.githubusercontent.com/jensonhirst/Orion/main/source'))()
local Window = OrionLib:MakeWindow({Name = "Adopt Me Auto-Farm", HidePremium = false, SaveConfig = true, ConfigFolder = "AdoptMeFarm"})

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local LocalPlayer = Players.LocalPlayer

_G.AutoFarm = false

-- Безопасная пауза
local function safeWait(minSec, maxSec)
    local waitTime = math.random(minSec * 10, maxSec * 10) / 10
    task.wait(waitTime)
end

-- Получение модуля ClientData
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

-- Отправка события завершения задачи на сервер
local function fireTaskCompletion(ailmentName, petUniqueId)
    local API = ReplicatedStorage:FindFirstChild("API") or ReplicatedStorage:FindFirstChild(" me", true)
    
    print("[Действие] Пытаемся выполнить задачу: " .. tostring(ailmentName))
    
    -- Безопасное выполнение задачи через универсальные ремоуты Adopt Me
    pcall(function()
        if ReplicatedStorage:FindFirstChild("API") then
            ReplicatedStorage.API["AilmentsServices/AilmentCompleted"]:FireServer(ailmentName, {
                ["pet_unique"] = petUniqueId
            })
        end
    end)
end

-- Проверка потребностей
local function checkPetNeeds()
    local ClientData = getClientData()
    if not ClientData then 
        print("[Ошибка] ClientData недоступен")
        return 
    end

    local success, playerData = pcall(function()
        return ClientData.get_data()[LocalPlayer.Name]
    end)

    if not success or not playerData then 
        print("[Ошибка] Не удалось прочитать playerData")
        return 
    end

    local equippedPets = playerData.equip_manager and playerData.equip_manager.pets
    if not equippedPets then return end

    local activeAilments = playerData.ailments or playerData.ailments_manager

    for petUniqueId, pet in pairs(equippedPets) do
        local foundTask = false

        -- Проверка задач в глобальной таблице
        if activeAilments and activeAilments[petUniqueId] then
            for ailmentName, _ in pairs(activeAilments[petUniqueId]) do
                if _G.AutoFarm then
                    foundTask = true
                    print(">>> НАЙДЕНА ЗАДАЧА ПИТОМЦА:", tostring(ailmentName))
                    safeWait(1.5, 3)
                    fireTaskCompletion(ailmentName, petUniqueId)
                end
            end
        end

        -- Проверка задач внутри самого объекта питомца
        if not foundTask and pet.ailments then
            for ailmentName, _ in pairs(pet.ailments) do
                if _G.AutoFarm then
                    foundTask = true
                    print(">>> НАЙДЕНА ЗАДАЧА В ПИТОМЦЕ:", tostring(ailmentName))
                    safeWait(1.5, 3)
                    fireTaskCompletion(ailmentName, petUniqueId)
                end
            end
        end

        if not foundTask then
            print("[Поиск] Сканируем задачи для питомца ID " .. tostring(petUniqueId) .. "...")
        end
    end
end

-- Вкладка меню
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
            print("=== Автофарм с авто-завершением запущен ===")
            task.spawn(function()
                while _G.AutoFarm do
                    checkPetNeeds()
                    task.wait(3)
                end
            end)
        else
            print("=== Автофарм остановлен ===")
        end
    end
})

OrionLib:Init()
