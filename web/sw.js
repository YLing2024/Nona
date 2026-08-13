// I-04：Nona PWA Service Worker——应用外壳缓存 + 版本控制 + 更新提示。
// 由 index.html 注册；发布版本号作为缓存版本（构建时写入）。
const CACHE_NAME = 'nona-app-shell-v1.3.0';

// 应用外壳：首屏所需的最小资源（index.html 经 flutter_bootstrap 引导）
const APP_SHELL = [
  './',
  './index.html',
  './manifest.json',
  './flutter_bootstrap.js',
  './main.dart.js',
  './icons/Icon-192.png',
  './icons/Icon-512.png',
  './favicon.png',
];

// 安装：预缓存应用外壳（失败不阻塞）
self.addEventListener('install', (event) => {
  event.waitUntil(
    caches.open(CACHE_NAME).then((cache) => cache.addAll(APP_SHELL)).then(
      () => self.skipWaiting(),
    ).catch(() => {}),
  );
});

// 激活：清理旧版本缓存
self.addEventListener('activate', (event) => {
  event.waitUntil(
    caches.keys().then((keys) =>
      Promise.all(
        keys
          .filter((key) => key.startsWith('nona-app-shell-') && key !== CACHE_NAME)
          .map((key) => caches.delete(key)),
      ),
    ).then(() => self.clients.claim()),
  );
});

// 请求策略：应用外壳走 cache-first（离线可用）；其余网络优先 + 缓存回退
self.addEventListener('fetch', (event) => {
  const { request } = event;
  if (request.method !== 'GET') return;
  const url = new URL(request.url);
  if (url.origin !== self.location.origin) return;

  // 外壳资源：cache-first
  const isShell = APP_SHELL.some(
    (path) => url.pathname.endsWith(path) || url.pathname === path,
  );
  if (isShell) {
    event.respondWith(
      caches.match(request).then(
        (cached) =>
          cached ||
          fetch(request).then((response) => {
            const copy = response.clone();
            caches.open(CACHE_NAME).then((cache) => cache.put(request, copy));
            return response;
          }),
      ),
    );
    return;
  }

  // 其余：network-first，失败回退缓存
  event.respondWith(
    fetch(request)
      .then((response) => {
        if (response.ok) {
          const copy = response.clone();
          caches.open(CACHE_NAME).then((cache) => cache.put(request, copy));
        }
        return response;
      })
      .catch(() => caches.match(request)),
  );
});

// 更新提示：新版本激活后通知页面
self.addEventListener('message', (event) => {
  if (event.data === 'SKIP_WAITING') {
    self.skipWaiting();
  }
});
