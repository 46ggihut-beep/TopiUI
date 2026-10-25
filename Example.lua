-- TopiUI Example
local Library = loadstring(game:HttpGet("https://raw.githubusercontent.com/46ggihut-beep/TopiUI/refs/heads/main/TopiUI_Lib.lua"))()

----------------------------------------------------------------------
-- DEMO: tao cua so, tab, toggle, slider, input, dropdown, button
----------------------------------------------------------------------
local Players = game:GetService("Players")
local UIS = game:GetService("UserInputService")
local Lighting = game:GetService("Lighting")
local LP = Players.LocalPlayer

local Window = Library:CreateWindow({
	Title = "TopiUI",
	SubTitle = "Demo",
	Size = UDim2.fromOffset(500, 400),
	TabWidth = 160,
	Transparency = 0.5,
	MinimizeKey = Enum.KeyCode.LeftControl,
})

local function GetHum()
	local c = LP.Character
	return c and c:FindFirstChildOfClass("Humanoid")
end

----------------------------------------------------------------------
-- TAB 1: Main
----------------------------------------------------------------------
local Main = Window:AddTab({ Title = "Main" })

Main:AddParagraph({
	Title = "Chào mừng",
	Content = "Đây là UI demo. Bấm logo hoặc LeftControl để ẩn/hiện.",
})

local Move = Main:AddSection("Di chuyển")

local speedOn, jumpOn = false, false
local speedVal, jumpVal = 16, 50

Move:AddToggle("SpeedToggle", {
	Title = "Bật WalkSpeed",
	Description = "Giữ tốc độ chạy theo slider bên dưới",
	Default = false,
	Callback = function(v)
		speedOn = v
		if not v then
			local h = GetHum()
			if h then h.WalkSpeed = 16 end
		end
	end,
})

Move:AddSlider("SpeedSlider", {
	Title = "WalkSpeed",
	Description = "Tốc độ chạy",
	Min = 16, Max = 200, Default = 16, Rounding = 0,
	Callback = function(v) speedVal = v end,
})

Move:AddToggle("JumpToggle", {
	Title = "Bật JumpPower",
	Default = false,
	Callback = function(v)
		jumpOn = v
		if not v then
			local h = GetHum()
			if h then h.UseJumpPower = true h.JumpPower = 50 end
		end
	end,
})

Move:AddSlider("JumpSlider", {
	Title = "JumpPower",
	Min = 50, Max = 300, Default = 50, Rounding = 0,
	Callback = function(v) jumpVal = v end,
})

local infJump = false
Move:AddToggle("InfJump", {
	Title = "Infinite Jump",
	Description = "Nhảy liên tục trên không",
	Default = false,
	Callback = function(v) infJump = v end,
})

-- vong lap ap dung speed / jump (tu dung khi Unload)
task.spawn(function()
	while not Library.Unloaded do
		local h = GetHum()
		if h then
			if speedOn then h.WalkSpeed = speedVal end
			if jumpOn then h.UseJumpPower = true h.JumpPower = jumpVal end
		end
		task.wait(0.2)
	end
end)

UIS.JumpRequest:Connect(function()
	if Library.Unloaded or not infJump then return end
	local h = GetHum()
	if h then h:ChangeState(Enum.HumanoidStateType.Jumping) end
end)

local Act = Main:AddSection("Hành động")

Act:AddButton({
	Title = "Hồi sinh nhân vật",
	Description = "Reset nhân vật hiện tại",
	Callback = function()
		local h = GetHum()
		if h then h.Health = 0 end
	end,
})

Act:AddButton({
	Title = "Gửi thông báo thử",
	Callback = function()
		Library:Notify({
			Title = "Xin chào",
			Content = "Đây là thông báo thử nghiệm.",
			SubContent = "Tự đóng sau 4 giây",
			Duration = 4,
		})
	end,
})

----------------------------------------------------------------------
-- TAB 2: Visual
----------------------------------------------------------------------
local Visual = Window:AddTab({ Title = "Visual" })
local Env = Visual:AddSection("Môi trường")

local origBright = Lighting.Brightness
local origClock = Lighting.ClockTime

Env:AddToggle("Fullbright", {
	Title = "Fullbright",
	Description = "Làm sáng toàn bản đồ",
	Default = false,
	Callback = function(v)
		if v then
			origBright = Lighting.Brightness
			Lighting.Brightness = 3
		else
			Lighting.Brightness = origBright
		end
	end,
})

Env:AddSlider("ClockTime", {
	Title = "Thời gian trong ngày",
	Min = 0, Max = 24, Default = math.floor(origClock), Rounding = 1,
	Callback = function(v) Lighting.ClockTime = v end,
})

Env:AddSlider("FOV", {
	Title = "Field of View",
	Min = 40, Max = 120, Default = 70, Rounding = 0,
	Callback = function(v)
		local cam = workspace.CurrentCamera
		if cam then cam.FieldOfView = v end
	end,
})

----------------------------------------------------------------------
-- TAB 3: Components (test cac loai element)
----------------------------------------------------------------------
local Comp = Window:AddTab({ Title = "Components" })
local Inputs = Comp:AddSection("Input & Dropdown")

Inputs:AddInput("NameInput", {
	Title = "Tên",
	Description = "Gõ gì đó và nhấn Enter",
	Default = "",
	Placeholder = "Nhập tên...",
	Finished = true,
	Callback = function(v) print("[TopiUI] Input:", v) end,
})

Inputs:AddInput("NumInput", {
	Title = "Số",
	Placeholder = "123",
	Numeric = true,
	Finished = true,
	Callback = function(v) print("[TopiUI] Number:", v) end,
})

Inputs:AddDropdown("SingleDrop", {
	Title = "Chọn một",
	Values = { "Táo", "Cam", "Xoài", "Nho", "Dưa hấu", "Chuối", "Ổi" },
	Default = 1,
	Callback = function(v) print("[TopiUI] Dropdown:", v) end,
})

Inputs:AddDropdown("MultiDrop", {
	Title = "Chọn nhiều",
	Values = { "A", "B", "C", "D" },
	Multi = true,
	Default = { "A" },
	Callback = function(v)
		local out = {}
		for k, on in pairs(v) do if on then table.insert(out, k) end end
		print("[TopiUI] Multi:", table.concat(out, ", "))
	end,
})

----------------------------------------------------------------------
-- TAB 4: Settings
----------------------------------------------------------------------
local Settings = Window:AddTab({ Title = "Settings" })
local UISec = Settings:AddSection("Giao diện")

UISec:AddSlider("UITransparency", {
	Title = "Độ trong suốt UI",
	Min = 0, Max = 1, Default = 0.5, Rounding = 2,
	Callback = function(v) Window:SetTransparency(v) end,
})

UISec:AddButton({
	Title = "Đóng và gỡ UI",
	Description = "Unload toàn bộ UI",
	Callback = function() Library:Unload() end,
})

local CfgSec = Settings:AddSection("Config (Topi)")

CfgSec:AddParagraph({
	Title = "Tự động lưu",
	Content = "Mọi thay đổi được lưu vào Topi/<TênBạn>-Topi.json",
})

CfgSec:AddButton({
	Title = "Lưu config ngay",
	Callback = function()
		local ok = Library:SaveConfig()
		Library:Notify({ Title = "Topi", Content = ok and "Đã lưu config." or "Không lưu được (executor không hỗ trợ file?).", Duration = 3 })
	end,
})

CfgSec:AddButton({
	Title = "Tải lại config",
	Callback = function()
		Library:ApplyConfig()
		Library:Notify({ Title = "Topi", Content = "Đã tải lại config.", Duration = 3 })
	end,
})

CfgSec:AddButton({
	Title = "Xóa config",
	Callback = function()
		Library:DeleteConfig()
		Library:Notify({ Title = "Topi", Content = "Đã xóa file config.", Duration = 3 })
	end,
})

Library:Notify({
	Title = "TopiUI",
	Content = "Đã tải xong UI demo.",
	Duration = 4,
})
