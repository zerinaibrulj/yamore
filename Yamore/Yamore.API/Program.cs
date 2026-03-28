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
using Yamore.API.Filters;
using Yamore.API.Validation;
using Yamore.Services.Database;
using Yamore.Services.Interfaces;
using Yamore.Services.Services;
using Yamore.Services.YachtStateMachine;
using Yamore.API.Services;


var builder = WebApplication.CreateBuilder(args);

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

// READ allowed origins from configuration (appsettings or environment)
var allowedOrigins = builder.Configuration.GetSection("AllowedOrigins").Get<string[]>() ?? Array.Empty<string>();

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



// For Appsetting.json
var connectionString = builder.Configuration.GetConnectionString("DefaultConnection");
builder.Services.AddDbContext<_220245Context>(options => options.UseSqlServer(connectionString));

builder.Services.AddMapster();      //dodamo Mapster za automatsko mapiranje entiteta u modele



builder.Services.AddAuthentication("BasicAuthentication")
    .AddScheme<AuthenticationSchemeOptions, BasicAuthenticationHandler>("BasicAuthentication", null);


var app = builder.Build();

// Apply EF Core migrations so a fresh Docker SQL volume gets tables (avoids "Invalid object name").
using (var scope = app.Services.CreateScope())
{
    var db = scope.ServiceProvider.GetRequiredService<_220245Context>();
    db.Database.Migrate();
}

// Configure the HTTP request pipeline.
if (app.Environment.IsDevelopment())
{
    app.UseSwagger();
    app.UseSwaggerUI();
}

// Android emulator calls the local API over http://10.0.2.2:5096 in Development.
// Forcing HTTPS redirection there can cause connection-aborted errors on login.
if (!app.Environment.IsDevelopment())
{
    app.UseHttpsRedirection();
}

// apply the named CORS policy
app.UseCors("DefaultCorsPolicy");

app.UseAuthentication();

app.UseAuthorization();

app.MapControllers();

app.Run();
