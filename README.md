# TopiUI

Thư viện UI cho Roblox (Luau) phong cách **Fluent Dark**: cửa sổ kính mờ, hiệu ứng nảy đàn hồi, nút logo ẩn/hiện kiểu giọt nước, tự lưu config, tìm kiếm xuyên tab.

> Đây là **thư viện UI** (không tự chạy gì cả). Bạn dùng nó để tạo cửa sổ, tab, toggle, slider... cho script của bạn. Muốn xem ngay thì chạy [bản demo](#chạy-demo).

---

## Mục lục

1. [Tính năng](#tính-năng)
2. [Yêu cầu](#yêu-cầu)
3. [Chạy demo](#chạy-demo)
4. [Cài đặt](#cài-đặt)
5. [Bắt đầu nhanh](#bắt-đầu-nhanh)
6. [Hướng dẫn chi tiết](#hướng-dẫn-chi-tiết)
   - [Tạo cửa sổ](#1-tạo-cửa-sổ)
   - [Tạo tab](#2-tạo-tab)
   - [Section (nhóm)](#3-section-nhóm)
   - [Các thành phần (element)](#4-các-thành-phần-element)
   - [Đọc / đổi giá trị từ code](#5-đọc--đổi-giá-trị-từ-code)
   - [Thông báo](#6-thông-báo-notify)
   - [Điều khiển cửa sổ](#7-điều-khiển-cửa-sổ-từ-code)
   - [Gỡ UI](#8-gỡ-ui-unload)
7. [Lưu / tải config](#lưu--tải-config)
8. [Thao tác trên giao diện](#thao-tác-trên-giao-diện)
9. [Ví dụ đầy đủ](#ví-dụ-đầy-đủ)
10. [Câu hỏi thường gặp](#câu-hỏi-thường-gặp)
11. [Cấu trúc repo](#cấu-trúc-repo)

---

## Tính năng

- Cửa sổ kéo được, **đổi kích thước** (góc dưới phải), thu nhỏ / phóng to.
- Kéo title bar khi đang **full size**: UI vừa thu nhỏ về kích thước cũ vừa bám theo con trỏ.
- Nút **logo tròn** để ẩn / hiện UI (kéo được, có hiệu ứng giọt nước), hoặc phím tắt (mặc định `LeftControl`).
- Thành phần: **Paragraph, Button, Toggle, Slider, Input, Dropdown (một / nhiều lựa chọn)**.
- **Tìm kiếm xuyên tab**: gõ tên một mục ở tab nào cũng hiện ra và dùng được ngay.
- **Tự lưu config** theo từng người chơi (`Topi/<TênNgườiChơi>-Topi.json`).
- Thông báo (Notify) góc phải dưới.
- Slider cho phép bấm vào ô số để gõ giá trị chính xác.

## Yêu cầu

- Executor chạy được Luau với `loadstring` và `game:HttpGet`.
- (Tùy chọn) Hỗ trợ `writefile`, `readfile`, `isfolder`, `makefolder` để dùng tính năng lưu config. Nếu executor không có các hàm này, UI vẫn chạy bình thường, chỉ là không lưu được.
- GUI tự chọn nơi gắn theo thứ tự: `gethui()` → `CoreGui` → `PlayerGui`.

---

## Chạy demo

Chạy dòng sau trong executor:

```lua
loadstring(game:HttpGet("https://raw.githubusercontent.com/46ggihut-beep/TopiUI/refs/heads/main/Example.lua"))()
```

Demo gồm 4 tab: **Main** (WalkSpeed, JumpPower, Infinite Jump, nút), **Visual** (Fullbright, giờ trong ngày, FOV), **Components** (Input, Dropdown một / nhiều lựa chọn), **Settings** (độ trong suốt UI, quản lý config, gỡ UI).

---

## Cài đặt

Tải thư viện về biến `Library` bằng một dòng:

```lua
local Library = loadstring(game:HttpGet("https://raw.githubusercontent.com/46ggihut-beep/TopiUI/refs/heads/main/TopiUI_Lib.lua"))()
```

Hoặc nếu bạn đã lưu file `TopiUI_Lib.lua` vào thư mục workspace của executor:

```lua
local Library = loadstring(readfile("TopiUI_Lib.lua"))()
```

Sau đó tạo cửa sổ và các thành phần như hướng dẫn bên dưới.

---

## Bắt đầu nhanh

```lua
local Library = loadstring(game:HttpGet("https://raw.githubusercontent.com/46ggihut-beep/TopiUI/refs/heads/main/TopiUI_Lib.lua"))()

local Window = Library:CreateWindow({
	Title = "Tên Hub",
	SubTitle = "v1.0",
})

local Tab = Window:AddTab({ Title = "Main" })
local Section = Tab:AddSection("Di chuyển")

Section:AddToggle("SpeedOn", {
	Title = "Bật tốc độ",
	Default = false,
	Callback = function(value)
		print("Toggle:", value)
	end,
})

Section:AddSlider("SpeedValue", {
	Title = "WalkSpeed",
	Min = 16, Max = 200, Default = 16, Rounding = 0,
	Callback = function(value)
		print("Slider:", value)
	end,
})

Section:AddButton({
	Title = "Bấm thử",
	Callback = function()
		Library:Notify({ Title = "Xin chào", Content = "Bạn vừa bấm nút!", Duration = 3 })
	end,
})
```

---

## Hướng dẫn chi tiết

### 1. Tạo cửa sổ

```lua
local Window = Library:CreateWindow({
	Title = "Tên Hub",
	SubTitle = "Phụ đề",
	Size = UDim2.fromOffset(580, 460),
	TabWidth = 160,
	Transparency = 0.5,
	MinimizeKey = Enum.KeyCode.LeftControl,
})
```

| Tham số | Kiểu | Mặc định | Ý nghĩa |
| --- | --- | --- | --- |
| `Title` | string | `"Title"` | Tiêu đề trên title bar |
| `SubTitle` | string | không có | Dòng phụ đề nhỏ dưới tiêu đề |
| `Size` | UDim2 | `UDim2.fromOffset(580, 460)` | Kích thước ban đầu |
| `TabWidth` | number | `160` | Chiều rộng cột tab bên trái |
| `Transparency` | number (0–1) | `0.5` | Độ trong suốt nền cửa sổ |
| `MinimizeKey` | Enum.KeyCode | `LeftControl` | Phím ẩn / hiện UI |
| `ToggleImage` | string | logo mặc định | Ảnh trên nút logo tròn, dạng `"rbxassetid://123"` |
| `ToggleSize` | number | `50` | Kích thước nút logo (pixel) |
| `TTogglePosition` | UDim2 | `UDim2.fromOffset(20, 250)` | Vị trí ban đầu của nút logo |

### 2. Tạo tab

```lua
local Tab = Window:AddTab({ Title = "Main", Icon = "rbxassetid://1234567890" })
```

| Tham số | Kiểu | Ý nghĩa |
| --- | --- | --- |
| `Title` | string | Tên tab |
| `Icon` | string hoặc number | (Tùy chọn) Icon bên cạnh tên tab, có thể là số id hoặc `"rbxassetid://..."` |

Tab đầu tiên được chọn tự động. Muốn chuyển tab bằng code: `Window:SelectTab(2)` (đánh số từ 1 theo thứ tự tạo).

Bạn có thể gọi trực tiếp các hàm `Add...` trên tab (không cần Section), hoặc chia nhóm bằng Section.

### 3. Section (nhóm)

```lua
local Section = Tab:AddSection("Tên nhóm")
```

Section trả về một đối tượng có đủ các hàm `AddParagraph`, `AddButton`, `AddToggle`, `AddSlider`, `AddInput`, `AddDropdown` giống như tab.

### 4. Các thành phần (element)

> **Quan trọng:** `AddToggle`, `AddSlider`, `AddInput`, `AddDropdown` đều nhận **một tên định danh (`idx`) làm tham số đầu**, ví dụ `"SpeedOn"`. Tên này phải **không trùng nhau**, vì nó dùng để truy cập giá trị (`Library.Options.SpeedOn`) và làm khóa lưu config. `AddButton` và `AddParagraph` thì không cần.

Các tham số chung cho mọi thành phần: `Title` (tên), `Description` (mô tả nhỏ bên dưới, tùy chọn), `Icon` (tùy chọn).

#### Paragraph (đoạn chữ)

```lua
local P = Section:AddParagraph({
	Title = "Giới thiệu",
	Content = "Nội dung hiển thị ở đây.",
})

P:SetTitle("Tiêu đề mới")
P:SetDesc("Nội dung mới")
```

#### Button (nút bấm)

```lua
Section:AddButton({
	Title = "Hồi sinh",
	Description = "Reset nhân vật",
	Callback = function()
		print("Đã bấm")
	end,
})
```

#### Toggle (công tắc)

```lua
Section:AddToggle("AutoFarm", {
	Title = "Auto Farm",
	Description = "Tự động farm",
	Default = false,
	Callback = function(value) -- value: true / false
		print(value)
	end,
})
```

#### Slider (thanh trượt)

```lua
Section:AddSlider("Speed", {
	Title = "Tốc độ",
	Description = "Kéo hoặc bấm vào ô số để gõ giá trị",
	Min = 0,
	Max = 100,
	Default = 50,
	Rounding = 0,
	Suffix = "%",
	Callback = function(value) -- value: số
		print(value)
	end,
})
```

| Tham số | Mặc định | Ý nghĩa |
| --- | --- | --- |
| `Min` / `Max` | `0` / `100` | Khoảng giá trị |
| `Default` | `Min` | Giá trị ban đầu |
| `Rounding` | `0` | Số chữ số thập phân (ví dụ `1` → `0.5`) |
| `Suffix` | rỗng | Hậu tố hiển thị cạnh số, ví dụ `"%"` hoặc `"s"` |

#### Input (ô nhập)

```lua
Section:AddInput("PlayerName", {
	Title = "Tên người chơi",
	Default = "",
	Placeholder = "Nhập tên...",
	Numeric = false,
	Finished = true,
	Callback = function(text) -- text: chuỗi
		print(text)
	end,
})
```

| Tham số | Mặc định | Ý nghĩa |
| --- | --- | --- |
| `Default` | `""` | Nội dung ban đầu |
| `Placeholder` | rỗng | Chữ gợi ý khi ô trống |
| `Numeric` | `false` | `true` thì chỉ cho gõ số, dấu `.` và `-` |
| `Finished` | `false` | `true` thì chỉ gọi callback khi nhấn Enter / rời ô. `false` thì gọi mỗi lần gõ |

#### Dropdown (danh sách chọn)

Chọn một:

```lua
Section:AddDropdown("Fruit", {
	Title = "Chọn trái",
	Values = { "Táo", "Cam", "Xoài" },
	Default = 1, -- số thứ tự trong Values, hoặc chính giá trị, ví dụ "Táo"
	Callback = function(value) -- value: giá trị đã chọn (string)
		print(value)
	end,
})
```

Chọn nhiều:

```lua
Section:AddDropdown("Skills", {
	Title = "Chọn skill",
	Values = { "Z", "X", "C", "V" },
	Multi = true,
	Default = { "Z", "X" },
	Callback = function(value) -- value: bảng dạng { Z = true, X = true }
		for name, on in pairs(value) do
			if on then print("Đang chọn:", name) end
		end
	end,
})
```

| Tham số | Ý nghĩa |
| --- | --- |
| `Values` | Danh sách các lựa chọn (mảng) |
| `Multi` | `true` để chọn nhiều |
| `Default` | Chọn một: số thứ tự hoặc giá trị. Chọn nhiều: mảng `{ "Z", "X" }` hoặc bảng `{ Z = true }` |

Danh sách hiển thị tối đa khoảng 6 mục, nhiều hơn thì cuộn.

### 5. Đọc / đổi giá trị từ code

Mọi thành phần có `idx` đều được lưu trong `Library.Options`:

```lua
-- Đọc
print(Library.Options.AutoFarm.Value)   -- true / false
print(Library.Options.Speed.Value)      -- số
print(Library.Options.PlayerName.Value) -- chuỗi
print(Library.Options.Fruit.Value)      -- giá trị đang chọn
print(Library.Options.Skills.Value.Z)   -- Multi: true nếu đang chọn "Z"

-- Đổi giá trị (UI cập nhật theo và callback được gọi)
Library.Options.AutoFarm:SetValue(true)
Library.Options.Speed:SetValue(80)
Library.Options.PlayerName:SetValue("Topi")
Library.Options.Fruit:SetValue("Cam")
Library.Options.Skills:SetValue({ "Z", "C" })

-- Thay danh sách của dropdown (có hiệu lực ở lần mở kế tiếp)
Library.Options.Fruit:SetValues({ "Nho", "Dưa hấu" })

-- Lắng nghe thay đổi ở bất kỳ đâu
Library.Options.AutoFarm:OnChanged(function(value)
	print("AutoFarm đổi thành", value)
end)
```

Mỗi option có thuộc tính `Type` là `"Toggle"`, `"Slider"`, `"Input"` hoặc `"Dropdown"`.

> **Lưu ý về callback lúc khởi tạo:** `Toggle` và `Slider` luôn gọi callback một lần ngay khi được tạo (với giá trị mặc định hoặc giá trị đã lưu). `Dropdown` và `Input` chỉ gọi callback lúc tạo khi giá trị được **khôi phục từ file config**.

### 6. Thông báo (Notify)

```lua
local N = Library:Notify({
	Title = "Tiêu đề",
	Content = "Nội dung chính",
	SubContent = "Dòng phụ (tùy chọn)",
	Duration = 5,
})

N:Close() -- đóng sớm nếu muốn
```

| Tham số | Mặc định | Ý nghĩa |
| --- | --- | --- |
| `Title` | rỗng | Tiêu đề |
| `Content` | rỗng | Nội dung |
| `SubContent` | rỗng | Dòng phụ nhỏ hơn |
| `Duration` | `5` | Số giây tự đóng |

### 7. Điều khiển cửa sổ từ code

```lua
Window:SetVisible(false)      -- ẩn UI (có hiệu ứng thu vào logo)
Window:SetVisible(true)       -- hiện UI
Window:Minimize()             -- đảo trạng thái ẩn / hiện
Window:ToggleMaximize()       -- phóng to / khôi phục
Window:SelectTab(2)           -- chọn tab số 2
Window:SetTransparency(0.3)   -- đổi độ trong suốt nền (0 đến 1)
Window.MinimizeKey = Enum.KeyCode.RightShift -- đổi phím tắt ẩn / hiện
```

Thời gian hiệu ứng ẩn / hiện chỉnh được bằng `Library.FlowDuration` (mặc định `0.4`).

### 8. Gỡ UI (Unload)

```lua
Library:Unload()
```

Hủy toàn bộ UI và ngắt mọi kết nối. Nút **X** trên title bar cũng gọi hàm này. Sau khi gỡ, `Library.Unloaded` là `true`. Nếu có vòng lặp trong script của bạn, nên kiểm tra để dừng:

```lua
task.spawn(function()
	while not Library.Unloaded do
		-- việc của bạn
		task.wait(0.2)
	end
end)
```

Muốn chạy lại UI thì tải lại thư viện bằng `loadstring` một lần nữa.

---

## Lưu / tải config

TopiUI **tự động lưu** mọi thay đổi của Toggle, Slider, Input và Dropdown, và tự khôi phục khi lần sau bạn chạy script.

- File lưu ở: `Topi/<TênNgườiChơi>-Topi.json` (trong thư mục workspace của executor).
- Mỗi giá trị được lưu theo `idx` bạn đặt (ví dụ `"AutoFarm"`). **Nếu bạn đổi tên `idx` thì giá trị cũ không còn khớp.**
- Nhiều thay đổi liên tiếp (như kéo slider) được gom lại và ghi file một lần, nên không bị giật.
- Khi gỡ UI, thay đổi còn chờ sẽ được lưu nốt.

Các hàm điều khiển:

| Hàm / thuộc tính | Tác dụng |
| --- | --- |
| `Library:SaveConfig()` | Lưu ngay, trả về `true` nếu thành công |
| `Library:ApplyConfig()` | Đọc lại file và áp lên các option đang có (callback được gọi) |
| `Library:LoadConfig()` | Chỉ đọc file vào `Library.Settings`, chưa đổi UI |
| `Library:DeleteConfig()` | Xóa file config |
| `Library:GetConfigPath()` | Trả về đường dẫn file hiện tại |
| `Library.AutoSave = false` | Tắt tự động lưu (vẫn gọi `SaveConfig()` thủ công được) |
| `Library.ConfigFolder` | Tên thư mục, mặc định `"Topi"` |
| `Library.ConfigSuffix` | Hậu tố tên file, mặc định `"-Topi.json"` |

Muốn đổi tên thư mục hoặc file, đặt **trước khi tạo cửa sổ** và gọi `LoadConfig()` lại:

```lua
local Library = loadstring(game:HttpGet("https://raw.githubusercontent.com/46ggihut-beep/TopiUI/refs/heads/main/TopiUI_Lib.lua"))()

Library.ConfigFolder = "MyHub"
Library.ConfigSuffix = "-MyHub.json"
Library:LoadConfig()

local Window = Library:CreateWindow({ Title = "My Hub" })
```

Ví dụ thêm nút quản lý config vào một tab:

```lua
local Sec = Tab:AddSection("Config")

Sec:AddButton({ Title = "Lưu config", Callback = function()
	Library:SaveConfig()
end })

Sec:AddButton({ Title = "Tải lại config", Callback = function()
	Library:ApplyConfig()
end })

Sec:AddButton({ Title = "Xóa config", Callback = function()
	Library:DeleteConfig()
end })
```

---

## Thao tác trên giao diện

| Thao tác | Kết quả |
| --- | --- |
| Kéo title bar | Di chuyển cửa sổ |
| Kéo title bar khi đang full size | Cửa sổ thu nhỏ về kích thước cũ và bám theo con trỏ |
| Kéo góc dưới phải | Đổi kích thước (tối thiểu 420 × 260) |
| Nút `−` | Ẩn UI vào logo |
| Nút `□` | Phóng to / khôi phục |
| Nút `X` | Gỡ UI hoàn toàn |
| Phím `LeftControl` (hoặc `MinimizeKey`) hoặc bấm logo | Ẩn / hiện UI. Phím tắt không hoạt động khi bạn đang gõ trong ô nhập |
| Kéo logo tròn | Di chuyển nút logo |
| Nút kính lúp | Mở ô tìm kiếm |
| Gõ vào ô tìm kiếm | Hiện các mục khớp (theo tiêu đề hoặc mô tả) từ **tất cả các tab**, nhóm theo tab. Xóa chữ để về lại tab cũ |
| Bấm vào ô số của slider | Gõ giá trị chính xác |

---

## Ví dụ đầy đủ

```lua
local Library = loadstring(game:HttpGet("https://raw.githubusercontent.com/46ggihut-beep/TopiUI/refs/heads/main/TopiUI_Lib.lua"))()

local Window = Library:CreateWindow({
	Title = "TopiHub",
	SubTitle = "Ví dụ",
	Size = UDim2.fromOffset(580, 460),
	MinimizeKey = Enum.KeyCode.LeftControl,
})

----------------------------------------------------------------
-- Tab Main
----------------------------------------------------------------
local Main = Window:AddTab({ Title = "Main" })

Main:AddParagraph({
	Title = "Chào mừng",
	Content = "Bấm logo hoặc LeftControl để ẩn / hiện.",
})

local Move = Main:AddSection("Di chuyển")

local speedOn, speedVal = false, 16

Move:AddToggle("SpeedOn", {
	Title = "Bật WalkSpeed",
	Default = false,
	Callback = function(v)
		speedOn = v
		if not v then
			local c = game.Players.LocalPlayer.Character
			local h = c and c:FindFirstChildOfClass("Humanoid")
			if h then h.WalkSpeed = 16 end
		end
	end,
})

Move:AddSlider("SpeedValue", {
	Title = "WalkSpeed",
	Min = 16, Max = 200, Default = 16, Rounding = 0,
	Callback = function(v) speedVal = v end,
})

task.spawn(function()
	while not Library.Unloaded do
		local c = game.Players.LocalPlayer.Character
		local h = c and c:FindFirstChildOfClass("Humanoid")
		if h and speedOn then h.WalkSpeed = speedVal end
		task.wait(0.2)
	end
end)

----------------------------------------------------------------
-- Tab Components
----------------------------------------------------------------
local Comp = Window:AddTab({ Title = "Components" })
local Inputs = Comp:AddSection("Nhập liệu")

Inputs:AddInput("Name", {
	Title = "Tên",
	Placeholder = "Nhập tên...",
	Finished = true,
	Callback = function(v) print("Tên:", v) end,
})

Inputs:AddDropdown("Fruit", {
	Title = "Chọn một",
	Values = { "Táo", "Cam", "Xoài" },
	Default = 1,
	Callback = function(v) print("Chọn:", v) end,
})

Inputs:AddDropdown("Skills", {
	Title = "Chọn nhiều",
	Values = { "Z", "X", "C", "V" },
	Multi = true,
	Default = { "Z" },
	Callback = function(v)
		local out = {}
		for k, on in pairs(v) do if on then table.insert(out, k) end end
		print("Đang chọn:", table.concat(out, ", "))
	end,
})

----------------------------------------------------------------
-- Tab Settings
----------------------------------------------------------------
local Set = Window:AddTab({ Title = "Settings" })
local UISec = Set:AddSection("Giao diện")

UISec:AddSlider("UITransparency", {
	Title = "Độ trong suốt UI",
	Min = 0, Max = 1, Default = 0.5, Rounding = 2,
	Callback = function(v) Window:SetTransparency(v) end,
})

UISec:AddButton({
	Title = "Gỡ UI",
	Callback = function() Library:Unload() end,
})

Library:Notify({ Title = "TopiHub", Content = "Đã tải xong.", Duration = 4 })
```

---

## Câu hỏi thường gặp

**UI không hiện ra / báo lỗi khi tạo `Library.Options[nil]`?**
Bạn quên truyền `idx` (tên định danh) ở `AddToggle`, `AddSlider`, `AddInput` hoặc `AddDropdown`. Hãy đặt tên là tham số đầu tiên: `AddToggle("Ten", { ... })`.

**Config không lưu?**
Kiểm tra executor có hỗ trợ `writefile`, `readfile`, `isfolder`, `makefolder` không. Có thể bấm `Library:SaveConfig()` và xem giá trị trả về (`false` nghĩa là ghi thất bại).

**Đổi tên `idx` rồi mất cài đặt cũ?**
Config lưu theo `idx`, đổi tên thì khóa cũ không còn khớp và option sẽ dùng `Default`.

**Có hai UI chồng lên nhau?**
Bạn chạy script hai lần. Gọi `Library:Unload()` trên bản cũ trước khi chạy bản mới (nút `X` cũng làm được việc này).

**Muốn đổi font?**
Đặt `Library.UseFluentFont = false` trước khi tạo cửa sổ để dùng font Gotham mặc định của Roblox.

---

## Cấu trúc repo

```
.
├── TopiUI_Lib.lua # Thư viện UI
├── Example.lua   # Script demo (load thư viện từ GitHub)
└── README.md
```

Repo: <https://github.com/46ggihut-beep/TopiUI>

---

## License

Chọn license phù hợp cho dự án của bạn (ví dụ MIT) và thêm file `LICENSE` vào repo.
