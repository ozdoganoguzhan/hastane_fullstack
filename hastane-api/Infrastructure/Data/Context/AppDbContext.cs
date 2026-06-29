using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;
using System.Linq.Expressions;
using System.Reflection;
using Microsoft.EntityFrameworkCore;
using Ozi.Application.Constants;
using Ozi.Application.EventHandling;
using Ozi.Application.Infrastructure.ApplicationContext;
using Ozi.Application.Infrastructure.Config;
using Ozi.Domain.Entities;
using Ozi.Domain.Enums;
using Ozi.Domain.Shared;
using Ozi.Infrastructure.Data.Converters;

namespace Ozi.Infrastructure.Data.Context;

/// <summary>
/// Konvansiyon tabanlı uygulama DbContext'i:
/// • Sağlayıcı seçimi <see cref="OziAppSettings"/> üzerinden (çoklu DB'ye hazır)
/// • Denetim alanları (CreatedBy/UpdatedBy/UpdatedAt) + soft-delete + alan olayı dağıtımı
/// • Otomatik tablo adlandırma, string max-length ve UTC DateTime konvansiyonları.
/// </summary>
public class AppDbContext : DbContext
{
    private readonly IApplicationContext? _applicationContext;
    private readonly IDomainEventDispatcher _domainEventDispatcher;
    private readonly OziAppSettings _appSettings;

    /// <summary>Tasarım zamanı (migration). Sağlayıcı <see cref="OnConfiguring"/> içinde seçilir.</summary>
    public AppDbContext(OziAppSettings appSettings, IDomainEventDispatcher domainEventDispatcher)
    {
        _appSettings = appSettings;
        _domainEventDispatcher = domainEventDispatcher;
    }

    /// <summary>Çalışma zamanı (DI).</summary>
    public AppDbContext(
        DbContextOptions<AppDbContext> options,
        OziAppSettings appSettings,
        IApplicationContext applicationContext,
        IDomainEventDispatcher domainEventDispatcher) : base(options)
    {
        _appSettings = appSettings;
        _applicationContext = applicationContext;
        _domainEventDispatcher = domainEventDispatcher;
    }

    public DbSet<AdminUser> AdminUsers => Set<AdminUser>();
    public DbSet<Announcement> Announcements => Set<Announcement>();
    public DbSet<HospitalInfo> HospitalInfos => Set<HospitalInfo>();

    protected sealed override void OnConfiguring(DbContextOptionsBuilder optionsBuilder)
    {
        if (!optionsBuilder.IsConfigured)
            ConfigureDatabase(optionsBuilder);
    }

    private void ConfigureDatabase(DbContextOptionsBuilder optionsBuilder)
    {
        var database = _appSettings.Database;
        switch (database.DatabaseType)
        {
            case DatabaseType.Postgres:
                optionsBuilder.UseNpgsql(database.ConnectionStrings.Postgres);
                break;
            case DatabaseType.SqlServer:
            case DatabaseType.Sqlite:
            case DatabaseType.MySql:
                throw new NotImplementedException(
                    $"{database.DatabaseType} sağlayıcısı bu derlemede etkin değil (yalnızca Postgres).");
            default:
                throw new ArgumentOutOfRangeException(
                    nameof(optionsBuilder), database.DatabaseType, "Desteklenmeyen veritabanı tipi.");
        }
    }

    public override async Task<int> SaveChangesAsync(CancellationToken cancellationToken = default)
    {
        var userId = _applicationContext?.UserContext?.User.Id;
        var now = DateTime.Now;
        var trackedEntities = ChangeTracker.Entries<EntityBase>().ToList();

        foreach (var entry in trackedEntities)
        {
            switch (entry.State)
            {
                case EntityState.Added:
                    if (userId is not null) entry.Entity.CreatedBy = userId.Value;
                    break;
                case EntityState.Modified:
                    if (userId is not null) entry.Entity.UpdatedBy = userId.Value;
                    entry.Entity.UpdatedAt = now;
                    break;
                case EntityState.Deleted:
                    // Soft-delete: fiziksel silmek yerine işaretle.
                    entry.State = EntityState.Modified;
                    entry.Entity.Deleted = true;
                    entry.Entity.UpdatedAt = now;
                    if (userId is not null) entry.Entity.UpdatedBy = userId.Value;
                    break;
            }

            if (entry.Entity.DomainEvents.Count != 0)
                await _domainEventDispatcher.DispatchAsync(entry.Entity.DomainEvents, cancellationToken);
        }

        var result = await base.SaveChangesAsync(cancellationToken);
        trackedEntities.ForEach(e => e.Entity.ClearDomainEvents());
        return result;
    }

    /// <summary>Tablolarımız bu Postgres şemasında izole edilir (paylaşımlı "angora" DB'sindeki tablolarla çakışmaz).</summary>
    public const string Schema = "hastane_menu";

    protected override void OnModelCreating(ModelBuilder modelBuilder)
    {
        // Tüm varlıklar + __EFMigrationsHistory bu şemaya yerleşir (mevcut public tablolarla çakışmayı önler).
        modelBuilder.HasDefaultSchema(Schema);

        // 1) EntityBase'ten türeyen tüm somut varlıkları keşfet: tablo adı + anahtar + soft-delete filtresi.
        var entityTypes = AppConstants.BaseEntityType.Assembly.GetTypes()
            .Where(t => AppConstants.BaseEntityType.IsAssignableFrom(t)
                        && t is { IsClass: true, IsAbstract: false, IsGenericType: false }
                        && t.Name != AppConstants.BaseEntityTypeName)
            .ToList();

        foreach (var entityType in entityTypes)
        {
            var tableName = entityType.GetCustomAttribute<TableAttribute>()?.Name ?? entityType.Name switch
            {
                var n when n.EndsWith('y') => string.Concat(n.AsSpan(0, n.Length - 1), "ies"),
                var n when n.EndsWith('s') => n + "es",
                var n => n + "s"
            };

            var builder = modelBuilder.Entity(entityType);
            builder.ToTable(tableName);
            builder.HasKey(nameof(IEntity.Id));
            builder.Ignore(nameof(IEntity.DomainEvents));

            // Soft-delete global query filter: e => !e.Deleted
            var parameter = Expression.Parameter(entityType, "e");
            var filter = Expression.Lambda(
                Expression.Not(Expression.Property(parameter, nameof(IEntity.Deleted))), parameter);
            builder.HasQueryFilter(filter);
        }

        // 2) Tüm varlıklar için string (max-length + required) ve DateTime (UTC) konvansiyonları.
        var nullabilityContext = new NullabilityInfoContext();
        foreach (var entity in modelBuilder.Model.GetEntityTypes()
                     .Where(e => !AppConstants.BaseValueObjectType.IsAssignableFrom(e.ClrType)))
        {
            var clrProperties = entity.ClrType.GetProperties();

            foreach (var stringProperty in clrProperties.Where(p =>
                         p.PropertyType == typeof(string)
                         && p.GetCustomAttribute<NotMappedAttribute>() is null
                         && entity.FindProperty(p.Name) is not null))
            {
                var propertyBuilder = modelBuilder.Entity(entity.ClrType).Property(stringProperty.Name);

                if (stringProperty.GetCustomAttribute<MaxLengthAttribute>() is null)
                    propertyBuilder.HasMaxLength(ConfigurationConstants.DefaultStringMaxLength);

                var isNullable = nullabilityContext.Create(stringProperty).WriteState == NullabilityState.Nullable;
                propertyBuilder.IsRequired(!isNullable);
            }

            foreach (var dateTimeProperty in clrProperties.Where(p =>
                         (p.PropertyType == typeof(DateTime) || p.PropertyType == typeof(DateTime?))
                         && entity.FindProperty(p.Name) is not null))
            {
                modelBuilder.Entity(entity.ClrType).Property(dateTimeProperty.Name)
                    .HasConversion(new UtcDateTimeConverter());
            }
        }

        base.OnModelCreating(modelBuilder);

        // 3) Varlığa özel ince ayarlar (IEntityTypeConfiguration) — konvansiyonları ezer.
        modelBuilder.ApplyConfigurationsFromAssembly(typeof(AppDbContext).Assembly);
    }
}
