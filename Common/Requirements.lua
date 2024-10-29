type RequirementsModule = {
	Call : (self : RequirementsModule, functionName : string, ...any) -> any?,
	IsCompatible : (self : RequirementsModule) -> (boolean, {string})
}

local requiredFunctions = {
	["CloneRef"] = cloneref,
	["IsFolder"] = isfolder,
	["ReadFile"] = readfile,
	["DelFolder"] = delfolder,
	["WriteFile"] = writefile,
	["MakeFolder"] = makefolder,
	["CheckCaller"] = checkcaller,
	["GetIdentity"] = (syn and syn.get_thread_identity) or get_thread_identity or getidentity or getthreadidentity,
	["NewCClosure"] = newcclosure,
	["SetIdentity"] = (syn and syn.set_thread_identity) or set_thread_identity or setidentity or setthreadidentity,
	["SetReadOnly"] = setreadonly,
	["GetMetatable"] = getrawmetatable or debug.getmetatable,
	["HookFunction"] = hookfunction or detour_function,
	["CloneFunction"] = clonefunction,
	["GetConnections"] = get_signal_cons or getconnections,
	["HookMetamethod"] = hookmetamethod or (hookFunction and function(instance : Instance, method : string, newFunction : (...any) -> (...any))
		local metatable = getrawmetatable(instance) or debug.getmetatable(instance)
		setreadonly(metatable, false)
		return hookfunction(metatable[method], newcclosure(newFunction))
	end),
	["GetNamecallMethod"] = getnamecallmethod,
}

local Requirements : RequirementsModule = {} :: RequirementsModule

function Requirements:Call(functionName : string, ... : any) : any?
	local functionValue = requiredFunctions[functionName] or getgenv()[functionName]
	if functionValue then
		return functionValue(...)
	end
	return nil
end

function Requirements:IsCompatible() : (boolean, {string})
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
