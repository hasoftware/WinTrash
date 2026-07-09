# WinTrash Toolkit

**Một file PowerShell duy nhất** quét 18 loại tàn dư ứng dụng trên Windows và dọn dẹp **có chọn lọc từng mục** — bạn tự tick bằng phím Space, không có chuyện tự động xóa mọi thứ.

![Quét 18 loại tàn dư](assets/scan.png)

> **Triết lý an toàn:** Quét chỉ đọc -> bạn chọn từng mục bằng checkbox -> xác nhận -> mới xóa (luôn backup .reg/.xml/Recycle Bin trước).

## Cài đặt & chạy lần đầu

> **Quan trọng khi tải file từ mạng:** Windows đánh dấu file tải về và chặn chạy script. Mở PowerShell tại thư mục chứa file và gỡ chặn trước:
>
> ```powershell
> Unblock-File .\WinTrash.ps1
> ```
>
> Nếu gặp lỗi *"running scripts is disabled on this system"*, cho phép script đã ký/cục bộ chạy (chỉ cần làm một lần):
>
> ```powershell
> Set-ExecutionPolicy RemoteSigned -Scope CurrentUser
> ```

```powershell
.\WinTrash.ps1
```

1. Chọn **ngôn ngữ**: Tiếng Việt / English / 中文 / Русский
2. Chọn **vai trò**:
   - **User** — quét & dọn tàn dư, sắp xếp Downloads
   - **Developer** — thêm: quét cache toolchain (npm/NuGet/Gradle/pip...), cài [DevRadar](https://github.com/hasoftware/DevRadar) và [Claudefy](https://github.com/hasoftware/Claudefy) (có spinner tiến trình)

Chạy tự động không cần menu:
```powershell
.\WinTrash.ps1 -Language vi -Role Developer -Action scan     # chỉ quét + báo cáo HTML
.\WinTrash.ps1 -Language vi -Role User -Action clean         # quét + chọn + dọn
```

## Dọn dẹp tương tác (điểm nhấn chính)

Sau khi quét, mọi mục có thể dọn hiện thành **danh sách checkbox**:

![Danh sách chọn tương tác](assets/picker.png)

| Phím | Chức năng |
|---|---|
| Phím mũi tên / PgUp / PgDn | Di chuyển |
| **Space** | Chọn / bỏ chọn mục |
| A / N | Chọn tất cả / bỏ tất cả |
| **F** | Lọc theo mức độ (All -> High -> Medium -> Info) |
| **I** | Ẩn mục này vĩnh viễn (ghi vào `wintrash.ignore.json` — không báo lại ở các lần quét sau) |
| **Enter** | Xác nhận (hỏi lại y/N lần cuối) |
| Esc | Hủy, không làm gì |

Cột mức độ tô màu: **High** đỏ | **Medium** vàng | **Info** xanh dương.

**Chưa có gì bị xóa cho tới khi bạn Enter + gõ `y`.** Mỗi lần dọn tạo thư mục `WinTrashBackups\<timestamp>\` chứa: export `.reg` của mọi key/value bị xóa, `.xml` của task, PATH gốc, log đầy đủ. Thư mục/file thì vào Recycle Bin.

## 18 loại tàn dư được quét

| Nhóm | Modules |
|---|---|
| Môi trường | PATH chết, biến môi trường chết (JAVA_HOME...) |
| Đĩa | Thư mục mồ côi AppData/LocalLow/ProgramData |
| Tự khởi động | Services, Run-key + Startup folder, Scheduled Tasks |
| Registry | Mục "ma" Add/Remove, App Paths, URL Protocols, Vendor keys |
| Giao diện | Shortcuts chết (Start Menu/Desktop) |
| **Bảo mật** | Defender exclusions mồ côi, root CA của proxy tool (Burp/Fiddler), IFEO debugger hijack, Native Messaging Hosts hỏng |
| Mạng | Firewall rules mồ côi |
| Container / WSL | Tàn dư Docker Desktop đã gỡ (kho dữ liệu, distro `docker-desktop*`); distro WSL mồ côi trong Lxss, dữ liệu `ext4.vhdx` không còn đăng ký, thư mục WSL1 legacy |

Mức độ: **High** = hỏng khách quan (đích không tồn tại) | **Medium** = heuristic, cần bạn xem xét | **Info** = tham khảo. Chứng chỉ (Certs) không bao giờ bị xóa tự động — chỉ báo cáo, xóa tay qua `certmgr.msc`.

Báo cáo HTML xuất kèm sau mỗi lần quét:

![Báo cáo HTML](assets/report.png)

## Các tiện ích đi kèm

- **Khôi phục** (`-Action restore` hoặc menu): chọn bản backup trong `WinTrashBackups\` -> tự import lại `.reg`, đăng ký lại scheduled task, khôi phục PATH.
- **So sánh lịch sử**: mỗi lần quét lưu snapshot vào `ScanHistory\` (giữ 12 bản) và báo *"+N mục mới, M mục biến mất so với lần quét trước"* — biến tool thành máy giám sát sức khỏe hệ thống.
- **Dọn Temp an toàn** (`-Action temp`): chỉ xóa file cũ hơn 24 giờ trong User Temp / Windows Temp / CrashDumps, file đang bị khóa tự bỏ qua.
- **Lịch quét hàng tháng** (`-Action schedule`): tạo/xóa Scheduled Task tự chạy quét ngày 1 hằng tháng.

## Sắp xếp Downloads

Chỉ đụng **file rời ở gốc** Downloads (không bao giờ đụng thư mục con), phân nhóm Documents/Images/Videos/Installers..., bạn **chọn nhóm nào muốn áp dụng** bằng checkbox, file không rõ loại để yên, luôn sinh script `Undo-Downloads_*.ps1` để hoàn tác.

## Developer mode

- Phát hiện 15+ toolchain; cache của toolchain **đã gỡ** (Gradle, Cargo... mồ côi) đưa vào danh sách checkbox để dọn; cache của toolchain **đang dùng** chỉ hiện lệnh dọn chính chủ (`npm cache clean --force`, `dotnet nuget locals all --clear`...) — không tự xóa.
- Cài DevRadar / Claudefy qua npm với spinner, tự kiểm tra Node.js >= 18, log cài đặt đầy đủ.

## Yêu cầu & Lưu ý

- Windows PowerShell 5.1 hoặc PowerShell 7+ (file lưu UTF-8 BOM).
- Không cần Administrator để quét; một số mục khi **dọn** (service, HKLM, PATH Machine, Defender) cần chạy admin — mục lỗi sẽ được báo để chạy lại elevated.
- Heuristic không hoàn hảo: nhóm Medium có thể chứa app portable — luôn đọc kỹ trước khi tick.
- Thư mục `legacy\` chứa các script rời phiên bản cũ (đã được hợp nhất vào `WinTrash.ps1`).

## Giấy phép

MIT — dùng, sửa, chia sẻ tự do.
