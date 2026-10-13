-- Adopt Me Farm via AilmentsClient
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

-- Безопасная загрузка Fsys модулей
local function getFsysModule(modName)
    local success, fsys = pcall(function()
        return require(ReplicatedStorage:WaitForChild("Fsys", 2))
    end)
    if success and fsys and fsys.load then
        local s, mod = pcall(function() return fsys.load(modName) end)
        if s and mod then return mod end
    end
    return nil
end

-- Выполнение задачи
local function resolveTask(ailmentName, petUniqueId)
    print(">>> ВЫПОЛНЯЕМ ЗАДАЧУ:", tostring(ailmentName))
    
    -- Вызов разрешения потребности через контроллеры
    pcall(function()
        local ailmentsClient = getFsysModule("AilmentsClient")
        if ailmentsClient and ailmentsClient.resolve_ailment then
            ailmentsClient.resolve_ailment(petUniqueId, ailmentName)
        end
    end)

    pcall(function()
        local events = ReplicatedStorage:FindFirstChild("API")
        if events then
            if events:FindFirstChild("AilmentsServices/ResolveAilment") then
                events["AilmentsServices/ResolveAilment"]:FireServer(petUniqueId, ailmentName)
            elseif events:FindFirstChild("AilmentsServices/AilmentCompleted") then
                events["AilmentsServices/AilmentCompleted"]:FireServer(ailmentName, {["pet_unique"] = petUniqueId})
            end
        end
    end)
end

-- Главная функция сканирования
local function checkPetNeeds()
    local ailmentsClient = getFsysModule("AilmentsClient")
    local clientData = getFsysModule("ClientData")
    
    if not clientData then return end

    local playerData = nil
    pcall(function() playerData = clientData.get_data()[LocalPlayer.Name] end)
    if not playerData or not playerData.equip_manager or not playerData.equip_manager.pets then return end

    for petUniqueId, pet in pairs(playerData.equip_manager.pets) do
        local tasksFound = {}

        -- 1. Чтение прямо из AilmentsClient (самый свежий источник)
        if ailmentsClient and ailmentsClient.get_active_ailments then
            pcall(function()
                local active = ailmentsClient.get_active_ailments()
                if active then
                    for _, taskObj in pairs(active) do
                        if taskObj.pet_unique == petUniqueId or taskObj.unique == petUniqueId then
                            table.insert(tasksFound, taskObj.kind or taskObj.name or taskObj.id)
                        elseif type(taskObj) == "string" then
                            table.insert(tasksFound, taskObj)
                        end
                    end
                end
            end)
        end

        -- 2. Запасная проверка через ClientData
        if #tasksFound == 0 and playerData.ailments then
            local pAilments = playerData.ailments[petUniqueId] or playerData.ailments
            if type(pAilments) == "table" then
                for aName, _ in pairs(pAilments) do
                    table.insert(tasksFound, aName)
                end
            end
        end

        -- Выполняем найденные задачи
        if #tasksFound > 0 then
            for _, taskName in ipairs(tasksFound) do
                if _G.AutoFarm then
                    safeWait(1.5, 3)
                    resolveTask(taskName, petUniqueId)
                end
            end
        else
            print("[Поиск] Активных задач пока нет (сканируем...)")
        end
    end
end

-- Интерфейс
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
            print("=== Автофарм AilmentsClient запущен ===")
            task.spawn(function()
                while _G.AutoFarm do
                    checkPetNeeds()
                    task.wait(2.5)
                end
            end)
        else
            print("=== Автофарм остановлен ===")
        end
    end
})

OrionLib:Init()
