local shown,opened,mutated=0,0,0
local L=setmetatable({UI_PERFORMANCE='Performance'},{__index=function(_,k)return k end})
LibStub=function(name)assert(name=='AceLocale-3.0');return {GetLocale=function()return L end}end
APR={
 NewModule=function()return {}end,
 TrimString=function(_,s)return s:match('^%s*(.-)%s*$')end,
 RemoveContiguousSpaces=function(_,s)return s:gsub('%s+',' ')end,
 NavigationBenchmark={Show=function()shown=shown+1 end},
 settings={profile={enableAddon=false},OpenSettings=function()opened=opened+1 end},
 PrintInfo=function()mutated=mutated+1 end,
}
assert(loadfile('APR-Core/core/Commands.lua'))()
APR.command:SlashCmd(' NaVBeNcH ')
assert(shown==1 and opened==0 and mutated==0)
assert(APR.settings.profile.enableAddon==false)
local help=APR.command:GetHelpEntries()
local found=0
for _,entry in ipairs(help)do
 if entry[1]=='/apr navbench' then assert(entry[2]:find('V1') and entry[2]:find('V2'));found=found+1 end
end
assert(found==1)
APR.NavigationBenchmark=nil
APR.command:SlashCmd('navbench')
assert(opened==0 and mutated==0)
print('Navigation benchmark command: readonly entry while APR disabled, discoverable help, optional module guarded passed')
