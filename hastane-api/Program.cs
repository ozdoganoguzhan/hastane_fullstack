using System.Text;
using System.Text.Json;
using System.Text.Json.Serialization;
using Microsoft.AspNetCore.Authentication.JwtBearer;
using Microsoft.AspNetCore.Identity;
using Microsoft.IdentityModel.Tokens;
using Ozi.Application.EventHandling;
using Ozi.Application.Infrastructure.ApplicationContext;
using Ozi.Application.Infrastructure.Config;
using Ozi.Domain.Entities;
using Ozi.Features.Auth;
using Ozi.Features.HbysMock;
using Ozi.Features.HospitalInfo;
using Ozi.Features.Menu;
using Ozi.Features.Otp;
using Ozi.Features.Personnel;
using Ozi.Infrastructure.Data.Context;
using Ozi.Infrastructure.Data.Seed;
using Ozi.Infrastructure.Integration.Hbys;
using Ozi.Infrastructure.Integration.Sms;
using Ozi.Infrastructure.Security;
using Ozi.Infrastructure.Web;
using Scalar.AspNetCore;

// 3G Bilişim SMS gateway'i yanıtlarını ISO-8859-9 (Latin-5) ile döner; .NET Core
// bu kod sayfasını yalnızca bu sağlayıcı kayıtlıysa tanır.
Encoding.RegisterProvider(CodePagesEncodingProvider.Instance);

var builder = WebApplication.CreateBuilder(args);

// ── Ayarlar (tek merkez: appsettings "Ozi" bölümü) ───────────────────────────
var appSettings = builder.Configuration.GetSection(OziAppSettings.SectionName).Get<OziAppSettings>()
                  ?? new OziAppSettings();
builder.Services.AddSingleton(appSettings);
builder.Services.AddSingleton(appSettings.Jwt);
builder.Services.AddSingleton(appSettings.Hbys);
builder.Services.AddSingleton(appSettings.Sms);

// ── İstek bağlamı + alan olayları (domain events) ────────────────────────────
builder.Services.AddHttpContextAccessor();
builder.Services.AddScoped<IApplicationContext, HttpApplicationContext>();
builder.Services.AddScoped<IDomainEventDispatcher, DomainEventDispatcher>();

// ── Veritabanı (sağlayıcı OnConfiguring içinde OziAppSettings'ten seçilir) ────
builder.Services.AddDbContext<AppDbContext>();

// ── Güvenlik (şifre hash + JWT) ──────────────────────────────────────────────
builder.Services.AddSingleton<IPasswordHasher<AdminUser>, PasswordHasher<AdminUser>>();
builder.Services.AddSingleton<JwtTokenService>();
builder.Services
    .AddAuthentication(JwtBearerDefaults.AuthenticationScheme)
    .AddJwtBearer(options =>
    {
        options.MapInboundClaims = false; // claim adlarını koru (sub, unique_name, displayName)
        options.TokenValidationParameters = new TokenValidationParameters
        {
            ValidateIssuer = true,
            ValidIssuer = appSettings.Jwt.Issuer,
            ValidateAudience = true,
            ValidAudience = appSettings.Jwt.Audience,
            ValidateIssuerSigningKey = true,
            IssuerSigningKey = new SymmetricSecurityKey(Encoding.UTF8.GetBytes(appSettings.Jwt.Key)),
            ValidateLifetime = true,
            ClockSkew = TimeSpan.FromSeconds(30)
        };
    });
builder.Services.AddAuthorization();

// ── HBYS entegrasyonu ────────────────────────────────────────────────────────
builder.Services.AddHttpClient(HbysClient.HttpClientName, client =>
{
    client.Timeout = TimeSpan.FromSeconds(appSettings.Hbys.TimeoutSeconds);
    client.DefaultRequestHeaders.TryAddWithoutValidation("Accept-Language", "tr");
    client.DefaultRequestHeaders.TryAddWithoutValidation("Accept", "*/*");
});
builder.Services.AddSingleton<HbysTokenProvider>();
builder.Services.AddScoped<HbysClient>();

// Turkcell HBYS'nin birebir mock'u (DB'ye gitmez) — mobil uygulama canlıda
// doğrudan Turkcell'e, geliştirmede bu mock'a bağlanır. Bkz. Features/HbysMock.
builder.Services.AddSingleton<HbysMockTokenStore>();

// ── SMS / OTP (3G Bilişim) ───────────────────────────────────────────────────
// Turkcell HBYS'de SMS servisi olmadığı için OTP akışını bu backend sağlar.
builder.Services.AddHttpClient(Bilisim3GSmsSender.HttpClientName, client =>
    client.Timeout = TimeSpan.FromSeconds(appSettings.Sms.TimeoutSeconds));
builder.Services.AddSingleton<ISmsSender, Bilisim3GSmsSender>();
builder.Services.AddSingleton<OtpStore>();

// ── JSON / hata / OpenAPI ────────────────────────────────────────────────────
builder.Services.ConfigureHttpJsonOptions(options =>
{
    options.SerializerOptions.PropertyNamingPolicy = JsonNamingPolicy.CamelCase;
    options.SerializerOptions.Converters.Add(new JsonStringEnumConverter(JsonNamingPolicy.CamelCase));
});
builder.Services.AddExceptionHandler<GlobalExceptionHandler>();
builder.Services.AddProblemDetails();
builder.Services.AddOpenApi();

// ── CORS (panel için) ────────────────────────────────────────────────────────
const string corsPolicy = "PanelCors";
builder.Services.AddCors(options =>
    options.AddPolicy(corsPolicy, policy =>
        policy.WithOrigins(appSettings.Cors.AllowedOrigins).AllowAnyHeader().AllowAnyMethod()));

var app = builder.Build();

// ── Pipeline ─────────────────────────────────────────────────────────────────
app.UseExceptionHandler();
app.UseCors(corsPolicy);
app.UseAuthentication();
app.UseAuthorization();

app.MapOpenApi();
app.MapScalarApiReference(); // /scalar

app.MapGet("/health", () => Results.Ok(new { status = "ok", time = DateTime.UtcNow }))
   .WithTags("System");

// ⭐ Turkcell HBYS dokümanı ile BİREBİR mock uçları (mobil uygulama bunları kullanır).
app.MapHbysMockEndpoints();

// SMS ile doğrulama (OTP) — mobil giriş akışı bunu kullanır.
app.MapOtpEndpoints();

app.MapAuthEndpoints();
app.MapHospitalInfoEndpoints();
app.MapMenuEndpoints();
app.MapPersonnelEndpoints();

// İlk açılışta migration + tohum verisi (PostgreSQL).
await DbSeeder.MigrateAndSeedAsync(app.Services);

app.Run();
