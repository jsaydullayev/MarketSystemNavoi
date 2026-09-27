# =====================================================================
# Flutter Web — Multi-stage build, layer-cache optimized
# =====================================================================
# Stage 1: build with Flutter SDK image
# Stage 2: serve static files with tiny nginx:alpine (~20 MB)
# =====================================================================

# ---- Build stage ----
# Pinned to the Flutter version the app is developed and tested with (local
# `flutter --version`). The floating `stable` tag once pulled Flutter 3.44,
# whose freshly re-resolved packages (adaptive_theme 3.8 → material_ui
# ThemeData) no longer compiled. Bump together with the local SDK + lockfile.
FROM ghcr.io/cirruslabs/flutter:3.41.2 AS build

ENV FLUTTER_ROOT=/sdks/flutter \
    PUB_CACHE=/root/.pub-cache

WORKDIR /app

# pubspec.lock is generated through the pub.flutter-io.cn mirror (developers'
# PUB_HOSTED_URL). pub treats a different hosted URL as a different source and
# silently re-resolves EVERY package to its newest version — so the lock was
# never honoured here. Point it at pub.dev (same archives, same sha256).
ARG LOCK_FIX="s#https://pub.flutter-io.cn#https://pub.dev#g"

# 1) Copy ONLY pubspec files first — this layer is cached
#    and won't bust when source code changes.
COPY pubspec.yaml pubspec.lock ./

# 2) Resolve dependencies exactly as locked — any drift fails the build
#    instead of shipping untested package versions.
RUN sed -i "$LOCK_FIX" pubspec.lock && flutter pub get --enforce-lockfile

# 3) NOW copy source code (everything else)
#    Build context here is minimal thanks to .dockerignore
COPY . .

# COPY brought the mirror-URL lockfile back; re-point it so the implicit
# `pub get` of `flutter build` keeps the versions resolved above.
RUN sed -i "$LOCK_FIX" pubspec.lock

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

# Healthcheck for docker-compose. 127.0.0.1, not localhost: busybox wget
# resolves localhost to ::1 first, where nginx (`listen 80;`, IPv4 only) isn't
# listening — the container reported "unhealthy" while serving fine.
HEALTHCHECK --interval=30s --timeout=5s --start-period=10s --retries=3 \
    CMD wget --quiet --spider http://127.0.0.1/ || exit 1

CMD ["nginx", "-g", "daemon off;"]
