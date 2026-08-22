using System;

namespace SmartGuard.Model.DTOs
{
    public class FaceDetectionEvent
    {
        public int Id { get; set; }
        public int DeviceId { get; set; }
        public Device Device { get; set; }
        public int? PersonId { get; set; }
        public KnownPerson Person { get; set; }
        public double? Score { get; set; }
        public string Image { get; set; }
        public DateTime Timestamp { get; set; }
        // Embedding is deliberately NOT exposed here: the raw face vector is biometric data and
        // only leaves the API over the internal gRPC service (VectorMatchingGrpcService), which is
        // gated by the internal service token and not published outside the Docker network.
    }
}
