local F=dofile('tests/lua/navigation_v2_calibration/chain_fixture.lua')
for _,client in ipairs({'Standard','Camelot'})do
    local e=F.Raw(client)
    local options=e:Options({portals={},personal={{id='recall',kind='spell',spellID=901,from='start',to='exit',
        name='Recall',destination={space='far',phase='present'},useSeconds=2,loadingSeconds=3,
        cooldownSeconds=60,timeoutSeconds=60,moneyCopper=0}},observePersonal=true,personalAPI=e.api,
        personalOrigin={node='start',space='home',phase='present',reliable=true,indoors=true}})
    assert(e.host:Enable(F.Graph(),options))
    local result=e:Plan()
    assert(result.estimatedSeconds==10 and e:Start(result).kind=='personal')
    assert(e.host:GetCalibrationStats().accepted==0,'offered use is not a started measurement')
    assert(e.host:GetPersonalButton())
    e.buttons[1]:HardwareClick()
    local action=e.host:GetTravelAction()
    assert(action.phase=='awaiting_transition' and e.host.travel:IsCommitted())
    local travel,journey=e.host.travel,e.host.journey
    local receipt=travel.personalExecution:GetState()
    local usedAt,deadline=receipt.usedAt,receipt.deadline
    e.time=102;e:Fire('PLAYER_LEAVING_WORLD')
    e.time=107;e:Fire('PLAYER_ENTERING_WORLD',false,false)
    assert(e.host.travel==travel and e.host:GetCalibrationStats().accepted==0)
    assert(e.host:GetTravelAction().attempt==action.attempt and e.host:GetTravelAction().deadline==deadline)
    local revision=e.host.planner.revision
    assert(e.host:SetCalibrationCost('personal/recall/loading',9))
    assert(e.host.planner.revision==revision and e.host.travel==travel,'pending manual cost must defer while committed')
    local current=travel.personalExecution:GetState()
    assert(current.usedAt==usedAt and current.deadline==deadline and current.attempt==receipt.attempt)
    local realApply=e.host.planner.ApplyCalibrationCosts
    local batches,priceRevisions=0,0
    e.host.planner.ApplyCalibrationCosts=function(planner,updates)
        local before=planner.revision
        local changed,reason=realApply(planner,updates)
        if changed then batches=batches+1;priceRevisions=priceRevisions+planner.revision-before end
        return changed,reason
    end
    local realPlan=e.host.Plan
    local recoveries=0
    e.host.Plan=function(host,...)
        recoveries=recoveries+1;return realPlan(host,...)
    end
    e.casting=false;e.time=110
    local proof={sequence=1,reliable=true,loading=false,node='exit',space='far',phase='present',
        transition={personalId='recall',from='start',to='exit',complete=true,attempt=action.attempt}}
    local observed=e.host:ObserveTravel(proof)
    assert(observed.kind=='replan',observed.kind..'/'..tostring(observed.reason))
    assert(e.host:GetCalibrationStats().accepted==1,'normal committed loading survives future route invalidation')
    assert(batches==1 and priceRevisions==1 and recoveries==1,'one price revision and one recovery; fresh native facts may also revise')
    assert(e.host.journey==journey and journey.viaIndex==1,'same objective and confirmed visit cursor')
    assert(e.host.personalSource.origin.node=='exit' and e.host.personalSource.origin.space=='far'
        and e.host.personalSource.origin.phase=='present' and e.host.personalSource.origin.reliable==true,
        'accepted personal arrival must retain its observed origin for the next planning capture')
    assert(e.host.planner.personal.byId.recall.useSeconds==2,'fixed use duration is never calibrated')
    assert(e.host:GetCalibrationCost('personal/recall/loading')==9)
    local replacement=e.host.job
    assert(e:Finish().estimatedSeconds==5)
    local _,why=e.host:ObserveTravel(proof)
    assert(why=='no_travel' and e.host.job==replacement)
    assert(e.host:ResetCalibrationCosts('personal/recall/loading','manual'))
    assert(e.host:GetCalibrationCost('personal/recall/loading')==5)
    assert(e.protectedUses==1 and e.quests==0 and APR.navigation.legacy)
    e.host:Disable()
end
