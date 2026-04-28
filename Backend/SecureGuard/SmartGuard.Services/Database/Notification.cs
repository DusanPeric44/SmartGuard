using System;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;
using Microsoft.AspNetCore.Identity;

namespace SmartGuard.Services.Database
{
    public class Notification
    {
        [Key]
        public int Id { get; set; }

        [ForeignKey("User")]
        public string UserId { get; set; }
        public IdentityUser User { get; set; }

        public string Title { get; set; }
        public string Text { get; set; }
        public DateTime Timestamp { get; set; }
        public bool IsRead { get; set; }
    }
}
