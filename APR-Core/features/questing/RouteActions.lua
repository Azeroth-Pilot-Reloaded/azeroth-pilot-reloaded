local L = LibStub("AceLocale-3.0"):GetLocale("APR")
local actionKeys = { "DeathSkip", "SellItems", "LearnSkill", "BankDeposit", "BankWithdraw", "TameBeast", "DestroyItems", "EquipItem" }
APR.routeActionKeys = actionKeys

local function CurrentNPC()
    local guid = UnitGUID and (UnitGUID("npc") or UnitGUID("target"))
    return guid and tonumber((select(6, strsplit("-", guid))))
end

local function Bags(bank)
    local bags = {}
    if bank then
        bags[#bags + 1] = -1
        for id = 5, 11 do bags[#bags + 1] = id end
    else
        for id = 0, (NUM_BAG_SLOTS or 4) do bags[#bags + 1] = id end
    end
    return bags
end

local function ContainerInfo(bag, slot)
    if C_Container and C_Container.GetContainerItemInfo then return C_Container.GetContainerItemInfo(bag, slot) end
    if GetContainerItemInfo then
        local _, count, locked, quality, _, _, _, _, _, id = GetContainerItemInfo(bag, slot)
        if id then return { itemID = id, stackCount = count, isLocked = locked, quality = quality } end
    end
end

local function ContainerCall(name, ...)
    local fn = C_Container and C_Container[name] or _G[name]
    if fn then return fn(...) end
end

local function Entries(rule)
    return rule.items or rule
end

local function TrainerMatchesSpell(index, name, rank, spellID)
    local link = GetTrainerServiceItemLink and GetTrainerServiceItemLink(index)
    local linkedID = link and tonumber(link:match('spell:(%d+)'))
    if linkedID then return linkedID == spellID end
    -- Classic trainers expose localized names/ranks, not a service spell-ID API.
    local info = C_Spell and C_Spell.GetSpellInfo and C_Spell.GetSpellInfo(spellID)
    local spellName = info and info.name or (GetSpellInfo and GetSpellInfo(spellID))
    local subtext = C_Spell and C_Spell.GetSpellSubtext or GetSpellSubtext
    local spellRank = subtext and subtext(spellID)
    return spellName == name and (rank or '') == (spellRank or '')
end

-- Process one complete stack at a time. Never touch an unrelated cursor item,
-- locked slot, unlisted item or a closed bank/merchant. Bag events drive retries.
function APR:ProcessRouteItems(key, rule, state)
    if (InCombatLockdown and InCombatLockdown()) or (CursorHasItem and CursorHasItem()) then return false end
    if key == "SellItems" and not self.routeMerchantOpen then return false end
    if (key == "BankDeposit" or key == "BankWithdraw") and not self.routeBankOpen then return false end
    if rule.npcID and CurrentNPC() ~= rule.npcID then return false end
    if (ContainerCall('GetContainerNumSlots', 0) or 0) == 0 then return false end
    if (key == 'BankDeposit' or key == 'BankWithdraw') and (ContainerCall('GetContainerNumSlots', -1) or 0) == 0 then return false end
    if state.pending then
        local p = state.pending
        local item = ContainerInfo(p.bag, p.slot)
        if item and item.itemID == p.itemID and item.stackCount == p.count and GetTime() - p.time < 1 then return false end
        state.pending = nil
    end
    for _, bag in ipairs(Bags(key == "BankWithdraw")) do
        for slot = 1, (ContainerCall("GetContainerNumSlots", bag) or 0) do
            local info = ContainerInfo(bag, slot)
            if info and info.itemID then
                local wanted = rule.junk and info.quality == 0
                for _, entry in ipairs(Entries(rule)) do
                    local id = type(entry) == "table" and entry.itemID or entry
                    if id == info.itemID then wanted = true end
                end
                if wanted and key == 'SellItems' and info.hasNoValue then
                    if rule.junk then wanted = false else return false end
                end
                if wanted then
                    if info.isLocked then return false end
                    state.pending = { bag = bag, slot = slot, itemID = info.itemID, count = info.stackCount, time =
                    GetTime() }
                    if key == "DestroyItems" then
                        ContainerCall("PickupContainerItem", bag, slot)
                        local kind, id = GetCursorInfo()
                        if kind == "item" and id == info.itemID then DeleteCursorItem() else ClearCursor() end
                    else
                        ContainerCall("UseContainerItem", bag, slot)
                    end
                    return false
                end
            end
        end
    end
    return true
end

function APR:GetRouteActionState()
    local token = self:GetCurrentStepToken(self.ActiveRoute, APRData[self.PlayerID][self.ActiveRoute])
    if not self.routeActionState or self.routeActionState.token ~= token then
        self.routeActionState = { token = token }
    end
    return self.routeActionState
end

function APR:GetRouteActionText(key, rule)
    local label = L[key:upper()]
    if type(rule) ~= "table" then return label end

    local function Fallback()
        return self:ResolveStepText(rule.text or rule.Text) or label
    end

    if key == "LearnSkill" and (rule.spellID or rule.spellIDs) then
        local names = {}
        for _, id in ipairs(rule.spellID and { rule.spellID } or rule.spellIDs) do
            local info = C_Spell and C_Spell.GetSpellInfo and C_Spell.GetSpellInfo(id)
            local name = info and info.name or (GetSpellInfo and GetSpellInfo(id))
            names[#names + 1] = name or ((UNKNOWN or "?") .. " (" .. id .. ")")
        end
        -- Spell names come from the client; a route's literal text must never override them.
        return #names > 0 and (label .. ": " .. table.concat(names, ", ")) or label
    end

    if key == "TameBeast" and rule.npcID then
        local name = APRData and APRData.NPCList and APRData.NPCList[rule.npcID]
        return name and (label .. ": " .. name) or Fallback()
    end

    if key == "EquipItem" and rule.itemID then
        local getItemInfo = C_Item and C_Item.GetItemInfo or GetItemInfo
        local name = getItemInfo and getItemInfo(rule.itemID)
        return label .. ": " .. (name or ((UNKNOWN or "?") .. " (" .. rule.itemID .. ")"))
    end

    if key == "SellItems" or key == "BankDeposit" or key == "BankWithdraw" or key == "DestroyItems" then
        local names, missing = {}, false
        local getItemInfo = C_Item and C_Item.GetItemInfo or GetItemInfo
        for _, entry in ipairs(Entries(rule)) do
            local id = type(entry) == "table" and entry.itemID or entry
            local name = getItemInfo and getItemInfo(id)
            if not name then
                missing = true
                name = type(entry) == "table" and self:ResolveStepText(entry.text or entry.Text)
            end
            names[#names + 1] = name or ((UNKNOWN or "?") .. " (" .. id .. ")")
        end
        -- Item data can be absent until cached. Keep the route fallback until every name is available.
        if missing and (rule.text or rule.Text) then return Fallback() end
        if #names > 0 then return label .. ": " .. table.concat(names, ", ") end
    end

    return Fallback()
end

function APR:HandleRouteAction(step)
    if (step.LeaveQuest or step.LeaveQuests) and not self:HasAnyMainStepOption(step) then
        local complete = true
        for _, id in ipairs(step.LeaveQuests or { step.LeaveQuest }) do
            if C_QuestLog.IsOnQuest(id) then
                complete = false; self:LeaveQuest(id)
            end
        end
        if complete then self:NextQuestStep() end
        return true
    end
    for _, key in ipairs(actionKeys) do
        if step[key] then
            local rule = type(step[key]) == "table" and step[key] or {}
            local state = self:GetRouteActionState()
            local complete
            if key == "DeathSkip" or key == "TameBeast" then
                complete = state.complete
            elseif key == "EquipItem" then
                complete = GetInventoryItemID("player", rule.slot) == rule.itemID
            elseif key == "LearnSkill" then
                self:HandleSkillTrainer(step)
                complete = state.complete
                if rule.spellID then
                    complete = self:IsSpellKnown(rule.spellID)
                elseif rule.spellIDs then
                    complete = true
                    for _, id in ipairs(rule.spellIDs) do if not self:IsSpellKnown(id) then complete = false end end
                end
            else
                complete = self:ProcessRouteItems(key, rule, state)
            end
            if complete then
                self:NextQuestStep(); return true
            end
            self.currentStep:AddQuestSteps(key, self:GetRouteActionText(key, rule), key, false, true)
            if key == "TameBeast" then
                self.currentStep:AddStepButton(key .. "-spell", rule.spellID or 1515, "spell")
                if rule.npcID then self.currentStep:AddRaidIconButton(key .. "-target", rule.npcID) end
            elseif key == "EquipItem" then
                self.currentStep:AddStepButton(key .. "-" .. key, rule.itemID, "item", rule.slot)
            end
            return true
        end
    end
    return false
end

function APR:HandleSkillTrainer(step)
    if not step or not step.LearnSkill or not self.routeTrainerOpen then return end
    local rule = step.LearnSkill
    if rule.npcID and CurrentNPC() ~= rule.npcID then return end
    if not GetNumTrainerServices or not GetTrainerServiceInfo or not BuyTrainerService then return end
    if InCombatLockdown and InCombatLockdown() then return end
    local anyAvailable = false
    for index = 1, GetNumTrainerServices() do
        local name, rank, status = GetTrainerServiceInfo(index)
        local wanted = rule.allAvailable == true
        if rule.spellID then wanted = TrainerMatchesSpell(index, name, rank, rule.spellID) end
        for _, id in ipairs(rule.spellIDs or {}) do
            if TrainerMatchesSpell(index, name, rank, id) then wanted = true end
        end
        if wanted and status == "available" then
            anyAvailable = true
            if (GetTrainerServiceCost(index) or 0) <= GetMoney() then
                BuyTrainerService(index); break
            end
        end
    end
    if rule.allAvailable and not anyAvailable then self:GetRouteActionState().complete = true end
end

function APR:HandleDeathSkip(step, event)
    if not step or not step.DeathSkip or not self:AreConditionalFiltersMet(step) then return end
    local state = self:GetRouteActionState()
    if event == "PLAYER_DEAD" then state.died = true end
    if event == "CONFIRM_XP_LOSS" then
        state.died, state.spiritHealer = true, true
        if C_PlayerInteractionManager and C_PlayerInteractionManager.ConfirmationInteraction and Enum and Enum.PlayerInteractionType then
            C_PlayerInteractionManager.ConfirmationInteraction(Enum.PlayerInteractionType.SpiritHealer)
        elseif AcceptXPLoss then
            AcceptXPLoss()
        end
    end
    if event == "PLAYER_UNGHOST" and state.died and state.spiritHealer then state.complete = true end
end

function APR:HandleTameBeast(step, event, unit, spell)
    if not step or not step.TameBeast or unit ~= "player" or spell ~= (step.TameBeast.spellID or 1515) then return end
    local state = self:GetRouteActionState()
    if event == "UNIT_SPELLCAST_START" then
        state.target = self.GetTargetID and self:GetTargetID("target") or CurrentNPC()
    elseif event == "UNIT_SPELLCAST_SUCCEEDED" then
        state.complete = not step.TameBeast.npcID or state.target == step.TameBeast.npcID
    end
end

function APR:HandleSpellETA(step, unit, spell)
    if not step or not step.SpellETA or unit ~= "player" then return end
    local r, wanted = step.SpellETA, step.SpellETA.spellID
    if r.itemID then
        local fn = C_Item and C_Item.GetItemSpell or GetItemSpell
        if fn then
            local _, id = fn(r.itemID); wanted = id
        end
    end
    local state = self:GetRouteActionState()
    if wanted == spell and not state.timerStarted then
        state.timerStarted = true
        self.AFK:SetAfkTimer(r.seconds)
    end
end
