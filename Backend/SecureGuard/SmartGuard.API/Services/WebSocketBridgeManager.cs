using System.Net.WebSockets;
using System.Text;
using MassTransit;
using Microsoft.AspNetCore.SignalR;
using Microsoft.Extensions.Logging;
using SmartGuard.API.Hubs;
using SmartGuard.Model.Events;
using SmartGuard.Model.Interfaces;

namespace SmartGuard.API.Services
{
    public class WebSocketBridgeManager : IWebSocketBridgeManager
    {
        private readonly System.Collections.Concurrent.ConcurrentDictionary<string, WebSocket> _sockets = new();
        private readonly IHubContext<CameraHub> _hubContext;
        private readonly ILogger<WebSocketBridgeManager> _logger;
        private readonly IBus _bus;

        public WebSocketBridgeManager(IHubContext<CameraHub> hubContext, ILogger<WebSocketBridgeManager> logger, IBus bus)
        {
            _hubContext = hubContext;
            _logger = logger;
            _bus = bus;
        }

        public async Task AddSocketAsync(string deviceId, WebSocket socket)
        {
            if (_sockets.TryGetValue(deviceId, out var oldSocket))
            {
                _logger.LogWarning("Device {DeviceId} already connected. Closing old connection.", deviceId);
                try
                {
                    await oldSocket.CloseAsync(WebSocketCloseStatus.NormalClosure, "New connection established", CancellationToken.None);
                }
                catch (Exception ex)
                {
                    _logger.LogError(ex, "Error closing old socket for device {DeviceId}", deviceId);
                }
                _sockets.TryRemove(deviceId, out _);
            }

            if (_sockets.TryAdd(deviceId, socket))
            {
                _logger.LogInformation("Device {DeviceId} connected via WebSocket.", deviceId);
                try
                {
                    await _bus.Publish<IChangeDeviceStatusEvent>(new
                    {
                        DeviceId = deviceId,
                        StatusName = "Online",
                        TimestampUtc = DateTime.UtcNow
                    });
                }
                catch (Exception ex)
                {
                    _logger.LogError(ex, "Failed to publish Online status event for device {DeviceId}", deviceId);
                }
            }
        }

        public async Task RemoveSocketAsync(string deviceId)
        {
            if (_sockets.TryRemove(deviceId, out _))
            {
                _logger.LogInformation("Device {DeviceId} disconnected from WebSocket.", deviceId);
                try
                {
                    await _bus.Publish<IChangeDeviceStatusEvent>(new
                    {
                        DeviceId = deviceId,
                        StatusName = "Offline",
                        TimestampUtc = DateTime.UtcNow
                    });
                }
                catch (Exception ex)
                {
                    _logger.LogError(ex, "Failed to publish Offline status event for device {DeviceId}", deviceId);
                }
            }
            await Task.CompletedTask;
        }

        public async Task SendToDeviceAsync(string deviceId, string message)
        {
            if (_sockets.TryGetValue(deviceId, out var socket))
            {
                if (socket.State == WebSocketState.Open)
                {
                    try
                    {
                        var bytes = Encoding.UTF8.GetBytes(message);
                        await socket.SendAsync(new ArraySegment<byte>(bytes), WebSocketMessageType.Text, true, CancellationToken.None);
                    }
                    catch (WebSocketException ex)
                    {
                        _logger.LogWarning("Failed to send message to device {DeviceId} (Socket closed): {Message}", deviceId, ex.Message);
                        await RemoveSocketAsync(deviceId);
                    }
                    catch (Exception ex)
                    {
                        _logger.LogError(ex, "Unexpected error sending message to device {DeviceId}", deviceId);
                        await RemoveSocketAsync(deviceId);
                    }
                }
                else
                {
                    _logger.LogWarning("Socket for device {DeviceId} is in state {State}. Removing.", deviceId, socket.State);
                    await RemoveSocketAsync(deviceId);
                }
            }
            else
            {
                _logger.LogWarning("Attempted to send message to non-existent device {DeviceId}", deviceId);
            }
        }

        public async Task BroadcastFrameAsync(string deviceId, string base64Frame)
        {
            try
            {
                // Forward the frame only to SignalR clients that joined this device's group (mobile app, web app)
                // Mobile app expects: MjpegFrame(deviceId, base64Frame)
                await _hubContext.Clients.Group($"device-{deviceId}").SendAsync("MjpegFrame", deviceId, base64Frame);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error broadcasting frame from device {DeviceId}", deviceId);
            }
        }
    }
}
