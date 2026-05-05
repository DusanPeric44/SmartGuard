namespace SmartGuard.Services.Database
{
    public interface ISoftDeletable
    {
        bool IsDeleted { get; set; }
    }
}
