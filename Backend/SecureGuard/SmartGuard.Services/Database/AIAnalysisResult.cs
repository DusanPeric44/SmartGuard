using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace SmartGuard.Services.Database
{
    public class AIAnalysisResult
    {
        [Key]
        public int Id { get; set; }

        [ForeignKey("FaceEvent")]
        public int? FaceEventId { get; set; }
        public FaceDetectionEvent FaceEvent { get; set; }

        [ForeignKey("Alert")]
        public int? AlertId { get; set; }
        public Alert Alert { get; set; }

        public string Reason { get; set; }
        public double Confidence { get; set; }
        public string Recommendation { get; set; }
    }
}
