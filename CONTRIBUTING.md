# Đóng góp cho WinTrash

Cảm ơn bạn quan tâm đến dự án. Mọi hình thức đóng góp đều được chào đón: báo lỗi, đề xuất tính năng, sửa tài liệu, dịch thuật hay gửi code.

## Báo lỗi

Dùng mẫu **Báo lỗi** khi tạo issue. Ba thông tin quan trọng nhất (đừng bỏ qua):

1. **Engine**: Windows PowerShell 5.1 hay PowerShell 7.x (`$PSVersionTable.PSVersion`)
2. **Cách chạy script**: gõ `.\WinTrash.ps1` trong console, `powershell -File ...`, hay chuột phải Run with PowerShell — cùng một lỗi có thể chỉ xuất hiện ở MỘT cách chạy (xem issue #1)
3. **Thông báo lỗi nguyên văn** (copy cả khối đỏ)

## Môi trường phát triển

- Windows 10/11, cài cả **Windows PowerShell 5.1** (có sẵn) lẫn **PowerShell 7** — mọi thay đổi phải chạy được trên cả hai.
- Test: `Install-Module Pester -MinimumVersion 5.0 -Scope CurrentUser` rồi chạy `Invoke-Pester -Path tests\` trên **cả hai engine**.
- CI (GitHub Actions) tự chạy: parse check 2 engine, PSScriptAnalyzer (mức Error), Pester.

## Quy tắc bắt buộc khi sửa `WinTrash.ps1`

Đây là các bẫy có thật mà dự án từng dính — CI và test sẽ chặn một phần, phần còn lại nhờ bạn tự kiểm:

- **Giữ nguyên UTF-8 BOM.** File mất BOM sẽ vỡ cú pháp trên PS 5.1 (bị đọc thành CP1252, ký tự tiếng Việt biến thành smart-quote). Editor phải để chế độ "UTF-8 with BOM".
- **Một file duy nhất.** Không tách module, không thêm file phụ thuộc lúc chạy.
- **Không dùng `.GetNewClosure()`.** Closure bị buộc vào dynamic module nên mất khả năng gọi hàm ở script scope — lỗi chỉ hiện khi chạy `.\WinTrash.ps1` trực tiếp (issue #1). Có test AST chặn sẵn.
- **Test cả hai kiểu chạy**: `powershell -File WinTrash.ps1` VÀ gõ `.\WinTrash.ps1` trong console. Hai kiểu này đặt hàm vào scope khác nhau (global vs script).
- **In ra console khi spinner nền đang quay phải qua `Invoke-WithSpinnerPaused`**, không `Write-Host` thẳng — nếu không frame spinner sẽ vẽ đè dòng của bạn.
- **Chuỗi UI mới phải đủ 4 ngôn ngữ** (vi/en/zh/ru) trong bảng `$Strings`.
- **Không bao giờ tự động xóa.** Mọi thao tác xóa phải đi qua danh sách checkbox + xác nhận y/N + backup (.reg/.xml/Recycle Bin) — đây là nguyên tắc thiết kế cốt lõi của tool.
- Gọi exe native có tham số chứa nháy kép (schtasks...) cần lưu ý `PSNativeCommandArgumentPassing` trên pwsh 7.3+ (xem các đoạn đã có trong code làm mẫu).
- Tự tham chiếu file script dùng `$PSCommandPath`, không ghép cứng tên file.

## Quy trình Pull Request

1. Fork / tạo branch từ `main` (ví dụ `fix/ten-loi`, `feat/ten-tinh-nang`).
2. Sửa code + chạy Pester trên cả 2 engine.
3. Nếu thay đổi hành vi: thêm mục vào `CHANGELOG.md` và bump `$script:WinTrashVersion` trong script + file `VERSION` (hai chỗ phải khớp — cơ chế self-update đọc file `VERSION`).
4. Mở PR vào `main`, điền theo mẫu có sẵn. CI phải xanh.
5. PR được merge kiểu **rebase** để giữ lịch sử tuyến tính.

## Dịch thuật

UI hiện có tiếng Việt, English, 中文, Русский. Muốn thêm ngôn ngữ mới: thêm một khóa vào bảng `$Strings` với đầy đủ các chuỗi (lấy khóa `en` làm gốc) và cập nhật menu chọn ngôn ngữ.
