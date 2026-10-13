-- Adopt Me Safe Auto-Farm with Full Structure Dump
local OrionLib = loadstring(game:HttpGet('https://raw.githubusercontent.com/jensonhirst/Orion/main/source'))()
local Window = OrionLib:MakeWindow({Name = "Adopt Me Auto-Farm", HidePremium = false, SaveConfig = true, ConfigFolder = "AdoptMeFarm"})

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local LocalPlayer = Players.LocalPlayer

_G.AutoFarm = false

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

    for petUniqueId, pet in pairs(equippedPets) do
        print("=== СТРУКТУРА ПИТОМЦА ID:", tostring(petUniqueId), " ===")
        for k, v in pairs(pet) do
            print("  Ключ:", tostring(k), "| Тип:", typeof(v))
            if typeof(v) == "table" then
                for subK, subV in pairs(v) do
                    print("    -> под-ключ:", tostring(subK), "| Тип:", typeof(subV))
                end
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
            print("=== Запуск сканирования ===")
            task.spawn(function()
                while _G.AutoFarm do
                    checkPetNeeds()
                    task.wait(6) -- раз в 6 секунд выводим структуру
                end
            end)
        else
            print("=== Остановлено ===")
        end
    end
})

OrionLib:Init()
