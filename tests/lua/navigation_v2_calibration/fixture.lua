local ns={}
assert(loadfile('APR-Core/libs/LibAPRNavigation-2.0/Calibration.lua'))('test',ns)
local F={Core=ns.NavigationV2Calibration,ns=ns}
function F.New(store,identity)
    return assert(F.Core.New({store=store,identity=identity or {
        client='Forever',character='invented-character',computer='desk',build='test-build'},
        definitions={{key='taxi/flight/ride',defaultSeconds=20,component='ride'},
            {key='taxi/flight/loading',defaultSeconds=2,component='loading'}}}))
end
function F.Begin(c,now)
    local owner,attempt={},{}
    local handle=assert(c:Begin({ride='taxi/flight/ride',loading='taxi/flight/loading'},owner,attempt,now))
    return handle,owner,attempt
end
return F
