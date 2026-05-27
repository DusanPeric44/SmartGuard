using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.SignalR;
using SmartGuard.Model.Interfaces;
using System.Security.Claims;

namespace SmartGuard.API.Hubs
{
    [Authorize]
    public class CameraHub : Hub
    {
        private readonly IWebSocketBridgeManager _bridgeManager;
        private readonly IStreamRecordingManager _recordingManager;

        public CameraHub(IWebSocketBridgeManager bridgeManager, IStreamRecordingManager recordingManager)
        {
            _bridgeManager = bridgeManager;
            _recordingManager = recordingManager;
        }

        /// <summary>
        /// Receives a base64 encoded JPEG frame from the ESP32 and broadcasts it to other clients.
        /// </summary>
        /// <param name="deviceId">The ID of the device sending the frame.</param>
        /// <param name="base64Frame">The base64 encoded image data.</param>
        public async Task UploadFrame(string deviceId, string base64Frame)
        {
            if (!string.IsNullOrWhiteSpace(deviceId) && !string.IsNullOrWhiteSpace(base64Frame))
            {
                try
                {
                    var bytes = Convert.FromBase64String(base64Frame);
                    await _recordingManager.TryWriteFrameAsync(deviceId, bytes, Context.ConnectionAborted);
                }
                catch (FormatException)
                {
                }
            }

            // Broadcast the frame to all other connected clients (e.g., Mobile App)
            // The Mobile app expects the event name "MjpegFrame"
            await Clients.Others.SendAsync("MjpegFrame", deviceId, base64Frame);
        }

        /// <summary>
        /// Command to start the camera stream. Broadcasted to the ESP32.
        /// </summary>
        public async Task StartStream(string deviceId)
        {
            await Clients.All.SendAsync("StartStream", deviceId);
            // Also send to raw WebSocket devices
            await _bridgeManager.SendToDeviceAsync(deviceId, "{\"target\":\"StartStream\"}");
        }

        /// <summary>
        /// Command to stop the camera stream. Broadcasted to the ESP32.
        /// </summary>
        public async Task StopStream(string deviceId)
        {
            await Clients.All.SendAsync("StopStream", deviceId);
            // Also send to raw WebSocket devices
            await _bridgeManager.SendToDeviceAsync(deviceId, "{\"target\":\"StopStream\"}");
        }

        /// <summary>
        /// Marks a specific face ID as safe. Broadcasted to the ESP32.
        /// </summary>
        /// <param name="deviceId">The ID of the target device.</param>
        /// <param name="faceId">The ID of the face to whitelist.</param>
        public async Task MarkSafe(string deviceId, int faceId)
        {
            await Clients.All.SendAsync("MarkSafe", deviceId, faceId);
            // Also send to raw WebSocket devices
            await _bridgeManager.SendToDeviceAsync(deviceId, $"{{\"target\":\"MarkSafe\",\"arguments\":[{faceId}]}}");
        }

        [Authorize(Roles = "HomeOwner")]
        public async Task StartRecording(string deviceId)
        {
            var userId = Context.User?.FindFirstValue("UserId") ?? string.Empty;
            if (string.IsNullOrWhiteSpace(userId))
            {
                throw new HubException("Unauthorized");
            }

            await _recordingManager.StartAsync(deviceId, userId, Context.ConnectionId, Context.ConnectionAborted);
            await Clients.All.SendAsync("StartRecording", deviceId);
            await _bridgeManager.SendToDeviceAsync(deviceId, "{\"target\":\"StartRecording\"}");
        }

        [Authorize(Roles = "HomeOwner")]
        public async Task StopRecording(string deviceId)
        {
            await _recordingManager.StopAsync(deviceId, "UserStop", Context.ConnectionAborted);
            await Clients.All.SendAsync("StopRecording", deviceId);
            await _bridgeManager.SendToDeviceAsync(deviceId, "{\"target\":\"StopRecording\"}");
        }

        public override Task OnConnectedAsync()
        {
            return base.OnConnectedAsync();
        }

        public override async Task OnDisconnectedAsync(Exception? exception)
        {
            IReadOnlyList<string> stoppedDeviceIds = Array.Empty<string>();
            try
            {
                stoppedDeviceIds = await _recordingManager.StopByConnectionAsync(Context.ConnectionId, "RecorderDisconnected");
            }
            catch
            {
            }

            foreach (var deviceId in stoppedDeviceIds)
            {
                await Clients.All.SendAsync("StopRecording", deviceId);
                await _bridgeManager.SendToDeviceAsync(deviceId, "{\"target\":\"StopRecording\"}");
            }

            await base.OnDisconnectedAsync(exception);
        }
    }
}
