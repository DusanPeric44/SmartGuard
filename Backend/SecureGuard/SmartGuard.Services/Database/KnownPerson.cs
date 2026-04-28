using System.Collections.Generic;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;
using Microsoft.AspNetCore.Identity;

namespace SmartGuard.Services.Database
{
    public class KnownPerson
    {
        [Key]
        public int Id { get; set; }
        public string FirstName { get; set; }
        public string LastName { get; set; }
        public string Description { get; set; }
        public byte[] FaceEmbedding { get; set; }
        public string Picture { get; set; }

        [ForeignKey("Owner")]
        public string OwnerId { get; set; }
        public IdentityUser Owner { get; set; }

        public ICollection<FaceDetectionEvent> FaceDetectionEvents { get; set; }
        public ICollection<UserNotificationPreference> UserNotificationPreferences { get; set; }
    }
}
