# Changelog

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
