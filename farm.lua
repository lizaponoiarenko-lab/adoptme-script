-- Adopt Me Safe Auto-Farm with GUI
local OrionLib = loadstring(game:HttpGet('https://raw.githubusercontent.com/jensonhirst/Orion/main/source'))()
local Window = OrionLib:MakeWindow({Name = "Adopt Me Auto-Farm", HidePremium = false, SaveConfig = true, ConfigFolder = "AdoptMeFarm"})

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local LocalPlayer = Players.LocalPlayer

_G.AutoFarm = false

local function safeWait(minSec, maxSec)
    local waitTime = math.random(minSec * 10, maxSec * 10) / 10
    task.wait(waitTime)
end

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

local function checkPetNeeds()
    local ClientData = getClientData()
    if not ClientData then
        print("[Debug] ClientData не найден")
        return
    end

    local success, playerData = pcall(function()
        return ClientData.get_data()[LocalPlayer.Name]
    end)

    if not success or not playerData then
        print("[Debug] Не удалось получить playerData игрока")
        return
    end

    -- Проверяем экипированных питомцев
    local equippedPets = playerData.equip_manager and playerData.equip_manager.pets
    if not equippedPets then
        print("[Debug] Нет экипированных питомцев!")
        return
    end

    local foundAnyPet = false
    for petUniqueId, pet in pairs(equippedPets) do
        foundAnyPet = true
        print("[Debug] Найден экипированный питомец/яйцо ID:", petUniqueId)
        
        local ailments = pet.properties and pet.properties.ailments
        if ailments then
            local count = 0
            for ailmentName, _ in pairs(ailments) do
                count = count + 1
                if _G.AutoFarm then
                    print(">>> НАЙДЕНА ЗАДАЧА:", tostring(ailmentName))
                    safeWait(1.5, 3)
                end
            end
            if count == 0 then
                print("[Debug] У питомца сейчас нет активных задач (ailments пуст)")
            end
        else
            print("[Debug] Свойство ailments у питомца отсутствует")
        end
    end

    if not foundAnyPet then
        print("[Debug] Питомцы не достаны из инвентаря!")
    end
end

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
            print("=== Автофарм запущен ===")
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
