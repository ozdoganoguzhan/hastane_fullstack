using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;
using Ozi.Domain.Entities;

namespace Ozi.Infrastructure.Data.Configurations;

public sealed class HospitalInfoConfiguration : IEntityTypeConfiguration<HospitalInfo>
{
    public void Configure(EntityTypeBuilder<HospitalInfo> builder)
    {
        builder.Property(x => x.HospitalName).HasMaxLength(200).IsRequired();
        builder.Property(x => x.Subtitle).HasMaxLength(200);
        builder.Property(x => x.Description).HasMaxLength(2000);
        builder.Property(x => x.WorkingHours).HasMaxLength(200);
        builder.Property(x => x.Location).HasMaxLength(300);
        builder.Property(x => x.Contact).HasMaxLength(200);
    }
}
