using Grpc.Core;
using Grpc.Core.Interceptors;

namespace SmartGuard.API.Grpc
{
    /// <summary>
    /// Requires every gRPC call to present the shared internal service token. This service carries
    /// raw face-embedding data and is only meant to be called by our own VectorMatching microservice,
    /// never directly by an end-user client.
    /// </summary>
    public class InternalTokenInterceptor : Interceptor
    {
        private const string HeaderName = "x-internal-token";
        private readonly string _expectedToken;

        public InternalTokenInterceptor(IConfiguration configuration)
        {
            _expectedToken = configuration["Internal:ServiceToken"]
                ?? throw new InvalidOperationException("Internal:ServiceToken is not configured.");
        }

        public override Task<TResponse> UnaryServerHandler<TRequest, TResponse>(
            TRequest request,
            ServerCallContext context,
            UnaryServerMethod<TRequest, TResponse> continuation)
        {
            Validate(context);
            return continuation(request, context);
        }

        public override Task ServerStreamingServerHandler<TRequest, TResponse>(
            TRequest request,
            IServerStreamWriter<TResponse> responseStream,
            ServerCallContext context,
            ServerStreamingServerMethod<TRequest, TResponse> continuation)
        {
            Validate(context);
            return continuation(request, responseStream, context);
        }

        private void Validate(ServerCallContext context)
        {
            var provided = context.RequestHeaders.GetValue(HeaderName);
            if (string.IsNullOrEmpty(provided) || provided != _expectedToken)
            {
                throw new RpcException(new Status(StatusCode.Unauthenticated, "Invalid or missing internal service token"));
            }
        }
    }
}
