using Microsoft.AspNetCore.SignalR;
using SmartGuard.Model.Interfaces;

namespace SmartGuard.API.Hubs
{
    public class CameraHub : Hub
    {
        private readonly IWebSocketBridgeManager _bridgeManager;

        public CameraHub(IWebSocketBridgeManager bridgeManager)
        {
            _bridgeManager = bridgeManager;
        }

        /// <summary>
        /// Receives a base64 encoded JPEG frame from the ESP32 and broadcasts it to other clients.
        /// </summary>
        /// <param name="deviceId">The ID of the device sending the frame.</param>
        /// <param name="base64Frame">The base64 encoded image data.</param>
        public async Task UploadFrame(string deviceId, string base64Frame)
        {
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

        public async Task StartRecording(string deviceId)
        {
            await Clients.All.SendAsync("StartRecording", deviceId);
            await _bridgeManager.SendToDeviceAsync(deviceId, "{\"target\":\"StartRecording\"}");
        }

        public async Task StopRecording(string deviceId)
        {
            await Clients.All.SendAsync("StopRecording", deviceId);
            await _bridgeManager.SendToDeviceAsync(deviceId, "{\"target\":\"StopRecording\"}");
        }

        public override Task OnConnectedAsync()
        {
            return base.OnConnectedAsync();
        }

        public override Task OnDisconnectedAsync(Exception? exception)
        {
            return base.OnDisconnectedAsync(exception);
        }
    }
}
