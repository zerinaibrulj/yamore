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

From repository root (`Yamore`):

1. **Card payments (optional):** copy `.env.example` to `.env` and set your Stripe **test** keys (`STRIPE_SECRET_KEY`, `STRIPE_PUBLISHABLE_KEY`). If you skip this, bookings still work with **Pay on arrival**; the app will show *Payment configuration missing* for card checkout.
2. **Email from Worker (optional):** in `.env`, set `SMTP_HOST`, `SMTP_USER_NAME`, `SMTP_PASSWORD`, and `SMTP_FROM_ADDRESS` (see `.env.example`). If `SMTP_HOST` is empty, reservations still work; the worker logs *Skipping email*.
3. Start stack:

```bash
docker compose up -d --build
```

After changing `.env`, recreate containers so env is applied, e.g. `docker compose up -d --force-recreate api worker` (or `--build` if you changed code).

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
   flutter run --dart-define=API_BASE_URL=http://10.0.2.2:5096
   ```

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
- Flutter API address via:
  - `flutter run --dart-define=API_BASE_URL=http://...`

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

## Notes for Evaluators

- RabbitMQ UI: `http://localhost:15672` (`guest/guest`)
- API Swagger (development): `http://localhost:5096/swagger`
- **Stripe test checkout:** ensure test keys are configured (see `.env.example`), then use the sample card and fields in **`PAYMENTS.md` → *Testing card checkout*** (or [Stripe testing docs](https://docs.stripe.com/testing)).
- Core functionalities are available without code edits when configuration is provided through environment/appsettings.
