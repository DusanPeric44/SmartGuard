using Grpc.Core;
using Microsoft.EntityFrameworkCore;
using SmartGuard.Grpc.VectorMatching;
using SmartGuard.Services.Database;

namespace SmartGuard.API.Grpc
{
    public class VectorMatchingGrpcService : VectorMatchingDataService.VectorMatchingDataServiceBase
    {
        private readonly SmartGuardContext _context;

        public VectorMatchingGrpcService(SmartGuardContext context)
        {
            _context = context;
        }

        public override async Task<FaceDetectionEventData> GetFaceDetectionEvent(GetFaceDetectionEventRequest request, ServerCallContext context)
        {
            var evt = await _context.FaceDetectionEvents
                .AsNoTracking()
                .Where(x => x.Id == request.FaceDetectionEventId)
                .Select(x => new { x.Id, x.DeviceId, x.Embedding })
                .SingleOrDefaultAsync(context.CancellationToken);

            if (evt == null)
            {
                throw new RpcException(new Status(StatusCode.NotFound, "FaceDetectionEvent not found"));
            }

            if (!evt.DeviceId.HasValue)
            {
                throw new RpcException(new Status(StatusCode.FailedPrecondition, "FaceDetectionEvent.DeviceId is null"));
            }

            if (evt.Embedding == null || evt.Embedding.Length == 0)
            {
                throw new RpcException(new Status(StatusCode.FailedPrecondition, "FaceDetectionEvent.Embedding is empty"));
            }

            return new FaceDetectionEventData
            {
                FaceDetectionEventId = evt.Id,
                DeviceId = evt.DeviceId.Value,
                Embedding = Google.Protobuf.ByteString.CopyFrom(evt.Embedding)
            };
        }

        public override async Task StreamKnownPersonEmbeddings(StreamKnownPersonEmbeddingsRequest request, IServerStreamWriter<KnownPersonEmbedding> responseStream, ServerCallContext context)
        {
            var expected = request.ExpectedEmbeddingLength;
            if (expected <= 0)
            {
                throw new RpcException(new Status(StatusCode.InvalidArgument, "expected_embedding_length must be > 0"));
            }

            await foreach (var person in _context.KnownPersons
                .AsNoTracking()
                .Where(x => x.Embedding != null && x.Embedding.Length == expected)
                .Select(x => new { x.Id, x.Embedding })
                .AsAsyncEnumerable()
                .WithCancellation(context.CancellationToken))
            {
                await responseStream.WriteAsync(new KnownPersonEmbedding
                {
                    PersonId = person.Id,
                    Embedding = Google.Protobuf.ByteString.CopyFrom(person.Embedding!)
                }, context.CancellationToken);
            }
        }
    }
}
