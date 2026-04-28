using System.Collections.Generic;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;
using Microsoft.AspNetCore.Identity;

namespace SmartGuard.Services.Database
{
    public class Alert
    {
        [Key]
        public int Id { get; set; }

        [ForeignKey("AlertType")]
        public int TypeId { get; set; }
        public AlertType AlertType { get; set; }

        [ForeignKey("AlertStatus")]
        public int StatusId { get; set; }
        public AlertStatus AlertStatus { get; set; }

        public string Description { get; set; }

        [ForeignKey("Device")]
        public int DeviceId { get; set; }
        public Device Device { get; set; }

        [ForeignKey("LinkedEvent")]
        public int? LinkedEventId { get; set; }
        public FaceDetectionEvent LinkedEvent { get; set; }

        [ForeignKey("ConfirmedByUser")]
        public string ConfirmedByUserId { get; set; }
        public IdentityUser ConfirmedByUser { get; set; }

        public bool IsDeleted { get; set; }

        public ICollection<AIAnalysisResult> AIAnalysisResults { get; set; }
    }
}
