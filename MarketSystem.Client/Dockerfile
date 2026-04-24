# Stage 1: Build the Flutter Web application
FROM ghcr.io/cirruslabs/flutter:stable AS build

# Suppress Flutter root user warning
ENV FLUTTER_ROOT=/flutter

# Set the working directory
WORKDIR /app

# Copy only the pubspec.yaml to avoid corrupted lockfile issues
COPY pubspec.yaml ./
RUN flutter pub get

# Copy the rest of the application code
COPY . .

# Clean build artifacts and FontManifest to prevent path doubling
RUN flutter clean

# Build the web application (HTML renderer is default in Flutter 3.24+)
RUN flutter build web --release

# Stage 2: Serve the application with Nginx
FROM nginx:alpine

# Copy the build output from the previous stage
COPY --from=build /app/build/web /usr/share/nginx/html

# Copy the Nginx configuration
COPY nginx.conf /etc/nginx/conf.d/default.conf

# Expose port 80
EXPOSE 80

# Start Nginx
CMD ["nginx", "-g", "daemon off;"]
