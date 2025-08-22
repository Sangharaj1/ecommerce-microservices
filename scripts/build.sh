#!/bin/bash

# Build and Deploy E-Commerce Microservices
# Usage: ./build.sh [options]

set -e

# Configuration
DOCKER_REGISTRY="your-registry.com"
PROJECT_VERSION="1.0.0"
NAMESPACE="ecommerce"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Function to build service
build_service() {
    local service_name=$1
    print_status "Building $service_name..."
    
    cd $service_name
    
    # Build JAR
    ./mvnw clean package -DskipTests
    
    # Build Docker image
    docker build -t ${DOCKER_REGISTRY}/${service_name}:${PROJECT_VERSION} .
    
    # Tag as latest
    docker tag ${DOCKER_REGISTRY}/${service_name}:${PROJECT_VERSION} ${DOCKER_REGISTRY}/${service_name}:latest
    
    cd ..
    print_status "$service_name built successfully"
}

# Main build process
main() {
    print_status "Starting E-Commerce Microservices build process..."
    
    # Array of services to build
    services=("discovery-server" "config-server" "auth-service" "user-service" "product-service" "order-service" "api-gateway")
    
    # Build parent project first
    print_status "Building parent project..."
    ./mvnw clean install -DskipTests
    
    # Build each service
    for service in "${services[@]}"; do
        if [ -d "$service" ]; then
            build_service $service
        else
            print_warning "Service directory $service not found, skipping..."
        fi
    done
    
    print_status "Build process completed successfully!"
    print_status "To deploy to Kubernetes, run: ./deploy.sh"
}

# Parse command line arguments
case "${1:-}" in
    --help|-h)
        echo "Usage: $0 [options]"
        echo "Options:"
        echo "  --help    Show this help message"
        exit 0
        ;;
    *)
        main "$@"
        ;;
esac
