using System.Threading.Channels;
using SmartGuard.Services.Audit;

namespace SmartGuard.API.Services
{
    public class AuditLogChannel
    {
        public Channel<AuditEvent> Channel { get; } = System.Threading.Channels.Channel.CreateBounded<AuditEvent>(new BoundedChannelOptions(1000)
        {
            SingleReader = true,
            SingleWriter = false,
            FullMode = BoundedChannelFullMode.DropWrite
        });
    }
}

