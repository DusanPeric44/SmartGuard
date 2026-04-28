using System;

namespace SmartGuard.Model.DTOs
{
    public class Notification
    {
        public int Id { get; set; }
        public string UserId { get; set; }
        public string Title { get; set; }
        public string Text { get; set; }
        public DateTime Timestamp { get; set; }
        public bool IsRead { get; set; }
    }
}
