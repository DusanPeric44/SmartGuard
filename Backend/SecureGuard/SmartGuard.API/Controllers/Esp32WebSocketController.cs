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
        private readonly ILogger<Esp32WebSocketController> _logger;

        public Esp32WebSocketController(IWebSocketBridgeManager bridgeManager, ILogger<Esp32WebSocketController> logger)
        {
            _bridgeManager = bridgeManager;
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
            
            while (webSocket.State == WebSocketState.Open)
            {
                WebSocketReceiveResult result;
                ms.SetLength(0); // Reset stream for new message
                
                do
                {
                    result = await webSocket.ReceiveAsync(new ArraySegment<byte>(buffer), CancellationToken.None);
                    
                    if (result.MessageType == WebSocketMessageType.Close)
                    {
                        await webSocket.CloseAsync(WebSocketCloseStatus.NormalClosure, "Closing", CancellationToken.None);
                        return;
                    }

                    await ms.WriteAsync(buffer, 0, result.Count);
                } 
                while (!result.EndOfMessage);

                // Full message received
                var data = ms.ToArray();
                if (result.MessageType == WebSocketMessageType.Binary)
                {
                    // Direct binary frame (JPEG)
                    var base64Frame = Convert.ToBase64String(data);
                    await _bridgeManager.BroadcastFrameAsync(deviceId, base64Frame);
                }
                else if (result.MessageType == WebSocketMessageType.Text)
                {
                    var message = Encoding.UTF8.GetString(data);
                    
                    // Heuristic: if it's long, it's likely a base64 frame
                    if (message.Length > 100)
                    {
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
