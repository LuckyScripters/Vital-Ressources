type Settings = typeof(setmetatable({} :: {
	Data : {[string] : any},
	Name : string,
	Path : string,
	GetData : (self : Settings) -> {[string] : any},
	SetPath : (self : Settings) -> (),
	AddField : (self : Settings, name : string, value : any, overwrite : boolean) -> (),
	RemoveField : (self : Settings, name : string) -> (),
	AddToPath : (self : Settings, path : string) -> boolean,
	RemoveFromPath : (self : Settings, folderName : string) -> boolean,
	SaveSettings : (self : Settings) -> boolean,
	LoadSettings : (self : Settings) -> boolean
}, {} :: {
	__index : (self : Settings, index : string) -> any,
	__newindex : (self : Settings, index : string, value : any) -> ()
}))

type SettingsModule = {
	SetGlobalSettingsName : (self : SettingsModule, name : string) -> (),
	new : (name : string) -> Settings
}

local HttpService = cloneref(game:GetService("HttpService"))

local Settings : SettingsModule = {} :: SettingsModule
local globalSettings = {__name = "Vital-GlobalSettings"}

function Settings:SetGlobalSettingsName(name : string)
	globalSettings.__name = name
end

local function getData(self : Settings) : {[string] : any}
	return self.Data
end

local function setPath(self : Settings, path : string)
	self.Path = globalSettings.__name .. "/" .. path .. (string.sub(path, string.len(path), string.len(path)) == "/" and "" or "/")
end

local function addField(self : Settings, name : string, value : any, overwrite : boolean)
	assert(self.Data[name] == nil or (self.Data[name] ~= nil and overwrite), "This field already exists!")
	self.Data[name] = value
end

local function removeField(self : Settings, name : string)
	assert(self.Data[name], "This field doesn't exist!")
	self.Data[name] = nil
end

local function removeFromPath(self : Settings, folderName : string) : boolean
	assert(table.find(string.split(self.Path, "/"), folderName, 1), "Invalid folder!")
	local startPattern, finishPattern = string.find(self.Path, folderName, 1, true)
	local pathToRemove = string.sub(self.Path, 1, finishPattern)
	local success, result = pcall(delfolder, pathToRemove)
	if not success then
		return true
	end
	self.Path = string.sub(self.Path, 1, startPattern - 1)
	return false
end

local function checkForClone(self : Settings, path : string?) : boolean
	local splittedPath = string.split(path or self.Path, "/")
	local success, result = pcall(isfolder, splittedPath[2])
	if not success then
		return false
	end
	if result then
		local success, result = pcall(delfolder, splittedPath[2])
		if success then
			return true
		end
	end
	return false
end

local function saveSettings(self : Settings) : boolean
	local jsonData = HttpService:JSONEncode(self.Data)
	local success, result = pcall(writefile, self.Path .. self.Name .. ".json", jsonData)
	if not success then
		warn("Error while saving settings! Error: " .. result)
		return false
	end
	checkForClone(self, self.Path .. self.Name .. ".json")
	return true
end

local function loadSettings(self : Settings) : boolean
	local success, jsonData = pcall(readfile, self.Path .. self.Name .. ".json")
	if not success then
		warn("Error while loading settings! Error: " .. jsonData)
		return false
	end
	local success, tableData = pcall(HttpService.JSONDecode, HttpService, jsonData)
	if not success then
		warn("Error while parsing settings! Error: " .. tableData)
		return false
	end
	self.Data = tableData
	return true
end

local function addToPath(self : Settings, path : string) : boolean
	local splittedPath = string.split(path, "/")
	for index, folderName in splittedPath do
		local success, result = pcall(isfolder, self.Path .. "/" .. folderName)
		if not success then
			warn("Error while checking if path exists! Error: " .. result)
			return false
		end
		local success, result = pcall(makefolder, self.Path .. "/" .. folderName)
		if not success then
			warn("Error while creating folder! Error: " .. result)
			return false
		end
		self.Path = self.Path .. folderName .. "/"
        checkForClone(self)
	end
	return true
end

function Settings.new(name : string) : Settings
	local self = setmetatable({
		Data = {},
		Name = name,
		Path = globalSettings.__name .. "/",
	}, {
		__index = function(self : {[string] : any}, index : string)
			return rawget(self, index)
		end,
		__newindex = function(self : {[string] : any}, index : string, value : any)
			rawset(self, index, value)
		end,
	})
	self.GetData = getData
	self.SetPath = setPath
	self.AddField = addField
	self.RemoveField = removeField
	self.AddToPath = addToPath
	self.RemoveFromPath = removeFromPath
	self.SaveSettings = saveSettings
	self.LoadSettings = loadSettings
	if not isfolder(globalSettings.__name) then
		makefolder(globalSettings.__name)
	end
	return self
end

return Settings
