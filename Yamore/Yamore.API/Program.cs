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


var builder = WebApplication.CreateBuilder(args);

builder.Services.AddCors(options =>
{
    options.AddPolicy("AllowLocalhost5096", policy =>
    {
        policy
            .WithOrigins("http://localhost:5096", "https://localhost:5096")
            .AllowAnyHeader()
            .AllowAnyMethod()
            .AllowCredentials();
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
builder.Services.AddTransient<ISpecialRequestService, SpecialRequestService>();
builder.Services.AddTransient<IReservationServiceService, ReservationServiceService>();
builder.Services.AddTransient<IReviewService, ReviewService>();
builder.Services.AddTransient<INotificationService, NotificationService>();
builder.Services.AddTransient<IPaymentService, PaymentService>();




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



// Configure the HTTP request pipeline.
if (app.Environment.IsDevelopment())
{
    app.UseSwagger();
    app.UseSwaggerUI();
}

app.UseHttpsRedirection();

app.UseCors("AllowLocalhost5096");

app.UseAuthentication();

app.UseAuthorization();

app.MapControllers();

app.Run();
