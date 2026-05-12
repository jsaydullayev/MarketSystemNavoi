# Multi-stage build for .NET 9.0 API
# -----------------------------------------------------------------------------
# Runtime image runs as a non-root user — a container escape from a future RCE
# inside the API process cannot trivially become root on the host. The user is
# created at build time so file ownership is correct without runtime chown.
# -----------------------------------------------------------------------------

FROM mcr.microsoft.com/dotnet/sdk:9.0 AS build
ARG BUILD_CONFIGURATION=Release
WORKDIR /src

# Restore as a separate layer so source-only changes don't bust the NuGet cache.
COPY ["MarketSystem.API/MarketSystem.API.csproj", "MarketSystem.API/"]
COPY ["MarketSystem.Application/MarketSystem.Application.csproj", "MarketSystem.Application/"]
COPY ["MarketSystem.Domain/MarketSystem.Domain.csproj", "MarketSystem.Domain/"]
COPY ["MarketSystem.Infrastructure/MarketSystem.Infrastructure.csproj", "MarketSystem.Infrastructure/"]
RUN dotnet restore "MarketSystem.API/MarketSystem.API.csproj"

COPY . .
WORKDIR "/src/MarketSystem.API"
RUN dotnet publish "MarketSystem.API.csproj" \
    -c "$BUILD_CONFIGURATION" \
    -o /app/publish \
    /p:UseAppHost=false

# -----------------------------------------------------------------------------
# Runtime
# -----------------------------------------------------------------------------
FROM mcr.microsoft.com/dotnet/aspnet:9.0 AS runtime
WORKDIR /app
EXPOSE 8080
ENV ASPNETCORE_ENVIRONMENT=Production \
    ASPNETCORE_URLS=http://+:8080 \
    DOTNET_RUNNING_IN_CONTAINER=true \
    # Disable .NET diagnostics socket — eliminates a privilege-escalation
    # vector inside the container.
    DOTNET_EnableDiagnostics=0

# curl for the docker-compose healthcheck.
RUN apt-get update \
    && apt-get install -y --no-install-recommends curl \
    && rm -rf /var/lib/apt/lists/* \
    # Non-root system user. Fixed UID/GID so bind-mounted volumes (if any) have
    # predictable ownership across hosts.
    && groupadd --system --gid 1001 marketsystem \
    && useradd --system --uid 1001 --gid marketsystem --no-create-home --shell /sbin/nologin marketsystem

COPY --from=build --chown=marketsystem:marketsystem /app/publish .

USER marketsystem:marketsystem

HEALTHCHECK --interval=30s --timeout=10s --start-period=40s --retries=3 \
    CMD curl --fail --silent http://localhost:8080/health || exit 1

ENTRYPOINT ["dotnet", "MarketSystem.API.dll"]
