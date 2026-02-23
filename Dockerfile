# Multi-stage build for .NET 9.0 API
FROM mcr.microsoft.com/dotnet/aspnet:9.0 AS base
WORKDIR /app
EXPOSE 80

# Build stage
FROM mcr.microsoft.com/dotnet/sdk:9.0 AS build
WORKDIR /src
COPY ["MarketSystem.API/MarketSystem.API.csproj", "MarketSystem.API/"]
COPY ["MarketSystem.Application/MarketSystem.Application.csproj", "MarketSystem.Application/"]
COPY ["MarketSystem.Domain/MarketSystem.Domain.csproj", "MarketSystem.Domain/"]
COPY ["MarketSystem.Infrastructure/MarketSystem.Infrastructure.csproj", "MarketSystem.Infrastructure/"]

RUN dotnet restore "MarketSystem.API/MarketSystem.API.csproj"
COPY . .
WORKDIR "/src/MarketSystem.API"
RUN dotnet publish "MarketSystem.API.csproj" -c Release -o /app/publish /p:UseAppHost=false

# Runtime stage
FROM base AS final
WORKDIR /app
COPY --from=build /app/publish .
ENTRYPOINT ["dotnet", "MarketSystem.API.dll"]
