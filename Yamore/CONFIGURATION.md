# Centralized configuration

All configuration is stored in configuration files (appsettings, environment variables, or Flutter dart-define). No secrets or environment-specific values are hardcoded in source.

---

## Yamore.API (main service)

| Key | Description | Example / where to set |
|-----|-------------|------------------------|
| **ConnectionStrings:DefaultConnection** | SQL Server connection string | `appsettings.json` (empty in repo), `appsettings.Development.json`, or env |
| **Stripe:SecretKey** | Stripe secret key (never commit) | User Secrets, env, or appsettings.Development.json |
| **Stripe:PublishableKey** | Stripe publishable key | `appsettings.Development.json` or env |
| **RabbitMQ:HostName** | RabbitMQ server host | `appsettings.json` / `appsettings.Development.json` |
| **RabbitMQ:Port** | RabbitMQ port | Default 5672 |
| **RabbitMQ:UserName** | RabbitMQ user | Default guest |
| **RabbitMQ:Password** | RabbitMQ password | Default guest |
| **RabbitMQ:VirtualHost** | RabbitMQ vhost | Default / |
| **RabbitMQ:QueueName** | Queue name for worker | Default yamore-tasks |
| **AllowedHosts** | CORS / host configuration | appsettings |
| **AllowedOrigins** | CORS origins | appsettings array |

**User Secrets (development):**
```bash
cd Yamore.API
dotnet user-secrets set "ConnectionStrings:DefaultConnection" "Data Source=...;..."
dotnet user-secrets set "Stripe:SecretKey" "sk_test_..."
```

---

## Yamore.Worker (auxiliary service)

| Key | Description | Example / where to set |
|-----|-------------|------------------------|
| **RabbitMQ:HostName** | Same as API (must match) | appsettings.json / appsettings.Development.json |
| **RabbitMQ:Port** | Same as API | 5672 |
| **RabbitMQ:UserName** | Same as API | guest |
| **RabbitMQ:Password** | Same as API | guest |
| **RabbitMQ:VirtualHost** | Same as API | / |
| **RabbitMQ:QueueName** | Same as API | yamore-tasks |
| **Smtp:Host** | SMTP server for emails | appsettings |
| **Smtp:Port** | SMTP port | 587 |
| **Smtp:UserName** | SMTP login | Optional |
| **Smtp:Password** | SMTP password | User Secrets in production |
| **Smtp:UseSsl** | Use SSL/TLS | true |
| **Smtp:FromAddress** | Sender email | noreply@yourdomain.com |
| **Smtp:FromDisplayName** | Sender display name | Yamore |

If **Smtp:Host** is empty, the worker still runs and processes messages (logging only; no email sent).

---

## Flutter (mobile / desktop client)

| Source | Key | Description |
|--------|-----|-------------|
| **dart-define** | `API_BASE_URL` | API base URL (overrides defaults) |

**Run with custom API address:**
```bash
flutter run -d windows --dart-define=API_BASE_URL=http://localhost:5096
flutter run -d chrome --dart-define=API_BASE_URL=https://api.yourdomain.com
```

If `API_BASE_URL` is not set, the app uses:
- Android emulator: `http://10.0.2.2:5096`
- Other platforms: `http://localhost:5096`

---

## Running the two services

1. **RabbitMQ** must be running (e.g. Docker: `docker run -d --name rabbitmq -p 5672:5672 -p 15672:15672 rabbitmq:3-management`).
2. **Start the API:** `cd Yamore.API && dotnet run`
3. **Start the Worker:** `cd Yamore.Worker && dotnet run` (in a separate terminal or container).
4. **Flutter:** `flutter run -d windows` or with `--dart-define=API_BASE_URL=...` if the API is not on localhost.

The API publishes messages (e.g. reservation created, payment completed) to the queue; the Worker consumes them and performs logging and optional email.
