# Yamore

**Seminar project for the course Software Development 2**

📍 Faculty of Information Technology, Mostar

---

## About the project

**Yamore** is a yacht reservation platform: guests browse and book yachts, owners manage listings, and administrators use reporting and moderation tools.

It includes:

- **Yacht listings** with categories, locations, availability, and images  
- **Reservations** and booking history (mobile)  
- **Payments** (Stripe card checkout when configured, or pay on arrival)  
- **Admin dashboard** with statistics and export/print  
- **Recommendations** for destinations and yachts  
- **RabbitMQ** — API publishes messages; **Worker** sends email notifications (reservation created, payment confirmed) when SMTP is configured  
- **Flutter client:** JWT (Bearer) authentication (access + refresh tokens), HTTP error handling (including session reset on **401**), optional deep links (`yamore://…`), and parallel API calls where appropriate  

---

## Getting the project running

### Prerequisites

- **Docker Desktop** (Windows: WSL2 backend recommended) — for the recommended Compose stack  
- **Flutter SDK** (stable) — desktop and mobile clients  
- **.NET SDK 8** — to run `dotnet ef database update` if you need to align an older backup with the latest migrations, or to run API/Worker without Docker  

---

### Database (required)

The course provides a **SQL Server `.bak`** file. Restore it to an instance the API can use.

1. **Restore the backup** with SQL Server Management Studio, Azure Data Studio, or `sqlcmd`, on:
   - the **Docker** SQL Server started by this repo (`localhost` / `127.0.0.1`, port **1433** — see `docker-compose.yml` for the `sa` password), or  
   - a **local** SQL Server (e.g. Express), if you run the API outside Docker.

2. **Point the app at that database** by setting **`ConnectionStrings__DefaultConnection`** in **`Yamore/.env`** (copy from **`Yamore/.env.example`**). Use the correct **server**, **database name** (must match the restored database), and authentication.

3. **Migrations:** if the backup is **older** than the current code, apply pending migrations after restore (from the `Yamore` folder):

   ```powershell
   $env:ASPNETCORE_ENVIRONMENT = "Development"
   dotnet ef database update --project Yamore.Services\Yamore.Services.csproj --startup-project Yamore.API\Yamore.API.csproj
   ```

   If the backup already matches the latest schema, this is a no-op.

4. **Docker Compose** sets a default connection string to the bundled SQL Server (`Server=sqlserver,…;Database=220245;…` in `docker-compose.yml`). If your restored database uses a **different name**, update the connection string (or your restore target) so they match.

More detail and alternative layouts: **`Yamore/CONFIGURATION.md`**.

---

### Configuration (`Yamore/.env`)

Copy **`Yamore/.env.example`** → **`Yamore/.env`** and fill in at least:

- **`ConnectionStrings__DefaultConnection`** — required (see above).  
- **`JWT_SECRET`** (or `Jwt__Secret`) — at least **32 characters**; required for signing access/refresh tokens in non-trivial use.  
- **Optional:** **Stripe** (`STRIPE_SECRET_KEY`, `STRIPE_PUBLISHABLE_KEY`) for card payments; **SMTP** and **RabbitMQ** for email and messaging (defaults in `.env.example` work with Compose for RabbitMQ).  

Card payments and webhooks: **`Yamore/PAYMENTS.md`**.

---

### Backend (Docker — recommended)

From the **`Yamore`** folder (the one that contains **`docker-compose.yml`**):

```bash
cd Yamore
docker compose up -d --build
```

| Service    | URL / port |
|------------|------------|
| API        | `http://localhost:5096` — Swagger: `/swagger` |
| SQL Server | `localhost:1433` |
| RabbitMQ   | broker `localhost:5672`, management UI `http://localhost:15672` (`guest` / `guest`) |

Stop: `docker compose down` (same folder). Data for SQL Server and RabbitMQ persists in Docker volumes unless you use `down -v`.

---

### Flutter (desktop)

```bash
cd Yamore/UI/yamore_mobile
flutter pub get
flutter run -d windows
```

Default API base: **`http://localhost:5096`**. Override:

```bash
flutter run -d windows --dart-define=API_BASE_URL=http://localhost:5096
```

---

### Flutter (Android emulator)

```bash
cd Yamore/UI/yamore_mobile
flutter pub get
flutter run
```

Default API for the emulator: **`http://10.0.2.2:5096`**. Override:

```bash
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:5096
```

---

## Login credentials

Use with the **restored course database**. API base: **`http://localhost:5096`** (desktop / Swagger) or **`http://10.0.2.2:5096`** (Android emulator).

| Role | Username | Password |
|------|----------|----------|
| 👑 Administrator | `zerina` | `Zerina123!` |
| 🛥️ Yacht owner | `antonio` | `Antonio123!` |
| 🛥️ Yacht owner | `julian` | `Julian123!` |
| 👤 End user | `zara` | `Zara123!` |
| 👤 End user | `arman` | `Arman123!` |
| 👤 End user | `faris` | `Faris123!` |

---

## Run without Docker (optional)

Run SQL Server (restored `.bak`) and RabbitMQ locally or in Docker. Set **`ConnectionStrings__DefaultConnection`** and secrets via **`Yamore/.env`** or User Secrets, then start **`Yamore.API`** and **`Yamore.Worker`** (e.g. `dotnet run` in two terminals). Flutter: same as above.

---

## Development vs Docker

- **`Yamore/Yamore.API/appsettings.Development.json`** defaults to **`SKIP_EF_DATABASE_MIGRATE`** and **`SKIP_DEMO_SEED`** so local F5 runs do not fight your database; override if you want migrate/seed on launch.  
- **Docker** `api` service sets those flags for automatic migrate/seed on **empty** databases; a **restored** `.bak` is not empty, so you mainly rely on the backup data plus optional `database update` as above.

---

## Microservice flow (RabbitMQ)

The API publishes messages; the Worker consumes and sends **email** when SMTP is configured. Example: reservation created → optional “reservation received” email; card payment completed → optional “payment confirmed” email. Worker logs: `docker compose logs -f worker` (from `Yamore`).

---

## Technologies

| Layer | Technology |
|-------|------------|
| Backend | ASP.NET Core (.NET 8) |
| Frontend | Flutter (desktop + mobile) |
| Database | SQL Server |
| Message broker | RabbitMQ |
| Containerization | Docker Compose (API, Worker, SQL Server, RabbitMQ) |
| Payments (optional) | Stripe |

---

## Repository layout

| Path | Description |
|------|-------------|
| `Yamore/` | Solution, `docker-compose.yml` |
| `Yamore/Yamore.Configuration` | Shared `.env` loading and environment aliases |
| `Yamore/UI/yamore_mobile` | Flutter app; `API_BASE_URL` for the backend |

---

## Troubleshooting (short)

| Issue | What to try |
|-------|-------------|
| **MSB1009** / project not found | Run `docker compose` only from the **`Yamore`** folder. |
| Ports in use | Free `1433`, `5096`, `5672` or change ports in `docker-compose.yml`. |
| Flutter cannot reach API | API running; desktop → `localhost:5096`, Android emulator → `10.0.2.2:5096`. |
| **Invalid object name** / migration errors | Check `docker compose logs api`. Connection string and database name must match the restored DB. |
| **Payment configuration missing** | Add Stripe keys to `.env` and restart the `api` service, or use pay on arrival. |

---

## Notes for evaluators

- Swagger: `http://localhost:5096/swagger` when enabled (e.g. Docker with `ENABLE_SWAGGER=true`).  
- RabbitMQ UI: `http://localhost:15672` (`guest` / `guest`).  
- Stripe test mode: keys in `.env` from `.env.example`, then **`Yamore/PAYMENTS.md`** for test cards.  
- Test user accounts: **Login credentials** section above.  
