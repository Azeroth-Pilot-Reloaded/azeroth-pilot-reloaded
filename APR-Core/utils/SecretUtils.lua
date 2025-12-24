-- Secret/taint helpers (12.0.0+). Keep all secret-value handling centralized here.
APRSecret = APRSecret or {}

function APRSecret:Attach(target)
    if not target then
        return
    end
    target.Secret = self
    target.CanAccessValue = function(_, value)
        return self:CanAccessValue(value)
    end
    target.CanAccessSecrets = function(_)
        return self:CanAccessSecrets()
    end
    target.SafeUnitName = function(_, unit, fallback)
        return self:SafeUnitName(unit, fallback)
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

function APRSecret:SafeUnitClass(unit)
    local classLocal, className, classId = UnitClass(unit)
    if not self:CanAccessValue(classLocal) or not self:CanAccessValue(className) or not self:CanAccessValue(classId) then
        return nil, nil, nil
    end
    return classLocal, className, classId
end

function APRSecret:SafeUnitGUID(unit, fallback)
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
