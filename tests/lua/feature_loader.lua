-- Load a feature in isolation using its real XML order and its constants.
local loadManifest = dofile("tests/lua/manifest_fixture.lua")
local manifests, constantNamespaces = {}, {}

for entry in io.lines("APR.toc") do
    local feature = entry:match("^(APR%-Core/features/[%w_]+/[%w_]+)%.xml%s*$")
    if feature then manifests[feature .. ".lua"] = feature .. ".xml" end

    local directory, group = entry:match("^(APR%-Core/features/(%w+))/Constants%.lua%s*$")
    if directory then
        constantNamespaces[directory] = group:gsub("^%l", string.upper) .. "Constants"
    end
end

return function(load, globals)
    return function(path)
        local directory = path:match("^(APR%-Core/features/%w+)/[^/]+%.lua$")
        local namespace = constantNamespaces[directory]
        if namespace and globals.APR and not globals.APR[namespace] and path ~= directory .. "/Constants.lua" then
            load(directory .. "/Constants.lua")
        end
        local manifest = manifests[path]
        if manifest then
            loadManifest(manifest, { load = load })
            return
        end
        return load(path)
    end
end
