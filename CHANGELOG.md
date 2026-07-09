# Changelog

## [1.3.0] - 2026-07-09

### Thêm
- **Quét tàn dư Docker** (module 17): Docker Desktop/CLI đã gỡ mà còn sót thì báo — thư mục dữ liệu (`%LOCALAPPDATA%\Docker` chứa vhdx nhiều GB, `%APPDATA%\Docker`, `%PROGRAMDATA%\Docker`, `~\.docker`, thư mục cài đặt sót trong Program Files) và đăng ký WSL distro `docker-desktop`/`docker-desktop-data` mồ côi. Docker còn cài thì chỉ báo kho dữ liệu >= 1 GB kèm lệnh dọn chính chủ (`docker system prune`) dạng Info, không cho xóa.
- **Quét tàn dư WSL** (module 18): đăng ký distro trong `HKCU\...\Lxss` trỏ tới thư mục đã biến mất (High, xóa key kèm backup .reg), dữ liệu distro `ext4.vhdx` trên đĩa mà WSL không còn đăng ký — cả trong `%LOCALAPPDATA%\wsl` lẫn gói Store đã gỡ (Medium), và thư mục `lxss` legacy của WSL1 cũ. Distro đăng ký hợp lệ và gói Store còn cài KHÔNG bị đụng tới; không xác định được trạng thái gói (Get-AppxPackage lỗi) thì bỏ qua cho an toàn.
- **Hiện "CÓ GÌ MỚI" trước khi cập nhật**: prompt tự cập nhật giờ tải `CHANGELOG.md` từ GitHub và liệt kê thay đổi của TẤT CẢ các bản nằm giữa bản đang dùng và bản mới (tối đa 30 dòng) rồi mới hỏi y/N — biết mình sắp nhận gì trước khi bấm. Tải/parse lỗi thì bỏ qua êm và vẫn hỏi cập nhật như cũ.

## [1.2.2] - 2026-07-07

### Sửa
- **"Write-StatusLine is not recognized" khi dọn (issue #1)**: hai scriptblock in dòng kết quả √/× trong `Remove-SelectedFindings` dùng `.GetNewClosure()` - closure bị buộc vào dynamic module, mà tra cứu lệnh trong module chỉ đi *module -> global*, bỏ qua script scope. Chạy script bằng `.\WinTrash.ps1` trong console (hàm nằm ở script scope) là dính lỗi với MỌI mục xóa, bộ đếm OK/lỗi về 0 và `cleanup.log` rỗng (dù xóa + backup vẫn chạy thật); chạy bằng `-File`/chuột phải thì không sao (hàm vào global scope) nên trước giờ không lộ. Fix: bỏ `GetNewClosure` - block thường giữ nguyên session state, hàm lẫn biến đều resolve đúng ở mọi kiểu chạy, trên cả PS 5.1 lẫn PS 7.
- **Test suite vỡ cú pháp trên PS 5.1**: `tests\WinTrash.Tests.ps1` thiếu UTF-8 BOM - PS 5.1 đọc file thành CP1252, vài byte của chữ Việt biến thành smart-quote làm parser hiểu nhầm chuỗi. Thêm BOM (giống `WinTrash.ps1`); thêm test AST chặn `GetNewClosure` tái xuất.
- **Lịch quét tháng tạo từ PowerShell 7 không bao giờ chạy**: PS 7.3+ mặc định `PSNativeCommandArgumentPassing='Windows'` escape LẠI chuỗi `\"` viết tay trong `/TR` của `schtasks` -> task lưu literal `\"` quanh đường dẫn, tháng nào cũng fail im lặng dù lúc tạo báo thành công. Ép `Legacy` trong scope con quanh lệnh `schtasks /Create` (trên PS 5.1 vô hại) - đã kiểm chứng XML task sạch trên cả 2 engine.
- **Lịch quét trỏ sai file khi script bị đổi tên**: `Invoke-FlowSchedule` ghép cứng tên `WinTrash.ps1` thay vì dùng `$PSCommandPath` như đường elevate - user giữ file dạng `WinTrash (1).ps1` sẽ có task trỏ file không tồn tại, fail im lặng. Giờ dùng `$PSCommandPath`.
- **Spinner nền vẽ đè báo cáo DevTrash**: khối in kết quả cuối `Invoke-ScanDevTrash` chạy khi spinner nền còn quay (không qua handshake như các chỗ khác) -> thi thoảng dòng báo cáo bị frame spinner chèn/lệch cột. Giờ in qua `Invoke-WithSpinnerPaused`.
- **Esc / Enter-không-chọn trong picker bị báo nhầm "Console không tương tác"**: mảng rỗng trả về từ `Show-CheckboxMenu` bị pipeline unwrap thành `$null` - trùng với sentinel dành cho console không tương tác. Bọc `,` khi return (đúng thông báo "Không chọn mục nào").

## [1.2.1] - 2026-07-06

### Thêm
- **Quét registry của user OFFLINE** (multi-user, cần admin): với user chưa đăng nhập, script nạp tạm `NTUSER.DAT` bằng `reg load` vào điểm gắn riêng (`HKU\WinTrash_Offline`), đọc Run/RunOnce rồi **unload ngay** (bọc try/finally + GC để nhả handle chắc chắn). Khi dọn cũng theo đúng chu trình nạp -> backup .reg -> xóa value -> nhả (RemoveKind `OfflineRegValue`). Hive đang bị khóa (user vừa đăng nhập) thì bỏ qua êm và báo rõ khi dọn.

## [1.2.0] - 2026-07-06

### Thêm
- **Quét đa user (multi-user)**: khi chạy với quyền Administrator trên máy có nhiều user, script hỏi có quét cả hồ sơ của họ không. Đồng ý thì mở rộng: thư mục mồ côi trong AppData (Roaming/Local/LocalLow/Programs) của từng user, shortcut Start Menu + Desktop, thư mục Startup, và Run/RunOnce key qua HKEY_USERS cho user đang đăng nhập. Mục của user khác được gắn nhãn [tên-user] trong danh sách chọn và tự nhận diện là cần Administrator khi dọn.

## [1.1.4] - 2026-07-06

### Sửa
- **Spinner khi GỠ cũng quay mượt**: vòng gỡ dùng spinner nền như vòng quét; các dòng kết quả √/× in qua cơ chế "suspend handshake" (spinner tự nhường console trong tích tắc rồi chạy tiếp) - mục xóa lâu không còn làm đứng hình.
- **App Paths "song sinh" WOW64**: nhiều key App Paths là bản chiếu giữa view 64-bit và WOW6432Node - xóa bản gốc thì bản chiếu biến mất theo, gây lỗi ảo "does not exist" ở lệnh xóa thứ hai. Giờ mỗi cặp gộp thành MỘT mục (RemoveKind RegKeyMulti) xóa mọi view còn tồn tại.
- **"Đã biến mất" = thành công**: RegKey/RegValue kiểm tra tồn tại trước khi xóa; key/value không còn (đã dọn trước đó, bản chiếu...) được tính OK thay vì báo lỗi.

## [1.1.3] - 2026-07-06

### Sửa
- **Màn hình lộn xộn sau khi bấm Enter**: 3 lớp phòng vệ mới - (1) `Clear-Screen` xóa triệt để cả viewport lẫn scrollback (ESC[2J + ESC[3J) thay cho Clear-Host chỉ xóa viewport, (2) spinner nền được bọc try/finally và có lưới `Stop-LeakedSpinner` dập spinner sót trước mỗi lần vẽ màn mới (trước đây module lỗi giữa chừng làm spinner sống dai, vẽ đè lên menu), (3) `Clear-PendingInput` nuốt các phím Enter bấm thừa trong buffer để không tự trả lời prompt kế tiếp.

## [1.1.2] - 2026-07-06

### Thêm
- **Tự động nâng quyền Administrator**: khi xác nhận dọn mà có mục cần admin, script hỏi "mở cửa sổ Admin?" - đồng ý thì lưu danh sách mục đã chọn, mở cửa sổ Administrator (UAC), quét lại nhanh và dọn đúng các mục đó (`-Action clean-resume`). Chọn n thì chỉ dọn phần làm được, không còn cảnh hàng trăm dòng "Access is denied".

### Sửa
- **Protocols xóa đúng hive**: HKCR là view gộp HKCU+HKLM Classes - xóa qua HKCR gây lỗi "subkey does not exist" giữa chừng; giờ xóa thẳng ở cả hai hive thật (backup .reg từng cái).
- **Recycle Bin fallback**: khi API Recycle của VisualBasic báo "not supported" (hay gặp với file trong ProgramData), tự chuyển sang copy-vào-backup rồi xóa - vẫn hoàn tác được.
- **Tắt progress bar hệ thống** (`$ProgressPreference = SilentlyContinue`): các cmdlet như Remove-NetFirewallRule không còn vẽ khối progress xanh đè lên giao diện.

## [1.1.1] - 2026-07-06

### Sửa
- **Spinner quét quay mượt liên tục**: chuyển animation sang runspace nền (80ms/frame) - không còn đứng hình khi module chạy lâu (Firewall ~16s). Luồng nền là người ghi duy nhất của dòng trạng thái, module chỉ cập nhật text qua hashtable đồng bộ.
- **Cài DevRadar/Claudefy hiển thị trực tiếp**: bỏ chế độ chạy ẩn + spinner; output npm/npx stream thẳng ra console và installer tương tác (Claudefy có menu) hoạt động bình thường - trước đây chạy trong cửa sổ ẩn khiến installer chờ phím mà người dùng tưởng bị treo.

## [1.1.0] - 2026-07-06

### Thêm
- **Tự động kiểm tra cập nhật**: sau khi chọn ngôn ngữ, script so phiên bản với file `VERSION` trên GitHub; có bản mới thì hỏi update/skip, đồng ý thì tải về thay thế (backup `.bak`) và tự khởi động lại. Lỗi mạng bỏ qua êm.
- **Wizard nhiều màn hình**: mỗi bước (ngôn ngữ -> vai trò -> menu) một màn hình sạch, banner giữ trên đỉnh; nút Quay lại ở bước vai trò (0) và menu chính (B = đổi ngôn ngữ/vai trò).

### Sửa
- **Picker hết cuộn màn hình**: vùng vẽ cố định + ẩn con trỏ + vẽ tối thiểu (Space vẽ lại 1 dòng, di chuyển vẽ 2 dòng) - mượt như các TUI hiện đại.

## [1.0.0] - 2026-07-06

Phiên bản đầu tiên — hợp nhất toàn bộ toolkit vào một file `WinTrash.ps1`.

### Tính năng
- **16 module quét tàn dư**: PATH, EnvVars, Folders (AppData/ProgramData mồ côi), Services, Startup, Tasks, Uninstall ghost, App Paths, Shortcuts, Firewall, Defender exclusions, root CA của proxy tool, IFEO, Native Messaging Hosts, URL Protocols, Vendor registry keys.
- **Dọn dẹp tương tác**: danh sách checkbox (↑↓/Space/A/N), lọc theo mức độ (F), ẩn vĩnh viễn vào `wintrash.ignore.json` (I). Không xóa gì cho tới khi xác nhận.
- **Backup mọi thứ trước khi xóa**: export `.reg`, `.xml` task (kèm manifest), PATH gốc, Recycle Bin cho file/thư mục → `WinTrashBackups\`.
- **Khôi phục** (`-Action restore`): import lại .reg, đăng ký lại task, khôi phục PATH từ bản backup chọn.
- **So sánh lịch sử quét**: mỗi lần scan lưu snapshot vào `ScanHistory\`, báo mục mới/mất so với lần trước (giữ 12 bản).
- **Dọn Temp an toàn**: chỉ file cũ hơn 24h trong User Temp / Windows Temp / CrashDumps.
- **Lịch quét hàng tháng**: tạo/xóa Scheduled Task tự chạy `-Action scan`.
- **Developer mode**: quét cache 15+ toolchain, phát hiện cache mồ côi của toolchain đã gỡ; cài DevRadar + Claudefy (spinner).
- **Sắp xếp Downloads**: chỉ file rời ở gốc, chọn nhóm bằng checkbox, undo script.
- **Đa ngôn ngữ UI**: Tiếng Việt / English / 中文 / Русский.
- **Giao diện terminal**: spinner braille, log kiểu npm/cargo, true-color ANSI (không bị theme remap), banner HASOFTWARE.
- Xuất báo cáo HTML/CSV/JSON.

### Kỹ thuật
- Một file duy nhất, tương thích Windows PowerShell 5.1 + PowerShell 7, UTF-8 BOM.
- Quét không cần Administrator; các thao tác dọn cần quyền sẽ báo rõ.
- Heuristic khớp app: bỏ dấu tiếng Việt, đường dẫn từ UninstallString/DisplayIcon, tiến trình đang chạy, LastAccessTime.
