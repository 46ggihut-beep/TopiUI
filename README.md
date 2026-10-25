# TopiUI
# dùng
```
local Library = loadstring(game:HttpGet("https://raw.githubusercontent.com/46ggihut-beep/TopiUI/refs/heads/main/TopiUI_Lib.lua"))()

local Window = Library:CreateWindow({
	Title = "Topi Hub", SubTitle = "by wzarii",
	Size = UDim2.fromOffset(580, 460),
	Transparency = 0.5,
})

local Main = Window:AddTab({ Title = "Main", Icon = "" })
local Farm = Main:AddSection("Farm")
Farm:AddToggle("AutoFarm", { Title = "Auto Farm", Default = false })```
