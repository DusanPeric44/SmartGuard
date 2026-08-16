using Grpc.Core;
using Grpc.Core.Interceptors;

namespace SmartGuard.VectorMatching.Microservice.Services
{
    /// <summary>
    /// Attaches the shared internal service token to every outgoing call to the API's
    /// VectorMatchingGrpcService, so the API can verify the call originates from this trusted service.
    /// </summary>
    public class InternalTokenClientInterceptor : Interceptor
    {
        private const string HeaderName = "x-internal-token";
        private readonly string _token;

        public InternalTokenClientInterceptor(IConfiguration configuration)
        {
            _token = configuration["Internal:ServiceToken"]
                ?? throw new InvalidOperationException("Internal:ServiceToken is not configured.");
        }

        public override TResponse BlockingUnaryCall<TRequest, TResponse>(
            TRequest request,
            ClientInterceptorContext<TRequest, TResponse> context,
            BlockingUnaryCallContinuation<TRequest, TResponse> continuation)
        {
            return continuation(request, AddHeader(context));
        }

        public override AsyncUnaryCall<TResponse> AsyncUnaryCall<TRequest, TResponse>(
            TRequest request,
            ClientInterceptorContext<TRequest, TResponse> context,
            AsyncUnaryCallContinuation<TRequest, TResponse> continuation)
        {
            return continuation(request, AddHeader(context));
        }

        public override AsyncServerStreamingCall<TResponse> AsyncServerStreamingCall<TRequest, TResponse>(
            TRequest request,
            ClientInterceptorContext<TRequest, TResponse> context,
            AsyncServerStreamingCallContinuation<TRequest, TResponse> continuation)
        {
            return continuation(request, AddHeader(context));
        }

        private ClientInterceptorContext<TRequest, TResponse> AddHeader<TRequest, TResponse>(
            ClientInterceptorContext<TRequest, TResponse> context)
            where TRequest : class
            where TResponse : class
        {
            var headers = context.Options.Headers ?? new Metadata();
            headers.Add(HeaderName, _token);

            var options = context.Options.WithHeaders(headers);
            return new ClientInterceptorContext<TRequest, TResponse>(context.Method, context.Host, options);
        }
    }
}
