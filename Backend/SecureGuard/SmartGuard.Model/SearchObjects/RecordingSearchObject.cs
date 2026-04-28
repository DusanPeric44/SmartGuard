using System;

namespace SmartGuard.Model.SearchObjects
{
    public class RecordingSearchObject : BaseSearchObject
    {
        public int? DeviceId { get; set; }
        public int? TypeId { get; set; }
        public int? StatusId { get; set; }
        public DateTime? From { get; set; }
        public DateTime? To { get; set; }
    }
}
