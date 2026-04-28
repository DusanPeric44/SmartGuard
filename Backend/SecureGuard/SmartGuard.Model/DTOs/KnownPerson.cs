namespace SmartGuard.Model.DTOs
{
    public class KnownPerson
    {
        public int Id { get; set; }
        public string FirstName { get; set; }
        public string LastName { get; set; }
        public string Description { get; set; }
        public byte[] FaceEmbedding { get; set; }
        public string Picture { get; set; }
        public string OwnerId { get; set; }
    }
}
