using System;

namespace SmartGuard.Model.DTOs
{
    public class AuditLog
    {
        public int Id { get; set; }
        public string UserId { get; set; }
        public string Action { get; set; }
        public string Resource { get; set; }
        public string Status { get; set; }
        public DateTime Timestamp { get; set; }
        public string Details { get; set; }
    }
}
