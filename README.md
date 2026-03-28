# Yamore

Yacht reservation platform: **Flutter** client, **.NET 8** API, **SQL Server**, **RabbitMQ** worker, optional **Stripe** and **SMTP**.

## Repository layout

| Path | What it is |
|------|------------|
| **`Yamore/`** | Main solution: API, services, worker, `docker-compose.yml`, detailed docs |
| **`Yamore/UI/yamore_mobile`** | Flutter app (admin desktop + mobile flows) |

**Start here for setup:** [Yamore/README.md](Yamore/README.md) — Docker Compose, local run, test accounts, Stripe/SMTP, troubleshooting.

---

## Quick start (Docker)

1. Install **Docker Desktop** (Windows: use **WSL2 backend** if you hit TLS or networking issues with Linux containers).
2. Open a terminal in the **`Yamore`** folder (the one that contains `docker-compose.yml`).
3. Optional: copy `Yamore/.env.example` → `Yamore/.env` and set Stripe/SMTP if you need card payments or emails.
4. Run:

```bash
cd Yamore
docker compose up -d --build
```

5. Wait until containers are healthy (first SQL Server pull can take several minutes).
6. API: **http://localhost:5096** (Swagger in Development: `/swagger`).
7. Run the Flutter app (defaults to `http://localhost:5096` on Windows; Android emulator uses `http://10.0.2.2:5096` automatically):

```bash
cd Yamore/UI/yamore_mobile
flutter pub get
flutter run
```

Use `--dart-define=API_BASE_URL=...` only if the API is not on the default host/port.

---

## If Docker misbehaves

Common causes and fixes are documented in **[Yamore/README.md](Yamore/README.md)** under *Docker troubleshooting*, including:

- Running compose from the **wrong directory** (build context / missing project file).
- **Ports** already in use (`1433`, `5096`, `5672`).
- SQL **TLS / handshake** errors (host and Docker settings).
- **Empty database / invalid object name** — the API applies EF migrations on startup so a new volume gets schema; if migration still fails, see the troubleshooting section.

---

## Configuration (no secrets in source)

- **Backend:** connection string, RabbitMQ, Stripe, SMTP → `appsettings`, environment variables, or `Yamore/.env` for Compose. See [Yamore/CONFIGURATION.md](Yamore/CONFIGURATION.md).
- **Flutter:** optional **`--dart-define=API_BASE_URL=...`** to override the dev default (`Yamore/README.md`).

---

## Test logins

See **Test credentials** in [Yamore/README.md](Yamore/README.md) (admin, end users, yacht owners).
