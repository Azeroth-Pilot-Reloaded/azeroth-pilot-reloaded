local F=dofile('tests/lua/navigation_v2_calibration/chain_fixture.lua')
for _,client in ipairs({'Standard','Camelot'})do
    local old=F.Store(client,{['portal/door/loading']=7})
    old.navigationV2Costs.version=0
    local otherClient=client=='Camelot' and 'Retail' or 'Forever'
    old.navigationV2Costs.profiles[otherClient]={foreign='keep'}
    APRSettings={foreign={keep=true}}
    local settings=APRSettings
    local e=F.Host(client,nil,nil,old)
    assert(e.host:GetCalibrationCost('portal/door/loading')==7)
    assert(e:Plan().estimatedSeconds==15)
    assert(e.host:SetCalibrationCost('portal/door/loading',8))
    local saved=APRNavigationCharacterSettings
    assert(saved~=old and saved.foreign==old.foreign and saved.oldTaxiDurations==old.oldTaxiDurations and APRSettings==settings)
    local costs=saved.navigationV2Costs.profiles[e.calOptions.client]['synthetic-build']['synthetic-character'].desk.costs
    assert(costs['portal/door/loading'].measuredSeconds==7 and costs['portal/door/loading'].manualSeconds==8)
    assert(saved.navigationV2Costs.profiles[otherClient]==old.navigationV2Costs.profiles[otherClient])
    assert(old.navigationV2Costs.version==0 and old.navigationV2Costs.profiles[e.calOptions.client]['synthetic-build']['synthetic-character'].desk.costs['portal/door/loading']==7)
    assert(e.host:ResetCalibrationCosts('portal/door/loading','manual'))
    assert(e.host:GetCalibrationCost('portal/door/loading')==7)
    e.host:Disable()
    for _,namespace in ipairs({{version=98,foreign='future'},'malformed'})do
        local root={foreign='keep',navigationV2Costs=namespace}
        e=F.Raw(client,root)
        local enabled,reason=e.host:Enable(F.Graph(),e:Options())
        assert(enabled==nil and reason and APRNavigationCharacterSettings==root and root.navigationV2Costs==namespace)
    end
end
