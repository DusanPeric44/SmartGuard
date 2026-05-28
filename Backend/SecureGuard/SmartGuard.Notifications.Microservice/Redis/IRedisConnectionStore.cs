namespace SmartGuard.Notifications.Microservice.Redis
{
    public interface IRedisConnectionStore
    {
        Task AddConnectionAsync(string userId, string connectionId, CancellationToken cancellationToken = default);
        Task RemoveConnectionAsync(string userId, string connectionId, CancellationToken cancellationToken = default);
        Task<IReadOnlyList<string>> GetConnectionsAsync(string userId, CancellationToken cancellationToken = default);
    }
}

