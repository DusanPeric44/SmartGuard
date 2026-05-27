FROM mcr.microsoft.com/dotnet/runtime:10.0 AS base
USER $APP_UID
WORKDIR /app

FROM mcr.microsoft.com/dotnet/sdk:10.0 AS build
ARG BUILD_CONFIGURATION=Release
WORKDIR /src
COPY ["SmartGuard.VectorMatching.Microservice/SmartGuard.VectorMatching.Microservice.csproj", "SmartGuard.VectorMatching.Microservice/"]
COPY ["SmartGuard.Model/SmartGuard.Model.csproj", "SmartGuard.Model/"]
RUN dotnet restore "./SmartGuard.VectorMatching.Microservice/SmartGuard.VectorMatching.Microservice.csproj"
COPY . .
WORKDIR "/src/SmartGuard.VectorMatching.Microservice"
RUN dotnet build "./SmartGuard.VectorMatching.Microservice.csproj" -c $BUILD_CONFIGURATION -o /app/build

FROM build AS publish
ARG BUILD_CONFIGURATION=Release
RUN dotnet publish "./SmartGuard.VectorMatching.Microservice.csproj" -c $BUILD_CONFIGURATION -o /app/publish /p:UseAppHost=false

FROM base AS final
WORKDIR /app
COPY --from=publish /app/publish .
ENTRYPOINT ["dotnet", "SmartGuard.VectorMatching.Microservice.dll"]
