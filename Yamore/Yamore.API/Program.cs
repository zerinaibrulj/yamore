using System.Text.Json.Serialization;
using Mapster;
using FluentValidation;
using Microsoft.AspNetCore.Authentication;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Internal;
using Microsoft.EntityFrameworkCore.Storage;
using Microsoft.AspNetCore.Mvc;
using Microsoft.OpenApi.Models;
using Yamore.API;
using Yamore.API.Configuration;
using Yamore.API.Filters;
using Yamore.API.Validation;
using Yamore.Services.Database;
using Yamore.Services.Interfaces;
using Yamore.Services.Services;
using Yamore.Services.YachtStateMachine;
using Yamore.API.Services;
using Microsoft.Extensions.Logging;
using Microsoft.Data.SqlClient;

// Load Yamore/.env (or a .env found by walking up from the project directory) before configuration is built.
// All secrets and environment-specific values must come from environment / .env — not from committed appsettings.json.
LocalEnvFileLoader.Load();
// Map STRIPE_*, SMTP_*, etc. to Stripe__*, Smtp__* so one .env works for Docker substitution and for dotnet run.
ConfigurationEnvAliases.Apply();

var builder = WebApplication.CreateBuilder(args);

// Linux Docker containers: bind 0.0.0.0:8080 so host port 5096→8080 forwarding works (fixes "connection refused" from Windows).
if (File.Exists("/.dockerenv"))
{
    builder.WebHost.UseUrls("http://0.0.0.0:8080");
}

// Configure Mapster mappings.
// 1) Avoid cycles between User and UserRole.
TypeAdapterConfig<Yamore.Services.Database.UserRole, Yamore.Model.UserRole>
    .NewConfig()
    .Ignore(dest => dest.User);

// 2) For User updates, ignore null values so that fields not sent
//    from the client (like Email/Username) do not overwrite existing data.
TypeAdapterConfig<Yamore.Model.Requests.User.UserUpdateRequest, Yamore.Services.Database.User>
    .NewConfig()
    .IgnoreNullValues(true);

// CORS: comma-separated origins from Cors:AllowedOrigins (env: Cors__AllowedOrigins). If unset, dev allows any origin.
var corsList = builder.Configuration["Cors:AllowedOrigins"];
var allowedOrigins = !string.IsNullOrWhiteSpace(corsList)
    ? corsList.Split(',', StringSplitOptions.RemoveEmptyEntries | StringSplitOptions.TrimEntries)
    : Array.Empty<string>();

builder.Services.AddCors(options =>
{
    options.AddPolicy("DefaultCorsPolicy", policy =>
    {
        if (allowedOrigins.Length > 0)
        {
            policy.WithOrigins(allowedOrigins)
                  .AllowAnyHeader()
                  .AllowAnyMethod()
                  .AllowCredentials();
        }
        else if (builder.Environment.IsDevelopment())
        {
            // development fallback (only)
            policy.AllowAnyOrigin()
                  .AllowAnyHeader()
                  .AllowAnyMethod();
        }
        else
        {
            // production: deny by default (or set a secure default)
            policy.DisallowCredentials();
        }
    });
});


// Add services to the container.

builder.Services.AddHttpContextAccessor();
builder.Services.AddTransient<IYachtsService, YachtsService>();  //dodamo servis
//builder.Services.AddTransient<YachtsService, YachtsService>(); 
//builder.Services.AddTransient<YachtsService, DummyYachtsService>();
//builder.Services.AddTransient<IYachtsService, DummyYachtsService>();
builder.Services.AddTransient<IUsersService, UsersService>();
builder.Services.AddTransient<IYachtCategoryService, YachtCategoryService>();
builder.Services.AddTransient<ICountryService, CountryService>();
builder.Services.AddTransient<ICityService, CityService>();
builder.Services.AddTransient<IServiceService, ServiceService>();
builder.Services.AddTransient<IRouteService, RouteService>();
builder.Services.AddTransient<IRoleService, RoleService>();
builder.Services.AddTransient<IUserRoleService, UserRoleService>();
builder.Services.AddTransient<IWeatherForecastService, WeatherForecastService>();
builder.Services.AddTransient<IReservationService, Yamore.Services.Services.ReservationService>();   //imam klasu ReservationService pa sam zbog toga morala navesti tacnu putanju da se odnosi na servis a ne na klasu
builder.Services.AddTransient<IReservationServiceService, ReservationServiceService>();
builder.Services.AddTransient<IReviewService, ReviewService>();
builder.Services.AddTransient<INotificationService, NotificationService>();
builder.Services.AddTransient<IPaymentService, PaymentService>();
builder.Services.AddTransient<IYachtAvailabilityService, YachtAvailabilityService>();
builder.Services.AddTransient<IServiceCategoryService, ServiceCategoryService>();
builder.Services.AddTransient<IStatisticsService, StatisticsService>();
builder.Services.AddTransient<IYachtImageService, YachtImageService>();
builder.Services.AddTransient<IYachtServiceService, YachtServiceService>();
builder.Services.AddSingleton<StripePaymentService>();
builder.Services.AddSingleton<IMessagePublisher, RabbitMQMessagePublisher>();



builder.Services.AddTransient<BaseYachtState>();
builder.Services.AddTransient<InitialYachtState>();
builder.Services.AddTransient<DraftYachtState>();
builder.Services.AddTransient<ActiveYachtState>();
builder.Services.AddTransient<HiddenYachtState>();




builder.Services.AddControllers(x =>
{
    x.Filters.Add<ExceptionFilter>();
    x.Filters.Add<FluentValidationActionFilter>();
})
.AddJsonOptions(options =>
{
    options.JsonSerializerOptions.ReferenceHandler = ReferenceHandler.IgnoreCycles;
    options.JsonSerializerOptions.PropertyNamingPolicy = System.Text.Json.JsonNamingPolicy.CamelCase;
})
.ConfigureApiBehaviorOptions(options =>
{
    options.InvalidModelStateResponseFactory = context =>
    {
        var problem = new ValidationProblemDetails(context.ModelState)
        {
            Title = "Validation failed",
            Detail = "Please fix the highlighted fields and try again.",
            Status = StatusCodes.Status400BadRequest
        };

        return new BadRequestObjectResult(problem);
    };
});

builder.Services.AddValidatorsFromAssemblyContaining<UserInsertRequestValidator>();



// Learn more about configuring Swagger/OpenAPI at https://aka.ms/aspnetcore/swashbuckle
builder.Services.AddEndpointsApiExplorer();
builder.Services.AddSwaggerGen(c =>
{
    c.AddSecurityDefinition("basicAuth", new Microsoft.OpenApi.Models.OpenApiSecurityScheme()
    {
        Type = Microsoft.OpenApi.Models.SecuritySchemeType.Http,
        Scheme = "basic"
    });

    c.AddSecurityRequirement(new Microsoft.OpenApi.Models.OpenApiSecurityRequirement()
    {
        {
            new OpenApiSecurityScheme
            {
                Reference=new OpenApiReference{Type=ReferenceType.SecurityScheme, Id="basicAuth"}
            },
            new string[]{}
        }
    });
});



// Connection string: set ConnectionStrings__DefaultConnection in .env or the environment. Optional dev fallback: Yamore__Development__DefaultConnection
var connectionString = builder.Configuration.GetConnectionString("DefaultConnection");
if (string.IsNullOrWhiteSpace(connectionString) && builder.Environment.IsDevelopment())
{
    connectionString = builder.Configuration["Yamore:Development:DefaultConnection"]?.Trim();
}
if (string.IsNullOrWhiteSpace(connectionString))
{
    throw new InvalidOperationException(
        "Connection string 'DefaultConnection' is missing. " +
        "Set ConnectionStrings__DefaultConnection in Yamore/.env (copy from .env.example), the process environment, or Docker. " +
        "In .env, use double-underscore for nested keys, e.g. ConnectionStrings__DefaultConnection=Server=...;");
}

builder.Services.AddDbContext<_220245Context>(options => options.UseSqlServer(connectionString));

builder.Services.AddMapster();      //dodamo Mapster za automatsko mapiranje entiteta u modele



builder.Services.AddAuthentication("BasicAuthentication")
    .AddScheme<AuthenticationSchemeOptions, BasicAuthenticationHandler>("BasicAuthentication", null);

builder.Services.AddAuthorization();

var app = builder.Build();

// Apply EF Core migrations so a fresh Docker SQL volume gets tables (avoids "Invalid object name").
// Set SKIP_EF_DATABASE_MIGRATE=true to skip (diagnostics only). Retries help if SQL is slow right after healthcheck.
var skipMigrate = string.Equals(
    app.Configuration["SKIP_EF_DATABASE_MIGRATE"],
    "true",
    StringComparison.OrdinalIgnoreCase);

using (var scope = app.Services.CreateScope())
{
    var loggerFactory = scope.ServiceProvider.GetRequiredService<ILoggerFactory>();
    var startupLogger = loggerFactory.CreateLogger("Startup");

    if (app.Environment.IsDevelopment())
    {
        var sk = StripeKeyResolver.GetSecretKey(app.Configuration);
        var pk = StripeKeyResolver.GetPublishableKey(app.Configuration);
        var skOk = !string.IsNullOrEmpty(sk) && sk.StartsWith("sk_", StringComparison.Ordinal);
        var pkOk = !string.IsNullOrEmpty(pk) && pk.StartsWith("pk_", StringComparison.Ordinal);
        startupLogger.LogInformation(
            "Stripe: secret key (sk_*) ok: {SkOk}, publishable (pk_*) ok: {PkOk}. If false, fix Yamore/.env or remove conflicting Stripe: entries from user secrets.",
            skOk, pkOk);
    }

    if (skipMigrate)
    {
        startupLogger.LogWarning(
            "SKIP_EF_DATABASE_MIGRATE=true: skipping Database.Migrate(). Apply migrations manually if the database is empty.");
    }
    else
    {
        var db = scope.ServiceProvider.GetRequiredService<_220245Context>();
        for (var attempt = 1; attempt <= 10; attempt++)
        {
            try
            {
                db.Database.Migrate();
                if (attempt > 1)
                {
                    startupLogger.LogInformation("Database.Migrate succeeded on attempt {Attempt}.", attempt);
                }

                break;
            }
            catch (Exception ex)
            {
                SqlException? sqlEx = null;
                for (var e = ex; e != null; e = e.InnerException)
                {
                    if (e is SqlException s)
                    {
                        sqlEx = s;
                        break;
                    }
                }

                if (sqlEx?.Number == 2714)
                {
                    startupLogger.LogCritical(
                        "Database.Migrate failed: object already exists (SQL error 2714). " +
                        "The Docker SQL volume has tables from an older run, but EF migration history does not match. " +
                        "Reset only the database volume (not your project files): from the Yamore folder run " +
                        "\"docker compose down -v\" then \"docker compose up -d --build\". " +
                        "Or see README.md at the repository root → Docker troubleshooting.");
                    throw;
                }

                startupLogger.LogWarning(ex, "Database.Migrate attempt {Attempt}/10 failed.", attempt);
                if (attempt == 10)
                {
                    throw;
                }

                Thread.Sleep(TimeSpan.FromSeconds(3));
            }
        }

        var skipDemoSeed = string.Equals(
            app.Configuration["SKIP_DEMO_SEED"],
            "true",
            StringComparison.OrdinalIgnoreCase);
        if (!skipDemoSeed)
        {
            try
            {
                var demoNotifyEmail = app.Configuration["DemoSeed:NotificationEmail"];
                DemoDataSeeder.SeedIfEmpty(db, startupLogger, demoNotifyEmail);
            }
            catch (Exception ex)
            {
                startupLogger.LogError(ex, "Demo database seed failed.");
                throw;
            }
        }
        else
        {
            startupLogger.LogWarning("SKIP_DEMO_SEED=true: skipping demo seed.");
        }
    }
}

// Configure the HTTP request pipeline.
// Swagger: Development locally, or Docker Compose (ENABLE_SWAGGER=true) so http://localhost:5096/swagger works reliably.
var enableSwagger = app.Environment.IsDevelopment()
    || string.Equals(
        Environment.GetEnvironmentVariable("ENABLE_SWAGGER"),
        "true",
        StringComparison.OrdinalIgnoreCase);
if (enableSwagger)
{
    app.UseSwagger();
    app.UseSwaggerUI();
}

// Android emulator / Docker HTTP port mapping: HTTPS redirect breaks http://localhost:5096.
var disableHttpsRedirect = string.Equals(
    Environment.GetEnvironmentVariable("DISABLE_HTTPS_REDIRECT"),
    "true",
    StringComparison.OrdinalIgnoreCase);
if (!app.Environment.IsDevelopment() && !disableHttpsRedirect)
{
    app.UseHttpsRedirection();
}

// apply the named CORS policy
app.UseCors("DefaultCorsPolicy");

app.UseAuthentication();

app.UseAuthorization();

app.MapControllers();

app.Run();
