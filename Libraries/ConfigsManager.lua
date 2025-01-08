type ConfigManager = {
    	IsMainFolderLoaded : boolean,
	__index : ConfigManager,
	new : (name : string) -> ConfigSettings?,
	LoadLibrary : () -> (),
	AddConfig : (self : ConfigSettings, configName : string, config : {[string] : any}) -> (),
	GetConfig : (self : ConfigSettings, configName : string) -> {[string] : any}?,
    	LoadConfig : () -> (),
    	SaveConfig : () -> (),
	ModifyConfig : (self : ConfigSettings, configName : string, key : string, value : any) -> boolean,
	OnConfigChanged : (self : ConfigSettings, callback : (configName : string, key : string, newValue : any, oldValue : any) -> ()) -> {Disconnect : () -> ()}
}

type ConfigSettings = typeof(setmetatable({} :: {
	Name : string,
	Configs : {[string] : {[string] : any}},
	Listeners : {[string] : (configName : string, key : string, newValue : any, oldValue : any) -> ()}
}, {} :: ConfigManager))

local HttpService = cloneref(game:GetService("HttpService"))

local globalConfigs = {
    MainFolderName = "VitalMainSettings",
    IsAutoSaveEnabled = false
}

local ConfigManager : ConfigManager = {IsMainFolderLoaded = false} :: ConfigManager
ConfigManager.__index = ConfigManager

function ConfigManager.new(name : string) : ConfigSettings
	if not ConfigManager.IsMainFolderLoaded then
		warn("Main folder not loaded, you should load it before creating settings")
		return nil
	end
	local self = setmetatable({}, ConfigManager)
	self.Name = name
	self.Configs = {}
	self.Listeners = {}
	if globalConfigs.IsAutoSaveEnabled and not isfolder(globalConfigs.MainFolderName .. "/" .. name) then
		makefolder(globalConfigs.MainFolderName .. "/" .. name)
	end
	return self
end

function ConfigManager:SetGlobalConfig(configName : string, value : any)
    if not globalConfigs[configName] then
        return
    end
    globalConfigs[configName] = value
    local jsonData = HttpService:JSONEncode(globalConfigs)
    writefile(globalConfigs.MainFolderName .. "/" .. "__GLOBAL.json", jsonData)
end

function ConfigManager:LoadLibrary()
	if ConfigManager.IsMainFolderLoaded then
		return
	end
	ConfigManager.IsMainFolderLoaded = true
	if not isfolder(globalConfigs.MainFolderName) then
		makefolder(globalConfigs.MainFolderName)
	end
    if not isfile(globalConfigs.MainFolderName .. "/" .. "__GLOBAL.json") then
        local jsonData = HttpService:JSONEncode(globalConfigs)
        writefile(globalConfigs.MainFolderName .. "/" .. "__GLOBAL.json", jsonData)
    else
        local jsonData = readfile(globalConfigs.MainFolderName .. "/" .. "__GLOBAL.json")
        local decodedData = HttpService:JSONDecode(jsonData)
        for configName, value in decodedData do
            globalConfigs[configName] = value
        end
    end
end

function ConfigManager:GetConfig(configName : string) : {[string] : any}?
	return self.Configs[configName]
end

function ConfigManager:AddConfig(configName : string, config : {[string] : any})
	if self.Configs[configName] then
		warn("Configuration with this name already exists: " .. configName)
		return
	end
	if globalConfigs.IsAutoSaveEnabled and not isfolder(globalConfigs.MainFolderName .. "/" .. self.Name .. "/" .. configName) then
        makefolder(globalConfigs.MainFolderName .. "/" .. self.Name .. "/" .. configName)
    end
    if globalConfigs.IsAutoSaveEnabled then
        local jsonData = HttpService:JSONEncode(config)
        writefile(globalConfigs.MainFolderName .. "/" .. self.Name .. "/" .. configName .. "/" .. "Data.json", jsonData)
    end
	self.Configs[configName] = config
end

function ConfigManager:OnConfigChanged(callback : (configName : string, key : string, newValue : any, oldValue : any) -> ()) : {Disconnect : () -> ()}
	local id = table.maxn(self.Listeners) + 1
	self.Listeners[id] = callback
	return {
		Disconnect = function()
			self.Listeners[id] = nil
		end
	}
end

function ConfigManager:SaveConfig()
    if not isfolder(globalConfigs.MainFolderName .. "/" .. self.Name) then
        makefolder(globalConfigs.MainFolderName .. "/" .. self.Name)
    end
    for configName, config in self.Configs do
        if not isfolder(globalConfigs.MainFolderName .. "/" .. self.Name .. "/" .. configName) then
            makefolder(globalConfigs.MainFolderName .. "/" .. self.Name .. "/" .. configName)
        end
        local jsonData = HttpService:JSONEncode(config)
        writefile(globalConfigs.MainFolderName .. "/" .. self.Name .. "/" .. configName .. "/" .. "Data.json", jsonData)
    end
end

function ConfigManager:LoadConfig()
    if not isfolder(globalConfigs.MainFolderName .. "/" .. self.Name) then
        return
    end
    for configName, config in self.Configs do
        if not isfolder(globalConfigs.MainFolderName .. "/" .. self.Name .. "/" .. configName) then
            continue
        end
        local jsonData = readfile(globalConfigs.MainFolderName .. "/" .. self.Name .. "/" .. configName .. "/" .. "Data.json")
        local decodedData = HttpService:JSONDecode(jsonData)
        self.Configs[configName] = decodedData
    end
end

function ConfigManager:ModifyConfig(configName : string, key : string, value : any) : boolean
	local config = self.Configs[configName]
	if not config then
		return false
	end
	local oldValue = config[key]
	config[key] = value
    if ConfigManager.IsAutoSaveEnabled then
        local jsonData = HttpService:JSONEncode(config)
        writefile(globalConfigs.MainFolderName .. "/" .. self.Name .. "/" .. configName .. "/" .. "Data.json", jsonData)
    end
	if oldValue ~= value then
		for id, callback in self.Listeners do
			callback(configName, key, value, oldValue)
		end
	end
	return true
end

return ConfigManager
