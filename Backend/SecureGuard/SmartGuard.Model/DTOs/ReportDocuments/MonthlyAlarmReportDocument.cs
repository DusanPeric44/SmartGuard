using System;
using System.Collections.Generic;

namespace SmartGuard.Model.DTOs.ReportDocuments
{
    public class MonthlyAlarmReportDocument
    {
        public DateTime PeriodStartUtc { get; set; }
        public DateTime PeriodEndUtc { get; set; }

        public IList<MonthlyAlarmAlertRow> Alerts { get; set; } = new List<MonthlyAlarmAlertRow>();
        public IList<MonthlyAlarmFaceDetectionRow> FaceDetections { get; set; } = new List<MonthlyAlarmFaceDetectionRow>();
    }

    public class MonthlyAlarmAlertRow
    {
        public int Id { get; set; }
        public string Status { get; set; }
        public string Type { get; set; }
        public string? ConfirmedOrDismissedBy { get; set; }
        public DateTime CreatedAtUtc { get; set; }
        public string DeviceName { get; set; }
        public string? PersonFirstName { get; set; }
        public string? PersonLastName { get; set; }
    }

    public class MonthlyAlarmFaceDetectionRow
    {
        public int Id { get; set; }
        public DateTime TimestampUtc { get; set; }
        public string DeviceName { get; set; }
        public int? FaceId { get; set; }
        public string? PersonFirstName { get; set; }
        public string? PersonLastName { get; set; }
    }
}

