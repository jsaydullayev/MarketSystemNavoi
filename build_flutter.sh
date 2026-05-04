#!/bin/bash

# Flutter Web Build Script
# Usage: ./build_flutter.sh

set -e  # Exit on error

echo "=========================================="
echo "Flutter Web Build Script"
echo "=========================================="

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Functions
print_success() {
    echo -e "${GREEN}✓ $1${NC}"
}

print_error() {
    echo -e "${RED}✗ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠ $1${NC}"
}

# Check if Flutter is installed
if ! command -v flutter &> /dev/null; then
    print_error "Flutter is not installed. Please install Flutter first."
    exit 1
fi

# Navigate to Flutter project directory
cd MarketSystem.Client || exit 1

print_success "Changed to Flutter project directory"

# Step 1: Get dependencies
echo ""
echo "Step 1: Getting Flutter dependencies..."
flutter pub get
print_success "Dependencies installed"

# Step 2: Clean build artifacts
echo ""
echo "Step 2: Cleaning build artifacts..."
flutter clean
print_success "Build artifacts cleaned"

# Step 3: Build for web
echo ""
echo "Step 3: Building Flutter web app..."
flutter build web --release
print_success "Flutter web app built"

# Step 4: Check build output
echo ""
echo "Step 4: Checking build output..."

if [ -d "build/web" ]; then
    print_success "Build output directory exists"
    echo "Build contents:"
    ls -lh build/web/ | head -20
else
    print_error "Build output directory not found"
    exit 1
fi

# Step 5: Test local build
echo ""
echo "Step 5: Testing local build..."
echo "You can test the build by running:"
echo "  cd build/web"
echo "  python3 -m http.server 8080"
echo ""
echo "Then open: http://localhost:8080"

# Step 6: Build Docker image
echo ""
echo "Step 6: Building Docker image..."

cd ..
docker build -f MarketSystem.Client/Dockerfile -t market-system-client:latest ./MarketSystem.Client
print_success "Docker image built"

# Step 7: Display Docker image info
echo ""
echo "Docker image information:"
docker images | grep market-system-client

echo ""
echo "=========================================="
echo "Build completed successfully!"
echo "=========================================="
echo ""
echo "Next steps:"
echo "1. Deploy to server: docker push market-system-client:latest"
echo "2. Or run locally: docker run -p 8081:80 market-system-client:latest"
echo "3. Or update docker-compose: docker-compose up -d market-system-client"
echo ""

# Optional: Test Docker container
read -p "Do you want to test the Docker container? (y/n) " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo "Starting Docker container..."
    docker run -d --name test-flutter -p 8081:80 market-system-client:latest

    echo "Waiting for container to start..."
    sleep 5

    echo "Testing container..."
    if curl -s http://localhost:8081 > /dev/null; then
        print_success "Container is running successfully"
        echo "Access at: http://localhost:8081"
    else
        print_error "Container test failed"
        docker logs test-flutter
        docker stop test-flutter
        docker rm test-flutter
        exit 1
    fi

    echo "Stopping test container..."
    docker stop test-flutter
    docker rm test-flutter
fi

print_success "Build and test completed!"
