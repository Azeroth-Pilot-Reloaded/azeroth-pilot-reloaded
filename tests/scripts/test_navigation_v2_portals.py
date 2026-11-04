"""Static routing certificates cannot be reused for a new portal optimum."""
import unittest

from tests.lua.navigation_v2_sectors.test_prepared import prepared


class PortalRoutingTests(unittest.TestCase):
    def test_missing_native_movement_metadata_is_unknown_without_reusing_static_bounds(self):
        lua, _, _ = prepared([[0, 0, 0]] * 3, [[1, 2, 1000], [2, 3, 1000]])
        lua.execute(b'''
            local movement=assert(ns.LibAPRNavigationV2.NewForeverMovement({initialMode='mount',level=40,
                mountOwned=true,mountUsable=true,canMountHere=true},{dismountSeconds=7}))
            planner=assert(ns.LibAPRNavigationV2.New(source,{clock=function()return 100 end,
                profileClock=options.profileClock,movement=movement}))
            local r=finish(plan(1,3))
            assert(r.status=='unknown' and r.reason=='movement_metadata_missing')
            assert(not r.segments and not r.diagnostics.certificateComplete)
            local stats=planner.preparation.compiled.stats
            assert(stats.geometryLoads==0 and stats.potentialLoads==0 and stats.witnessLoads==0)
        ''')

    def test_dynamic_shortcut_cost_and_observation_invalidate_static_acceleration(self):
        # Atlas optimum is 30s. New 2s portal through node3 beats that bound;
        # a stale certificate would return the audited but now suboptimal30s.
        lua, _, _ = prepared([[0, 0, 0]] * 4,
                             [[1, 2, 10000], [2, 3, 10000], [3, 4, 10000]],
                             landmarks=2, node_limit=2)
        lua.execute(b'''
            local before=finish(plan(1,4))
            assert(before.status=='complete' and before.estimatedSeconds==30)
            local portals={{id='shortcut',from=refs[1],to=refs[3],phase='present',
                destination={space='far',phase='present'},waitSeconds=0,useSeconds=1,
                loadingSeconds=1,timeoutSeconds=30}}
            local observation={revision=1,phase='present',portals={shortcut={open=true,access=true}}}
            local graph=source
            -- The unrelated index entry is deliberately hostile to eager scans.
            graph.index.unused=setmetatable({}, {__index=function()error('World scan')end})
            planner=assert(ns.LibAPRNavigationV2.New(graph,{
                clock=function()return testTime.wall end,profileClock=options.profileClock,
                portals=portals,portalObservation=observation}))
            assert(planner.preparation.compiled.stats.nativeDecodes==0)
            local job=plan(1,4)
            assert(planner.preparation.compiled.stats.nativeDecodes==0)
            local r=finish(job,1)
            assert(r.status=='complete' and r.estimatedSeconds==12)
            assert(r.segments[1].edgeId=='portal:shortcut')
            assert(not r.diagnostics.certificateComplete and not r.diagnostics.witnessEdges)
            local graph=planner.preparation.compiled
            assert(graph.stats.geometryLoads==0 and graph.stats.witnessLoads==0 and graph.stats.potentialLoads==0)
            assert(graph.stats.residentRows<=graph.maxRows)
            local loads=graph.stats.loads
            assert(finish(plan(1,4)).estimatedSeconds==12 and graph.stats.loads==loads)
            assert(planner:SetPortalCosts('shortcut',{loadingSeconds=29}))
            assert(not planner:IsCurrent(r))
            assert(finish(plan(1,4)).estimatedSeconds==30)
            assert(planner:SetPortalCosts('shortcut',{loadingSeconds=0}))
            assert(finish(plan(1,4)).estimatedSeconds==11)
            assert(planner:ObservePortals({revision=2,phase='present',portals={shortcut={open=false,access=true}}}))
            assert(finish(plan(1,4)).estimatedSeconds==30)
            local revision=planner.revision
            local changed,reason=planner:ObservePortals(observation)
            assert(changed==false and reason=='stale_observation' and planner.revision==revision)
            assert(finish(plan(1,4)).estimatedSeconds==30)
            assert(planner.budgets.sliceMs==1 and planner.budgets.cpuMs==100 and planner.budgets.elapsedMs==5000)
        ''')
