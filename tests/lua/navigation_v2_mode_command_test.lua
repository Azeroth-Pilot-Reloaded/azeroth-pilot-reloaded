local mode,calls,opened='v1',{},0
local L=setmetatable({},{__index=function(_,key)return key end})
LibStub=function()return {GetLocale=function()return L end}end
APR={NewModule=function()return {}end,TrimString=function(_,s)return s:match('^%s*(.-)%s*$')end,
    RemoveContiguousSpaces=function(_,s)return s:gsub('%s+',' ')end,
    PrintInfo=function(_,s)calls[#calls+1]=s end,
    settings={profile={enableAddon=false},OpenSettings=function()opened=opened+1 end},
    navigation={GetEngine=function()return mode end,SetEngine=function(_,value)
        if value~='v1' and value~='v2' then return nil,'invalid_engine'end;mode=value;return true
    end}}
dofile('APR-Core/core/Commands.lua')
APR.command:SlashCmd(' NaVeNgInE V2 ')
assert(mode=='v2' and opened==0 and APR.settings.profile.enableAddon==false)
APR.command:SlashCmd('navengine v1');assert(mode=='v1')
APR.command:SlashCmd('navengine nonsense');assert(mode=='v1')
APR.command:SlashCmd('navengine');assert(mode=='v1' and #calls>=3)
local found=0
for _,entry in ipairs(APR.command:GetHelpEntries())do
    if entry[1]=='/apr navengine v1|v2' then found=found+1 end
end
assert(found==1)
print('APR engine command: explicit reversible session choice, help and disabled addon preserved passed')
