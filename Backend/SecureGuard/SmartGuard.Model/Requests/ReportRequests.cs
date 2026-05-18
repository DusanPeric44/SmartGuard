using System;

namespace SmartGuard.Model.Requests
{
    public class ReportInsertRequest
    {
        public int TypeId { get; set; }
        public int StatusId { get; set; }
        public DateTime PeriodStartUtc { get; set; }
        public DateTime PeriodEndUtc { get; set; }
        public DateTime? GeneratedAtUtc { get; set; }
        public string? GeneratedByUserId { get; set; }
        public string FileUrl { get; set; }
        public string? Error { get; set; }
    }

    public class ReportUpdateRequest
    {
        public int? TypeId { get; set; }
        public int? StatusId { get; set; }
        public DateTime? PeriodStartUtc { get; set; }
        public DateTime? PeriodEndUtc { get; set; }
        public DateTime? GeneratedAtUtc { get; set; }
        public string? GeneratedByUserId { get; set; }
        public string? FileUrl { get; set; }
        public string? Error { get; set; }
    }

    public class SecurityActivityReportGenerateRequest
    {
        public DateTime Start { get; set; }
        public DateTime End { get; set; }
    }
}
