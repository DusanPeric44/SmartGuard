using System;

namespace SmartGuard.Model.SearchObjects
{
    public class RecordingSearchObject : BaseSearchObject
    {
        public string Term { get; set; } = string.Empty;
        public int DeviceId { get; set; }
        public int RecordingTypeId { get; set; }
        public int RecordingStatusId { get; set; }
        public DateTime Start { get; set; }
        public DateTime End { get; set; }
    }
}
