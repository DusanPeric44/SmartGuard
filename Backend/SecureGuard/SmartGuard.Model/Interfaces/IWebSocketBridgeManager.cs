using System.Net.WebSockets;

namespace SmartGuard.Model.Interfaces
{
    public interface IWebSocketBridgeManager
    {
        Task AddSocketAsync(string deviceId, WebSocket socket);
        Task RemoveSocketAsync(string deviceId);
        Task SendToDeviceAsync(string deviceId, string message);
        Task BroadcastFrameAsync(string deviceId, string base64Frame);
    }
}
