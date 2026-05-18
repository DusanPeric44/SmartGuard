using System;
using System.Collections.Generic;

namespace SmartGuard.Model.DTOs.ReportDocuments
{
    public class WeeklyReportDocument
    {
        public DateTime PeriodStartUtc { get; set; }
        public DateTime PeriodEndUtc { get; set; }

        public IList<WeeklyAlertRow> Alerts { get; set; } = new List<WeeklyAlertRow>();
        public IList<WeeklyFaceDetectionRow> FaceDetections { get; set; } = new List<WeeklyFaceDetectionRow>();
        public IList<WeeklyDeviceRow> Devices { get; set; } = new List<WeeklyDeviceRow>();
    }

    public class WeeklyAlertRow
    {
        public int Id { get; set; }
        public string Status { get; set; }
        public string Type { get; set; }
        public DateTime CreatedAtUtc { get; set; }
        public string DeviceName { get; set; }
    }

    public class WeeklyFaceDetectionRow
    {
        public int Id { get; set; }
        public DateTime TimestampUtc { get; set; }
        public string DeviceName { get; set; }
        public int? FaceId { get; set; }
        public string? PersonFirstName { get; set; }
        public string? PersonLastName { get; set; }
    }

    public class WeeklyDeviceRow
    {
        public int Id { get; set; }
        public string Name { get; set; }
        public string Location { get; set; }
        public DateTime CreatedAtUtc { get; set; }
    }
}

