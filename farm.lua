-- Adopt Me Advanced Auto-Farm with Client Ailments Hook
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

-- Улучшенная функция выполнения задачи через игровые модули
local function fireTaskCompletion(ailmentName, petUniqueId)
    print("[Действие] Выполняем задачу: " .. tostring(ailmentName))
    
    pcall(function()
        -- Способ 1: Через Fsys загрузчик модулей задач
        local fsys = require(ReplicatedStorage.Fsys)
        local ailmentsClient = fsys.load("AilmentsClient")
        if ailmentsClient and ailmentsClient.resolve_ailment then
            ailmentsClient.resolve_ailment(petUniqueId, ailmentName)
            return
        end
    end)

    pcall(function()
        -- Способ 2: Прямой вызов через RemoteEvent в API
        local events = ReplicatedStorage:FindFirstChild("API")
        if events and events:FindFirstChild("AilmentsServices/ResolveAilment") then
            events["AilmentsServices/ResolveAilment"]:FireServer(petUniqueId, ailmentName)
        elseif events and events:FindFirstChild("AilmentsServices/AilmentCompleted") then
            events["AilmentsServices/AilmentCompleted"]:FireServer(ailmentName, {["pet_unique"] = petUniqueId})
        end
    end)
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

    local activeAilments = playerData.ailments or playerData.ailments_manager

    for petUniqueId, pet in pairs(equippedPets) do
        local foundTask = false

        if activeAilments and activeAilments[petUniqueId] then
            for ailmentName, _ in pairs(activeAilments[petUniqueId]) do
                if _G.AutoFarm then
                    foundTask = true
                    print(">>> НАЙДЕНА ЗАДАЧА:", tostring(ailmentName))
                    safeWait(1, 2)
                    fireTaskCompletion(ailmentName, petUniqueId)
                end
            end
        end

        if not foundTask and pet.ailments then
            for ailmentName, _ in pairs(pet.ailments) do
                if _G.AutoFarm then
                    foundTask = true
                    print(">>> НАЙДЕНА ЗАДАЧА В ПИТОМЦЕ:", tostring(ailmentName))
                    safeWait(1, 2)
                    fireTaskCompletion(ailmentName, petUniqueId)
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
