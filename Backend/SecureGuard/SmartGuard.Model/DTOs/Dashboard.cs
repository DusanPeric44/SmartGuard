using System.Collections.Generic;

namespace SmartGuard.Model.DTOs
{
    public class Dashboard
    {
        public DashboardDesktop Desktop { get; set; } = new();
        public DashboardMobile Mobile { get; set; } = new();
    }

    public class DashboardDesktop
    {
        public int DevicesCount { get; set; }
        public int ConnectedDevicesCount { get; set; }
        public int RecordingsCount { get; set; }
        public int PendingAlarmsCount { get; set; }
        public int ActiveUsersCount { get; set; }
        public long UsedVideosBytes { get; set; }
        public long UsedImagesBytes { get; set; }
        public long UsedReportsBytes { get; set; }
        public List<AuditLog> LastAuditLogs { get; set; } = [];
    }

    public class DashboardMobile
    {
        public int DevicesCount { get; set; }
        public int PendingAlarmsCount { get; set; }
        public List<DashboardDeviceListItem> Devices { get; set; } = [];
    }

    public class DashboardDeviceListItem
    {
        public int Id { get; set; }
        public string Name { get; set; } = string.Empty;
    }
}

