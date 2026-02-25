# Multi-stage build for .NET 9.0 API - Railway Deployment
FROM mcr.microsoft.com/dotnet/aspnet:9.0 AS base
WORKDIR /app
EXPOSE 8080
ENV ASPNETCORE_ENVIRONMENT=Production

# Build stage
FROM mcr.microsoft.com/dotnet/sdk:9.0 AS build
ARG BUILD_CONFIGURATION=Release
WORKDIR /src
COPY ["MarketSystem.API/MarketSystem.API.csproj", "MarketSystem.API/"]
COPY ["MarketSystem.Application/MarketSystem.Application.csproj", "MarketSystem.Application/"]
COPY ["MarketSystem.Domain/MarketSystem.Domain.csproj", "MarketSystem.Domain/"]
COPY ["MarketSystem.Infrastructure/MarketSystem.Infrastructure.csproj", "MarketSystem.Infrastructure/"]

RUN dotnet restore "MarketSystem.API/MarketSystem.API.csproj"
COPY . .
WORKDIR "/src/MarketSystem.API"
RUN dotnet publish "MarketSystem.API.csproj" -c $BUILD_CONFIGURATION -o /app/publish /p:UseAppHost=false

# Runtime stage
FROM base AS final
WORKDIR /app
COPY --from=build /app/publish .
ENTRYPOINT ["dotnet", "MarketSystem.API.dll"]
