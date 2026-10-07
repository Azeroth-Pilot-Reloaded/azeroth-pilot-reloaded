-- Provides capability-based secret-value guards and safe unit identity reads before APR is created.
-- A public table may contain inaccessible values; check accessibility before indexing or comparing.

APRSecret = APRSecret or {}

function APRSecret:Attach(target)
    if not target then
        return
    end
    target.Secret = self
    target.CanAccessValue = function(_, value)
        return self:CanAccessValue(value)
    end
    target.CanAccessTable = function(_, value)
        return self:CanAccessTable(value)
    end
    target.CanAccessSecrets = function(_)
        return self:CanAccessSecrets()
    end
    target.SafeUnitName = function(_, unit, fallback)
        return self:SafeUnitName(unit, fallback)
    end
    target.SafeUnitNameUnmodified = function(_, unit, fallback)
        return self:SafeUnitNameUnmodified(unit, fallback)
    end
    target.SafeUnitClass = function(_, unit)
        return self:SafeUnitClass(unit)
    end
    target.SafeUnitGUID = function(_, unit, fallback)
        return self:SafeUnitGUID(unit, fallback)
    end
    target.SafeConcat = function(_, fallback, ...)
        return self:SafeConcat(fallback, ...)
    end
end

function APRSecret:CanAccessValue(value)
    if canaccessvalue then
        return canaccessvalue(value)
    end
    if issecretvalue then
        return not issecretvalue(value)
    end
    return true
end

function APRSecret:CanAccessSecrets()
    if canaccesssecrets then
        return canaccesssecrets()
    end
    return true
end

-- A public table can still contain restricted contents (notably UNIT_AURA).
function APRSecret:CanAccessTable(value)
    return self:CanAccessValue(value) and type(value) == "table"
        and (not canaccesstable or canaccesstable(value))
end

function APRSecret:SafeUnitCreatureID(unit)
    if not self:CanAccessValue(unit) then return nil end
    -- Prefer the namespaced API, which consumes a GUID rather than a unit token.
    local id
    if C_CreatureInfo and C_CreatureInfo.GetCreatureID then
        local guid = self:SafeUnitGUID(unit)
        if not guid then return nil end
        id = C_CreatureInfo.GetCreatureID(guid)
    elseif UnitCreatureID then
        id = UnitCreatureID(unit)
    else
        local guid = self:SafeUnitGUID(unit)
        if not guid then return nil end
        local kind, _, _, _, _, creatureID = strsplit("-", guid)
        if kind == "Creature" or kind == "Vehicle" then id = creatureID end
    end
    if not self:CanAccessValue(id) then return nil end
    return tonumber(id)
end

function APRSecret:SafeUnitName(unit, fallback)
    local name, realm = UnitName(unit)
    if not self:CanAccessValue(name) then
        return fallback, nil
    end
    if not self:CanAccessValue(realm) then
        return name, nil
    end
    return name, realm
end

function APRSecret:SafeUnitNameUnmodified(unit, fallback)
    local name, realm = UnitNameUnmodified(unit)
    if not self:CanAccessValue(name) then
        return fallback, nil
    end
    if not self:CanAccessValue(realm) then
        return name, nil
    end
    return name, realm
end

function APRSecret:SafeUnitClass(unit)
    local classLocal, className, classId = UnitClass(unit)
    if not self:CanAccessValue(classLocal) or not self:CanAccessValue(className) or not self:CanAccessValue(classId) then
        return nil, nil, nil
    end
    return classLocal, className, classId
end

function APRSecret:SafeUnitGUID(unit, fallback)
    if not self:CanAccessValue(unit) then return fallback end
    local guid = UnitGUID(unit)
    if not self:CanAccessValue(guid) then
        return fallback
    end
    return guid
end

function APRSecret:SafeConcat(fallback, ...)
    local count = select("#", ...)
    local parts = {}
    for i = 1, count do
        local part = select(i, ...)
        if not self:CanAccessValue(part) or part == nil then
            return fallback
        end
        parts[i] = tostring(part)
    end
    return table.concat(parts)
end
