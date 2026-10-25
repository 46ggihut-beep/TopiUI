local TweenService = game:GetService("TweenService")
local UIS = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")

local Library = {
	Options = {},
	Unloaded = false,
	UseFluentFont = true,
	FontId = "rbxassetid://12187365364",
	NoiseId = "rbxassetid://9968344227",
	FlowDuration = 0.4,
}

local Connections = {}
local Registry = {} -- dung cho o tim kiem
local function Connect(signal, fn)
	local c = signal:Connect(fn)
	table.insert(Connections, c)
	return c
end

local function SafeDestroy(inst)
	if not inst then return end
	pcall(function()
		if typeof(inst) == "Instance" then
			inst:Destroy()
		elseif type(inst) == "table" and type(inst.Destroy) == "function" then
			inst:Destroy()
		end
	end)
end

----------------------------------------------------------------------
-- Config (save / load) - file: Topi/<TenNguoiChoi>-Topi.json
----------------------------------------------------------------------
Library.ConfigFolder = "Topi"
Library.ConfigSuffix = "-Topi.json"
Library.AutoSave = true
Library.Settings = {}
local SavePending = false

local function HasFS()
	return type(writefile) == "function" and type(readfile) == "function"
		and type(isfolder) == "function" and type(makefolder) == "function"
end

function Library:GetConfigPath()
	local name = "Player"
	pcall(function() name = Players.LocalPlayer.Name end)
	return self.ConfigFolder .. "/" .. name .. self.ConfigSuffix
end

-- Doc file config vao Library.Settings (khong dong vao UI, dung de lay gia tri mac dinh luc tao element)
function Library:LoadConfig()
	if not HasFS() then return self.Settings end
	local ok, data = pcall(function()
		local path = self:GetConfigPath()
		if type(isfile) == "function" and not isfile(path) then return nil end
		return HttpService:JSONDecode(readfile(path))
	end)
	if ok and type(data) == "table" then
		self.Settings = data
	end
	return self.Settings
end

-- Ghi toan bo gia tri hien tai cua cac option ra file
function Library:SaveConfig()
	SavePending = false
	if not HasFS() then return false end
	local data = {}
	for k, v in pairs(self.Settings) do data[tostring(k)] = v end
	for idx, o in pairs(self.Options) do
		if o.Value ~= nil then
			if o.Type == "Dropdown" and o.Multi then
				local list = {}
				local src = (o.ClickOrder and o.Order) or o.Values
				for _, v in ipairs(src) do
					if o.Value[v] then table.insert(list, v) end
				end
				data[tostring(idx)] = list
			else
				data[tostring(idx)] = o.Value
			end
		end
	end
	self.Settings = data
	local ok = pcall(function()
		if not isfolder(self.ConfigFolder) then makefolder(self.ConfigFolder) end
		writefile(self:GetConfigPath(), HttpService:JSONEncode(data))
	end)
	return ok
end

-- Doc lai file va ap len cac option dang co (kich callback)
function Library:ApplyConfig()
	self:LoadConfig()
	for idx, o in pairs(self.Options) do
		local v = self.Settings[tostring(idx)]
		if v ~= nil and o.SetValue then
			pcall(function()
				if o.Type == "Slider" then o:SetValue(v, false, true) else o:SetValue(v) end
			end)
		end
	end
end

function Library:DeleteConfig()
	self.Settings = {}
	if HasFS() and type(isfile) == "function" and type(delfile) == "function" then
		pcall(function()
			local path = self:GetConfigPath()
			if isfile(path) then delfile(path) end
		end)
	end
end

-- Gom nhieu thay doi lien tiep thanh 1 lan ghi file
function Library:_QueueSave()
	if SavePending or self.Unloaded or not self.AutoSave then return end
	SavePending = true
	task.delay(0.6, function()
		if SavePending and not Library.Unloaded then Library:SaveConfig() end
	end)
end

local function ConfigValue(idx)
	return Library.Settings[tostring(idx)]
end

Library:LoadConfig()

----------------------------------------------------------------------
-- Theme (Fluent Dark) - giu nguyen mau goc
----------------------------------------------------------------------
local Theme = {
	Accent = Color3.fromRGB(96, 205, 255),
	AcrylicBorder = Color3.fromRGB(90, 90, 90),
	GradientA = Color3.fromRGB(60, 60, 60),
	GradientB = Color3.fromRGB(40, 40, 40),
	TitleBarLine = Color3.fromRGB(75, 75, 75),
	Text = Color3.fromRGB(240, 240, 240),
	SubText = Color3.fromRGB(170, 170, 170),
	Element = Color3.fromRGB(120, 120, 120),
	ElementBorder = Color3.fromRGB(35, 35, 35),
	InElementBorder = Color3.fromRGB(90, 90, 90),
	ToggleOff = Color3.fromRGB(175, 175, 175),
	ToggleOn = Color3.fromRGB(0, 0, 0),
	ToggleStroke = Color3.fromRGB(167, 167, 167),
	SliderRail = Color3.fromRGB(120, 120, 120),
	Input = Color3.fromRGB(160, 160, 160),
	InputFocused = Color3.fromRGB(10, 10, 10),
	InputIndicator = Color3.fromRGB(150, 150, 150),
	DropdownHolder = Color3.fromRGB(45, 45, 45),
	DropdownBorder = Color3.fromRGB(35, 35, 35),
}

----------------------------------------------------------------------
-- Helpers
----------------------------------------------------------------------
local FontCache = {}
local function GetFont(weight)
	weight = weight or Enum.FontWeight.Regular
	if not FontCache[weight] then
		local f
		if Library.UseFluentFont then
			local ok, res = pcall(Font.new, Library.FontId, weight, Enum.FontStyle.Normal)
			if ok then f = res end
		end
		FontCache[weight] = f or Font.fromEnum(Enum.Font.GothamMedium)
	end
	return FontCache[weight]
end

local function Create(class, props, children)
	local inst = Instance.new(class)
	local parent
	for k, v in pairs(props or {}) do
		if k == "Parent" then parent = v else inst[k] = v end
	end
	for _, c in ipairs(children or {}) do c.Parent = inst end
	if parent then inst.Parent = parent end
	return inst
end

local function Corner(r) return Create("UICorner", { CornerRadius = UDim.new(0, r) }) end
local function Round() return Create("UICorner", { CornerRadius = UDim.new(1, 0) }) end
local function Stroke(color, thickness, transparency)
	return Create("UIStroke", {
		Color = color, Thickness = thickness or 1, Transparency = transparency or 0,
		ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
	})
end

local function Tween(inst, t, props)
	local tw = TweenService:Create(inst, TweenInfo.new(t, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), props)
	tw:Play()
	return tw
end

-- Tween voi style tuy chon (dung cho hieu ung "nay / dan hoi" kieu kinh long)
local function TweenS(inst, t, style, dir, props)
	local tw = TweenService:Create(inst, TweenInfo.new(t, style, dir), props)
	tw:Play()
	return tw
end

local function NewLabel(parent, text, size, weight, color, transparency, extra)
	local props = {
		Parent = parent, BackgroundTransparency = 1, BorderSizePixel = 0,
		Text = text or "", TextSize = size or 13, FontFace = GetFont(weight),
		TextColor3 = color or Theme.Text, TextTransparency = transparency or 0,
		TextXAlignment = Enum.TextXAlignment.Left, TextYAlignment = Enum.TextYAlignment.Center,
		TextWrapped = true, AutomaticSize = Enum.AutomaticSize.Y, Size = UDim2.new(1, 0, 0, 0),
	}
	for k, v in pairs(extra or {}) do props[k] = v end
	return Create("TextLabel", props)
end

local function DrawX(parent, len, color)
	for _, rot in ipairs({ 45, -45 }) do
		Create("Frame", {
			Parent = parent, AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5),
			Size = UDim2.fromOffset(len, 1), Rotation = rot, BackgroundColor3 = color or Theme.Text, BorderSizePixel = 0,
		})
	end
end

local function DrawMaximize(parent, size, color)
	Create("Frame", {
		Parent = parent, AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromOffset(size, size), BackgroundTransparency = 1, BorderSizePixel = 0,
	}, { Stroke(color or Theme.Text, 1.5, 0) })
end

local function DrawRestore(parent, size, color)
	Create("Frame", {
		Parent = parent, AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(0.5, 2, 0.5, -2),
		Size = UDim2.fromOffset(size, size), BackgroundTransparency = 1, BorderSizePixel = 0,
	}, { Stroke(color or Theme.Text, 1.5, 0.5) })
	Create("Frame", {
		Parent = parent, AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(0.5, -2, 0.5, 2),
		Size = UDim2.fromOffset(size, size), BackgroundTransparency = 1, BorderSizePixel = 0, ZIndex = 2,
	}, { Stroke(color or Theme.Text, 1.5, 0) })
end

local function DrawSearch(parent, color)
	Create("Frame", {
		Parent = parent, AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(0.5, -1.5, 0.5, -1.5),
		Size = UDim2.fromOffset(10, 10), BackgroundTransparency = 1, BorderSizePixel = 0,
	}, { Round(), Stroke(color or Theme.Text, 1.5, 0) })
	Create("Frame", {
		Parent = parent, AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(0.5, 4.5, 0.5, 4.5),
		Size = UDim2.fromOffset(6, 1.5), Rotation = 45, BackgroundColor3 = color or Theme.Text, BorderSizePixel = 0,
	})
end

local function GetGuiParent()
	local ok, h = pcall(function() return gethui and gethui() end)
	if ok and h then return h end
	local ok2 = pcall(function() return game:GetService("CoreGui"):GetChildren() end)
	if ok2 then return game:GetService("CoreGui") end
	return Players.LocalPlayer:WaitForChild("PlayerGui")
end

local Gui
local function GetGui()
	if Gui and Gui.Parent then return Gui end
	Gui = Create("ScreenGui", {
		Name = "TopiUI_" .. HttpService:GenerateGUID(false):sub(1, 8),
		ResetOnSpawn = false, IgnoreGuiInset = true,
		ZIndexBehavior = Enum.ZIndexBehavior.Sibling, DisplayOrder = 999,
	})
	Gui.Parent = GetGuiParent()
	return Gui
end

----------------------------------------------------------------------
-- Flow animation (UI <-> nut toggle, kieu giot nuoc hut vao / nha ra)
----------------------------------------------------------------------
local FlowAnim = {}
FlowAnim.__index = FlowAnim

-- Giot nuoc nho bay giua UI va toggle
local function Droplet(from, to, delay, dur, size, onArrive, fadeOut)
	task.delay(delay, function()
		if Library.Unloaded then return end
		local gui = GetGui()
		local d = Create("Frame", {
			Parent = gui, AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromOffset(from.X, from.Y), Size = UDim2.fromOffset(2, 2),
			BackgroundColor3 = Color3.new(1, 1, 1), BackgroundTransparency = 1, BorderSizePixel = 0, ZIndex = 140,
		}, { Round(), Stroke(Theme.Accent, 1.5, 1) })
		local st = d:FindFirstChildOfClass("UIStroke")
		TweenS(d, 0.14, Enum.EasingStyle.Back, Enum.EasingDirection.Out, {
			Size = UDim2.fromOffset(size, size), BackgroundTransparency = 0.7,
		})
		TweenS(st, 0.14, Enum.EasingStyle.Quad, Enum.EasingDirection.Out, { Transparency = 0.2 })
		task.delay(0.1, function()
			if not d.Parent then return end
			local goal = { Position = UDim2.fromOffset(to.X, to.Y) }
			if not fadeOut then goal.Size = UDim2.fromOffset(4, 4) end
			local t = TweenS(d, dur, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut, goal)
			t.Completed:Connect(function()
				if fadeOut and d.Parent then
					TweenS(d, 0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out, { BackgroundTransparency = 1 })
					TweenS(st, 0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out, { Transparency = 1 })
					task.delay(0.22, function() SafeDestroy(d) end)
				else
					SafeDestroy(d)
				end
				if onArrive then onArrive() end
			end)
		end)
	end)
end

function FlowAnim.new(window, toggleInst, toggleScale)
	return setmetatable({
		Window = window,
		Toggle = toggleInst,
		Scale = toggleScale,
		Playing = false,
	}, FlowAnim)
end

function FlowAnim:_TogglePos()
	local gui = GetGui()
	local tp = self.Toggle.AbsolutePosition
	local ts = self.Toggle.AbsoluteSize
	local gp = gui.AbsolutePosition
	return Vector2.new(tp.X + ts.X / 2 - gp.X, tp.Y + ts.Y / 2 - gp.Y), ts
end

-- Toggle phong len roi nay lai (giot nuoc nhap vao)
function FlowAnim:_Pulse(amount)
	local s = self.Scale
	if not s or not s.Parent then return end
	TweenS(s, 0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.Out, { Scale = amount })
	task.delay(0.12, function()
		if s.Parent then
			TweenS(s, 0.45, Enum.EasingStyle.Back, Enum.EasingDirection.Out, { Scale = 1 })
		end
	end)
end

-- Vong song lan ra tu toggle
function FlowAnim:_Ripple()
	-- [VA 2] khong tao GUI moi sau khi Unload
	if Library.Unloaded then return end
	local gui = GetGui()
	local c, ts = self:_TogglePos()
	local r = Create("Frame", {
		Parent = gui, AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromOffset(c.X, c.Y),
		Size = UDim2.fromOffset(ts.X, ts.X), BackgroundTransparency = 1, BorderSizePixel = 0, ZIndex = 99,
	}, { Round(), Stroke(Theme.Accent, 2, 0.1) })
	TweenS(r, 0.55, Enum.EasingStyle.Quint, Enum.EasingDirection.Out, { Size = UDim2.fromOffset(ts.X * 1.9, ts.X * 1.9) })
	TweenS(r:FindFirstChildOfClass("UIStroke"), 0.55, Enum.EasingStyle.Quad, Enum.EasingDirection.Out, { Transparency = 1 })
	task.delay(0.6, function() SafeDestroy(r) end)
end

function FlowAnim:Hide(onDone)
	if self.Playing then return end
	self.Playing = true

	local W = self.Window
	local main = W.Main
	local gui = GetGui()
	W._hideSize, W._hidePos = main.Size, main.Position

	local ms = main.AbsoluteSize
	local mp = main.AbsolutePosition - gui.AbsolutePosition
	local tc, ts = self:_TogglePos()
	local d = math.min(ts.X, ts.Y)
	local dur = Library.FlowDuration + 0.15

	-- cac giot nuoc bay vao toggle
	for i = 1, 3 do
		local from = Vector2.new(mp.X + ms.X * (0.2 + 0.6 * math.random()), mp.Y + ms.Y * (0.2 + 0.6 * math.random()))
		Droplet(from, tc, (i - 1) * 0.07, 0.42, math.random(14, 22), function() self:_Pulse(1.12) end, false)
	end

	task.delay(0.12, function()
		if Library.Unloaded or not main.Parent then
			self.Playing = false
			if onDone then onDone() end
			return
		end
		local info = TweenInfo.new(dur, Enum.EasingStyle.Back, Enum.EasingDirection.In)
		local t = TweenService:Create(main, info, {
			Size = UDim2.fromOffset(d, d),
			Position = UDim2.fromOffset(tc.X, tc.Y),
		})
		TweenService:Create(W._corner, info, { CornerRadius = UDim.new(0, d / 2) }):Play()
		TweenService:Create(main, TweenInfo.new(dur * 0.85, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
			GroupTransparency = 1,
		}):Play()
		t:Play()
		t.Completed:Connect(function()
			-- [VA 2] UI da bi Unload trong luc animation chay
			if Library.Unloaded then
				self.Playing = false
				return
			end
			if main.Parent then
				main.Visible = false
				main.Size = W._hideSize
				main.Position = W._hidePos
				W._corner.CornerRadius = UDim.new(0, 8)
			end
			self:_Ripple()
			self:_Pulse(1.28)
			task.delay(0.2, function()
				self.Playing = false
				if onDone then onDone() end
			end)
		end)
	end)
end

function FlowAnim:Show(onDone)
	if self.Playing then return end
	self.Playing = true

	local W = self.Window
	local main = W.Main
	local gui = GetGui()
	local tc, ts = self:_TogglePos()
	local d = math.min(ts.X, ts.Y)
	local size = W._hideSize or main.Size
	local pos = W._hidePos or main.Position
	local ga = gui.AbsoluteSize
	local center = Vector2.new(pos.X.Scale * ga.X + pos.X.Offset, pos.Y.Scale * ga.Y + pos.Y.Offset)
	local dur = Library.FlowDuration + 0.2

	main.Size = UDim2.fromOffset(d, d)
	main.Position = UDim2.fromOffset(tc.X, tc.Y)
	main.GroupTransparency = 1
	W._corner.CornerRadius = UDim.new(0, d / 2)
	main.Visible = true

	self:_Pulse(1.22)
	self:_Ripple()

	-- giot nuoc bay ra tu toggle
	local sx = size.X.Offset > 0 and size.X.Offset or 580
	local sy = size.Y.Offset > 0 and size.Y.Offset or 460
	for i = 1, 3 do
		local to = Vector2.new(center.X + (math.random() - 0.5) * sx * 0.6, center.Y + (math.random() - 0.5) * sy * 0.6)
		Droplet(tc, to, (i - 1) * 0.06, 0.4, math.random(12, 20), nil, true)
	end

	task.delay(0.1, function()
		if Library.Unloaded or not main.Parent then
			self.Playing = false
			return
		end
		local info = TweenInfo.new(dur, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
		local t = TweenService:Create(main, info, { Size = size, Position = pos })
		TweenService:Create(W._corner, info, { CornerRadius = UDim.new(0, 8) }):Play()
		TweenService:Create(main, TweenInfo.new(dur * 0.6, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
			GroupTransparency = 0,
		}):Play()
		t:Play()
		t.Completed:Connect(function()
			self.Playing = false
			if onDone then onDone() end
		end)
	end)
end

----------------------------------------------------------------------
-- Option object
----------------------------------------------------------------------
local function NewOption(kind, cfg)
	local o = { Type = kind, Callback = cfg.Callback, Changed = {} }
	function o:OnChanged(fn) table.insert(self.Changed, fn) end
	return o
end

local function Fire(o, ...)
	if o.Callback then task.spawn(o.Callback, ...) end
	for _, f in ipairs(o.Changed) do task.spawn(f, ...) end
	if o.Idx ~= nil then Library:_QueueSave() end
end

----------------------------------------------------------------------
-- Element base
----------------------------------------------------------------------
-- Thu tu hien thi co dinh cho moi container (de co the nhac element ra / tra lai dung cho khi tim kiem)
local function NextOrder(parent)
	local n = (parent:GetAttribute("_n") or 0) + 1
	parent:SetAttribute("_n", n)
	return n
end

-- Tim ten + so thu tu cua tab chua element nay
local function TabInfo(inst)
	local p = inst
	while p do
		local t = p:GetAttribute("TabTitle")
		if t then return t, p:GetAttribute("TabIndex") or 0 end
		p = p.Parent
	end
	return "", 0
end

local function Element(parent, title, desc, rightW, icon)
	local order = NextOrder(parent)
	local el = Create("Frame", {
		Parent = parent, Size = UDim2.new(1, 0, 0, 34), AutomaticSize = Enum.AutomaticSize.Y, LayoutOrder = order,
		BackgroundColor3 = Theme.Element, BackgroundTransparency = 0.87, BorderSizePixel = 0,
	}, { Corner(6), Stroke(Theme.ElementBorder, 1, 0.5) })

	local leftPad = 12
	if icon and icon ~= "" then
		if tonumber(icon) then icon = "rbxassetid://" .. icon end
		Create("ImageLabel", {
			Parent = el, AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.new(0, 12, 0.5, 0),
			Size = UDim2.fromOffset(18, 18), BackgroundTransparency = 1, Image = icon, ImageColor3 = Theme.Text,
		})
		leftPad = 42
	end

	local holder = Create("Frame", {
		Parent = el, Position = UDim2.fromOffset(leftPad, 0),
		Size = UDim2.new(1, -(leftPad + 12 + (rightW or 0)), 0, 0), AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundTransparency = 1,
	}, {
		Create("UIListLayout", { SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 2) }),
		Create("UIPadding", { PaddingTop = UDim.new(0, 10), PaddingBottom = UDim.new(0, 10) }),
	})
	local titleLbl = NewLabel(holder, title or "", 13, Enum.FontWeight.Regular, Theme.Text, 0, { LayoutOrder = 1 })
	local descLbl = NewLabel(holder, desc or "", 11, Enum.FontWeight.Regular, Theme.Text, 0.4, {
		LayoutOrder = 2, Visible = (desc ~= nil and desc ~= ""),
	})
	local tabTitle, tabIdx = TabInfo(parent)
	table.insert(Registry, {
		el = el, parent = parent, order = order,
		title = title or "", desc = desc or "",
		tabTitle = tabTitle, tabIdx = tabIdx, idx = #Registry + 1,
	})
	return el, titleLbl, descLbl, holder
end

local function HitOverlay(el, onClick, onDown, onUp, onLeave)
	local hit = Create("TextButton", {
		Parent = el, Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Text = "",
		AutoButtonColor = false, BorderSizePixel = 0, ZIndex = 10,
	})
	Connect(hit.MouseEnter, function() Tween(el, 0.1, { BackgroundTransparency = 0.83 }) end)
	Connect(hit.MouseLeave, function()
		Tween(el, 0.1, { BackgroundTransparency = 0.87 })
		if onLeave then onLeave() end
	end)
	Connect(hit.MouseButton1Down, function()
		Tween(el, 0.1, { BackgroundTransparency = 0.9 })
		if onDown then onDown() end
	end)
	Connect(hit.MouseButton1Up, function()
		Tween(el, 0.1, { BackgroundTransparency = 0.83 })
		if onUp then onUp() end
	end)
	Connect(hit.MouseButton1Click, onClick)
	return hit
end

----------------------------------------------------------------------
-- Elements mixin
----------------------------------------------------------------------
local Elements = {}
Elements.__index = Elements

function Elements:AddParagraph(cfg)
	local el, t, d = Element(self.Container, cfg.Title, cfg.Content or "", 0, cfg.Icon)
	d.Visible = true
	d.TextTransparency = 0.3
	local P = {}
	function P:SetTitle(v) t.Text = v end
	function P:SetDesc(v) d.Text = v end
	return P
end

-- BUTTON: vong vien "kinh" hien ra khi nhan giu, xung vong lan ra khi click
function Elements:AddButton(cfg)
	local el = Element(self.Container, cfg.Title, cfg.Description, 0, cfg.Icon)
	local hold = Create("Frame", {
		Parent = el, AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.new(1, -8, 1, -8), BackgroundTransparency = 1, BorderSizePixel = 0, ZIndex = 5,
	}, { Corner(6), Stroke(Theme.Accent, 2, 1) })
	local holdStroke = hold:FindFirstChildOfClass("UIStroke")

	local function Release()
		TweenS(hold, 0.3, Enum.EasingStyle.Quint, Enum.EasingDirection.Out, { Size = UDim2.new(1, -8, 1, -8) })
		TweenS(holdStroke, 0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out, { Transparency = 1 })
	end

	HitOverlay(el, function()
		local r = Create("Frame", {
			Parent = el, AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5),
			Size = UDim2.new(1, -12, 1, -12), BackgroundTransparency = 1, BorderSizePixel = 0, ZIndex = 5,
		}, { Corner(6), Stroke(Theme.Accent, 2, 0.1) })
		TweenS(r, 0.5, Enum.EasingStyle.Quint, Enum.EasingDirection.Out, { Size = UDim2.new(1, -4, 1, -4) })
		TweenS(r:FindFirstChildOfClass("UIStroke"), 0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out, { Transparency = 1 })
		task.delay(0.55, function() SafeDestroy(r) end)
		if cfg.Callback then task.spawn(cfg.Callback) end
	end, function()
		TweenS(hold, 0.25, Enum.EasingStyle.Quint, Enum.EasingDirection.Out, { Size = UDim2.new(1, -4, 1, -4) })
		TweenS(holdStroke, 0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out, { Transparency = 0.35 })
	end, Release, Release)
	return {}
end

-- TOGGLE: nut tron keo dai ra (pill) khi nhan, bat nay sang vi tri moi
function Elements:AddToggle(idx, cfg)
	local T = NewOption("Toggle", cfg)
	T.Value = false
	local el = Element(self.Container, cfg.Title, cfg.Description, 56, cfg.Icon)
	local track = Create("Frame", {
		Parent = el, AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -12, 0.5, 0),
		Size = UDim2.fromOffset(40, 20), BackgroundColor3 = Theme.Accent, BackgroundTransparency = 1, BorderSizePixel = 0,
	}, { Round() })
	local stroke = Stroke(Theme.ToggleStroke, 1, 0)
	stroke.Parent = track
	local knob = Create("Frame", {
		Parent = track, AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.new(0, 4, 0.5, 0),
		Size = UDim2.fromOffset(12, 12), BackgroundColor3 = Theme.ToggleOff, BorderSizePixel = 0,
	}, { Round() })

	local function Visual(instant)
		local on = T.Value
		local x = on and 24 or 4
		local col = on and Theme.ToggleOn or Theme.ToggleOff
		if instant then
			track.BackgroundTransparency = on and 0 or 1
			stroke.Color = on and Theme.Accent or Theme.ToggleStroke
			knob.Position = UDim2.new(0, x, 0.5, 0)
			knob.Size = UDim2.fromOffset(12, 12)
			knob.BackgroundColor3 = col
			return
		end
		Tween(track, 0.2, { BackgroundTransparency = on and 0 or 1 })
		Tween(stroke, 0.2, { Color = on and Theme.Accent or Theme.ToggleStroke })
		-- keo dai khi truot, sau do co lai (dan hoi)
		TweenS(knob, 0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.Out, { Size = UDim2.fromOffset(17, 14) })
		TweenS(knob, 0.4, Enum.EasingStyle.Back, Enum.EasingDirection.Out, {
			Position = UDim2.new(0, x, 0.5, 0), BackgroundColor3 = col,
		})
		task.delay(0.12, function()
			if knob.Parent then
				TweenS(knob, 0.35, Enum.EasingStyle.Back, Enum.EasingDirection.Out, { Size = UDim2.fromOffset(12, 12) })
			end
		end)
	end

	function T:SetValue(v, force)
		v = v and true or false
		if v == self.Value and not force then return end
		self.Value = v
		Visual(force == true and not T._ready)
		Fire(self, v)
	end

	local function Rest()
		TweenS(knob, 0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out, {
			Size = UDim2.fromOffset(12, 12), Position = UDim2.new(0, T.Value and 24 or 4, 0.5, 0),
		})
	end

	HitOverlay(el, function() T:SetValue(not T.Value) end, function()
		-- nhan giu: nut phinh to ra thanh pill
		TweenS(knob, 0.2, Enum.EasingStyle.Back, Enum.EasingDirection.Out, {
			Size = UDim2.fromOffset(18, 14), Position = UDim2.new(0, T.Value and 18 or 4, 0.5, 0),
		})
	end, nil, Rest)

	local saved = ConfigValue(idx)
	if type(saved) ~= "boolean" then saved = cfg.Default or false end
	T:SetValue(saved, true)
	T._ready = true
	T.Idx = idx
	Library.Options[idx] = T
	return T
end

-- SLIDER: nut to len + vong sang khi keo, thanh fill chay muot
function Elements:AddSlider(idx, cfg)
	local S = NewOption("Slider", cfg)
	S.Min, S.Max, S.Rounding = cfg.Min or 0, cfg.Max or 100, cfg.Rounding or 0
	S.Value = S.Min
	local suffix = cfg.Suffix or ""
	local el, _, _, holder = Element(self.Container, cfg.Title, cfg.Description, 0, cfg.Icon)

	local row = Create("Frame", {
		Parent = holder, LayoutOrder = 3, Size = UDim2.new(1, 0, 0, 24), BackgroundTransparency = 1,
	})
	local editing = false
	-- O so: bam vao de nhap gia tri tuy chon
	local valLbl = Create("TextBox", {
		Parent = row, AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, 0, 0.5, 0),
		Size = UDim2.new(0, 52, 0, 22), BackgroundColor3 = Theme.Input, BackgroundTransparency = 1,
		BorderSizePixel = 0, Text = "", ClearTextOnFocus = false, TextSize = 12, FontFace = GetFont(),
		TextColor3 = Theme.Text, TextTransparency = 0.2, TextXAlignment = Enum.TextXAlignment.Center,
		ClipsDescendants = true,
	}, { Corner(5), Stroke(Theme.Accent, 1, 1) })
	local valStroke = valLbl:FindFirstChildOfClass("UIStroke")
	local rail = Create("Frame", {
		Parent = row, Size = UDim2.new(1, -58, 1, 0), BackgroundTransparency = 1,
	})
	local line = Create("Frame", {
		Parent = rail, AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.new(1, -10, 0, 2), BackgroundColor3 = Theme.SliderRail, BorderSizePixel = 0,
	}, { Round() })
	local fill = Create("Frame", {
		Parent = line, Size = UDim2.new(0, 0, 1, 0), BackgroundColor3 = Theme.Accent, BorderSizePixel = 0,
	}, { Round() })
	local dot = Create("Frame", {
		Parent = rail, AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(0, 5, 0.5, 0),
		Size = UDim2.fromOffset(10, 10), BackgroundColor3 = Theme.Accent, BorderSizePixel = 0,
	}, { Round(), Stroke(Theme.Accent, 4, 1) })
	local dotStroke = dot:FindFirstChildOfClass("UIStroke")

	local function Rnd(n)
		local m = 10 ^ S.Rounding
		return math.floor(n * m + 0.5) / m
	end
	function S:SetValue(v, force, smooth)
		v = Rnd(math.clamp(tonumber(v) or S.Min, S.Min, S.Max))
		local changed = v ~= self.Value
		self.Value = v
		local frac = (S.Max == S.Min) and 0 or (v - S.Min) / (S.Max - S.Min)
		if not editing then valLbl.Text = tostring(v) .. suffix end
		local dp = UDim2.new(frac, 5 - 10 * frac, 0.5, 0)
		local fs = UDim2.new(frac, 0, 1, 0)
		if smooth then
			TweenS(dot, 0.08, Enum.EasingStyle.Quad, Enum.EasingDirection.Out, { Position = dp })
			TweenS(fill, 0.08, Enum.EasingStyle.Quad, Enum.EasingDirection.Out, { Size = fs })
		else
			dot.Position = dp
			fill.Size = fs
		end
		if changed or force then Fire(self, v) end
	end

	do
		local valHover = false
		Connect(valLbl.MouseEnter, function()
			valHover = true
			if not editing then Tween(valLbl, 0.15, { BackgroundTransparency = 0.9 }) end
		end)
		Connect(valLbl.MouseLeave, function()
			valHover = false
			if not editing then Tween(valLbl, 0.15, { BackgroundTransparency = 1 }) end
		end)
		Connect(valLbl.Focused, function()
			editing = true
			valLbl.Text = tostring(S.Value)
			Tween(valLbl, 0.15, { BackgroundTransparency = 0.5, BackgroundColor3 = Theme.InputFocused, TextTransparency = 0 })
			TweenS(valStroke, 0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out, { Transparency = 0.2 })
		end)
		Connect(valLbl.FocusLost, function()
			editing = false
			local n = tonumber(valLbl.Text)
			if n then
				S:SetValue(n, false, true)
			end
			valLbl.Text = tostring(S.Value) .. suffix
			Tween(valLbl, 0.15, { BackgroundTransparency = valHover and 0.9 or 1, BackgroundColor3 = Theme.Input, TextTransparency = 0.2 })
			TweenS(valStroke, 0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out, { Transparency = 1 })
		end)
		Connect(valLbl:GetPropertyChangedSignal("Text"), function()
			if not editing then return end
			local clean = valLbl.Text:gsub("[^%d%.%-]", "")
			if clean ~= valLbl.Text then valLbl.Text = clean end
		end)
	end

	local dragging, hovering = false, false
	local function Grow(on)
		if on then
			TweenS(dot, 0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out, { Size = UDim2.fromOffset(16, 16) })
			TweenS(dotStroke, 0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out, { Transparency = 0.65 })
		else
			local s = hovering and 12 or 10
			TweenS(dot, 0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out, { Size = UDim2.fromOffset(s, s) })
			TweenS(dotStroke, 0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out, { Transparency = 1 })
		end
	end
	local function FromX(x)
		local w = rail.AbsoluteSize.X - 10
		if w <= 0 then return end
		local frac = math.clamp((x - rail.AbsolutePosition.X - 5) / w, 0, 1)
		S:SetValue(S.Min + (S.Max - S.Min) * frac, false, true)
	end
	Connect(rail.MouseEnter, function()
		hovering = true
		if not dragging then Grow(false) end
	end)
	Connect(rail.MouseLeave, function()
		hovering = false
		if not dragging then Grow(false) end
	end)
	Connect(rail.InputBegan, function(i)
		if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
			dragging = true
			Grow(true)
			FromX(i.Position.X)
		end
	end)
	Connect(UIS.InputChanged, function(i)
		if dragging and (i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.Touch) then
			FromX(i.Position.X)
		end
	end)
	Connect(UIS.InputEnded, function(i)
		if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
			if dragging then
				dragging = false
				Grow(false)
			end
		end
	end)
	local saved = ConfigValue(idx)
	if type(saved) ~= "number" then saved = cfg.Default or S.Min end
	S:SetValue(saved, true)
	S.Idx = idx
	Library.Options[idx] = S
	return S
end

-- INPUT: vong sang mo rong ra khi focus, gach duoi chay tu giua
function Elements:AddInput(idx, cfg)
	local I = NewOption("Input", cfg)
	local saved = ConfigValue(idx)
	I.Value = (saved ~= nil) and tostring(saved) or (cfg.Default or "")
	local el = Element(self.Container, cfg.Title, cfg.Description, 176, cfg.Icon)
	local box = Create("Frame", {
		Parent = el, AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -12, 0.5, 0),
		Size = UDim2.fromOffset(160, 26), BackgroundColor3 = Theme.Input, BackgroundTransparency = 0.9, BorderSizePixel = 0,
	}, { Corner(5), Stroke(Theme.InElementBorder, 1, 0.5) })
	local boxStroke = box:FindFirstChildOfClass("UIStroke")
	local ring = Create("Frame", {
		Parent = box, AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.new(1, -4, 1, -4), BackgroundTransparency = 1, BorderSizePixel = 0,
	}, { Corner(8), Stroke(Theme.Accent, 2, 1) })
	local ringStroke = ring:FindFirstChildOfClass("UIStroke")
	local tb = Create("TextBox", {
		Parent = box, Position = UDim2.fromOffset(8, 0), Size = UDim2.new(1, -16, 1, 0), BackgroundTransparency = 1,
		ClearTextOnFocus = false, Text = I.Value, PlaceholderText = cfg.Placeholder or "",
		PlaceholderColor3 = Color3.fromRGB(140, 140, 140), TextColor3 = Theme.Text, TextSize = 12,
		FontFace = GetFont(), TextXAlignment = Enum.TextXAlignment.Left, ClipsDescendants = true,
	})
	local indicator = Create("Frame", {
		Parent = box, AnchorPoint = Vector2.new(0.5, 1), Position = UDim2.new(0.5, 0, 1, 0),
		Size = UDim2.new(1, -8, 0, 1), BackgroundColor3 = Theme.InputIndicator, BorderSizePixel = 0,
	})
	Connect(tb.Focused, function()
		Tween(box, 0.2, { BackgroundColor3 = Theme.InputFocused, BackgroundTransparency = 0.5 })
		Tween(boxStroke, 0.2, { Color = Theme.Accent, Transparency = 0.2 })
		TweenS(ring, 0.35, Enum.EasingStyle.Back, Enum.EasingDirection.Out, { Size = UDim2.new(1, 8, 1, 8) })
		TweenS(ringStroke, 0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out, { Transparency = 0.5 })
		indicator.BackgroundColor3 = Theme.Accent
		indicator.Size = UDim2.new(0, 0, 0, 2)
		Tween(indicator, 0.3, { Size = UDim2.new(1, -8, 0, 2) })
	end)
	Connect(tb.FocusLost, function()
		Tween(box, 0.2, { BackgroundColor3 = Theme.Input, BackgroundTransparency = 0.9 })
		Tween(boxStroke, 0.2, { Color = Theme.InElementBorder, Transparency = 0.5 })
		TweenS(ring, 0.25, Enum.EasingStyle.Quint, Enum.EasingDirection.Out, { Size = UDim2.new(1, -4, 1, -4) })
		TweenS(ringStroke, 0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out, { Transparency = 1 })
		Tween(indicator, 0.25, { Size = UDim2.new(1, -8, 0, 1), BackgroundColor3 = Theme.InputIndicator })
		I.Value = tb.Text
		if cfg.Finished then Fire(I, I.Value) end
	end)
	Connect(tb:GetPropertyChangedSignal("Text"), function()
		if cfg.Numeric then
			local clean = tb.Text:gsub("[^%d%.%-]", "")
			if clean ~= tb.Text then tb.Text = clean return end
		end
		I.Value = tb.Text
		if not cfg.Finished then Fire(I, I.Value) end
	end)
	function I:SetValue(v) tb.Text = tostring(v) end
	if saved ~= nil then Fire(I, I.Value) end
	I.Idx = idx
	Library.Options[idx] = I
	return I
end

-- DROPDOWN: danh sach bung xuong, muc truot vao lan luot, mui ten xoay
function Elements:AddDropdown(idx, cfg)
	local D = NewOption("Dropdown", cfg)
	D.Values = cfg.Values or {}
	D.Multi = cfg.Multi and true or false
	D.Value = D.Multi and {} or nil
	-- ClickOrder (chi Multi): true = phan gioi thieu (Description) cua dropdown hien item da chon theo luot: item 1 -> item 2 -> ...; false = nhu cu
	D.ClickOrder = (D.Multi and cfg.ClickOrder) and true or false
	D.Order = {}
	local function SyncOrder(arr)
		local order, seen = {}, {}
		local function add(v)
			if D.Value[v] and not seen[v] then
				seen[v] = true
				table.insert(order, v)
			end
		end
		if arr and #arr > 0 then
			for _, v in ipairs(arr) do add(v) end
		else
			for _, v in ipairs(D.Order) do add(v) end
		end
		for _, v in ipairs(D.Values) do add(v) end
		D.Order = order
	end
	local el, _, descLbl = Element(self.Container, cfg.Title, cfg.Description, 136, cfg.Icon)
	local baseDesc = cfg.Description or ""
	local box = Create("Frame", {
		Parent = el, AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -12, 0.5, 0),
		Size = UDim2.fromOffset(120, 26), BackgroundColor3 = Theme.Input, BackgroundTransparency = 0.9, BorderSizePixel = 0,
	}, { Corner(5), Stroke(Theme.InElementBorder, 1, 0.5) })
	local text = NewLabel(box, "--", 12, Enum.FontWeight.Regular, Theme.Text, 0, {
		Position = UDim2.fromOffset(8, 0), Size = UDim2.new(1, -26, 1, 0), AutomaticSize = Enum.AutomaticSize.None,
		TextWrapped = false, TextTruncate = Enum.TextTruncate.AtEnd,
	})
	local chev = Create("Frame", {
		Parent = box, AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -8, 0.5, 0),
		Size = UDim2.fromOffset(10, 10), BackgroundTransparency = 1,
	})
	for _, c in ipairs({ { -2.1, 45 }, { 2.1, -45 } }) do
		Create("Frame", {
			Parent = chev, AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(0.5, c[1], 0.5, 1),
			Size = UDim2.fromOffset(6, 1), Rotation = c[2], BackgroundColor3 = Theme.Text, BackgroundTransparency = 0.2, BorderSizePixel = 0,
		})
	end

	local function Display()
		if D.Multi then
			local out = {}
			for _, v in ipairs(D.Values) do if D.Value[v] then table.insert(out, v) end end
			text.Text = #out > 0 and table.concat(out, ", ") or "--"
		else
			text.Text = D.Value ~= nil and tostring(D.Value) or "--"
		end
		-- ClickOrder: ghi thu tu chon vao phan gioi thieu
		if D.Multi and D.ClickOrder then
			local chain = {}
			for _, v in ipairs(D.Order) do if D.Value[v] then table.insert(chain, tostring(v)) end end
			local line = table.concat(chain, " -> ")
			local full = baseDesc
			if line ~= "" then full = (baseDesc ~= "" and (baseDesc .. "\n") or "") .. line end
			descLbl.Text = full
			descLbl.Visible = full ~= ""
		end
	end

	local refresh
	function D:SetValue(v)
		if D.Multi then
			local new = {}
			if type(v) == "table" then
				for k, val in pairs(v) do
					if type(k) == "number" then new[val] = true elseif val then new[k] = true end
				end
			end
			D.Value = new
			SyncOrder(type(v) == "table" and v or nil)
		else
			D.Value = v
		end
		Display()
		if refresh then refresh() end
		Fire(D, D.Value)
	end
	function D:SetValues(vals) D.Values = vals or {} end

	local holder, blocker
	-- [VA 3] connection rieng cho moi lan mo dropdown, khai bao TRUOC Close
	local openConns = {}
	local function Close()
		if not D.Opened then return end
		D.Opened = false
		for _, c in ipairs(openConns) do
			pcall(function() c:Disconnect() end)
		end
		table.clear(openConns)
		TweenS(chev, 0.25, Enum.EasingStyle.Quint, Enum.EasingDirection.Out, { Rotation = 0 })
		if blocker then SafeDestroy(blocker) blocker = nil end
		local h = holder
		holder = nil
		refresh = nil
		if h then
			local st = h:FindFirstChildOfClass("UIStroke")
			if st then TweenS(st, 0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.In, { Transparency = 1 }) end
			local tw = TweenS(h, 0.2, Enum.EasingStyle.Quint, Enum.EasingDirection.In, {
				Size = UDim2.fromOffset(h.Size.X.Offset, 0), BackgroundTransparency = 1,
			})
			tw.Completed:Connect(function() SafeDestroy(h) end)
		end
	end
	local function Open()
		D.Opened = true
		local function C(sig, fn)
			local c = sig:Connect(fn)
			table.insert(openConns, c)
			return c
		end
		TweenS(chev, 0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out, { Rotation = 180 })
		local gui = GetGui()
		blocker = Create("TextButton", {
			Parent = gui, Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Text = "", ZIndex = 49, AutoButtonColor = false,
		})
		C(blocker.MouseButton1Click, Close)
		local n = #D.Values
		local h = math.min(n, 6) * 36 + 4
		local w = 170
		local bp, bs = box.AbsolutePosition, box.AbsoluteSize
		local vp = gui.AbsoluteSize
		local x = math.clamp(bp.X + bs.X - w, 4, vp.X - w - 4)
		local y = bp.Y + bs.Y + 4
		if y + h > vp.Y - 4 then y = bp.Y - h - 4 end
		holder = Create("Frame", {
			Parent = gui, Position = UDim2.fromOffset(x, y - 8), Size = UDim2.fromOffset(w, 0), ZIndex = 50,
			BackgroundColor3 = Theme.DropdownHolder, BackgroundTransparency = 1, BorderSizePixel = 0, ClipsDescendants = true,
		}, { Corner(7), Stroke(Theme.DropdownBorder, 1, 1) })
		local myHolder = holder
		TweenS(holder, 0.32, Enum.EasingStyle.Quint, Enum.EasingDirection.Out, {
			Size = UDim2.fromOffset(w, h), Position = UDim2.fromOffset(x, y), BackgroundTransparency = 0.05,
		})
		TweenS(holder:FindFirstChildOfClass("UIStroke"), 0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out, { Transparency = 0 })

		local scroll = Create("ScrollingFrame", {
			Parent = holder, Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, BorderSizePixel = 0,
			ScrollBarThickness = 3, ScrollBarImageColor3 = Color3.new(1, 1, 1), ScrollBarImageTransparency = 0.9,
			CanvasSize = UDim2.new(), AutomaticCanvasSize = Enum.AutomaticSize.Y,
		}, {
			Create("UIListLayout", { Padding = UDim.new(0, 4), SortOrder = Enum.SortOrder.LayoutOrder }),
			Create("UIPadding", {
				PaddingTop = UDim.new(0, 4), PaddingLeft = UDim.new(0, 4), PaddingRight = UDim.new(0, 4), PaddingBottom = UDim.new(0, 4),
			}),
		})
		local items = {}
		for i, v in ipairs(D.Values) do
			local b = Create("TextButton", {
				Parent = scroll, Size = UDim2.new(1, 0, 0, 32), BackgroundColor3 = Color3.new(1, 1, 1),
				BackgroundTransparency = 1, Text = "", AutoButtonColor = false, LayoutOrder = i, BorderSizePixel = 0,
			}, { Corner(5) })
			local lbl = NewLabel(b, tostring(v), 13, Enum.FontWeight.Regular, Theme.Text, 1, {
				Position = UDim2.fromOffset(2, 0), Size = UDim2.new(1, -20, 1, 0), AutomaticSize = Enum.AutomaticSize.None, TextWrapped = false,
			})
			local pill = Create("Frame", {
				Parent = b, AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.new(0, 0, 0.5, 0),
				Size = UDim2.fromOffset(3, 0), BackgroundColor3 = Theme.Accent, BorderSizePixel = 0, Visible = false,
			}, { Corner(2) })
			items[v] = { b = b, pill = pill }
			-- muc truot vao + hien dan
			task.delay(0.04 * (i - 1) + 0.05, function()
				if lbl.Parent then
					TweenS(lbl, 0.3, Enum.EasingStyle.Quint, Enum.EasingDirection.Out, {
						TextTransparency = 0, Position = UDim2.fromOffset(12, 0),
					})
				end
			end)
			C(b.MouseEnter, function()
				local sel = D.Multi and D.Value[v] or D.Value == v
				if not sel then Tween(b, 0.1, { BackgroundTransparency = 0.93 }) end
			end)
			C(b.MouseLeave, function()
				local sel = D.Multi and D.Value[v] or D.Value == v
				if not sel then Tween(b, 0.1, { BackgroundTransparency = 1 }) end
			end)
			C(b.MouseButton1Click, function()
				if D.Multi then
					local new = {}
					for k in pairs(D.Value) do new[k] = true end
					new[v] = (not new[v]) or nil
					D:SetValue(new)
				else
					D:SetValue(v)
					Close()
				end
			end)
		end
		refresh = function()
			for v, it in pairs(items) do
				local sel = D.Multi and D.Value[v] or D.Value == v
				if sel then
					it.pill.Visible = true
					TweenS(it.pill, 0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out, { Size = UDim2.fromOffset(3, 14) })
				else
					it.pill.Visible = false
					it.pill.Size = UDim2.fromOffset(3, 0)
				end
				Tween(it.b, 0.15, { BackgroundTransparency = sel and 0.89 or 1 })
			end
		end
		refresh()
	end

	HitOverlay(el, function()
		if D.Opened then Close() else Open() end
	end)

	local saved = ConfigValue(idx)
	local def = cfg.Default
	local fromSaved = false
	if saved ~= nil then
		if D.Multi then
			if type(saved) == "table" then def = saved fromSaved = true end
		else
			for _, v in ipairs(D.Values) do
				if v == saved then def = saved fromSaved = true break end
			end
		end
	end
	if D.Multi then
		local dict = {}
		if type(def) == "table" then
			for k, val in pairs(def) do
				if type(k) == "number" then dict[val] = true elseif val then dict[k] = true end
			end
		end
		D.Value = dict
		SyncOrder(type(def) == "table" and def or nil)
	else
		if not fromSaved and type(def) == "number" then def = D.Values[def] end
		D.Value = def
	end
	Display()
	if fromSaved then Fire(D, D.Value) end
	D.Idx = idx
	Library.Options[idx] = D
	return D
end

function Elements:AddSection(title)
	local holder = Create("Frame", {
		Parent = self.Container, Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, BackgroundTransparency = 1,
		LayoutOrder = NextOrder(self.Container),
	}, {
		Create("UIListLayout", { Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder }),
		Create("UIPadding", { PaddingTop = UDim.new(0, 4) }),
	})
	NewLabel(holder, title or "Section", 13, Enum.FontWeight.SemiBold, Theme.SubText, 0, { LayoutOrder = 0 })
	local content = Create("Frame", {
		Parent = holder, Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, BackgroundTransparency = 1, LayoutOrder = 1,
	}, { Create("UIListLayout", { Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder }) })
	return setmetatable({ Container = content }, Elements)
end

----------------------------------------------------------------------
-- Notify
----------------------------------------------------------------------
local NotifyHolder
function Library:Notify(cfg)
	-- [VA 2] khong tao GUI moi sau khi Unload, tra ve doi tuong gia de code goi N:Close() khong loi
	if Library.Unloaded then
		return { Close = function() end }
	end
	cfg = cfg or {}
	local gui = GetGui()
	if not NotifyHolder or not NotifyHolder.Parent then
		NotifyHolder = Create("Frame", {
			Name = "Notifications", Parent = gui, AnchorPoint = Vector2.new(1, 1),
			Position = UDim2.new(1, -16, 1, -16), Size = UDim2.new(0, 310, 1, -32), BackgroundTransparency = 1,
		}, { Create("UIListLayout", {
			Padding = UDim.new(0, 8), VerticalAlignment = Enum.VerticalAlignment.Bottom, SortOrder = Enum.SortOrder.LayoutOrder,
		}) })
	end
	local wrap = Create("Frame", {
		Parent = NotifyHolder, Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, BackgroundTransparency = 1,
	})
	local card = Create("Frame", {
		Parent = wrap, Position = UDim2.new(1, 30, 0, 0), Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundColor3 = Color3.fromRGB(45, 45, 45), BackgroundTransparency = 0.25, BorderSizePixel = 0,
	}, { Corner(8), Stroke(Theme.AcrylicBorder, 1, 0.5) })
	local content = Create("Frame", {
		Parent = card, Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, BackgroundTransparency = 1,
	}, {
		Create("UIListLayout", { Padding = UDim.new(0, 4), SortOrder = Enum.SortOrder.LayoutOrder }),
		Create("UIPadding", {
			PaddingTop = UDim.new(0, 12), PaddingBottom = UDim.new(0, 12), PaddingLeft = UDim.new(0, 12), PaddingRight = UDim.new(0, 30),
		}),
	})
	NewLabel(content, cfg.Title or "", 13, Enum.FontWeight.SemiBold, Theme.Text, 0, { LayoutOrder = 1 })
	if cfg.Content and cfg.Content ~= "" then
		NewLabel(content, cfg.Content, 13, Enum.FontWeight.Regular, Theme.Text, 0.3, { LayoutOrder = 2 })
	end
	if cfg.SubContent and cfg.SubContent ~= "" then
		NewLabel(content, cfg.SubContent, 12, Enum.FontWeight.Regular, Theme.Text, 0.5, { LayoutOrder = 3 })
	end
	local closeBtn = Create("TextButton", {
		Parent = card, AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -6, 0, 6), Size = UDim2.fromOffset(22, 22),
		BackgroundColor3 = Color3.new(1, 1, 1), BackgroundTransparency = 1, Text = "", AutoButtonColor = false, BorderSizePixel = 0,
	}, { Corner(5) })
	DrawX(closeBtn, 9, Theme.Text)

	local N, closed = {}, false
	function N:Close()
		if closed then return end
		closed = true
		if card.Parent then
			Tween(card, 0.25, { Position = UDim2.new(1, 30, 0, 0) })
		end
		task.delay(0.28, function() SafeDestroy(wrap) end)
	end
	Connect(closeBtn.MouseEnter, function() Tween(closeBtn, 0.1, { BackgroundTransparency = 0.93 }) end)
	Connect(closeBtn.MouseLeave, function() Tween(closeBtn, 0.1, { BackgroundTransparency = 1 }) end)
	Connect(closeBtn.MouseButton1Click, function() N:Close() end)
	Tween(card, 0.3, { Position = UDim2.new(0, 0, 0, 0) })
	task.delay(cfg.Duration or 5, function() N:Close() end)
	return N
end

----------------------------------------------------------------------
-- Window
----------------------------------------------------------------------
function Library:CreateWindow(cfg)
	cfg = cfg or {}
	local Window = { Tabs = {}, TabCount = 0, Selected = nil, Minimized = false, Max = false }
	local size = cfg.Size or UDim2.fromOffset(580, 460)
	local tabWidth = cfg.TabWidth or 160
	local transparency = cfg.Transparency or 0.5
	local minimizeKey = cfg.MinimizeKey or Enum.KeyCode.LeftControl
	local gui = GetGui()
	local TITLE_H = 50

	local MainCorner = Corner(8)
	-- CanvasGroup de co the fade ca cua so + bo goc theo animation
	local Main = Create("CanvasGroup", {
		Name = "Window", Parent = gui, AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5),
		Size = size, BackgroundTransparency = 1, BorderSizePixel = 0, Active = true, GroupTransparency = 0,
	}, {
		MainCorner,
		Stroke(Theme.AcrylicBorder, 1, 0.5),
	})
	local Bg = Create("Frame", {
		Name = "Bg", Parent = Main, Size = UDim2.fromScale(1, 1), BackgroundColor3 = Color3.new(1, 1, 1),
		BackgroundTransparency = transparency, BorderSizePixel = 0,
	}, {
		Create("UIGradient", { Color = ColorSequence.new(Theme.GradientA, Theme.GradientB), Rotation = 90 }),
	})
	Create("ImageLabel", {
		Parent = Main, Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Image = Library.NoiseId,
		ImageTransparency = 0.92, ScaleType = Enum.ScaleType.Tile, TileSize = UDim2.fromOffset(128, 128), BorderSizePixel = 0,
	})
	Window.Main = Main
	Window.Bg = Bg
	Window._corner = MainCorner
	Window._transparency = transparency

	----------------------------------------------------------------
	-- Title bar (tieu de + phu de xep doc nhu anh)
	----------------------------------------------------------------
	local TitleBar = Create("Frame", {
		Parent = Main, Size = UDim2.new(1, 0, 0, TITLE_H), BackgroundTransparency = 1, Active = true,
	})
	local titleHolder = Create("Frame", {
		Parent = TitleBar, Position = UDim2.fromOffset(16, 0), Size = UDim2.new(0, 220, 1, 0), BackgroundTransparency = 1,
	}, { Create("UIListLayout", {
		FillDirection = Enum.FillDirection.Vertical, VerticalAlignment = Enum.VerticalAlignment.Center,
		Padding = UDim.new(0, 1), SortOrder = Enum.SortOrder.LayoutOrder,
	}) })
	NewLabel(titleHolder, cfg.Title or "Title", 14, Enum.FontWeight.SemiBold, Theme.Text, 0, {
		AutomaticSize = Enum.AutomaticSize.XY, Size = UDim2.new(), TextWrapped = false, LayoutOrder = 1,
	})
	if cfg.SubTitle and cfg.SubTitle ~= "" then
		NewLabel(titleHolder, cfg.SubTitle, 11, Enum.FontWeight.Regular, Theme.Text, 0.4, {
			AutomaticSize = Enum.AutomaticSize.XY, Size = UDim2.new(), TextWrapped = false, LayoutOrder = 2,
		})
	end
	Create("Frame", {
		Parent = Main, Position = UDim2.fromOffset(0, TITLE_H), Size = UDim2.new(1, 0, 0, 1),
		BackgroundColor3 = Theme.TitleBarLine, BackgroundTransparency = 0.5, BorderSizePixel = 0,
	})

	local controls = Create("Frame", {
		Parent = TitleBar, AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -8, 0.5, 0), Size = UDim2.fromOffset(150, 34),
		BackgroundTransparency = 1,
	}, { Create("UIListLayout", {
		FillDirection = Enum.FillDirection.Horizontal, HorizontalAlignment = Enum.HorizontalAlignment.Right,
		VerticalAlignment = Enum.VerticalAlignment.Center, Padding = UDim.new(0, 4), SortOrder = Enum.SortOrder.LayoutOrder,
	}) })
	local function ControlButton(order, round)
		local b = Create("TextButton", {
			Parent = controls, Size = UDim2.fromOffset(round and 30 or 34, round and 30 or 34),
			BackgroundColor3 = Color3.new(1, 1, 1), BackgroundTransparency = round and 0.94 or 1,
			Text = "", AutoButtonColor = false, LayoutOrder = order, BorderSizePixel = 0,
		}, { round and Round() or Corner(7) })
		if round then Stroke(Theme.ElementBorder, 1, 0.4).Parent = b end
		local base = round and 0.94 or 1
		Connect(b.MouseEnter, function() Tween(b, 0.1, { BackgroundTransparency = 0.88 }) end)
		Connect(b.MouseLeave, function() Tween(b, 0.1, { BackgroundTransparency = base }) end)
		return b
	end
	local searchBtn = ControlButton(0, true)
	local minBtn, maxBtn, closeBtn = ControlButton(1), ControlButton(2), ControlButton(3)

	DrawSearch(searchBtn, Theme.Text)
	Create("Frame", {
		Parent = minBtn, AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromOffset(10, 1), BackgroundColor3 = Theme.Text, BorderSizePixel = 0,
	})
	local maxIcon = Create("Frame", {
		Parent = maxBtn, Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1,
	})
	DrawMaximize(maxIcon, 10, Theme.Text)
	DrawX(closeBtn, 14, Theme.Text)

	-- Search box (mo ra khi bam nut kinh lup)
	local searchBox = Create("Frame", {
		Parent = TitleBar, AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -166, 0.5, 0),
		Size = UDim2.fromOffset(0, 28), BackgroundColor3 = Theme.Input, BackgroundTransparency = 0.9,
		BorderSizePixel = 0, ClipsDescendants = true, Visible = false,
	}, { Corner(14), Stroke(Theme.InElementBorder, 1, 0.5) })
	local searchTB = Create("TextBox", {
		Parent = searchBox, Position = UDim2.fromOffset(12, 0), Size = UDim2.new(1, -24, 1, 0), BackgroundTransparency = 1,
		ClearTextOnFocus = false, Text = "", PlaceholderText = "Search...", PlaceholderColor3 = Color3.fromRGB(140, 140, 140),
		TextColor3 = Theme.Text, TextSize = 12, FontFace = GetFont(), TextXAlignment = Enum.TextXAlignment.Left,
	})
	-- Tim kiem xuyen tab: nhac cac element khop ra trang "ket qua", xoa o tim kiem thi tra ve dung cho cu
	local ResultsPage, EmptyLbl, TabDisplayRef = nil, nil, nil
	local ResultsHeaders = {}
	Window._searching = false

	local function ApplySearch(q)
		q = string.lower(q or "")
		local searching = q ~= ""
		Window._searching = searching
		if not ResultsPage then return end

		if not searching then
			for _, r in ipairs(Registry) do
				local el = r.el
				if el and el.Parent == ResultsPage then
					el.LayoutOrder = r.order
					el.Parent = r.parent
				end
			end
			for _, h in pairs(ResultsHeaders) do h.Visible = false end
			EmptyLbl.Visible = false
			ResultsPage.Visible = false
			local sel = Window.Tabs[Window.Selected]
			if sel then
				sel.Page.Visible = true
				TabDisplayRef.Text = sel.Title
			end
			return
		end

		for _, t in pairs(Window.Tabs) do t.Page.Visible = false end
		ResultsPage.Visible = true
		TabDisplayRef.Text = "Search"

		local tabHas, any = {}, false
		for _, r in ipairs(Registry) do
			local el = r.el
			if el and r.parent and r.parent.Parent and r.parent:IsDescendantOf(Main) then
				local hit = string.find(string.lower(r.title), q, 1, true) ~= nil
					or string.find(string.lower(r.desc), q, 1, true) ~= nil
				if hit then
					if el.Parent ~= ResultsPage then el.Parent = ResultsPage end
					el.LayoutOrder = r.tabIdx * 100000 + r.idx
					el.Visible = true
					any = true
					if r.tabTitle ~= "" then tabHas[r.tabIdx] = r.tabTitle end
				elseif el.Parent == ResultsPage then
					el.LayoutOrder = r.order
					el.Parent = r.parent
				end
			end
		end
		for idx, title in pairs(tabHas) do
			local h = ResultsHeaders[idx]
			if not h then
				h = NewLabel(ResultsPage, title, 12, Enum.FontWeight.SemiBold, Theme.SubText, 0, { LayoutOrder = idx * 100000 })
				ResultsHeaders[idx] = h
			end
			h.Visible = true
		end
		for idx, h in pairs(ResultsHeaders) do
			if not tabHas[idx] then h.Visible = false end
		end
		EmptyLbl.Visible = not any
	end
	local searchOpen = false
	Connect(searchBtn.MouseButton1Click, function()
		searchOpen = not searchOpen
		if searchOpen then
			searchBox.Visible = true
			TweenS(searchBox, 0.35, Enum.EasingStyle.Back, Enum.EasingDirection.Out, { Size = UDim2.fromOffset(170, 28) })
			task.delay(0.15, function() if searchOpen then searchTB:CaptureFocus() end end)
		else
			searchTB.Text = ""
			ApplySearch("")
			local tw = TweenS(searchBox, 0.25, Enum.EasingStyle.Quint, Enum.EasingDirection.In, { Size = UDim2.fromOffset(0, 28) })
			tw.Completed:Connect(function()
				if not searchOpen then searchBox.Visible = false end
			end)
		end
	end)
	Connect(searchTB:GetPropertyChangedSignal("Text"), function() ApplySearch(searchTB.Text) end)

	-- Drag logic
	local dragging, dragStart, startPos
	local grabbing = false -- dang giu chuot (ke ca luc animation thu nho con chay)

	local function OverControls(pos)
		for _, f in ipairs({ controls, searchBox }) do
			if f.Visible then
				local a, sz = f.AbsolutePosition, f.AbsoluteSize
				if pos.X >= a.X and pos.X <= a.X + sz.X and pos.Y >= a.Y and pos.Y <= a.Y + sz.Y then
					return true
				end
			end
		end
		return false
	end

	Connect(TitleBar.InputBegan, function(i)
		if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
			Window._pointer = i.Position
			if Window.Max then
				if OverControls(i.Position) then return end
				-- dang full size: thu nho ve kich thuoc cu NGAY TRONG KHI bam vao con tro, roi tiep tuc keo
				grabbing = true
				Window:RestoreForDrag(i.Position, function()
					if grabbing and Window._pointer then
						dragging = true
						dragStart = Window._pointer
						startPos = Main.Position
					end
				end)
			else
				dragging, dragStart, startPos = true, i.Position, Main.Position
			end
		end
	end)
	Connect(UIS.InputChanged, function(i)
		if i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.Touch then
			Window._pointer = i.Position
			if dragging then
				local d = i.Position - dragStart
				Main.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + d.X, startPos.Y.Scale, startPos.Y.Offset + d.Y)
			end
		end
	end)
	Connect(UIS.InputEnded, function(i)
		if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
			dragging = false
			grabbing = false
		end
	end)

	----------------------------------------------------------------
	-- Sidebar: tabs
	----------------------------------------------------------------
	local TabArea = Create("Frame", {
		Parent = Main, Position = UDim2.fromOffset(12, TITLE_H + 12), Size = UDim2.new(0, tabWidth, 1, -(TITLE_H + 24)),
		BackgroundTransparency = 1, ClipsDescendants = true,
	})
	local TabScroll = Create("ScrollingFrame", {
		Parent = TabArea, Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, BorderSizePixel = 0,
		ScrollBarThickness = 0, CanvasSize = UDim2.new(), AutomaticCanvasSize = Enum.AutomaticSize.Y,
	}, {
		Create("UIListLayout", { Padding = UDim.new(0, 4), SortOrder = Enum.SortOrder.LayoutOrder }),
		Create("UIPadding", {
			PaddingLeft = UDim.new(0, 6), PaddingRight = UDim.new(0, 2),
			PaddingTop = UDim.new(0, 2), PaddingBottom = UDim.new(0, 2),
		}),
	})
	local Selector = Create("Frame", {
		Parent = TabArea, Position = UDim2.fromOffset(0, 11), Size = UDim2.fromOffset(3, 16),
		BackgroundColor3 = Theme.Accent, BorderSizePixel = 0, ZIndex = 2,
	}, { Corner(2) })

	local TabDisplay = NewLabel(Main, "", 28, Enum.FontWeight.SemiBold, Theme.Text, 0, {
		Position = UDim2.fromOffset(tabWidth + 28, TITLE_H + 12), Size = UDim2.new(1, -(tabWidth + 40), 0, 34),
		AutomaticSize = Enum.AutomaticSize.None, TextWrapped = false,
	})
	local ContainerHolder = Create("Frame", {
		Parent = Main, Position = UDim2.fromOffset(tabWidth + 26, TITLE_H + 56), Size = UDim2.new(1, -(tabWidth + 38), 1, -(TITLE_H + 68)),
		BackgroundTransparency = 1, ClipsDescendants = true,
	})

	TabDisplayRef = TabDisplay
	ResultsPage = Create("ScrollingFrame", {
		Name = "SearchResults", Parent = ContainerHolder, Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, BorderSizePixel = 0,
		ScrollBarThickness = 3, ScrollBarImageColor3 = Color3.new(1, 1, 1), ScrollBarImageTransparency = 0.95,
		CanvasSize = UDim2.new(), AutomaticCanvasSize = Enum.AutomaticSize.Y, Visible = false,
	}, {
		Create("UIListLayout", { Padding = UDim.new(0, 8), SortOrder = Enum.SortOrder.LayoutOrder }),
		Create("UIPadding", {
			PaddingLeft = UDim.new(0, 2), PaddingTop = UDim.new(0, 2),
			PaddingRight = UDim.new(0, 8), PaddingBottom = UDim.new(0, 4),
		}),
	})
	EmptyLbl = NewLabel(ResultsPage, "No results", 13, Enum.FontWeight.Regular, Theme.SubText, 0, {
		LayoutOrder = 2000000000, Visible = false,
	})

	function Window:SelectTab(i)
		local target = self.Tabs[i]
		if not target then return end
		self.Selected = i
		for idx, t in pairs(self.Tabs) do
			local sel = idx == i
			Tween(t.Button, 0.15, { BackgroundTransparency = sel and 0.89 or 1 })
			Tween(t.Label, 0.15, { TextTransparency = sel and 0 or 0.4 })
			Tween(t.Stroke, 0.15, { Transparency = sel and 0.5 or 1 })
			if t.Icon then Tween(t.Icon, 0.15, { ImageTransparency = sel and 0 or 0.4 }) end
			t.Page.Visible = sel and not self._searching
		end
		TweenS(Selector, 0.35, Enum.EasingStyle.Back, Enum.EasingDirection.Out, { Position = UDim2.fromOffset(0, (i - 1) * 38 + 11) })
		if not self._searching then TabDisplay.Text = target.Title end
		TabDisplay.TextTransparency = 1
		Tween(TabDisplay, 0.3, { TextTransparency = 0 })
		target.Page.Position = UDim2.fromOffset(0, 14)
		Tween(target.Page, 0.25, { Position = UDim2.fromOffset(0, 0) })
	end

	function Window:AddTab(tcfg)
		tcfg = tcfg or {}
		self.TabCount += 1
		local index = self.TabCount
		local tab = { Title = tcfg.Title or "Tab", Index = index }
		tab.Button = Create("TextButton", {
			Parent = TabScroll, Size = UDim2.new(1, 0, 0, 34), BackgroundColor3 = Color3.new(1, 1, 1),
			BackgroundTransparency = 1, Text = "", AutoButtonColor = false, LayoutOrder = index, BorderSizePixel = 0,
		}, { Corner(6) })
		tab.Stroke = Stroke(Theme.ElementBorder, 1, 1)
		tab.Stroke.Parent = tab.Button
		local offset = 14
		local icon = tcfg.Icon
		if icon and icon ~= "" then
			if tonumber(icon) then icon = "rbxassetid://" .. icon end
			tab.Icon = Create("ImageLabel", {
				Parent = tab.Button, BackgroundTransparency = 1, AnchorPoint = Vector2.new(0, 0.5),
				Position = UDim2.new(0, 12, 0.5, 0), Size = UDim2.fromOffset(16, 16), Image = icon,
				ImageColor3 = Theme.Accent, ImageTransparency = 0.4,
			})
			offset = 38
		end
		tab.Label = NewLabel(tab.Button, tab.Title, 12, Enum.FontWeight.Medium, Theme.Text, 0.4, {
			Position = UDim2.fromOffset(offset, 0), Size = UDim2.new(1, -(offset + 6), 1, 0),
			AutomaticSize = Enum.AutomaticSize.None, TextWrapped = false,
		})
		Connect(tab.Button.MouseEnter, function()
			if Window.Selected ~= index then Tween(tab.Button, 0.1, { BackgroundTransparency = 0.95 }) end
		end)
		Connect(tab.Button.MouseLeave, function()
			if Window.Selected ~= index then Tween(tab.Button, 0.1, { BackgroundTransparency = 1 }) end
		end)
		Connect(tab.Button.MouseButton1Click, function()
			-- dang tim kiem thi bam tab = thoat ket qua, mo tab do
			if Window._searching then searchTB.Text = "" end
			Window:SelectTab(index)
		end)

		tab.Page = Create("ScrollingFrame", {
			Parent = ContainerHolder, Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, BorderSizePixel = 0,
			ScrollBarThickness = 3, ScrollBarImageColor3 = Color3.new(1, 1, 1), ScrollBarImageTransparency = 0.95,
			CanvasSize = UDim2.new(), AutomaticCanvasSize = Enum.AutomaticSize.Y, Visible = false,
		}, {
			Create("UIListLayout", { Padding = UDim.new(0, 8), SortOrder = Enum.SortOrder.LayoutOrder }),
			Create("UIPadding", {
				PaddingLeft = UDim.new(0, 2), PaddingTop = UDim.new(0, 2),
				PaddingRight = UDim.new(0, 8), PaddingBottom = UDim.new(0, 4),
			}),
		})
		tab.Page:SetAttribute("TabTitle", tab.Title)
		tab.Page:SetAttribute("TabIndex", index)
		tab.Container = tab.Page
		self.Tabs[index] = tab
		if index == 1 then self:SelectTab(1) end
		return setmetatable(tab, { __index = Elements })
	end

	function Window:SetTransparency(n)
		Window._transparency = n
		Bg.BackgroundTransparency = n
	end

	Window.MinimizeKey = minimizeKey

	local function KeyName(k)
		return typeof(k) == "EnumItem" and k.Name or tostring(k)
	end

	----------------------------------------------------------------
	-- Nut toggle an/hien UI
	----------------------------------------------------------------
	local TOGGLE_IMAGE = cfg.ToggleImage or "rbxassetid://77671524243147"
	local TOGGLE_SIZE = cfg.ToggleSize or 50
	local SHOWN_RATIO = 0.95
	local HIDDEN_RATIO = 0.75

	local toggle = Create("TextButton", {
		Name = "TopiToggle", Parent = gui,
		Position = cfg.TTogglePosition or UDim2.fromOffset(20, 250),
		Size = UDim2.fromOffset(TOGGLE_SIZE, TOGGLE_SIZE),
		BackgroundColor3 = Color3.fromRGB(45, 45, 45), BackgroundTransparency = 0.2,
		Text = "", AutoButtonColor = false, BorderSizePixel = 0, ZIndex = 100,
	}, {
		Create("UICorner", { CornerRadius = UDim.new(1, 0) }),
		Stroke(Theme.AcrylicBorder, 1, 0.3),
	})
	local toggleScale = Create("UIScale", { Parent = toggle, Scale = 1 })
	local logo = Create("ImageLabel", {
		Parent = toggle, AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromOffset(TOGGLE_SIZE * SHOWN_RATIO, TOGGLE_SIZE * SHOWN_RATIO),
		BackgroundTransparency = 1, Image = TOGGLE_IMAGE, ZIndex = 101,
	}, { Create("UICorner", { CornerRadius = UDim.new(1, 0) }) })

	local function UpdateToggle(visible)
		local ratio = visible and SHOWN_RATIO or HIDDEN_RATIO
		Tween(logo, 0.2, { Size = UDim2.fromOffset(TOGGLE_SIZE * ratio, TOGGLE_SIZE * ratio) })
		Tween(toggle, 0.2, {
			BackgroundColor3 = visible and Color3.fromRGB(45, 45, 45) or Color3.new(1, 1, 1),
			BackgroundTransparency = visible and 0.2 or 0,
		})
	end
	UpdateToggle(true)

	-- hover / nhan: nut nay nhu giot nuoc
	Connect(toggle.MouseEnter, function()
		TweenS(toggleScale, 0.25, Enum.EasingStyle.Back, Enum.EasingDirection.Out, { Scale = 1.07 })
	end)
	Connect(toggle.MouseLeave, function()
		TweenS(toggleScale, 0.25, Enum.EasingStyle.Back, Enum.EasingDirection.Out, { Scale = 1 })
	end)

	local flow = FlowAnim.new(Window, toggle, toggleScale)
	Window._flow = flow

	function Window:SetVisible(v)
		-- [VA 1] bo qua neu animation dang chay, tranh lech trang thai Minimized
		if flow.Playing then return end
		self.Minimized = not v
		if v then
			UpdateToggle(true)
			flow:Show()
		else
			UpdateToggle(false)
			flow:Hide()
		end
		if v == false and self._hinted ~= true then
			self._hinted = true
			Library:Notify({
				Title = "TopiUI",
				Content = "Nhấn " .. KeyName(self.MinimizeKey) .. " hoặc bấm logo để ẩn/hiện UI.",
				Duration = 5,
			})
		end
	end

	function Window:Minimize()
		self:SetVisible(self.Minimized)
	end

	-- MAXIMIZE / RESTORE
	local maxIconInner = maxIcon
	function Window:ToggleMaximize()
		if self.Max then
			self.Max = false
			local info = TweenInfo.new(0.25, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)
			if self._maxTween then self._maxTween:Cancel() end
			self._maxTween = TweenService:Create(Main, info, {
				Size = self._savedSize,
				Position = self._savedPos,
			})
			self._maxTween:Play()
			for _, c in ipairs(maxIconInner:GetChildren()) do SafeDestroy(c) end
			DrawMaximize(maxIconInner, 10, Theme.Text)
		else
			self.Max = true
			self._savedSize = Main.Size
			self._savedPos = Main.Position
			local info = TweenInfo.new(0.25, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)
			if self._maxTween then self._maxTween:Cancel() end
			self._maxTween = TweenService:Create(Main, info, {
				Size = UDim2.new(1, -16, 1, -16),
				Position = UDim2.fromScale(0.5, 0.5),
			})
			self._maxTween:Play()
			for _, c in ipairs(maxIconInner:GetChildren()) do SafeDestroy(c) end
			DrawRestore(maxIconInner, 8, Theme.Text)
		end
	end

	-- Keo title bar luc dang full size: vua thu nho ve size cu, vua bam theo con tro
	function Window:RestoreForDrag(pointer, onDone)
		if not self.Max then return end
		self.Max = false
		if self._maxTween then self._maxTween:Cancel() end
		for _, c in ipairs(maxIconInner:GetChildren()) do SafeDestroy(c) end
		DrawMaximize(maxIconInner, 10, Theme.Text)

		local ga, gp = gui.AbsoluteSize, gui.AbsolutePosition
		local fromSize, fromPos = Main.AbsoluteSize, Main.AbsolutePosition
		local ss = self._savedSize
		local toW = ss.X.Scale * ga.X + ss.X.Offset
		local toH = ss.Y.Scale * ga.Y + ss.Y.Offset
		-- giu nguyen vi tri con tro tren title bar theo ti le ngang
		local rx = fromSize.X > 0 and math.clamp((pointer.X - fromPos.X) / fromSize.X, 0, 1) or 0.5
		local yoff = math.clamp(pointer.Y - fromPos.Y, 0, TITLE_H)

		if self._shrinkConn then self._shrinkConn:Disconnect() end
		local t0, DUR = os.clock(), 0.2
		local conn
		conn = RunService.Heartbeat:Connect(function()
			if Library.Unloaded or not Main.Parent then
				conn:Disconnect()
				self._shrinkConn = nil
				return
			end
			local a = math.clamp((os.clock() - t0) / DUR, 0, 1)
			local e = 1 - (1 - a) ^ 3
			local w = fromSize.X + (toW - fromSize.X) * e
			local h = fromSize.Y + (toH - fromSize.Y) * e
			local pt = self._pointer or pointer
			Main.Size = UDim2.fromOffset(w, h)
			Main.Position = UDim2.fromOffset(pt.X - rx * w + w / 2 - gp.X, pt.Y - yoff + h / 2 - gp.Y)
			if a >= 1 then
				conn:Disconnect()
				self._shrinkConn = nil
				Main.Size = ss
				if onDone then onDone() end
			end
		end)
		self._shrinkConn = conn
	end

	Connect(maxBtn.MouseButton1Click, function() Window:ToggleMaximize() end)
	Connect(minBtn.MouseButton1Click, function() Window:Minimize() end)
	Connect(closeBtn.MouseButton1Click, function() Library:Unload() end)

	Connect(UIS.InputBegan, function(input)
		if input.UserInputType ~= Enum.UserInputType.Keyboard then return end
		if UIS:GetFocusedTextBox() then return end
		local key = Window.MinimizeKey
		if input.KeyCode == key or input.KeyCode.Name == key then
			Window:Minimize()
		end
	end)

	do
		local pressing, dragged, startPos2, startInput = false, false, nil, nil
		Connect(toggle.InputBegan, function(i)
			if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
				pressing, dragged, startPos2, startInput = true, false, toggle.Position, i.Position
				TweenS(toggleScale, 0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out, { Scale = 0.9 })
			end
		end)
		Connect(UIS.InputChanged, function(i)
			if not pressing then return end
			if i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.Touch then
				local d = i.Position - startInput
				if dragged or d.Magnitude > 6 then
					dragged = true
					toggle.Position = UDim2.new(startPos2.X.Scale, startPos2.X.Offset + d.X, startPos2.Y.Scale, startPos2.Y.Offset + d.Y)
				end
			end
		end)
		Connect(UIS.InputEnded, function(i)
			if not pressing then return end
			if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
				pressing = false
				TweenS(toggleScale, 0.35, Enum.EasingStyle.Back, Enum.EasingDirection.Out, { Scale = 1 })
				if not dragged then Window:Minimize() end
			end
		end)
	end

	----------------------------------------------------------------
	-- RESIZE GRIP (goc duoi phai)
	----------------------------------------------------------------
	local grip = Create("Frame", {
		Name = "ResizeGrip",
		Parent = Main,
		AnchorPoint = Vector2.new(1, 1),
		Position = UDim2.new(1, -2, 1, -2),
		Size = UDim2.fromOffset(18, 18),
		BackgroundTransparency = 1,
		ZIndex = 200,
	})
	for i = 1, 3 do
		Create("Frame", {
			Parent = grip,
			AnchorPoint = Vector2.new(1, 1),
			Position = UDim2.new(1, -2 - i * 3, 1, -2),
			Size = UDim2.fromOffset(2, i * 3 + 2),
			BackgroundColor3 = Theme.Text,
			BackgroundTransparency = 0.5,
			BorderSizePixel = 0,
			Rotation = -45,
		})
	end

	local resizing = false
	local resizeStart, startSize, startPos3

	Connect(grip.InputBegan, function(i)
		if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
			if Window.Max then return end
			resizing = true
			resizeStart = i.Position
			startSize = Main.AbsoluteSize
			startPos3 = Main.AbsolutePosition
		end
	end)

	Connect(UIS.InputChanged, function(i)
		if not resizing then return end
		if i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.Touch then
			local d = i.Position - resizeStart
			local newX = math.max(startSize.X + d.X, 420)
			local newY = math.max(startSize.Y + d.Y, 260)

			Main.Size = UDim2.fromOffset(newX, newY)

			local guiAbs = gui.AbsolutePosition
			local newCenterX = startPos3.X + newX / 2
			local newCenterY = startPos3.Y + newY / 2

			Main.Position = UDim2.new(
				0, newCenterX - guiAbs.X,
				0, newCenterY - guiAbs.Y
			)
		end
	end)

	Connect(UIS.InputEnded, function(i)
		if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
			if resizing then
				resizing = false
				if not Window.Max then
					Window._savedSize = Main.Size
					Window._savedPos = Main.Position
				end
			end
		end
	end)

	Window._savedSize = Main.Size
	Window._savedPos = Main.Position

	table.insert(Library, Window)
	return Window
end

function Library:Unload()
	if self.Unloaded then return end
	if SavePending then self:SaveConfig() end
	self.Unloaded = true
	for _, c in ipairs(Connections) do pcall(function() c:Disconnect() end) end
	table.clear(Registry)
	if Gui then SafeDestroy(Gui) end
	for i = #self, 1, -1 do
		self[i] = nil
	end
end

return Library
