# Centralized configuration

All configuration is stored in configuration files (appsettings, environment variables, or Flutter dart-define). No secrets or environment-specific values are hardcoded in source.

**Shared host bootstrap:** The **`Yamore.Configuration`** class library (referenced by **Yamore.API** and **Yamore.Worker**) loads **`Yamore/.env`** via **`LocalEnvFileLoader`** and maps Docker-style variable names via **`ConfigurationEnvAliases`** before the ASP.NET or Worker host builds configuration—one implementation, two entry points.

---

## Yamore.API (main service)

| Key | Description | Example / where to set |
|-----|-------------|------------------------|
| **ConnectionStrings:DefaultConnection** | SQL Server connection string | User Secrets, env `ConnectionStrings__DefaultConnection`, or empty placeholder in appsettings (never commit real credentials) |
| **Stripe:SecretKey** | Stripe secret key | Env `Stripe__SecretKey` or User Secrets only |
| **Stripe:PublishableKey** | Stripe publishable key | Env `Stripe__PublishableKey` or User Secrets only |
| **RabbitMQ:HostName** | RabbitMQ server host | `appsettings.json` (non-secret defaults) or env `RabbitMQ__HostName` |
| **RabbitMQ:Port** | RabbitMQ port | appsettings or env `RabbitMQ__Port` (default 5672) |
| **RabbitMQ:UserName** | RabbitMQ user | Env `RabbitMQ__UserName` or User Secrets; if unset, client defaults to guest for local dev |
| **RabbitMQ:Password** | RabbitMQ password | Env `RabbitMQ__Password` or User Secrets; if unset, client defaults to guest for local dev |
| **RabbitMQ:VirtualHost** | RabbitMQ vhost | Default / |
| **RabbitMQ:QueueName** | Queue name for worker | Default yamore-tasks |
| **AllowedHosts** | CORS / host configuration | appsettings |
| **AllowedOrigins** | CORS origins | appsettings array |

**User Secrets (development):**
```bash
cd Yamore.API
dotnet user-secrets set "ConnectionStrings:DefaultConnection" "Data Source=...;..."
dotnet user-secrets set "Stripe:SecretKey" "sk_test_..."
dotnet user-secrets set "Stripe:PublishableKey" "pk_test_..."
```

**Docker Compose:** set `STRIPE_SECRET_KEY` and `STRIPE_PUBLISHABLE_KEY` in `Yamore/.env` (see `.env.example`). Compose maps them to `Stripe__SecretKey` and `Stripe__PublishableKey` for the API container. The database connection string is set in `docker-compose.yml` as `ConnectionStrings__DefaultConnection` for the API service.

**Docker Compose (Worker email):** set `SMTP_HOST`, `SMTP_PORT`, `SMTP_USER_NAME`, `SMTP_PASSWORD`, `SMTP_FROM_ADDRESS`, `SMTP_FROM_DISPLAY_NAME`, and optionally `SMTP_USE_SSL` in `Yamore/.env`. Maps to `Smtp__*` on the worker container. If `SMTP_HOST` is empty, the worker still runs but skips sending mail.

**Weather forecasts (mobile booking):** `GET /WeatherForecast` accepts optional `TripStart` and `TripEnd` (ISO 8601) together with `RouteId`. The API returns only rows whose `ForecastDate` falls on a calendar day between those trip dates (inclusive). The mobile app passes the user’s booking window from the route step. Omit trip dates to list all forecasts for a route (e.g. admin).

---

## Yamore.Worker (auxiliary service)

| Key | Description | Example / where to set |
|-----|-------------|------------------------|
| **RabbitMQ:HostName** | Same as API (must match) | appsettings (defaults) or env `RabbitMQ__HostName` |
| **RabbitMQ:Port** | Same as API | appsettings or env `RabbitMQ__Port` |
| **RabbitMQ:UserName** | Same as API | Env `RabbitMQ__UserName`; if unset, defaults to guest in code |
| **RabbitMQ:Password** | Same as API | Env `RabbitMQ__Password`; if unset, defaults to guest in code |
| **RabbitMQ:VirtualHost** | Same as API | / |
| **RabbitMQ:QueueName** | Same as API | yamore-tasks |
| **Smtp:Host** | SMTP server for emails | **Env only** (`Smtp__Host`) — not stored in committed appsettings |
| **Smtp:Port** | SMTP port | Env `Smtp__Port` (e.g. 587) |
| **Smtp:UserName** | SMTP login | Env `Smtp__UserName` |
| **Smtp:Password** | SMTP password | Env `Smtp__Password` |
| **Smtp:UseSsl** | Use SSL/TLS | Env `Smtp__UseSsl` (default true in code if unset) |
| **Smtp:FromAddress** | Sender email | Env `Smtp__FromAddress` |
| **Smtp:FromDisplayName** | Sender display name | Env `Smtp__FromDisplayName` |

If **Smtp:Host** is not set in the environment, the worker still runs and processes messages (logging only; no email sent).

---

## Flutter (mobile / desktop client)

| Source | Key | Description |
|--------|-----|-------------|
| **dart-define** | `API_BASE_URL` | Optional. Overrides the dev default (see below). Use for staging/production URLs. |

**Defaults when `API_BASE_URL` is omitted:**
- Android emulator: `http://10.0.2.2:5096`
- Other platforms (Windows, iOS simulator, web, …): `http://localhost:5096`

**Override examples:**
```bash
flutter run -d windows --dart-define=API_BASE_URL=https://api.yourdomain.com
flutter run -d chrome --dart-define=API_BASE_URL=https://api.yourdomain.com
```

---

## Running the two services

1. **RabbitMQ** must be running (e.g. Docker: `docker run -d --name rabbitmq -p 5672:5672 -p 15672:15672 rabbitmq:3-management`).
2. **Start the API:** `cd Yamore.API && dotnet run`
3. **Start the Worker:** `cd Yamore.Worker && dotnet run` (in a separate terminal or container).
4. **Flutter:** `flutter run -d windows` (defaults to `http://localhost:5096`) or pass `--dart-define=API_BASE_URL=...` for a non-default API.

The API publishes messages (e.g. reservation created, payment completed) to the queue; the Worker consumes them and performs logging and optional email.
