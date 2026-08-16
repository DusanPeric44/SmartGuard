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
        private readonly IDeviceAccessService _deviceAccessService;

        public CameraHub(IWebSocketBridgeManager bridgeManager, IStreamRecordingManager recordingManager, IDeviceAccessService deviceAccessService)
        {
            _bridgeManager = bridgeManager;
            _recordingManager = recordingManager;
            _deviceAccessService = deviceAccessService;
        }

        private static string GroupName(string deviceId) => $"device-{deviceId}";

        private async Task EnsureCanAccessDeviceAsync(string deviceId, DeviceAccessPermission permission)
        {
            if (string.IsNullOrWhiteSpace(deviceId) || !int.TryParse(deviceId, out var parsedDeviceId))
            {
                throw new HubException("Invalid deviceId");
            }

            var userId = Context.User?.FindFirstValue("UserId") ?? string.Empty;
            var isAdmin = Context.User?.IsInRole("Admin") ?? false;

            if (!await _deviceAccessService.CanAccessDeviceAsync(userId, parsedDeviceId, permission, isAdmin))
            {
                throw new HubException("Forbidden");
            }
        }

        /// <summary>
        /// Joins the caller to the SignalR group for a device so it can receive that device's frames/events.
        /// Must be called before UploadFrame/StartStream/etc. will reach this connection.
        /// </summary>
        public async Task JoinDeviceGroup(string deviceId)
        {
            await EnsureCanAccessDeviceAsync(deviceId, DeviceAccessPermission.View);
            await Groups.AddToGroupAsync(Context.ConnectionId, GroupName(deviceId));
        }

        public async Task LeaveDeviceGroup(string deviceId)
        {
            if (!string.IsNullOrWhiteSpace(deviceId))
            {
                await Groups.RemoveFromGroupAsync(Context.ConnectionId, GroupName(deviceId));
            }
        }

        /// <summary>
        /// Receives a base64 encoded JPEG frame from the ESP32 and broadcasts it to other clients.
        /// </summary>
        /// <param name="deviceId">The ID of the device sending the frame.</param>
        /// <param name="base64Frame">The base64 encoded image data.</param>
        public async Task UploadFrame(string deviceId, string base64Frame)
        {
            await EnsureCanAccessDeviceAsync(deviceId, DeviceAccessPermission.Stream);

            if (!string.IsNullOrWhiteSpace(base64Frame))
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

            // Broadcast the frame to other clients in this device's group (e.g., Mobile App)
            // The Mobile app expects the event name "MjpegFrame"
            await Clients.OthersInGroup(GroupName(deviceId)).SendAsync("MjpegFrame", deviceId, base64Frame);
        }

        /// <summary>
        /// Command to start the camera stream. Broadcasted to the ESP32.
        /// </summary>
        public async Task StartStream(string deviceId)
        {
            await EnsureCanAccessDeviceAsync(deviceId, DeviceAccessPermission.Stream);

            await Clients.Group(GroupName(deviceId)).SendAsync("StartStream", deviceId);
            // Also send to raw WebSocket devices
            await _bridgeManager.SendToDeviceAsync(deviceId, "{\"target\":\"StartStream\"}");
        }

        /// <summary>
        /// Command to stop the camera stream. Broadcasted to the ESP32.
        /// </summary>
        public async Task StopStream(string deviceId)
        {
            await EnsureCanAccessDeviceAsync(deviceId, DeviceAccessPermission.Stream);

            await Clients.Group(GroupName(deviceId)).SendAsync("StopStream", deviceId);
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
            await EnsureCanAccessDeviceAsync(deviceId, DeviceAccessPermission.Stream);

            await Clients.Group(GroupName(deviceId)).SendAsync("MarkSafe", deviceId, faceId);
            // Also send to raw WebSocket devices
            await _bridgeManager.SendToDeviceAsync(deviceId, $"{{\"target\":\"MarkSafe\",\"arguments\":[{faceId}]}}");
        }

        [Authorize(Roles = "HomeOwner")]
        public async Task StartRecording(string deviceId)
        {
            await EnsureCanAccessDeviceAsync(deviceId, DeviceAccessPermission.Stream);

            var userId = Context.User?.FindFirstValue("UserId") ?? string.Empty;
            if (string.IsNullOrWhiteSpace(userId))
            {
                throw new HubException("Unauthorized");
            }

            await _recordingManager.StartAsync(deviceId, userId, Context.ConnectionId, Context.ConnectionAborted);
            await Clients.Group(GroupName(deviceId)).SendAsync("StartRecording", deviceId);
            await _bridgeManager.SendToDeviceAsync(deviceId, "{\"target\":\"StartRecording\"}");
        }

        [Authorize(Roles = "HomeOwner")]
        public async Task StopRecording(string deviceId)
        {
            await EnsureCanAccessDeviceAsync(deviceId, DeviceAccessPermission.Stream);

            await _recordingManager.StopAsync(deviceId, "UserStop", Context.ConnectionAborted);
            await Clients.Group(GroupName(deviceId)).SendAsync("StopRecording", deviceId);
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
                await Clients.Group(GroupName(deviceId)).SendAsync("StopRecording", deviceId);
                await _bridgeManager.SendToDeviceAsync(deviceId, "{\"target\":\"StopRecording\"}");
            }

            await base.OnDisconnectedAsync(exception);
        }
    }
}
