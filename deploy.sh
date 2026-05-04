#!/bin/bash

# MarketSystem Deployment Script
# Usage: ./deploy.sh

set -e  # Exit on error

echo "=========================================="
echo "MarketSystem Deployment Script"
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

# Check if running as root
if [ "$EUID" -eq 0 ]; then
    print_warning "Don't run this script as root. Use a regular user with sudo privileges."
    exit 1
fi

# Check if Docker is installed
if ! command -v docker &> /dev/null; then
    print_error "Docker is not installed. Please install Docker first."
    exit 1
fi

# Check if Docker Compose is installed
if ! command -v docker-compose &> /dev/null; then
    print_error "Docker Compose is not installed. Please install Docker Compose first."
    exit 1
fi

# Step 1: Stop existing containers
echo ""
echo "Step 1: Stopping existing containers..."
docker-compose down
print_success "Containers stopped"

# Step 2: Build and start new containers
echo ""
echo "Step 2: Building and starting containers..."
docker-compose up -d --build
print_success "Containers built and started"

# Step 3: Wait for containers to be ready
echo ""
echo "Step 3: Waiting for containers to be ready..."
sleep 10

# Step 4: Check container status
echo ""
echo "Step 4: Checking container status..."
CONTAINER_STATUS=$(docker-compose ps)
echo "$CONTAINER_STATUS"

if ! docker-compose ps | grep -q "Up"; then
    print_error "Some containers failed to start"
    docker-compose logs
    exit 1
fi

print_success "All containers are running"

# Step 5: Check API health
echo ""
echo "Step 5: Checking API health..."
API_HEALTH=$(curl -s http://localhost:8080/health || echo "failed")

if [ "$API_HEALTH" == "failed" ]; then
    print_error "API health check failed"
    docker-compose logs market-system-api
    exit 1
fi

print_success "API is healthy"
echo "Response: $API_HEALTH"

# Step 6: Check Nginx
echo ""
echo "Step 6: Checking Nginx configuration..."

if [ -f "web_server_config/nginx.conf" ]; then
    print_success "Nginx configuration file found"
    echo "Please manually update nginx configuration:"
    echo "  sudo cp web_server_config/nginx.conf /etc/nginx/sites-available/strotech.uz"
    echo "  sudo nginx -t"
    echo "  sudo systemctl reload nginx"
else
    print_warning "Nginx configuration file not found"
fi

# Step 7: Display service URLs
echo ""
echo "=========================================="
echo "Deployment completed successfully!"
echo "=========================================="
echo ""
echo "Services are now accessible at:"
echo "  • API Health:        http://114.29.239.156:8080/health"
echo "  • API Swagger:      http://114.29.239.156:8080/swagger/index.html"
echo "  • Frontend:          http://114.29.239.156/"
echo "  • API Endpoints:     http://114.29.239.156:8080/api"
echo ""
echo "To view logs:"
echo "  docker-compose logs -f"
echo "  docker-compose logs -f market-system-api"
echo "  docker-compose logs -f market-system-client"
echo ""
echo "To restart services:"
echo "  docker-compose restart"
echo ""
echo "To stop services:"
echo "  docker-compose down"
echo ""

# Step 8: Optional: Run tests
read -p "Do you want to run tests? (y/n) " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo "Running tests..."
    # Add your test commands here
fi

print_success "Deployment completed!"
