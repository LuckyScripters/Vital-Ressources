type UtilitiesModule = {
	ProtectInstance : (self : UtilitiesModule, instance : Instance) -> (),
	UnprotectInstance : (self : UtilitiesModule, instance : Instance) -> (),
	DisableLogs : (self : UtilitiesModule) -> boolean,
	Create : (self : UtilitiesModule, className : string, instanceType : "Instance" | "Drawing", protected : boolean, properties : {[string] : any}) -> Instance | {[string] : any}?,
	ThrowErrorUI : (self : UtilitiesModule, title : string, text : string, options : {{Text : string, Callback : () -> ()}}?) -> ()
}

local CoreGui = game:GetService("CoreGui")
local ScriptContext = game:GetService("ScriptContext")

local robloxGui = CoreGui.RobloxGui
local modules = robloxGui.Modules
local errorPrompt = require(modules.ErrorPrompt)

local requirements = loadstring(game:HttpGet("https://raw.githubusercontent.com/LuckyScripters/Vital-Ressources/refs/heads/main/Common/Requirements.lua", true))()

local Utilities : UtilitiesModule = {} :: UtilitiesModule

local oldIndex = nil
local oldNamecall = nil

local newDrawing = requirements:Call("NewCClosure", Drawing.new)
local newInstance = requirements:Call("NewCClosure", Instance.new)

local protectedInstances = {}

function Utilities:ProtectInstance(instance : Instance)
	if not table.find(protectedInstances, instance, 1) then
		table.insert(protectedInstances, instance)
	end
end

function Utilities:UnprotectInstance(instance : Instance)
	if table.find(protectedInstances, instance, 1) then
		table.remove(protectedInstances, table.find(protectedInstances, instance, 1))
	end
end

function Utilities:DisableLogs() : boolean
	local success, result = pcall(function()
		for index, signal in {ScriptContext.Error} do
			for index, connection in requirements:Call("GetConnections", signal) do
				connection:Disable()
			end
		end
	end)
	if not success then
		warn("Failed to disable logs! Error: " .. result)
		return false
	end
	return true
end

function Utilities:Create(className : string, instanceType : "Instance" | "Drawing", protected : boolean, properties : {[string] : any}) : Instance | {[string] : any}?
	if instanceType == "Instance" then
		local instance = newInstance(className)
		if protected then
			Utilities:ProtectInstance(instance)
		end
		for propertieName, propertieValue in properties do
			instance[propertieName] = propertieValue
		end
		return instance
	elseif instanceType == "Drawing" then
		local drawing = newDrawing(className)
		if protected then
			Utilities:ProtectInstance(drawing)
		end
		for propertieName, propertieValue in properties do
			drawing[propertieName] = propertieValue
		end
		return drawing
	end
	return nil
end

function Utilities:ThrowErrorUI(title : string, text : string, options : {{Text : string, Callback : () -> ()}}?)
	local identity = requirements:Call("GetIdentity")
	local remadeOptions = {}
	requirements:Call("SetIdentity", 6)
	local errorGui = Utilities:Create("ScreenGui", "Instance", true, {
		Parent = CoreGui
	})
	errorGui.Name = "RobloxErrorPrompt"
	local prompt = errorPrompt.new("Default")
	prompt._hideErrorCode = true
	prompt:setErrorTitle(title)
	if options then
		for index, option in options do
			table.insert(remadeOptions, {
				Text = option.Text,
				Callback = function()
					if option.Callback then
						option.Callback()
					end
					prompt:_close()
					Utilities:UnprotectInstance(errorGui)
					errorGui:Destroy()
				end,
				Primary = index == 1
			})
		end
	end
	prompt:updateButtons(remadeOptions ~= {} and remadeOptions or {{
		Text = "OK",
		Callback = function()
			prompt:_close()
		end,
		Primary = true
	}}, "Default")
	prompt:setParent(errorGui)
	prompt:_open(text)
	requirements:Call("SetIdentity", identity)
end

oldIndex = requirements:Call("HookMetamethod", game, "__index", requirements:Call("NewCClosure", function(self : Instance, index : string)
	if requirements:Call("CheckCaller") then
		return oldIndex(self, index)
	end
	if table.find(protectedInstances, self, 1) then
		return nil
	end
	return oldIndex(self, index)
end))

oldNamecall = requirements:Call("HookMetamethod", game, "__namecall", requirements:Call("NewCClosure", function(self : Instance, ... : any)
	if requirements:Call("CheckCaller") then
		return oldNamecall(self, ...)
	end
	local result = oldNamecall(self, ...)
	local arguments = table.pack(...)
	local namecallmethod = requirements:Call("GetNamecallMethod")
	if namecallmethod == "WaitForChild" then
		if table.find(protectedInstances, result, 1) then
			local childName, timeout = arguments[1], arguments[2]
			result = nil
			task.delay(timeout or 5, function()
				warn("Infinite yield possible on '" .. self.GetFullName(self) .. ":WaitForChild(\"" .. tostring(childName) .. "\")'")
			end)
		end
	elseif namecallmethod == "FindFirstChild" then
		if table.find(protectedInstances, result, 1) then
			result = nil
		end
	elseif namecallmethod == "GetChildren" or namecallmethod == "GetDescendants" then
		if typeof(result) == "table" then
			for index, value in result do
				if table.find(protectedInstances, value, 1) then
					table.remove(result, index)
				end
				for index, protectedInstance in protectedInstances do
					if namecallmethod == "GetDescendants" and value.IsDescendantOf(value, protectedInstance) then
						table.remove(result, index)
					end
				end
			end
		end
	else
		return oldNamecall(self, ...)
	end
	return result
end))

return Utilities
