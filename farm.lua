-- Adopt Me Auto-Farm with Direct Ailment Trigger
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

local function getFsys()
    local success, fsys = pcall(function()
        return require(ReplicatedStorage:WaitForChild("Fsys", 2))
    end)
    if success and fsys and fsys.load then
        return fsys
    end
    return nil
end

local function fireTask(ailmentName, petUniqueId)
    print("[Действие] Выполняем задачу: " .. tostring(ailmentName))
    
    local fsys = getFsys()
    if fsys then
        pcall(function()
            local ailmentsClient = fsys.load("AilmentsClient")
            if ailmentsClient then
                if ailmentsClient.resolve_ailment then
                    ailmentsClient.resolve_ailment(petUniqueId, ailmentName)
                elseif ailmentsClient.resolve then
                    ailmentsClient.resolve(petUniqueId, ailmentName)
                end
            end
        end)
    end

    pcall(function()
        local api = ReplicatedStorage:FindFirstChild("API")
        if api then
            if api:FindFirstChild("AilmentsServices/AilmentCompleted") then
                api["AilmentsServices/AilmentCompleted"]:FireServer(ailmentName, {["pet_unique"] = petUniqueId})
            elseif api:FindFirstChild("AilmentsServices/ResolveAilment") then
                api["AilmentsServices/ResolveAilment"]:FireServer(petUniqueId, ailmentName)
            end
        end
    end)
end

local function scanAndComplete()
    local fsys = getFsys()
    if not fsys then return end

    local clientData = nil
    pcall(function() clientData = fsys.load("ClientData") end)
    if not clientData then return end

    local playerData = nil
    pcall(function() playerData = clientData.get_data()[LocalPlayer.Name] end)
    if not playerData or not playerData.equip_manager or not playerData.equip_manager.pets then return end

    for petUniqueId, _ in pairs(playerData.equip_manager.pets) do
        local ailmentsList = {}

        -- Сканирование через AilmentsClient
        pcall(function()
            local ailmentsClient = fsys.load("AilmentsClient")
            if ailmentsClient then
                local active = nil
                if ailmentsClient.get_active_ailments then
                    active = ailmentsClient.get_active_ailments()
                elseif ailmentsClient.active_ailments then
                    active = ailmentsClient.active_ailments
                end

                if active then
                    for k, v in pairs(active) do
                        if type(v) == "table" then
                            local aName = v.kind or v.name or v.ailment or k
                            table.insert(ailmentsList, tostring(aName))
                        elseif type(v) == "string" then
                            table.insert(ailmentsList, v)
                        end
                    end
                end
            end
        end)

        -- Сканирование через playerData.ailments
        if #ailmentsList == 0 and playerData.ailments then
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
                    print(">>> ОБНАРУЖЕНА ЗАДАЧА:", taskName)
                    safeWait(1.5, 3)
                    fireTask(taskName, petUniqueId)
                end
            end
        else
            print("[Мониторинг v1500] Ожидание появления новых задач...")
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
            print("=== Автофарм v1500 Запущен ===")
            task.spawn(function()
                while _G.AutoFarm do
                    scanAndComplete()
                    task.wait(3)
                end
            end)
        else
            print("=== Автофарм Остановлен ===")
        end
    end
})

OrionLib:Init()
