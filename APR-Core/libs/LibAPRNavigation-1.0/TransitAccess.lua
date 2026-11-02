-- Physical usability does not make a hostile-controlled transit prudent.
-- The shared space resolver owns identity; this policy only consumes it.
local Lib=LibStub("LibAPRNavigation-1.0")
if not Lib:BeginModule("transit-access",1) then return end
local Instance=Lib.Instance

local function SameTransitRegion(owner,point,region)
    if not point then return false end
    local space,reason=owner:ResolveNavigationSpace(point)
    if not space then return nil,reason or "navigation_space_unavailable" end
    return (space.transitRegion or space.id)==region
end

local function EndpointAccess(owner,point,context,character)
    local space,reason=owner:ResolveNavigationSpace(point)
    if not space then return nil,reason or "navigation_space_unavailable" end
    if not space.transitFaction or space.transitFaction=="Neutral" then return true end
    if not character or not character.faction then return nil,"transit_faction_unknown" end
    if space.transitFaction==character.faction then return true end
    local region=space.transitRegion or space.id
    local origin,originReason=SameTransitRegion(owner,context.start or context.playerPosition,region)
    local objective,objectiveReason=SameTransitRegion(owner,context.goal,region)
    if origin==true or objective==true then return true end
    if origin==nil or objective==nil then return nil,originReason or objectiveReason or "navigation_space_unavailable" end
    return false,"hostile_transit_region"
end

function Instance:CheckTransitAccess(from,to,context,character)
    if not self.ResolveNavigationSpace then return true end
    context=context or {}
    for _,point in ipairs({from,to}) do
        local allowed,reason=EndpointAccess(self,point,context,character)
        if allowed~=true then return allowed,reason end
    end
    return true
end
