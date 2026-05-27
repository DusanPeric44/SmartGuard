using System.Net.WebSockets;
using System.Text;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using SmartGuard.Model.Interfaces;

namespace SmartGuard.API.Controllers
{
    [Route("api/esp32")]
    [ApiController]
    public class Esp32WebSocketController : ControllerBase
    {
        private readonly IWebSocketBridgeManager _bridgeManager;
        private readonly IStreamRecordingManager _recordingManager;
        private readonly ILogger<Esp32WebSocketController> _logger;

        public Esp32WebSocketController(IWebSocketBridgeManager bridgeManager, IStreamRecordingManager recordingManager, ILogger<Esp32WebSocketController> logger)
        {
            _bridgeManager = bridgeManager;
            _recordingManager = recordingManager;
            _logger = logger;
        }

        [AllowAnonymous]
        [HttpGet("ws")]
        public async Task Get([FromQuery] string deviceId)
        {
            if (string.IsNullOrEmpty(deviceId))
            {
                HttpContext.Response.StatusCode = StatusCodes.Status400BadRequest;
                await HttpContext.Response.WriteAsync("deviceId is required");
                return;
            }

            if (HttpContext.WebSockets.IsWebSocketRequest)
            {
                using var webSocket = await HttpContext.WebSockets.AcceptWebSocketAsync();
                await _bridgeManager.AddSocketAsync(deviceId, webSocket);
                
                try
                {
                    await HandleWebSocketLoop(deviceId, webSocket);
                }
                catch (WebSocketException ex)
                {
                    // This is expected when the ESP32 disconnects abruptly or power cycles
                    _logger.LogWarning("WebSocket connection for device {DeviceId} was closed abruptly: {Message}", deviceId, ex.Message);
                }
                catch (Exception ex)
                {
                    _logger.LogError(ex, "Unexpected error in WebSocket loop for device {DeviceId}", deviceId);
                }
                finally
                {
                    await _bridgeManager.RemoveSocketAsync(deviceId);
                    try
                    {
                        await _recordingManager.StopAsync(deviceId, "DeviceDisconnected");
                    }
                    catch (Exception ex)
                    {
                        _logger.LogError(ex, "Failed to stop recording for device {DeviceId} after WebSocket disconnect", deviceId);
                    }
                }
            }
            else
            {
                HttpContext.Response.StatusCode = StatusCodes.Status400BadRequest;
            }
        }

        private async Task HandleWebSocketLoop(string deviceId, WebSocket webSocket)
        {
            var buffer = new byte[1024 * 16]; // 16KB chunk buffer
            using var ms = new System.IO.MemoryStream();
            var heartbeatTimeout = TimeSpan.FromSeconds(30);
            var lastSeenUtc = DateTime.UtcNow;
            
            while (webSocket.State == WebSocketState.Open)
            {
                WebSocketReceiveResult result;
                ms.SetLength(0); // Reset stream for new message
                
                do
                {
                    var remaining = (lastSeenUtc + heartbeatTimeout) - DateTime.UtcNow;
                    if (remaining <= TimeSpan.Zero)
                    {
                        _logger.LogWarning("Heartbeat timeout for device {DeviceId}. Closing WebSocket.", deviceId);
                        try
                        {
                            await webSocket.CloseAsync(WebSocketCloseStatus.NormalClosure, "Heartbeat timeout", CancellationToken.None);
                        }
                        catch
                        {
                            webSocket.Abort();
                        }
                        return;
                    }

                    try
                    {
                        using var cts = new CancellationTokenSource(remaining);
                        result = await webSocket.ReceiveAsync(new ArraySegment<byte>(buffer), cts.Token);
                    }
                    catch (OperationCanceledException)
                    {
                        _logger.LogWarning("Heartbeat timeout for device {DeviceId}. Closing WebSocket.", deviceId);
                        try
                        {
                            await webSocket.CloseAsync(WebSocketCloseStatus.NormalClosure, "Heartbeat timeout", CancellationToken.None);
                        }
                        catch
                        {
                            webSocket.Abort();
                        }
                        return;
                    }
                    
                    if (result.MessageType == WebSocketMessageType.Close)
                    {
                        await webSocket.CloseAsync(WebSocketCloseStatus.NormalClosure, "Closing", CancellationToken.None);
                        return;
                    }

                    if (result.Count > 0)
                    {
                        lastSeenUtc = DateTime.UtcNow;
                    }

                    await ms.WriteAsync(buffer, 0, result.Count);
                } 
                while (!result.EndOfMessage);

                // Full message received
                var data = ms.ToArray();
                if (result.MessageType == WebSocketMessageType.Binary)
                {
                    // Direct binary frame (JPEG)
                    await _recordingManager.TryWriteFrameAsync(deviceId, data);
                    var base64Frame = Convert.ToBase64String(data);
                    await _bridgeManager.BroadcastFrameAsync(deviceId, base64Frame);
                }
                else if (result.MessageType == WebSocketMessageType.Text)
                {
                    var message = Encoding.UTF8.GetString(data);
                    if (message == "HB")
                    {
                        continue;
                    }
                    
                    // Heuristic: if it's long, it's likely a base64 frame
                    if (message.Length > 100)
                    {
                        try
                        {
                            var bytes = Convert.FromBase64String(message);
                            await _recordingManager.TryWriteFrameAsync(deviceId, bytes);
                        }
                        catch (FormatException)
                        {
                        }

                        await _bridgeManager.BroadcastFrameAsync(deviceId, message);
                    }
                    else
                    {
                        _logger.LogInformation("Received text from {DeviceId}: {Message}", deviceId, message);
                    }
                }
            }
        }
    }
}
