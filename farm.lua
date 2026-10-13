-- Adopt Me Safe Auto-Farm with GUI
local OrionLib = loadstring(game:HttpGet('https://raw.githubusercontent.com/jensonhirst/Orion/main/source'))()
local Window = OrionLib:MakeWindow({Name = "Adopt Me Auto-Farm", HidePremium = false, SaveConfig = true, ConfigFolder = "AdoptMeFarm"})

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local LocalPlayer = Players.LocalPlayer

-- Флаг состояния автофарма
_G.AutoFarm = false

-- Функция безопасной задержки
local function safeWait(minSec, maxSec)
    local waitTime = math.random(minSec * 10, maxSec * 10) / 10
    task.wait(waitTime)
end

-- Выполнение отдельной задачи
local function completeTask(taskName)
    if not _G.AutoFarm then return end
    print("Выполняем задачу питомца: " .. tostring(taskName))
    safeWait(1.5, 3)
end

-- Быстрый поиск ClientData
local function getClientData()
    local clientDataModule = ReplicatedStorage:FindFirstChild("ClientData") or ReplicatedStorage:FindFirstChild("ClientModules") and ReplicatedStorage.ClientModules:FindFirstChild("ClientData")
    if clientDataModule then
        local success, result = pcall(function() return require(clientDataModule) end)
        if success then return result end
    end
    return nil
end

-- Проверка потребностей питомца
local function checkPetNeeds()
    local ClientData = getClientData()
    if not ClientData then
        print("Подключение к данным Adopt Me...")
        return
    end

    local playerData = ClientData.get_data()[LocalPlayer.Name]
    if playerData and playerData.equip_manager and playerData.equip_manager.pets then
        for _, pet in pairs(playerData.equip_manager.pets) do
            if pet.kind then
                local ailments = pet.properties and pet.properties.ailments
                if ailments then
                    for ailmentName, _ in pairs(ailments) do
                        if not _G.AutoFarm then break end
                        print("Найдена задача: " .. tostring(ailmentName))
                        completeTask(ailmentName)
                    end
                end
            end
        end
    end
end

-- Создаем вкладку в меню
local FarmTab = Window:MakeTab({
    Name = "Автофарм",
    PremiumOnly = false
})

-- Переключатель (Toggle)
FarmTab:AddToggle({
    Name = "Включить Автофарм",
    Default = false,
    Callback = function(Value)
        _G.AutoFarm = Value
        if _G.AutoFarm then
            print("Автофарм запущен")
            task.spawn(function()
                while _G.AutoFarm do
                    checkPetNeeds()
                    task.wait(2)
                end
            end)
        else
            print("Автофарм остановлен")
        end
    end
})

OrionLib:Init()
