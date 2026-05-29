# =====================================================================
# Flutter Web — Multi-stage build, layer-cache optimized
# =====================================================================
# Stage 1: build with Flutter SDK image
# Stage 2: serve static files with tiny nginx:alpine (~20 MB)
# =====================================================================

# ---- Build stage ----
FROM ghcr.io/cirruslabs/flutter:stable AS build

ENV FLUTTER_ROOT=/sdks/flutter \
    PUB_CACHE=/root/.pub-cache

WORKDIR /app

# 1) Copy ONLY pubspec files first — this layer is cached
#    and won't bust when source code changes.
COPY pubspec.yaml pubspec.lock* ./

# 2) Resolve dependencies — cached unless pubspec changes
RUN flutter pub get

# 3) NOW copy source code (everything else)
#    Build context here is minimal thanks to .dockerignore
COPY . .

# Build-time deployment knob: the hidden SuperAdmin console URL segment.
# Compiled into the bundle via --dart-define (NOT a secret — see AppConfig).
# MUST match the backend's SuperAdmin:ConsoleSegment, else every console
# call 404s and the SPA shows "Konsol sozlanmagan". Passed from compose
# (build.args) which reads it from the .env SuperAdmin__ConsoleSegment.
ARG SUPERADMIN_CONSOLE_SEGMENT=""

# 4) Build the web app (release mode)
RUN flutter build web --release --no-tree-shake-icons \
    --dart-define=SUPERADMIN_CONSOLE_SEGMENT=${SUPERADMIN_CONSOLE_SEGMENT}

# ---- Runtime stage ----
FROM nginx:alpine AS runtime

# Copy compiled web app from build stage
COPY --from=build /app/build/web /usr/share/nginx/html

# Custom nginx config (SPA routing, gzip, etc.)
COPY nginx.conf /etc/nginx/conf.d/default.conf

EXPOSE 80

# Healthcheck for docker-compose
HEALTHCHECK --interval=30s --timeout=5s --start-period=10s --retries=3 \
    CMD wget --quiet --spider http://localhost/ || exit 1

CMD ["nginx", "-g", "daemon off;"]
