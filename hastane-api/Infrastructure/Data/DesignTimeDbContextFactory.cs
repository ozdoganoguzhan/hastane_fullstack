using Microsoft.EntityFrameworkCore.Design;
using Microsoft.Extensions.Configuration;
using Ozi.Application.EventHandling;
using Ozi.Application.Infrastructure.Config;
using Ozi.Domain.Shared;
using Ozi.Infrastructure.Data.Context;

namespace Ozi.Infrastructure.Data;

/// <summary><c>dotnet ef</c> komutları için DbContext üretir (web host başlatmadan).</summary>
public class DesignTimeDbContextFactory : IDesignTimeDbContextFactory<AppDbContext>
{
    public AppDbContext CreateDbContext(string[] args)
    {
        var config = new ConfigurationBuilder()
            .SetBasePath(Directory.GetCurrentDirectory())
            .AddJsonFile("appsettings.json", optional: false)
            .AddJsonFile("appsettings.Development.json", optional: true)
            .Build();

        var settings = config.GetSection(OziAppSettings.SectionName).Get<OziAppSettings>() ?? new OziAppSettings();
        return new AppDbContext(settings, new NoOpDomainEventDispatcher());
    }

    /// <summary>Tasarım zamanında olay dağıtımına gerek yoktur.</summary>
    private sealed class NoOpDomainEventDispatcher : IDomainEventDispatcher
    {
        public Task DispatchAsync(
            IReadOnlyCollection<IDomainEvent> domainEvents, CancellationToken cancellationToken = default) =>
            Task.CompletedTask;
    }
}
