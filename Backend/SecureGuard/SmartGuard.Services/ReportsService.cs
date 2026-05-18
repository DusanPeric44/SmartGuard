using System.IO;
using Mapster;
using Microsoft.EntityFrameworkCore;
using QuestPDF.Infrastructure;
using SmartGuard.Model;
using SmartGuard.Model.DTOs.ReportDocuments;
using SmartGuard.Model.Interfaces;
using SmartGuard.Model.Requests;
using SmartGuard.Model.SearchObjects;
using SmartGuard.Services.Database;
using SmartGuard.Services.Reports.Pdf;

namespace SmartGuard.Services
{
    public class ReportsService : BaseCRUDService<Model.DTOs.Report, Database.Report, ReportSearchObject, ReportInsertRequest, ReportUpdateRequest>, IReportsService
    {
        private readonly IFileStorageService _fileStorage;
        private static bool _licenseConfigured;
        private static readonly object _licenseLock = new();

        public ReportsService(SmartGuardContext context, IFileStorageService fileStorage) : base(context)
        {
            _fileStorage = fileStorage;

            if (!_licenseConfigured)
            {
                lock (_licenseLock)
                {
                    if (!_licenseConfigured)
                    {
                        QuestPDF.Settings.License = LicenseType.Community;
                        _licenseConfigured = true;
                    }
                }
            }
        }

        protected override IQueryable<Database.Report> AddFilter(IQueryable<Database.Report> query, ReportSearchObject search = null)
        {
            if (search?.Start.HasValue == true)
            {
                query = query.Where(x => x.PeriodStartUtc >= search.Start.Value);
            }

            if (search?.End.HasValue == true)
            {
                query = query.Where(x => x.PeriodEndUtc <= search.End.Value);
            }

            if (search?.TypeId.HasValue == true)
            {
                query = query.Where(x => x.TypeId == search.TypeId.Value);
            }

            if (search?.StatusId.HasValue == true)
            {
                query = query.Where(x => x.StatusId == search.StatusId.Value);
            }

            return query;
        }

        protected override IQueryable<Database.Report> AddInclude(IQueryable<Database.Report> query, ReportSearchObject search = null)
        {
            return query
                .Include(x => x.ReportType)
                .Include(x => x.ReportStatus);
        }

        public Task<Model.DTOs.Report> GenerateSecurityActivityAsync(DateTime startUtc, DateTime endUtc, string? userId)
        {
            if (endUtc <= startUtc)
            {
                throw new UserException("EndUtc must be greater than StartUtc");
            }

            var start = startUtc;
            var end = endUtc;

            if (start.Kind != DateTimeKind.Utc) start = DateTime.SpecifyKind(start, DateTimeKind.Utc);
            if (end.Kind != DateTimeKind.Utc) end = DateTime.SpecifyKind(end, DateTimeKind.Utc);

            return GenerateReportAsync("SecurityActivity", start, end, userId);
        }

        public Task<Model.DTOs.Report> GenerateWeeklyAsync(DateTime weekStartUtc)
        {
            var start = weekStartUtc.Date;
            return GenerateReportAsync("WeeklySummary", start, start.AddDays(7), null);
        }

        public Task<Model.DTOs.Report> GenerateMonthlyAsync(DateTime monthStartUtc)
        {
            var start = new DateTime(monthStartUtc.Year, monthStartUtc.Month, 1, 0, 0, 0, DateTimeKind.Utc);
            return GenerateReportAsync("MonthlyAlarm", start, start.AddMonths(1), null);
        }

        public async Task<(Stream Stream, string ContentType, string FileName)> OpenReportFileAsync(int reportId)
        {
            var report = await _context.Reports
                .AsNoTracking()
                .Include(x => x.ReportType)
                .SingleOrDefaultAsync(x => x.Id == reportId);

            if (report == null)
            {
                throw new UserException("Report not found");
            }

            if (string.IsNullOrWhiteSpace(report.FileUrl))
            {
                throw new UserException("Report file is not available");
            }

            var (stream, contentType) = await _fileStorage.OpenReadAsync(report.FileUrl);
            var fileName = $"{report.ReportType.Name}_{report.PeriodStartUtc:yyyyMMdd}_{report.PeriodEndUtc:yyyyMMdd}.pdf";
            return (stream, contentType, fileName);
        }

        private async Task<Model.DTOs.Report> GenerateReportAsync(string reportTypeName, DateTime periodStartUtc, DateTime periodEndUtc, string? generatedByUserId)
        {
            var reportType = await _context.ReportTypes.SingleAsync(x => x.Name == reportTypeName);
            var generatingStatusId = await _context.ReportStatuses.Where(x => x.Name == "Generating").Select(x => x.Id).SingleAsync();
            var generatedStatusId = await _context.ReportStatuses.Where(x => x.Name == "Generated").Select(x => x.Id).SingleAsync();
            var failedStatusId = await _context.ReportStatuses.Where(x => x.Name == "Failed").Select(x => x.Id).SingleAsync();

            var report = await _context.Reports
                .Include(x => x.ReportType)
                .Include(x => x.ReportStatus)
                .SingleOrDefaultAsync(x =>
                    x.TypeId == reportType.Id &&
                    x.PeriodStartUtc == periodStartUtc &&
                    x.PeriodEndUtc == periodEndUtc);

            if (report != null && report.StatusId == generatedStatusId && !string.IsNullOrWhiteSpace(report.FileUrl))
            {
                return report.Adapt<Model.DTOs.Report>();
            }

            if (report == null)
            {
                report = new Database.Report
                {
                    TypeId = reportType.Id,
                    StatusId = generatingStatusId,
                    PeriodStartUtc = periodStartUtc,
                    PeriodEndUtc = periodEndUtc,
                    GeneratedByUserId = generatedByUserId,
                    FileUrl = string.Empty
                };

                _context.Reports.Add(report);
                await _context.SaveChangesAsync();
            }
            else
            {
                report.StatusId = generatingStatusId;
                report.GeneratedAtUtc = null;
                report.GeneratedByUserId = generatedByUserId;
                report.Error = null;
                await _context.SaveChangesAsync();
            }

            try
            {
                var pdfBytes = reportTypeName switch
                {
                    "MonthlyAlarm" => MonthlyAlarmReportPdf.Render(await BuildMonthlyAlarmReportDocumentAsync(periodStartUtc, periodEndUtc)),
                    "WeeklySummary" => WeeklyReportPdf.Render(await BuildWeeklyReportDocumentAsync(periodStartUtc, periodEndUtc)),
                    "SecurityActivity" => SecurityActivityReportPdf.Render(await BuildSecurityActivityReportDocumentAsync(periodStartUtc, periodEndUtc)),
                    _ => throw new UserException("Unknown report type")
                };

                var fileUrl = await _fileStorage.SaveFileAsync(pdfBytes, ".pdf", Path.Combine("reports", reportTypeName));

                report.FileUrl = fileUrl;
                report.GeneratedAtUtc = DateTime.UtcNow;
                report.StatusId = generatedStatusId;
                report.Error = null;
                await _context.SaveChangesAsync();
            }
            catch (Exception ex)
            {
                report.StatusId = failedStatusId;
                report.Error = ex.Message;
                await _context.SaveChangesAsync();
            }

            var result = await _context.Reports
                .AsNoTracking()
                .Include(x => x.ReportType)
                .Include(x => x.ReportStatus)
                .SingleAsync(x => x.Id == report.Id);

            return result.Adapt<Model.DTOs.Report>();
        }

        private async Task<MonthlyAlarmReportDocument> BuildMonthlyAlarmReportDocumentAsync(DateTime periodStartUtc, DateTime periodEndUtc)
        {
            var alerts = await _context.Alerts
                .AsNoTracking()
                .Where(x => x.CreatedAt >= periodStartUtc && x.CreatedAt < periodEndUtc)
                .Include(x => x.AlertStatus)
                .Include(x => x.AlertType)
                .Include(x => x.Device)
                .Include(x => x.ConfirmedByUser)
                .Include(x => x.LinkedEvent)
                    .ThenInclude(x => x.Person)
                .OrderBy(x => x.CreatedAt)
                .ToListAsync();

            var detections = await _context.FaceDetectionEvents
                .AsNoTracking()
                .Where(x => x.Timestamp >= periodStartUtc && x.Timestamp < periodEndUtc)
                .Include(x => x.Device)
                .Include(x => x.Person)
                .OrderBy(x => x.Timestamp)
                .ToListAsync();

            var result = new MonthlyAlarmReportDocument
            {
                PeriodStartUtc = periodStartUtc,
                PeriodEndUtc = periodEndUtc
            };

            foreach (var a in alerts)
            {
                var by = a.ConfirmedByUser != null
                    ? $"{a.ConfirmedByUser.FirstName} {a.ConfirmedByUser.LastName}".Trim()
                    : a.ConfirmedByUserId;

                var linkedEvent = a.LinkedEventId.HasValue ? a.LinkedEvent : null;
                var person = linkedEvent?.PersonId.HasValue == true ? linkedEvent.Person : null;

                result.Alerts.Add(new MonthlyAlarmAlertRow
                {
                    Id = a.Id,
                    Status = a.AlertStatus?.Name ?? string.Empty,
                    Type = a.AlertType?.Name ?? string.Empty,
                    ConfirmedOrDismissedBy = string.IsNullOrWhiteSpace(by) ? null : by,
                    CreatedAtUtc = a.CreatedAt,
                    DeviceName = a.Device?.Name ?? string.Empty,
                    PersonFirstName = person?.FirstName,
                    PersonLastName = person?.LastName
                });
            }

            foreach (var d in detections)
            {
                result.FaceDetections.Add(new MonthlyAlarmFaceDetectionRow
                {
                    Id = d.Id,
                    TimestampUtc = d.Timestamp,
                    DeviceName = d.Device?.Name ?? string.Empty,
                    FaceId = d.FaceId,
                    PersonFirstName = d.PersonId.HasValue ? d.Person?.FirstName : null,
                    PersonLastName = d.PersonId.HasValue ? d.Person?.LastName : null
                });
            }

            return result;
        }

        private async Task<WeeklyReportDocument> BuildWeeklyReportDocumentAsync(DateTime periodStartUtc, DateTime periodEndUtc)
        {
            var alerts = await _context.Alerts
                .AsNoTracking()
                .Where(x => x.CreatedAt >= periodStartUtc && x.CreatedAt < periodEndUtc)
                .Include(x => x.AlertStatus)
                .Include(x => x.AlertType)
                .Include(x => x.Device)
                .OrderBy(x => x.CreatedAt)
                .ToListAsync();

            var detections = await _context.FaceDetectionEvents
                .AsNoTracking()
                .Where(x => x.Timestamp >= periodStartUtc && x.Timestamp < periodEndUtc)
                .Include(x => x.Device)
                .Include(x => x.Person)
                .OrderBy(x => x.Timestamp)
                .ToListAsync();

            var devices = await _context.Devices
                .AsNoTracking()
                .Where(x => x.CreatedAt >= periodStartUtc && x.CreatedAt < periodEndUtc)
                .OrderBy(x => x.CreatedAt)
                .ToListAsync();

            var result = new WeeklyReportDocument
            {
                PeriodStartUtc = periodStartUtc,
                PeriodEndUtc = periodEndUtc
            };

            foreach (var d in devices)
            {
                result.Devices.Add(new WeeklyDeviceRow
                {
                    Id = d.Id,
                    Name = d.Name,
                    Location = d.Location,
                    CreatedAtUtc = d.CreatedAt
                });
            }

            foreach (var a in alerts)
            {
                result.Alerts.Add(new WeeklyAlertRow
                {
                    Id = a.Id,
                    Status = a.AlertStatus?.Name ?? string.Empty,
                    Type = a.AlertType?.Name ?? string.Empty,
                    CreatedAtUtc = a.CreatedAt,
                    DeviceName = a.Device?.Name ?? string.Empty
                });
            }

            foreach (var d in detections)
            {
                result.FaceDetections.Add(new WeeklyFaceDetectionRow
                {
                    Id = d.Id,
                    TimestampUtc = d.Timestamp,
                    DeviceName = d.Device?.Name ?? string.Empty,
                    FaceId = d.FaceId,
                    PersonFirstName = d.PersonId.HasValue ? d.Person?.FirstName : null,
                    PersonLastName = d.PersonId.HasValue ? d.Person?.LastName : null
                });
            }

            return result;
        }

        private async Task<SecurityActivityReportDocument> BuildSecurityActivityReportDocumentAsync(DateTime periodStartUtc, DateTime periodEndUtc)
        {
            var alerts = await _context.Alerts
                .AsNoTracking()
                .Where(x => x.CreatedAt >= periodStartUtc && x.CreatedAt < periodEndUtc)
                .Include(x => x.AlertStatus)
                .Include(x => x.AlertType)
                .Include(x => x.Device)
                .OrderBy(x => x.CreatedAt)
                .ToListAsync();

            var persons = await _context.KnownPersons
                .AsNoTracking()
                .Where(x => x.CreatedAt >= periodStartUtc && x.CreatedAt < periodEndUtc)
                .OrderBy(x => x.CreatedAt)
                .ToListAsync();

            var detections = await _context.FaceDetectionEvents
                .AsNoTracking()
                .Where(x => x.Timestamp >= periodStartUtc && x.Timestamp < periodEndUtc)
                .Include(x => x.Device)
                .Include(x => x.Person)
                .OrderBy(x => x.Timestamp)
                .ToListAsync();

            var result = new SecurityActivityReportDocument
            {
                PeriodStartUtc = periodStartUtc,
                PeriodEndUtc = periodEndUtc
            };

            foreach (var a in alerts)
            {
                result.Alerts.Add(new SecurityActivityAlertRow
                {
                    Id = a.Id,
                    Status = a.AlertStatus?.Name ?? string.Empty,
                    Type = a.AlertType?.Name ?? string.Empty,
                    CreatedAtUtc = a.CreatedAt,
                    DeviceName = a.Device?.Name ?? string.Empty
                });
            }

            foreach (var p in persons)
            {
                result.KnownPersons.Add(new SecurityActivityKnownPersonRow
                {
                    Id = p.Id,
                    FirstName = p.FirstName,
                    LastName = p.LastName,
                    CreatedAtUtc = p.CreatedAt
                });
            }

            foreach (var d in detections)
            {
                result.FaceDetections.Add(new SecurityActivityFaceDetectionRow
                {
                    Id = d.Id,
                    TimestampUtc = d.Timestamp,
                    DeviceName = d.Device?.Name ?? string.Empty,
                    FaceId = d.FaceId,
                    PersonFirstName = d.PersonId.HasValue ? d.Person?.FirstName : null,
                    PersonLastName = d.PersonId.HasValue ? d.Person?.LastName : null
                });
            }

            return result;
        }
    }
}
