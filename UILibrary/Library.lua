type Dictionary = {[any] : any}

local CoreGui = cloneref(game:GetService("CoreGui"))
local RunService = cloneref(game:GetService("RunService"))
local HttpService = cloneref(game:GetService("HttpService"))
local TextService = cloneref(game:GetService("TextService"))
local TweenService = cloneref(game:GetService("TweenService"))
local UserInputService = cloneref(game:GetService("UserInputService"))

if getgenv().VitalLibrary then
	getgenv().VitalLibrary:Unload()
end

local VitalLibrary = {Tabs = {}, Flags = {}, Theme = {}, Title = "Vital.wtf", IsOpen = false, Options = {}, TabSize = 0, FileText = ".txt", Draggable = true, Instances = {}, FolderName = "Vital.wtf_Configs", Connections = {}, Notifications = {}}

local utilities = loadstring(game:HttpGet("https://raw.githubusercontent.com/LuckyScripters/Vital-Ressources/refs/heads/main/Common/Utilities.lua", true))()
local requirements = loadstring(game:HttpGet("https://raw.githubusercontent.com/LuckyScripters/Vital-Ressources/refs/heads/main/Common/Requirements.lua", true))()

local dragData = {Dragging = false, DragInput = nil, DragStart = Vector3.zero, DragObject = nil, StartPosition = UDim2.new(0, 0, 0, 0)}
local blacklistedKeyCodes = {Enum.KeyCode.A, Enum.KeyCode.D, Enum.KeyCode.S, Enum.KeyCode.W, Enum.KeyCode.Tab, Enum.KeyCode.Slash, Enum.KeyCode.Escape, Enum.KeyCode.Unknown}
local whitelistedMouseInputs = {Enum.UserInputType.MouseButton1, Enum.UserInputType.MouseButton2, Enum.UserInputType.MouseButton3}

getgenv().VitalLibrary = VitalLibrary

function VitalLibrary:Create(className : string, properties : {[string] : any}, protected : boolean) : Instance? | Dictionary?
	if not className then
		return nil
	end
	local isDrawing = className == "Line" or className == "Quad" or className == "Text" or className == "Image" or className == "Circle" or className == "Square" or className == "Triangle"
	local object = utilities:Create(className, isDrawing and "Drawing" or "Instance", protected, properties)
	table.insert(self.Instances, object)
	return object
end

function VitalLibrary:AddConnection(signal : RBXScriptSignal, name : string | (...any) -> (), callback : (...any) -> ()?) : RBXScriptSignal
	local connection = signal:Connect(typeof(name) == "function" and name or callback)
	if typeof(name) ~= "function" then
		self.Connections[name] = connection
	else
		table.insert(self.Connections, connection)
	end
	return connection
end

function VitalLibrary:Unload()
	for index, connection in self.Connections do
		connection:Disconnect()
	end
	for index, object in self.Instances do
		if requirements:Call("IsRenderObj", object) then
			pcall(object.Remove, object)
		else
			pcall(object.Destroy, object)
		end
	end
	for index, option in self.Options do
		if option.Type == "Toggle" then
			task.spawn(option.SetState, option)
		end
	end
	VitalLibrary = nil
	getgenv().VitalLibrary = nil
end

function VitalLibrary:LoadConfig(config : string)
	if table.find(self:GetConfigs(), config, 1) then
		local success, decodedConfig = pcall(HttpService.JSONDecode, HttpService, requirements:Call("ReadFile", self.FolderName .. "/" .. config .. self.FileText))
		if success then
			for index, option in self.Options do
				if option.HasInit then
					if option.Type ~= "Button" and option.Flag and not option.SkipFlag then
						if option.Type == "Toggle" then
							task.spawn(option.SetState, option, decodedConfig[option.Flag] == 1)
						elseif option.Type == "Color" then
							if decodedConfig[option.Flag] then
								task.spawn(option.SetColor, option, decodedConfig[option.Flag])
								if option.Transparency then
									task.spawn(option.SetTransparency, option, decodedConfig[option.Flag .. " Transparency"])
								end
							end
						elseif option.Type == "Bind" then
							task.spawn(option.SetKeyCode, option, decodedConfig[option.Flag])
						else
							task.spawn(option.SetValue, option, decodedConfig[option.Flag])
						end
					end
				end
			end
		end
	end
end

function VitalLibrary:SaveConfig(config : string)
	local configData = table.find(self:GetConfigs(), config, 1) and HttpService:JSONEncode(requirements:Call("ReadFile", self.FolderName .. "/" .. config .. self.FileText)) or {}
	for index, option in self.Options do
		if option.Type ~= "Button" and option.Flag and not option.SkipFlag then
			if option.Type == "Toggle" then
				configData[option.Flag] = option.State and 1 or 0
			elseif option.Type == "Color" then
				configData[option.Flag] = {option.Color.R, option.Color.G, option.Color.B}
				if option.Transparency then
					configData[option.Flag .. " Transparency"] = option.Transparency
				end
			elseif option.Type == "Bind" then
				if option.KeyCode ~= "None" then
					configData[option.Flag] = option.KeyCode
				end
			elseif option.Type == "List" then
				configData[option.Flag] = option.Value
			else
				configData[option.Flag] = option.Value
			end
		end
	end
	requirements:Call("WriteFile", self.FolderName .. "/" .. config .. self.FileText, HttpService:JSONEncode(configData))
end

function VitalLibrary:GetConfigs() : Dictionary
	if not requirements:Call("IsFolder", self.FolderName) then
		requirements:Call("MakeFolder", self.FolderName)
		return {}
	end
	local files = {}
	for index, value in requirements:Call("ListFiles", self.FolderName) do
		if string.sub(value, string.len(value) - string.len(self.FileText) + 1, string.len(value)) == self.FileText then
			value = string.gsub(value, self.FolderName .. "\\", "", 1)
			value = string.gsub(value, self.FileText, "", 1)
			table.insert(files, value)
		end
	end
	return files
end

VitalLibrary.SnapTo = function(number : number | Color3 | Vector2 | Vector3, bracket : number?) : number
	if typeof(number) == "Vector2" then
		return VitalLibrary.SnapTo(number.X, bracket), VitalLibrary.SnapTo(number.Y, bracket)
	elseif typeof(number) == "Vector3" then
		return VitalLibrary.SnapTo(number.X, bracket), VitalLibrary.SnapTo(number.Y, bracket), VitalLibrary.SnapTo(number.Z, bracket)
	elseif typeof(number) == "Color3" then
		return VitalLibrary.SnapTo(number.R * 255, bracket), VitalLibrary.SnapTo(number.G * 255, bracket), VitalLibrary.SnapTo(number.B * 255, bracket)
	else
		return number - number % (bracket or 1)
	end
end

VitalLibrary.CreateLabel = function(option : Dictionary, parent : Instance)
	option.Main = VitalLibrary:Create("TextLabel", {
		LayoutOrder = option.Position,
		Position = UDim2.new(0, 6, 0, 0),
		Size = UDim2.new(1, -12, 0, 24),
		BackgroundTransparency = 1,
		TextSize = 15,
		Font = Enum.Font.Code,
		TextColor3 = Color3.new(1, 1, 1),
		TextXAlignment = Enum.TextXAlignment.Left,
		TextYAlignment = Enum.TextYAlignment.Top,
		TextWrapped = true,
		Parent = parent
	}, false)
	setmetatable(option, {
		__newindex = function(_, index : string, value : string?)
			if index == "CurrentText" then
				option.Main.Text = tostring(value)
				option.Main.Size = UDim2.new(1, -12, 0, TextService:GetTextSize(option.Main.Text, 15, Enum.Font.Code, Vector2.new(option.Main.AbsoluteSize.X, math.huge)).Y + 6)
			end
		end
	})
	option.CurrentText = option.Text
end

VitalLibrary.CreateDivider = function(option : Dictionary, parent : Instance)
	option.Main = VitalLibrary:Create("Frame", {
		LayoutOrder = option.Position,
		Size = UDim2.new(1, 0, 0, 18),
		BackgroundTransparency = 1,
		Parent = parent
	}, false)
	VitalLibrary:Create("Frame", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.new(0.5, 0, 0.5, 0),
		Size = UDim2.new(1, -24, 0, 1),
		BackgroundColor3 = Color3.fromRGB(60, 60, 60),
		BorderColor3 = Color3.new(0, 0, 0),
		Parent = option.Main
	}, false)
	option.Title = VitalLibrary:Create("TextLabel", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.new(0.5, 0, 0.5, 0),
		BackgroundColor3 = Color3.fromRGB(30, 30, 30),
		BorderSizePixel = 0,
		TextColor3 =  Color3.new(1, 1, 1),
		TextSize = 15,
		Font = Enum.Font.Code,
		TextXAlignment = Enum.TextXAlignment.Center,
		Parent = option.Main
	}, false)
	setmetatable(option, {
		__newindex = function(_, index : string, value : string?)
			if index == "CurrentText" then
				if value then
					option.Title.Text = tostring(value)
					option.Title.Size = UDim2.new(0, TextService:GetTextSize(option.Title.Text, 15, Enum.Font.Code, Vector2.new(math.huge, math.huge)).X + 12, 0, 20)
					option.Main.Size = UDim2.new(1, 0, 0, 18)
				else
					option.Title.Text = ""
					option.Title.Size = UDim2.new(0, 0, 0, 0)
					option.Main.Size = UDim2.new(1, 0, 0, 6)
				end
			end
		end
	})
	option.CurrentText = option.Text
end

VitalLibrary.CreateToggle = function(option : Dictionary, parent : Instance)
	local tickbox, tickboxOverlay = nil, nil
	option.HasInit = true
	option.Main = VitalLibrary:Create("Frame", {
		LayoutOrder = option.Position,
		Size = UDim2.new(1, 0, 0, 20),
		BackgroundTransparency = 1,
		Parent = parent
	}, false)
	if option.Style then
		tickbox = VitalLibrary:Create("ImageLabel", {
			Position = UDim2.new(0, 6, 0, 4),
			Size = UDim2.new(0, 12, 0, 12),
			BackgroundTransparency = 1,
			Image = "rbxassetid://3570695787",
			ImageColor3 = Color3.new(0, 0, 0),
			Parent = option.Main
		}, false)
		VitalLibrary:Create("ImageLabel", {
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.new(0.5, 0, 0.5, 0),
			Size = UDim2.new(1, -2, 1, -2),
			BackgroundTransparency = 1,
			Image = "rbxassetid://3570695787",
			ImageColor3 = Color3.fromRGB(60, 60, 60),
			Parent = tickbox
		}, false)
		VitalLibrary:Create("ImageLabel", {
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.new(0.5, 0, 0.5, 0),
			Size = UDim2.new(1, -6, 1, -6),
			BackgroundTransparency = 1,
			Image = "rbxassetid://3570695787",
			ImageColor3 = Color3.fromRGB(40, 40, 40),
			Parent = tickbox
		}, false)
		tickboxOverlay = VitalLibrary:Create("ImageLabel", {
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.new(0.5, 0, 0.5, 0),
			Size = UDim2.new(1, -6, 1, -6),
			BackgroundTransparency = 1,
			Image = "rbxassetid://3570695787",
			ImageColor3 = VitalLibrary.Flags["Menu Accent Color"] or Color3.fromRGB(255, 255, 255),
			Visible = option.State,
			Parent = tickbox
		}, false)
		VitalLibrary:Create("ImageLabel", {
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.new(0.5, 0, 0.5, 0),
			Size = UDim2.new(1, 0, 1, 0),
			BackgroundTransparency = 1,
			Image = "rbxassetid://5941353943",
			ImageTransparency = 0.6,
			Parent = tickbox
		}, false)
		table.insert(VitalLibrary.Theme, tickboxOverlay)
	else
		tickbox = VitalLibrary:Create("Frame", {
			Position = UDim2.new(0, 6, 0, 4),
			Size = UDim2.new(0, 12, 0, 12),
			BackgroundColor3 = VitalLibrary.Flags["Menu Accent Color"] or Color3.fromRGB(255, 255, 255),
			BorderColor3 = Color3.new(0, 0, 0),
			Parent = option.Main
		}, false)
		tickboxOverlay = VitalLibrary:Create("ImageLabel", {
			Size = UDim2.new(1, 0, 1, 0),
			BackgroundTransparency = option.State and 1 or 0,
			BackgroundColor3 = Color3.fromRGB(50, 50, 50),
			BorderColor3 = Color3.new(0, 0, 0),
			Image = "rbxassetid://4155801252",
			ImageTransparency = 0.6,
			ImageColor3 = Color3.new(0, 0, 0),
			Parent = tickbox
		}, false)
		VitalLibrary:Create("ImageLabel", {
			Size = UDim2.new(1, 0, 1, 0),
			BackgroundTransparency = 1,
			Image = "rbxassetid://2592362371",
			ImageColor3 = Color3.fromRGB(60, 60, 60),
			ScaleType = Enum.ScaleType.Slice,
			SliceCenter = Rect.new(2, 2, 62, 62),
			Parent = tickbox
		}, false)
		VitalLibrary:Create("ImageLabel", {
			Size = UDim2.new(1, -2, 1, -2),
			Position = UDim2.new(0, 1, 0, 1),
			BackgroundTransparency = 1,
			Image = "rbxassetid://2592362371",
			ImageColor3 = Color3.new(0, 0, 0),
			ScaleType = Enum.ScaleType.Slice,
			SliceCenter = Rect.new(2, 2, 62, 62),
			Parent = tickbox
		}, false)
		table.insert(VitalLibrary.Theme, tickbox)
	end
	option.Interest = VitalLibrary:Create("Frame", {
		Position = UDim2.new(0, 0, 0, 0),
		Size = UDim2.new(1, 0, 0, 20),
		BackgroundTransparency = 1,
		Parent = option.Main
	}, false)
	option.Title = VitalLibrary:Create("TextLabel", {
		Position = UDim2.new(0, 24, 0, 0),
		Size = UDim2.new(1, 0, 1, 0),
		BackgroundTransparency = 1,
		Text = option.Text,
		TextColor3 =  option.State and Color3.fromRGB(210, 210, 210) or Color3.fromRGB(180, 180, 180),
		TextSize = 15,
		Font = Enum.Font.Code,
		TextXAlignment = Enum.TextXAlignment.Left,
		Parent = option.Interest
	}, false)
	option.Interest.InputBegan:Connect(function(input : InputObject)
		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			option:SetState(not option.State, false)
		end
		if input.UserInputType == Enum.UserInputType.MouseMovement then
			if not VitalLibrary.Warning and not VitalLibrary.Slider then
				if option.Style then
					tickbox.ImageColor3 = VitalLibrary.Flags["Menu Accent Color"] or Color3.fromRGB(255, 255, 255)
					TweenService:Create(tickbox, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out, 0, false, 0), {ImageColor3 = VitalLibrary.Flags["Menu Accent Color"] or Color3.fromRGB(255, 255, 255)}):Play()
				else
					tickbox.BorderColor3 = VitalLibrary.Flags["Menu Accent Color"] or Color3.fromRGB(255, 255, 255)
					tickboxOverlay.BorderColor3 = VitalLibrary.Flags["Menu Accent Color"] or Color3.fromRGB(255, 255, 255)
					TweenService:Create(tickbox, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out, 0, false, 0), {BorderColor3 = VitalLibrary.Flags["Menu Accent Color"] or Color3.fromRGB(255, 255, 255)}):Play()
					TweenService:Create(tickboxOverlay, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out, 0, false, 0), {BorderColor3 = VitalLibrary.Flags["Menu Accent Color"] or Color3.fromRGB(255, 255, 255)}):Play()
				end
			end
			if option.ToolTip then
				VitalLibrary.ToolTip.Text = option.ToolTip
				VitalLibrary.ToolTip.Size = UDim2.new(0, TweenService:GetTextSize(option.ToolTip, 15, Enum.Font.Code, Vector2.new(math.huge, math.huge)).X, 0, 20)
			end
		end
	end)
	option.Interest.InputChanged:Connect(function(input : InputObject)
		if input.UserInputType == Enum.UserInputType.MouseMovement then
			if option.ToolTip then
				VitalLibrary.ToolTip.Position = UDim2.new(0, input.Position.X + 26, 0, input.Position.Y + 36)
			end
		end
	end)
	option.Interest.InputEnded:Connect(function(input : InputObject)
		if input.UserInputType == Enum.UserInputType.MouseMovement then
			if option.Style then
				tickbox.ImageColor3 = Color3.new(0, 0, 0)
				TweenService:Create(tickbox, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out, 0, false, 0), {ImageColor3 = Color3.new(0, 0, 0)}):Play()
			else
				tickbox.BorderColor3 = Color3.new(0, 0, 0)
				tickboxOverlay.BorderColor3 = Color3.new(0, 0, 0)
				TweenService:Create(tickbox, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out, 0, false, 0), {BorderColor3 = Color3.new(0, 0, 0)}):Play()
				TweenService:Create(tickboxOverlay, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out, 0, false, 0), {BorderColor3 = Color3.new(0, 0, 0)}):Play()
			end
			VitalLibrary.ToolTip.Position = UDim2.new(2, 0, 0, 0)
		end
	end)
	function option:SetState(state : boolean?, nocallback : boolean)
		VitalLibrary.Flags[self.Flag] = state or false
		self.State = state or false
		option.Title.TextColor3 = (state or false) and Color3.fromRGB(210, 210, 210) or Color3.fromRGB(160, 160, 160)
		if option.Style then
			tickboxOverlay.Visible = state or false
		else
			tickboxOverlay.BackgroundTransparency = (state or false) and 1 or 0
		end
		if not nocallback then
			self.Callback(state or false)
		end
	end
	if option.State ~= nil then
		task.delay(1, function()
			if VitalLibrary then
				option.Callback(option.State)
			end
		end)
	end
	setmetatable(option, {
		__newindex = function(_, index : string, value : string?)
			if index == "CurrentText" then
				option.Title.Text = tostring(value)
			end
		end
	})
end

VitalLibrary.CreateButton = function(option : Dictionary, parent : Instance)
	option.HasInit = true
	option.Main = VitalLibrary:Create("Frame", {
		LayoutOrder = option.Position,
		Size = UDim2.new(1, 0, 0, 28),
		BackgroundTransparency = 1,
		Parent = parent
	}, false)
	option.Title = VitalLibrary:Create("TextLabel", {
		AnchorPoint = Vector2.new(0.5, 1),
		Position = UDim2.new(0.5, 0, 1, -5),
		Size = UDim2.new(1, -12, 0, 20),
		BackgroundColor3 = Color3.fromRGB(50, 50, 50),
		BorderColor3 = Color3.new(0, 0, 0),
		Text = option.Text,
		TextColor3 = Color3.new(1, 1, 1),
		TextSize = 15,
		Font = Enum.Font.Code,
		Parent = option.Main
	}, false)
	VitalLibrary:Create("ImageLabel", {
		Size = UDim2.new(1, 0, 1, 0),
		BackgroundTransparency = 1,
		Image = "rbxassetid://2592362371",
		ImageColor3 = Color3.fromRGB(60, 60, 60),
		ScaleType = Enum.ScaleType.Slice,
		SliceCenter = Rect.new(2, 2, 62, 62),
		Parent = option.Title
	}, false)
	VitalLibrary:Create("ImageLabel", {
		Size = UDim2.new(1, -2, 1, -2),
		Position = UDim2.new(0, 1, 0, 1),
		BackgroundTransparency = 1,
		Image = "rbxassetid://2592362371",
		ImageColor3 = Color3.new(0, 0, 0),
		ScaleType = Enum.ScaleType.Slice,
		SliceCenter = Rect.new(2, 2, 62, 62),
		Parent = option.Title
	}, false)
	VitalLibrary:Create("UIGradient", {
		Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0, Color3.fromRGB(180, 180, 180)),
			ColorSequenceKeypoint.new(1, Color3.fromRGB(253, 253, 253)),
		}),
		Rotation = -90,
		Parent = option.Title
	}, false)
	option.Title.InputBegan:Connect(function(input : InputObject)
		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			option.Callback()
			if VitalLibrary then
				VitalLibrary.Flags[option.Flag] = true
			end
		end
		if input.UserInputType == Enum.UserInputType.MouseMovement then
			if not VitalLibrary.Warning and not VitalLibrary.Slider then
				option.Title.BorderColor3 = VitalLibrary.Flags["Menu Accent Color"] or Color3.fromRGB(255, 255, 255)
			end
		end
	end)
	option.Title.InputChanged:Connect(function(input : InputObject)
		if input.UserInputType == Enum.UserInputType.MouseMovement then
			if option.ToolTip then
				VitalLibrary.ToolTip.Text = option.ToolTip
				VitalLibrary.ToolTip.Size = UDim2.new(0, TextService:GetTextSize(option.ToolTip, 15, Enum.Font.Code, Vector2.new(math.huge, math.huge)).X, 0, 20)
				VitalLibrary.ToolTip.Position = UDim2.new(0, input.Position.X + 26, 0, input.Position.Y + 36)
			end
		end
	end)
	option.Title.InputEnded:Connect(function(input : InputObject)
		if input.UserInputType == Enum.UserInputType.MouseMovement then
			option.Title.BorderColor3 = Color3.new(0, 0, 0)
			VitalLibrary.ToolTip.Position = UDim2.new(2, 0, 0, 0)
		end
	end)
end

VitalLibrary.CreateBind = function(option : Dictionary, parent : Instance)
	local binding, holding, loop = nil, nil, nil
	option.HasInit = true
	if option.Sub then
		option.Main = option:GetMain()
	else
		option.Main = option.Main or VitalLibrary:Create("Frame", {
			LayoutOrder = option.Position,
			Size = UDim2.new(1, 0, 0, 20),
			BackgroundTransparency = 1,
			Parent = parent
		}, false)
		VitalLibrary:Create("TextLabel", {
			Position = UDim2.new(0, 6, 0, 0),
			Size = UDim2.new(1, -12, 1, 0),
			BackgroundTransparency = 1,
			Text = option.Text,
			TextSize = 15,
			Font = Enum.Font.Code,
			TextColor3 = Color3.fromRGB(210, 210, 210),
			TextXAlignment = Enum.TextXAlignment.Left,
			Parent = option.Main
		}, false)
	end
	local bindInput = VitalLibrary:Create(option.Sub and "TextButton" or "TextLabel", {
		Position = UDim2.new(1, -6 - (option.SubPosition or 0), 0, option.Sub and 2 or 3),
		SizeConstraint = Enum.SizeConstraint.RelativeYY,
		BackgroundColor3 = Color3.fromRGB(30, 30, 30),
		BorderSizePixel = 0,
		TextSize = 15,
		Font = Enum.Font.Code,
		TextColor3 = Color3.fromRGB(160, 160, 160),
		TextXAlignment = Enum.TextXAlignment.Right,
		Parent = option.Main
	}, false)
	local interest = option.Sub and bindInput or option.Main
	if option.Sub then
		bindInput.AutoButtonColor = false
	end
	interest.InputEnded:Connect(function(input : InputObject)
		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			binding = true
			bindInput.Text = "[...]"
			bindInput.Size = UDim2.new(0, -TextService:GetTextSize(bindInput.Text, 16, Enum.Font.Code, Vector2.new(math.huge, math.huge)).X, 0, 16)
			bindInput.TextColor3 = VitalLibrary.Flags["Menu Accent Color"] or Color3.fromRGB(255, 255, 255)
		end
	end)
	VitalLibrary:AddConnection(UserInputService.InputBegan, function(input : InputObject, gameProcessedEvent : boolean)
		if UserInputService:GetFocusedTextBox() then
			return
		end
		if binding then
			local inputType = (table.find(whitelistedMouseInputs, input.UserInputType, 1) and not option.NoMouse) and input.UserInputType
			option:SetKeyCode(inputType or (not table.find(blacklistedKeyCodes, input.KeyCode, 1)) and input.KeyCode)
		else
			if (input.KeyCode.Name == option.KeyCode or input.UserInputType.Name == option.KeyCode) and not binding then
				if option.Mode == "Toggle" then
					VitalLibrary.Flags[option.Flag] = not VitalLibrary.Flags[option.Flag]
					option.Callback(VitalLibrary.Flags[option.Flag], 0)
				else
					VitalLibrary.Flags[option.Flag] = true
					if loop then 
						loop:Disconnect() 
						option.Callback(true, 0) 
					end
					loop = VitalLibrary:AddConnection(RunService.RenderStepped, function(deltaTime : number)
						if not UserInputService:GetFocusedTextBox() then
							option.Callback(nil, deltaTime)
						end
					end)
				end
			end
		end
	end)
	VitalLibrary:AddConnection(UserInputService.InputEnded, function(input : InputObject, gameProcessedEvent : boolean)
		if UserInputService:GetFocusedTextBox() then
			return
		end
		if option.KeyCode ~= "None" then
			if input.KeyCode.Name == option.KeyCode or input.UserInputType.Name == option.KeyCode then
				if loop then
					loop:Disconnect()
					VitalLibrary.Flags[option.Flag] = false
					option.Callback(true, 0)
				end
			end
		end
	end)
	function option:SetKeyCode(keyCode : Enum.KeyCode?)
		binding = false
		bindInput.TextColor3 = Color3.fromRGB(160, 160, 160)
		if loop then 
			loop:Disconnect() 
			VitalLibrary.Flags[option.Flag] = false 
			option.Callback(true, 0) 
		end
		self.KeyCode = (keyCode and keyCode.Name) or keyCode or self.KeyCode
		if self.KeyCode == "Backspace" then
			self.KeyCode = "None"
			bindInput.Text = "[NONE]"
		else
			local newKeyCode = self.KeyCode
			if string.match(self.KeyCode, "Mouse", 1) then
				newKeyCode = string.gsub(string.gsub(self.KeyCode, "Button", "", 1), "Mouse", "M", 1)
			elseif string.match(self.KeyCode, "Alt", 1) or string.match(self.KeyCode, "Meta", 1) or string.match(self.KeyCode, "Shift", 1) or string.match(self.KeyCode, "Control", 1) then
				newKeyCode = string.gsub(string.gsub(self.KeyCode, "Left", "L"), "Right", "R")
			end
			local finalKeyCode, _ = string.gsub(newKeyCode, "Control", "CTRL", 1)
			bindInput.Text = "[" .. string.upper(finalKeyCode) .. "]"
		end
		bindInput.Size = UDim2.new(0, -TextService:GetTextSize(bindInput.Text, 16, Enum.Font.Code, Vector2.new(math.huge, math.huge)).X, 0, 16)
	end
	option:SetKeyCode(nil)
end

VitalLibrary.CreateSlider = function(option : Dictionary, parent : Instance)
	local manualInput = false
	option.HasInit = true
	if option.Sub then
		option.Main = option:GetMain()
		option.Main.Size = UDim2.new(1, 0, 0, 42)
	else
		option.Main = VitalLibrary:Create("Frame", {
			LayoutOrder = option.Position,
			Size = UDim2.new(1, 0, 0, option.TextPosition and 24 or 40),
			BackgroundTransparency = 1,
			Parent = parent
		}, false)
	end
	option.Slider = VitalLibrary:Create("Frame", {
		Position = UDim2.new(0, 6, 0, (option.Sub and 22 or option.TextPosition and 4 or 20)),
		Size = UDim2.new(1, -12, 0, 16),
		BackgroundColor3 = Color3.fromRGB(50, 50, 50),
		BorderColor3 = Color3.new(0, 0, 0),
		Parent = option.Main
	}, false)
	VitalLibrary:Create("ImageLabel", {
		Size = UDim2.new(1, 0, 1, 0),
		BackgroundTransparency = 1,
		Image = "rbxassetid://2454009026",
		ImageColor3 = Color3.new(0, 0, 0),
		ImageTransparency = 0.8,
		Parent = option.Slider
	}, false)
	option.Fill = VitalLibrary:Create("Frame", {
		BackgroundColor3 = VitalLibrary.Flags["Menu Accent Color"] or Color3.fromRGB(255, 255, 255),
		BorderSizePixel = 0,
		Parent = option.Slider
	}, false)
	VitalLibrary:Create("ImageLabel", {
		Size = UDim2.new(1, 0, 1, 0),
		BackgroundTransparency = 1,
		Image = "rbxassetid://2592362371",
		ImageColor3 = Color3.fromRGB(60, 60, 60),
		ScaleType = Enum.ScaleType.Slice,
		SliceCenter = Rect.new(2, 2, 62, 62),
		Parent = option.Slider
	}, false)
	VitalLibrary:Create("ImageLabel", {
		Size = UDim2.new(1, -2, 1, -2),
		Position = UDim2.new(0, 1, 0, 1),
		BackgroundTransparency = 1,
		Image = "rbxassetid://2592362371",
		ImageColor3 = Color3.new(0, 0, 0),
		ScaleType = Enum.ScaleType.Slice,
		SliceCenter = Rect.new(2, 2, 62, 62),
		Parent = option.Slider
	}, false)
	option.Title = VitalLibrary:Create("TextBox", {
		Position = UDim2.new((option.Sub or option.TextPosition) and 0.5 or 0, (option.Sub or option.TextPosition) and 0 or 6, 0, 0),
		Size = UDim2.new(0, 0, 0, (option.Sub or option.TextPosition) and 14 or 18),
		BackgroundTransparency = 1,
		Text = (option.Text == "nil" and "" or option.Text .. ": ") .. option.Value .. option.Suffix,
		TextSize = (option.Sub or option.TextPosition) and 14 or 15,
		Font = Enum.Font.Code,
		TextColor3 = Color3.fromRGB(210, 210, 210),
		TextXAlignment = Enum.TextXAlignment[(option.Sub or option.TextPosition) and "Center" or "Left"],
		Parent = (option.Sub or option.TextPosition) and option.Slider or option.Main
	}, false)
	table.insert(VitalLibrary.Theme, option.Fill)
	VitalLibrary:Create("UIGradient", {
		Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0, Color3.fromRGB(115, 115, 115)),
			ColorSequenceKeypoint.new(1, Color3.new(1, 1, 1)),
		}),
		Rotation = -90,
		Parent = option.Fill
	}, false)
	local interest = (option.Sub or option.TextPosition) and option.Slider or option.Main
	if option.Minimum >= 0 then
		option.Fill.Size = UDim2.new((option.Value - option.Minimum) / (option.Maximum - option.Minimum), 0, 1, 0)
	else
		option.Fill.Position = UDim2.new((0 - option.Minimum) / (option.Maximum - option.Minimum), 0, 0, 0)
		option.Fill.Size = UDim2.new(option.Value / (option.Maximum - option.Minimum), 0, 1, 0)
	end
	option.Title.Focused:Connect(function()
		if not manualInput then
			option.Title:ReleaseFocus(true)
			option.Title.Text = (option.Text == "nil" and "" or option.Text .. ": ") .. option.Value .. option.Suffix
		end
	end)
	option.Title.FocusLost:Connect(function(enterPressed : boolean, inputThatCausedFocusLoss : InputObject)
		option.Slider.BorderColor3 = Color3.new(0, 0, 0)
		if manualInput then
			if tonumber(option.Title.Text) then
				option:SetValue(tonumber(option.Title.Text))
			else
				option.Title.Text = (option.Text == "nil" and "" or option.Text .. ": ") .. option.Value .. option.Suffix
			end
		end
		manualInput = false
	end)
	interest.InputBegan:Connect(function(input : InputObject)
		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			if UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) or UserInputService:IsKeyDown(Enum.KeyCode.RightControl) then
				manualInput = true
				option.Title:CaptureFocus()
			else
				VitalLibrary.Slider = option
				option.Slider.BorderColor3 = VitalLibrary.Flags["Menu Accent Color"] or Color3.fromRGB(255, 255, 255)
				option:SetValue(option.Minimum + ((input.Position.X - option.Slider.AbsolutePosition.X) / option.Slider.AbsoluteSize.X) * (option.Maximum - option.Minimum))
			end
		end
		if input.UserInputType == Enum.UserInputType.MouseMovement then
			if not VitalLibrary.Warning and not VitalLibrary.Slider then
				option.Slider.BorderColor3 = VitalLibrary.Flags["Menu Accent Color"] or Color3.fromRGB(255, 255, 255)
			end
			if option.ToolTip then
				VitalLibrary.ToolTip.Text = option.ToolTip
				VitalLibrary.ToolTip.Size = UDim2.new(0, TextService:GetTextSize(option.ToolTip, 15, Enum.Font.Code, Vector2.new(math.huge, math.huge)).X, 0, 20)
			end
		end
	end)
	interest.InputChanged:Connect(function(input : InputObject)
		if input.UserInputType == Enum.UserInputType.MouseMovement then
			if option.ToolTip then
				VitalLibrary.ToolTip.Position = UDim2.new(0, input.Position.X + 26, 0, input.Position.Y + 36)
			end
		end
	end)
	interest.InputEnded:Connect(function(input : InputObject)
		if input.UserInputType == Enum.UserInputType.MouseMovement then
			VitalLibrary.ToolTip.Position = UDim2.new(2, 0, 0, 0)
			if option ~= VitalLibrary.Slider then
				option.Slider.BorderColor3 = Color3.new(0, 0, 0)
				option.Fill.BorderColor3 = Color3.new(0, 0, 0)
			end
		end
	end)
	function option:SetValue(value : number?, nocallback : boolean)
		if typeof(value) ~= "number" then 
			value = 0 
		end
		value = math.clamp(VitalLibrary.SnapTo(value, option.Float), self.Minimum, self.Maximum)
		if self.Minimum >= 0 then
			option.Fill.Size = UDim2.new((value - self.Minimum) / (self.Maximum - self.Minimum), 0, 1, 0)
		else
			option.Fill.Position = UDim2.new((0 - self.Minimum) / (self.Maximum - self.Minimum), 0, 0, 0)
			option.Fill.Size = UDim2.new(value / (self.Maximum - self.Minimum), 0, 1, 0)
		end
		VitalLibrary.Flags[self.Flag] = value
		self.Value = value
		option.Title.Text = (option.Text == "nil" and "" or option.Text .. ": ") .. option.Value .. option.Suffix
		if not nocallback then
			self.Callback(value)
		end
	end
	task.delay(1, function()
		if VitalLibrary then
			option:SetValue(option.Value, false)
		end
	end)
end

VitalLibrary.CreateList = function(option : Dictionary, parent : Instance) : Dictionary
	local selected, valueCount = nil, 0
	local function getMultiText() : string
		local concatenatedList = ""
		for index, value in option.Values do
			concatenatedList = concatenatedList .. (option.Value[value] and (tostring(value) .. ", ") or "")
		end
		return string.sub(concatenatedList, 1, string.len(concatenatedList) - 2)
	end
	option.HasInit = true
	if option.Sub then
		option.Main = option:GetMain()
		option.Main.Size = UDim2.new(1, 0, 0, 48)
	else
		option.Main = VitalLibrary:Create("Frame", {
			LayoutOrder = option.Position,
			Size = UDim2.new(1, 0, 0, option.Text == "nil" and 30 or 48),
			BackgroundTransparency = 1,
			Parent = parent
		}, false)
		if option.Text ~= "nil" then
			VitalLibrary:Create("TextLabel", {
				Position = UDim2.new(0, 6, 0, 0),
				Size = UDim2.new(1, -12, 0, 18),
				BackgroundTransparency = 1,
				Text = option.Text,
				TextSize = 15,
				Font = Enum.Font.Code,
				TextColor3 = Color3.fromRGB(210, 210, 210),
				TextXAlignment = Enum.TextXAlignment.Left,
				Parent = option.Main
			}, false)
		end
	end
	option.ListValue = VitalLibrary:Create("TextLabel", {
		Position = UDim2.new(0, 6, 0, (option.Text == "nil" and not option.Sub) and 4 or 22),
		Size = UDim2.new(1, -12, 0, 22),
		BackgroundColor3 = Color3.fromRGB(50, 50, 50),
		BorderColor3 = Color3.new(0, 0, 0),
		Text = " " .. (typeof(option.Value) == "string" and option.Value or getMultiText()),
		TextSize = 15,
		Font = Enum.Font.Code,
		TextColor3 = Color3.new(1, 1, 1),
		TextXAlignment = Enum.TextXAlignment.Left,
		TextTruncate = Enum.TextTruncate.AtEnd,
		Parent = option.Main
	}, false)
	VitalLibrary:Create("ImageLabel", {
		Size = UDim2.new(1, 0, 1, 0),
		BackgroundTransparency = 1,
		Image = "rbxassetid://2454009026",
		ImageColor3 = Color3.new(0, 0, 0),
		ImageTransparency = 0.8,
		Parent = option.ListValue
	}, false)
	VitalLibrary:Create("ImageLabel", {
		Size = UDim2.new(1, 0, 1, 0),
		BackgroundTransparency = 1,
		Image = "rbxassetid://2592362371",
		ImageColor3 = Color3.fromRGB(60, 60, 60),
		ScaleType = Enum.ScaleType.Slice,
		SliceCenter = Rect.new(2, 2, 62, 62),
		Parent = option.ListValue
	}, false)
	VitalLibrary:Create("ImageLabel", {
		Size = UDim2.new(1, -2, 1, -2),
		Position = UDim2.new(0, 1, 0, 1),
		BackgroundTransparency = 1,
		Image = "rbxassetid://2592362371",
		ImageColor3 = Color3.new(0, 0, 0),
		ScaleType = Enum.ScaleType.Slice,
		SliceCenter = Rect.new(2, 2, 62, 62),
		Parent = option.ListValue
	}, false)
	option.Arrow = VitalLibrary:Create("ImageLabel", {
		Position = UDim2.new(1, -16, 0, 7),
		Size = UDim2.new(0, 8, 0, 8),
		Rotation = 90,
		BackgroundTransparency = 1,
		Image = "rbxassetid://4918373417",
		ImageColor3 = Color3.new(1, 1, 1),
		ScaleType = Enum.ScaleType.Fit,
		ImageTransparency = 0.4,
		Parent = option.ListValue
	}, false)
	option.Holder = VitalLibrary:Create("TextButton", {
		ZIndex = 4,
		BackgroundColor3 = Color3.fromRGB(40, 40, 40),
		BorderColor3 = Color3.new(0, 0, 0),
		Text = "",
		AutoButtonColor = false,
		Visible = false,
		Parent = VitalLibrary.Base
	}, false)
	option.Content = VitalLibrary:Create("ScrollingFrame", {
		ZIndex = 4,
		Size = UDim2.new(1, 0, 1, 0),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		ScrollBarImageColor3 = Color3.new(0, 0, 0),
		ScrollBarThickness = 3,
		ScrollingDirection = Enum.ScrollingDirection.Y,
		VerticalScrollBarInset = Enum.ScrollBarInset.Always,
		TopImage = "rbxasset://textures/ui/Scroll/scroll-middle.png",
		BottomImage = "rbxasset://textures/ui/Scroll/scroll-middle.png",
		Parent = option.Holder
	}, false)
	VitalLibrary:Create("ImageLabel", {
		ZIndex = 4,
		Size = UDim2.new(1, 0, 1, 0),
		BackgroundTransparency = 1,
		Image = "rbxassetid://2592362371",
		ImageColor3 = Color3.fromRGB(60, 60, 60),
		ScaleType = Enum.ScaleType.Slice,
		SliceCenter = Rect.new(2, 2, 62, 62),
		Parent = option.Holder
	}, false)
	VitalLibrary:Create("ImageLabel", {
		ZIndex = 4,
		Size = UDim2.new(1, -2, 1, -2),
		Position = UDim2.new(0, 1, 0, 1),
		BackgroundTransparency = 1,
		Image = "rbxassetid://2592362371",
		ImageColor3 = Color3.new(0, 0, 0),
		ScaleType = Enum.ScaleType.Slice,
		SliceCenter = Rect.new(2, 2, 62, 62),
		Parent = option.Holder
	}, false)
	local layout = VitalLibrary:Create("UIListLayout", {
		Padding = UDim.new(0, 2),
		Parent = option.Content
	}, false)
	VitalLibrary:Create("UIPadding", {
		PaddingTop = UDim.new(0, 4),
		PaddingLeft = UDim.new(0, 4),
		Parent = option.Content
	}, false)
	local interest = option.Sub and option.ListValue or option.Main
	layout.Changed:Connect(function()
		option.Holder.Size = UDim2.new(0, option.ListValue.AbsoluteSize.X, 0, 8 + (valueCount > option.Maximum and (-2 + (option.Maximum * 22)) or layout.AbsoluteContentSize.Y))
		option.Content.CanvasSize = UDim2.new(0, 0, 0, 8 + layout.AbsoluteContentSize.Y)
	end)
	option.ListValue.InputBegan:Connect(function(input : InputObject)
		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			if VitalLibrary.Popup == option then
				VitalLibrary.Popup:Close() 
				return 
			end
			if VitalLibrary.Popup then
				VitalLibrary.Popup:Close()
			end
			option.Arrow.Rotation = -90
			option.IsOpen = true
			option.Holder.Visible = true
			local position = option.Main.AbsolutePosition
			option.Holder.Position = UDim2.new(0, position.X + 6, 0, position.Y + option.ListValue.AbsoluteSize.Y + ((option.Text == "nil" and not option.Sub) and 66 or 84))
			VitalLibrary.Popup = option
			option.ListValue.BorderColor3 = VitalLibrary.Flags["Menu Accent Color"] or Color3.fromRGB(255, 255, 255)
		end
		if input.UserInputType == Enum.UserInputType.MouseMovement then
			if not VitalLibrary.Warning and not VitalLibrary.Slider then
				option.ListValue.BorderColor3 = VitalLibrary.Flags["Menu Accent Color"] or Color3.fromRGB(255, 255, 255)
			end
		end
	end)
	option.ListValue.InputEnded:Connect(function(input : InputObject)
		if input.UserInputType == Enum.UserInputType.MouseMovement then
			if not option.IsOpen then
				option.ListValue.BorderColor3 = Color3.new(0, 0, 0)
			end
		end
	end)
	interest.InputBegan:Connect(function(input : InputObject)
		if input.UserInputType == Enum.UserInputType.MouseMovement then
			if option.ToolTip then
				VitalLibrary.ToolTip.Text = option.ToolTip
				VitalLibrary.ToolTip.Size = UDim2.new(0, TextService:GetTextSize(option.ToolTip, 15, Enum.Font.Code, Vector2.new(math.huge, math.huge)).X, 0, 20)
			end
		end
	end)
	interest.InputChanged:Connect(function(input : InputObject)
		if input.UserInputType == Enum.UserInputType.MouseMovement then
			if option.ToolTip then
				VitalLibrary.ToolTip.Position = UDim2.new(0, input.Position.X + 26, 0, input.Position.Y + 36)
			end
		end
	end)
	interest.InputEnded:Connect(function(input : InputObject)
		if input.UserInputType == Enum.UserInputType.MouseMovement then
			VitalLibrary.ToolTip.Position = UDim2.new(2, 0, 0, 0)
		end
	end)
	function option:AddValue(value : string, state : boolean?)
		if self.Labels[value] then 
			return 
		end
		valueCount = valueCount + 1
		if self.MultipleSelection then
			self.Values[value] = state
		else
			if not table.find(self.Values, value, 1) then
				table.insert(self.Values, value)
			end
		end
		local label = VitalLibrary:Create("TextLabel", {
			ZIndex = 4,
			Size = UDim2.new(1, 0, 0, 20),
			BackgroundTransparency = 1,
			Text = value,
			TextSize = 15,
			Font = Enum.Font.Code,
			TextTransparency = self.MultipleSelection and (self.Value[value] and 1 or 0) or self.Value == value and 1 or 0,
			TextColor3 = Color3.fromRGB(210, 210, 210),
			TextXAlignment = Enum.TextXAlignment.Left,
			Parent = option.Content
		}, false)
		self.Labels[value] = label
		local labelOverlay = VitalLibrary:Create("TextLabel", {
			ZIndex = 4,	
			Size = UDim2.new(1, 0, 1, 0),
			BackgroundTransparency = 0.8,
			Text = " " .. value,
			TextSize = 15,
			Font = Enum.Font.Code,
			TextColor3 = VitalLibrary.Flags["Menu Accent Color"] or Color3.fromRGB(255, 255, 255),
			TextXAlignment = Enum.TextXAlignment.Left,
			Visible = self.MultipleSelection and self.Value[value] or self.Value == value,
			Parent = label
		}, false)
		selected = selected or self.Value == value and labelOverlay
		table.insert(VitalLibrary.Theme, labelOverlay)
		label.InputBegan:Connect(function(input : InputObject)
			if input.UserInputType == Enum.UserInputType.MouseButton1 then
				if self.MultipleSelection then
					self.Value[value] = not self.Value[value]
					self:SetValue(self.Value)
				else
					self:SetValue(value)
					self:Close()
				end
			end
		end)
	end
	for index, value in option.Values do
		option:AddValue(tostring(typeof(index) == "number" and value or index))
	end
	function option:RemoveValue(value : string)
		local label = self.Labels[value]
		if label then
			label:Destroy()
			self.Labels[value] = nil
			valueCount = valueCount - 1
			if self.MultipleSelection then
				self.Values[value] = nil
				self:SetValue(self.Value)
			else
				table.remove(self.Values, table.find(self.Values, value, 1))
				if self.Value == value then
					selected = nil
					self:SetValue(self.Values[1] or "")
				end
			end
		end
	end
	function option:SetValue(value : string | Dictionary, nocallback : boolean)
		local multipleValues = {}
		if self.MultipleSelection and typeof(value) ~= "table" then
			for index, value in self.Values do
				multipleValues[value] = false
			end
		end
		print(option.Values, table.maxn(option.Values))
		value = self.MultipleSelection and multipleValues or value
		self.Value = typeof(value) == "table" and value or tostring(table.find(self.Values, value, 1) and value or self.Values[1])
		VitalLibrary.Flags[self.Flag] = self.Value
		option.ListValue.Text = " " .. (self.MultipleSelection and getMultiText() or self.Value)
		if self.MultipleSelection then
			for name, label in self.Labels do
				label.TextTransparency = self.Value[name] and 1 or 0
				if label:FindFirstChild("TextLabel") then
					label.TextLabel.Visible = self.Value[name]
				end
			end
		else
			if selected then
				selected.TextTransparency = 0
				if selected:FindFirstChild("TextLabel") then
					selected.TextLabel.Visible = false
				end
			end
			if self.Labels[self.Value] then
				selected = self.Labels[self.Value]
				selected.TextTransparency = 1
				if selected:FindFirstChild("TextLabel") then
					selected.TextLabel.Visible = true
				end
			end
		end
		if not nocallback then
			self.Callback(self.Value)
		end
	end
	task.delay(1, function()
		if VitalLibrary then
			option:SetValue(option.Value, false)
		end
	end)
	function option:Close()
		VitalLibrary.Popup = nil
		option.Arrow.Rotation = 90
		self.IsOpen = false
		option.Holder.Visible = false
		option.ListValue.BorderColor3 = Color3.new(0, 0, 0)
	end
	return option
end

VitalLibrary.CreateBox = function(option : Dictionary, parent : Instance)
	option.HasInit = true
	option.Main = VitalLibrary:Create("Frame", {
		LayoutOrder = option.Position,
		Size = UDim2.new(1, 0, 0, option.Text == "nil" and 28 or 44),
		BackgroundTransparency = 1,
		Parent = parent
	}, false)
	if option.Text ~= "nil" then
		option.Title = VitalLibrary:Create("TextLabel", {
			Position = UDim2.new(0, 6, 0, 0),
			Size = UDim2.new(1, -12, 0, 18),
			BackgroundTransparency = 1,
			Text = option.Text,
			TextSize = 15,
			Font = Enum.Font.Code,
			TextColor3 = Color3.fromRGB(210, 210, 210),
			TextXAlignment = Enum.TextXAlignment.Left,
			Parent = option.Main
		}, false)
	end
	option.Holder = VitalLibrary:Create("Frame", {
		Position = UDim2.new(0, 6, 0, option.Text == "nil" and 4 or 20),
		Size = UDim2.new(1, -12, 0, 20),
		BackgroundColor3 = Color3.fromRGB(50, 50, 50),
		BorderColor3 = Color3.new(0, 0, 0),
		Parent = option.Main
	}, false)
	VitalLibrary:Create("ImageLabel", {
		Size = UDim2.new(1, 0, 1, 0),
		BackgroundTransparency = 1,
		Image = "rbxassetid://2454009026",
		ImageColor3 = Color3.new(0, 0, 0),
		ImageTransparency = 0.8,
		Parent = option.Holder
	}, false)
	VitalLibrary:Create("ImageLabel", {
		Size = UDim2.new(1, 0, 1, 0),
		BackgroundTransparency = 1,
		Image = "rbxassetid://2592362371",
		ImageColor3 = Color3.fromRGB(60, 60, 60),
		ScaleType = Enum.ScaleType.Slice,
		SliceCenter = Rect.new(2, 2, 62, 62),
		Parent = option.Holder
	}, false)
	VitalLibrary:Create("ImageLabel", {
		Size = UDim2.new(1, -2, 1, -2),
		Position = UDim2.new(0, 1, 0, 1),
		BackgroundTransparency = 1,
		Image = "rbxassetid://2592362371",
		ImageColor3 = Color3.new(0, 0, 0),
		ScaleType = Enum.ScaleType.Slice,
		SliceCenter = Rect.new(2, 2, 62, 62),
		Parent = option.Holder
	}, false)
	local inputvalue = VitalLibrary:Create("TextBox", {
		Position = UDim2.new(0, 4, 0, 0),
		Size = UDim2.new(1, -4, 1, 0),
		BackgroundTransparency = 1,
		Text = "  " .. option.Value,
		TextSize = 15,
		Font = Enum.Font.Code,
		TextColor3 = Color3.new(1, 1, 1),
		TextXAlignment = Enum.TextXAlignment.Left,
		TextWrapped = true,
		ClearTextOnFocus = false,
		Parent = option.Holder
	}, false)
	inputvalue.FocusLost:Connect(function(enterPressed : boolean, inputThatCausedFocusLoss : InputObject)
		option.Holder.BorderColor3 = Color3.new(0, 0, 0)
		option:SetValue(inputvalue.Text, enterPressed)
	end)
	inputvalue.Focused:Connect(function()
		option.Holder.BorderColor3 = VitalLibrary.Flags["Menu Accent Color"] or Color3.fromRGB(255, 255, 255)
	end)
	inputvalue.InputBegan:Connect(function(input : InputObject)
		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			inputvalue.Text = ""
		end
		if input.UserInputType == Enum.UserInputType.MouseMovement then
			if not VitalLibrary.Warning and not VitalLibrary.Slider then
				option.Holder.BorderColor3 = VitalLibrary.Flags["Menu Accent Color"] or Color3.fromRGB(255, 255, 255)
			end
			if option.ToolTip then
				VitalLibrary.ToolTip.Text = option.ToolTip
				VitalLibrary.ToolTip.Size = UDim2.new(0, TextService:GetTextSize(option.ToolTip, 15, Enum.Font.Code, Vector2.new(math.huge, math.huge)).X, 0, 20)
			end
		end
	end)
	inputvalue.InputChanged:Connect(function(input : InputObject)
		if input.UserInputType == Enum.UserInputType.MouseMovement then
			if option.ToolTip then
				VitalLibrary.ToolTip.Position = UDim2.new(0, input.Position.X + 26, 0, input.Position.Y + 36)
			end
		end
	end)
	inputvalue.InputEnded:Connect(function(input : InputObject)
		if input.UserInputType == Enum.UserInputType.MouseMovement then
			if not inputvalue:IsFocused() then
				option.Holder.BorderColor3 = Color3.new(0, 0, 0)
			end
			VitalLibrary.ToolTip.Position = UDim2.new(2, 0, 0, 0)
		end
	end)
	function option:SetValue(value : string, enterPressed : boolean)
		if tostring(value) == "" then
			inputvalue.Text = self.Value
		else
			VitalLibrary.Flags[self.Flag] = tostring(value)
			self.Value = tostring(value)
			inputvalue.Text = self.Value
			self.Callback(value, enterPressed)
		end
	end
	task.delay(1, function()
		if VitalLibrary then
			option:SetValue(option.Value, false)
		end
	end)
end

VitalLibrary.CreateColorPickerWindow = function(option : Dictionary) : Dictionary
	option.MainHolder = VitalLibrary:Create("TextButton", {
		ZIndex = 4,
		Position = UDim2.new(1, -184, 1, 6),
		Size = UDim2.new(0, option.Transparency and 200 or 184, 0, 264),
		BackgroundColor3 = Color3.fromRGB(40, 40, 40),
		BorderColor3 = Color3.new(0, 0, 0),
		AutoButtonColor = false,
		Visible = false,
		Parent = VitalLibrary.Base
	}, false)
	option.RGBBox = VitalLibrary:Create("Frame", {
		Position = UDim2.new(0, 6, 0, 214),
		Size = UDim2.new(0, (option.MainHolder.AbsoluteSize.X - 12), 0, 20),
		BackgroundColor3 = Color3.fromRGB(57, 57, 57),
		BorderColor3 = Color3.new(0, 0, 0),
		ZIndex = 5,
		Parent = option.MainHolder
	}, false)
	VitalLibrary:Create("ImageLabel", {
		Size = UDim2.new(1, 0, 1, 0),
		BackgroundTransparency = 1,
		Image = "rbxassetid://2454009026",
		ImageColor3 = Color3.new(0, 0, 0),
		ImageTransparency = 0.8,
		ZIndex = 6,
		Parent = option.RGBBox
	}, false)
	VitalLibrary:Create("ImageLabel", {
		Size = UDim2.new(1, 0, 1, 0),
		BackgroundTransparency = 1,
		Image = "rbxassetid://2592362371",
		ImageColor3 = Color3.fromRGB(60, 60, 60),
		ScaleType = Enum.ScaleType.Slice,
		SliceCenter = Rect.new(2, 2, 62, 62),
		ZIndex = 6,
		Parent = option.RGBBox
	}, false)
	VitalLibrary:Create("ImageLabel", {
		Size = UDim2.new(1, -2, 1, -2),
		Position = UDim2.new(0, 1, 0, 1),
		BackgroundTransparency = 1,
		Image = "rbxassetid://2592362371",
		ImageColor3 = Color3.new(0, 0, 0),
		ScaleType = Enum.ScaleType.Slice,
		SliceCenter = Rect.new(2, 2, 62, 62),
		ZIndex = 6,
		Parent = option.RGBBox
	}, false)
	option.RGBInput = VitalLibrary:Create("TextBox", {
		Position = UDim2.new(0, 4, 0, 0),
		Size = UDim2.new(1, -4, 1, 0),
		BackgroundTransparency = 1,
		Text = tostring(option.Color),
		TextSize = 14,
		Font = Enum.Font.Code,
		TextColor3 = Color3.new(1, 1, 1),
		TextXAlignment = Enum.TextXAlignment.Center,
		TextWrapped = true,
		ClearTextOnFocus = false,
		ZIndex = 6;
		Parent = option.RGBBox
	}, false)
	option.HexBox = option.RGBBox:Clone()
	option.HexBox.Position = UDim2.new(0, 6, 0, 238)
	option.HexBox.Size = UDim2.new(0, (option.MainHolder.AbsoluteSize.X / 2 - 10), 0, 20)
	option.HexBox.Parent = option.MainHolder
	option.HexInput = option.HexBox.TextBox
	VitalLibrary:Create("ImageLabel", {
		ZIndex = 4,
		Size = UDim2.new(1, 0, 1, 0),
		BackgroundTransparency = 1,
		Image = "rbxassetid://2592362371",
		ImageColor3 = Color3.fromRGB(60, 60, 60),
		ScaleType = Enum.ScaleType.Slice,
		SliceCenter = Rect.new(2, 2, 62, 62),
		Parent = option.MainHolder
	}, false)
	VitalLibrary:Create("ImageLabel", {
		ZIndex = 4,
		Size = UDim2.new(1, -2, 1, -2),
		Position = UDim2.new(0, 1, 0, 1),
		BackgroundTransparency = 1,
		Image = "rbxassetid://2592362371",
		ImageColor3 = Color3.new(0, 0, 0),
		ScaleType = Enum.ScaleType.Slice,
		SliceCenter = Rect.new(2, 2, 62, 62),
		Parent = option.MainHolder
	}, false)
	local transparencyMain = nil
	local hue, saturation, value = option.Color:ToHSV()
	local editingHue, editingTransparency, editingSaturationValue = false, false, false
	hue, saturation, value = hue == 0 and 1 or hue, saturation + 0.005, value - 0.005
	if option.Transparency then
		transparencyMain = VitalLibrary:Create("ImageLabel", {
			ZIndex = 5,
			Size = UDim2.new(1, 0, 1, 0),
			BackgroundTransparency = 1,
			Image = "rbxassetid://2454009026",
			ImageColor3 = Color3.fromHSV(hue, 1, 1),
			Rotation = 180,
			Parent = VitalLibrary:Create("ImageLabel", {
				ZIndex = 4,
				AnchorPoint = Vector2.new(1, 0),
				Position = UDim2.new(1, -6, 0, 6),
				Size = UDim2.new(0, 10, 1, -60),
				BorderColor3 = Color3.new(0, 0, 0),
				Image = "rbxassetid://4632082392",
				ScaleType = Enum.ScaleType.Tile,
				TileSize = UDim2.new(0, 5, 0, 5),
				Parent = option.MainHolder
			}, false)
		}, false)
		option.TransparencySlider = VitalLibrary:Create("Frame", {
			ZIndex = 5,
			Position = UDim2.new(0, 0, option.Transparency, 0),
			Size = UDim2.new(1, 0, 0, 2),
			BackgroundColor3 = Color3.fromRGB(38, 41, 65),
			BorderColor3 = Color3.fromRGB(255, 255, 255),
			Parent = transparencyMain
		}, false)
		transparencyMain.InputBegan:Connect(function(input : InputObject)
			if input.UserInputType == Enum.UserInputType.MouseButton1 then
				editingTransparency = true
				option:SetTransparency(1 - ((input.Position.Y - transparencyMain.AbsolutePosition.Y) / transparencyMain.AbsoluteSize.Y))
			end
		end)
		transparencyMain.InputEnded:Connect(function(input : InputObject)
			if input.UserInputType == Enum.UserInputType.MouseButton1 then
				editingTransparency = false
			end
		end)
	end
	local hueMain = VitalLibrary:Create("Frame", {
		ZIndex = 4,
		AnchorPoint = Vector2.new(0, 1),
		Position = UDim2.new(0, 6, 1, -54),
		Size = UDim2.new(1, option.Transparency and -28 or -12, 0, 10),
		BackgroundColor3 = Color3.new(1, 1, 1),
		BorderColor3 = Color3.new(0, 0, 0),
		Parent = option.MainHolder
	}, false)
	local hueSlider = VitalLibrary:Create("Frame", {
		ZIndex = 4,
		Position = UDim2.new(1 - hue, 0, 0, 0),
		Size = UDim2.new(0, 2, 1, 0),
		BackgroundColor3 = Color3.fromRGB(38, 41, 65),
		BorderColor3 = Color3.fromRGB(255, 255, 255),
		Parent = hueMain
	}, false)
	local gradient = VitalLibrary:Create("UIGradient", {
		Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 0, 0)),
			ColorSequenceKeypoint.new(0.17, Color3.fromRGB(255, 0, 255)),
			ColorSequenceKeypoint.new(0.33, Color3.fromRGB(0, 0, 255)),
			ColorSequenceKeypoint.new(0.5, Color3.fromRGB(0, 255, 255)),
			ColorSequenceKeypoint.new(0.67, Color3.fromRGB(0, 255, 0)),
			ColorSequenceKeypoint.new(0.83, Color3.fromRGB(255, 255, 0)),
			ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 0, 0)),
		}),
		Parent = hueMain
	}, false)
	hueMain.InputBegan:Connect(function(input : InputObject)
		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			editingHue = true
			local x = (hueMain.AbsolutePosition.X + hueMain.AbsoluteSize.X) - hueMain.AbsolutePosition.X
			x = math.clamp((input.Position.X - hueMain.AbsolutePosition.X) / x, 0, 0.995)
			option:SetColor(Color3.fromHSV(1 - x, saturation, value))
		end
	end)
	hueMain.InputEnded:Connect(function(input : InputObject)
		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			editingHue = false
		end
	end)
	local saturationValue = VitalLibrary:Create("ImageLabel", {
		ZIndex = 4,
		Position = UDim2.new(0, 6, 0, 6),
		Size = UDim2.new(1, option.Transparency and -28 or -12, 1, -74),
		BackgroundColor3 = Color3.fromHSV(hue, 1, 1),
		BorderColor3 = Color3.new(0, 0, 0),
		Image = "rbxassetid://4155801252",
		ClipsDescendants = true,
		Parent = option.MainHolder
	}, false)
	local saturationValueSlider = VitalLibrary:Create("Frame", {
		ZIndex = 4,
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.new(saturation, 0, 1 - value, 0),
		Size = UDim2.new(0, 4, 0, 4),
		Rotation = 45,
		BackgroundColor3 = Color3.fromRGB(255, 255, 255),
		Parent = saturationValue
	}, false)
	saturationValue.InputBegan:Connect(function(input : InputObject)
		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			editingSaturationValue = true
			local x = (saturationValue.AbsolutePosition.X + saturationValue.AbsoluteSize.X) - saturationValue.AbsolutePosition.X
			local y = (saturationValue.AbsolutePosition.Y + saturationValue.AbsoluteSize.Y) - saturationValue.AbsolutePosition.Y
			x = math.clamp((input.Position.X - saturationValue.AbsolutePosition.X) / x, 0.005, 1)
			y = math.clamp((input.Position.Y - saturationValue.AbsolutePosition.Y) / y, 0, 0.995)
			option:SetColor(Color3.fromHSV(hue, x, 1 - y))
		end
	end)
	VitalLibrary:AddConnection(UserInputService.InputChanged, function(input : InputObject, gameProcessedEvent : boolean)
		if input.UserInputType == Enum.UserInputType.MouseMovement then
			if editingSaturationValue then
				local x = (saturationValue.AbsolutePosition.X + saturationValue.AbsoluteSize.X) - saturationValue.AbsolutePosition.X
				local y = (saturationValue.AbsolutePosition.Y + saturationValue.AbsoluteSize.Y) - saturationValue.AbsolutePosition.Y
				x = math.clamp((input.Position.X - saturationValue.AbsolutePosition.X) / x, 0.005, 1)
				y = math.clamp((input.Position.Y - saturationValue.AbsolutePosition.Y) / y, 0, 0.995)
				option:SetColor(Color3.fromHSV(hue, x, 1 - y))
			elseif editingHue then
				local x = (hueMain.AbsolutePosition.X + hueMain.AbsoluteSize.X) - hueMain.AbsolutePosition.X
				x = math.clamp((input.Position.X - hueMain.AbsolutePosition.X) / x, 0, 0.995)
				option:SetColor(Color3.fromHSV(1 - x, saturation, value))
			elseif editingTransparency then
				option:SetTransparency(1 - ((input.Position.Y - transparencyMain.AbsolutePosition.Y) / transparencyMain.AbsoluteSize.Y))
			end
		end
	end)
	saturationValue.InputEnded:Connect(function(input : InputObject)
		if input.UserInputType.Name == "MouseButton1" then
			editingSaturationValue = false
		end
	end)
	local r, g, b = VitalLibrary.SnapTo(option.Color, nil)
	option.HexInput.Text = string.format("#%02x%02x%02x", r, g, b)
	option.RGBInput.Text = table.concat({r, g, b}, ",", 1, 3)
	option.RGBInput.FocusLost:Connect(function(enterPressed : boolean, inputThatCausedFocusLoss : InputObject)
		local r, g, b = string.match(string.gsub(option.RGBInput.Text, "%s+", "", math.huge), "(%d+),(%d+),(%d+)", 1)
		if r and g and b then
			local color = Color3.fromRGB(tonumber(r), tonumber(g), tonumber(b))
			return option:SetColor(color)
		end
		local r, g, b = VitalLibrary.SnapTo(option.Color, nil)
		option.RGBInput.Text = table.concat({r, g, b}, ",", 1, 3)
	end)
	option.HexInput.FocusLost:Connect(function(enterPressed : boolean, inputThatCausedFocusLoss : InputObject)
		local r, g, b = string.match(option.HexInput.Text, "#?(..)(..)(..)")
		if r and g and b then
			local color = Color3.fromRGB(tonumber("0x" .. r), tonumber("0x" .. g), tonumber("0x" .. b))
			return option:SetColor(color)
		end
		local r, g, b = VitalLibrary.SnapTo(option.Color, nil)
		option.HexInput.Text = string.format("#%02x%02x%02x", r, g, b)
	end)
	function option:UpdateVisuals(color : Color3)
		hue, saturation, value = color:ToHSV()
		hue = hue == 0 and 1 or hue
		saturationValue.BackgroundColor3 = Color3.fromHSV(hue, 1, 1)
		if option.Transparency then
			transparencyMain.ImageColor3 = Color3.fromHSV(hue, 1, 1)
		end
		hueSlider.Position = UDim2.new(1 - hue, 0, 0, 0)
		saturationValueSlider.Position = UDim2.new(saturation, 0, 1 - value, 0)
		local r, g, b = VitalLibrary.SnapTo(Color3.fromHSV(hue, saturation, value), nil)
		option.HexInput.Text = string.format("#%02x%02x%02x", r, g, b)
		option.RGBInput.Text = table.concat({r, g, b}, ",", 1, 3)
	end
	return option
end

VitalLibrary.CreateColor = function(option : Dictionary, parent : Instance)
	option.HasInit = true
	if option.Sub then
		option.Main = option:GetMain()
	else
		option.Main = VitalLibrary:Create("Frame", {
			LayoutOrder = option.Position,
			Size = UDim2.new(1, 0, 0, 20),
			BackgroundTransparency = 1,
			Parent = parent
		}, false)
		option.Title = VitalLibrary:Create("TextLabel", {
			Position = UDim2.new(0, 6, 0, 0),
			Size = UDim2.new(1, -12, 1, 0),
			BackgroundTransparency = 1,
			Text = option.Text,
			TextSize = 15,
			Font = Enum.Font.Code,
			TextColor3 = Color3.fromRGB(210, 210, 210),
			TextXAlignment = Enum.TextXAlignment.Left,
			Parent = option.Main
		}, false)
	end
	option.Visualize = VitalLibrary:Create(option.Sub and "TextButton" or "Frame", {
		Position = UDim2.new(1, -(option.SubPosition or 0) - 24, 0, 4),
		Size = UDim2.new(0, 18, 0, 12),
		SizeConstraint = Enum.SizeConstraint.RelativeYY,
		BackgroundColor3 = option.Color,
		BorderColor3 = Color3.new(0, 0, 0),
		Parent = option.Main
	}, false)
	VitalLibrary:Create("ImageLabel", {
		Size = UDim2.new(1, 0, 1, 0),
		BackgroundTransparency = 1,
		Image = "rbxassetid://2454009026",
		ImageColor3 = Color3.new(0, 0, 0),
		ImageTransparency = 0.6,
		Parent = option.Visualize
	}, false)
	VitalLibrary:Create("ImageLabel", {
		Size = UDim2.new(1, 0, 1, 0),
		BackgroundTransparency = 1,
		Image = "rbxassetid://2592362371",
		ImageColor3 = Color3.fromRGB(60, 60, 60),
		ScaleType = Enum.ScaleType.Slice,
		SliceCenter = Rect.new(2, 2, 62, 62),
		Parent = option.Visualize
	}, false)
	VitalLibrary:Create("ImageLabel", {
		Size = UDim2.new(1, -2, 1, -2),
		Position = UDim2.new(0, 1, 0, 1),
		BackgroundTransparency = 1,
		Image = "rbxassetid://2592362371",
		ImageColor3 = Color3.new(0, 0, 0),
		ScaleType = Enum.ScaleType.Slice,
		SliceCenter = Rect.new(2, 2, 62, 62),
		Parent = option.Visualize
	}, false)
	local interest = option.Sub and option.Visualize or option.Main
	if option.Sub then
		option.Visualize.Text = ""
		option.Visualize.AutoButtonColor = false
	end
	interest.InputBegan:Connect(function(input : InputObject)
		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			if not option.MainHolder then VitalLibrary.CreateColorPickerWindow(option) end
			if VitalLibrary.Popup == option then VitalLibrary.Popup:Close() return end
			if VitalLibrary.Popup then VitalLibrary.Popup:Close() end
			option.IsOpen = true
			local pos = option.Main.AbsolutePosition
			option.MainHolder.Position = UDim2.new(0, pos.X + 36 + (option.Transparency and -16 or 0), 0, pos.Y + 56 + option.Visualize.AbsoluteSize.Y * 2)
			option.MainHolder.Visible = true
			VitalLibrary.Popup = option
			option.Visualize.BorderColor3 = VitalLibrary.Flags["Menu Accent Color"] or Color3.fromRGB(255, 255, 255)
		end
		if input.UserInputType == Enum.UserInputType.MouseMovement then
			if not VitalLibrary.Warning and not VitalLibrary.Slider then
				option.Visualize.BorderColor3 = VitalLibrary.Flags["Menu Accent Color"] or Color3.fromRGB(255, 255, 255)
			end
			if option.ToolTip then
				VitalLibrary.ToolTip.Text = option.ToolTip
				VitalLibrary.ToolTip.Size = UDim2.new(0, TextService:GetTextSize(option.ToolTip, 15, Enum.Font.Code, Vector2.new(math.huge, math.huge)).X, 0, 20)
			end
		end
	end)
	interest.InputChanged:Connect(function(input : InputObject)
		if input.UserInputType == Enum.UserInputType.MouseMovement then
			if option.ToolTip then
				VitalLibrary.ToolTip.Position = UDim2.new(0, input.Position.X + 26, 0, input.Position.Y + 36)
			end
		end
	end)
	interest.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseMovement then
			if not option.IsOpen then
				option.Visualize.BorderColor3 = Color3.new(0, 0, 0)
			end
			VitalLibrary.ToolTip.Position = UDim2.new(2, 0, 0, 0)
		end
	end)
	function option:SetColor(newColor : Color3 | {number}, nocallback : boolean)
		if typeof(newColor) == "table" then
			newColor = Color3.new(newColor[1], newColor[2], newColor[3])
		end
		newColor = newColor or Color3.new(1, 1, 1)
		if self.MainHolder then
			self:UpdateVisuals(newColor)
		end
		option.Visualize.BackgroundColor3 = newColor
		VitalLibrary.Flags[self.Flag] = newColor
		self.Color = newColor
		if not nocallback then
			self.Callback(newColor)
		end
	end
	if option.Transparency then
		function option:SetTransparency(value : number)
			value = math.clamp(tonumber(value) or 0, 0, 1)
			if self.TransparencySlider then
				self.TransparencySlider.Position = UDim2.new(0, 0, value, 0)
			end
			self.Transparency = value
			VitalLibrary.Flags[self.Flag .. " Transparency"] = 1 - value
			self.CallTransparency(value)
		end
		option:SetTransparency(option.Transparency)
	end
	task.delay(1, function()
		if VitalLibrary then
			option:SetColor(option.Color, false)
		end
	end)
	function option:Close()
		VitalLibrary.Popup = nil
		self.IsOpen = false
		self.MainHolder.Visible = false
		option.Visualize.BorderColor3 = Color3.new(0, 0, 0)
	end
end

function VitalLibrary:AddTab(title : string, position : number) : Dictionary
	local tab = {Tabs = {}, Title = tostring(title), CanInit = true, Columns = {}}
	table.insert(self.Tabs, position or table.maxn(self.Tabs) + 1, tab)
	function tab:AddColumn() : Dictionary
		local column = {Tab = self, CanInit = true, Position = table.maxn(self.Columns), Sections = {}}
		table.insert(self.Columns, column)
		function column:AddSection(title : string) : Dictionary
			local section = {Title = tostring(title), Column = self, CanInit = true, Options = {}}
			table.insert(self.Sections, section)
			function section:AddLabel(text : string) : Dictionary
				local option = {Text = text}
				option.Section = self
				option.Type = "Label"
				option.Position = table.maxn(self.Options)
				option.CanInit = true
				table.insert(self.Options, option)
				if VitalLibrary.HasInit and self.HasInit then
					VitalLibrary.CreateLabel(option, self.Content)
				else
					option.Init = VitalLibrary.CreateLabel
				end
				return option
			end
			function section:AddDivider(text : string) : Dictionary
				local option = {Text = text}
				option.Section = self
				option.Type = "Divider"
				option.Position = table.maxn(self.Options)
				option.CanInit = true
				table.insert(self.Options, option)
				if VitalLibrary.HasInit and self.HasInit then
					VitalLibrary.CreateDivider(option, self.Content)
				else
					option.Init = VitalLibrary.CreateDivider
				end
				return option
			end

			function section:AddToggle(option : Dictionary) : Dictionary
				option = typeof(option) == "table" and option or {}
				option.Section = self
				option.Text = tostring(option.Text)
				option.State = typeof(option.State) == "boolean" and option.State or false
				option.Callback = typeof(option.Callback) == "function" and option.Callback or function() end
				option.Type = "Toggle"
				option.Position = table.maxn(self.Options)
				option.Flag = (VitalLibrary.FlagPrefix and VitalLibrary.FlagPrefix .. " " or "") .. (option.Flag or option.Text)
				option.SubCount = 0
				option.CanInit = (option.CanInit ~= nil and option.CanInit) or true
				option.ToolTip = option.ToolTip and tostring(option.ToolTip)
				option.Style = option.Style == 2
				VitalLibrary.Flags[option.Flag] = option.State
				table.insert(self.Options, option)
				VitalLibrary.Options[option.Flag] = option
				function option:AddColor(subOption : Dictionary) : Dictionary
					subOption = typeof(subOption) == "table" and subOption or {}
					subOption.Sub = true
					subOption.SubPosition = self.SubCount * 24
					function subOption:GetMain() 
						return option.Main 
					end
					self.SubCount = self.SubCount + 1
					return section:AddColor(subOption)
				end
				function option:AddBind(subOption : Dictionary) : Dictionary
					subOption = typeof(subOption) == "table" and subOption or {}
					subOption.Sub = true
					subOption.SubPosition = self.SubCount * 24
					function subOption:GetMain()
						return option.Main 
					end
					self.SubCount = self.SubCount + 1
					return section:AddBind(subOption)
				end
				function option:AddList(subOption : Dictionary) : Dictionary
					subOption = typeof(subOption) == "table" and subOption or {}
					subOption.Sub = true
					function subOption:GetMain() 
						return option.Main 
					end
					self.SubCount = self.SubCount + 1
					return section:AddList(subOption)
				end
				function option:AddSlider(subOption : Dictionary) : Dictionary
					subOption = typeof(subOption) == "table" and subOption or {}
					subOption.Sub = true
					function subOption:GetMain() 
						return option.Main 
					end
					self.SubCount = self.SubCount + 1
					return section:AddSlider(subOption)
				end
				if VitalLibrary.HasInit and self.HasInit then
					VitalLibrary.CreateToggle(option, self.Content)
				else
					option.Init = VitalLibrary.CreateToggle
				end
				return option
			end
			function section:AddButton(option : Dictionary) : Dictionary
				option = typeof(option) == "table" and option or {}
				option.Section = self
				option.Text = tostring(option.Text)
				option.Callback = typeof(option.Callback) == "function" and option.Callback or function() end
				option.Type = "Button"
				option.Position = table.maxn(self.Options)
				option.Flag = (VitalLibrary.FlagPrefix and VitalLibrary.FlagPrefix .. " " or "") .. (option.Flag or option.Text)
				option.SubCount = 0
				option.CanInit = (option.CanInit ~= nil and option.CanInit) or true
				option.ToolTip = option.ToolTip and tostring(option.ToolTip)
				table.insert(self.Options, option)
				VitalLibrary.Options[option.Flag] = option
				function option:AddBind(subOption : Dictionary) : Dictionary
					subOption = typeof(subOption) == "table" and subOption or {}
					subOption.Sub = true
					subOption.SubPosition = self.SubCount * 24
					function subOption:GetMain() 
						option.Main.Size = UDim2.new(1, 0, 0, 40) 
						return option.Main 
					end
					self.SubCount = self.SubCount + 1
					return section:AddBind(subOption)
				end
				function option:AddColor(subOption : Dictionary) : Dictionary
					subOption = typeof(subOption) == "table" and subOption or {}
					subOption.Sub = true
					subOption.SubPosition = self.SubCount * 24
					function subOption:GetMain()
						option.Main.Size = UDim2.new(1, 0, 0, 40) 
						return option.Main 
					end
					self.SubCount = self.SubCount + 1
					return section:AddColor(subOption)
				end
				if VitalLibrary.HasInit and self.HasInit then
					VitalLibrary.CreateButton(option, self.Content)
				else
					option.Init = VitalLibrary.CreateButton
				end
				return option
			end
			function section:AddBind(option : Dictionary) : Dictionary
				option = typeof(option) == "table" and option or {}
				option.Section = self
				option.Text = tostring(option.Text)
				option.KeyCode = (option.KeyCode and option.KeyCode.Name) or option.KeyCode or "None"
				option.NoMouse = typeof(option.NoMouse) == "boolean" and option.NoMouse or false
				option.Mode = (typeof(option.Mode) == "string" and (option.Mode == "Toggle" or option.Mode == "Hold")) and option.Mode or "Toggle"
				option.Callback = typeof(option.Callback) == "function" and option.Callback or function() end
				option.Type = "Bind"
				option.Position = table.maxn(self.Options)
				option.Flag = (VitalLibrary.FlagPrefix and VitalLibrary.FlagPrefix .. " " or "") .. (option.Flag or option.Text)
				option.CanInit = (option.CanInit ~= nil and option.CanInit) or true
				option.ToolTip = option.ToolTip and tostring(option.ToolTip)
				table.insert(self.Options, option)
				VitalLibrary.Options[option.Flag] = option
				if VitalLibrary.HasInit and self.HasInit then
					VitalLibrary.CreateBind(option, self.Content)
				else
					option.Init = VitalLibrary.CreateBind
				end
				return option
			end
			function section:AddSlider(option : Dictionary) : Dictionary
				option = typeof(option) == "table" and option or {}
				option.Section = self
				option.Text = tostring(option.Text)
				option.Minimum = typeof(option.Minimum) == "number" and option.Minimum or 0
				option.Maximum = typeof(option.Maximum) == "number" and option.Maximum or 0
				option.Value = option.Minimum < 0 and 0 or math.clamp(typeof(option.Value) == "number" and option.Value or option.Minimum, option.Minimum, option.Maximum)
				option.Callback = typeof(option.Callback) == "function" and option.Callback or function() end
				option.Float = typeof(option.Value) == "number" and option.Float or 1
				option.Suffix = option.Suffix and tostring(option.Suffix) or ""
				option.TextPosition = option.TextPosition == 2
				option.Type = "Slider"
				option.Position = table.maxn(self.Options)
				option.Flag = (VitalLibrary.FlagPrefix and VitalLibrary.FlagPrefix .. " " or "") .. (option.Flag or option.Text)
				option.SubCount = 0
				option.CanInit = (option.CanInit ~= nil and option.CanInit) or true
				option.ToolTip = option.ToolTip and tostring(option.ToolTip)
				VitalLibrary.Flags[option.Flag] = option.Value
				table.insert(self.Options, option)
				VitalLibrary.Options[option.Flag] = option
				function option:AddColor(subOption : Dictionary) : Dictionary
					subOption = typeof(subOption) == "table" and subOption or {}
					subOption.Sub = true
					subOption.SubPosition = self.SubCount * 24
					function subOption:GetMain()
						return option.Main 
					end
					self.SubCount = self.SubCount + 1
					return section:AddColor(subOption)
				end
				function option:AddBind(subOption : Dictionary) : Dictionary
					subOption = typeof(subOption) == "table" and subOption or {}
					subOption.Sub = true
					subOption.SubPosition = self.SubCount * 24
					function subOption:GetMain()
						return option.Main 
					end
					self.SubCount = self.SubCount + 1
					return section:AddBind(subOption)
				end
				if VitalLibrary.HasInit and self.HasInit then
					VitalLibrary.CreateSlider(option, self.Content)
				else
					option.Init = VitalLibrary.CreateSlider
				end
				return option
			end
			function section:AddList(option : Dictionary) : Dictionary
				option = typeof(option) == "table" and option or {}
				option.Section = self
				option.Text = tostring(option.Text)
				option.Values = typeof(option.Values) == "table" and option.Values or {}
				option.Callback = typeof(option.Callback) == "function" and option.Callback or function() end
				option.MultipleSelection = typeof(option.MultipleSelection) == "boolean" and option.MultipleSelection or false
				option.Value = option.MultipleSelection and (typeof(option.Value) == "table" and option.Value or {}) or tostring(option.Value or option.Values[1] or "")
				if option.MultipleSelection then
					for i,v in next, option.Values do
						option.Value[v] = false
					end
				end
				option.Maximum = option.Maximum or 4
				option.IsOpen = false
				option.Type = "List"
				option.Position = table.maxn(self.Options)
				option.Labels = {}
				option.Flag = (VitalLibrary.FlagPrefix and VitalLibrary.FlagPrefix .. " " or "") .. (option.Flag or option.Text)
				option.SubCount = 0
				option.CanInit = (option.CanInit ~= nil and option.CanInit) or true
				option.ToolTip = option.ToolTip and tostring(option.ToolTip)
				VitalLibrary.Flags[option.Flag] = option.Value
				table.insert(self.Options, option)
				VitalLibrary.Options[option.Flag] = option
				function option:AddValue(value : string, state : boolean)
					if self.MultipleSelection then
						self.Values[value] = state
					else
						table.insert(self.Values, value)
					end
				end
				function option:AddColor(subOption : Dictionary) : Dictionary
					subOption = typeof(subOption) == "table" and subOption or {}
					subOption.Sub = true
					subOption.SubPosition = self.SubCount * 24
					function subOption:GetMain()
						return option.Main 
					end
					self.SubCount = self.SubCount + 1
					return section:AddColor(subOption)
				end
				function option:AddBind(subOption : Dictionary) : Dictionary
					subOption = typeof(subOption) == "table" and subOption or {}
					subOption.Sub = true
					subOption.SubPosition = self.SubCount * 24
					function subOption:GetMain() 
						return option.Main 
					end
					self.SubCount = self.SubCount + 1
					return section:AddBind(subOption)
				end
				if VitalLibrary.HasInit and self.HasInit then
					VitalLibrary.CreateList(option, self.Content)
				else
					option.Init = VitalLibrary.CreateList
				end
				return option
			end
			function section:AddBox(option : Dictionary) : Dictionary
				option = typeof(option) == "table" and option or {}
				option.Section = self
				option.Text = tostring(option.Text)
				option.Value = tostring(option.Value or "")
				option.Callback = typeof(option.Callback) == "function" and option.Callback or function() end
				option.Type = "Box"
				option.Position = table.maxn(self.Options)
				option.Flag = (VitalLibrary.FlagPrefix and VitalLibrary.FlagPrefix .. " " or "") .. (option.Flag or option.Text)
				option.CanInit = (option.CanInit ~= nil and option.CanInit) or true
				option.ToolTip = option.ToolTip and tostring(option.ToolTip)
				VitalLibrary.Flags[option.Flag] = option.Value
				table.insert(self.Options, option)
				VitalLibrary.Options[option.Flag] = option
				if VitalLibrary.HasInit and self.HasInit then
					VitalLibrary.CreateBox(option, self.Content)
				else
					option.Init = VitalLibrary.CreateBox
				end
				return option
			end
			function section:AddColor(option : Dictionary) : Dictionary
				option = typeof(option) == "table" and option or {}
				option.Section = self
				option.Text = tostring(option.Text)
				option.Color = typeof(option.Color) == "table" and Color3.new(option.Color[1], option.Color[2], option.Color[3]) or option.Color or Color3.new(1, 1, 1)
				option.Callback = typeof(option.Callback) == "function" and option.Callback or function() end
				option.CallTransparency = typeof(option.CallTransparency) == "function" and option.CallTransparency or (option.CallTransparency == 1 and option.Callback) or function() end
				option.IsOpen = false
				option.Transparency = tonumber(option.Transparency)
				option.SubCount = 1
				option.Type = "Color"
				option.Position = table.maxn(self.Options)
				option.Flag = (VitalLibrary.FlagPrefix and VitalLibrary.FlagPrefix .. " " or "") .. (option.Flag or option.Text)
				option.CanInit = (option.CanInit ~= nil and option.CanInit) or true
				option.ToolTip = option.ToolTip and tostring(option.ToolTip)
				VitalLibrary.Flags[option.Flag] = option.Color
				table.insert(self.Options, option)
				VitalLibrary.Options[option.Flag] = option
				function option:AddColor(subOption : Dictionary) : Dictionary
					subOption = typeof(subOption) == "table" and subOption or {}
					subOption.Sub = true
					subOption.SubPosition = self.SubCount * 24
					function subOption:GetMain() return option.Main end
					self.SubCount = self.SubCount + 1
					return section:AddColor(subOption)
				end
				if option.Transparency then
					VitalLibrary.Flags[option.Flag .. " Transparency"] = option.Transparency
				end
				if VitalLibrary.HasInit and self.HasInit then
					VitalLibrary.CreateColor(option, self.Content)
				else
					option.Init = VitalLibrary.CreateColor
				end
				return option
			end
			function section:SetTitle(newTitle : string)
				self.Title = tostring(newTitle)
				if self.TitleText then
					self.TitleText.Text = tostring(newTitle)
				end
			end
			function section:Init()
				if self.HasInit then 
					return 
				end
				self.HasInit = true
				self.Main = VitalLibrary:Create("Frame", {
					BackgroundColor3 = Color3.fromRGB(30, 30, 30),
					BorderColor3 = Color3.new(0, 0, 0),
					Parent = column.Main
				}, false)
				self.Content = VitalLibrary:Create("Frame", {
					Size = UDim2.new(1, 0, 1, 0),
					BackgroundColor3 = Color3.fromRGB(30, 30, 30),
					BorderColor3 = Color3.fromRGB(60, 60, 60),
					BorderMode = Enum.BorderMode.Inset,
					Parent = self.Main
				}, false)
				VitalLibrary:Create("ImageLabel", {
					Size = UDim2.new(1, -2, 1, -2),
					Position = UDim2.new(0, 1, 0, 1),
					BackgroundTransparency = 1,
					Image = "rbxassetid://2592362371",
					ImageColor3 = Color3.new(0, 0, 0),
					ScaleType = Enum.ScaleType.Slice,
					SliceCenter = Rect.new(2, 2, 62, 62),
					Parent = self.Main
				}, false)
				table.insert(VitalLibrary.Theme, VitalLibrary:Create("Frame", {
					Size = UDim2.new(1, 0, 0, 1),
					BackgroundColor3 = VitalLibrary.Flags["Menu Accent Color"] or Color3.fromRGB(255, 255, 255),
					BorderSizePixel = 0,
					BorderMode = Enum.BorderMode.Inset,
					Parent = self.Main
				}, false))
				local layout = VitalLibrary:Create("UIListLayout", {
					HorizontalAlignment = Enum.HorizontalAlignment.Center,
					SortOrder = Enum.SortOrder.LayoutOrder,
					Padding = UDim.new(0, 2),
					Parent = self.Content
				}, false)
				VitalLibrary:Create("UIPadding", {
					PaddingTop = UDim.new(0, 12),
					Parent = self.Content
				}, false)
				self.TitleText = VitalLibrary:Create("TextLabel", {
					AnchorPoint = Vector2.new(0, 0.5),
					Position = UDim2.new(0, 12, 0, 0),
					Size = UDim2.new(0, TextService:GetTextSize(self.Title, 15, Enum.Font.Code, Vector2.new(math.huge, math.huge)).X + 10, 0, 3),
					BackgroundColor3 = Color3.fromRGB(30, 30, 30),
					BorderSizePixel = 0,
					Text = self.Title,
					TextSize = 15,
					Font = Enum.Font.Code,
					TextColor3 = Color3.new(1, 1, 1),
					Parent = self.Main
				}, false)
				layout.Changed:Connect(function()
					self.Main.Size = UDim2.new(1, 0, 0, layout.AbsoluteContentSize.Y + 16)
				end)
				for index, option in self.Options do
					if option.CanInit then
						option.Init(option, self.Content)
					end
				end
			end
			if VitalLibrary.HasInit and self.HasInit then
				section:Init()
			end
			return section
		end
		function column:Init()
			if self.HasInit then
				return 
			end
			self.HasInit = true
			self.Main = VitalLibrary:Create("ScrollingFrame", {
				ZIndex = 2,
				Position = UDim2.new(0, 6 + (self.Position * 239), 0, 2),
				Size = UDim2.new(0, 233, 1, -4),
				BackgroundTransparency = 1,
				BorderSizePixel = 0,
				ScrollBarImageColor3 = Color3.fromRGB(),
				ScrollBarThickness = 4,	
				VerticalScrollBarInset = Enum.ScrollBarInset.ScrollBar,
				ScrollingDirection = Enum.ScrollingDirection.Y,
				Visible = false,
				Parent = VitalLibrary.ColumnHolder
			}, false)
			local layout = VitalLibrary:Create("UIListLayout", {
				HorizontalAlignment = Enum.HorizontalAlignment.Center,
				SortOrder = Enum.SortOrder.LayoutOrder,
				Padding = UDim.new(0, 12),
				Parent = self.Main
			}, false)
			VitalLibrary:Create("UIPadding", {
				PaddingTop = UDim.new(0, 8),
				PaddingLeft = UDim.new(0, 2),
				PaddingRight = UDim.new(0, 2),
				Parent = self.Main
			}, false)
			layout.Changed:Connect(function()
				self.Main.CanvasSize = UDim2.new(0, 0, 0, layout.AbsoluteContentSize.Y + 14)
			end)
			for index, section in self.Sections do
				if section.CanInit and #section.Options > 0 then
					section:Init()
				end
			end
		end
		if VitalLibrary.HasInit and self.HasInit then
			column:Init()
		end
		return column
	end
	function tab:Init()
		if self.HasInit then
			return 
		end
		self.HasInit = true
		local size = TextService:GetTextSize(self.Title, 18, Enum.Font.Code, Vector2.new(math.huge, math.huge)).X + 10
		self.Button = VitalLibrary:Create("TextLabel", {
			Position = UDim2.new(0, VitalLibrary.TabSize, 0, 22),
			Size = UDim2.new(0, size, 0, 30),
			BackgroundTransparency = 1,
			Text = self.Title,
			TextColor3 = Color3.new(1, 1, 1),
			TextSize = 15,
			Font = Enum.Font.Code,
			TextWrapped = true,
			ClipsDescendants = true,
			Parent = VitalLibrary.Main
		}, false)
		VitalLibrary.TabSize = VitalLibrary.TabSize + size
		self.Button.InputBegan:Connect(function(input)
			if input.UserInputType.Name == "MouseButton1" then
				VitalLibrary:SelectTab(self)
			end
		end)
		for index, column in self.Columns do
			if column.CanInit then
				column:Init()
			end
		end
	end
	if self.HasInit then
		tab:Init()
	end
	return tab
end

function VitalLibrary:AddWarning(warning : Dictionary)
	warning = typeof(warning) == "table" and warning or {}
	warning.Text = tostring(warning.Text) 
	warning.Type = warning.Type == "Confirm" and "Confirm" or ""
	local answer = nil
	function warning:Show()
		VitalLibrary.Warning = warning
		if warning.Main and warning.Type == "" then return end
		if VitalLibrary.Popup then VitalLibrary.Popup:Close() end
		if not warning.Main then
			warning.Main = VitalLibrary:Create("TextButton", {
				ZIndex = 2,
				Size = UDim2.new(1, 0, 1, 0),
				BackgroundTransparency = 0.6,
				BackgroundColor3 = Color3.new(0, 0, 0),
				BorderSizePixel = 0,
				Text = "",
				AutoButtonColor = false,
				Parent = VitalLibrary.Main
			}, false)
			warning.Message = VitalLibrary:Create("TextLabel", {
				ZIndex = 2,
				Position = UDim2.new(0, 20, 0.5, -60),
				Size = UDim2.new(1, -40, 0, 40),
				BackgroundTransparency = 1,
				TextSize = 16,
				Font = Enum.Font.Code,
				TextColor3 = Color3.new(1, 1, 1),
				TextWrapped = true,
				RichText = true,
				Parent = warning.Main
			}, false)
			if warning.Type == "Confirm" then
				local yesButton = VitalLibrary:Create("TextLabel", {
					ZIndex = 2,
					Position = UDim2.new(0.5, -105, 0.5, -10),
					Size = UDim2.new(0, 100, 0, 20),
					BackgroundColor3 = Color3.fromRGB(40, 40, 40),
					BorderColor3 = Color3.new(0, 0, 0),
					Text = "Yes",
					TextSize = 16,
					Font = Enum.Font.Code,
					TextColor3 = Color3.new(1, 1, 1),
					Parent = warning.Main
				}, false)
				VitalLibrary:Create("ImageLabel", {
					ZIndex = 2,
					Size = UDim2.new(1, 0, 1, 0),
					BackgroundTransparency = 1,
					Image = "rbxassetid://2454009026",
					ImageColor3 = Color3.new(0, 0, 0),
					ImageTransparency = 0.8,
					Parent = yesButton
				}, false)
				VitalLibrary:Create("ImageLabel", {
					ZIndex = 2,
					Size = UDim2.new(1, 0, 1, 0),
					BackgroundTransparency = 1,
					Image = "rbxassetid://2592362371",
					ImageColor3 = Color3.fromRGB(60, 60, 60),
					ScaleType = Enum.ScaleType.Slice,
					SliceCenter = Rect.new(2, 2, 62, 62),
					Parent = yesButton
				}, false)
				local noButton = VitalLibrary:Create("TextLabel", {
					ZIndex = 2,
					Position = UDim2.new(0.5, 5, 0.5, -10),
					Size = UDim2.new(0, 100, 0, 20),
					BackgroundColor3 = Color3.fromRGB(40, 40, 40),
					BorderColor3 = Color3.new(0, 0, 0),
					Text = "No",
					TextSize = 16,
					Font = Enum.Font.Code,
					TextColor3 = Color3.new(1, 1, 1),
					Parent = warning.Main
				}, false)
				VitalLibrary:Create("ImageLabel", {
					ZIndex = 2,
					Size = UDim2.new(1, 0, 1, 0),
					BackgroundTransparency = 1,
					Image = "rbxassetid://2454009026",
					ImageColor3 = Color3.new(0, 0, 0),
					ImageTransparency = 0.8,
					Parent = noButton
				}, false)
				VitalLibrary:Create("ImageLabel", {
					ZIndex = 2,
					Size = UDim2.new(1, 0, 1, 0),
					BackgroundTransparency = 1,
					Image = "rbxassetid://2592362371",
					ImageColor3 = Color3.fromRGB(60, 60, 60),
					ScaleType = Enum.ScaleType.Slice,
					SliceCenter = Rect.new(2, 2, 62, 62),
					Parent = noButton
				}, false)
				yesButton.InputBegan:Connect(function(input : InputObject)
					if input.UserInputType == Enum.UserInputType.MouseButton1 then
						answer = true
					end
				end)
				noButton.InputBegan:Connect(function(input : InputObject)
					if input.UserInputType == Enum.UserInputType.MouseButton1 then
						answer = false
					end
				end)
			else
				local okButton = VitalLibrary:Create("TextLabel", {
					ZIndex = 2,
					Position = UDim2.new(0.5, -50, 0.5, -10),
					Size = UDim2.new(0, 100, 0, 20),
					BackgroundColor3 = Color3.fromRGB(30, 30, 30),
					BorderColor3 = Color3.new(0, 0, 0),
					Text = "OK",
					TextSize = 16,
					Font = Enum.Font.Code,
					TextColor3 = Color3.new(1, 1, 1),
					Parent = warning.Main
				}, false)
				VitalLibrary:Create("ImageLabel", {
					ZIndex = 2,
					Size = UDim2.new(1, 0, 1, 0),
					BackgroundTransparency = 1,
					Image = "rbxassetid://2454009026",
					ImageColor3 = Color3.new(0, 0, 0),
					ImageTransparency = 0.8,
					Parent = okButton
				}, false)
				VitalLibrary:Create("ImageLabel", {
					ZIndex = 2,
					AnchorPoint = Vector2.new(0.5, 0.5),
					Position = UDim2.new(0.5, 0, 0.5, 0),
					Size = UDim2.new(1, -2, 1, -2),
					BackgroundTransparency = 1,
					Image = "rbxassetid://3570695787",
					ImageColor3 = Color3.fromRGB(50, 50, 50),
					Parent = okButton
				}, false)
				okButton.InputBegan:Connect(function(input : InputObject)
					if input.UserInputType == Enum.UserInputType.MouseButton1 then
						answer = true
					end
				end)
			end
		end
		warning.Main.Visible = true
		warning.Message.Text = warning.Text
		while answer == nil do
			task.wait()
		end
		task.spawn(warning.Close)
		VitalLibrary.Warning = nil
		return answer
	end
	function warning:Close()
		answer = nil
		if not warning.Main then
			return 
		end
		warning.Main.Visible = false
	end
	return warning
end

function VitalLibrary:Toggle()
	self.IsOpen = not self.IsOpen
	if self.Main then
		if self.Popup then
			self.Popup:Close()
		end
		self.Main.Visible = self.IsOpen
	end
end

function VitalLibrary:Init()
	if self.HasInit then
		return 
	end
	self.HasInit = true
	self.Base = VitalLibrary:Create("ScreenGui", {IgnoreGuiInset = true, ZIndexBehavior = Enum.ZIndexBehavior.Global}, true)
	if RunService:IsStudio() then
		self.Base.Parent = script.Parent.Parent
	else
		pcall(function() 
			self.Base.RobloxLocked = true 
		end)
		self.Base.Parent = CoreGui
	end
	self.Main = self:Create("ImageButton", {
		AutoButtonColor = false,
		Position = UDim2.new(0, 100, 0, 46),
		Size = UDim2.new(0, 500, 0, 600),
		BackgroundColor3 = Color3.fromRGB(20, 20, 20),
		BorderColor3 = Color3.new(0, 0, 0),
		ScaleType = Enum.ScaleType.Tile,
		Modal = true,
		Visible = false,
		Parent = self.Base
	}, false)
	self.Top = self:Create("Frame", {
		Size = UDim2.new(1, 0, 0, 50),
		BackgroundColor3 = Color3.fromRGB(30, 30, 30),
		BorderColor3 = Color3.new(0, 0, 0),
		Parent = self.Main
	}, false)
	self:Create("TextLabel", {
		Position = UDim2.new(0, 6, 0, -1),
		Size = UDim2.new(0, 0, 0, 20),
		BackgroundTransparency = 1,
		Text = tostring(self.Title),
		Font = Enum.Font.Code,
		TextSize = 18,
		TextColor3 = Color3.new(1, 1, 1),
		TextXAlignment = Enum.TextXAlignment.Left,
		Parent = self.Main
	}, false)
	table.insert(VitalLibrary.Theme, self:Create("Frame", {
		Size = UDim2.new(1, 0, 0, 1),
		Position = UDim2.new(0, 0, 0, 24),
		BackgroundColor3 = VitalLibrary.Flags["Menu Accent Color"] or Color3.fromRGB(255, 255, 255),
		BorderSizePixel = 0,
		Parent = self.Main
	}, false))
	VitalLibrary:Create("ImageLabel", {
		Size = UDim2.new(1, 0, 1, 0),
		BackgroundTransparency = 1,
		Image = "rbxassetid://2454009026",
		ImageColor3 = Color3.new(0, 0, 0),
		ImageTransparency = 0.4,
		Parent = self.Top
	}, false)
	self.TabHighlight = self:Create("Frame", {
		BackgroundColor3 = VitalLibrary.Flags["Menu Accent Color"] or Color3.fromRGB(255, 255, 255),
		BorderSizePixel = 0,
		Parent = self.Main
	}, false)
	table.insert(VitalLibrary.Theme, self.TabHighlight)
	self.ColumnHolder = self:Create("Frame", {
		Position = UDim2.new(0, 5, 0, 55),
		Size = UDim2.new(1, -10, 1, -60),
		BackgroundTransparency = 1,
		Parent = self.Main
	}, false)
	self.ToolTip = self:Create("TextLabel", {
		ZIndex = 2,
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		TextSize = 15,
		Font = Enum.Font.Code,
		TextColor3 = Color3.new(1, 1, 1),
		Visible = true,
		Parent = self.Base
	}, false)
	self:Create("Frame", {
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.new(0.5, 0, 0, 0),
		Size = UDim2.new(1, 10, 1, 0),
		Style = Enum.FrameStyle.RobloxRound,
		Parent = self.ToolTip
	}, false)
	self:Create("ImageLabel", {
		Size = UDim2.new(1, 0, 1, 0),
		BackgroundTransparency = 1,
		Image = "rbxassetid://2592362371",
		ImageColor3 = Color3.fromRGB(60, 60, 60),
		ScaleType = Enum.ScaleType.Slice,
		SliceCenter = Rect.new(2, 2, 62, 62),
		Parent = self.Main
	}, false)
	self:Create("ImageLabel", {
		Size = UDim2.new(1, -2, 1, -2),
		Position = UDim2.new(0, 1, 0, 1),
		BackgroundTransparency = 1,
		Image = "rbxassetid://2592362371",
		ImageColor3 = Color3.new(0, 0, 0),
		ScaleType = Enum.ScaleType.Slice,
		SliceCenter = Rect.new(2, 2, 62, 62),
		Parent = self.Main
	}, false)
	self.Top.InputBegan:Connect(function(input : InputObject)
		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			dragData.Dragging = true
			dragData.DragStart = input.Position
			dragData.DragObject = self.Main
			dragData.StartPosition = dragData.DragObject.Position
			if VitalLibrary.Popup then 
				VitalLibrary.Popup:Close() 
			end
		end
	end)
	self.Top.InputChanged:Connect(function(input : InputObject)
		if dragData.Dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
			dragData.DragInput = input
		end
	end)
	self.Top.InputEnded:Connect(function(input : InputObject)
		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			dragData.Dragging = false
		end
	end)
	function self:SelectTab(tab : Dictionary)
		if self.CurrentTab == tab then 
			return 
		end
		if VitalLibrary.Popup then 
			VitalLibrary.Popup:Close() 
		end
		if self.CurrentTab then
			self.CurrentTab.Button.TextColor3 = Color3.fromRGB(255, 255, 255)
			for index, column in self.CurrentTab.Columns do
				column.Main.Visible = false
			end
		end
		self.Main.Size = UDim2.new(0, 16 + ((table.maxn(tab.Columns) < 2 and 2 or table.maxn(tab.Columns)) * 239), 0, 600)
		self.CurrentTab = tab
		tab.Button.TextColor3 = VitalLibrary.Flags["Menu Accent Color"] or Color3.fromRGB(255, 255, 255)
		self.TabHighlight.Position = UDim2.new(0, tab.Button.Position.X.Offset, 0, 50)
		self.TabHighlight.Size = UDim2.new(0, tab.Button.AbsoluteSize.X, 0, -1)
		for index, column in tab.Columns do
			column.Main.Visible = true
		end
	end
	task.spawn(function()
		while VitalLibrary do
			if self.Options["Config List"] then		
				local configs = self:GetConfigs()
				for index, config in configs do
					if not table.find(self.Options["Config List"].Values, config, 1) then
						self.Options["Config List"]:AddValue(config)
					end
				end
				for index, config in self.Options["Config List"].Values do
					if not table.find(configs, config, 1) then
						self.Options["Config List"]:RemoveValue(config)
					end
				end
			end
			task.wait(1)
		end
	end)
	for index, tab in self.Tabs do
		if tab.CanInit then
			tab:Init()
			self:SelectTab(tab)
		end
	end
	self:AddConnection(UserInputService.InputEnded, function(input : InputObject, gameProcessedEvent : boolean)
		if input.UserInputType == Enum.UserInputType.MouseButton1 and self.Slider then
			self.Slider.Slider.BorderColor3 = Color3.new(0, 0, 0)
			self.Slider = nil
		end
	end)
	self:AddConnection(UserInputService.InputChanged, function(input : InputObject, gameProcessedEvent : boolean)
		if not self.IsOpen then 
			return 
		end
		if input.UserInputType == Enum.UserInputType.MouseMovement then
			if self.Slider then
				self.Slider:SetValue(self.Slider.Minimum + ((input.Position.X - self.Slider.Slider.AbsolutePosition.X) / self.Slider.Slider.AbsoluteSize.X) * (self.Slider.Maximum - self.Slider.Minimum))
			end
		end
		if input == dragData.DragInput and dragData.Dragging and VitalLibrary.Draggable then
			local delta = input.Position - dragData.DragStart
			local xPosition = (dragData.StartPosition.X.Offset + delta.X) < 0 and 0 or (dragData.StartPosition.X.Offset + delta.X) > dragData.DragObject.Parent.AbsoluteSize.X - dragData.DragObject.AbsoluteSize.X and dragData.DragObject.Parent.AbsoluteSize.X - dragData.DragObject.AbsoluteSize.X or dragData.StartPosition.X.Offset + delta.X
			local yPosition = (dragData.StartPosition.Y.Offset + delta.Y) < 0 and 0 or (dragData.StartPosition.Y.Offset + delta.Y) > dragData.DragObject.Parent.AbsoluteSize.Y - dragData.DragObject.AbsoluteSize.Y and dragData.DragObject.Parent.AbsoluteSize.Y - dragData.DragObject.AbsoluteSize.Y or dragData.StartPosition.Y.Offset + delta.Y
			dragData.DragObject.Position = UDim2.new(dragData.StartPosition.X.Scale, xPosition, dragData.StartPosition.Y.Scale, yPosition)
		end
	end)
	if not getgenv().Silent then
		task.delay(1, function() 
			self:Toggle() 
		end)
	end
end
