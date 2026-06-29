namespace Ozi.Features.HospitalInfo;

public record HospitalInfoDto(
    string HospitalName,
    string Subtitle,
    string Description,
    string WorkingHours,
    string Location,
    string Contact,
    DateTime UpdatedAt);

public record UpdateHospitalInfoRequest(
    string HospitalName,
    string Subtitle,
    string Description,
    string WorkingHours,
    string Location,
    string Contact);
