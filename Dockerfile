# Multi-stage build for .NET 9.0 API
# Build stage: full SDK (keyin tashlanadi)
# Runtime stage: alpine-based minimal image (~100MB)

FROM mcr.microsoft.com/dotnet/sdk:9.0-alpine AS build
ARG BUILD_CONFIGURATION=Release
WORKDIR /src

COPY ["MarketSystem.API/MarketSystem.API.csproj", "MarketSystem.API/"]
COPY ["MarketSystem.Application/MarketSystem.Application.csproj", "MarketSystem.Application/"]
COPY ["MarketSystem.Domain/MarketSystem.Domain.csproj", "MarketSystem.Domain/"]
COPY ["MarketSystem.Infrastructure/MarketSystem.Infrastructure.csproj", "MarketSystem.Infrastructure/"]
RUN dotnet restore "MarketSystem.API/MarketSystem.API.csproj" --runtime linux-musl-x64

COPY . .
WORKDIR "/src/MarketSystem.API"
RUN dotnet publish "MarketSystem.API.csproj" \
    -c "$BUILD_CONFIGURATION" \
    -r linux-musl-x64 \
    --no-restore \
    -o /app/publish \
    /p:UseAppHost=false

# Runtime: alpine (~100MB vs Debian ~220MB)
FROM mcr.microsoft.com/dotnet/aspnet:9.0-alpine AS runtime
WORKDIR /app
EXPOSE 8080

# ICU (internatsionalizatsiya) + tzdata (Toshkent vaqt mintaqasi uchun)
RUN apk add --no-cache icu-libs tzdata \
    && addgroup -S -g 1001 marketsystem \
    && adduser -S -u 1001 -G marketsystem -H -s /sbin/nologin marketsystem

ENV ASPNETCORE_ENVIRONMENT=Production \
    ASPNETCORE_URLS=http://+:8080 \
    DOTNET_RUNNING_IN_CONTAINER=true \
    DOTNET_EnableDiagnostics=0 \
    DOTNET_SYSTEM_GLOBALIZATION_INVARIANT=false \
    TZ=Asia/Tashkent

COPY --from=build --chown=marketsystem:marketsystem /app/publish .

# Product-images mount point must exist AND be owned by the runtime user before
# the named volume (docker-compose: product-images) mounts over it. Docker
# seeds a fresh named volume with this directory's ownership, so creating it as
# marketsystem here is what lets the non-root process write uploads. Without
# this, the volume would be root-owned and every upload would fail with EACCES.
RUN mkdir -p /app/wwwroot/uploads/products \
    && chown -R marketsystem:marketsystem /app/wwwroot

USER marketsystem:marketsystem

# wget alpine'da mavjud (busybox) — curl o'rnatilmaydi
HEALTHCHECK --interval=30s --timeout=10s --start-period=40s --retries=3 \
    CMD wget --no-verbose --tries=1 --spider http://localhost:8080/health || exit 1

ENTRYPOINT ["dotnet", "MarketSystem.API.dll"]
