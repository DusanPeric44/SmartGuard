using System;

namespace SmartGuard.Model.DTOs
{
    public class Report
    {
        public int Id { get; set; }

        public int TypeId { get; set; }
        public ReportType ReportType { get; set; }

        public int StatusId { get; set; }
        public ReportStatus ReportStatus { get; set; }

        public DateTime PeriodStartUtc { get; set; }
        public DateTime PeriodEndUtc { get; set; }
        public DateTime? GeneratedAtUtc { get; set; }

        public string? GeneratedByUserId { get; set; }

        public string FileUrl { get; set; }
        public string? Error { get; set; }
    }
}

