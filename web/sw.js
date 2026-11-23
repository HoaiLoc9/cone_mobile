// COne PWA Service Worker for Push Notifications
const CACHE_NAME = 'cone-pwa-v2';

self.addEventListener('install', (event) => {
  self.skipWaiting();
});

self.addEventListener('activate', (event) => {
  event.waitUntil(self.clients.claim());
});

/**
 * Chuẩn hóa tiêu đề & nội dung thông báo gọn đẹp trên màn hình khóa iOS / Android:
 * - Không để tiêu đề dài bị cắt "..."
 * - Đưa số điểm cộng lên tiêu đề (vd: "Cộng +3 điểm rèn luyện")
 * - Nội dung chỉ còn 1–2 dòng súc tích (vd: "Hội thảo kỹ năng viết CV • HK2 2025-2026")
 */
function formatConeNotification(rawTitle, rawBody) {
  let title = (rawTitle || 'Thông báo mới').toString().trim();
  let body = (rawBody || '').toString().trim();

  // Mẫu cộng điểm ĐRL từ hệ thống:
  // Title: "Cộng điểm DRL: Hội thảo..."
  // Body:  "Tham gia đầy đủ hoạt động "Tên HĐ" (HK2 2025-2026). Được cộng 3 điểm rèn luyện."
  const isDrlBonus =
    /cộng điểm/i.test(title) || /được cộng\s+\d+/i.test(body);

  if (isDrlBonus) {
    const ptsMatch = body.match(/(?:được\s+cộng|\+)\s*(\d+(?:[.,]\d+)?)\s*điểm/i);
    const actMatch = body.match(/[""]([^""]+)[""]/);
    const semMatch = body.match(/\((HK[^)]+)\)/i);

    if (ptsMatch) {
      title = `Cộng +${ptsMatch[1]} điểm rèn luyện`;
    } else {
      title = 'Cộng điểm rèn luyện';
    }

    if (actMatch) {
      const actName = actMatch[1].trim();
      const sem = semMatch ? semMatch[1].trim() : '';
      body = sem ? `${actName} • ${sem}` : actName;
    }
  } else if (title.length > 30 && title.includes(':')) {
    // Nếu tiêu đề có dạng "Loại thông báo: Nội dung dài..." thì tách phần dài xuống body
    const idx = title.indexOf(':');
    const prefix = title.slice(0, idx).trim();
    const rest = title.slice(idx + 1).trim();
    if (prefix.length >= 4 && prefix.length <= 26) {
      title = prefix;
      if (rest && !body.toLowerCase().includes(rest.toLowerCase())) {
        body = body ? `${rest} • ${body}` : rest;
      }
    }
  }

  return { title, body };
}

// Xử lý khi người dùng chạm vào thông báo trên iOS / Android / Desktop
self.addEventListener('notificationclick', (event) => {
  event.notification.close();
  event.waitUntil(
    clients.matchAll({ type: 'window', includeUncontrolled: true }).then((clientList) => {
      for (const client of clientList) {
        if ('focus' in client) {
          return client.focus();
        }
      }
      if (clients.openWindow) {
        return clients.openWindow('./');
      }
    })
  );
});

// Nhận lệnh hiển thị thông báo từ trang web
self.addEventListener('message', (event) => {
  if (event.data && event.data.type === 'SHOW_NOTIFICATION') {
    const formatted = formatConeNotification(event.data.title, event.data.body);
    const options = {
      body: formatted.body,
      icon: event.data.icon || 'icons/Icon-192.png',
      badge: event.data.badge || 'icons/Icon-192.png',
      vibrate: [180, 90, 180],
      tag: 'cone-' + Date.now(),
      renotify: true,
      data: event.data.data || {}
    };
    self.registration.showNotification(formatted.title, options);
  }
});

// Lắng nghe sự kiện Push từ máy chủ khi tắt app
self.addEventListener('push', (event) => {
  let data = {};
  if (event.data) {
    try {
      data = event.data.json();
    } catch (_) {
      data = { title: 'Thông báo mới', body: event.data.text() };
    }
  }
  const formatted = formatConeNotification(
    data.title || 'Thông báo mới',
    data.body || data.message || 'Bạn có thông báo mới từ Nhà trường.'
  );
  const options = {
    body: formatted.body,
    icon: 'icons/Icon-192.png',
    badge: 'icons/Icon-192.png',
    vibrate: [180, 90, 180],
    tag: 'cone-push-' + Date.now(),
    renotify: true,
    data: data
  };
  event.waitUntil(self.registration.showNotification(formatted.title, options));
});
