# Mô tả

<!-- Thay đổi gì và vì sao? Nếu sửa lỗi từ issue, ghi: Fixes #số -->

## Loại thay đổi

- [ ] Sửa lỗi (bugfix)
- [ ] Tính năng mới
- [ ] Tài liệu / dịch thuật
- [ ] Refactor (không đổi hành vi)

## Checklist

- [ ] Đã test trên **Windows PowerShell 5.1** và **PowerShell 7**
- [ ] Đã test **cả hai kiểu chạy**: gõ `.\WinTrash.ps1` trong console VÀ `powershell -File WinTrash.ps1` (hai kiểu đặt hàm vào scope khác nhau — xem CONTRIBUTING.md)
- [ ] File `.ps1` giữ nguyên **UTF-8 BOM**
- [ ] `Invoke-Pester -Path tests\` xanh trên cả 2 engine
- [ ] Chuỗi UI mới (nếu có) đủ 4 ngôn ngữ vi/en/zh/ru
- [ ] Thay đổi hành vi: đã cập nhật `CHANGELOG.md` + bump version trong script và file `VERSION`
- [ ] Không vi phạm nguyên tắc an toàn: không tự động xóa, xóa phải qua checkbox + xác nhận + backup
