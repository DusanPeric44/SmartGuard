using StackExchange.Redis;

namespace SmartGuard.Notifications.Microservice.Redis
{
    public class RedisConnectionStore(IConnectionMultiplexer connectionMultiplexer) : IRedisConnectionStore
    {
        private readonly IDatabase _db = connectionMultiplexer.GetDatabase();

        public Task AddConnectionAsync(string userId, string connectionId, CancellationToken cancellationToken = default)
        {
            if (string.IsNullOrWhiteSpace(userId) || string.IsNullOrWhiteSpace(connectionId))
            {
                return Task.CompletedTask;
            }

            return _db.SetAddAsync(GetConnectionsKey(userId), connectionId);
        }

        public Task RemoveConnectionAsync(string userId, string connectionId, CancellationToken cancellationToken = default)
        {
            if (string.IsNullOrWhiteSpace(userId) || string.IsNullOrWhiteSpace(connectionId))
            {
                return Task.CompletedTask;
            }

            return _db.SetRemoveAsync(GetConnectionsKey(userId), connectionId);
        }

        public async Task<IReadOnlyList<string>> GetConnectionsAsync(string userId, CancellationToken cancellationToken = default)
        {
            if (string.IsNullOrWhiteSpace(userId))
            {
                return Array.Empty<string>();
            }

            var values = await _db.SetMembersAsync(GetConnectionsKey(userId));
            return values
                .Select(x => x.ToString())
                .Where(x => !string.IsNullOrWhiteSpace(x))
                .ToArray();
        }

        private static string GetConnectionsKey(string userId) => $"notifications:connections:{userId}";
    }
}

