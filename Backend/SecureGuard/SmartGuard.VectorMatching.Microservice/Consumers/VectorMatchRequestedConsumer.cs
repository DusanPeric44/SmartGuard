using MassTransit;
using Grpc.Core;
using SmartGuard.Model;
using SmartGuard.Model.Events;
using SmartGuard.Grpc.VectorMatching;
using SmartGuard.Model.Interfaces;

namespace SmartGuard.VectorMatching.Microservice.Consumers
{
    public class VectorMatchRequestedConsumer : IConsumer<IVectorMatchRequestedEvent>
    {
        private readonly ICosineSimilarityService _cosineSimilarity;
        private readonly VectorMatchingDataService.VectorMatchingDataServiceClient _client;

        public VectorMatchRequestedConsumer(ICosineSimilarityService cosineSimilarity, VectorMatchingDataService.VectorMatchingDataServiceClient client)
        {
            _cosineSimilarity = cosineSimilarity;
            _client = client;
        }

        public async Task Consume(ConsumeContext<IVectorMatchRequestedEvent> context)
        {
            FaceDetectionEventData faceEvent;
            try
            {
                faceEvent = await _client.GetFaceDetectionEventAsync(
                    new GetFaceDetectionEventRequest { FaceDetectionEventId = context.Message.FaceDetectionEventId },
                    cancellationToken: context.CancellationToken);
            }
            catch (RpcException ex)
            {
                await context.Publish<IVectorMatchCompletedEvent>(new
                {
                    context.Message.FaceDetectionEventId,
                    context.Message.DeviceId,
                    IsMatched = false,
                    MatchedPersonId = (int?)null,
                    BestScore = 0d  
                });
                return;
            }

            if (faceEvent.Embedding == null || faceEvent.Embedding.Length == 0)
            {
                await context.Publish<IVectorMatchCompletedEvent>(new
                {
                    context.Message.FaceDetectionEventId,
                    context.Message.DeviceId,
                    IsMatched = false,
                    MatchedPersonId = (int?)null,
                    BestScore = 0d
                });
                return;
            }

            var queryEmbedding = VectorPacking.UnpackFloat32(faceEvent.Embedding.ToByteArray());

            var bestScore = 0d;
            int? bestPersonId = null;

            using var call = _client.StreamKnownPersonEmbeddings(new StreamKnownPersonEmbeddingsRequest
            {
                ExpectedEmbeddingLength = faceEvent.Embedding.Length
            }, cancellationToken: context.CancellationToken);

            try
            {
                while (await call.ResponseStream.MoveNext(context.CancellationToken))
                {
                    var candidate = call.ResponseStream.Current;
                    if (candidate.Embedding == null || candidate.Embedding.Length == 0) continue;

                    var candidateVector = VectorPacking.UnpackFloat32(candidate.Embedding.ToByteArray());
                    var score = _cosineSimilarity.CalculateSimilarity(queryEmbedding, candidateVector);
                    if (score > bestScore)
                    {
                        bestScore = score;
                        bestPersonId = candidate.PersonId;
                    }
                }
            }
            catch (RpcException)
            {
                await context.Publish<IVectorMatchCompletedEvent>(new
                {
                    context.Message.FaceDetectionEventId,
                    context.Message.DeviceId,
                    IsMatched = false,
                    MatchedPersonId = (int?)null,
                    BestScore = 0d
                });
                return;
            }

            var isMatched = bestPersonId.HasValue && bestScore >= 0.70d;

            await context.Publish<IVectorMatchCompletedEvent>(new
            {
                faceEvent.FaceDetectionEventId,
                faceEvent.DeviceId,
                IsMatched = isMatched,
                MatchedPersonId = isMatched ? bestPersonId : (int?)null,
                BestScore = bestScore
            });
        }
    }
}
