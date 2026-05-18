using System;
using System.Collections.Generic;
using System.ComponentModel.DataAnnotations;

namespace SmartGuard.Services.Database
{
    public class KnownPerson
    {
        [Key]
        public int Id { get; set; }
        public string FirstName { get; set; } = string.Empty;
        public string LastName { get; set; } = string.Empty;
        public string Description { get; set; } = string.Empty;
        public string Picture { get; set; } = string.Empty;

        public DateTime CreatedAt { get; set; } = DateTime.UtcNow;

        public int? FaceId { get; set; }
        public int DetectionCount { get; set; }

        public ICollection<FaceDetectionEvent> FaceDetectionEvents { get; set; } = null!;
        public ICollection<UserNotificationPreference> UserNotificationPreferences { get; set; } = null!;
    }
}
