#!/bin/bash

# Build script for K8s demo application
# This script builds Docker images for backend and frontend

set -e

echo "🔨 Building Docker images for K8s demo..."

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Change to project directory
PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$PROJECT_DIR"

echo -e "${BLUE}📦 Building backend image...${NC}"
docker build -t prj-backend:latest ./backend
echo -e "${GREEN}✓ Backend image built successfully${NC}"

echo -e "${BLUE}📦 Building frontend image...${NC}"
docker build -t prj-frontend:latest ./frontend
echo -e "${GREEN}✓ Frontend image built successfully${NC}"

echo -e "${GREEN}🎉 All images built successfully!${NC}"
echo ""
echo "Images created:"
echo "  - prj-backend:latest"
echo "  - prj-frontend:latest"
echo ""
echo -e "${YELLOW}💡 Tip: If using kind/minikube, load images with:${NC}"
echo "  kind load docker-image prj-backend:latest --name <cluster-name>"
echo "  kind load docker-image prj-frontend:latest --name <cluster-name>"
