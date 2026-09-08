/* Service worker tối giản — chỉ để trình duyệt cho phép "Cài đặt ứng dụng"
   (thêm ra màn hình chính, mở như app riêng không có thanh địa chỉ).
   KHÔNG cache dữ liệu Supabase hay script CDN — app luôn cần dữ liệu mới
   nhất, chỉ cache đúng vỏ app (index.html + icon) để mở được ngay cả khi
   vừa mất mạng, thay vì màn hình lỗi trắng của trình duyệt. */
const CACHE_NAME = 'pcb-flowtrack-shell-v1';
const SHELL_FILES = ['./', './index.html', './manifest.webmanifest'];

self.addEventListener('install', (event) => {
  event.waitUntil(
    caches.open(CACHE_NAME).then((cache) => cache.addAll(SHELL_FILES)).catch(() => {})
  );
  self.skipWaiting();
});

self.addEventListener('activate', (event) => {
  event.waitUntil(
    caches.keys().then((keys) =>
      Promise.all(keys.filter((k) => k !== CACHE_NAME).map((k) => caches.delete(k)))
    )
  );
  self.clients.claim();
});

self.addEventListener('fetch', (event) => {
  if (event.request.method !== 'GET') return;
  if (event.request.mode !== 'navigate') return; // chỉ can thiệp khi mở/tải lại trang
  event.respondWith(
    fetch(event.request).catch(() => caches.match('./index.html'))
  );
});
