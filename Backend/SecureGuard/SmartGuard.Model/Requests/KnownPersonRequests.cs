using System.ComponentModel.DataAnnotations;

namespace SmartGuard.Model.Requests
{
    public class KnownPersonInsertRequest
    {
        [Required]
        public string FirstName { get; set; }
        [Required]
        public string LastName { get; set; }
        public string Description { get; set; }
        public byte[] FaceEmbedding { get; set; }
        public string Picture { get; set; }
        public string OwnerId { get; set; }
    }

    public class KnownPersonUpdateRequest
    {
        public string FirstName { get; set; }
        public string LastName { get; set; }
        public string Description { get; set; }
        public byte[] FaceEmbedding { get; set; }
        public string Picture { get; set; }
        public string OwnerId { get; set; }
    }
}
