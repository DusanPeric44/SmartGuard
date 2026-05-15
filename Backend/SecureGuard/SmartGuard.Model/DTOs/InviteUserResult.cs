namespace SmartGuard.Model.DTOs
{
    public class InviteUserResult
    {
        public string UserId { get; set; }
        public string Email { get; set; }
        public string Role { get; set; }
        public string TemporaryPassword { get; set; }
    }
}
