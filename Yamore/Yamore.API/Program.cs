using Mapster;
using Microsoft.AspNetCore.Authentication;
using Microsoft.Data.SqlClient;
using Microsoft.EntityFrameworkCore;
using Microsoft.OpenApi.Models;
using Yamore.API;
using Yamore.API.Filters;
using Yamore.Services.Database;
using Yamore.Services.Interfaces;
using Yamore.Services.Services;
using Yamore.Services.YachtStateMachine;

var builder = WebApplication.CreateBuilder(args);

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



builder.Services.AddTransient<BaseYachtState>();
builder.Services.AddTransient<InitialYachtState>();
builder.Services.AddTransient<DraftYachtState>();
builder.Services.AddTransient<ActiveYachtState>();
builder.Services.AddTransient<HiddenYachtState>();




builder.Services.AddControllers( x=>
{
    x.Filters.Add<ExceptionFilter>();
});



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

app.UseAuthorization();

app.MapControllers();

app.Run();
