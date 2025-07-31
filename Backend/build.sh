#!/bin/bash

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}=== Zerodha Backend Docker Build Script ===${NC}"

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

# Check if Docker is running
print_status "Checking Docker daemon..."
if ! docker info > /dev/null 2>&1; then
    print_error "Docker daemon is not running. Please start Docker and try again."
    exit 1
fi

# Clean up any existing containers and images (optional)
read -p "Do you want to clean up existing containers and images? (y/N): " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    print_status "Cleaning up existing containers and images..."
    docker system prune -f
    docker image prune -f
fi

# Set build arguments
IMAGE_NAME="zerodha-backend"
TAG="latest"
FULL_IMAGE_NAME="${IMAGE_NAME}:${TAG}"

print_status "Building Docker image: ${FULL_IMAGE_NAME}"

# Build with retry logic
MAX_RETRIES=3
RETRY_COUNT=0

while [ $RETRY_COUNT -lt $MAX_RETRIES ]; do
    print_status "Build attempt $((RETRY_COUNT + 1)) of $MAX_RETRIES"
    
    # Build the Docker image with detailed output
    if docker build --no-cache --progress=plain -t "${FULL_IMAGE_NAME}" .; then
        print_status "✅ Docker build completed successfully!"
        
        # Show image info
        print_status "Image details:"
        docker images "${FULL_IMAGE_NAME}"
        
        # Optional: Run a quick test
        read -p "Do you want to test the container? (y/N): " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            print_status "Testing container..."
            docker run --rm -d --name test-container -p 5000:5000 "${FULL_IMAGE_NAME}"
            sleep 5
            if curl -f http://localhost:5000/api/market_status > /dev/null 2>&1; then
                print_status "✅ Container test passed!"
            else
                print_warning "⚠️  Container test failed - check logs"
            fi
            docker stop test-container
        fi
        
        exit 0
    else
        RETRY_COUNT=$((RETRY_COUNT + 1))
        if [ $RETRY_COUNT -lt $MAX_RETRIES ]; then
            print_warning "Build failed. Retrying in 10 seconds..."
            sleep 10
        else
            print_error "Build failed after $MAX_RETRIES attempts."
            print_error "Common solutions:"
            print_error "1. Check your internet connection"
            print_error "2. Ensure Docker has enough resources (memory/disk)"
            print_error "3. Try running: docker system prune -a"
            print_error "4. Check if any antivirus is blocking Docker"
            exit 1
        fi
    fi
done 