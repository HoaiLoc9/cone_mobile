// COne PWA Service Worker for Push Notifications
const CACHE_NAME = 'cone-pwa-v1';

self.addEventListener('install', (event) => {
  self.skipWaiting();
});

self.addEventListener('activate', (event) => {
  event.waitUntil(self.clients.claim());
});

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
    const title = event.data.title || 'COne';
    const options = {
      body: event.data.body || '',
      icon: event.data.icon || 'icons/Icon-192.png',
      badge: event.data.badge || 'icons/Icon-192.png',
      vibrate: [200, 100, 200],
      tag: 'cone-' + Date.now(),
      renotify: true,
      data: event.data.data || {}
    };
    self.registration.showNotification(title, options);
  }
});
