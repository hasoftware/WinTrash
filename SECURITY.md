# Chính sách bảo mật

## Phiên bản được hỗ trợ

Chỉ phiên bản mới nhất trên nhánh `main` được hỗ trợ vá lỗi bảo mật. Script có cơ chế tự cập nhật: chạy `WinTrash.ps1`, sau bước chọn ngôn ngữ tool sẽ tự so phiên bản và đề nghị cập nhật khi có bản mới.

| Phiên bản | Hỗ trợ |
| --------- | ------ |
| Mới nhất (main) | Có |
| Cũ hơn | Không — hãy cập nhật |

## Báo cáo lỗ hổng

**Đừng mở issue công khai cho lỗ hổng bảo mật.** Thay vào đó:

- Dùng tab **Security → Report a vulnerability** của repo (báo cáo riêng tư), hoặc
- Email: **hoanganhuet@hotmail.com** với tiêu đề bắt đầu bằng `[SECURITY]`

Vui lòng mô tả: điều kiện tái hiện, phạm vi ảnh hưởng (file/registry nào bị đụng tới), và bản WinTrash + PowerShell bạn dùng. Bạn sẽ nhận phản hồi trong vòng 7 ngày; lỗ hổng xác nhận sẽ được vá sớm nhất có thể và ghi công người báo cáo (nếu muốn) trong CHANGELOG.

## Thiết kế an toàn của tool

Các nguyên tắc mà mọi thay đổi code đều phải giữ — nếu bạn thấy hành vi vi phạm những điều dưới đây thì đó là bug bảo mật, hãy báo:

- **Quét chỉ đọc.** Bước scan không sửa/xóa bất cứ thứ gì trên hệ thống.
- **Không tự động xóa.** Mọi mục xóa phải được người dùng tick chọn thủ công và xác nhận y/N lần cuối.
- **Luôn backup trước khi xóa**: registry export `.reg`, scheduled task export `.xml`, PATH gốc lưu file, file/thư mục vào Recycle Bin — tất cả trong `WinTrashBackups\<timestamp>\`, khôi phục được bằng `-Action restore`.
- **Không thu thập dữ liệu.** Tool không gửi bất kỳ thông tin nào ra ngoài. Kết nối mạng duy nhất là đọc file `VERSION` và tải bản mới từ chính repo GitHub này khi bạn đồng ý cập nhật.
- **Chứng chỉ (Certs) không bao giờ bị xóa tự động** — chỉ báo cáo để bạn tự xử lý qua `certmgr.msc`.
- Mã nguồn là **một file PowerShell duy nhất, không obfuscate** — bạn có thể (và nên) đọc trước khi chạy.
