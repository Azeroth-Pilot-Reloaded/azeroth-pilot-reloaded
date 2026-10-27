-- Route consumers use the same item definitions as the navigation graph.
local Lib = LibStub("LibAPRNavigation-1.0")
if not Lib:BeginModule("travel-actions", 2) then return end
local Instance = Lib.Instance

function Instance:IsHousingLocation(position)
    local maps = self.config.HousingMaps
    if not maps then return false end
    local current, seen = position and position.uiMapID, {}
    if not current then return nil end
    for _ = 1, 50 do
        if not current or current == 0 then return false end
        if maps[current] then return true end
        if seen[current] then return nil end
        seen[current] = true
        local info = self:GetMapAncestryInfo(current)
        if not info then return nil end
        current = info.parentMapID
    end
end

-- This is a native escape instruction, not a graph edge. Returning does not
-- require owning the visited house or knowing its server-side return point.
function Instance:GetHousingExitAction(start, goal)
    if self:IsHousingLocation(start) ~= true or self:IsHousingLocation(goal) ~= false then return nil end
    if self:GetActionUsability("housing_return") ~= true then return nil end
    local destination = self.env.getDynamicPosition and self.env.getDynamicPosition("housing_exit")
    if destination and self:IsHousingLocation(destination) ~= false then destination = nil end
    return { kind = "housing_return", action = { type = "housing_return" }, from = start, to = destination,
        sourceFree = true, mandatory = true, exitHousing = true, label = self:GetText("EXIT_HOUSING") }
end

local function Action(definition)
    local option = definition.actions and definition.actions[1]
    return option and { type = option.type, data = option.id } or nil
end

function Lib:GetTravelAction(profile, key)
    if type(key) ~= "string" then return nil end
    for _, category in pairs(self.datasets[profile] or {}) do
        for _, definition in ipairs(category.connections or {}) do
            if definition.routeAction == key then return Action(definition) end
        end
    end
end

function Instance:GetTravelAction(key)
    if type(key) ~= "string" then return nil end
    for _, definition in ipairs(self.connections) do
        if definition.routeAction == key then return Action(definition) end
    end
end

function Instance:GetActionSpellID(kind, id)
    if kind == "spell" then return id end
    if kind ~= "item" then return nil end
    local resolved = self.env.getItemSpellID and self.env.getItemSpellID(id)
    if type(resolved) == "number" and resolved > 0 and resolved < math.huge then return resolved end
    local definition = self.actionDefinitions["item:" .. tostring(id)]
    return definition and definition.useSpellID
end

function Instance:IsTravelActionSpell(key, spellID, selectedItemID)
    if type(key) ~= "string" or type(spellID) ~= "number" then return false end
    for _, definition in ipairs(self.connections) do
        -- Learned recalls also return to the inn; fixed teleports never complete UseHS.
        local innRecall = key == "UseHS" and definition.kind == "spell"
            and definition.to and definition.to.dynamic == "bind"
        if definition.routeAction == key or innRecall then
            for _, option in ipairs(definition.actions or {}) do
                local effect = option.type == "spell" and option.id or option.useSpellID
                if effect == spellID then return true end
                if option.type == "item" and (key ~= "UseHS" or option.id == selectedItemID)
                    and self:GetActionSpellID(option.type, option.id) == spellID then return true end
            end
        end
    end
    return false
end
