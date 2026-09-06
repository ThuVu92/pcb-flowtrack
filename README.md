# PCB FlowTrack

Ứng dụng web quản lý công đoạn sản xuất PCB (bảng mạch in) — theo dõi nhiệm vụ, ca làm việc, và tiến độ sản xuất theo từng công đoạn.

## Tính năng

- **Đăng nhập / Đăng ký** tài khoản người dùng
- **Quản lý nhiệm vụ**: tạo nhiệm vụ mới, phân công, theo dõi nhiệm vụ đã nhận
- **Ca làm việc**: xem các nhiệm vụ đang thực hiện và đã hoàn thành trong ngày
- **Dashboard**: thống kê thời gian trung bình mỗi công đoạn, xem chi tiết bản ghi
- **Mua hàng (Purchasing)**: tải lên file PR, Xcode, PO
- **Dữ liệu chủ (Master data)**: quản lý bộ phận, danh sách người dùng

## Chạy thử

Đây là ứng dụng một file HTML độc lập (không cần cài đặt hay build). Chỉ cần mở trực tiếp trong trình duyệt:

```bash
open pcb-flowtrack.html
```

## Công nghệ

- HTML/CSS/JavaScript thuần, không dùng framework
- [SheetJS (xlsx)](https://github.com/SheetJS/sheetjs) để đọc/ghi file Excel
- Font: IBM Plex Sans / IBM Plex Mono (Google Fonts)
