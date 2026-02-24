# This stage is used to build the service project
FROM mcr.microsoft.com/dotnet/sdk:9.0 AS build
ARG BUILD_CONFIGURATION=Release
WORKDIR /src
COPY ["MarketSystem.API/MarketSystem.API.csproj", "MarketSystem.API/"]
COPY ["MarketSystem.Application/MarketSystem.Application.csproj", "MarketSystem.Application/"]
COPY ["MarketSystem.Infrastructure/MarketSystem.Infrastructure.csproj", "MarketSystem.Infrastructure/"]
COPY ["MarketSystem.Domain/MarketSystem.Domain.csproj", "MarketSystem.Domain/"]
RUN dotnet restore "./MarketSystem.API/MarketSystem.API.csproj"
COPY . .
WORKDIR "/src/MarketSystem.API"
RUN dotnet build "./MarketSystem.API.csproj" -c $BUILD_CONFIGURATION -o /app/build

# This stage is used to publish the service project to be copied to the final stage
FROM build AS publish
ARG BUILD_CONFIGURATION=Release
RUN dotnet publish "./MarketSystem.API.csproj" -c $BUILD_CONFIGURATION -o /app/publish /p:UseAppHost=false

# This stage is used in production or when running from VS in regular mode (Default when not using the Debug configuration)
FROM base AS final
WORKDIR /app
COPY --from=publish /app/publish .
ENTRYPOINT ["dotnet", "MarketSystem.API.dll"]