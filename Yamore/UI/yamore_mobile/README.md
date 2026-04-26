# yamore_mobile (Flutter)

Client for Yamore: admin/desktop and mobile flows.

## API URL

- **Local development:** run as usual — no flags required:
  ```bash
  flutter pub get
  flutter run
  ```
  - Web: **`http://localhost:5096`**; Windows (desktop) / iOS simulator: **`http://localhost:5096`**
  - Android emulator: **`http://10.0.2.2:5096`**
  - Port is [defaultDevApiPort](lib/config.dart) (must match `Yamore.API/Properties/launchSettings.json` and `docker-compose.yml` when using Docker)

- **Staging / production / custom host:** override at build time:
  ```bash
  flutter run --dart-define=API_BASE_URL=https://your-api.example.com
  flutter build apk --dart-define=API_BASE_URL=https://your-api.example.com
  ```

Full stack (Docker, database `.bak`, ports, configuration): **[../../../README.md](../../../README.md)** (repository root).
