namespace SmartGuard.Model.DTOs
{
    public class KnownPerson
    {
        public int Id { get; set; }
        public string FirstName { get; set; } = string.Empty;
        public string LastName { get; set; } = string.Empty;
        public string Description { get; set; } = string.Empty;
        public string Picture { get; set; } = string.Empty;
        public int? FaceId { get; set; }
        public int DetectionCount { get; set; }
    }
}
