using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;
using Microsoft.AspNetCore.Identity;

namespace SmartGuard.Services.Database
{
    public class UserNotificationPreference
    {
        [Key]
        public int Id { get; set; }

        [ForeignKey("User")]
        public string UserId { get; set; }
        public ApplicationUser User { get; set; }

        [ForeignKey("Person")]
        public int? PersonId { get; set; }
        public KnownPerson Person { get; set; }

        [ForeignKey("AlertType")]
        public int? AlertTypeId { get; set; }
        public AlertType AlertType { get; set; }

        public bool ReceivePush { get; set; }
        public bool ReceiveEmail { get; set; }
    }
}
