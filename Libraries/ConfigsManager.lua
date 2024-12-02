type ConfigManager = {
	__index : ConfigManager,
	new : () -> ConfigSettings,
	AddConfig : (self : ConfigSettings, configName : string, config : {[string] : any}) -> (),
	GetConfig : (self : ConfigSettings, configName : string) -> {[string] : any}?,
	ModifyConfig : (self : ConfigSettings, configName : string, key : string, value : any) -> boolean,
	OnConfigChanged : (self : ConfigSettings, callback : (configName : string, key : string, newValue : any, oldValue : any) -> ()) -> {Disconnect : () -> ()}
}

type ConfigSettings = typeof(setmetatable({} :: {
	Configs : {[string] : {[string] : any}},
	Listeners : {[string] : (configName : string, key : string, newValue : any, oldValue : any) -> ()}
}, {} :: ConfigManager))

local HttpService = game:GetService("HttpService")

local ConfigManager : ConfigManager = {} :: ConfigManager
ConfigManager.__index = ConfigManager

function ConfigManager.new() : ConfigSettings
	local self = setmetatable({}, ConfigManager)
	self.Configs = {}
	self.Listeners = {}
	return self
end

function ConfigManager.GetConfig(self : ConfigSettings, configName : string) : {[string] : any}?
	return self.Configs[configName]
end

function ConfigManager.AddConfig(self : ConfigSettings, configName : string, config : {[string] : any})
	if self.Configs[configName] then
		warn("Configuration with this name already exists: " .. configName)
		return
	end
	self.Configs[configName] = config
end

function ConfigManager.OnConfigChanged(self : ConfigSettings, callback : (configName : string, key : string, newValue : any, oldValue : any) -> ()) : {Disconnect : () -> ()}
	local id = HttpService:GenerateGUID()
	self.Listeners[id] = callback
	return {
		Disconnect = function()
			self.Listeners[id] = nil
		end
	}
end

function ConfigManager.ModifyConfig(self : ConfigSettings, configName : string, key : string, value : any) : boolean
	local config = self.Configs[configName]
	if not config then
		return false
	end
	local oldValue = config[key]
	config[key] = value
	if oldValue ~= value then
		for id, callback in self.Listeners do
			callback(configName, key, value, oldValue)
		end
	end
	return true
end

return ConfigManager
