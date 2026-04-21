#!/bin/bash

# MarketSystem Deployment Script
# Usage: bash deploy.sh [ENVIRONMENT]
# ENVIRONMENT: development | production

set -e

ENVIRONMENT=${1:-production}
PROJECT_NAME="MarketSystemNavoi"
GITHUB_REPO="https://github.com/jsaydullayev/MarketSystemNavoi.git"
BRANCH="master"

echo "🚀 Starting deployment for: $ENVIRONMENT"
echo "=========================================="

# 1. Navigate to project directory
cd /root/$PROJECT_NAME || {
    echo "❌ Project directory not found: /root/$PROJECT_NAME"
    exit 1
}

# 2. Pull latest changes
echo "📥 Pulling latest changes from GitHub..."
git pull origin $BRANCH

# 3. Stop existing containers
echo "🛑 Stopping existing containers..."
docker compose down

# 4. Remove old images (optional - uncomment if needed)
# echo "🗑️ Removing old Docker images..."
# docker image prune -f

# 5. Build and start containers
echo "🔨 Building and starting containers..."
if [ "$ENVIRONMENT" = "production" ]; then
    # Production deployment
    docker compose -f docker-compose.yml up -d --build --force-recreate
else
    # Development deployment
    docker compose -f docker-compose.yml up -d --build
fi

# 6. Wait for services to be healthy
echo "⏳ Waiting for services to start..."
sleep 10

# 7. Check container status
echo "📊 Checking container status..."
docker compose ps

# 8. Check API health
echo "🏥 Checking API health..."
for i in {1..30}; do
    if curl -f http://localhost:8080/health > /dev/null 2>&1; then
        echo "✅ API is healthy!"
        break
    fi
    echo "⏳ Waiting for API... ($i/30)"
    sleep 2
done

# 9. View logs (optional - uncomment for debugging)
# echo "📋 Recent logs:"
# docker compose logs --tail=50

echo "=========================================="
echo "✅ Deployment completed successfully!"
echo ""
echo "🌐 Access URLs (server):"
echo "   API:         http://103.125.217.28:8080"
echo "   API Swagger: http://103.125.217.28:8080/swagger"
echo "   Frontend:    http://103.125.217.28:8081"
echo ""
echo "🌐 Local Access (from server):"
echo "   API:         http://localhost:8080"
echo "   API Swagger: http://localhost:8080/swagger"
echo "   Frontend:    http://localhost:8081"
echo "   Database:    localhost:5433"
echo ""
echo "📝 Useful commands:"
echo "   View logs:    docker compose logs -f"
echo "   Stop all:     docker compose down"
echo "   Restart:      docker compose restart"
