type RequirementsModule = {
	Call : (self : RequirementsModule, functionName : string, ...any) -> any?,
	IsCompatible : (self : RequirementsModule) -> (boolean, {string})
}

local requiredFunctions = {
	["CloneRef"] = cloneref or "nil",
	["IsFolder"] = isfolder or "nil",
	["ReadFile"] = readfile or "nil",
	["DelFolder"] = delfolder or "nil",
	["WriteFile"] = writefile or "nil",
	["GetUpValue"] = getupvalue or debug.getupvalue or "nil",
	["MakeFolder"] = makefolder or "nil",
	["CheckCaller"] = checkcaller or "nil",
	["GetIdentity"] = (syn and syn.get_thread_identity) or get_thread_identity or getidentity or getthreadidentity or "nil",
	["NewCClosure"] = newcclosure or "nil",
	["SetIdentity"] = (syn and syn.set_thread_identity) or set_thread_identity or setidentity or setthreadidentity or "nil",
	["SetReadOnly"] = setreadonly or "nil",
	["GetMetatable"] = getrawmetatable or debug.getmetatable or "nil",
	["HookFunction"] = hookfunction or detour_function or "nil",
	["CloneFunction"] = clonefunction or "nil",
	["GetConnections"] = get_signal_cons or getconnections or "nil",
	["HookMetamethod"] = hookmetamethod or (hookFunction and function(instance : Instance, method : string, newFunction : (...any) -> (...any))
		local metatable = getrawmetatable(instance) or debug.getmetatable(instance)
		setreadonly(metatable, false)
		return hookfunction(metatable[method], newcclosure(newFunction))
	end) or "nil",
	["GetNamecallMethod"] = getnamecallmethod or "nil",
}

local Requirements : RequirementsModule = {} :: RequirementsModule

function Requirements:Call(functionName : string, ... : any) : any?
	local functionValue = requiredFunctions[functionName] or getgenv()[functionName]
	if functionValue then
		local success, result = pcall(functionValue, ...)
		if not success then
			warn("Error when trying to call" .. " " .. functionName .. "\n" .. result)
			return nil
		end
		return result
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
