namespace SmartGuard.Model.Requests
{
    public class UserPushTokenUpsertRequest
    {
        public string Token { get; set; }
        public string? Platform { get; set; }
    }
}
