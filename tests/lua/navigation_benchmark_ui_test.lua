-- Real benchmark controller behind strict widget doubles: UI actions own no navigation.
local ns={NavigationV2Graph={Budgets={sliceMs=1,cpuMs=100,elapsedMs=5000}}}
assert(loadfile("APR-Core/features/navigation/NavigationBenchmarkCase.lua"))("test",ns)
assert(loadfile("APR-Core/features/navigation/NavigationBenchmarkRun.lua"))("test",ns)

local frames,windows,hideHooks,fontRegistrations=0,0,0,0
local methods={}
local function widget(kind,parent)
    frames=frames+1
    return setmetatable({kind=kind,parent=parent,shown=true,enabled=true,scripts={},text="",width=400,height=300},
        {__index=function(_,key) return assert(methods[key],"Unexpected widget API: "..key) end})
end
function methods:SetScript(name,fn) assert(fn==nil or type(fn)=="function");self.scripts[name]=fn end
function methods:GetScript(name) return self.scripts[name] end
function methods:HookScript(name,fn)
    local old=self.scripts[name]
    self.scripts[name]=function(...) if old then old(...) end;fn(...) end
end
function methods:Fire(name,...) if self.scripts[name] then return self.scripts[name](self,...) end end
function methods:Show() local old=self.shown;self.shown=true;if not old then self:Fire("OnShow") end end
function methods:Hide() local old=self.shown;self.shown=false;if old then self:Fire("OnHide") end end
function methods:IsShown() return self.shown end
function methods:Raise() self.raised=true end
function methods:SetPoint(...) self.lastPoint={...} end
function methods:ClearAllPoints() self.lastPoint=nil end
function methods:SetSize(w,h) self.width,self.height=w,h end
function methods:SetWidth(w) self.width=w end
function methods:SetHeight(h) self.height=h end
function methods:GetWidth() return self.width end
function methods:GetHeight() return self.height end
function methods:GetSize() return self.width,self.height end
function methods:SetResizeBounds(w,h) self.minimumWidth,self.minimumHeight=w,h end
function methods:SetText(value)
    assert(type(value)=="string","Widget text must be a string")
    self.text=value
    if self.kind=="EditBox" then self:Fire("OnTextChanged",false) end
end
function methods:GetText() return self.text end
function methods:GetStringHeight() local _,n=self.text:gsub("\n","");return (n+1)*14 end
function methods:SetJustifyV(value) self.justifyV=value end
function methods:SetWordWrap(value) self.wrap=value end
function methods:SetMaxLetters(value) self.maximumLetters=value end
function methods:SetTextInsets(...) self.insets={...} end
function methods:ClearFocus() self.focused=false end
function methods:Enable() self.enabled=true end
function methods:Disable() self.enabled=false end
function methods:SetEnabled(value) assert(self.kind=="Button");self.enabled=value end
function methods:IsEnabled() return self.enabled end
function methods:SetScrollChild(value) self.child=value end
function methods:SetVerticalScroll(value) self.offset=value end
function methods:Click() if self.enabled then self:Fire("OnClick") end end

UIParent={GetWidth=function()return 1200 end,GetHeight=function()return 900 end}
SOURCE,TARGET,PLAYER,CANCEL,UNAVAILABLE="Source","Target","Player","Cancel","Unavailable"
PERFORMANCE_LABEL="Global performance"
MILLISECONDS_ABBR,SECONDS_ABBR="ms","s"
local locale={UI_PERFORMANCE="Performance",UI_CAPTURE="Capture",UI_STOP="Stop",UI_CALLS="Calls",
    COPY_HELPER="Copy helper",STATUS_EXPORT="Export"}
function LibStub(name)
    assert(name=="AceLocale-3.0")
    return {GetLocale=function(_,addon)assert(addon=="APR");return locale end}
end
function CreateFrame(kind,_,parent) assert(kind=="Frame");return widget(kind,parent) end
local function forbidden() error("Benchmark UI touched native position or ordinary navigation") end
C_Map=setmetatable({}, {__index=function()return forbidden end})
GetPlayerMapPosition,UnitPosition,SetSuperTrackedUserWaypoint=forbidden,forbidden,forbidden
-- The real recorder needs its public clock even while UI code is forbidden
-- from acquiring native observations. Keep that exception caller-specific.
function GetTime()
    local caller=debug.getinfo(2,"f").func
    assert(APRInstrumentation and (caller==APRInstrumentation.ResetLog or caller==APRInstrumentation.Record),
        "Benchmark UI acquired a native clock instead of using its owner")
    return 0
end
assert(not pcall(GetTime),"Direct non-recorder clock access must remain forbidden")
APR={UI={},NavigationV2={Enable=forbidden,SetTarget=forbidden},NextStep=forbidden}
function APR:RegisterFontString(_,scope,options)
    assert(scope=="general");fontRegistrations=fontRegistrations+1
    if options.onApplied then options.onApplied() end
end
local UI=APR.UI
function UI:Label(parent,text,size,role)
    local value=widget("FontString",parent);value:SetText(text or "")
    value.fontSize,value.role=size,role
    return value
end
function UI:Panel(parent) return widget("Frame",parent) end
function UI:Section(parent,title)
    local panel=self:Panel(parent);panel.title=self:Label(panel,title,14,"accent");return panel
end
function UI:Window(name,title,w,h)
    assert(name=="APRNavigationBenchmark");windows=windows+1
    local frame=widget("Frame");frame:SetSize(w,h);frame.title=title
    frame.content=widget("Frame",frame)
    frame:SetScript("OnHide",function()hideHooks=hideHooks+1 end)
    frame:Hide();return frame
end
function UI:Button(parent,text,width,callback)
    local button=widget("Button",parent);button:SetText(text);button:SetWidth(width)
    button:SetScript("OnClick",callback);return button
end
function UI:SetButtonActive(button,active) button.selected=active end
function UI:SearchBox(parent,width,placeholder,changed)
    local edit=widget("EditBox",parent);edit:SetWidth(width)
    edit.placeholder=self:Label(edit,placeholder);edit.searchIcon=widget("Texture",edit)
    edit:SetScript("OnTextChanged",function(self)changed(self:GetText())end)
    return edit
end
function UI:Scroll(parent) return widget("ScrollFrame",parent) end
function UI:Tooltip(control,title) control.tooltip=title end
local copied,reports=0,{}
function UI:ShowTextReport(title,text,owner)
    copied=copied+1;reports[#reports+1]={title=title,text=text,owner=owner}
end

local now,cpu=0,0
local starts,steps,cancels,positionReads=0,0,0,0
local player={mapID=81,x=22,y=33}
local requests,driverSteps={},{}
local outcomes={v1={status="complete",estimatedSeconds=0,optimal=false,estimateScope="known-graph"},
    v2={status="unknown",reason="coverage_missing",estimatedSeconds=999}}
local function factory(name)
    return function(request)
        requests[#requests+1]={name=name,mapID=request.from.mapID,x=request.from.x,y=request.from.y}
        request.from.x=99 -- The UI must not replace the controller's immutable paired capture.
        return {Step=function()
            driverSteps[name]=(driverSteps[name] or 0)+1
            return outcomes[name]
        end,GetMetrics=function()
            return {stepCalls=0,calculationsStarted=1,calculationsCompleted=0,operations=0,
                    preparedNodes=0,relaxedEdges=0,preparationMs=0}
        end,Cancel=function()end}
    end
end
local runner=assert(ns.NavigationBenchmarkRun.New({clock=function()return now end,
    profileClock=function()return cpu end,factories={v1=factory("v1"),v2=factory("v2")}}))
local owner={}
APR.NavigationBenchmark=owner
function owner:Start(input,mode)
    starts=starts+1
    local capture,reason=ns.NavigationBenchmarkCase.Capture(input,function()
        positionReads=positionReads+1;return player
    end)
    if not capture then return nil,reason end
    self.capture=capture
    return runner:Start(capture,mode)
end
function owner:Step() steps=steps+1;return runner:Step() end
function owner:Cancel() cancels=cancels+1;return runner:Cancel() end
function owner:GetState() return runner:GetState() end
function owner:GetCapture() return self.capture and self.capture:Copy() end
function owner:GetContext()
    return {client="synthetic-client",build="synthetic-build",cache="not-measured",provenance="fixture-source"}
end
function owner:GetReport() return "raw|report\ncontext=fixture-source\nsteps="..steps end

local before=frames
assert(loadfile("APR-Core/ui/NavigationBenchmark.lua"))("test",{})
assert(frames==before and windows==0 and starts==0 and positionReads==0,"Loading must create nothing or read no position")
local frame=owner:Show()
assert(frame and frame:IsShown() and windows==1 and frame:GetScript("OnUpdate")==nil)
assert(frame.title:find(PERFORMANCE_LABEL,1,true),"Compatible GlobalStrings take priority over locale keys")
assert(fontRegistrations>0 and frame.buttons.cancel:GetText()==CANCEL)
owner:Show();assert(windows==1,"Repeated Show must reuse the window")
local function text(engine) return frame.results[engine].text:GetText() end
local function contains(engine,value) assert(text(engine):find(value,1,true),engine.." missing "..value.."\n"..text(engine)) end
local function fill()
    for key,value in pairs({mapID="71",x="0",y="20"}) do frame.inputs.from[key]:SetText(value) end
    for key,value in pairs({mapID="72",x="30",y="40"}) do frame.inputs.to[key]:SetText(value) end
end
local function tick()
    local update=frame:GetScript("OnUpdate");assert(update,"Expected an active update")
    local count=steps;update(frame,.016);assert(steps==count+1,"Exactly one owner Step per tick")
end
fill();frame.buttons.v1:Click()
assert(starts==1 and frame:GetScript("OnUpdate") and #requests==0)
tick();tick()
assert(owner:GetState().status=="finished" and frame:GetScript("OnUpdate")==nil)
assert(#requests==1 and requests[1].x==0 and driverSteps.v1==1)
contains("v1","driver calls): 1");contains("v1","metrics.stepCalls: 0")
contains("v1","cpuMs");contains("v1","operations: 0");contains("v1","expandedNodes: "..UNAVAILABLE)
contains("v1","wallMs (elapsed ms): 0");contains("v1","cpuMs (active CPU ms): 0")
contains("v1","estimatedSeconds (ETA s): 0");contains("v1","metrics.calculationsCompleted: 0")
contains("v1","estimatedSeconds");contains("v1","optimal: false");contains("v1","known-graph")
contains("v2","status: "..UNAVAILABLE)
assert(not text("v1"):lower():find("speedup",1,true))
assert(frame.context:GetText():find("synthetic-build",1,true) and frame.context:GetText():find("fixture-source",1,true))
frame.buttons.copy:Click()
assert(copied==1 and reports[1].text==owner:GetReport() and reports[1].owner==frame)

-- Editing invalidates results/copy immediately, including after a finished run.
frame.inputs.to.x:SetText("31")
contains("v1","status: "..UNAVAILABLE)
assert(not frame.buttons.copy:IsEnabled())
frame.buttons.copy:Fire("OnClick");assert(copied==1,"Never copy a stale case after an edit")
frame.buttons.v2:Click();tick();tick()
contains("v2","coverage_missing")
assert(not text("v2"):find("999",1,true),"Unknown must not display a route ETA")
contains("v2","estimatedSeconds");contains("v2",UNAVAILABLE)

-- Selecting player does not sample; Run samples once and fills controls without cancelling itself.
frame.buttons.player:Click();assert(positionReads==0 and frame.buttons.player.selected)
local oldCancels=cancels
frame.buttons.both:Click()
assert(positionReads==1 and cancels==oldCancels and frame:GetScript("OnUpdate"))
assert(frame.inputs.from.mapID:GetText()=="81" and frame.inputs.from.x:GetText()=="22")
player={mapID=91,x=88,y=99}
local requestCount=#requests
tick();tick();tick();tick()
assert(#requests==requestCount+2 and requests[requestCount+1].name=="v1" and requests[requestCount+2].name=="v2")
assert(requests[requestCount+1].x==22 and requests[requestCount+2].x==22 and positionReads==1)
assert(frame:GetScript("OnUpdate")==nil and owner:GetState().status=="finished")

-- Active edit/cancel/hide remove update work; retained callbacks cannot advance the cancelled run.
frame.buttons.both:Click();tick()
local stale=frame:GetScript("OnUpdate");local oldSteps=steps;oldCancels=cancels
frame.inputs.to.y:SetText("41")
assert(cancels==oldCancels+1 and frame:GetScript("OnUpdate")==nil)
stale(frame,.016);assert(steps==oldSteps)
contains("v1","status: "..UNAVAILABLE)
frame.buttons.v1:Click();tick();frame.buttons.cancel:Click()
assert(owner:GetState().status=="cancelled" and frame:GetScript("OnUpdate")==nil)
frame.buttons.both:Click();tick()
local oldHide=hideHooks;oldCancels=cancels;oldSteps=steps
frame:Hide()
assert(hideHooks==oldHide+1 and cancels==oldCancels+1 and frame:GetScript("OnUpdate")==nil)
owner:Show();assert(windows==1 and steps==oldSteps and frame:GetScript("OnUpdate")==nil)

-- Invalid input surfaces the owner's reason without reviving its previous metrics.
frame.inputs.to.mapID:SetText("");frame.buttons.both:Click()
assert(frame:GetScript("OnUpdate")==nil and frame.status:GetText():find("benchmark_goal_map_invalid",1,true))
contains("v1","status: "..UNAVAILABLE)
assert(not frame.buttons.copy:IsEnabled())

-- Failed player capture must not leave a previous location looking current.
frame.inputs.to.mapID:SetText("72")
player=nil;local oldReads=positionReads
frame.buttons.both:Click()
assert(positionReads==oldReads+1 and frame:GetScript("OnUpdate")==nil)
assert(frame.status:GetText():find("benchmark_player_position_unavailable",1,true))
assert(frame.inputs.from.mapID:GetText()=="" and frame.inputs.from.x:GetText()=="",
    "Unavailable player position must clear the previous captured point")

-- A result returning after an input edit cannot repopulate invalidated columns.
frame.buttons.player:Click();assert(not frame.buttons.player.selected)
fill();frame.buttons.v1:Click();tick()
local stepMethod=owner.Step
function owner:Step()
    local state=stepMethod(self)
    frame.inputs.to.x:SetText("35")
    return state
end
tick();owner.Step=stepMethod
contains("v1","status: "..UNAVAILABLE)
assert(frame:GetScript("OnUpdate")==nil and not frame.buttons.copy:IsEnabled())

-- Optional profiling/counters remain unavailable while measured wall time stays zero.
runner=assert(ns.NavigationBenchmarkRun.New({clock=function()return 0 end,factories={
    v1=function()return {Step=function()return {status="complete",estimatedSeconds=0}end}end}}))
frame.buttons.v1:Click();tick();tick()
contains("v1","wallMs (elapsed ms): 0")
contains("v1","cpuMs (active CPU ms): "..UNAVAILABLE)
contains("v1","metrics.stepCalls: "..UNAVAILABLE)
contains("v1","driver calls): 1")
contains("v1","estimatedSeconds (ETA s): 0")

-- Rich native contexts must not let V1 consume the space needed for V2's domain/provenance.
local rich={profile="fixture-profile",build="fixture-build",cache="not-measured",
    character={level=0,class="fixture-class"},engines={
        v1={scope="legacy-route-domain",dataBuild="legacy-data-build"},
        v2={scope="admitted-graph-domain",dataBuild="v2-data-build",reason="v2-coverage-unavailable"}}}
for i=1,20 do
    rich.engines.v1["field"..i]="left-"..i
    rich.engines.v2["field"..i]="right-"..i
end
function owner:GetContext() return rich end
owner:Show()
local context=frame.context:GetText()
for _,value in ipairs({"engines.v1.scope: legacy-route-domain","engines.v2.scope: admitted-graph-domain",
    "engines.v2.dataBuild: v2-data-build","engines.v2.reason: v2-coverage-unavailable"}) do
    assert(context:find(value,1,true),"Context silently omitted "..value)
end
assert(frame.contextPane.scroll.child,"The complete rendered context must remain scrollable")
-- Even an oversized V1 context must not hide V2; truncation is explicit.
for i=21,90 do rich.engines.v1["field"..i]="overflow-"..i end
owner:Show();context=frame.context:GetText()
assert(context:find("engines.v2.reason: v2-coverage-unavailable",1,true))
assert(context:find("…",1,true),"Bounded context must disclose any truncation")
assert(frame.inputs.from.mapID.placeholder:GetText()=="UiMapID" and
       frame.inputs.to.mapID.placeholder:GetText()=="UiMapID","Map fields are UiMapIDs, not world/instance IDs")
local completeReport="raw|report\n"..string.rep("opaque-context\n",180).."v2-end=coverage-unavailable"
function owner:GetReport() return completeReport end
frame.buttons.copy:Click()
assert(reports[#reports].text==completeReport,"Context display limits must not shorten the copied raw report")

-- Keep the failed Start reason when reopening unchanged input; a new edit clears it.
frame.inputs.to.mapID:SetText("");frame.buttons.v1:Click()
frame:Hide();owner:Show()
assert(frame.status:GetText():find("benchmark_goal_map_invalid",1,true))
frame.inputs.to.mapID:SetText("72")
assert(not frame.status:GetText():find("benchmark_goal_map_invalid",1,true))
print("Benchmark UI: lazy window, paired capture, zero/unavailable counters, edit/cancel/hide lifecycle and raw report copy passed")
