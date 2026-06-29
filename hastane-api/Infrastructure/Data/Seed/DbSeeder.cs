using Microsoft.AspNetCore.Identity;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Logging;
using Ozi.Application.Infrastructure.Config;
using Ozi.Domain.Entities;
using Ozi.Domain.Enums;
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

        if (!await db.Announcements.AnyAsync())
        {
            db.Announcements.AddRange(SampleAnnouncements());
            logger.LogInformation("Örnek duyurular tohumlandı.");
        }

        await db.SaveChangesAsync();
    }

    private static IEnumerable<Announcement> SampleAnnouncements()
    {
        (AnnouncementType type, string title, string body, DateTime date)[] items =
        [
            (AnnouncementType.Important, "Ramazan Ayı İftar Menüsü",
                "Ramazan ayı boyunca iftar menüsü 19:00 - 20:30 saatleri arasında sunulacaktır. " +
                "Nöbetçi personel için sahur paketi hazırlanmaktadır.", new DateTime(2026, 4, 7)),
            (AnnouncementType.Info, "Diyabet Dostu Menü Seçeneği",
                "Diyabet hastaları ve personelimiz için özel düşük glisemik indeksli menü seçeneği " +
                "her gün sunulmaktadır.", new DateTime(2026, 4, 5)),
            (AnnouncementType.General, "Hijyen Denetimi Tamamlandı",
                "Yemekhanemiz İl Sağlık Müdürlüğü hijyen denetimini tam puan ile geçmiştir. " +
                "Gıda güvenliği sertifikamız yenilenmiştir.", new DateTime(2026, 4, 3)),
            (AnnouncementType.Info, "Cuma Balık Menüsü",
                "Her Cuma günü taze balık menümüz sunulmaktadır. Balık alerjisi olan personelimiz " +
                "için alternatif tavuk menüsü mevcuttur.", new DateTime(2026, 4, 1)),
            (AnnouncementType.Important, "Yemekhane Bakım Çalışması",
                "19-20 Nisan tarihleri arasında yemekhane havalandırma bakımı yapılacaktır. " +
                "Bu sürede yemekler paket olarak dağıtılacaktır.", new DateTime(2026, 3, 28)),
            (AnnouncementType.General, "Personel Memnuniyet Anketi",
                "Yemekhane hizmet kalitemizi artırmak için memnuniyet anketimize katılımınızı " +
                "bekliyoruz.", new DateTime(2026, 3, 25)),
        ];

        return items.Select(i => new Announcement
        {
            Type = i.type,
            Title = i.title,
            Body = i.body,
            PublishDate = i.date,
            IsPublished = true
        });
    }
}
