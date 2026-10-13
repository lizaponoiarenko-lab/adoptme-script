-- Adopt Me Pure Auto-Farm (No GUI, 100% Stable)
print("=== ЗАПУСК ЧИСТОГО АВТОФАРМА ===")

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local LocalPlayer = Players.LocalPlayer

_G.AutoFarm = true

-- Безопасный поиск ClientData
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

-- Отправка сигнала выполнения задачи
local function resolveAilment(ailmentName, petId)
    print(">>> ВЫПОЛНЯЕМ ЗАДАЧУ:", tostring(ailmentName), "| Pet ID:", tostring(petId))
    pcall(function()
        local api = ReplicatedStorage:FindFirstChild("API")
        if api then
            if api:FindFirstChild("AilmentsServices/AilmentCompleted") then
                api["AilmentsServices/AilmentCompleted"]:FireServer(ailmentName, {["pet_unique"] = petId})
            elseif api:FindFirstChild("AilmentsServices/ResolveAilment") then
                api["AilmentsServices/ResolveAilment"]:FireServer(petId, ailmentName)
            end
        end
    end)
end

-- Фоновый цикл сканирования и фарма
task.spawn(function()
    while true do
        if _G.AutoFarm then
            pcall(function()
                local clientData = getClientData()
                if clientData and clientData.get_data then
                    local myData = clientData.get_data()[LocalPlayer.Name]
                    if myData and myData.ailments then
                        local found = false
                        for petUnique, taskList in pairs(myData.ailments) do
                            if type(taskList) == "table" then
                                for taskName, _ in pairs(taskList) do
                                    found = true
                                    print(">>> НАЙДЕНА ЗАДАЧА:", tostring(taskName), "у питомца:", tostring(petUnique))
                                    task.wait(1.5)
                                    resolveAilment(taskName, petUnique)
                                end
                            end
                        end
                        if not found then
                            print("[Фарм] Ожидание задач у питомца...")
                        end
                    else
                        print("[Фарм] Ищем данные задач игрока...")
                    end
                end
            end)
        end
        task.wait(3)
    end
end)

print("=== АВТОФАРМ УСПЕШНО ЗАПУЩЕН В ФОНЕ ===")
