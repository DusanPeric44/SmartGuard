using System;

namespace SmartGuard.Model.SearchObjects
{
    public class AuditLogSearchObject : BaseSearchObject
    {
        public string UserId { get; set; }
        public string Action { get; set; }
        public DateTime? From { get; set; }
        public DateTime? To { get; set; }
    }
}
