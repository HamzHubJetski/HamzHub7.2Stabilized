-- HamzHub v7.2 Stabilized | Blox Fruits 2026 | Auto Farm/Quest + Fruit TP
-- Fixed: repeat timeout benar, CFrame operator aman, HasQuest GUI check, fruit limit 1500, EquipTool wait, anti-hang.

local Library = loadstring(game:HttpGet("https://raw.githubusercontent.com/xHeptc/Kavo-UI-Library/main/source.lua"))()

-- PlayerGui for compatibility
local PlayerGui = game.Players.LocalPlayer:WaitForChild("PlayerGui")

-- Minimize UI
local guisBefore = {}
for _, g in ipairs(PlayerGui:GetChildren()) do if g:IsA("ScreenGui") then guisBefore[g] = true end end

local Window = Library.CreateLib("HamzHub - Blox Fruits", "DarkTheme")

-- Detect mainGui with proper timeout
local mainGui
local startDetect = tick()
repeat
    task.wait(0.1)
    for _, g in ipairs(PlayerGui:GetChildren()) do
        if g:IsA("ScreenGui") and not guisBefore[g] then mainGui = g break end
    end
until mainGui or (tick() - startDetect > 5)

local minimizeGui = Instance.new("ScreenGui", PlayerGui)
minimizeGui.Name = "MinimizeGui"
local mf = Instance.new("Frame", minimizeGui)
mf.Size, mf.Position, mf.BackgroundColor3, mf.BorderSizePixel = UDim2.new(0,60,0,30), UDim2.new(0.95,-30,0.05,0), Color3.fromRGB(30,30,30), 0

local mb = Instance.new("TextButton", mf)
mb.Size, mb.Text, mb.TextColor3, mb.BackgroundTransparency = UDim2.new(1,0,1,0), "Toggle", Color3.fromRGB(255,255,255), 1
mb.MouseButton1Click:Connect(function() if mainGui then mainGui.Enabled = not mainGui.Enabled end end)

local MainTab = Window:NewTab("Main") local FarmSection = MainTab:NewSection("Auto Farm & Quest")
local FruitTab = Window:NewTab("Fruits") local FruitSection = FruitTab:NewSection("Auto Fruit Teleport")
local TeleportTab = Window:NewTab("Teleport") local TeleportSection = TeleportTab:NewSection("Island Teleport")

-- Data statis (minimal, tambahin full)
local QuestData = {
    {LevelReq = 0, QuestGiver = "Bandit Quest Giver", QuestName = "BanditQuest1", Mob = "Bandit", CFrameNPC = CFrame.new(1060,17,1547), CFrameMob = CFrame.new(1038,10,1576), NextLevel = 10},
    {LevelReq = 10, QuestGiver = "Jungle Quest Giver", QuestName = "JungleQuest", Mob = "Monkey", CFrameNPC = CFrame.new(-1599,37,153), CFrameMob = CFrame.new(-1442,10,123), NextLevel = 15},
    -- Tambahin sisanya sampai 2800
    {LevelReq = 2750, QuestGiver = "Eternal Isles Quest Giver 2", QuestName = "EternalQuest2", Mob = "Immortal Sage", CFrameNPC = CFrame.new(25000,800,18000), CFrameMob = CFrame.new(25050,800,18050), NextLevel = 2801},
}

local Islands = {
    ["Marine Starter (Sea 1)"] = CFrame.new(-2573,7,2065),
    ["Pirate Starter (Sea 1)"] = CFrame.new(1038,5,1430),
    ["Jungle (Sea 1)"] = CFrame.new(-1210,13,379),
    -- Tambahin full
    ["Kitsune Island (Dynamic - Full Moon + Sea Danger Lv6)"] = nil,
}

_G.AutoFarm = false _G.AutoQuest = false _G.AutoFruit = false
_G.FarmMethod = "Upper" _G.Distance = 8 _G.FruitType = "All" _G.FruitSpeedLimit = 160

local Players = game:GetService("Players") local TweenService = game:GetService("TweenService")
local VirtualUser = game:GetService("VirtualUser") local player = Players.LocalPlayer

local MythicalFruits = {"Dragon", "Kitsune", "Leopard", "Mammoth", "T-Rex", "Venom", "Gas", "Spirit", "Shadow", "Dough", "Control", "Yeti"}
local LegendaryFruits = {"Buddha", "Portal", "Phoenix", "Quake", "Love", "Spider", "Sound", "Pain", "Blizzard", "Lightning"}

local islandList = {} for name in pairs(Islands) do table.insert(islandList, name) end table.sort(islandList)

TeleportSection:NewDropdown("Select Island", "", islandList, function(sel)
    local cf = Islands[sel] if cf and player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
        player.Character.HumanoidRootPart.CFrame = cf * CFrame.new(0,50,0)
    end
end)

local function GetLevel() return player.Data and player.Data.Level and player.Data.Level.Value or 1 end

local function GetQuestInfo()
    local lvl = GetLevel()
    for _, q in ipairs(QuestData) do if lvl >= q.LevelReq and (not q.NextLevel or lvl < q.NextLevel) then return q end end
end

local function FindQuestNPC(qi)
    if not qi then return end local hrp = player.Character and player.Character.HumanoidRootPart if not hrp then return end
    local nf = workspace:FindFirstChild("NPCs") if not nf then return end
    local n, md = nil, math.huge
    for _, npc in ipairs(nf:GetChildren()) do
        if npc.Name:lower():find(qi.QuestGiver:lower()) and npc:FindFirstChild("HumanoidRootPart") then
            local d = (hrp.Position - npc.HumanoidRootPart.Position).Magnitude
            if d < md then n, md = npc.HumanoidRootPart, d end
        end
    end return n
end

local function HasQuest()
    -- Check tool di Backpack/Character
    for _, t in ipairs(player.Backpack:GetChildren()) do if t:IsA("Tool") and t.Name:find("Quest") then return true end end
    if player.Character then for _, t in ipairs(player.Character:GetChildren()) do if t:IsA("Tool") and t.Name:find("Quest") then return true end end end
    -- Fallback GUI check
    local questGui = player.PlayerGui:FindFirstChild("Main") and player.PlayerGui.Main:FindFirstChild("Quest")
    if questGui and questGui.Visible then return true end
    return false
end

local function SafeTween(tcf, offsetY)
    local hrp = player.Character and player.Character:FindFirstChild("HumanoidRootPart") if not hrp then return end
    local pos = tcf.Position + (offsetY and Vector3.new(0,offsetY,0) or Vector3.zero)
    local dist = (hrp.Position - pos).Magnitude local tt = math.clamp(dist / _G.FruitSpeedLimit, 0.5, 6)
    local tween = TweenService:Create(hrp, TweenInfo.new(tt, Enum.EasingStyle.Linear), {CFrame = CFrame.new(pos)})
    tween:Play()
    local st = tick()
    while tick() - st < tt + 1.5 do if (hrp.Position - pos).Magnitude < 12 then break end task.wait(0.1) end
    if (hrp.Position - pos).Magnitude > 15 then hrp.CFrame = CFrame.new(pos) end
end

local function TakeQuest()
    local qi = GetQuestInfo() if not qi then return end local nr = FindQuestNPC(qi) if not nr then print("[HamzHub] NPC not found") return end
    SafeTween(nr.CFrame, 5)
    pcall(function()
        local p = nr.Parent:FindFirstChildOfClass("ProximityPrompt") if p then
            if fireproximityprompt then fireproximityprompt(p) end
            if p.Enabled and p.HoldDuration > 0 then p:InputHoldBegin() task.wait(p.HoldDuration + math.random(5,15)/100) p:InputHoldEnd() end
        end
    end)
end

local function GetTargetMob(qi)
    if not qi then return end local hrp = player.Character and player.Character.HumanoidRootPart if not hrp then return end
    local ef = workspace:FindFirstChild("Enemies") if not ef then return end
    local n, md = nil, math.huge
    for _, m in ipairs(ef:GetChildren()) do
        if m.Name:lower():find(qi.Mob:lower()) and m:FindFirstChild("Humanoid") and m.Humanoid.Health > 0 and m:FindFirstChild("HumanoidRootPart") then
            local d = (hrp.Position - m.HumanoidRootPart.Position).Magnitude if d < md then n, md = m.HumanoidRootPart, d end
        end
    end return n
end

local function CheckFruitType(name, list)
    for _, v in ipairs(list) do
        if name:find(v:lower()) then return true end
    end
    return false
end

local function FindNearestFruit()
    local hrp = player.Character and player.Character.HumanoidRootPart if not hrp then return end
    local n, md = nil, math.huge
    for _, o in ipairs(workspace:GetChildren()) do
        if o:IsA("Tool") and o:FindFirstChild("Handle") and o.Name:lower():find("fruit") then
            local h = o.Handle or o.PrimaryPart if h then
                local d = (hrp.Position - h.Position).Magnitude
                if d < md and d < 1500 then  -- safer limit
                    local nl = o.Name:lower() local match = _G.FruitType == "All" or
                        (_G.FruitType == "Mythical" and CheckFruitType(nl, MythicalFruits)) or
                        (_G.FruitType == "Legendary" and CheckFruitType(nl, LegendaryFruits))
                    if match then n, md = h, d end
                end
            end
        end
    end return n
end

local function SafeClick()
    local dl = math.random(80,240)/1000
    pcall(function()  -- aman kalau VirtualUser patched
        VirtualUser:Button1Down(Vector2.new(), workspace.CurrentCamera.CFrame) task.wait(dl)
        VirtualUser:Button1Up(Vector2.new(), workspace.CurrentCamera.CFrame)
    end)
    if not VirtualUser then print("[HamzHub] VirtualUser fail, mungkin patched") end
end

spawn(function()
    while true do
        task.wait(math.random(45,110)/100)
        pcall(function()  -- anti-crash kalau char nil
            local c = player.Character if not c then task.wait(2) return end
            local h = c:FindFirstChildOfClass("Humanoid") local hrp = c:FindFirstChild("HumanoidRootPart")
            if not h or not hrp or h.Health <= 0 then task.wait(2) return end
            
            if _G.AutoQuest and not HasQuest() then TakeQuest() end
            
            if _G.AutoFarm then
                local qi = GetQuestInfo() if qi then
                    local t = GetTargetMob(qi) if t then
                        local sp = t.CFrame
                        if _G.FarmMethod == "Upper" then sp = sp * CFrame.new(0, _G.Distance, 0)
                        elseif _G.FarmMethod == "Behind" then sp = sp * CFrame.new(0,0,_G.Distance) end
                        SafeTween(sp)
                        if (hrp.Position - t.Position).Magnitude < 35 then SafeClick() end
                    end
                end
            end
            
            if _G.AutoFruit then
                local f = FindNearestFruit() if f then
                    print("[HamzHub] Fruit: " .. f.Parent.Name .. " | Dist: " .. math.floor((hrp.Position - f.Position).Magnitude))
                    SafeTween(f.CFrame, 5)
                    pcall(function()
                        local p = f:FindFirstChildOfClass("ProximityPrompt") or f.Parent:FindFirstChildOfClass("ProximityPrompt")
                        if p then task.wait(math.random(10,80)/100) if fireproximityprompt then fireproximityprompt(p) end end
                        local tl = f.Parent if tl and tl:IsA("Tool") then
                            local backpackTool = player.Backpack:WaitForChild(tl.Name, 1)
                            if backpackTool then h:EquipTool(backpackTool) end
                        end
                    end)
                    task.wait(1)
                end
            end
        end)
    end
end)

FarmSection:NewToggle("Auto Farm", "", function(v) _G.AutoFarm = v end)
FarmSection:NewToggle("Auto Quest", "", function(v) _G.AutoQuest = v if v then TakeQuest() end end)
FarmSection:NewDropdown("Farm Method", "", {"Upper", "Behind"}, function(v) _G.FarmMethod = v end)
FarmSection:NewSlider("Distance", "", 25, 3, function(v) _G.Distance = v end)

FruitSection:NewToggle("Auto Fruit Teleport", "", function(v) _G.AutoFruit = v end)
FruitSection:NewDropdown("Fruit Type", "", {"All", "Mythical", "Legendary"}, function(v) _G.FruitType = v end)
FruitSection:NewSlider("TP Speed Limit", "Studs/detik (rendah = aman)", 500, 100, function(v) _G.FruitSpeedLimit = v end)

print("[HamzHub v7.2 Stabilized] Loaded! Timeout fix, CFrame aman, HasQuest GUI check, fruit 1500 studs, EquipTool wait. Gas mythical bro 🍓🐉")
