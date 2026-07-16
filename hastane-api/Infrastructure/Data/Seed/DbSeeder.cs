using Microsoft.AspNetCore.Identity;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Logging;
using Ozi.Application.Infrastructure.Config;
using Ozi.Domain.Entities;
using Ozi.Infrastructure.Data.Context;

namespace Ozi.Infrastructure.Data.Seed;

/// <summary>Migration'ları uygular ve ilk açılışta temel veriyi tohumlar.</summary>
public static class DbSeeder
{
    public static async Task MigrateAndSeedAsync(IServiceProvider services)
    {
        using var scope = services.CreateScope();
        var sp = scope.ServiceProvider;
        var db = sp.GetRequiredService<AppDbContext>();
        var hasher = sp.GetRequiredService<IPasswordHasher<AdminUser>>();
        var settings = sp.GetRequiredService<OziAppSettings>();
        var logger = sp.GetRequiredService<ILoggerFactory>().CreateLogger("DbSeeder");

        logger.LogInformation("Veritabanı migration'ları uygulanıyor (PostgreSQL)...");
        await db.Database.MigrateAsync();

        if (!await db.AdminUsers.AnyAsync())
        {
            var user = new AdminUser
            {
                Username = settings.Seed.AdminUsername,
                DisplayName = settings.Seed.AdminDisplayName,
                Role = "admin"
            };
            user.PasswordHash = hasher.HashPassword(user, settings.Seed.AdminPassword);
            db.AdminUsers.Add(user);
            logger.LogInformation("Varsayılan yönetici oluşturuldu: '{Username}'", settings.Seed.AdminUsername);
        }

        if (!await db.HospitalInfos.AnyAsync())
        {
            db.HospitalInfos.Add(new HospitalInfo
            {
                HospitalName = "Eskişehir Şehir Hastanesi",
                Subtitle = "Yemekhane Menü Sistemi",
                Description =
                    "Yemekhanemiz hafta içi her gün personelimize hijyenik ve dengeli " +
                    "beslenme imkânı sunar. Menüler diyetisyen kontrolünde hazırlanmaktadır.",
                WorkingHours = "Pzt-Cum: 11:30 - 13:30 | 17:30 - 19:00",
                Location = "B Blok, Zemin Kat, Yemekhane Salonu",
                Contact = "Dahili: 4500 | Mutfak Şefi: 4501"
            });
            logger.LogInformation("Varsayılan hastane bilgisi tohumlandı.");
        }

        await db.SaveChangesAsync();
    }
}
