using System;
using System.Collections.Generic;

namespace SmartGuard.Model.DTOs.ReportDocuments
{
    public class SecurityActivityReportDocument
    {
        public DateTime PeriodStartUtc { get; set; }
        public DateTime PeriodEndUtc { get; set; }

        public IList<SecurityActivityAlertRow> Alerts { get; set; } = new List<SecurityActivityAlertRow>();
        public IList<SecurityActivityKnownPersonRow> KnownPersons { get; set; } = new List<SecurityActivityKnownPersonRow>();
        public IList<SecurityActivityFaceDetectionRow> FaceDetections { get; set; } = new List<SecurityActivityFaceDetectionRow>();
    }

    public class SecurityActivityAlertRow
    {
        public int Id { get; set; }
        public string Status { get; set; }
        public string Type { get; set; }
        public DateTime CreatedAtUtc { get; set; }
        public string DeviceName { get; set; }
    }

    public class SecurityActivityKnownPersonRow
    {
        public int Id { get; set; }
        public string FirstName { get; set; }
        public string LastName { get; set; }
        public DateTime CreatedAtUtc { get; set; }
    }

    public class SecurityActivityFaceDetectionRow
    {
        public int Id { get; set; }
        public DateTime TimestampUtc { get; set; }
        public string DeviceName { get; set; }
        public int? FaceId { get; set; }
        public string? PersonFirstName { get; set; }
        public string? PersonLastName { get; set; }
    }
}

