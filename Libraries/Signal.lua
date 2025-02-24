local currentThread = nil

local function executeCallback(callback : (...any) -> (), ... : any)
	local previousThread = currentThread
	currentThread = nil
	callback(...)
	currentThread = previousThread
end

local function coroutineHandler()
	while true do
		executeCallback(coroutine.yield())
	end
end

local SignalConnection = {}
SignalConnection.__index = SignalConnection

function SignalConnection.new(signal : {[any] : any}, callback : (...any) -> ())
	assert(type(signal) == "table", "Signal must be a table")
	assert(type(callback) == "function", "Callback must be a function")
	return setmetatable({
		ClassName = "SignalConnection",
		_connected = true,
		_signal = signal,
		_callback = callback,
		_next = nil
	}, SignalConnection)
end

function SignalConnection:Disconnect()
	self._connected = false
	if self._signal._handlerListHead == self then
		self._signal._handlerListHead = self._next
	else
		local prev = self._signal._handlerListHead
		while prev and prev._next ~= self do
			prev = prev._next
		end
		if prev then
			prev._next = self._next
		end
	end
end

local Signal = {}
Signal.__index = Signal

function Signal.new()
	return setmetatable({
		ClassName = "Signal",
		_handlerListHead = nil,
		_enabled = true
	}, Signal)
end

function Signal:Destroy()
	self:DisconnectAll()
	self:Disable()
	setmetatable(self, nil)
	table.clear(self)
end

function Signal:Disable()
	self._enabled = false
end

function Signal:Enable()
	self._enabled = true
end

function Signal:Connect(callback : (...any) -> ())
	assert(type(callback) == "function", "Callback must be a function")
	local connection = SignalConnection.new(self, callback)
	if not self._handlerListHead then
		self._handlerListHead = connection
	else
		connection._next = self._handlerListHead
		self._handlerListHead = connection
	end
	return connection
end

function Signal:DisconnectAll()
	self._handlerListHead = nil
end

function Signal:Fire(... : any)
	if self._enabled then
		local handler = self._handlerListHead
		while handler do
			if handler._connected then
				if not currentThread then
					currentThread = coroutine.create(coroutineHandler)
					coroutine.resume(currentThread)
				end
				task.spawn(currentThread, handler._callback, ...)
			end
			handler = handler._next
		end
	end
end

function Signal:Wait()
	local waitingCoroutine = coroutine.running()
	local capturedArgs = nil
	local connection; connection = self:Connect(function(... : any)
		connection:Disconnect()
		capturedArgs = {...}
		task.spawn(waitingCoroutine, ...)
	end)
	coroutine.yield()
	return unpack(capturedArgs)
end

function Signal:Once(callback : (...any) -> ())
	assert(type(callback) == "function", "Callback must be a function")
	local connection; connection = self:Connect(function(...)
		if connection._connected then
			connection:Disconnect()
		end
		callback(...)
	end)
	return connection
end

return Signal
