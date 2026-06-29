using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;
using Ozi.Domain.Entities;

namespace Ozi.Infrastructure.Data.Configurations;

public sealed class AnnouncementConfiguration : IEntityTypeConfiguration<Announcement>
{
    public void Configure(EntityTypeBuilder<Announcement> builder)
    {
        builder.Property(x => x.Title).HasMaxLength(200).IsRequired();
        builder.Property(x => x.Body).HasMaxLength(4000).IsRequired();
        // Enum okunabilir string olarak saklanır (Important/Info/General).
        builder.Property(x => x.Type).HasConversion<string>().HasMaxLength(32);
        builder.HasIndex(x => x.PublishDate);
        builder.HasIndex(x => x.IsPublished);
    }
}
