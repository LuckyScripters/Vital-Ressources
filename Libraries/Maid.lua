local Maid = {}

local function safelyDestroy(item : any) : boolean
	if typeof(item) == "function" then
		item()
		return true
	end
	if typeof(item) == "RBXScriptConnection" then
		item:Disconnect()
		return true
	end
	if typeof(item) == "table" and item.ClassName == "SignalConnection" then
		item:Disconnect()
		return true
	end
	if typeof(item) == "Instance" then
		item:Destroy()
		return true
	end
	if typeof(item) ~= "table" or (not item.Destroy and not item.Remove) then
		return false
	end
	if item.Destroy then
		item:Destroy()
	elseif item.Remove then
		item:Remove()
	end
	return true
end

function Maid.new()
	return setmetatable({
		Items = {},
		ClassName = "Maid",
		Destroyed = false,
	}, {
		__index = function(self : {[any] : any}, key : string)
			return self.Items[key] or Maid[key]
		end,
		__newindex = function(self : {[any] : any}, key : string, value : any)
			rawset(self, key, nil)
			self:CleanIndex(key)
			return self:Give(value, key)
		end
	})
end

function Maid:DestroyItem(item : any) : boolean
	return safelyDestroy(item)
end

function Maid:Give(item : any, key : any?) : any
	if self.Destroyed then
		if not safelyDestroy(item) then
			warn(string.format("Maid failed to destroy %q", key or "none"), item)
		end
		return item
	end
	local index = key or table.maxn(self.Items) + 1
	local existingItem = self.Items[index]
	if item ~= existingItem then
		self.Items[index] = item
	end
	if existingItem and not safelyDestroy(existingItem) then
		warn(string.format("Maid failed to destroy %q", index), existingItem)
	end
	return item
end

function Maid:Remove(item : any) : any?
	for key, storedItem in self.Items do
		if storedItem == item then
			self.Items[key] = nil
			return item
		end
	end
	return nil
end

function Maid:CleanIndex(key : any)
	local item = self.Items[key]
	self.Items[key] = nil
	if item and not safelyDestroy(item) then
		warn(string.format("Maid failed to destroy %q", key), item)
	end
end

function Maid:CleanConnections()
	for index, item in self.Items do
		if typeof(item) == "RBXScriptConnection" or (typeof(item) == "table" and item.ClassName == "SignalConnection") then
			item:Disconnect()
		end
	end
end

function Maid:Clean()
	self:CleanConnections()
	repeat
		local key, item = next(self.Items)
		if key ~= nil then
			self.Items[key] = nil
		end
		if item ~= nil and not safelyDestroy(item) then
			warn(string.format("Maid failed to destroy %q", key), item)
		end
	until key == nil and item == nil
end

function Maid:Destroy()
	if not self.Destroyed then
		self.Destroyed = true
		self:Clean()
		setmetatable(self, nil)
		table.clear(self)
		self.Destroyed = true
	end
end

return Maid
