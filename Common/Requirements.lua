type RequirementsModule = {
	Call : (self : RequirementsModule, functionName : string, ...any) -> any?,
	IsCompatible : (self : RequirementsModule) -> (boolean, {string})
}

local Players = cloneref(game:GetService("Players"))

local requiredFunctions = {
    ["IsFile"] = isfile or "nil",
    ["CloneRef"] = cloneref or "nil",
    ["IsFolder"] = isfolder or "nil",
    ["ReadFile"] = readfile or "nil",
    ["DelFolder"] = delfolder or "nil",
    ["WriteFile"] = writefile or "nil",
    ["GetUpValue"] = getupvalue or debug.getupvalue or "nil",
    ["MakeFolder"] = makefolder or "nil",
    ["CheckCaller"] = checkcaller or "nil",
    ["GetIdentity"] = (syn and syn.get_thread_identity) or get_thread_identity or getidentity or getthreadidentity or getthreadcontext or get_thread_context or "nil",
    ["IsRenderObj"] = isrenderobj or "nil",
    ["NewCClosure"] = newcclosure or "nil",
    ["NewLClosure"] = newlclosure or function(callback : (...any) -> ...any)
		return function(...)
			local oldThreadIdentity = getthreadidentity()
			setthreadidentity(8)
			local result = callback(...)
			setthreadidentity(oldThreadIdentity)
			return result
		end
	end or "nil",
    ["SetIdentity"] = (syn and syn.set_thread_identity) or set_thread_identity or setidentity or setthreadidentity or setthreadcontext or set_thread_context or "nil",
    ["SetReadOnly"] = setreadonly or ((make_readonly and make_writeable) and function(tableToEdit : {[any] : any}, readonly : boolean)
		if readonly then
			make_readonly(tableToEdit)
		else
			make_writeable(tableToEdit)
		end
	end) or "nil",
    ["GetMetatable"] = getrawmetatable or debug.getmetatable or "nil",
    ["HookFunction"] = hookfunction or detour_function or replaceclosure or "nil",
    ["CloneFunction"] = clonefunction or "nil",
    ["GetConnections"] = get_signal_cons or getconnections or "nil",
    ["GetCustomAsset"] = getcustomasset or getsynasset or "nil",
    ["HookMetamethod"] = hookmetamethod or (hookfunction and function(instance : Instance, method : string, newFunction : (...any) -> (...any))
		local metatable = getrawmetatable(instance) or debug.getmetatable(instance)
		setreadonly(metatable, false)
		return hookfunction(metatable[method], newcclosure(newFunction))
	end) or "nil",
    ["IsNetworkOwner"] = function(basePart : BasePart)
        local localPlayer = Players.LocalPlayer
        local character = localPlayer.Character
        if not character then
            return false
        end
        local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
        if not humanoidRootPart then
            return false
        end
        if basePart.Anchored then
            return false
        end
        local networkOwnership = gethiddenproperty(basePart, "NetworkOwnershipRule")
        if networkOwnership ~= Enum.NetworkOwnership.Automatic then
            return false
        end
        local maxSimulationRadius = gethiddenproperty(localPlayer, "MaximumSimulationRadius")
        if (basePart.Position - humanoidRootPart.Position).Magnitude > maxSimulationRadius then
            return false
        end
        return (basePart.Position - humanoidRootPart.Position).Magnitude <= gethiddenproperty(localPlayer, "SimulationRadius") / 2
    end,
    ["GetNamecallMethod"] = getnamecallmethod or "nil",
    ["GetRenderProperty"] = getrenderproperty or "nil",
    ["SetRenderProperty"] = setrenderproperty or "nil"
}

local Requirements : RequirementsModule = {} :: RequirementsModule

function Requirements:Call(functionName : string, ... : any) : any?
	local functionValue = requiredFunctions[functionName] or getrenv()[functionName]
	if functionValue and typeof(functionValue) == "function" then
		local success, result = pcall(functionValue, ...)
		if not success then
			warn("Error when trying to call" .. " " .. string.lower(functionName) .. ":" .. " " .. result)
			return nil
		end
		return result
	end
	warn("Failed to get" .. " " .. string.lower(functionName) .. " " .. "because your executor doesn't support it")
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
