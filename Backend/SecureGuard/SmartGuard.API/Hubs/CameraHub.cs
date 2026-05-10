using Microsoft.AspNetCore.SignalR;

namespace SmartGuard.API.Hubs
{
    public class CameraHub : Hub
    {
        /// <summary>
        /// Receives a base64 encoded JPEG frame from the ESP32 and broadcasts it to other clients.
        /// </summary>
        /// <param name="base64Frame">The base64 encoded image data.</param>
        public async Task UploadFrame(string base64Frame)
        {
            // Broadcast the frame to all other connected clients (e.g., Mobile App)
            // The Mobile app expects the event name "MjpegFrame"
            await Clients.Others.SendAsync("MjpegFrame", base64Frame);
        }

        /// <summary>
        /// Command to start the camera stream. Broadcasted to the ESP32.
        /// </summary>
        public async Task StartStream()
        {
            await Clients.All.SendAsync("StartStream");
        }

        /// <summary>
        /// Command to stop the camera stream. Broadcasted to the ESP32.
        /// </summary>
        public async Task StopStream()
        {
            await Clients.All.SendAsync("StopStream");
        }

        /// <summary>
        /// Marks a specific face ID as safe. Broadcasted to the ESP32.
        /// </summary>
        /// <param name="faceId">The ID of the face to whitelist.</param>
        public async Task MarkSafe(int faceId)
        {
            await Clients.All.SendAsync("MarkSafe", faceId);
        }
    }
}
