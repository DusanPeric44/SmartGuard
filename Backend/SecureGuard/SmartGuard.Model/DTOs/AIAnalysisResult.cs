namespace SmartGuard.Model.DTOs
{
    public class AIAnalysisResult
    {
        public int Id { get; set; }
        public int? FaceEventId { get; set; }
        public FaceDetectionEvent FaceEvent { get; set; }
        public int? AlertId { get; set; }
        public Alert Alert { get; set; }
        public string Reason { get; set; }
        public double Confidence { get; set; }
        public string Recommendation { get; set; }
    }
}
