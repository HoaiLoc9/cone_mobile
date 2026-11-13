# COne Mobile

Flutter mobile app kết nối backend Laravel đã deploy tại `https://cofer.io.vn`.

## API Config

Mặc định app dùng:

- Web URL: `https://cofer.io.vn`
- Mobile API Base URL: `https://cofer.io.vn/api/mobile`

Chạy app với cấu hình deploy:

```powershell
flutter run --dart-define=API_BASE_URL=https://cofer.io.vn/api/mobile --dart-define=WEB_URL=https://cofer.io.vn
```

Build APK release:

```powershell
flutter build apk --release --dart-define=API_BASE_URL=https://cofer.io.vn/api/mobile --dart-define=WEB_URL=https://cofer.io.vn
```

Build web:

```powershell
flutter build web --dart-define=API_BASE_URL=https://cofer.io.vn/api/mobile --dart-define=WEB_URL=https://cofer.io.vn
```
