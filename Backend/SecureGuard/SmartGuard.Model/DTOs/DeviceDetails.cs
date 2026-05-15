using System;
using System.Collections.Generic;

namespace SmartGuard.Model.DTOs
{
    public class DeviceDetails
    {
        public Device Device { get; set; } = null!;
        public List<DeviceUserDto> AssignedUsers { get; set; } = new();
        public DateTime LastSeenAt { get; set; }
    }

    public class DeviceUserDto
    {
        public string Id { get; set; } = string.Empty;
        public string Username { get; set; } = string.Empty;
    }
}
