type ConfigManager = {
	__index : ConfigManager,
	new : () -> ConfigManager,
	AddConfig : (self : ConfigSettings, name : string, config : {[string] : any}) -> (),
	GetSettings : (self : ConfigSettings, name : string) -> {[string] : any}?,
	ModifySetting : (self : ConfigSettings, name : string, key : string, value : any) -> boolean,
	OnConfigChanged : (self : ConfigSettings, callback : (name : string, key : string, newValue : any, oldValue : any) -> ()) -> ()
}

type ConfigSettings = typeof(setmetatable({} :: {
	Configs : {[string] : ConfigSettings},
	Listerners : {[string] : {Disconnect : () -> ()}}
}, {} :: ConfigManager))

local HttpService = game:GetService("HttpService")

local ConfigManager : ConfigManager = {} :: ConfigManager
ConfigManager.__index = ConfigManager

function ConfigManager.new() : ConfigManager
	local self = setmetatable({}, ConfigManager)
	self.Configs = {}
	self.Listeners = {}
	return self
end

function ConfigManager:GetSettings(name : string) : {[string] : any}?
	return self.Configs[name]
end

function ConfigManager:AddConfig(name : string, config : {[string] : any})
	if self.Configs[name] then
		warn("Configuration with this name already exists: " .. name)
		return
	end
	self.Configs[name] = settings
end

function ConfigManager:OnConfigChanged(callback : (name : string, key : string, newValue : any, oldValue : any) -> ())
	local id = HttpService:GenerateGUID(false)
	self.Listeners[id] = callback
	return {
		Disconnect = function()
			self.Listeners[id] = nil
		end,
	}
end

function ConfigManager:ModifySetting(name : string, key : string, value : any) : boolean
	local config = self.Configs[name]
	if not config then
		return false
	end
	local oldValue = config[key]
	config[key] = value
	if oldValue ~= value then
		for id, callback in self.Listeners do
			callback(name, key, value, oldValue)
		end
	end
	return true
end

return ConfigManager
