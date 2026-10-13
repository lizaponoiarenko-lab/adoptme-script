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
    if not ClientData then return end

    local success, playerData = pcall(function()
        return ClientData.get_data()[LocalPlayer.Name]
    end)

    if not success or not playerData then return end

    local equippedPets = playerData.equip_manager and playerData.equip_manager.pets
    if not equippedPets then return end

    for _, pet in pairs(equippedPets) do
        -- Универсальный поиск задач по разным возможным ключам
        local ailments = nil
        if pet.properties then
            ailments = pet.properties.ailments or pet.properties.tasks or pet.properties.needs
        end
        if not ailments and pet.ailments then
            ailments = pet.ailments
        end

        if ailments then
            for ailmentName, ailmentData in pairs(ailments) do
                if _G.AutoFarm then
                    print(">>> НАЙДЕНА ЗАДАЧА:", tostring(ailmentName))
                    -- Здесь в будущем будет вызов выполнения задачи
                    safeWait(1.5, 3)
                end
            end
        else
            -- Выведем ключи свойств для отладки, если задач всё еще не видно
            if pet.properties then
                local keys = {}
                for k, _ in pairs(pet.properties) do table.insert(keys, k) end
                print("[Debug] Доступные ключи в properties:", table.concat(keys, ", "))
            end
        end
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
                    task.wait(2)
                end
            end)
        else
            print("=== Автофарм остановлен ===")
        end
    end
})

OrionLib:Init()
