#!/bin/bash

# Colors for better output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}SimpleHot Backend Setup${NC}"
echo "=============================="

# Create a clean .npmrc file for Docker to use
mkdir -p ~/.npm-config-tmp
echo 'registry=https://registry.npmjs.org/' > ~/.npm-config-tmp/.npmrc
echo -e "${GREEN}Created clean .npmrc file for Docker at ~/.npm-config-tmp/.npmrc${NC}"

# Check for .npmrc file in the home directory
NPMRC_FILE="$HOME/.npmrc"
if [ ! -f "$NPMRC_FILE" ]; then
    echo -e "${YELLOW}Warning: No .npmrc file found in your home directory.${NC}"
    echo "This may cause npm authentication issues during Docker builds."
    echo "Would you like to create a basic .npmrc file? (y/n)"
    read -r create_npmrc
    
    if [[ "$create_npmrc" =~ ^[Yy]$ ]]; then
        echo "registry=https://registry.npmjs.org/" > "$NPMRC_FILE"
        echo "always-auth=false" >> "$NPMRC_FILE"
        echo -e "${GREEN}Created basic .npmrc file at $NPMRC_FILE${NC}"
    else
        echo -e "${YELLOW}Continuing without .npmrc file. Docker builds may fail if npm authentication is required.${NC}"
    fi
else
    echo -e "${GREEN}Found .npmrc file at $NPMRC_FILE${NC}"
    
    # Check if using http instead of https in registry URL
    if grep -q "http://" "$NPMRC_FILE"; then
        echo -e "${YELLOW}Warning: Your .npmrc file contains http:// URLs. This may cause issues.${NC}"
        echo "Would you like to update http:// to https:// in your .npmrc? (y/n)"
        read -r update_npmrc
        
        if [[ "$update_npmrc" =~ ^[Yy]$ ]]; then
            sed -i '' 's|http://|https://|g' "$NPMRC_FILE"
            echo -e "${GREEN}Updated registry URLs to use https in $NPMRC_FILE${NC}"
        fi
    fi
fi

# Determine absolute path for this script and the project root
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$SCRIPT_DIR"

# Check for Docker and Docker Compose
echo "Checking for Docker..."
if command -v docker &> /dev/null; then
    echo -e "${GREEN}Docker is installed.${NC}"
    DOCKER_AVAILABLE=true
else
    echo -e "${YELLOW}Docker is not installed. Will run in local mode.${NC}"
    DOCKER_AVAILABLE=false
fi

# Set development mode
if [ "$DOCKER_AVAILABLE" = true ]; then
    echo "Do you want to run in Docker mode? (y/n)"
    read -r use_docker
    
    if [[ "$use_docker" =~ ^[Yy]$ ]]; then
        DEV_MODE="docker"
        cp "$PROJECT_ROOT/.env.docker" "$PROJECT_ROOT/.env"
        echo -e "${GREEN}Using Docker mode.${NC}"
    else
        DEV_MODE="local"
        echo -e "${YELLOW}Using local mode even though Docker is available.${NC}"
    fi
else
    DEV_MODE="local"
    echo -e "${YELLOW}Using local mode because Docker is not available.${NC}"
fi

# Update the .env file with the correct development mode
sed -i '' "s/DEV_MODE=.*/DEV_MODE=$DEV_MODE/g" "$PROJECT_ROOT/.env"

# Install dependencies based on the mode
if [ "$DEV_MODE" = "docker" ]; then
    echo "Building Docker containers..."
    docker-compose build
    
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}Docker build successful.${NC}"
        echo "Starting Docker containers..."
        docker-compose up -d
        
        if [ $? -eq 0 ]; then
            echo -e "${GREEN}Docker containers started successfully.${NC}"
        else
            echo -e "${RED}Failed to start Docker containers. Falling back to local mode.${NC}"
            DEV_MODE="local"
            sed -i '' "s/DEV_MODE=.*/DEV_MODE=local/g" "$PROJECT_ROOT/.env"
        fi
    else
        echo -e "${RED}Docker build failed. Falling back to local mode.${NC}"
        DEV_MODE="local"
        sed -i '' "s/DEV_MODE=.*/DEV_MODE=local/g" "$PROJECT_ROOT/.env"
    fi
fi

# If we're in local mode, install dependencies for each service
if [ "$DEV_MODE" = "local" ]; then
    echo "Installing dependencies in local mode..."
    
    # Install root dependencies
    echo "Installing root dependencies..."
    npm install
    
    # Install gateway dependencies
    echo "Installing gateway dependencies..."
    cd "$PROJECT_ROOT/gateway" && npm install
    
    # Install auth-service dependencies
    echo "Installing auth-service dependencies..."
    cd "$PROJECT_ROOT/auth-service" && npm install
    
    # Install user-service dependencies
    echo "Installing user-service dependencies..."
    cd "$PROJECT_ROOT/user-service" && npm install
    
    echo -e "${GREEN}All dependencies installed successfully.${NC}"
    
    # Return to project root
    cd "$PROJECT_ROOT"
fi

echo -e "${GREEN}Setup complete!${NC}"
echo ""
echo "To start the services in local mode, run:"
echo "  - Gateway: cd gateway && npm start"
echo "  - Auth Service: cd auth-service && npm start"
echo "  - User Service: cd user-service && npm start"
echo ""
echo "To start the services in Docker mode, run:"
echo "  docker-compose up"
echo ""
echo "For more information, see the README.md file." 