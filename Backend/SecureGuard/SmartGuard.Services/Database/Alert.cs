using System;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;
using Microsoft.AspNetCore.Identity;

namespace SmartGuard.Services.Database
{
    public class Alert : ISoftDeletable
    {
        [Key]
        public int Id { get; set; }

        public DateTime CreatedAt { get; set; } = DateTime.UtcNow;

        [ForeignKey("AlertType")]
        public int TypeId { get; set; }
        public AlertType AlertType { get; set; }

        [ForeignKey("AlertStatus")]
        public int StatusId { get; set; }
        public AlertStatus AlertStatus { get; set; }

        public string Description { get; set; }
        
        public string? DismissalReason { get; set; }

        [ForeignKey("Device")]
        public int? DeviceId { get; set; }
        public Device? Device { get; set; }

        [ForeignKey("LinkedEvent")]
        public int? LinkedEventId { get; set; }
        public FaceDetectionEvent? LinkedEvent { get; set; }

        [ForeignKey("ConfirmedByUser")]
        public string? ConfirmedByUserId { get; set; }
        public ApplicationUser? ConfirmedByUser { get; set; }

        public bool IsDeleted { get; set; }
    }
}
