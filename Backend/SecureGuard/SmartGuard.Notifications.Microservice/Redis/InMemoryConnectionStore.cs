using System.Collections.Concurrent;

namespace SmartGuard.Notifications.Microservice.Redis
{
    public class InMemoryConnectionStore : IRedisConnectionStore
    {
        private readonly ConcurrentDictionary<string, ConcurrentDictionary<string, byte>> _store = new();

        public Task AddConnectionAsync(string userId, string connectionId, CancellationToken cancellationToken = default)
        {
            if (string.IsNullOrWhiteSpace(userId) || string.IsNullOrWhiteSpace(connectionId))
            {
                return Task.CompletedTask;
            }

            var connections = _store.GetOrAdd(userId, _ => new ConcurrentDictionary<string, byte>());
            connections.TryAdd(connectionId, 0);
            return Task.CompletedTask;
        }

        public Task RemoveConnectionAsync(string userId, string connectionId, CancellationToken cancellationToken = default)
        {
            if (string.IsNullOrWhiteSpace(userId) || string.IsNullOrWhiteSpace(connectionId))
            {
                return Task.CompletedTask;
            }

            if (_store.TryGetValue(userId, out var connections))
            {
                connections.TryRemove(connectionId, out _);
                if (connections.IsEmpty)
                {
                    _store.TryRemove(userId, out _);
                }
            }

            return Task.CompletedTask;
        }

        public Task<IReadOnlyList<string>> GetConnectionsAsync(string userId, CancellationToken cancellationToken = default)
        {
            if (string.IsNullOrWhiteSpace(userId))
            {
                return Task.FromResult<IReadOnlyList<string>>(Array.Empty<string>());
            }

            if (!_store.TryGetValue(userId, out var connections) || connections.IsEmpty)
            {
                return Task.FromResult<IReadOnlyList<string>>(Array.Empty<string>());
            }

            return Task.FromResult<IReadOnlyList<string>>(connections.Keys.ToArray());
        }
    }
}

