local RunService = cloneref(game:GetService("RunService"))

local Stepper = {}
Stepper.__index = Stepper

local function executeStep(stepper : {[any] : any})
	if not stepper.isRunning then
		local currentTime = os.clock()
		local deltaTime = currentTime - stepper.lastStepTime
		local shouldExecute = stepper.stepRate <= deltaTime
		if stepper.forceNextStep then
			stepper.forceNextStep = false
			shouldExecute = true
		end
		if shouldExecute then
			stepper.isRunning = true
			local success, errorMessage = xpcall(stepper.callback, debug.traceback, currentTime, deltaTime)
			if success then
				stepper.lastStepTime = currentTime
			else
				warn("Stepper encountered an error:", errorMessage)
				if stepper.disconnectOnError and stepper.connection then
					stepper.connection:Disconnect()
				end
				if stepper.customErrorHandler then
					stepper.customErrorHandler(errorMessage)
				end
			end
			stepper.isRunning = false
		end
	end
end

function Stepper.new(stepRate : number, runServiceEvent : string, callback : (number, number) -> ())
	assert(type(stepRate) == "number", "stepRate must be a number")
	assert(type(runServiceEvent) == "string", "runServiceEvent must be a string")
	assert(type(callback) == "function", "callback must be a function")
	local self = setmetatable({}, Stepper)
	self.isEnabled = true
	self.stepRate = stepRate or 0
	self.lastStepTime = os.clock() - self.stepRate
	self.callback = callback
	self.isRunning = false
	self.forceNextStep = false
	self.disconnectOnError = false
	self.connection = RunService[runServiceEvent]:Connect(function()
		executeStep(self)
	end)
	return self
end

function Stepper:Destroy()
	if not self.isDestroyed then
		self.isDestroyed = true
		self.connection:Disconnect()
		setmetatable(self, nil)
		table.clear(self)
	end
end

function Stepper:Enable() : {[any] : any}
	self.isEnabled = true
	return self
end

function Stepper:Disable() : {[any] : any}
	self.isEnabled = false
	return self
end

function Stepper:ForceStep() : {[any] : any}
	self.forceNextStep = true
	return self
end

function Stepper:SetRate(newRate : number) : {[any] : any}
	assert(type(newRate) == "number", "newRate must be a number")
	self.stepRate = newRate
	return self
end

function Stepper:DisconnectOnError(shouldDisconnect : boolean) : {[any] : any}
	assert(type(shouldDisconnect) == "boolean", "shouldDisconnect must be a boolean")
	self.disconnectOnError = shouldDisconnect
	return self
end

function Stepper:IsRunning() : {[any] : any}
	return self.isRunning
end

return Stepper
