using System;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace SmartGuard.Services.Database
{
    public class Report
    {
        [Key]
        public int Id { get; set; }

        [ForeignKey("ReportType")]
        public int TypeId { get; set; }
        public ReportType ReportType { get; set; }

        [ForeignKey("ReportStatus")]
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
