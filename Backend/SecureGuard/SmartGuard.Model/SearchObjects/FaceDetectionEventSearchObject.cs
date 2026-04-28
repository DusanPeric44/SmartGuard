using System;

namespace SmartGuard.Model.SearchObjects
{
    public class FaceDetectionEventSearchObject : BaseSearchObject
    {
        public int? DeviceId { get; set; }
        public int? PersonId { get; set; }
        public DateTime? From { get; set; }
        public DateTime? To { get; set; }
    }
}
