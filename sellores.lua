if not game:IsLoaded() then game.Loaded:Wait() end
local S
local ClickGUI = loadstring(game:HttpGet("https://raw.githubusercontent.com/Sc0peGam1ng/AscendHubGuiPublic/main/clickgui.lua?v=e69ef4a-final"))()
local Library = { Scheme = {} }
function Library:SetFont() end
function Library:AddTooltip(info) return info end
function Library:Notify(title, data, time)
    if type(title) == "table" then
        time = title.Time
        data = title.Description or title.Text or ""
        title = title.Title or "AscendHub"
    end
    local message = type(data) == "table" and (data.Description or data.Text or "") or tostring(data or "")
    if self._ui then self._ui:Notify(title, message, time or 3) end
end
function Library:CreateWindow(options)
    local ui = ClickGUI.new(options.Title or "AscendHub")
    self._ui = ui
    local window = {}
    function window:AddTab(tabOptions)
        local tab = { _ui = ui, _name = tabOptions.Name or "Page" }
        tab._category = ui:AddCategory(tab._name, tabOptions.Icon, tabOptions.Color)
        function tab:AddLeftGroupbox(name)
            local section = tab._category:AddSection(name or "Options")
            local group = {}
            local hasSectionApi = type(section) == "table" and type(section.AddToggle) == "function"
            function group:AddLabel(value)
                local text = type(value) == "table" and value.Text or tostring(value or "")
                if hasSectionApi then return section:AddLabel(text) end
                return tab._category:AddLabel(text)
            end
            function group:AddDivider() return nil end
            function group:AddToggle(_, cfg)
                if hasSectionApi then return section:AddToggle(cfg.Text or "Toggle", cfg.Default == true, cfg.Callback) end
                return tab._category:AddToggle(cfg.Text or "Toggle", cfg.Default == true, cfg.Callback)
            end
            function group:AddSlider(_, cfg)
                if hasSectionApi then return section:AddSlider(cfg.Text or "Slider", cfg.Min or 0, cfg.Max or 100, cfg.Default or cfg.Min or 0, "", cfg.Callback) end
                return tab._category:AddSlider(cfg.Text or "Slider", cfg.Min or 0, cfg.Max or 100, cfg.Default or cfg.Min or 0, cfg.Callback)
            end
            function group:AddDropdown(_, cfg)
                local values = cfg.Values or {}
                if #values == 0 then
                    local list = {}
                    for key in pairs(values) do table.insert(list, key) end
                    values = list
                end
                local default = cfg.Default
                if cfg.Multi then
                    local first = values[1]
                    default = type(default) == "table" and (default[first] and first or values[1]) or first
                end
                if hasSectionApi then return section:AddDropdown(cfg.Text or "Dropdown", values, default, cfg.Callback) end
                return tab._category:AddDropdown(cfg.Text or "Dropdown", values, default, cfg.Callback)
            end
            function group:AddInput(_, cfg)
                if hasSectionApi then return section:AddInput(cfg.Text or "Input", cfg.Default or "", cfg.Placeholder or "", cfg.Callback) end
                return tab._category:AddInput(cfg.Text or "Input", cfg.Default or "", cfg.Placeholder or "", cfg.Callback)
            end
            return group
        end
        tab.AddRightGroupbox = tab.AddLeftGroupbox
        return tab
    end
    return window
end
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")
local UIS = game:GetService("UserInputService")
local HttpService = game:GetService("HttpService")
local plr = Players.LocalPlayer
local Remotes = ReplicatedStorage:WaitForChild("Remotes", 10)
local Bases = Workspace:WaitForChild("Bases", 10)
local RUN_TOKEN = (tonumber(getgenv().AscendHubSellOresToken) or 0) + 1
getgenv().AscendHubSellOresToken = RUN_TOKEN
local function isAlive()
    return getgenv().AscendHubSellOresToken == RUN_TOKEN
end
-- ClickGUI owns the AscendHub ScreenGui. Do not destroy it after loading.
local BUILD = "2026-09-01.42"
local function getRemote(name)
    if Remotes then
        local r = Remotes:FindFirstChild(name)
        if r then return r end
    end
    return ReplicatedStorage:FindFirstChild(name)
end
local function safeFire(name, ...)
    local r = getRemote(name)
    if not r then return nil end
    local s, res = pcall(r.FireServer, r, ...)
    return s and res or nil
end
local function safeInvoke(name, ...)
    local r = getRemote(name)
    if not r then return nil end
    local s, res = pcall(r.InvokeServer, r, ...)
    return s and res or nil
end
local function getAttr(name, default)
    local v = plr:GetAttribute(name)
    return v ~= nil and v or default
end
local function getAssignedBase()
    local name = getAttr("AssignedBaseName", "")
    if name == "" then return nil end
    if Bases then return Bases:FindFirstChild(name) end
    return nil
end
local function getMoney()
    local n = tonumber(plr:GetAttribute("Money"))
    if n then return n end
    local ls = plr:FindFirstChild("leaderstats")
    local v = ls and ls:FindFirstChild("Money") and ls.Money.Value
    if type(v) == "number" then return v end
    if type(v) == "string" then
        local num, suf = v:gsub("[%$,%s]", ""):match("^([%d%.]+)([KMBT]?)$")
        num = tonumber(num)
        if num then
            local mult = ({ K = 1e3, M = 1e6, B = 1e9, T = 1e12 })[suf] or 1
            return num * mult
        end
    end
    return 0
end
local function fireRemote(name, ...)
    local r = getRemote(name)
    if not r then return nil end
    if r:IsA("RemoteFunction") then
        local s, res = pcall(r.InvokeServer, r, ...)
        return s and res or nil
    end
    local s, res = pcall(r.FireServer, r, ...)
    return s and res or nil
end
local actionQueue = {}
local actionCooldown = {}
local actionBusy = {}
local actionQueued = {}
local PRIORITY = {
    buyPed = 100,
    rollTP = 60,
    spin = 40,
    buyFurnace = 30,
    buyFuser = 30,
    boostSwap = 20,
    petsEquip = 15,
    farm = 10,
}
local pendingBuyOre = nil
local rollGateLoggedAt = 0
local function cooldownOk(name, cooldown)
    return (actionCooldown[name] or 0) + cooldown <= os.clock()
end
local function queuePendingAbove(prio)
    for _, j in ipairs(actionQueue) do
        if (j.prio or 0) > prio then return true end
    end
    return false
end
local function purgeQueue(name)
    for i = #actionQueue, 1, -1 do
        if actionQueue[i].name == name then
            actionQueued[name] = nil
            table.remove(actionQueue, i)
        end
    end
end
local function enqueue(name, fn)
    table.insert(actionQueue, { name = name, fn = fn, prio = PRIORITY[name] or 0 })
end
local function tryEnqueue(name, cooldown, fn, guard)
    if actionQueued[name] then
        return false
    end
    if not cooldownOk(name, cooldown) then
        return false
    end
    if #actionQueue > 25 then
        return false
    end
    local prio = PRIORITY[name] or 0
    local pos = #actionQueue + 1
    for i, j in ipairs(actionQueue) do
        if prio > (j.prio or 0) then
            pos = i
            break
        end
    end
    table.insert(actionQueue, pos, { name = name, fn = fn, guard = guard, prio = prio })
    actionQueued[name] = true
    return true
end
local function runNow(name, cooldown, fn)
    if actionBusy[name] then return false end
    if not cooldownOk(name, cooldown) then return false end
    actionCooldown[name] = os.clock()
    actionBusy[name] = true
    task.spawn(function()
        local ok, err = pcall(fn)
        if not ok then
            warn("[AscendHub] '" .. name .. "' упал с ошибкой: " .. tostring(err))
        end
        actionBusy[name] = false
    end)
    return true
end
task.spawn(function()
    while isAlive() do
        local job = table.remove(actionQueue, 1)
        if job then
            if job.guard and not job.guard() then
                actionQueued[job.name] = nil
                task.wait(0.02)
            else
                actionCooldown[job.name] = os.clock()
                local ok = pcall(job.fn)
                actionQueued[job.name] = nil
                task.wait(0.05)
            end
        else
            task.wait(0.02)
        end
    end
end)
local TP_SETTLE = 0.3
local function getRoot()
    local char = plr.Character
    return char and char:FindFirstChild("HumanoidRootPart")
end
local function forceTP(cf)
    local char = plr.Character
    local root = char and char:FindFirstChild("HumanoidRootPart")
    if not root or not char then
        return false
    end
    for attempt = 1, 2 do
        pcall(function()
            root.AssemblyLinearVelocity = Vector3.zero
            char:PivotTo(cf)
        end)
        task.wait(TP_SETTLE)
        local r2 = getRoot()
        if r2 and (r2.Position - cf.Position).Magnitude < 25 then
            return true
        end
    end
    return false
end
local function getPromptHolder(prompt)
    local ok, holder = pcall(function()
        if prompt.Parent:IsA("BasePart") then return prompt.Parent end
        return prompt.Parent:FindFirstChildWhichIsA("BasePart", true)
            or prompt.Parent.Parent and prompt.Parent.Parent:FindFirstChildWhichIsA("BasePart", true)
    end)
    return ok and holder or nil
end
local function firePrompt(prompt, mustTP, neverTP, allowDisabled)
    if not prompt or not prompt.Parent then
        return false
    end
    if not prompt.Enabled and not allowDisabled then
        return false
    end
    local wantTP = false
    if not neverTP then
        wantTP = not neverTP
    end
    local holder = wantTP and getPromptHolder(prompt) or nil
    local root = getRoot()
    local oldCF = root and root.CFrame
    if holder then
        local maxDist = tonumber(prompt.MaxActivationDistance) or 12
        local near = root
            and (root.Position - holder.Position).Magnitude <= math.max(8, maxDist - 1)
        if near then
        elseif not forceTP(holder.CFrame * CFrame.new(0, 3.5, 0)) then
            return false
        end
    elseif wantTP then
    end
    local ok = false
    if fireproximityprompt then
        ok = pcall(fireproximityprompt, prompt)
    end
    if not ok then
        ok = pcall(function()
            prompt:InputHoldBegin()
            task.wait((prompt.HoldDuration or 0) + 0.2)
            prompt:InputHoldEnd()
        end)
    end
    return ok
end
local function firePromptVerified(prompt, mustTP, verify, attempts, allowDisabled)
    attempts = attempts or 4
    for i = 1, attempts do
        local ok = firePrompt(prompt, mustTP, nil, allowDisabled)
        if not verify then return ok end
        if verify() then return true end
        if i < attempts then
            task.wait(0.3)
        end
    end
    return false
end
local function getIncomePerMin()
    local v = plr:GetAttribute("DroneEarningsPerMinute")
    if type(v) == "number" and v >= 0 and v == v and v < 1/0 then
        return v
    end
    return 0
end
local function canAffordSoon(price)
    local money = getMoney()
    if price <= money then return "yes" end
    local ipm = getIncomePerMin()
    S.IncomePerMin = ipm
    if ipm > 0 and (money + ipm * S.BudgetHorizon) >= price then
        return "soon"
    end
    return "no"
end
local function fmtShort(n)
    n = tonumber(n) or 0
    if n >= 1e15 then return string.format("%.1fq", n / 1e15) end
    if n >= 1e12 then return string.format("%.1fT", n / 1e12) end
    if n >= 1e9 then return string.format("%.1fB", n / 1e9) end
    if n >= 1e6 then return string.format("%.1fM", n / 1e6) end
    if n >= 1e3 then return string.format("%.1fK", n / 1e3) end
    return tostring(math.floor(n))
end
local ORE_RANK = {
    Common = 1, Uncommon = 2, Rare = 3, Epic = 4, Legendary = 5,
    Secret = 6, Prismatic = 7, Divine = 8, Exotic = 9, Transcended = 10,
    Ascended = 11, Almighty = 12, Admin = 13,
}
local ORE_RARITY_LIST = { "Common", "Uncommon", "Rare", "Epic", "Legendary",
    "Secret", "Prismatic", "Divine", "Exotic", "Transcended",
    "Ascended", "Almighty", "Admin" }
local GEAR_LIST = {
    { Id = "SmallGrowthGem",   Price = 500000 },
    { Id = "OreCleanser",      Price = 1000000 },
    { Id = "RustCoating",      Price = 10000000 },
    { Id = "LargeGrowthGem",   Price = 50000000 },
    { Id = "FrostCoating",     Price = 750000000 },
    { Id = "CrystalCoating",   Price = 1000000000 },
    { Id = "VoidCoating",      Price = 10000000000 },
    { Id = "SuperGrowthGem",   Price = 15000000000 },
    { Id = "AlienCoating",     Price = 100000000000 },
    { Id = "GalaxyCoating",    Price = 1000000000000 },
    { Id = "DevilsGrowthGem",  Price = 25000000000000 },
}
local LUCKY_BLOCK_LIST = { "Common", "Uncommon", "Rare", "Epic", "Legendary",
    "Secret", "Prismatic", "Divine", "Exotic", "Transcended",
    "Ascended", "Almighty", "Admin" }
local oreOk, OreMetadata = pcall(function()
    return require(ReplicatedStorage:WaitForChild("OreMetadata", 10))
end)
if not oreOk then OreMetadata = nil end
local toolOk, ToolMetadata = pcall(function()
    return require(ReplicatedStorage:WaitForChild("ToolMetadata", 10))
end)
if not toolOk then ToolMetadata = nil end
local function getMyBase()
    local baseName = getAttr("AssignedBaseName", "")
    if baseName == "" or not Bases then return nil end
    local base = Bases:FindFirstChild(baseName)
    return (base and base:IsA("Model")) and base or nil
end
local function parseMoney(str)
    if type(str) == "number" then return str end
    if type(str) ~= "string" then return nil end
    local s = str:lower():gsub("[%s,_%$]", "")
    if s == "" then return 0 end
    local num, suf = s:match("^([%d%.]+)([kmbtq]?)")
    local n = tonumber(num)
    if not n then return nil end
    local mults = { k = 1e3, m = 1e6, b = 1e9, t = 1e12, q = 1e15 }
    if suf and mults[suf] then n = n * mults[suf] end
    return n
end
local BOOST_SLOTS = 2
local BOOST_COSTS = { [1] = 10000, [2] = 1000000000 }
local function showcaseAttr(i, suffix, default)
    local v = plr:GetAttribute("ShowcasePedestal" .. i .. suffix)
    if v == nil then return default end
    return v
end
local function showcaseUnlocked(i)
    return showcaseAttr(i, "Unlocked", false) == true
end
local function showcaseOreName(i)
    local v = showcaseAttr(i, "OreName", "")
    return (type(v) == "string") and v or ""
end
local function showcaseBoostLeft(i)
    local exp = tonumber(showcaseAttr(i, "BoostExpiresAt", 0)) or 0
    local left = exp - os.time()
    return (left > 0) and left or 0
end
local function oreShowcaseMult(oreName)
    if type(oreName) ~= "string" or oreName == "" then return 0 end
    if OreMetadata then
        local ok, mult = pcall(function()
            if type(OreMetadata.GetShowcaseMultiplier) == "function" then
                return OreMetadata.GetShowcaseMultiplier(oreName)
            end
            local t = OreMetadata.ShowcaseMultipliersByOreName
            return t and t[oreName]
        end)
        local n = ok and tonumber(mult)
        if n and n > 0 then return n end
    end
    return 1
end
local function listOreTools()
    local out = {}
    local function scan(parent)
        if not parent then return end
        for _, t in ipairs(parent:GetChildren()) do
            if t:IsA("Tool") then
                local id = t:GetAttribute("OreToolId")
                local name = t:GetAttribute("OreName")
                if type(id) == "string" and id ~= ""
                    and type(name) == "string" and name ~= "" then
                    table.insert(out, { tool = t, name = name, mult = oreShowcaseMult(name) })
                end
            end
        end
    end
    scan(plr:FindFirstChild("Backpack"))
    scan(plr.Character)
    return out
end
local function bestBoostOre()
    local best
    for _, e in ipairs(listOreTools()) do
        if not best or e.mult > best.mult then best = e end
    end
    return best
end
local function getShowcasePedestal(i)
    local base = getMyBase()
    if not base then return nil end
    return base:FindFirstChild("OreShowcasePedestal" .. i)
end
local function equipOreTool(tool)
    local char = plr.Character
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    if not hum or not tool or not tool.Parent then return false end
    if tool.Parent == char then return true end
    pcall(function() hum:EquipTool(tool) end)
    task.wait(0.15)
    return tool.Parent == char
end
local function wakePrompt(prompt)
    if prompt and not prompt.Enabled then
        pcall(function() prompt.Enabled = true end)
    end
end
local function swapShowcaseOre(i)
    local best = bestBoostOre()
    if not best then
        return false
    end
    local cur = showcaseOreName(i)
    local curMult = oreShowcaseMult(cur)
    if cur ~= "" and best.mult <= curMult then
        return false
    end
    local ped = getShowcasePedestal(i)
    local prompt = ped and ped:FindFirstChild("ShowcaseOrePrompt", true)
    if not prompt then
        return false
    end
    if cur ~= "" then
        wakePrompt(prompt)
        if not firePrompt(prompt, true) then
            return false
        end
        task.wait(0.2)
    end
    if not equipOreTool(best.tool) then
        return false
    end
    wakePrompt(prompt)
    if not firePrompt(prompt, true) then
        return false
    end
    task.wait(0.2)
    return true
end
local boostBusy = {}
local function activateBoost(i)
    if boostBusy[i] then return false end
    local base = getMyBase()
    if not base then return false end
    if not showcaseUnlocked(i) then return false end
    local ore = showcaseOreName(i)
    if ore == "" then
        return false
    end
    local mult = tonumber(showcaseAttr(i, "Multiplier", 0)) or 0
    if mult <= 0 then mult = oreShowcaseMult(ore) end
    boostBusy[i] = true
    local res = safeInvoke("ShowcasePedestalAction", "ActivateBoost", i, base.Name)
    boostBusy[i] = false
    if type(res) == "table" then
        if res.success then
            return true
        end
    else
    end
    if cooldownOk("boostTP" .. i, 8) then
        enqueue("boostTP" .. i, function()
            if showcaseBoostLeft(i) > 0 then return end
            local b2 = getMyBase()
            if not b2 then return end
            local ped = getShowcasePedestal(i)
            local part = ped and ped:FindFirstChildWhichIsA("BasePart", true)
            if not part then return end
            if forceTP(part.CFrame * CFrame.new(0, 3, 0)) then
                task.wait(0.15)
                local r2 = safeInvoke("ShowcasePedestalAction", "ActivateBoost", i, b2.Name)
            end
        end)
    end
    return false
end
local function boostSwapEnabled()
    return S.AutoMoneyBoost or S.SwapBestOrePedestal
end
local function swapNeeded(i)
    if not boostSwapEnabled() then return false end
    local best = bestBoostOre()
    if not best then return false end
    local cur = showcaseOreName(i)
    if cur == "" then return true end
    return best.mult > oreShowcaseMult(cur)
end
local function anySwapPending()
    if not boostSwapEnabled() then return false end
    for i = 1, BOOST_SLOTS do
        if showcaseUnlocked(i) and swapNeeded(i) then return true end
    end
    return false
end
local function serviceBoostActivate()
    if not getMyBase() then return end
    for i = 1, BOOST_SLOTS do
        if showcaseUnlocked(i) and showcaseBoostLeft(i) <= 60 then
            pcall(activateBoost, i)
        end
    end
end
local function serviceBuyShowcasePedestal()
    local base = getMyBase()
    if not base then return end
    for i = 1, BOOST_SLOTS do
        if not showcaseUnlocked(i) then
            local cost = BOOST_COSTS[i]
            if not cost then break end
            local money = getMoney()
            if money < cost then
                return
            end
            local res = safeInvoke("ShowcasePedestalAction", "Purchase", i, base.Name)
            if type(res) == "table" then
                if res.success then
                else
                end
            end
            return
        end
    end
end
local function serviceBoostSwap()
    if not getMyBase() then return end
    for i = 1, BOOST_SLOTS do
        if showcaseUnlocked(i) and swapNeeded(i) then
            local ok, changed = pcall(swapShowcaseOre, i)
            if ok and changed then
                pcall(activateBoost, i)
            end
        end
    end
end
local savingFor = nil
local function startSaving(oreName, price)
    if not S.FreezeUpgradesForOre then return end
    local horizon = (tonumber(S.BudgetHorizon) or 10) * 60
    if savingFor and savingFor.ore == oreName then
        savingFor.price = price
        return
    end
    savingFor = { ore = oreName, price = price, deadline = os.clock() + horizon }
end
local function stopSaving(why)
    if not savingFor then return end
    savingFor = nil
end
local function spendingBlocked(cost)
    if savingFor then
        if os.clock() > savingFor.deadline and not pendingBuyOre then
            stopSaving("таймаут " .. tostring(S.BudgetHorizon) .. " мин")
        elseif S.FreezeUpgradesForOre then
            return true
        end
    end
    local reserve = tonumber(S.MoneyReserve) or 0
    if reserve > 0 then
        local money = getMoney()
        cost = tonumber(cost) or 0
        if cost > 0 then
            if money - cost < reserve then return true end
        elseif money <= reserve then
            return true
        end
    end
    return false
end
local function lvlAttr(prefix, floor)
    local v = plr:GetAttribute(string.format("%s_Floor%d", prefix, floor))
    if v == nil then v = plr:GetAttribute(prefix) end
    return tonumber(v) or 1
end
local function drillSpeedInfo(floor)
    local lvl = math.clamp(math.floor(lvlAttr("DrillSpeedLevel", floor)), 1, 10)
    if lvl >= 10 then return lvl, nil end
    return lvl, math.floor(10000 * 5 ^ (floor - 1) * 20 ^ (lvl - 1))
end
local function drillYieldInfo(floor)
    local lvl = math.max(1, math.floor(lvlAttr("DrillYieldLevel", floor)))
    return lvl, math.floor(80 * 5 ^ (floor - 1) * 1.45 ^ (lvl - 1))
end
local function oreRegenInfo(floor)
    local lvl = math.max(1, math.floor(lvlAttr("OreRegenSpeedLevel", floor)))
    return lvl, math.floor(80 * 5 ^ (floor - 1) * 1.35 ^ (lvl - 1))
end
local PEDESTAL_PRICES = { 2000, 15000, 100000, 1000000, 25000000 }
local function pedestalInfo()
    local lvl = math.clamp(math.floor(tonumber(plr:GetAttribute("NumberOfRollingPedestals")) or 1), 1, 6)
    if lvl >= 6 then return lvl, nil end
    return lvl, PEDESTAL_PRICES[lvl]
end
local luckOk, OreLuckConfig = pcall(function()
    return require(ReplicatedStorage:WaitForChild("OreLuckConfig", 10))
end)
if not luckOk then OreLuckConfig = nil end
local OL = {
    FirstTierJump = 25, BaseCost = 60, LevelsPerTier = 25,
    TierJump = 3.5, BaseGrowth = 1.55, GrowthStep = 0.04, MaxGrowth = 1.85,
}
local function olGrowth(tier)
    return math.min(OL.BaseGrowth + tier * OL.GrowthStep, OL.MaxGrowth)
end
local function oreLuckCostFallback(lvl)
    if lvl < OL.FirstTierJump then
        return math.floor(OL.BaseCost * OL.BaseGrowth ^ (lvl - 1))
    end
    local cost = math.floor(math.floor(OL.BaseCost * OL.BaseGrowth ^ (OL.FirstTierJump - 2)) * OL.TierJump)
    local startLvl = OL.FirstTierJump
    local tier = 1
    while lvl >= startLvl + OL.LevelsPerTier do
        cost = math.floor(math.floor(cost * olGrowth(tier) ^ (OL.LevelsPerTier - 1)) * OL.TierJump)
        startLvl = startLvl + OL.LevelsPerTier
        tier = tier + 1
    end
    return math.floor(cost * olGrowth(tier) ^ (lvl - startLvl))
end
local function oreLuckInfo()
    local lvl = math.max(1, math.floor(tonumber(plr:GetAttribute("RollingLuck")) or 1))
    local price
    if OreLuckConfig and type(OreLuckConfig.GetUpgradeCost) == "function" then
        local ok, c = pcall(OreLuckConfig.GetUpgradeCost, lvl)
        if ok then price = tonumber(c) end
    end
    if not price then price = oreLuckCostFallback(lvl) end
    return lvl, price
end
local function tunnelOreInfo(floor, tunnelName)
    local num = tunnelName:match("%d+") or tunnelName
    local candidates = {
        string.format("Floor%d_Tunnel%s", floor, tunnelName),
        string.format("Floor%d_%s", floor, tunnelName),
        string.format("Floor%d_Tunnel%s", floor, num),
    }
    for _, prefix in ipairs(candidates) do
        local oreType = plr:GetAttribute(prefix .. "_OreType")
        if type(oreType) == "string" and oreType ~= "" then
            local lvl = math.max(1, math.floor(tonumber(plr:GetAttribute(prefix .. "_OreLevel")) or 1))
            return oreType, lvl
        end
    end
    return nil
end
local function baseFloorsContainer(base)
    if not base then return nil end
    local fl = base:FindFirstChild("Floors")
    if fl then return fl end
    for _, c in ipairs(base:GetChildren()) do
        if c.Name:match("^[Ff]loor") then return c end
    end
    return base
end
local function getTunnelModels(floorModel)
    local out = {}
    if not floorModel then return out end
    for _, tn in ipairs(floorModel:GetChildren()) do
        if tn.Name:match("^Tunnel%d+$") then out[#out + 1] = tn end
    end
    if #out == 0 then
        for _, d in ipairs(floorModel:GetDescendants()) do
            if d.Name:match("^Tunnel%d+$") and (d:IsA("Model") or d:IsA("Folder")) then
                out[#out + 1] = d
            end
        end
    end
    table.sort(out, function(a, b)
        return (tonumber(a.Name:match("%d+")) or 0) < (tonumber(b.Name:match("%d+")) or 0)
    end)
    return out
end
local function tunnelRemoteName(tunnelModel)
    local num = tunnelModel.Name:match("(%d+)$")
    return num and ("Tunnel" .. num) or tunnelModel.Name
end
local function tunnelAttr(floor, tunnelName, suffix)
    local num = tunnelName:match("%d+") or "1"
    for _, p in ipairs({
        string.format("Floor%d_Tunnel%s_%s", floor, "Tunnel" .. num, suffix),
        string.format("Floor%d_Tunnel%s_%s", floor, num, suffix),
        string.format("Floor%d_%s_%s", floor, tunnelName, suffix),
    }) do
        local v = plr:GetAttribute(p)
        if v ~= nil then return v end
    end
    return nil
end
local function listFloors(base)
    local out = {}
    if not base then return out end
    local container = baseFloorsContainer(base)
    if container then
        for _, c in ipairs(container:GetChildren()) do
            local n = tonumber(c.Name:match("^Floor(%d+)$"))
            if n then out[#out + 1] = { num = n, model = c } end
        end
    end
    if #out == 0 then
        for _, d in ipairs(base:GetDescendants()) do
            local n = tonumber(d.Name:match("^Floor(%d+)$"))
            if n then out[#out + 1] = { num = n, model = d } end
        end
    end
    table.sort(out, function(a, b) return a.num < b.num end)
    return out
end
local function isTunnelOpen(floor, tunnelName)
    if tunnelAttr(floor, tunnelName, "Unlocked") == true then return true end
    return tunnelOreInfo(floor, tunnelName) ~= nil
end
local function forEachTunnel(base, fn)
    local seen = 0
    for _, f in ipairs(listFloors(base)) do
        for _, tm in ipairs(getTunnelModels(f.model)) do
            seen = seen + 1
            if fn(f.num, tunnelRemoteName(tm), tm, f.model) then return seen end
        end
    end
    return seen
end
local floorLockLimit = nil
local function maxFloorOwned()
    local best = 1
    for k, v in pairs(plr:GetAttributes()) do
        local n = tonumber(k:match("^Floor(%d+)_TunnelTunnel%d+_Unlocked$"))
        if n and v == true and n > best then best = n end
        local n2 = tonumber(k:match("^Floor(%d+)_TunnelTunnel%d+_OreType$"))
        if n2 and type(v) == "string" and v ~= "" and n2 > best then best = n2 end
    end
    local attr = tonumber(getAttr("MaxFloorUnlocked", 1)) or 1
    if attr > best then best = attr end
    best = math.clamp(math.floor(best), 1, 15)
    if floorLockLimit and best > floorLockLimit then
        best = floorLockLimit
    end
    return best
end
local function markFloorLocked(floorNum)
    local limit = math.max(1, floorNum - 1)
    if not floorLockLimit or limit < floorLockLimit then
        floorLockLimit = limit
    end
end
local function markFloorOwned(floorNum)
    if floorNum > (floorLockLimit or 0) then
        floorLockLimit = floorNum
    end
end
local function mutationMultOfName(name)
    if type(name) ~= "string" or name == "" then return 1 end
    if not OreMetadata or type(OreMetadata.GetMutationMultiplier) ~= "function" then return 1 end
    local ok, mm = pcall(OreMetadata.GetMutationMultiplier, name)
    if ok and tonumber(mm) then return tonumber(mm) end
    return 1
end
local function toolMutationName(tool)
    if not tool then return nil end
    local ok, a = pcall(tool.GetAttributes, tool)
    if ok and type(a) == "table" then
        local m = a.Mutation or a.OreMutation
        if type(m) == "string" and m ~= "" then return m end
    end
    return nil
end
local function oreInstMult(entry)
    if not entry then return 1 end
    return mutationMultOfName(toolMutationName(entry.tool))
end
local function tunnelMutationName(floor, tunnelName)
    local m = tunnelAttr(floor, tunnelName, "OreMutation")
    if type(m) == "string" and m ~= "" then return m end
    return nil
end
local function tunnelInstMult(floor, tunnelName)
    return mutationMultOfName(tunnelMutationName(floor, tunnelName))
end
local toolAttrsDumped = false
local function dbgDumpToolAttrs(entry)
    if toolAttrsDumped or not entry or not entry.tool then return end
    local ok, attrs = pcall(entry.tool.GetAttributes, entry.tool)
    if ok and type(attrs) == "table" then
        local parts = {}
        for k, v in pairs(attrs) do parts[#parts + 1] = k .. "=" .. tostring(v) end
        table.sort(parts)
        toolAttrsDumped = true
    end
end
local function tunnelOreUpgradePrice(oreType, lvl, count)
    if not OreMetadata or type(OreMetadata.GetUpgradePrice) ~= "function" then return nil end
    local highest = plr:GetAttribute("HighestDiscoveredOreName")
    if type(highest) ~= "string" or highest == "" then highest = nil end
    local total = 0
    for i = 0, (count or 1) - 1 do
        local ok, p = pcall(OreMetadata.GetUpgradePrice, oreType, lvl + i, highest)
        if not ok then return nil end
        total = total + math.max(0, math.floor(tonumber(p) or 0))
    end
    return total
end
local ORE_INCOME_GROWTH = 1.46
local function oreBaseIncome(oreName)
    if not OreMetadata or type(oreName) ~= "string" or oreName == "" then return nil end
    if type(OreMetadata.GetBaseIncome) == "function" then
        local ok, v = pcall(OreMetadata.GetBaseIncome, oreName, 1)
        if ok and tonumber(v) then return tonumber(v) end
    end
    if type(OreMetadata.GetUpgradePrice) == "function" then
        local ok, p = pcall(OreMetadata.GetUpgradePrice, oreName, 1)
        if ok and tonumber(p) then return tonumber(p) / 5 end
    end
    return nil
end
local function oreIncomeAt(oreName, lvl)
    local base = oreBaseIncome(oreName)
    if not base then return nil end
    return base * ORE_INCOME_GROWTH ^ (math.max(1, math.floor(tonumber(lvl) or 1)) - 1)
end
local ORE_INCOME_GROWTH_RATE = 1.122462048309373
local function toolLevel(tool)
    if not tool then return 1 end
    local lvl = tonumber(tool:GetAttribute("OreLevel") or tool:GetAttribute("Level"))
    return math.max(1, math.floor(lvl or 1))
end
local function oreIncomeAtExact(oreName, lvl)
    if type(oreName) ~= "string" or oreName == "" then return nil end
    if OreMetadata and type(OreMetadata.GetBaseIncome) == "function" then
        local highest = plr:GetAttribute("HighestDiscoveredOreName")
        if type(highest) ~= "string" or highest == "" then highest = nil end
        local ok, v = pcall(OreMetadata.GetBaseIncome, oreName, lvl, highest)
        if ok and tonumber(v) and tonumber(v) > 0 then return tonumber(v) end
    end
    local base = oreBaseIncome(oreName)
    if not base then return nil end
    return base * ORE_INCOME_GROWTH_RATE ^ (math.max(1, math.floor(tonumber(lvl) or 1)) - 1)
end
local function orePotency(oreName, lvl, mutationName)
    local inc = oreIncomeAtExact(oreName, lvl)
    if not inc then return nil end
    return inc * mutationMultOfName(mutationName)
end
local function oreCeiling(oreName, mutationName)
    local base = oreBaseIncome(oreName)
    if not base then return nil end
    return base * mutationMultOfName(mutationName)
end
local function listOreCandidates()
    local out = {}
    local seen = {}
    local function scan(parent)
        if not parent then return end
        for _, t in ipairs(parent:GetChildren()) do
            if t:IsA("Tool") then
                local id = t:GetAttribute("OreToolId")
                local name = t:GetAttribute("OreName") or t:GetAttribute("OreType")
                if type(id) == "string" and id ~= ""
                    and type(name) == "string" and name ~= ""
                    and not seen[id] then
                    seen[id] = true
                    local lvl = toolLevel(t)
                    local mut = toolMutationName(t)
                    out[#out + 1] = {
                        tool = t, id = id, name = name,
                        lvl = lvl, mut = mut,
                        potency = orePotency(name, lvl, mut),
                        ceiling = oreCeiling(name, mut),
                    }
                end
            end
        end
    end
    scan(plr:FindFirstChild("Backpack"))
    scan(plr.Character)
    return out
end
local function equipTunnelOre(baseName, floor, tn, cand)
    if not equipOreTool(cand.tool) then
        return false
    end
    local res = safeInvoke("BaseBuildEquipOre", baseName, floor, tn,
        cand.name, cand.lvl, cand.id)
    if type(res) == "table" and res.success == false then
        return false
    end
    return true
end
local function removeTunnelOre(baseName, floor, tn)
    return safeInvoke("BaseBuildTunnelAction", baseName, floor, tn, "RemoveOre")
end
local FURNACE_BUY_PRICE = 150000
local FUSER_BUY_PRICE = 100000000000
local furnaceCfgOk, FurnaceConfig = pcall(function()
    return require(ReplicatedStorage:WaitForChild("FurnaceConfig", 10))
end)
if not furnaceCfgOk then FurnaceConfig = nil end
local function furnaceUpgradePrice(lvl)
    if FurnaceConfig and type(FurnaceConfig.GetUpgradePrice) == "function" then
        local ok, p = pcall(FurnaceConfig.GetUpgradePrice, lvl)
        if ok and tonumber(p) then return tonumber(p) end
    end
    local rate = math.max(1, math.floor(1000 * 1.25 ^ (lvl - 1)))
    return rate * 100
end
local furnaceStateCache = nil
local furnaceStateAt = 0
local function furnaceState(force)
    local now = os.clock()
    if not force and furnaceStateCache and (now - furnaceStateAt) < 5 then
        return furnaceStateCache
    end
    local base = getMyBase()
    if not base then return furnaceStateCache end
    local res = safeInvoke("BaseCrateAction", base.Name, "GetState")
    if type(res) == "table" and res.success == true
        and type(res.result) == "table" and type(res.result.Furnace) == "table"
    then
        furnaceStateCache = res.result.Furnace
        furnaceStateAt = now
    end
    return furnaceStateCache
end
local floorPriceCache = {}
local function floorPrice(floorNumber)
    if floorPriceCache[floorNumber] then return floorPriceCache[floorNumber] end
    local res = safeInvoke("BaseBuildPurchaseFloor", "GetFloorPrice", floorNumber)
    local price = nil
    if type(res) == "table" then
        if res.success == true and type(res.price) == "number" then
            price = res.price
        end
    elseif type(res) == "number" then
        price = res
    end
    if price and price > 0 then
        floorPriceCache[floorNumber] = price
        return price
    end
    return nil
end
local petOk, PetMetadata = pcall(function()
    return require(ReplicatedStorage:WaitForChild("PetMetadata", 10))
end)
if not petOk then PetMetadata = nil end
local function luckyBlockInfo(rarity)
    local id = tostring(rarity) .. "LuckyBlock"
    if PetMetadata and type(PetMetadata.GetLuckyBlock) == "function" then
        local ok, lb = pcall(PetMetadata.GetLuckyBlock, id)
        if ok and type(lb) == "table" then return id, tonumber(lb.Price) end
    end
    return id, nil
end
local function canSpend(tag, price)
    price = tonumber(price)
    if not price or price <= 0 then
        return false
    end
    local money = getMoney()
    if price > money then
        return false
    end
    if spendingBlocked(price) then
        return false
    end
    return true
end
local function cheapestFloorUpgrade(infoFn, skipFloors)
    local bestFloor, bestLvl, bestPrice
    local owned = maxFloorOwned()
    for _, f in ipairs(listFloors(getMyBase())) do
        if f.num <= owned and not (skipFloors and skipFloors[f.num]) then
            local lvl, price = infoFn(f.num)
            if price and (not bestPrice or price < bestPrice) then
                bestFloor, bestLvl, bestPrice = f.num, lvl, price
            end
        end
    end
    return bestFloor, bestLvl, bestPrice
end
local function savingState()
    if not savingFor then return nil end
    return {
        ore = savingFor.ore,
        price = savingFor.price or 0,
        left = savingFor.deadline - os.clock(),
    }
end
local function savingOre()
    return savingFor and savingFor.ore or nil
end
local collectedIds = {}
local function collectDroneOres()
    local base = getMyBase()
    if not base then return 0 end
    local ids = {}
    for _, obj in ipairs(Workspace:GetDescendants()) do
        local rid = obj:GetAttribute("RewardId")
        if rid and type(rid) == "string" and not collectedIds[rid] then
            collectedIds[rid] = true
            table.insert(ids, rid)
            if #ids >= 100 then break end
        end
    end
    if #ids == 0 then return 0 end
    local res = safeInvoke("BaseCrateAction", base.Name, "CollectDroneOres", ids)
    if type(res) ~= "table" then
        for _, id in ipairs(ids) do collectedIds[id] = nil end
        return 0
    end
    return #ids
end
local function getCarriedStack()
    local char = plr.Character
    if not char then return nil end
    local carried = char:FindFirstChild("CarriedOreCrateStack")
    if carried and carried:IsA("Model") then return carried end
    return nil
end
local function carryingCrates()
    return getCarriedStack() ~= nil
end
local function waitCarry(want, timeout)
    local t0 = os.clock()
    repeat
        local stack = getCarriedStack()
        if stack then
            if not want then return true end
            if stack:GetAttribute("CarriedCrateType") == want then return true end
        end
        task.wait(0.1)
    until os.clock() - t0 > (timeout or 1.5)
    return false
end
local function waitEmptyHands(timeout)
    local t0 = os.clock()
    repeat
        if not getCarriedStack() then return true end
        task.wait(0.1)
    until os.clock() - t0 > (timeout or 1.5)
    return false
end
local function countWoodCrates(base)
    local stack = base and base:FindFirstChild("DroneCrateStack")
    if not stack then return 0 end
    local n = 0
    for _, c in ipairs(stack:GetChildren()) do
        if c:IsA("Model") and c.Name:match("^Crate%d+$") then n = n + 1 end
    end
    return n
end
local function countMetalCrates(furnace)
    local stack = furnace and furnace:FindFirstChild("FurnaceMetalCrateStack")
    if not stack then return 0 end
    local n = 0
    for _, c in ipairs(stack:GetChildren()) do
        if c:IsA("Model") and c.Name:match("^MetalCrate%d+$") then n = n + 1 end
    end
    return n
end
local function getFurnace()
    local base = getMyBase()
    return base and base:FindFirstChild("Furnace")
end
local function sellOres()
    local base = getMyBase()
    if not base then
        return false
    end
    if not carryingCrates() then
        local wood = countWoodCrates(base)
        if wood == 0 then return false end
        local pickup = base:FindFirstChild("PickUpOresPrompt", true)
        if not pickup then
            return false
        end
        if not firePromptVerified(pickup, true, function() return waitCarry(nil, 1.2) end) then
            return false
        end
    end
    local sell = base:FindFirstChild("SellOresPrompt", true)
    if sell and sell.Enabled then
        return firePromptVerified(sell, true, function() return waitEmptyHands(1.2) end)
    end
    return false
end
local function furnaceTick()
    local base = getMyBase()
    if not base then
        return false
    end
    local furnace = base:FindFirstChild("Furnace")
    local purchased = plr:GetAttribute("FurnacePurchased") == true
    if not (furnace and purchased) then
        return sellOres()
    end
    local wood = countWoodCrates(base)
    if wood > 0 then
        local pickupWood = base:FindFirstChild("PickUpOresPrompt", true)
        if pickupWood then
            if firePromptVerified(pickupWood, true, function() return waitCarry("Wooden", 1.2) end) then
                local place = furnace:FindFirstChild("PlaceCratesPrompt", true)
                if place and place.Enabled then
                    firePromptVerified(place, true, function() return waitEmptyHands(1.2) end)
                else
                end
            end
        end
    end
    local metal = countMetalCrates(furnace)
    if metal > 0 then
        local pickupMetal = furnace:FindFirstChild("PickUpCratesPrompt", true)
        if pickupMetal then
            if firePromptVerified(pickupMetal, true, function() return waitCarry("Metal", 1.2) end) then
                local sell = base:FindFirstChild("SellOresPrompt", true)
                if sell and sell.Enabled then
                    firePromptVerified(sell, true, function() return waitEmptyHands(1.2) end)
                end
            end
        end
        return true
    end
    return false
end
local function notify(title, desc, time)
    Library:Notify({ Title = title, Description = desc, Time = time or 3 })
end
S = {
    AutoCollect = false,
    AutoSell = false,
    UseFurnace = true,
    AutoFurnaceSkip = false,
    AutoDrill = false,
    AutoUpgradeTunnelOre = false,
    AutoGrowthGems = false,
    AutoUpgradeFurnace = false,
    AutoBuyFurnace = false,
    AutoBuyTunnel = false,
    AutoBuyPedestal = false,
    PedestalMinRarity = "Legendary",
    FarmDelay = 1,
    FarmInterval = 20,
    AutoMoneyBoost = false,
    AutoBuyShowcasePedestal = false,
    SwapBestOrePedestal = false,
    FreezeUpgradesForOre = true,
    MoneyReserve = 0,
    BudgetHorizon = 10,
    IncomePerMin = 0,
    AutoGear = false,
    GearToBuyMulti = {},
    GearStackCap = 0,
    AutoRoll = false,
    RollDelay = 0.3,
    AutoDrillSpeed = false,
    AutoDrillYield = false,
    AutoOreRegen = false,
    AutoPedestal = false,
    AutoOreLuck = false,
    UpgradeDelay = 0.5,
    AutoEquipBest = false,
    SmartEquipBest = true,
    EquipDelay = 1,
    TunnelOreMaxLevel = 20,
    AutoBuyFloor = false,
    AutoTrash = false,
    TrashMaxRarity = "Common",
    AutoFuserBuy = false,
    AutoFuserRun = false,
    AutoFuserSkip = false,
    AutoClaimDaily = false,
    AutoClaimPlaytime = false,
    AutoClaimOffline = false,
    AutoTimeSkip = false,
    MinTimeSkip = "Any",
    AutoLuckySpin = false,
    AutoLuckyBlock = false,
    AutoGroupReward = false,
    BuyLuckyBlock = false,
    LuckyBlockRarity = { Legendary = true },
    AutoEquipPets = false,
    AutoMutation = false,
    Lang = "English",
    OreESP = false,
    CrateESP = false,
    Noclip = false,
    WalkSpeed = 16,
    JumpPower = 50,
}
local CONFIG_DIR = "ascendhub"
local CONFIG_PATH = "ascendhub/sell-ores-config.json"
local CONFIG_KEYS = {}
do
    local skip = { IncomePerMin = true }
    for k in pairs(S) do
        if not skip[k] then table.insert(CONFIG_KEYS, k) end
    end
end
local function saveConfig()
    if not writefile then return end
    local data = {}
    for _, k in ipairs(CONFIG_KEYS) do
        data[k] = S[k]
    end
    pcall(function()
        if not isfolder(CONFIG_DIR) then
            makefolder(CONFIG_DIR)
        end
        writefile(CONFIG_PATH, HttpService:JSONEncode(data))
    end)
end
local function loadConfig()
    if not readfile or not isfile then return 0 end
    local ok, raw = pcall(readfile, CONFIG_PATH)
    if not ok then return 0 end
    local ok2, data = pcall(HttpService.JSONDecode, HttpService, raw)
    if not ok2 or type(data) ~= "table" then return 0 end
    local n = 0
    for _, k in ipairs(CONFIG_KEYS) do
        if data[k] ~= nil then
            S[k] = data[k]
            n = n + 1
        end
    end
    return n
end
local loadedCount = loadConfig()
local function def(key, fallback)
    local v = S[key]
    if v ~= nil then return v end
    return fallback
end
local function stripPrice(s)
    if type(s) ~= "string" then return s end
    return (s:gsub("%s*%(.-%)$", ""))
end
local function defMulti(key, values)
    local v = S[key]
    local raw = {}
    if type(v) == "table" then
        for k, on in pairs(v) do
            if on == true and type(k) == "string" then table.insert(raw, k) end
            if type(k) == "number" and type(on) == "string" then table.insert(raw, on) end
        end
    elseif type(v) == "string" and v ~= "" and v ~= "None" then
        table.insert(raw, v)
    end
    if type(values) ~= "table" then
        table.sort(raw)
        return raw
    end
    local out = {}
    for _, val in ipairs(values) do
        for _, saved in ipairs(raw) do
            if val == saved or stripPrice(val) == saved then
                table.insert(out, val)
                break
            end
        end
    end
    return out
end
local function multiList(key)
    local v = S[key]
    local out = {}
    if type(v) == "table" then
        for k, on in pairs(v) do
            if on == true and type(k) == "string" then table.insert(out, k) end
            if type(k) == "number" and type(on) == "string" then table.insert(out, on) end
        end
        table.sort(out)
    elseif type(v) == "string" and v ~= "" and v ~= "None" then
        table.insert(out, v)
    end
    return out
end
task.spawn(function()
    while isAlive() and task.wait(15) do
        pcall(saveConfig)
    end
end)
Library.Scheme.FontColor       = Color3.fromHex("ffffff")
Library.Scheme.MainColor       = Color3.fromHex("1e1e2e")
Library.Scheme.AccentColor     = Color3.fromHex("cba6f7")
Library.Scheme.BackgroundColor = Color3.fromHex("11111b")
Library.Scheme.OutlineColor    = Color3.fromHex("313244")
Library:SetFont(Enum.Font.Gotham)
local LANGS = { "English", "Русский" }
local LANG = def("Lang", "English") == "Русский" and "ru" or "en"
local TR = {}
local function T(key)
    local e = TR[key]
    if not e then return key end
    return e[LANG] or e.en or key
end
local I18N = {
    LIVE = {},
    KEY = {},
    GBS = {},
    RAW = nil,
    REP = nil,
}
I18N.RAW = Library.AddTooltip
function Library:AddTooltip(InfoStr, DisabledInfoStr, HoverInstance)
    local tt = I18N.RAW(self, InfoStr, DisabledInfoStr, HoverInstance)
    I18N.LIVE[#I18N.LIVE + 1] = {
        tt = tt, info = InfoStr, disabled = DisabledInfoStr, hover = HoverInstance,
    }
    return tt
end
do
local Win = Library:CreateWindow({
    Title = "AscendHub",
    Footer = "discord.gg/WDDpN4Bv",
    Size = UDim2.fromOffset(760, 560),
    Center = true,
    AutoShow = true,
    Resizable = true,
    MinContainerWidth = 660,
    MaxContainerWidth = 960,
    ToggleKeybind = Enum.KeyCode.RightShift,
})
I18N.RAWTAB = Win.AddTab
function Win:AddTab(...)
    local tab, idx = I18N.RAWTAB(self, ...)
    if type(tab) == "table" then
        for _, m in ipairs({ "AddLeftGroupbox", "AddRightGroupbox" }) do
            local raw = tab[m]
            if raw then
                tab[m] = function(t, ...)
                    local gb = raw(t, ...)
                    if type(gb) == "table" then
                        I18N.GBS[#I18N.GBS + 1] = gb
                    end
                    return gb
                end
            end
        end
    end
    return tab, idx
end
local TabMain = Win:AddTab({ Name = "Main", Icon = "house" })
do
local StatusGB = TabMain:AddLeftGroupbox("Status")
local StatusLabel = StatusGB:AddLabel({ Text = "Loading...", DoesWrap = true })
local BaseLabel = StatusGB:AddLabel({ Text = "Base: ...", DoesWrap = true })
local FloorLabel = StatusGB:AddLabel({ Text = "Floor: ...", DoesWrap = true })
local IncomeLabel = StatusGB:AddLabel({ Text = "Income: ...", DoesWrap = true })
local SaveLabel = StatusGB:AddLabel({ Text = "Saving: off", DoesWrap = true })
task.spawn(function()
    while isAlive() and task.wait(1) do
        pcall(function()
            StatusLabel:SetText("Money: " .. tostring(getMoney()))
            local bn = getAttr("AssignedBaseName", "None")
            BaseLabel:SetText("Base: " .. bn)
            FloorLabel:SetText("Floor: " .. tostring(maxFloorOwned()))
            IncomeLabel:SetText("Income: " .. fmtShort(S.IncomePerMin) .. "/min")
            local sv = savingState()
            if sv then
                SaveLabel:SetText(string.format("Saving: %s (%s) | %ds", sv.ore,
                    fmtShort(sv.price), math.max(0, math.floor(sv.left))))
            elseif (tonumber(S.MoneyReserve) or 0) > 0 then
                SaveLabel:SetText("Saving: off | reserve " .. fmtShort(S.MoneyReserve))
            else
                SaveLabel:SetText("Saving: off")
            end
        end)
    end
end)
end
local SetGB = TabMain:AddRightGroupbox("Settings")
SetGB:AddDropdown("Lang", {
    Text = "Language / Язык",
    Values = LANGS,
    Default = def("Lang", "English"),
    Callback = function(v)
        LANG = v == "Русский" and "ru" or "en"
        S.Lang = v
        if I18N.REP then I18N.REP() end
    end,
})
SetGB:AddDivider()
local InfoLabel = SetGB:AddLabel({ Text = "RightShift — toggle UI", DoesWrap = true })
SetGB:AddLabel({ Text = "AscendHub · PlaceId 122572082932179", DoesWrap = true })
local TabFarm = Win:AddTab({ Name = "Farm", Icon = "pickaxe" })
local FarmGB = TabFarm:AddLeftGroupbox("Ore Farming")
TR.AutoSell = {
    en = "Automatically collects ores from drones and sells them (furnace +50% if enabled).",
    ru = "Автоматически собирает руду дронов и продаёт её (через печь +50%, если включена)." }
FarmGB:AddToggle("AutoSell", {
    Text = "Auto Sell Ores",
    Tooltip = T("AutoSell"),
    Default = def("AutoSell", false),
    Callback = function(v)
        S.AutoSell = v
        if not v then purgeQueue("farm") end
    end,
})
if def("AutoCollect", false) and not def("AutoSell", false) then
    S.AutoSell = true
end
if def("AutoFuser", false) then
    S.AutoFuserBuy = true
    S.AutoFuserRun = true
end
TR.FarmInterval = {
    en = "How often a full collect+sell cycle starts.",
    ru = "Как часто начинать новый цикл «собрал → продал»." }
FarmGB:AddSlider("FarmInterval", {
    Text = "Farm Interval (s)",
    Tooltip = T("FarmInterval"),
    Default = def("FarmInterval", 20),
    Min = 5, Max = 120, Rounding = 0,
    Callback = function(v) S.FarmInterval = v end,
})
TR.UseFurnace = {
    en = "Smelt wooden crates into metal (+50% value). Requires a purchased furnace.",
    ru = "Плавит деревянные ящики в металлические (+50% к цене). Нужна купленная печь." }
FarmGB:AddToggle("UseFurnace", {
    Text = "Use Furnace (+50%)",
    Tooltip = T("UseFurnace"),
    Default = def("UseFurnace", true),
    Callback = function(v) S.UseFurnace = v end,
})
TR.AutoFurnaceSkip = {
    en = "Instantly finishes all smelting using Furnace Skip items.",
    ru = "Мгновенно завершает всю плавку предметами Furnace Skip." }
FarmGB:AddToggle("AutoFurnaceSkip", {
    Text = "Auto Furnace Skip",
    Tooltip = T("AutoFurnaceSkip"),
    Default = def("AutoFurnaceSkip", false),
    Callback = function(v) S.AutoFurnaceSkip = v end,
})
TR.AutoBuyFurnace = {
    en = "Buys the furnace on your base for $150K.",
    ru = "Покупает печь на базе за $150K." }
FarmGB:AddToggle("AutoBuyFurnace", {
    Text = "Auto Buy Furnace ($150K)",
    Tooltip = T("AutoBuyFurnace"),
    Default = def("AutoBuyFurnace", false),
    Callback = function(v)
        S.AutoBuyFurnace = v
        if not v then purgeQueue("buyFurnace") end
    end,
})
TR.AutoUpgradeFurnace = {
    en = "Upgrades the furnace. Each level speeds up smelting.",
    ru = "Прокачивает печь. Каждый уровень ускоряет плавку." }
FarmGB:AddToggle("AutoUpgradeFurnace", {
    Text = "Auto Upgrade Furnace",
    Tooltip = T("AutoUpgradeFurnace"),
    Default = def("AutoUpgradeFurnace", false),
    Callback = function(v) S.AutoUpgradeFurnace = v end,
})
TR.AutoTrash = {
    en = "Throws away ores below the selected rarity.",
    ru = "Выбрасывает руды редкости ниже выбранной." }
FarmGB:AddToggle("AutoTrash", {
    Text = "Auto Trash",
    Tooltip = T("AutoTrash"),
    Default = def("AutoTrash", false),
    Callback = function(v) S.AutoTrash = v end,
})
TR.TrashMaxRarity = {
    en = "Ores rarer than this are kept.",
    ru = "Руды этой редкости и выше не трогаются." }
FarmGB:AddDropdown("TrashMaxRarity", {
    Text = "Trash Below Rarity",
    Tooltip = T("TrashMaxRarity"),
    Values = ORE_RARITY_LIST,
    Default = def("TrashMaxRarity", "Common"),
    Callback = function(v) S.TrashMaxRarity = v end,
})
local TabRoll = Win:AddTab({ Name = "Roll", Icon = "dices" })
local RollGB = TabRoll:AddLeftGroupbox("Ore Rolling")
TR.AutoRoll = {
    en = "Automatically rolls ores on the lever.",
    ru = "Автоматически роллит руду на рычаге." }
RollGB:AddToggle("AutoRoll", {
    Text = "Auto Roll Ores",
    Tooltip = T("AutoRoll"),
    Default = def("AutoRoll", false),
    Callback = function(v)
        S.AutoRoll = v
        if not v then purgeQueue("rollTP") end
    end,
})
TR.RollDelay = {
    en = "Delay between lever presses.",
    ru = "Задержка между нажатиями рычага." }
RollGB:AddSlider("RollDelay", {
    Text = "Roll Delay (s)",
    Tooltip = T("RollDelay"),
    Default = def("RollDelay", 0.5),
    Min = 0.2, Max = 3, Rounding = 1,
    Callback = function(v) S.RollDelay = v end,
})
TR.AutoBuyPedestal = {
    en = "Buys rolled ores from pedestals if their rarity is high enough.",
    ru = "Покупает выкатанную руду с пьедесталов, если редкость достаточно высокая." }
RollGB:AddToggle("AutoBuyPedestal", {
    Text = "Auto Buy Rolled Ores",
    Tooltip = T("AutoBuyPedestal"),
    Default = def("AutoBuyPedestal", false),
    Callback = function(v)
        S.AutoBuyPedestal = v
        if not v then
            purgeQueue("buyPed")
            pendingBuyOre = nil
        end
    end,
})
TR.PedestalMinRarity = {
    en = "Minimum rarity to buy from pedestals.",
    ru = "Минимальная редкость для покупки с пьедесталов." }
RollGB:AddDropdown("PedestalMinRarity", {
    Text = "Min Rarity to Buy",
    Tooltip = T("PedestalMinRarity"),
    Values = ORE_RARITY_LIST,
    Default = def("PedestalMinRarity", "Legendary"),
    Callback = function(v) S.PedestalMinRarity = v end,
})
TR.AutoPedestal = {
    en = "Upgrades the number of rolling pedestals.",
    ru = "Прокачивает количество пьедесталов ролла." }
RollGB:AddToggle("AutoPedestal", {
    Text = "Auto Upgrade Pedestals",
    Tooltip = T("AutoPedestal"),
    Default = def("AutoPedestal", false),
    Callback = function(v) S.AutoPedestal = v end,
})
TR.AutoOreLuck = {
    en = "Upgrades ore luck (better roll chances).",
    ru = "Прокачивает удачу руды (шансы ролла лучше)." }
RollGB:AddToggle("AutoOreLuck", {
    Text = "Auto Upgrade Ore Luck",
    Tooltip = T("AutoOreLuck"),
    Default = def("AutoOreLuck", false),
    Callback = function(v) S.AutoOreLuck = v end,
})
local BoostGB = TabRoll:AddRightGroupbox("Money Boost")
TR.AutoMoneyBoost = {
    en = "Places the best ore on the boost pedestal and activates the x-multiplier for 60 min. Free.",
    ru = "Кладёт лучшую руду на пьедестал буста и активирует множитель на 60 минут. Бесплатно." }
BoostGB:AddToggle("AutoMoneyBoost", {
    Text = "Auto Money Boost",
    Tooltip = T("AutoMoneyBoost"),
    Default = def("AutoMoneyBoost", false),
    Callback = function(v) S.AutoMoneyBoost = v end,
})
TR.AutoBuyShowcasePedestal = {
    en = "Buys boost pedestals: slot 1 — $10K, slot 2 — $1B.",
    ru = "Покупает пьедесталы буста: слот 1 — $10K, слот 2 — $1B." }
BoostGB:AddToggle("AutoBuyShowcasePedestal", {
    Text = "Auto Buy Boost Pedestal",
    Tooltip = T("AutoBuyShowcasePedestal"),
    Default = def("AutoBuyShowcasePedestal", false),
    Callback = function(v) S.AutoBuyShowcasePedestal = v end,
})
TR.SwapBestOrePedestal = {
    en = "Keeps the best ore on the boost pedestal.",
    ru = "Держит лучшую руду на пьедестале буста." }
BoostGB:AddToggle("SwapBestOrePedestal", {
    Text = "Auto Swap Boost Ore",
    Tooltip = T("SwapBestOrePedestal"),
    Default = def("SwapBestOrePedestal", false),
    Callback = function(v) S.SwapBestOrePedestal = v end,
})
TR.FreezeUpgradesForOre = {
    en = "Save up for ore on pedestal. Freezes all other spending until purchase or timeout.",
    ru = "Копим на руду с пьедестала — все остальные траты стоят на паузе." }
BoostGB:AddToggle("FreezeUpgradesForOre", {
    Text = "Save Up For Ore",
    Tooltip = T("FreezeUpgradesForOre"),
    Default = def("FreezeUpgradesForOre", true),
    Callback = function(v)
        S.FreezeUpgradesForOre = v
        if not v then stopSaving("выключено вручную") end
    end,
})
TR.BudgetHorizon = {
    en = "Minutes ahead to check if we can afford the ore. Higher = save longer.",
    ru = "На сколько минут вперёд считаем «дотянем». Больше = копим дольше." }
BoostGB:AddSlider("BudgetHorizon", {
    Text = "Budget Horizon (min)",
    Tooltip = T("BudgetHorizon"),
    Default = def("BudgetHorizon", 10),
    Min = 3, Max = 30, Rounding = 0,
    Callback = function(v) S.BudgetHorizon = v end,
})
TR.MoneyReserve = {
    en = "Never spend below this amount (500k / 1.5m / 2b). 0 = off.",
    ru = "Не тратить ниже этой суммы (500k / 1.5m / 2b). 0 = выкл." }
BoostGB:AddInput("MoneyReserve", {
    Text = "Money Reserve",
    Tooltip = T("MoneyReserve"),
    Default = fmtShort(tonumber(S.MoneyReserve) or 0),
    Finished = true,
    ClearTextOnFocus = false,
    Placeholder = "0 / 500k / 1.5m",
    VerifyValue = function(t) return parseMoney(t) ~= nil end,
    Callback = function(v)
        local n = parseMoney(v)
        if n then S.MoneyReserve = n end
    end,
})
local TabTun = Win:AddTab({ Name = "Tunnels", Icon = "route" })
local TunGB = TabTun:AddLeftGroupbox("Tunnel Ore")
TR.AutoUpgradeTunnelOre = {
    en = "Upgrades ore levels in tunnels (+10 when affordable, else +1).",
    ru = "Прокачивает уровень руды в тоннелях (+10 если хватает денег, иначе +1)." }
TunGB:AddToggle("AutoUpgradeTunnelOre", {
    Text = "Auto Upgrade Tunnel Ore",
    Tooltip = T("AutoUpgradeTunnelOre"),
    Default = def("AutoUpgradeTunnelOre", false),
    Callback = function(v) S.AutoUpgradeTunnelOre = v end,
})
TR.TunnelOreMaxLevel = {
    en = "Max ore level to upgrade to.",
    ru = "До какого уровня качать руду." }
TunGB:AddSlider("TunnelOreMaxLevel", {
    Text = "Ore Max Level",
    Tooltip = T("TunnelOreMaxLevel"),
    Default = def("TunnelOreMaxLevel", 20),
    Min = 1, Max = 100, Rounding = 0,
    Callback = function(v) S.TunnelOreMaxLevel = v end,
})
TR.AutoEquipBest = {
    en = "Automatically places the best ores into tunnels.",
    ru = "Автоматически ставит лучшую руду в тоннели." }
TunGB:AddToggle("AutoEquipBest", {
    Text = "Auto Equip Best Ore",
    Tooltip = T("AutoEquipBest"),
    Default = def("AutoEquipBest", false),
    Callback = function(v) S.AutoEquipBest = v end,
})
TR.SmartEquipBest = {
    en = "Compares ores by real value (level + mutation), not just base.",
    ru = "Сравнивает руды по реальной силе (уровень + мутация), а не только по базе." }
TunGB:AddToggle("SmartEquipBest", {
    Text = "Smart Equip",
    Tooltip = T("SmartEquipBest"),
    Default = def("SmartEquipBest", true),
    Callback = function(v) S.SmartEquipBest = v end,
})
TR.AutoMutation = {
    en = "Applies mutation coatings from inventory onto the best ores. Replaces worse mutations.",
    ru = "Накладывает мутации из инвентаря на лучшие руды. Худшие мутации заменяет." }
TunGB:AddToggle("AutoMutation", {
    Text = "Auto Mutation",
    Tooltip = T("AutoMutation"),
    Default = def("AutoMutation", false),
    Callback = function(v) S.AutoMutation = v end,
})
TR.AutoGrowthGems = {
    en = "Applies growth gems from inventory for a mining multiplier.",
    ru = "Применяет гемы роста из инвентаря — множитель к добыче." }
TunGB:AddToggle("AutoGrowthGems", {
    Text = "Auto Growth Gems",
    Tooltip = T("AutoGrowthGems"),
    Default = def("AutoGrowthGems", false),
    Callback = function(v) S.AutoGrowthGems = v end,
})
local TunUpGB = TabTun:AddRightGroupbox("Tunnel Upgrades")
TR.AutoDrillSpeed = {
    en = "Upgrades drill speed on all floors.",
    ru = "Прокачивает скорость бура на всех этажах." }
TunUpGB:AddToggle("AutoDrillSpeed", {
    Text = "Auto Drill Speed",
    Tooltip = T("AutoDrillSpeed"),
    Default = def("AutoDrillSpeed", false),
    Callback = function(v) S.AutoDrillSpeed = v end,
})
TR.AutoDrillYield = {
    en = "Upgrades drill yield on all floors.",
    ru = "Прокачивает добычу бура на всех этажах." }
TunUpGB:AddToggle("AutoDrillYield", {
    Text = "Auto Drill Yield",
    Tooltip = T("AutoDrillYield"),
    Default = def("AutoDrillYield", false),
    Callback = function(v) S.AutoDrillYield = v end,
})
TR.AutoOreRegen = {
    en = "Upgrades ore regeneration speed.",
    ru = "Прокачивает скорость регенерации руды." }
TunUpGB:AddToggle("AutoOreRegen", {
    Text = "Auto Ore Regen",
    Tooltip = T("AutoOreRegen"),
    Default = def("AutoOreRegen", false),
    Callback = function(v) S.AutoOreRegen = v end,
})
TR.UpgradeDelay = {
    en = "Delay between upgrade purchases.",
    ru = "Задержка между покупками апгрейдов." }
TunUpGB:AddSlider("UpgradeDelay", {
    Text = "Upgrade Delay (s)",
    Tooltip = T("UpgradeDelay"),
    Default = def("UpgradeDelay", 1),
    Min = 0.5, Max = 5, Rounding = 1,
    Callback = function(v) S.UpgradeDelay = v end,
})
TR.EquipDelay = {
    en = "Delay between ore equip actions.",
    ru = "Задержка между установками руды." }
TunUpGB:AddSlider("EquipDelay", {
    Text = "Equip Delay (s)",
    Tooltip = T("EquipDelay"),
    Default = def("EquipDelay", 1),
    Min = 1, Max = 10, Rounding = 0,
    Callback = function(v) S.EquipDelay = v end,
})
local TabBuy = Win:AddTab({ Name = "Purchases", Icon = "shopping-cart" })
local BuyGB = TabBuy:AddLeftGroupbox("Base Purchases")
TR.AutoBuyFloor = {
    en = "Buys the next floor (up to 15).",
    ru = "Покупает следующий этаж (до 15)." }
BuyGB:AddToggle("AutoBuyFloor", {
    Text = "Auto Buy Next Floor",
    Tooltip = T("AutoBuyFloor"),
    Default = def("AutoBuyFloor", false),
    Callback = function(v) S.AutoBuyFloor = v end,
})
TR.AutoBuyTunnel = {
    en = "Buys missing tunnels on owned floors.",
    ru = "Покупает недостающие тоннели на купленных этажах." }
BuyGB:AddToggle("AutoBuyTunnel", {
    Text = "Auto Buy Tunnels",
    Tooltip = T("AutoBuyTunnel"),
    Default = def("AutoBuyTunnel", false),
    Callback = function(v) S.AutoBuyTunnel = v end,
})
TR.AutoFuserBuy = {
    en = "Buys the Fuser for $100B.",
    ru = "Покупает Фьюзер за $100B." }
BuyGB:AddToggle("AutoFuserBuy", {
    Text = "Auto Buy Fuser ($100B)",
    Tooltip = T("AutoFuserBuy"),
    Default = def("AutoFuserBuy", false),
    Callback = function(v)
        S.AutoFuserBuy = v
        if not v then purgeQueue("buyFuser") end
    end,
})
TR.AutoFuserRun = {
    en = "Loads 5 ores into the Fuser, starts fusion, claims the result.",
    ru = "Загружает 5 руд в фьюзер, запускает сплавку, забирает результат." }
BuyGB:AddToggle("AutoFuserRun", {
    Text = "Auto Run Fuser",
    Tooltip = T("AutoFuserRun"),
    Default = def("AutoFuserRun", false),
    Callback = function(v)
        S.AutoFuserRun = v
        if not v then
            purgeQueue("fuserLoad")
            purgeQueue("fuserClaim")
        end
    end,
})
TR.AutoFuserSkip = {
    en = "Instantly finishes fusion with Fuser Skip items.",
    ru = "Мгновенно завершает сплавку предметами Fuser Skip." }
BuyGB:AddToggle("AutoFuserSkip", {
    Text = "Auto Fuser Skip",
    Tooltip = T("AutoFuserSkip"),
    Default = def("AutoFuserSkip", false),
    Callback = function(v) S.AutoFuserSkip = v end,
})
TR.AutoGear = {
    en = "Buys selected gear.",
    ru = "Покупает выбранные гиры." }
local GearGB = TabBuy:AddRightGroupbox("Shop")
GearGB:AddToggle("AutoGear", {
    Text = "Auto Buy Gear",
    Tooltip = T("AutoGear"),
    Default = def("AutoGear", false),
    Callback = function(v) S.AutoGear = v end,
})
TR.GearToBuyMulti = {
    en = "Gear items to buy. Cheapest first.",
    ru = "Какие предметы покупать. Сначала дешёвые." }
local GEAR_VALUES = (function()
    local vals = {}
    for _, g in ipairs(GEAR_LIST) do
        table.insert(vals, g.Id .. " (" .. fmtShort(g.Price) .. ")")
    end
    return vals
end)()
GearGB:AddDropdown("GearToBuyMulti", {
    Text = "Gear to Buy",
    Tooltip = T("GearToBuyMulti"),
    Multi = true,
    Values = GEAR_VALUES,
    Default = defMulti("GearToBuyMulti", GEAR_VALUES),
    Callback = function(v) S.GearToBuyMulti = v end,
})
TR.BuyLuckyBlock = {
    en = "Buys Lucky Blocks.",
    ru = "Покупает Лаки Блоки." }
GearGB:AddToggle("BuyLuckyBlock", {
    Text = "Auto Buy Lucky Blocks",
    Tooltip = T("BuyLuckyBlock"),
    Default = def("BuyLuckyBlock", false),
    Callback = function(v) S.BuyLuckyBlock = v end,
})
TR.LuckyBlockRarity = {
    en = "Lucky block rarities to buy/open.",
    ru = "Редкости лаки блоков для покупки/открытия." }
local LUCKY_VALUES = (function()
    local vals = {}
    for _, r in ipairs(LUCKY_BLOCK_LIST) do
        local _, price = luckyBlockInfo(r)
        if price then
            table.insert(vals, r .. " (" .. fmtShort(price) .. ")")
        else
            table.insert(vals, r)
        end
    end
    return vals
end)()
GearGB:AddDropdown("LuckyBlockRarity", {
    Text = "Lucky Block Rarity",
    Tooltip = T("LuckyBlockRarity"),
    Multi = true,
    Values = LUCKY_VALUES,
    Default = defMulti("LuckyBlockRarity", LUCKY_VALUES),
    Callback = function(v) S.LuckyBlockRarity = v end,
})
local TabPets = Win:AddTab({ Name = "Pets", Icon = "paw-print" })
local PetsGB = TabPets:AddLeftGroupbox("Pets")
TR.AutoEquipPets = {
    en = "Places pets on floors (one per floor) and swaps weak ones for better ones from inventory.",
    ru = "Ставит петов на этажи (по одному на этаж) и заменяет слабых лучшими из инвентаря." }
PetsGB:AddToggle("AutoEquipPets", {
    Text = "Auto Equip Pets",
    Tooltip = T("AutoEquipPets"),
    Default = def("AutoEquipPets", false),
    Callback = function(v) S.AutoEquipPets = v end,
})
TR.AutoLuckySpin = {
    en = "Spins the lucky wheel when a free spin is available.",
    ru = "Крутит колесо удачи, когда есть бесплатный спин." }
local SpinGB = TabPets:AddRightGroupbox("Lucky")
SpinGB:AddToggle("AutoLuckySpin", {
    Text = "Auto Lucky Spin",
    Tooltip = T("AutoLuckySpin"),
    Default = def("AutoLuckySpin", false),
    Callback = function(v)
        S.AutoLuckySpin = v
        if not v then purgeQueue("spin") end
    end,
})
TR.AutoLuckyBlock = {
    en = "Opens Lucky Blocks from inventory.",
    ru = "Открывает Лаки Блоки из инвентаря." }
SpinGB:AddToggle("AutoLuckyBlock", {
    Text = "Auto Open Lucky Blocks",
    Tooltip = T("AutoLuckyBlock"),
    Default = def("AutoLuckyBlock", false),
    Callback = function(v) S.AutoLuckyBlock = v end,
})
TR.AutoGroupReward = {
    en = "Claims the Roblox group reward once.",
    ru = "Забирает награду за вступление в группу один раз." }
SpinGB:AddToggle("AutoGroupReward", {
    Text = "Auto Group Reward",
    Tooltip = T("AutoGroupReward"),
    Default = def("AutoGroupReward", false),
    Callback = function(v) S.AutoGroupReward = v end,
})
local TabRew = Win:AddTab({ Name = "Rewards", Icon = "gift" })
local DailyGB = TabRew:AddLeftGroupbox("Rewards")
TR.AutoClaimDaily = {
    en = "Claims the daily reward.",
    ru = "Забирает ежедневную награду." }
DailyGB:AddToggle("AutoClaimDaily", {
    Text = "Auto Daily Rewards",
    Tooltip = T("AutoClaimDaily"),
    Default = def("AutoClaimDaily", false),
    Callback = function(v) S.AutoClaimDaily = v end,
})
TR.AutoClaimPlaytime = {
    en = "Claims playtime rewards as they unlock.",
    ru = "Забирает награды за время игры по мере открытия." }
DailyGB:AddToggle("AutoClaimPlaytime", {
    Text = "Auto Playtime Rewards",
    Tooltip = T("AutoClaimPlaytime"),
    Default = def("AutoClaimPlaytime", false),
    Callback = function(v) S.AutoClaimPlaytime = v end,
})
TR.AutoClaimOffline = {
    en = "Claims offline earnings on join.",
    ru = "Забирает оффлайн-доход при заходе." }
DailyGB:AddToggle("AutoClaimOffline", {
    Text = "Auto Offline Earnings",
    Tooltip = T("AutoClaimOffline"),
    Default = def("AutoClaimOffline", false),
    Callback = function(v) S.AutoClaimOffline = v end,
})
local SkipGB = TabRew:AddRightGroupbox("Time Skips")
TR.AutoTimeSkip = {
    en = "Uses Time Skip items for instant income.",
    ru = "Использует предметы Time Skip для мгновенного дохода." }
SkipGB:AddToggle("AutoTimeSkip", {
    Text = "Auto Use Time Skips",
    Tooltip = T("AutoTimeSkip"),
    Default = def("AutoTimeSkip", false),
    Callback = function(v) S.AutoTimeSkip = v end,
})
TR.MinTimeSkip = {
    en = "Only use skips of at least this size.",
    ru = "Тратить только скипы от этого размера." }
SkipGB:AddDropdown("MinTimeSkip", {
    Text = "Min Time Skip Size",
    Tooltip = T("MinTimeSkip"),
    Values = { "Any", "30 min+", "2h+", "6h+", "12h+" },
    Default = def("MinTimeSkip", "Any"),
    Callback = function(v) S.MinTimeSkip = v end,
})
local TabMisc = Win:AddTab({ Name = "Misc", Icon = "settings" })
local EspGB = TabMisc:AddLeftGroupbox("ESP")
TR.OreESP = {
    en = "Highlights ores through walls.",
    ru = "Подсвечивает руду сквозь стены." }
EspGB:AddToggle("OreESP", {
    Text = "Ore ESP",
    Tooltip = T("OreESP"),
    Default = def("OreESP", false),
    Callback = function(v)
        S.OreESP = v
        if not v then
            for _, obj in pairs(Workspace:GetDescendants()) do
                local hl = obj:FindFirstChild("AscendESP")
                if hl then hl:Destroy() end
            end
        end
    end,
})
TR.CrateESP = {
    en = "Highlights ore crates through walls.",
    ru = "Подсвечивает ящики руды сквозь стены." }
EspGB:AddToggle("CrateESP", {
    Text = "Crate ESP",
    Tooltip = T("CrateESP"),
    Default = def("CrateESP", false),
    Callback = function(v)
        S.CrateESP = v
        if not v then
            for _, obj in pairs(Workspace:GetDescendants()) do
                local hl = obj:FindFirstChild("AscendCrateESP")
                if hl then hl:Destroy() end
            end
        end
    end,
})
local PlayerGB = TabMisc:AddRightGroupbox("Player")
TR.Noclip = {
    en = "Walk through walls.",
    ru = "Ходить сквозь стены." }
PlayerGB:AddToggle("Noclip", {
    Text = "Noclip",
    Tooltip = T("Noclip"),
    Default = def("Noclip", false),
    Callback = function(v) S.Noclip = v end,
})
TR.WalkSpeed = {
    en = "Character walk speed.",
    ru = "Скорость персонажа." }
PlayerGB:AddSlider("WalkSpeed", {
    Text = "Walk Speed",
    Tooltip = T("WalkSpeed"),
    Default = def("WalkSpeed", 16),
    Min = 16, Max = 200, Rounding = 0,
    Callback = function(v)
        S.WalkSpeed = v
        pcall(function()
            local hum = plr.Character and plr.Character:FindFirstChildOfClass("Humanoid")
            if hum then hum.WalkSpeed = v end
        end)
    end,
})
TR.JumpPower = {
    en = "Character jump power.",
    ru = "Сила прыжка персонажа." }
PlayerGB:AddSlider("JumpPower", {
    Text = "Jump Power",
    Tooltip = T("JumpPower"),
    Default = def("JumpPower", 50),
    Min = 50, Max = 300, Rounding = 0,
    Callback = function(v)
        S.JumpPower = v
        pcall(function()
            local hum = plr.Character and plr.Character:FindFirstChildOfClass("Humanoid")
            if hum then hum.JumpPower = v end
        end)
    end,
})
task.spawn(function()
    while isAlive() and task.wait(0.15) do
        if S.AutoRoll then
            local base = getMyBase()
            local roller = base and base:FindFirstChild("Roller")
            local lever = roller and roller:FindFirstChild("Lever")
            local prompt = lever and lever:FindFirstChildWhichIsA("ProximityPrompt", true)
            if prompt then
                if pendingBuyOre then
                    if (os.clock() - (rollGateLoggedAt or 0)) > 5 then
                        rollGateLoggedAt = os.clock()
                    end
                elseif prompt.Enabled and fireproximityprompt then
                    runNow("roll", math.max(0.1, tonumber(S.RollDelay) or 0.5), function()
                        firePrompt(prompt, false, true)
                    end)
                else
                    tryEnqueue("rollTP", 2, function()
                        local h = getPromptHolder(prompt)
                        if not h or not prompt.Parent or pendingBuyOre then return end
                        if forceTP(h.CFrame * CFrame.new(0, 3.5, 0)) then
                            task.wait(0.2)
                            wakePrompt(prompt)
                            firePromptVerified(prompt, false, nil, 2)
                        end
                    end, function()
                        return S.AutoRoll and not pendingBuyOre
                    end)
                end
            end
        end
    end
end)
end
for key, e in pairs(TR) do
    if type(e) == "table" then
        if e.en then I18N.KEY[e.en] = key end
        if e.ru then I18N.KEY[e.ru] = key end
    end
end
for _, gb in ipairs(I18N.GBS) do
    for _, el in ipairs(gb.Elements or {}) do
        if el.Type == "Toggle" and el.TextLabel then
            el.TextLabel.ClipsDescendants = true
        end
    end
end
I18N.REP = function()
    for _, rec in ipairs(I18N.LIVE) do
        local key = I18N.KEY[rec.info]
        if key then
            local newInfo = T(key)
            if newInfo ~= rec.info then
                local oldTT, wasDisabled = rec.tt, rec.tt and rec.tt.Disabled
                rec.info = newInfo
                if oldTT then pcall(oldTT.Destroy, oldTT) end
                rec.tt = I18N.RAW(Library, newInfo, rec.disabled, rec.hover)
                if rec.tt and wasDisabled ~= nil then
                    rec.tt.Disabled = wasDisabled
                end
                for _, gb in ipairs(I18N.GBS) do
                    for _, el in ipairs(gb.Elements or {}) do
                        if el.TooltipTable == oldTT then
                            el.TooltipTable = rec.tt
                        end
                    end
                end
            end
        end
    end
end
local floorLockedAt = {}
local LOCK_TTL = 60
local function upgradeJob(tag, remote, infoFn)
    local base = getMyBase()
    if not base then return end
    local skipFloors = {}
    local now = os.clock()
    local cached = floorLockedAt[tag]
    if cached then
        for fl, ts in pairs(cached) do
            if now - ts < LOCK_TTL then
                skipFloors[fl] = true
            else
                cached[fl] = nil
            end
        end
    end
    local floor, lvl, price = cheapestFloorUpgrade(infoFn, skipFloors)
    if not floor then
        if next(skipFloors) then
        else
        end
        return
    end
    if not canSpend(tag, price) then return end
    local res = safeInvoke(remote, base.Name, floor)
    if type(res) == "table" and res.success == false then
        local reason = tostring(res.result or res.reason or "?")
        if reason:find("FloorLocked", 1, true) or reason:find("Locked", 1, true) then
            if not floorLockedAt[tag] then floorLockedAt[tag] = {} end
            floorLockedAt[tag][floor] = now
            markFloorLocked(floor)
        else
        end
    elseif type(res) == "table" and res.success == true then
        if floorLockedAt[tag] then floorLockedAt[tag][floor] = nil end
    end
end
local function upgDelay()
    return math.max(0.15, tonumber(S.UpgradeDelay) or 1)
end
task.spawn(function()
    while isAlive() and task.wait(0.25) do
        if S.AutoDrillSpeed then
            runNow("drillSpeed", upgDelay(), function()
                upgradeJob("drillSpeed", "BaseUpgradeDrillSpeed", drillSpeedInfo)
            end)
        end
    end
end)
task.spawn(function()
    while isAlive() and task.wait(0.25) do
        if S.AutoDrillYield then
            runNow("drillYield", upgDelay(), function()
                upgradeJob("drillYield", "BaseUpgradeDrillYield", drillYieldInfo)
            end)
        end
    end
end)
task.spawn(function()
    while isAlive() and task.wait(0.25) do
        if S.AutoOreRegen then
            runNow("oreRegen", upgDelay(), function()
                upgradeJob("oreRegen", "BaseUpgradeOreRegenSpeed", oreRegenInfo)
            end)
        end
    end
end)
task.spawn(function()
    while isAlive() and task.wait(0.4) do
        if S.AutoPedestal then
            runNow("pedUp", upgDelay(), function()
                local base = getMyBase()
                if not base then return end
                local lvl, price = pedestalInfo()
                if not price then
                    return
                end
                if not canSpend("pedestal", price) then return end
                safeInvoke("RollerUpgradePedestal", base.Name)
            end)
        end
    end
end)
task.spawn(function()
    while isAlive() and task.wait(0.4) do
        if S.AutoOreLuck then
            runNow("luck", upgDelay(), function()
                local base = getMyBase()
                if not base then return end
                local lvl, price = oreLuckInfo()
                if not canSpend("oreLuck", price) then return end
                safeInvoke("RollerUpgradeOreLuck", base.Name)
            end)
        end
    end
end)
task.spawn(function()
    while isAlive() and task.wait(0.2) do
        if S.AutoMoneyBoost then
            runNow("boostOn", 0.5, serviceBoostActivate)
        end
    end
end)
task.spawn(function()
    while isAlive() and task.wait(2) do
        if S.AutoBuyShowcasePedestal then
            runNow("boostBuy", 3, serviceBuyShowcasePedestal)
        end
    end
end)
task.spawn(function()
    while isAlive() and task.wait(0.25) do
        if boostSwapEnabled() and anySwapPending() then
            tryEnqueue("boostSwap", 1, serviceBoostSwap, boostSwapEnabled)
        end
    end
end)
task.spawn(function()
    while isAlive() and task.wait(0.4) do
        if S.AutoEquipBest then
            runNow("equipBest", math.max(0.5, tonumber(S.EquipDelay) or 1), function()
                local base = getMyBase()
                if not base then
                    return
                end
                if S.AutoMoneyBoost then
                    local best = bestBoostOre()
                    if best then
                        for i = 1, BOOST_SLOTS do
                            if showcaseUnlocked(i) and swapNeeded(i) then
                                local curMult = oreShowcaseMult(showcaseOreName(i))
                                if best.mult > curMult then
                                    return
                                end
                            end
                        end
                    end
                end
                if not S.SmartEquipBest then
                    safeInvoke("BaseBuildTunnelAction", base.Name, 1, "Tunnel1", "EquipBest")
                    return
                end
                local cands = listOreCandidates()
                if not cands[1] or not cands[1].ceiling then
                    safeInvoke("BaseBuildTunnelAction", base.Name, 1, "Tunnel1", "EquipBest")
                    return
                end
                table.sort(cands, function(a, b)
                    local ca, cb = a.ceiling or -1, b.ceiling or -1
                    if ca ~= cb then return ca > cb end
                    return (a.lvl or 0) > (b.lvl or 0)
                end)
                local bestC = cands[1]
                local bestCeil = bestC.ceiling or -1
                local acted = false
                if S.AutoMoneyBoost then
                    for i = 1, BOOST_SLOTS do
                        if showcaseUnlocked(i) and swapNeeded(i) then
                            local curMult = oreShowcaseMult(showcaseOreName(i))
                            if bestC.mult and bestC.mult > curMult then
                                acted = true
                                break
                            end
                        end
                    end
                    if acted then return end
                end
                local seenTun = forEachTunnel(base, function(floor, tn)
                    local ore, lvl = tunnelOreInfo(floor, tn)
                    if not ore then return end
                    local curMut = tunnelMutationName(floor, tn)
                    local curCeil = oreCeiling(ore, curMut)
                    local curPot = orePotency(ore, lvl, curMut)
                    local newPot = orePotency(bestC.name, bestC.lvl, bestC.mut)
                    local why
                    if curCeil == nil then
                        why = "текущая руда не опознана"
                    elseif bestCeil > curCeil * 1.05 then
                        why = "потолок выше"
                    elseif bestCeil >= curCeil and newPot and curPot
                        and newPot > curPot * 1.05 then
                        why = "тот же класс, но уровень тула выше"
                    end
                    if not why then return end
                    if removeTunnelOre(base.Name, floor, tn) then
                        equipTunnelOre(base.Name, floor, tn, bestC)
                    end
                    acted = true
                    return true
                end)
                if seenTun == 0 then
                    return
                end
                if acted then return end
                forEachTunnel(base, function(floor, tn)
                    if not isTunnelOpen(floor, tn) then return end
                    if tunnelOreInfo(floor, tn) then return end
                    equipTunnelOre(base.Name, floor, tn, bestC)
                    acted = true
                    return true
                end)
            end)
        end
    end
end)
task.spawn(function()
    while isAlive() and task.wait(2) do
        if S.AutoTrash then
            runNow("trash", 3, function()
                local base = getMyBase()
                local bin = base and base:FindFirstChild("TrashBin")
                if not bin then
                    return
                end
                local prompt = bin:FindFirstChildWhichIsA("ProximityPrompt", true)
                if not prompt then
                    return
                end
                local holder = getPromptHolder(prompt)
                local part = holder or bin:FindFirstChildWhichIsA("BasePart", true)
                local cands = listOreCandidates()
                if #cands == 0 then return end
                local rarityCap = ORE_RANK[S.TrashMaxRarity] or 1
                if rarityCap <= 1 then
                    return
                end
                local emptyNeed = 0
                forEachTunnel(base, function(floor, tn)
                    if isTunnelOpen(floor, tn) and not tunnelOreInfo(floor, tn) then
                        emptyNeed = emptyNeed + 1
                    end
                end)
                table.sort(cands, function(a, b)
                    return (a.ceiling or -1) > (b.ceiling or -1)
                end)
                local keep = emptyNeed + 1
                for i = #cands, keep + 1, -1 do
                    local c = cands[i]
                    local oreRarity = nil
                    if OreMetadata and OreMetadata.GetOre then
                        local okR, ore = pcall(OreMetadata.GetOre, c.name)
                        if okR and type(ore) == "table" then oreRarity = ORE_RANK[ore.rarity] end
                    end
                    if oreRarity ~= nil and oreRarity < rarityCap then
                        if equipOreTool(c.tool) then
                            if forceTP(part.CFrame * CFrame.new(0, 3, 0)) then
                                task.wait(0.3)
                                wakePrompt(prompt)
                                local ok = firePromptVerified(prompt, true,
                                    function() return true end, 2)
                            else
                            end
                        else
                        end
                        return
                    end
                end
            end)
        end
    end
end)
task.spawn(function()
    local floorFailAt = {}
    while isAlive() and task.wait(1) do
        if S.AutoBuyFloor then
            runNow("floor", 2, function()
                local base = getMyBase()
                if not base then return end
                local owned = maxFloorOwned()
                if owned >= 15 then
                    return
                end
                local nextFloor = owned + 1
                if floorFailAt[nextFloor] and os.clock() - floorFailAt[nextFloor] < LOCK_TTL then
                    return
                end
                local nextPrice = floorPrice(nextFloor)
                if not canSpend("floor", nextPrice) then return end
                local res = safeInvoke("BaseBuildPurchaseFloor", base.Name, nextFloor)
                if type(res) == "table" then
                    if res.success == true then
                        markFloorOwned(nextFloor)
                    else
                        local why = tostring(res.result or res.reason or "?")
                        floorFailAt[nextFloor] = os.clock()
                        if why:find("FloorLocked", 1, true) then
                            markFloorLocked(nextFloor)
                        end
                    end
                end
                floorPriceCache = {}
            end)
        end
    end
end)
local tunnelFailedAt = {}
task.spawn(function()
    while isAlive() and task.wait(1) do
        if S.AutoBuyTunnel and not spendingBlocked() then
            runNow("tunnel", 2, function()
                local base = getMyBase()
                if not base then return end
                local now = os.clock()
                local did = false
                local ownedMax = maxFloorOwned()
                local seen = forEachTunnel(base, function(floor, tn, tunnelModel)
                    if floor > ownedMax then return end
                    if isTunnelOpen(floor, tn) then return end
                    local key = floor .. ":" .. tn
                    if tunnelFailedAt[key] and now - tunnelFailedAt[key] < LOCK_TTL then
                        return
                    end
                    local pm = tunnelModel and tunnelModel:FindFirstChild("PurchaseModel")
                    local price = pm and tonumber(pm:GetAttribute("PurchasePrice")) or nil
                    if price and price > 0 and price > getMoney() then
                        return
                    end
                    local res = safeInvoke("BaseBuildPurchaseTunnel", base.Name, floor, tn)
                    if type(res) == "table" and res.success == false then
                        local reason = tostring(res.result or res.reason or "?")
                        tunnelFailedAt[key] = now
                    end
                    did = true
                    return true
                end)
                if seen == 0 then
                elseif not did then
                end
            end)
        end
    end
end)
task.spawn(function()
    while isAlive() and task.wait(1) do
        if S.AutoFuserBuy or S.AutoFuserRun then
            local base = getMyBase()
            if base then
                local fuser = base:FindFirstChild("Fuser")
                if fuser then
                    local purchased = fuser:GetAttribute("FuserPurchased") == true
                    if S.AutoFuserBuy and not purchased then
                        tryEnqueue("buyFuser", 5, function()
                            if not S.AutoFuserBuy then return end
                            local b = getMyBase()
                            if not b then return end
                            local f = b:FindFirstChild("Fuser")
                            if not f then return end
                            if f:GetAttribute("FuserPurchased") == true then return end
                            local prompt = f:FindFirstChild("PurchaseFuserPrompt", true)
                            if not prompt then return end
                            if getMoney() < FUSER_BUY_PRICE then
                                return
                            end
                            wakePrompt(prompt)
                            firePrompt(prompt, true)
                        end, function() return S.AutoFuserBuy end)
                    end
                    if S.AutoFuserRun and purchased then
                        local phase = fuser:GetAttribute("FuserPhase")
                        if phase == "Ready" then
                            tryEnqueue("fuserClaim", 3, function()
                                if not S.AutoFuserRun then return end
                                local b2 = getMyBase()
                                local f2 = b2 and b2:FindFirstChild("Fuser")
                                if not f2 then return end
                                if f2:GetAttribute("FuserPhase") ~= "Ready" then return end
                                local prompt = f2:FindFirstChild("ClaimMegaOrePrompt", true)
                                if not prompt then return end
                                wakePrompt(prompt)
                                firePrompt(prompt, true)
                            end, function() return S.AutoFuserRun end)
                        elseif phase == "Fusing" then
                        elseif phase == "Loading" then
                            local fmodel = fuser:FindFirstChild("FuserModel")
                            local nodes = fmodel and fmodel:FindFirstChild("Nodes")
                            if nodes then
                                local empty = {}
                                for _, node in ipairs(nodes:GetChildren()) do
                                    if node.Name:match("^Node_")
                                        and not node:FindFirstChild("FuserNodeOre", true) then
                                        empty[#empty + 1] = node
                                    end
                                end
                                if #empty > 0 then
                                    local curName = nil
                                    for _, node in ipairs(nodes:GetChildren()) do
                                        local vo = node:FindFirstChild("FuserNodeOre", true)
                                        if vo then
                                            curName = vo:GetAttribute("OreName")
                                                or vo:GetAttribute("OreType")
                                            if type(curName) == "string" and curName ~= "" then
                                                break
                                            end
                                            curName = nil
                                        end
                                    end
                                    local need = #empty
                                    if curName then
                                        need = need - 1
                                    end
                                    local oreName, oreTool = nil, nil
                                    local bestCeil = -1
                                    local counts = {}
                                    local toolOf = {}
                                    local function scanTools(parent)
                                        if not parent then return end
                                        for _, t in ipairs(parent:GetChildren()) do
                                            if t:IsA("Tool")
                                                and t:GetAttribute("ToolType") == "Ore" then
                                                local nm = t:GetAttribute("OreName")
                                                if type(nm) == "string" and nm ~= "" then
                                                    local q = math.max(1, math.floor(tonumber(
                                                        t:GetAttribute("Quantity")
                                                        or t:GetAttribute("StackCount")) or 1))
                                                    counts[nm] = (counts[nm] or 0) + q
                                                    if not toolOf[nm] then toolOf[nm] = t end
                                                end
                                            end
                                        end
                                    end
                                    scanTools(plr:FindFirstChild("Backpack"))
                                    scanTools(plr.Character)
                                    if curName then
                                        local cnt = counts[curName] or 0
                                        if cnt >= need then
                                            oreName = curName
                                            oreTool = toolOf[curName]
                                        else
                                        end
                                    end
                                    if not oreName and not curName then
                                        for nm, cnt in pairs(counts) do
                                            if cnt >= need then
                                                local ceil = oreCeiling(nm)
                                                if not ceil or ceil > bestCeil then
                                                    bestCeil = ceil or 0
                                                    oreName = nm
                                                    oreTool = toolOf[nm]
                                                end
                                            end
                                        end
                                    end
                                    if oreName then
                                        local targetName = empty[1].Name
                                        tryEnqueue("fuserLoad", 2, function()
                                            if not S.AutoFuserRun then return end
                                            local b3 = getMyBase()
                                            local f3 = b3 and b3:FindFirstChild("Fuser")
                                            if not f3 then return end
                                            if f3:GetAttribute("FuserPhase") ~= "Loading" then return end
                                            local m3 = f3:FindFirstChild("FuserModel")
                                            local n3 = m3 and m3:FindFirstChild("Nodes")
                                            local node = n3 and n3:FindFirstChild(targetName)
                                            if not node then return end
                                            if node:FindFirstChild("FuserNodeOre", true) then return end
                                            local holder = node:FindFirstChild("OrePlaceholder")
                                            local prompt = holder
                                                and holder:FindFirstChildWhichIsA("ProximityPrompt", true)
                                            if not prompt then return end
                                            if not equipOreTool(oreTool) then
                                                return
                                            end
                                            wakePrompt(prompt)
                                            firePrompt(prompt, true)
                                        end, function() return S.AutoFuserRun end)
                                    elseif not curName then
                                    end
                                else
                                    runNow("fuser", 1, function()
                                        local b4 = getMyBase()
                                        if not b4 then return end
                                        local f4 = b4:FindFirstChild("Fuser")
                                        if not f4 then return end
                                        local phase = f4:GetAttribute("FuserPhase")
                                        if phase ~= "Loading" then
                                            return
                                        end
                                        local res = safeInvoke("FuserAction", b4.Name, "StartFusion")
                                        if type(res) == "table" then
                                            if res.success then
                                            else
                                            end
                                        else
                                        end
                                    end)
                                end
                            end
                        end
                    end
                end
            end
        end
    end
end)
task.spawn(function()
    while isAlive() and task.wait(3) do
        if S.AutoLuckySpin then
            local function doSpin()
                local shops = Workspace:FindFirstChild("PhysicalShops")
                local wheel = shops and shops:FindFirstChild("LuckySpinWheel")
                if not wheel then
                    return
                end
                local state = safeInvoke("GetLuckySpinState")
                if type(state) ~= "table" then
                    return
                end
                local remaining = tonumber(state.remaining) or 0
                local spins = tonumber(state.spins) or 0
                if remaining > 0 and spins <= 0 then
                    return
                end
                local part = wheel:FindFirstChildWhichIsA("BasePart", true)
                    or (wheel:FindFirstChild("Spinner") and wheel.Spinner:FindFirstChildWhichIsA("BasePart", true))
                if not part or not forceTP(part.CFrame * CFrame.new(0, 3, 0)) then
                    return
                end
                local res = safeInvoke("RequestLuckySpin")
                local spinId = type(res) == "table" and (res.spinId or res.id) or nil
                if spinId then
                    task.wait(1)
                    safeInvoke("CompleteLuckySpin", spinId)
                else
                end
            end
            tryEnqueue("spin", 10, doSpin, function() return S.AutoLuckySpin end)
        end
    end
end)
local function pedOreName(ped)
    if not ped then return "" end
    local n = ped:GetAttribute("OreName")
    if type(n) == "string" and n ~= "" then return n end
    for _, d in ipairs(ped:GetDescendants()) do
        local a = d:GetAttribute("OreName") or d:GetAttribute("OreType")
        if type(a) == "string" and a ~= "" then return a end
    end
    return ""
end
task.spawn(function()
    while isAlive() and task.wait(0.5) do
        if S.AutoBuyPedestal then
            pcall(function()
                if pendingBuyOre then return end
                local base = getMyBase()
                local peds = base and base:FindFirstChild("OrePedestals")
                if not peds then return end
                local minRank = ORE_RANK[S.PedestalMinRarity] or 5
                for _, ped in ipairs(peds:GetChildren()) do
                    if ped.Name:match("^RolledOrePedestal") then
                        local oreName = pedOreName(ped)
                        if oreName ~= "" then
                            local rarity, price = nil, nil
                            if OreMetadata and OreMetadata.GetOre then
                                local ok, ore = pcall(OreMetadata.GetOre, oreName)
                                if ok and type(ore) == "table" then
                                    rarity = ore.rarity
                                    if type(ore.seedCost) == "number" then price = ore.seedCost end
                                end
                            end
                            if rarity and ORE_RANK[rarity] and ORE_RANK[rarity] >= minRank
                                and (not price or canAffordSoon(price) ~= "no") then
                                pendingBuyOre = oreName
                                break
                            end
                        end
                    end
                end
            end)
            local function handlePed(ped)
                local lrod = ped:FindFirstChild("LocalRollingOreDisplay")
                if lrod and lrod:GetAttribute("PurchaseRequestPending") == true then
                    return
                end
                local oreName = pedOreName(ped)
                if oreName == "" then
                    return
                end
                local rarity = nil
                if OreMetadata and OreMetadata.GetOre then
                    local ok, ore = pcall(OreMetadata.GetOre, oreName)
                    if ok and type(ore) == "table" then rarity = ore.rarity end
                end
                local minRank = ORE_RANK[S.PedestalMinRarity] or 5
                if not (rarity and ORE_RANK[rarity] and ORE_RANK[rarity] >= minRank) then
                    return
                end
                local price = nil
                if OreMetadata and OreMetadata.GetOre then
                    local okP, ore = pcall(OreMetadata.GetOre, oreName)
                    if okP and type(ore) == "table" and type(ore.seedCost) == "number" then
                        price = ore.seedCost
                    end
                end
                local verdict = price and canAffordSoon(price) or "yes"
                if verdict == "no" then
                    return
                end
                if verdict == "soon" then
                    startSaving(oreName, price)
                    pendingBuyOre = oreName
                    return
                end
                pendingBuyOre = oreName
                local prompt = ped:FindFirstChild("PurchaseOrePrompt", true)
                    or ped:FindFirstChildWhichIsA("ProximityPrompt", true)
                local holder = prompt and getPromptHolder(prompt)
                local part = holder or ped:FindFirstChildWhichIsA("BasePart", true)
                if not part then
                    return
                end
                if not forceTP(part.CFrame * CFrame.new(0, 3, 0)) then
                    return
                end
                task.wait(0.35)
                if lrod and lrod:GetAttribute("PurchasePromptReady") ~= true then
                    pcall(function() lrod:SetAttribute("PurchasePromptReady", true) end)
                end
                wakePrompt(prompt)
                if prompt then
                    local ok2 = firePromptVerified(prompt, false, function()
                        return pedOreName(ped) ~= oreName
                    end, 3, true)
                    if not ok2 then
                        safeFire("RollerPurchaseEvent", ped.Name, oreName)
                        task.wait(0.6)
                        ok2 = pedOreName(ped) ~= oreName
                    end
                else
                    safeFire("RollerPurchaseEvent", ped.Name, oreName)
                end
                task.wait(0.4)
                if savingOre() == oreName and pedOreName(ped) ~= oreName then
                    stopSaving("куплено: " .. oreName)
                end
                if pendingBuyOre == oreName and pedOreName(ped) ~= oreName then
                    pendingBuyOre = nil
                end
            end
            local function buyRounds()
                local base = getMyBase()
                local pedCount = tonumber(plr:GetAttribute("NumberOfRollingPedestals")) or 0
                if pedCount <= 0 then
                    return
                end
                local pedestals = base and base:FindFirstChild("OrePedestals")
                if not pedestals then
                    return
                end
                local want = savingOre()
                local stillThere = false
                for _, ped in ipairs(pedestals:GetChildren()) do
                    if ped.Name:match("^RolledOrePedestal") then
                        if want and pedOreName(ped) == want then stillThere = true end
                        handlePed(ped)
                    end
                end
                if want and not stillThere then
                    stopSaving("руда " .. want .. " пропала с пьедестала")
                end
                if pendingBuyOre then
                    local stillHere = false
                    for _, ped in ipairs(pedestals:GetChildren()) do
                        if ped.Name:match("^RolledOrePedestal")
                            and pedOreName(ped) == pendingBuyOre then
                            stillHere = true
                            break
                        end
                    end
                    if not stillHere then
                        pendingBuyOre = nil
                    end
                end
            end
            tryEnqueue("buyPed", 1.5, buyRounds, function() return S.AutoBuyPedestal end)
        end
    end
end)
task.spawn(function()
    while isAlive() and task.wait(1) do
        if S.AutoLuckyBlock or S.BuyLuckyBlock then
            runNow("lucky", 3, function()
                local rawList = multiList("LuckyBlockRarity")
                local list = {}
                for _, v in ipairs(rawList) do table.insert(list, stripPrice(v)) end
                if #list == 0 then
                    return
                end
                for _, rarity in ipairs(list) do
                    local id, price = luckyBlockInfo(rarity)
                    if S.AutoLuckyBlock then
                        local res = safeInvoke("LuckyBlockOpenRequest", id)
                        if type(res) == "table" and res.success == true and res.token then
                            safeFire("LuckyBlockClaimReward", res.token)
                        end
                    end
                    if S.BuyLuckyBlock and canSpend("luckyBlock:" .. rarity, price) then
                        local res = safeInvoke("RequestLuckyBlockPurchase", id)
                    end
                end
            end)
        end
    end
end)
task.spawn(function()
    local placeBlockedUntil = 0
    while isAlive() and task.wait(2) do
        if S.AutoEquipPets then
            tryEnqueue("petsEquip", 2, function()
                local base = getMyBase()
                if not base then return end
                local function petScore(id)
                    if not PetMetadata or type(PetMetadata.GetPet) ~= "function" then
                        return 0, 0
                    end
                    local ok, info = pcall(PetMetadata.GetPet, id)
                    if not ok or type(info) ~= "table" then return 0, 0 end
                    local mult = tonumber(info.Multiplier) or 0
                    local rank = ORE_RANK[info.Rarity] or 0
                    return mult, rank
                end
                local inv = {}
                local function scanContainer(c)
                    if not c then return end
                    for _, t in ipairs(c:GetChildren()) do
                        if t:IsA("Tool") and t:GetAttribute("ToolType") == "Pet" then
                            local id = t:GetAttribute("PetId")
                            if type(id) == "string" and id ~= "" then
                                local m, r = petScore(id)
                                inv[#inv + 1] = { id = id, score = m, rank = r, tool = t }
                            end
                        end
                    end
                end
                scanContainer(plr:FindFirstChild("Backpack"))
                scanContainer(plr.Character)
                local function equipPetTool(tool)
                    if not tool or not tool.Parent then return false end
                    local ok = pcall(function()
                        local hum = plr.Character
                            and plr.Character:FindFirstChildOfClass("Humanoid")
                        if hum then hum:EquipTool(tool) end
                    end)
                    if ok then task.wait(0.15) end
                    return ok
                end
                local placed = {}
                local placedPerFloor = {}
                local placedFolder = base:FindFirstChild("PlacedPets")
                if placedFolder then
                    for _, m in ipairs(placedFolder:GetChildren()) do
                        if m:IsA("Model") then
                            local pid = m:GetAttribute("PlacementId")
                            local petId = m:GetAttribute("PetId")
                            if type(pid) == "string" and type(petId) == "string" then
                                local sc, rk = petScore(petId)
                                local fl = math.floor(tonumber(m:GetAttribute("FloorNumber")) or 0)
                                placedPerFloor[fl] = (placedPerFloor[fl] or 0) + 1
                                placed[#placed + 1] =
                                    { pid = pid, id = petId, score = sc, rank = rk,
                                        model = m, floor = fl }
                            end
                        end
                    end
                end
                local function floorWalkArea(floorNum)
                    local floors = base:FindFirstChild("Floors")
                    if not floors then return nil end
                    if floorNum == 1 then
                        local a = floors:FindFirstChild("Floor1WalkArea")
                            or floors:FindFirstChild("WalkArea")
                        return a and a:IsA("BasePart") and a or nil
                    end
                    local prev = floors:FindFirstChild("Floor" .. (floorNum - 1))
                    local nfp = prev and prev:FindFirstChild("NextFloorParts")
                    local wa = nfp and nfp:FindFirstChild("WalkArea")
                    return wa and wa:IsA("BasePart") and wa or nil
                end
                local ownedMax = maxFloorOwned()
                local function pickFloor()
                    for f = ownedMax, 1, -1 do
                        if (placedPerFloor[f] or 0) == 0 and floorWalkArea(f) then
                            return f
                        end
                    end
                    return nil
                end
                if #inv == 0 then
                    return
                end
                table.sort(inv, function(a, b)
                    if a.score ~= b.score then return a.score > b.score end
                    return a.rank > b.rank
                end)
                if #inv > 0 and os.clock() >= placeBlockedUntil then
                    local best = inv[1]
                    local targetFloor = pickFloor()
                    if targetFloor then
                        local anchor = floorWalkArea(targetFloor)
                        if anchor and anchor:IsA("BasePart") then
                            forceTP(anchor.CFrame * CFrame.new(0, 3, 0))
                            task.wait(0.2)
                        end
                        if best.tool and best.tool.Parent ~= plr.Character then
                            equipPetTool(best.tool)
                        end
                        local res = safeInvoke("RequestPetPlacement", best.id)
                        if type(res) == "table" then
                            if res.success == true then
                            elseif res.result == "FloorFull" then
                                placedPerFloor[targetFloor] = (placedPerFloor[targetFloor] or 0) + 1
                            elseif res.result ~= "TooFast" then
                            end
                        end
                        return
                    end
                end
                if #inv == 0 then return end
                local candidate = inv[1]
                table.sort(placed, function(a, b)
                    if a.score ~= b.score then return a.score < b.score end
                    return a.rank < b.rank
                end)
                local weakest = placed[1]
                if not weakest then return end
                local better = candidate.score > weakest.score
                    or (candidate.score == weakest.score and candidate.rank > weakest.rank)
                if not better then
                    return
                end
                local wModel = weakest.model
                local wPart = wModel and wModel:IsA("Model")
                    and wModel:FindFirstChildWhichIsA("BasePart", true)
                if wPart then
                    if not forceTP(wPart.CFrame * CFrame.new(0, 3, 0)) then
                        return
                    end
                    task.wait(0.2)
                end
                local res = safeInvoke("RequestPetPickup", weakest.pid)
                if type(res) == "table" and res.success == true then
                    task.wait(0.25)
                    local candidateTool = nil
                    for _, cont in ipairs({ plr:FindFirstChild("Backpack"), plr.Character }) do
                        if cont then
                            for _, tool in ipairs(cont:GetChildren()) do
                                if tool:IsA("Tool") and tool:GetAttribute("ToolId") == candidate.id
                                    or (tool:GetAttribute("PetId") == candidate.id) then
                                    candidateTool = tool
                                    break
                                end
                            end
                        end
                        if candidateTool then break end
                    end
                    if candidateTool and candidateTool.Parent ~= plr.Character then
                        equipPetTool(candidateTool)
                    end
                    local res2 = safeInvoke("RequestPetPlacement", candidate.id)
                    if type(res2) == "table" and res2.success == true then
                    else
                    end
                else
                end
            end, function() return S.AutoEquipPets end)
        end
    end
end)
task.spawn(function()
    pcall(function()
        local VirtualUser = game:GetService("VirtualUser")
        plr.Idled:Connect(function()
            VirtualUser:CaptureController()
            VirtualUser:ClickButton2(Vector2.new())
        end)
    end)
    while isAlive() and task.wait(30) do
        safeFire("AFKActivity")
    end
end)
task.spawn(function()
    local COATING_MUTATION = {
        RustCoating = "Rusty", FrostCoating = "Frozen",
        CrystalCoating = "Crystal", VoidCoating = "Void",
        AlienCoating = "Alien", GalaxyCoating = "Galaxy",
    }
    while isAlive() and task.wait(1) do
        if S.AutoMutation then
            runNow("mutation", 2, function()
                local base = getMyBase()
                if not base then return end
                local coatings = {}
                local containers = { plr:FindFirstChild("Backpack"), plr.Character }
                for _, cont in ipairs(containers) do
                    if cont then
                        for _, tool in ipairs(cont:GetChildren()) do
                            if tool:IsA("Tool") and tool:GetAttribute("ToolType") == "Gear" then
                                local gid = tool:GetAttribute("GearId")
                                if type(gid) == "string" and COATING_MUTATION[gid] then
                                    coatings[#coatings + 1] = {
                                        id = gid,
                                        mut = COATING_MUTATION[gid],
                                        mult = mutationMultOfName(COATING_MUTATION[gid]),
                                    }
                                end
                            end
                        end
                    end
                end
                if #coatings == 0 then
                    return
                end
                table.sort(coatings, function(a, b) return a.mult > b.mult end)
                local tunnels = {}
                forEachTunnel(base, function(floor, tn)
                    if not isTunnelOpen(floor, tn) then return end
                    local ore, lvl = tunnelOreInfo(floor, tn)
                    if not ore then return end
                    local mut = tunnelMutationName(floor, tn)
                    local mult = mutationMultOfName(mut)
                    local ceil_ = oreCeiling(ore, mut)
                    if ceil_ then
                        tunnels[#tunnels + 1] = {
                            floor = floor, tn = tn, ore = ore, lvl = lvl,
                            mut = mut, mult = mult, ceiling = ceil_,
                        }
                    end
                end)
                if #tunnels == 0 then
                    return
                end
                table.sort(tunnels, function(a, b)
                    if a.ceiling ~= b.ceiling then return a.ceiling > b.ceiling end
                    return a.lvl > b.lvl
                end)
                local used = {}
                local cleanserAvailable = false
                for _, cont in ipairs(containers) do
                    if cont then
                        for _, tool in ipairs(cont:GetChildren()) do
                            if tool:IsA("Tool")
                                and tool:GetAttribute("GearId") == "OreCleanser" then
                                cleanserAvailable = true
                                break
                            end
                        end
                    end
                    if cleanserAvailable then break end
                end
                for _, c in ipairs(coatings) do
                    local target = nil
                    for _, t in ipairs(tunnels) do
                        local key = t.floor .. ":" .. t.tn
                        if not used[key] then
                            if not t.mut then
                                target = t
                                break
                            elseif t.mult < c.mult and cleanserAvailable then
                                target = t
                                break
                            end
                        end
                    end
                    if not target then
                    else
                        used[target.floor .. ":" .. target.tn] = true
                        if target.mut then
                            local guid = HttpService:GenerateGUID(false)
                            local res = safeInvoke("UseGearOnTunnel", "OreCleanser",
                                base.Name, target.floor, target.tn, guid)
                            if type(res) ~= "table" or res.success ~= true then
                                used[target.floor .. ":" .. target.tn] = nil
                            else
                                task.wait(0.4)
                            end
                        end
                        if not target.mut or cleanserAvailable then
                            local guid = HttpService:GenerateGUID(false)
                            local res = safeInvoke("UseGearOnTunnel", c.id,
                                base.Name, target.floor, target.tn, guid)
                            if type(res) == "table" then
                                if res.success == true then
                                else
                                end
                            end
                            task.wait(0.4)
                        end
                    end
                end
            end)
        end
    end
end)
task.spawn(function()
    while isAlive() and task.wait(0.5) do
        if S.AutoGear then
            runNow("gear", 1.5, function()
                local rawWant = multiList("GearToBuyMulti")
                local want = {}
                for _, v in ipairs(rawWant) do table.insert(want, stripPrice(v)) end
                if #want == 0 then
                    return
                end
                local priceOf = {}
                for _, g in ipairs(GEAR_LIST) do priceOf[g.Id] = g.Price end
                table.sort(want, function(a, b)
                    return (priceOf[a] or math.huge) < (priceOf[b] or math.huge)
                end)
                local cap = math.max(0, math.floor(tonumber(S.GearStackCap) or 0))
                local bought, skipped = 0, 0
                for _, id in ipairs(want) do
                    local unit = priceOf[id]
                    if not unit then
                    else
                        local have = 0
                        for _, cont in ipairs({ plr:FindFirstChild("Backpack"), plr.Character }) do
                            if cont then
                                for _, tool in ipairs(cont:GetChildren()) do
                                    if tool:IsA("Tool") and tool:GetAttribute("ToolType") == "Gear"
                                        and tool:GetAttribute("GearId") == id then
                                        have = have + math.max(1, math.floor(
                                            tonumber(tool:GetAttribute("Quantity")
                                                or tool:GetAttribute("StackCount")) or 1))
                                    end
                                end
                            end
                        end
                        local iter = 0
                        while iter < 50 do
                            if cap > 0 and have >= cap then
                                skipped = skipped + 1
                                break
                            end
                            local room = (cap > 0) and (cap - have) or math.huge
                            local money = getMoney()
                            local qty = 0
                            if not spendingBlocked(unit * 10) and room >= 10
                                and unit * 10 <= money then
                                qty = 10
                            elseif not spendingBlocked(unit) and room >= 1
                                and unit <= money then
                                qty = 1
                            end
                            if qty == 0 then
                                if iter == 0 then skipped = skipped + 1 end
                                break
                            end
                            local res = safeInvoke("RequestGearPurchase", id, qty)
                            if type(res) == "table" and res.success == true then
                                bought = bought + 1
                                have = have + qty
                                iter = iter + 1
                            else
                                break
                            end
                            task.wait(0.05)
                        end
                    end
                end
            end)
        end
    end
end)
local groupRewardDone = false
task.spawn(function()
    while isAlive() do
        if S.AutoGroupReward and not groupRewardDone then
            runNow("groupReward", 3, function()
                local res = safeInvoke("GroupRewardClaimRequest")
                if type(res) ~= "table" then return end
                if res.success == true then
                    groupRewardDone = true
                elseif res.reason == "NotInGroup" or res.reason == "AlreadyClaimed" then
                    groupRewardDone = true
                else
                end
            end)
        end
        task.wait(1)
    end
end)
local lastFarm = os.clock()
local FARM_MAX_STEPS = 14
local function farmHasWork()
    local base = getMyBase()
    if carryingCrates() then return true end
    if S.UseFurnace then
        local furnace = base and base:FindFirstChild("Furnace")
        local purchased = plr:GetAttribute("FurnacePurchased") == true
        if furnace and purchased then
            if countMetalCrates(furnace) > 0 then return true end
            if countWoodCrates(base) > 0 then return true end
            return false
        end
    end
    return countWoodCrates(base) > 0
end
local function farmCycle()
    pcall(collectDroneOres)
    local step = math.max(0.2, tonumber(S.FarmDelay) or 1)
    if S.UseFurnace then
        pcall(collectDroneOres)
        local ok, res = pcall(furnaceTick)
        lastFarm = os.clock()
    else
        for i = 1, FARM_MAX_STEPS do
            if not S.AutoSell then
                lastFarm = os.clock()
                return
            end
            if queuePendingAbove(PRIORITY.farm) then
                lastFarm = os.clock()
                return
            end
            if not farmHasWork() then
                lastFarm = os.clock()
                return
            end
            local ok, res = pcall(sellOres)
            if not ok then
                lastFarm = os.clock()
                return
            end
            if res == false then
                lastFarm = os.clock()
                return
            end
            task.wait(step)
        end
    end
    lastFarm = os.clock()
end
task.spawn(function()
    while isAlive() and task.wait(0.25) do
        if not S.AutoSell then
            lastFarm = os.clock()
        else
            local iv = math.max(1, tonumber(S.FarmInterval) or 20)
            if os.clock() - lastFarm >= iv then
                tryEnqueue("farm", 0.5, farmCycle, function() return S.AutoSell end)
            end
        end
    end
end)
task.spawn(function()
    local oreUpMaxed = {}
    while isAlive() and task.wait(0.5) do
        if S.AutoUpgradeTunnelOre then
            runNow("oreUp", upgDelay(), function()
                local base = getMyBase()
                if not base then return end
                local maxLvl = math.max(1, math.floor(tonumber(S.TunnelOreMaxLevel) or 20))
                local needOre, openCnt = 0, 0
                local budget = 12
                while budget > 0 do
                    budget = budget - 1
                    local known = nil
                    local blind = nil
                    openCnt, needOre = 0, 0
                    local found = forEachTunnel(base, function(floor, tn)
                        if not isTunnelOpen(floor, tn) then return end
                        openCnt = openCnt + 1
                        local key = floor .. ":" .. tn
                        if oreUpMaxed[key] then return end
                        local ore, lvl = tunnelOreInfo(floor, tn)
                        if not ore then
                            needOre = needOre + 1
                            return
                        end
                        local room = maxLvl - lvl
                        if room <= 0 then return end
                        local p10 = (room >= 10) and tunnelOreUpgradePrice(ore, lvl, 10) or nil
                        local p1 = tunnelOreUpgradePrice(ore, lvl, 1)
                        if p1 then
                            local cand = p10 or p1
                            if not known or cand < (known.p10 or known.p1) then
                                known = { floor = floor, tunnel = tn,
                                    ore = ore, lvl = lvl, p10 = p10, p1 = p1 }
                            end
                        elseif not blind then
                            blind = { floor = floor, tunnel = tn,
                                ore = ore, lvl = lvl, p10 = nil, p1 = nil }
                        end
                    end)
                    local best = known or blind
                    if not best then
                        if found == 0 and budget == 11 then
                        elseif budget == 11 then
                        end
                        return
                    end
                    local action, price
                    if best.p10 and canSpend("oreUp", best.p10) then
                        action, price = "IncreaseLevel10", best.p10
                    elseif best.p1 then
                        if not canSpend("oreUp", best.p1) then
                            return
                        end
                        action, price = "IncreaseLevel", best.p1
                    else
                        action, price = "IncreaseLevel", nil
                    end
                    if action == "IncreaseLevel10" then
                    elseif best.p1 then
                    else
                    end
                    local res = safeInvoke("BaseBuildTunnelAction",
                        base.Name, best.floor, best.tunnel, action)
                    task.wait(0.5)
                    local _, lvl2 = tunnelOreInfo(best.floor, best.tunnel)
                    if lvl2 and lvl2 > best.lvl then
                        if budget > 0 then task.wait(0.1) end
                    else
                        if type(res) == "table" and res.success == false then
                            local why = tostring(res.result or res.reason or "?")
                            if why:find("MaxLevel", 1, true) or why:find("max level", 1, true)
                                or why:find("Already", 1, true) then
                                oreUpMaxed[best.floor .. ":" .. best.tunnel] = true
                            elseif why:find("Money", 1, true) or why:find("money", 1, true) then
                                return
                            end
                        elseif type(res) == "table" and res.success == true then
                        else
                        end
                        return
                    end
                end
            end)
        end
    end
end)
task.spawn(function()
    while isAlive() and task.wait(1) do
        if S.AutoGrowthGems then
            local count = math.max(0, math.floor(tonumber(plr:GetAttribute("GrowthGemInventoryCount")) or 0))
            if count > 0 then
                runNow("gems", 3, function()
                    local base = getMyBase()
                    if not base then return end
                    local res = safeInvoke("BaseBuildTunnelAction", base.Name, 1, "Tunnel1", "ApplyBestGrowthGems")
                end)
            end
        end
    end
end)
task.spawn(function()
    while isAlive() and task.wait(1) do
        if S.AutoBuyFurnace or S.AutoUpgradeFurnace then
            runNow("furnaceSvc", 2, function()
                local base = getMyBase()
                if not base then return end
                local st = furnaceState(true)
                if not st or st.Purchased ~= true then
                    if S.AutoBuyFurnace then
                        tryEnqueue("buyFurnace", 5, function()
                            local b = getMyBase()
                            if not b then return end
                            local furnace = b:FindFirstChild("Furnace")
                            local prompt = furnace and furnace:FindFirstChild("PurchaseFurnacePrompt", true)
                            if not prompt then return end
                            if getMoney() < FURNACE_BUY_PRICE then
                                return
                            end
                            wakePrompt(prompt)
                            firePrompt(prompt, true)
                        end, function() return S.AutoBuyFurnace end)
                    end
                    return
                end
                if S.AutoUpgradeFurnace then
                    local lvl = math.max(1, math.floor(tonumber(st.Level) or 1))
                    local price = furnaceUpgradePrice(lvl)
                    if canSpend("furnaceUp", price) then
                        safeInvoke("BaseCrateAction", base.Name, "UpgradeFurnace")
                    end
                end
            end)
        end
    end
end)
task.spawn(function()
    while isAlive() do
        if S.AutoClaimDaily then
            runNow("daily", 3, function()
                local state = safeInvoke("GetDailyRewardsState")
                if type(state) ~= "table" then return end
                local elapsed = os.clock() - (state.receivedAt or os.clock())
                local now = (state.serverTime or os.time()) + elapsed
                if state.isAvailable == true or (state.nextAvailableAt or math.huge) <= now then
                    safeFire("ClaimDailyReward")
                else
                end
            end)
        end
        task.wait(2)
    end
end)
task.spawn(function()
    local playtimeState = nil
    pcall(function()
        Remotes:WaitForChild("PlaytimeRewardsChanged", 10).OnClientEvent:Connect(function(state)
            if not isAlive() then return end
            if type(state) == "table" then state.receivedAt = os.clock() end
            playtimeState = state
        end)
    end)
    while isAlive() do
        if S.AutoClaimPlaytime then
            runNow("playtime", 2, function()
                safeFire("PlaytimeRewardsRequestState")
                task.wait(0.3)
                local st = playtimeState
                if type(st) ~= "table" or type(st.rewards) ~= "table" then return end
                local elapsed = (tonumber(st.elapsed) or 0)
                    + (os.clock() - (tonumber(st.receivedAt) or os.clock()))
                local got = 0
                for j = 1, 12 do
                    local r = st.rewards[j]
                    if type(r) == "table" and r.claimed ~= true
                        and (tonumber(r.unlockAt) or math.huge) <= elapsed then
                        safeFire("PlaytimeRewardsClaim", j)
                        got = got + 1
                        task.wait(0.08)
                    end
                end
            end)
        end
        task.wait(2)
    end
end)
task.spawn(function()
    local offlineFails = 0
    while isAlive() do
        if S.AutoClaimOffline then
            local amount = tonumber(plr:GetAttribute("OfflineEarningsAmount")) or 0
            if amount > 0 then
                runNow("offline", 2, function()
                    if offlineFails >= 3 then return end
                    local res = safeInvoke("OfflineEarningsClaimRequest")
                    if type(res) == "table" and res.success == false then
                        offlineFails = offlineFails + 1
                    elseif type(res) ~= "table" then
                        offlineFails = offlineFails + 1
                    end
                    task.delay(3, function()
                        if (tonumber(plr:GetAttribute("OfflineEarningsAmount")) or 0) <= 0 then
                            offlineFails = 0
                        else
                            offlineFails = offlineFails + 1
                        end
                    end)
                end)
            else
                offlineFails = 0
            end
        end
        task.wait(1)
    end
end)
do
local function findGearTool(gearIdPrefix)
    local containers = { plr:FindFirstChild("Backpack"), plr.Character }
    for _, cont in ipairs(containers) do
        if cont then
            for _, tool in ipairs(cont:GetChildren()) do
                if tool:IsA("Tool") and tool:GetAttribute("ToolType") == "Gear" then
                    local gid = tool:GetAttribute("GearId")
                    if type(gid) == "string" and gid:sub(1, #gearIdPrefix) == gearIdPrefix then
                        return tool, gid
                    end
                end
            end
        end
    end
    return nil, nil
end
local function useSkipGear(gearId)
    if type(gearId) ~= "string" then return nil end
    local guid = HttpService:GenerateGUID(false)
    return safeInvoke("UseGearOnTunnel", gearId, nil, nil, nil, guid)
end
task.spawn(function()
    while isAlive() do
        if S.AutoTimeSkip then
            runNow("timeSkip", 3, function()
                local minSec = ({ ["Any"] = 0, ["30 min+"] = 1800,
                    ["2h+"] = 7200, ["6h+"] = 21600, ["12h+"] = 43200 })[S.MinTimeSkip] or 0
                local bestTool, bestSec, bestId
                local containers = { plr:FindFirstChild("Backpack"), plr.Character }
                for _, cont in ipairs(containers) do
                    if cont then
                        for _, tool in ipairs(cont:GetChildren()) do
                            if tool:IsA("Tool") and tool:GetAttribute("ToolType") == "Gear" then
                                local gid = tool:GetAttribute("GearId")
                                if type(gid) == "string" then
                                    local sec = tonumber(gid:match("^TimeSkip:(%d+)$"))
                                    if sec and sec >= minSec and (not bestSec or sec > bestSec) then
                                        bestTool, bestSec, bestId = tool, sec, gid
                                    end
                                end
                            end
                        end
                    end
                end
                if not bestId then
                    return
                end
                local res = useSkipGear(bestId)
                if type(res) == "table" then
                    if res.success then
                    elseif res.result == "Busy" then
                    elseif res.result == "NoGear" then
                    else
                    end
                end
            end)
        end
        task.wait(3)
    end
end)
task.spawn(function()
    while isAlive() and task.wait(2) do
        if S.AutoFurnaceSkip and S.UseFurnace then
            runNow("furnSkip", 5, function()
                local base = getMyBase()
                if not base then return end
                local furnace = base:FindFirstChild("Furnace")
                if not furnace then return end
                local st = furnaceState(false)
                if not st or st.Purchased ~= true then return end
                local place = furnace:FindFirstChild("PlaceCratesPrompt", true)
                if not place or place.Enabled then return end
                local _, gid = findGearTool("FurnaceSkip")
                if not gid then
                    return
                end
                local res = useSkipGear(gid)
            end)
        end
    end
end)
task.spawn(function()
    while isAlive() and task.wait(3) do
        if S.AutoFuserSkip and S.AutoFuserRun then
            runNow("fuserSkip", 5, function()
                local _, gid = findGearTool("FuserSkip")
                if not gid then
                    return
                end
                local res = useSkipGear(gid)
            end)
        end
    end
end)
end
task.spawn(function()
    while isAlive() and task.wait(1) do
        if S.OreESP then
            pcall(function()
                for _, obj in pairs(Workspace:GetDescendants()) do
                    if obj:IsA("Model") then
                        local name = obj.Name:lower()
                        if (name:find("ore") or name:find("crystal") or name:find("gem"))
                            and not obj:FindFirstChild("AscendESP")
                            and obj.Parent ~= Workspace
                        then
                            local hl = Instance.new("Highlight")
                            hl.Name = "AscendESP"
                            hl.FillColor = Color3.fromRGB(255, 50, 50)
                            hl.OutlineColor = Color3.fromRGB(255, 255, 255)
                            hl.FillTransparency = 0.4
                            hl.OutlineTransparency = 0
                            hl.Adornee = obj
                            hl.Parent = obj
                        end
                    end
                end
            end)
        end
    end
end)
task.spawn(function()
    while isAlive() and task.wait(1) do
        if S.CrateESP then
            pcall(function()
                for _, obj in pairs(Workspace:GetDescendants()) do
                    if obj:IsA("Model") and obj.Name:lower():find("crate")
                        and not obj:FindFirstChild("AscendCrateESP")
                    then
                        local hl = Instance.new("Highlight")
                        hl.Name = "AscendCrateESP"
                        hl.FillColor = Color3.fromRGB(0, 255, 100)
                        hl.OutlineColor = Color3.fromRGB(255, 255, 255)
                        hl.FillTransparency = 0.3
                        hl.OutlineTransparency = 0
                        hl.Adornee = obj
                        hl.Parent = obj
                    end
                end
            end)
        end
    end
end)
RunService.Stepped:Connect(function()
    if not isAlive() then return end
    if S.Noclip then
        pcall(function()
            local char = plr.Character
            if char then
                for _, part in pairs(char:GetDescendants()) do
                    if part:IsA("BasePart") then
                        part.CanCollide = false
                    end
                end
            end
        end)
    end
end)
plr.CharacterAdded:Connect(function(char)
    if not isAlive() then return end
    local hum = char:WaitForChild("Humanoid", 5)
    if hum then
        hum.WalkSpeed = S.WalkSpeed
        hum.JumpPower = S.JumpPower
    end
end)
notify("AscendHub", "Sell Ores loaded!\ndiscord.gg/WDDpN4Bv", 5)
