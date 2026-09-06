# PCB FlowTrack

Ứng dụng web quản lý công đoạn sản xuất PCB (bảng mạch in) — theo dõi nhiệm vụ, ca làm việc, và tiến độ sản xuất theo từng công đoạn. Dữ liệu dùng chung thật, nhiều người dùng đồng thời, lưu trên [Supabase](https://supabase.com) (Postgres + Auth + Row Level Security).

## Tính năng

- **Đăng nhập / Đăng ký** tài khoản người dùng — đăng ký xong chờ Admin duyệt
- **Quản lý nhiệm vụ**: tạo nhiệm vụ mới, phân công, theo dõi nhiệm vụ đã nhận, trao đổi qua chat
- **Ca làm việc**: bắt đầu/tạm dừng/hoàn thành tác vụ theo từng công đoạn, đo thời gian thực hiện
- **Dashboard**: thống kê thời gian trung bình mỗi công đoạn, xem chi tiết bản ghi, xuất báo cáo Excel
- **Dữ liệu chủ (Master data)**: quản lý bộ phận, công đoạn, bản vẽ, đơn hàng (Job), người dùng
- **Mua hàng (Purchasing)**: tải lên file PR/Xcode/PO — *hiện vẫn là dữ liệu mẫu tạm thời, chưa nối vào Supabase (sẽ làm ở giai đoạn kế tiếp)*

## Cài đặt Supabase (bắt buộc để chạy thật)

1. Tạo tài khoản + project miễn phí tại [supabase.com](https://supabase.com) (vùng gợi ý: Southeast Asia - Singapore).
2. Vào **SQL Editor**, chạy lần lượt 2 file trong `supabase/migrations/` theo đúng thứ tự số (0001 rồi 0002).
3. Vào **Authentication → Providers → Email**, tắt **Confirm email** (app dùng email giả `username@pcbflowtrack.local`, không có hộp thư thật để xác nhận).
4. Vào **Project Settings → API**, copy **Project URL** và **anon public key**, dán vào đầu file `index.html`:
   ```js
   window.supabase = supabase.createClient(
     'DÁN_PROJECT_URL_VÀO_ĐÂY',
     'DÁN_ANON_KEY_VÀO_ĐÂY'
   );
   ```
5. Tài khoản Admin đầu tiên: đăng ký một tài khoản bất kỳ qua giao diện app, sau đó vào Supabase → **Table Editor → profiles**, sửa dòng đó thành `role = admin`, `status = active`. Từ tài khoản Admin này, các tài khoản khác sẽ đăng ký rồi được duyệt ngay trong app.

## Chạy thử

Ứng dụng vẫn là một file HTML duy nhất (không build, không cài đặt gói) — sau khi cấu hình Supabase ở trên, chỉ cần mở trực tiếp trong trình duyệt:

```bash
open index.html
```

Hoặc truy cập qua GitHub Pages sau khi bật trong **Settings → Pages** của repo này.

## Công nghệ

- HTML/CSS/JavaScript thuần, không dùng framework
- [Supabase](https://supabase.com) — Postgres, Auth, Row Level Security
- [SheetJS (xlsx)](https://github.com/SheetJS/sheetjs) để đọc/ghi file Excel
- Font: IBM Plex Sans / IBM Plex Mono (Google Fonts)
