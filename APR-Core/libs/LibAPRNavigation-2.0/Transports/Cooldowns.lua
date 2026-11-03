-- Exact captured cooldown/charge decisions. No clocks, client calls or search.
local _, ns = ...
local Finite = ns.NavigationV2Graph.Finite
local Cooldowns = {}

local function Seconds(value)
    return Finite(value) and value >= 0
end

local function Profile(d, o)
    local a = o.actions[d.id]
    local p = {readyAt=a.readyAt, chargeBased=d.chargeBased}
    if d.chargeBased then
        p.charges, p.maximum = a.charges, a.maxCharges
        -- Playback rates other than one are not a forecast of future gameplay.
        if a.rechargeRate == 1 and a.rechargeSeconds and a.rechargeSeconds > 0 then
            p.duration = a.rechargeSeconds
            if p.charges and p.maximum and p.charges < p.maximum then
                if a.rechargeStart and a.rechargeStart>0 and o.observedAt and a.rechargeStart <= o.observedAt then
                    p.nextAt = a.rechargeStart + p.duration
                    if not Seconds(p.nextAt) or p.nextAt<=o.observedAt then p.duration,p.nextAt = nil,nil end
                else p.duration = nil end
            end
        end
    end
    return p
end

-- The shared group has one conservative public balance, never one per ability.
function Cooldowns.Capture(entries, observation)
    local profiles,active = {},{}
    for _,d in ipairs(entries) do
        if d.chargeBased or d.cooldownSeconds>0 then active['personal:'..d.useResourceId]=true end
    end
    for _,d in ipairs(entries) do
        if active['personal:'..d.useResourceId] then
            local key, p = 'personal:'..d.useResourceId, Profile(d, observation)
            local old = profiles[key]
            if old then
                if old.chargeBased ~= p.chargeBased then old.unknown = true end
                old.readyAt = old.readyAt and p.readyAt and math.max(old.readyAt,p.readyAt) or nil
                if p.chargeBased then
                    old.charges = old.charges and p.charges and math.min(old.charges,p.charges) or nil
                    old.maximum = old.maximum and p.maximum and math.min(old.maximum,p.maximum) or nil
                    if old.duration ~= p.duration or old.nextAt ~= p.nextAt then old.duration,old.nextAt = nil,nil end
                end
            else profiles[key] = p end
        end
    end
    return profiles
end

local function At(profile, state, now)
    state = state or profile
    if not profile.chargeBased then return {readyAt=state.readyAt} end
    local charges, nextAt = state.charges, state.nextAt
    if charges and nextAt and profile.duration and now >= nextAt then
        local gained = math.min(profile.maximum-charges, 1+math.floor((now-nextAt)/profile.duration))
        charges = charges+gained
        nextAt = charges < profile.maximum and nextAt+gained*profile.duration or nil
    end
    return {charges=charges,nextAt=nextAt}
end

-- Do not retain a past cooldown or a completely regenerated charge queue.
-- The unspent baseline already describes those same future possibilities.
function Cooldowns.Trim(profiles, states, now)
    local result={}
    for key,state in pairs(states) do
        local p=profiles[key]
        local current=At(p,state,now)
        if p.chargeBased then
            local baseline=At(p,nil,now)
            if current.charges~=baseline.charges or current.nextAt~=baseline.nextAt then result[key]=current end
        elseif current.readyAt>now then result[key]=current end
    end
    return result
end

-- Returns the earliest justified use and the group's state AFTER that use.
function Cooldowns.Use(profile, state, now, cooldownSeconds)
    if not Seconds(now) then return nil,'cooldown_clock_unknown' end
    if profile.unknown or not profile.readyAt then return nil,'cooldown_unknown' end
    local current = At(profile,state,now)
    local useAt = math.max(now,profile.readyAt)
    if not profile.chargeBased then
        useAt = math.max(useAt,current.readyAt)
        local readyAt = useAt+cooldownSeconds
        if not Seconds(readyAt) or (cooldownSeconds>0 and readyAt<=useAt) then return nil,'cooldown_overflow' end
        return useAt,{readyAt=readyAt}
    end
    if not current.charges then return nil,'resources_unknown' end
    current = At(profile,state,useAt)
    if current.charges == 0 then
        if not current.nextAt then return nil,'charge_recharge_unknown' end
        useAt = math.max(useAt,current.nextAt)
        current = At(profile,current,useAt)
    end
    current.charges = current.charges-1
    if profile.duration and not current.nextAt then current.nextAt = useAt+profile.duration end
    if current.nextAt and (not Seconds(current.nextAt) or current.nextAt<=useAt) then return nil,'cooldown_overflow' end
    return useAt,current
end

-- Earlier arrival may wait until the later label. Compare only future ability,
-- not historical use counts. Equal/full expired states need no extra labels.
function Cooldowns.Dominates(profiles, a, b, now)
    for key,p in pairs(profiles) do
        local x,y = At(p,a[key],now),At(p,b[key],now)
        if p.chargeBased then
            if x.charges~=y.charges and (not x.charges or not y.charges or x.charges<y.charges) then return false end
            if p.duration and x.charges and x.charges<p.maximum then
                -- Compare the first still-missing token; every later token has
                -- the same recharge interval. More charges alone is insufficient.
                local other=y.nextAt and y.nextAt+(x.charges-y.charges)*p.duration
                if other and (not x.nextAt or x.nextAt>other) then return false end
            end
        elseif math.max(now,x.readyAt or now) > math.max(now,y.readyAt or now) then return false end
    end
    return true
end

ns.NavigationV2Cooldowns = Cooldowns
return Cooldowns
