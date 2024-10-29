local requiredFunctions = {
    ["CloneRef"] = cloneref,
    ["IsFolder"] = isfolder,
    ["ReadFile"] = readfile,
    ["DelFolder"] = delfolder,
    ["WriteFile"] = writefile,
    ["MakeFolder"] = makefolder,
    ["NewCClosure"] = newcclosure,
    ["SetReadOnly"] = setreadonly,
    ["GetMetatable"] = getrawmetatable or debug.getmetatable,
    ["HookFunction"] = hookfunction or detour_function,
    ["GetConnections"] = get_signal_cons or getconnections,
    ["HookMetamethod"] = hookmetamethod or (hookFunction and function(instance : Instance, method : string, newFunction : (...any) -> (...any))
        local metatable = getrawmetatable(instance) or debug.getmetatable(instance)
        setreadonly(metatable, false)
        return hookfunction(metatable[method], newcclosure(newFunction))
    end),
}

local Requirements = {}

function Requirements:Call(functionName : string, ... : any) : any?
    local functionValue = requiredFunctions[functionName] or getgenv()[functionName]
    if functionValue then
        return functionValue(...)
    end
    return nil
end

function Requirements:IsCompatible() : boolean
    local isCompatible = true
    local unsupportedFunctions = {}
    for functionName, functionValue in requiredFunctions do
        if typeof(functionValue) ~= "function" then
            isCompatible = false
            table.insert(unsupportedFunctions, string.lower(functionName))
        end
    end
    return isCompatible, unsupportedFunctions
end

return Requirements
