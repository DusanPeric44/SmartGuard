namespace SmartGuard.Model.Interfaces
{
    public interface IUserContext
    {
        string Email { get; }
        string UserId { get; }
        bool IsAdmin { get; }
    }
}
