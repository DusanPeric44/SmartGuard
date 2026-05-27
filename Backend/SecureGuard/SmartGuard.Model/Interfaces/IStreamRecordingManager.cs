namespace SmartGuard.Model.Interfaces
{
    public interface IStreamRecordingManager
    {
        Task StartAsync(string deviceKey, string userId, string connectionId, CancellationToken cancellationToken = default);
        Task StopAsync(string deviceKey, string reason, CancellationToken cancellationToken = default);
        Task<IReadOnlyList<string>> StopByConnectionAsync(string connectionId, string reason, CancellationToken cancellationToken = default);
        Task TryWriteFrameAsync(string deviceKey, byte[] jpegBytes, CancellationToken cancellationToken = default);
    }
}
