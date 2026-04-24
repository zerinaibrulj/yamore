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
using Yamore.API.Hosted;
using Yamore.Configuration;
using Yamore.API.Filters;
using Yamore.API.Validation;
using Yamore.Services.Database;
using Yamore.Services.Interfaces;
using Yamore.Services.Services;
using Yamore.Services.YachtStateMachine;
using Yamore.API.Services;
using Microsoft.Extensions.Logging;
using Microsoft.Data.SqlClient;

LocalEnvFileLoader.Load();
ConfigurationEnvAliases.Apply();

var builder = WebApplication.CreateBuilder(args);

if (File.Exists("/.dockerenv"))
{
    builder.WebHost.UseUrls("http://0.0.0.0:8080");
}

TypeAdapterConfig<Yamore.Services.Database.UserRole, Yamore.Model.UserRole>
    .NewConfig()
    .Ignore(dest => dest.User);

TypeAdapterConfig<Yamore.Model.Requests.User.UserUpdateRequest, Yamore.Services.Database.User>
    .NewConfig()
    .IgnoreNullValues(true);

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
                  .WithExposedHeaders("X-Reservation-Cancel-Has-Card-Payment", "X-Operation-Message")
                  .AllowCredentials();
        }
        else if (builder.Environment.IsDevelopment())
        {
            policy.AllowAnyOrigin()
                  .AllowAnyHeader()
                  .AllowAnyMethod()
                  .WithExposedHeaders("X-Reservation-Cancel-Has-Card-Payment", "X-Operation-Message");
        }
        else
        {
            policy.DisallowCredentials();
        }
    });
});

builder.Services.AddHttpContextAccessor();
builder.Services.AddScoped<ExceptionFilter>();

builder.Services.AddScoped<IYachtsService, YachtsService>();
builder.Services.AddScoped<IUsersService, UsersService>();
builder.Services.AddScoped<IYachtCategoryService, YachtCategoryService>();
builder.Services.AddScoped<ICountryService, CountryService>();
builder.Services.AddScoped<ICityService, CityService>();
builder.Services.AddScoped<IServiceService, ServiceService>();
builder.Services.AddScoped<IRouteService, RouteService>();
builder.Services.AddScoped<IRoleService, RoleService>();
builder.Services.AddScoped<IUserRoleService, UserRoleService>();
builder.Services.AddScoped<IWeatherForecastService, WeatherForecastService>();
builder.Services.AddScoped<IReservationService, Yamore.Services.Services.ReservationService>();
builder.Services.AddHostedService<AutoCompleteReservationsHostedService>();
builder.Services.AddScoped<IReservationServiceService, ReservationServiceService>();
builder.Services.AddScoped<IReviewService, ReviewService>();
builder.Services.AddScoped<INotificationService, NotificationService>();
builder.Services.AddScoped<INewsItemService, NewsItemService>();
builder.Services.AddScoped<IPaymentService, PaymentService>();
builder.Services.AddScoped<IYachtAvailabilityService, YachtAvailabilityService>();
builder.Services.AddScoped<IServiceCategoryService, ServiceCategoryService>();
builder.Services.AddScoped<IStatisticsService, StatisticsService>();
builder.Services.AddScoped<IYachtImageService, YachtImageService>();
builder.Services.AddScoped<IYachtServiceService, YachtServiceService>();
builder.Services.AddScoped<ISampleYachtSeedService, SampleYachtSeedService>();
builder.Services.AddSingleton<StripePaymentService>();
builder.Services.AddSingleton<IMessagePublisher, RabbitMQMessagePublisher>();

builder.Services.AddScoped<BaseYachtState>();
builder.Services.AddScoped<InitialYachtState>();
builder.Services.AddScoped<DraftYachtState>();
builder.Services.AddScoped<ActiveYachtState>();
builder.Services.AddScoped<HiddenYachtState>();

builder.Services.AddScoped<IPaymentWorkflowService, PaymentWorkflowService>();




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

builder.Services.AddMapster();

builder.Services.AddHttpClient();
builder.Services.AddMemoryCache();

builder.Services.AddAuthentication("BasicAuthentication")
    .AddScheme<AuthenticationSchemeOptions, BasicAuthenticationHandler>("BasicAuthentication", null);

builder.Services.AddAuthorization();

var app = builder.Build();

if (!app.Environment.IsDevelopment() && allowedOrigins.Length == 0)
{
    throw new InvalidOperationException(
        "Cors:AllowedOrigins must be set (comma-separated list) in non-Development environments. " +
        "Set Cors__AllowedOrigins in configuration or the process environment.");
}

var skipMigrate = string.Equals(
    app.Configuration["SKIP_EF_DATABASE_MIGRATE"],
    "true",
    StringComparison.OrdinalIgnoreCase);

await using (var scope = app.Services.CreateAsyncScope())
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

                await Task.Delay(TimeSpan.FromSeconds(3));
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

var disableHttpsRedirect = string.Equals(
    Environment.GetEnvironmentVariable("DISABLE_HTTPS_REDIRECT"),
    "true",
    StringComparison.OrdinalIgnoreCase);
if (!app.Environment.IsDevelopment() && !disableHttpsRedirect)
{
    app.UseHttpsRedirection();
}

app.UseCors("DefaultCorsPolicy");

app.UseAuthentication();

app.UseAuthorization();

app.MapControllers();

app.Run();
