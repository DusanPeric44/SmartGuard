using System;
using System.IO;
using System.Threading.Tasks;
using SmartGuard.Model.SearchObjects;
using SmartGuard.Model.DTOs;
using SmartGuard.Model.Requests;

namespace SmartGuard.Model.Interfaces
{
    public interface IUsersService : IBaseGetService<UserDto, UsersSearchObject>
    {
        Task<InviteUserResult> InviteAsync(InviteUserRequest request);
        Task<UserDto> UpdateAsync(string id, UpdateUserRequest request);
        Task DeleteAsync(string id);
    }

    public interface IReportsService : IBaseCRUDService<Report, ReportSearchObject, ReportInsertRequest, ReportUpdateRequest>
    {
        Task<Report> GenerateSecurityActivityAsync(DateTime startUtc, DateTime endUtc, string? userId);
        Task<Report> GenerateWeeklyAsync(DateTime weekStartUtc);
        Task<Report> GenerateMonthlyAsync(DateTime monthStartUtc);
        Task<(Stream Stream, string ContentType, string FileName)> OpenReportFileAsync(int reportId);
    }
}
