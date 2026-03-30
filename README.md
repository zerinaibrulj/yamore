# Yamore

**Seminar project for the course Software Development 2**

📍 Faculty of Information Technology, Mostar

---

## 📖 About the project

**Yamore** is a yacht reservation platform: guests browse and book yachts, owners manage listings, and administrators use reporting and moderation tools.

It includes:

- 🛥️ **Yacht listings** with categories, locations, availability, and images  
- 📅 **Reservations** and booking history (mobile)  
- 💳 **Payments** (Stripe card checkout when configured, or pay on arrival)  
- 📊 **Admin dashboard** with statistics and export/print  
- 💡 **Recommendations** for destinations and yachts  
- 🐰 **RabbitMQ** — API publishes messages; **Worker** sends email notifications (reservation created, payment confirmed)

---

## 🚀 Instructions for running

### Prerequisites

- **Docker Desktop** (Windows: WSL2 backend recommended)  
- **Flutter SDK** (stable) — for desktop and mobile clients  
- **.NET SDK 8** — only if you run the API without Docker  

---

### Backend (Docker — recommended)

1. Clone this repository and open a terminal in the **`Yamore`** folder (the one that contains `docker-compose.yml`).  
   Running `docker compose` from the wrong path causes build errors (e.g. **MSB1009**).

2. **Optional — Stripe (card payments):** copy `Yamore/.env.example` → `Yamore/.env` and set `STRIPE_SECRET_KEY` and `STRIPE_PUBLISHABLE_KEY` (test keys). Without this, bookings still work with **Pay on arrival**.

3. **Optional — email (Worker):** in `.env`, set `SMTP_HOST`, `SMTP_USER_NAME`, `SMTP_PASSWORD`, `SMTP_FROM_ADDRESS` (see `.env.example`). If SMTP is empty, reservations still work; the worker skips sending email.

4. Start the stack:

```bash
cd Yamore
docker compose up -d --build
```

5. Wait until containers are healthy (first SQL Server image pull can take several minutes).

**What starts:**

| Service    | URL / port |
|------------|------------|
| API        | `http://localhost:5096` — Swagger: `/swagger` |
| SQL Server | `localhost:1433` |
| RabbitMQ   | broker `localhost:5672`, management UI `http://localhost:15672` (`guest` / `guest`) |

**Database:** On startup the API runs **EF Core migrations** and applies an **automatic demo seed** the first time the database is empty (see credentials below).  
**Volumes:** SQL Server and RabbitMQ use Docker volumes so data persists across `docker compose down` (not `down -v`).

To stop: `docker compose down` from the same `Yamore` folder.

---

### Desktop application (Flutter)

1. Enable **developer mode** on Windows if required for Flutter tooling.  
2. From the repo, go to the Flutter project:

```bash
cd Yamore/UI/yamore_mobile
flutter pub get
flutter run -d windows
```

The app defaults to the API at **`http://localhost:5096`**.  
Override if needed:

```bash
flutter run -d windows --dart-define=API_BASE_URL=http://localhost:5096
```

---

### Mobile application (Android)

1. Start the backend (Docker or local API on port **5096**).  
2. From `Yamore/UI/yamore_mobile`:

```bash
flutter pub get
flutter run
```

The project defaults the API to **`http://10.0.2.2:5096`** on the Android emulator (host `localhost` from the emulator).  
Override if needed:

```bash
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:5096
```

⚠️ Uninstall any older build of the app from the emulator if you see install conflicts.

---

## 🔐 Login credentials (Docker first run)

After a **clean** database (e.g. first `docker compose up`, or after `docker compose down -v`), the API seeds **demo users** automatically (only when the `Roles` table is empty).

**Shared password for all demo accounts:** `Demo123!`

| Role | Username | Password | Use case |
|------|----------|----------|----------|
| 👑 Administrator | `demo.admin` | `Demo123!` | Desktop admin, Swagger, protected admin endpoints |
| 🛥️ Yacht owner | `demo.owner` | `Demo123!` | Owner flows; sample yachts are seeded for this user |
| 👤 End user | `demo.user` | `Demo123!` | Mobile booking and guest flows |

- **Desktop / Swagger:** API base URL **`http://localhost:5096`**  
- **Android emulator:** API base URL **`http://10.0.2.2:5096`**

**Deliverable email for demo users (Docker):** In `Yamore/.env` set `DEMO_NOTIFICATION_EMAIL=your.real@gmail.com` (same value is used for all three seeded accounts’ `Email` so Gmail accepts delivery). Recreate the stack with a **fresh** DB for this to apply (`docker compose down -v` then `up -d --build`), or run SQL to update `Users.Email` for `demo.user` / `demo.admin` / `demo.owner` if you keep the volume.

**Why logs showed `user@yamore.local`:** That is the seeded **`demo.user`** (often `UserId=3`). Emails go to the **`Email` stored for the user who made the reservation**, not “whoever you think is logged in” if the app session is still the demo account.

---

## 🐰 Microservice functionality (RabbitMQ)

Yamore uses a **RabbitMQ** architecture: the **API** publishes messages; the **Worker** consumes them and sends **email** when SMTP is configured.

Typical flow:

1. User creates a **reservation** → message `ReservationCreated` → optional email *Reservation received*.  
2. User completes **card payment** (Stripe configured) → message `PaymentCompleted` → optional email *Payment confirmed*.

Check Worker logs: `docker compose logs -f worker` (from the `Yamore` folder).

---

## 🛠️ Technologies

| Layer | Technology |
|-------|------------|
| Backend | ASP.NET Core (.NET 8) |
| Frontend | Flutter (desktop + mobile) |
| Database | SQL Server |
| Message broker | RabbitMQ |
| Containerization | Docker Compose (API, Worker, SQL Server, RabbitMQ) |
| Payments (optional) | Stripe |

Further configuration: **`Yamore/CONFIGURATION.md`**. Payment testing: **`Yamore/PAYMENTS.md`**.

---

## 📁 Repository layout

| Path | Description |
|------|-------------|
| `Yamore/` | Solution: API, services, worker, `docker-compose.yml` |
| `Yamore/UI/yamore_mobile` | Flutter app |

---

## Docker vs Visual Studio database mode

- **Docker Compose run** (`docker compose up` from `Yamore/`): uses container SQL Server and runs migrations + demo seed (`SKIP_EF_DATABASE_MIGRATE=false`, `SKIP_DEMO_SEED=false` in compose).
- **Visual Studio Development run**: by default skips migrate/seed (`appsettings.Development.json`) so you can connect to your real database without demo data interfering.
- To use your real DB in Visual Studio, set `ConnectionStrings:DefaultConnection` in User Secrets (recommended) or `appsettings.Development.json`.

---

## Run without Docker (optional)

1. Run SQL Server and RabbitMQ locally (or RabbitMQ via Docker).  
2. Set `ConnectionStrings:DefaultConnection` and secrets (User Secrets or environment variables).  
3. Start `Yamore.API` and `Yamore.Worker` in separate terminals (`dotnet run`).  
4. Run Flutter from `Yamore/UI/yamore_mobile` as above.

Details: **`Yamore/CONFIGURATION.md`**.

---

## Troubleshooting (short)

| Issue | What to try |
|-------|-------------|
| **MSB1009** / project not found | Run `docker compose` only from the **`Yamore`** folder. |
| Ports in use | Free `1433`, `5096`, `5672` or change ports in `docker-compose.yml`. |
| Flutter cannot reach API | Ensure API is running; desktop → `localhost:5096`, Android emulator → `10.0.2.2:5096`. |
| **Invalid object name** / migration errors | Check `docker compose logs api`. For a broken SQL volume vs migrations: `docker compose down -v` then `up -d --build` (wipes Docker DB data only). |
| **Payment configuration missing** | Add Stripe keys to `.env` and restart the `api` service, or use pay on arrival. |

---

## Notes for evaluators

- Swagger: `http://localhost:5096/swagger` (when enabled, e.g. Docker with `ENABLE_SWAGGER=true`).  
- RabbitMQ UI: `http://localhost:15672` (`guest` / `guest`).  
- Stripe test mode: configure keys from `.env.example`, then follow **`Yamore/PAYMENTS.md`** for test cards.
