# Yamore

Yamore is a yacht reservation platform with:
- `Yamore.API` (main REST API)
- `Yamore.Worker` (auxiliary background service consuming RabbitMQ messages)
- `UI/yamore_mobile` (Flutter client used for admin/desktop and mobile UI)

## Submission Checklist Coverage

- Admin reporting with export/print: implemented (`Export report` on admin dashboard)
- Mobile booking flow + booking history + profile edit: implemented
- Recommendation module: implemented
- RabbitMQ microservice architecture: implemented (API publisher + Worker consumer)
- Email notifications (reservation created, payment confirmed): implemented

## Prerequisites

- .NET SDK 8
- Flutter SDK (stable)
- Docker Desktop

## Run With Docker Compose (recommended)

**Important:** run all `docker compose` commands from the **`Yamore`** directory (the folder that contains `docker-compose.yml`). If you run them from the repo root or the wrong path, you may see **MSB1009** (project file not found) or a broken build context.

From repository root (`Yamore`):

1. **Card payments (optional):** copy `.env.example` to `.env` and set your Stripe **test** keys (`STRIPE_SECRET_KEY`, `STRIPE_PUBLISHABLE_KEY`). If you skip this, bookings still work with **Pay on arrival**; the app will show *Payment configuration missing* for card checkout.
2. **Email from Worker (optional):** in `.env`, set `SMTP_HOST`, `SMTP_USER_NAME`, `SMTP_PASSWORD`, and `SMTP_FROM_ADDRESS` (see `.env.example`). If `SMTP_HOST` is empty, reservations still work; the worker logs *Skipping email`.
3. Start stack:

```bash
docker compose up -d --build
```

After changing `.env`, recreate containers so env is applied, e.g. `docker compose up -d --force-recreate api worker` (or `--build` if you changed code).

**Database schema:** on startup the API runs **EF Core `Migrate()`** so a new SQL Server volume gets tables and indexes. You should not see **Invalid object name** on a fresh compose stack unless SQL is unreachable or migrations fail (check API logs: `docker compose logs api`).

Services started:
- SQL Server: `localhost:1433`
- RabbitMQ broker: `localhost:5672`
- RabbitMQ management UI: `http://localhost:15672` (`guest/guest`)
- API: `http://localhost:5096`

To stop:

```bash
docker compose down
```

## Run Locally Without Docker Compose

1. Start SQL Server (local instance).
2. Start RabbitMQ:
   ```bash
   docker run -d --name yamore-rabbitmq -p 5672:5672 -p 15672:15672 rabbitmq:3-management
   ```
3. Configure `ConnectionStrings:DefaultConnection` and other secrets using User Secrets or environment variables.
4. Start API:
   ```bash
   cd Yamore.API
   dotnet run
   ```
5. Start Worker (separate terminal):
   ```bash
   cd Yamore.Worker
   dotnet run
   ```
6. Start Flutter app:
   ```bash
   cd UI/yamore_mobile
   flutter pub get
   flutter run
   ```
   Defaults match local API on port 5096. Override if needed: `--dart-define=API_BASE_URL=http://...`

## Test Credentials

Use these accounts during evaluation:

- Desktop/Admin:
  - Username: `zerina`
  - Password: `Zerina123!`
- Mobile/Users:
  - Username: `zara`
  - Password: `Zara123!`
  - Username: `arman`
  - Password: `Arman123!`
  - Username: `faris`
  - Password: `Faris123!`
- Additional roles (Yacht Owner):
  - Username: `antonio`
  - Password: `Antonio123!`
  - Username: `julian`
  - Password: `Julian123!`

If your seeded users differ, adjust this section before submission so evaluators can log in immediately.

## Required Configuration (Single Source via appsettings/env)

Do not hardcode credentials in code.

- `ConnectionStrings:DefaultConnection`
- `RabbitMQ:*`
- `Smtp:*`
- `Stripe:SecretKey`
- `Stripe:PublishableKey`
- Flutter API address: defaults to `localhost:5096` (desktop) / `10.0.2.2:5096` (Android emulator); override with `flutter run --dart-define=API_BASE_URL=http://...`

See `CONFIGURATION.md` for key-by-key details.

## RabbitMQ and Worker Verification

When creating reservation and confirming payment, Worker logs should contain:
- `Processing message type: ReservationCreated`
- `Processing message type: PaymentCompleted`

If SMTP is configured, logs should also contain:
- `Email sent to ... subject: Reservation received`
- `Email sent to ... subject: Payment confirmed`

## Troubleshooting

- **“Payment configuration missing”** (mobile, card checkout): the API has no `Stripe:PublishableKey`. With Docker Compose, add keys to `Yamore/.env` as in `.env.example` and restart the `api` service. Without Docker, set User Secrets or env vars for `Stripe:SecretKey` and `Stripe:PublishableKey`, or use **Pay on arrival**.

### Docker

| Symptom | What to try |
|--------|-------------|
| **MSB1009 / project file does not exist** | Run `docker compose` from the **`Yamore`** folder (same level as `docker-compose.yml`), not from the parent repo root. |
| **Port already allocated** | Stop other SQL Server / services using `1433`, `5096`, or `5672`, or change host ports in `docker-compose.yml`. |
| **SQL pre-login handshake / TLS (-2146893019)** | Often host–container TLS or corporate SSL inspection. Ensure Docker Desktop uses **WSL2** (Windows). Try updating Docker; ensure firewall allows Docker. SQL image logs: `docker compose logs sqlserver`. |
| **Invalid object name (208)** | Usually DB empty or migration failed. Check `docker compose logs api` — migrations run at startup. Ensure `sqlserver` is **healthy** before `api` starts (`depends_on` in compose). Retry: `docker compose restart api`. |
| **API exits or worker loops** | `docker compose logs -f api` and `docker compose logs -f worker`. RabbitMQ must be up; Worker waits for RabbitMQ. |
| **Flutter can’t reach API** | Start the API (`docker compose` or `dotnet run`). On Windows, default URL is `http://localhost:5096`. Use `--dart-define=API_BASE_URL=...` only if the API is elsewhere. |
| **API crash: “There is already an object named 'Roles'” (2714)** | The **SQL Server volume** still has tables from an old run, but **EF thinks** it must create them again. **Dev fix (deletes Docker DB data only):** `docker compose down -v` then `docker compose up -d --build`. Your **source code on disk is unchanged**. |

## Notes for Evaluators

- RabbitMQ UI: `http://localhost:15672` (`guest/guest`)
- API Swagger (development): `http://localhost:5096/swagger`
- **Stripe test checkout:** ensure test keys are configured (see `.env.example`), then use the sample card and fields in **`PAYMENTS.md` → *Testing card checkout*** (or [Stripe testing docs](https://docs.stripe.com/testing)).
- Core functionalities are available without code edits when configuration is provided through environment/appsettings.
