-- Adopt Me Working Auto-Farm (Fixed Fsys)
local OrionLib = loadstring(game:HttpGet('https://raw.githubusercontent.com/jensonhirst/Orion/main/source'))()
local Window = OrionLib:MakeWindow({Name = "Adopt Me Auto-Farm", HidePremium = false, SaveConfig = false})

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local LocalPlayer = Players.LocalPlayer

_G.AutoFarm = false

local function safeWait(minSec, maxSec)
    local waitTime = math.random(minSec * 10, maxSec * 10) / 10
    task.wait(waitTime)
end

-- Безопасный поиск ClientData без вызова ошибок в Fsys
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

local function fireTask(ailmentName, petUniqueId)
    print(">>> ЗАКРЫВАЕМ ЗАДАЧУ:", tostring(ailmentName))
    
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
    local clientData = getClientData()
    if not clientData then 
        print("[Ошибка] ClientData не найден")
        return 
    end

    local playerData = nil
    pcall(function() playerData = clientData.get_data()[LocalPlayer.Name] end)
    if not playerData or not playerData.equip_manager or not playerData.equip_manager.pets then return end

    for petUniqueId, _ in pairs(playerData.equip_manager.pets) do
        local ailmentsList = {}

        -- Поиск задач в playerData.ailments
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
                    print(">>> НАЙДЕНА АКТИВНАЯ ЗАДАЧА:", taskName)
                    safeWait(1.5, 3)
                    fireTask(taskName, petUniqueId)
                end
            end
        else
            print("[OK] Сканирование без ошибок... Ожидаем задачи.")
        end
    end
end

local FarmTab = Window:MakeTab({Name = "Фарм", PremiumOnly = false})

FarmTab:AddToggle({
    Name = "Запустить Автофарм",
    Default = false,
    Callback = function(Value)
        _G.AutoFarm = Value
        if _G.AutoFarm then
            print("=== ИСПРАВЛЕННЫЙ АВТОФАРМ ЗАПУЩЕН ===")
            task.spawn(function()
                while _G.AutoFarm do
                    scanAndComplete()
                    task.wait(2.5)
                end
            end)
        else
            print("=== Остановлено ===")
        end
    end
})

OrionLib:Init()
