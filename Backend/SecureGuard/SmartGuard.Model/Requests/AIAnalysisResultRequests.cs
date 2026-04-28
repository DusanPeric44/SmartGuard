namespace SmartGuard.Model.Requests
{
    public class AIAnalysisResultInsertRequest
    {
        public int? FaceEventId { get; set; }
        public int? AlertId { get; set; }
        public string Reason { get; set; }
        public double Confidence { get; set; }
        public string Recommendation { get; set; }
    }

    public class AIAnalysisResultUpdateRequest
    {
        public string Reason { get; set; }
        public double? Confidence { get; set; }
        public string Recommendation { get; set; }
    }
}
