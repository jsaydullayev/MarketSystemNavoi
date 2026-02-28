# Stage 1: Build the Flutter Web application
FROM ghcr.io/cirruslabs/flutter:stable AS build

# Set the working directory
WORKDIR /app

# Copy the pubspec files and install dependencies
COPY pubspec.* ./
RUN flutter pub get

# Copy the rest of the application code
COPY . .

# Build the web application
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
