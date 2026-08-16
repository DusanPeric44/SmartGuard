using MassTransit;
using SmartGuard.Grpc.VectorMatching;
using SmartGuard.Model.Interfaces;
using SmartGuard.VectorMatching.Microservice.Consumers;
using SmartGuard.VectorMatching.Microservice.Services;

var builder = Host.CreateApplicationBuilder(args);
AppContext.SetSwitch("System.Net.Http.SocketsHttpHandler.Http2UnencryptedSupport", true);

builder.Services.AddSingleton<InternalTokenClientInterceptor>();
builder.Services.AddGrpcClient<VectorMatchingDataService.VectorMatchingDataServiceClient>(o =>
{
    var address = builder.Configuration["Grpc:ApiAddress"];
    o.Address = new Uri(address ?? "http://localhost:5010");
})
.AddInterceptor<InternalTokenClientInterceptor>();
builder.Services.AddScoped<ICosineSimilarityService, CosineSimilarityService>();
builder.Services.Configure<FaceMatchingOptions>(builder.Configuration.GetSection("FaceMatching"));

var rabbitMqVHost = builder.Configuration["RabbitMQ:VirtualHost"] ?? "/";

builder.Services.AddMassTransit(x =>
{
    x.AddConsumer<VectorMatchRequestedConsumer>();

    x.UsingRabbitMq((context, cfg) =>
    {
        cfg.Host(builder.Configuration["RabbitMQ:Host"] ?? "localhost", rabbitMqVHost, h =>
        {
            h.Username(builder.Configuration["RabbitMQ:Username"] ?? "guest");
            h.Password(builder.Configuration["RabbitMQ:Password"] ?? "guest");
        });

        cfg.ReceiveEndpoint("vector-matching-worker-queue", e =>
        {
            e.ConfigureConsumer<VectorMatchRequestedConsumer>(context);
        });
    });
});

var host = builder.Build();
host.Run();
