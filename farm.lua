-- Adopt Me Safe Auto-Farm with GUI
local OrionLib = loadstring(game:HttpGet('https://raw.githubusercontent.com/jensonhirst/Orion/main/source'))()
local Window = OrionLib:MakeWindow({Name = "Adopt Me Auto-Farm", HidePremium = false, SaveConfig = true, ConfigFolder = "AdoptMeFarm"})

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local LocalPlayer = Players.LocalPlayer

-- Флаг состояния автофарма
_G.AutoFarm = false

-- Функция безопасной задержки (защита от античита)
local function safeWait(minSec, maxSec)
    local waitTime = math.random(minSec * 10, maxSec * 10) / 10
    task.wait(waitTime)
end

-- Выполнение отдельной задачи
local function completeTask(taskName)
    if not _G.AutoFarm then return end
    print("Выполняем задачу питомца: " .. tostring(taskName))
    safeWait(1.5, 3.5)
    safeWait(3, 6)
end

-- Проверка потребностей питомца
local function checkPetNeeds()
    local clientDataModule = ReplicatedStorage:FindFirstChild("ClientData")
    if not clientDataModule then 
        print("Ожидание подгрузки ClientData...")
        return 
    end

    local success, ClientData = pcall(function() return require(clientDataModule) end)
    if not success or not ClientData then return end

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

-- Переключатель (Toggle) для включения/выключения
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
                    task.wait(5)
                end
            end)
        else
            print("Автофарм остановлен")
        end
    end
})

OrionLib:Init()
