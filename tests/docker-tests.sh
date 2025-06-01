#!/bin/bash

echo "🚀 Running SimpleHot Backend Tests in Docker Environment"
echo "======================================================"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Step 1: Check if Docker is installed
if ! command -v docker &> /dev/null; then
    echo -e "${RED}Error: Docker is not installed or not in PATH${NC}"
    exit 1
fi

# Step 2: Check if Docker Compose is installed
if ! command -v docker-compose &> /dev/null; then
    echo -e "${RED}Error: Docker Compose is not installed or not in PATH${NC}"
    exit 1
fi

# Step 3: Build and start the services
echo -e "${YELLOW}🔨 Building and starting services...${NC}"
docker-compose up -d --build

# Step 4: Wait for services to be ready
echo -e "${YELLOW}⏳ Waiting for services to be ready...${NC}"
sleep 20  # Initial wait

# Check if gateway is responding
echo "Checking if gateway is ready..."
max_attempts=30
attempt=1
while [ $attempt -le $max_attempts ]; do
    echo "Attempt $attempt of $max_attempts..."
    if curl -s http://localhost:5050/health | grep -q "healthy"; then
        echo -e "${GREEN}Gateway is ready!${NC}"
        break
    fi
    if [ $attempt -eq $max_attempts ]; then
        echo -e "${RED}Gateway did not become ready in time. Exiting.${NC}"
        docker-compose logs gateway
        docker-compose down
        exit 1
    fi
    attempt=$((attempt + 1))
    sleep 2
done

# Step 5: Run tests
echo -e "${YELLOW}🧪 Running all tests...${NC}"
./tests/run-all-tests.sh
TEST_EXIT_CODE=$?

# Step 6: Display logs if tests failed
if [ $TEST_EXIT_CODE -ne 0 ]; then
    echo -e "${RED}Tests failed. Displaying service logs:${NC}"
    docker-compose logs
fi

# Step 7: Clean up
echo -e "${YELLOW}🧹 Cleaning up...${NC}"
docker-compose down

# Exit with test result
if [ $TEST_EXIT_CODE -eq 0 ]; then
    echo -e "${GREEN}🎉 All tests passed successfully!${NC}"
    exit 0
else
    echo -e "${RED}❌ Tests failed with exit code $TEST_EXIT_CODE${NC}"
    exit $TEST_EXIT_CODE
fi 