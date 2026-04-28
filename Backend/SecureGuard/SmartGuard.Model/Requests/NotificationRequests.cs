using System;
using System.ComponentModel.DataAnnotations;

namespace SmartGuard.Model.Requests
{
    public class NotificationInsertRequest
    {
        public string UserId { get; set; }
        [Required]
        public string Title { get; set; }
        [Required]
        public string Text { get; set; }
        public DateTime Timestamp { get; set; }
    }

    public class NotificationUpdateRequest
    {
        public bool? IsRead { get; set; }
    }
}
