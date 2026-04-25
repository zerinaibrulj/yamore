# yamore_mobile (Flutter)

Client for Yamore: admin/desktop and mobile flows.

## API URL

- **Local development:** run as usual — no flags required:
  ```bash
  flutter pub get
  flutter run
  ```
  - Windows / iOS simulator / web: defaults to **`http://localhost:5096`**
  - Android emulator: defaults to **`http://10.0.2.2:5096`** (reaches the API on your PC)

- **Staging / production / custom host:** override at build time:
  ```bash
  flutter run --dart-define=API_BASE_URL=https://your-api.example.com
  flutter build apk --dart-define=API_BASE_URL=https://your-api.example.com
  ```

Full stack (Docker, database `.bak`, ports, configuration): **[../../../README.md](../../../README.md)** (repository root).
