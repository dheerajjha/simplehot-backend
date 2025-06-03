#!/bin/bash

# SimpleHot Backend Services Startup Script
# This script ensures all services start properly and can be used for system boot

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
COMPOSE_FILE="../docker-compose.yml"
PROJECT_NAME="simplehot-backend"
MAX_WAIT_TIME=300  # 5 minutes
HEALTH_CHECK_INTERVAL=10

# Function to print colored output
print_status() {
    echo -e "${BLUE}[$(date '+%Y-%m-%d %H:%M:%S')]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[$(date '+%Y-%m-%d %H:%M:%S')]${NC} ✅ $1"
}

print_warning() {
    echo -e "${YELLOW}[$(date '+%Y-%m-%d %H:%M:%S')]${NC} ⚠️  $1"
}

print_error() {
    echo -e "${RED}[$(date '+%Y-%m-%d %H:%M:%S')]${NC} ❌ $1"
}

# Function to check if Docker is running
check_docker() {
    print_status "Checking Docker status..."
    if ! docker info >/dev/null 2>&1; then
        print_error "Docker is not running. Please start Docker first."
        exit 1
    fi
    print_success "Docker is running"
}

# Function to check if Docker Compose is available
check_docker_compose() {
    print_status "Checking Docker Compose..."
    if ! command -v docker-compose >/dev/null 2>&1; then
        print_error "Docker Compose is not installed"
        exit 1
    fi
    print_success "Docker Compose is available"
}

# Function to pull latest images
pull_images() {
    print_status "Pulling latest images..."
    docker-compose -f "$COMPOSE_FILE" -p "$PROJECT_NAME" pull
    print_success "Images pulled successfully"
}

# Function to build services
build_services() {
    print_status "Building services..."
    docker-compose -f "$COMPOSE_FILE" -p "$PROJECT_NAME" build --no-cache
    print_success "Services built successfully"
}

# Function to start services
start_services() {
    print_status "Starting services..."
    docker-compose -f "$COMPOSE_FILE" -p "$PROJECT_NAME" up -d
    print_success "Services started"
}

# Function to wait for services to be healthy
wait_for_health() {
    print_status "Waiting for services to become healthy..."
    local start_time=$(date +%s)
    local timeout=$((start_time + MAX_WAIT_TIME))
    
    while [ $(date +%s) -lt $timeout ]; do
        local all_healthy=true
        local services=("postgres" "redis" "auth-service" "user-service" "post-service" "stock-service" "prediction-service" "gateway")
        
        for service in "${services[@]}"; do
            local health_status=$(docker-compose -f "$COMPOSE_FILE" -p "$PROJECT_NAME" ps --format "table {{.Service}}\t{{.Status}}" | grep "$service" | awk '{print $2}')
            
            if [[ ! "$health_status" =~ "healthy" ]] && [[ ! "$health_status" =~ "Up" ]]; then
                all_healthy=false
                break
            fi
        done
        
        if [ "$all_healthy" = true ]; then
            print_success "All services are healthy!"
            return 0
        fi
        
        print_status "Waiting for services to become healthy... ($(( ($(date +%s) - start_time) ))s elapsed)"
        sleep $HEALTH_CHECK_INTERVAL
    done
    
    print_warning "Timeout waiting for all services to become healthy"
    return 1
}

# Function to check service endpoints
check_endpoints() {
    print_status "Checking service endpoints..."
    
    local endpoints=(
        "http://localhost:5050/health:Gateway"
        "http://localhost:5001/health:Auth Service"
        "http://localhost:5002/health:User Service"
        "http://localhost:5003/health:Post Service"
        "http://localhost:5004/health:Stock Service"
        "http://localhost:5005/health:Prediction Service"
    )
    
    for endpoint_info in "${endpoints[@]}"; do
        local url=$(echo "$endpoint_info" | cut -d: -f1)
        local name=$(echo "$endpoint_info" | cut -d: -f2)
        
        if curl -s -f "$url" >/dev/null 2>&1; then
            print_success "$name is responding"
        else
            print_warning "$name is not responding at $url"
        fi
    done
}

# Function to show service status
show_status() {
    print_status "Service Status:"
    docker-compose -f "$COMPOSE_FILE" -p "$PROJECT_NAME" ps
    echo ""
    print_status "Service URLs:"
    echo "  🌐 Gateway:           http://localhost:5050"
    echo "  🔐 Auth Service:      http://localhost:5001"
    echo "  👤 User Service:      http://localhost:5002"
    echo "  📝 Post Service:      http://localhost:5003"
    echo "  📈 Stock Service:     http://localhost:5004"
    echo "  🔮 Prediction Service: http://localhost:5005"
    echo "  🗄️  PostgreSQL:       localhost:5432"
    echo "  🔴 Redis:             localhost:6379"
    echo "  🔧 pgAdmin:           http://localhost:8080"
    echo "  📊 Metabase:          http://localhost:12345"
}

# Function to stop services
stop_services() {
    print_status "Stopping services..."
    docker-compose -f "$COMPOSE_FILE" -p "$PROJECT_NAME" down
    print_success "Services stopped"
}

# Function to restart services
restart_services() {
    print_status "Restarting services..."
    stop_services
    start_services
    wait_for_health
    check_endpoints
    show_status
}

# Function to show logs
show_logs() {
    local service=${1:-""}
    if [ -n "$service" ]; then
        docker-compose -f "$COMPOSE_FILE" -p "$PROJECT_NAME" logs -f "$service"
    else
        docker-compose -f "$COMPOSE_FILE" -p "$PROJECT_NAME" logs -f
    fi
}

# Function to clean up
cleanup() {
    print_status "Cleaning up..."
    docker-compose -f "$COMPOSE_FILE" -p "$PROJECT_NAME" down -v --remove-orphans
    docker system prune -f
    print_success "Cleanup completed"
}

# Main function
main() {
    case "${1:-start}" in
        "start")
            check_docker
            check_docker_compose
            start_services
            wait_for_health
            check_endpoints
            show_status
            ;;
        "stop")
            stop_services
            ;;
        "restart")
            restart_services
            ;;
        "status")
            show_status
            ;;
        "logs")
            show_logs "$2"
            ;;
        "build")
            check_docker
            check_docker_compose
            build_services
            ;;
        "pull")
            check_docker
            check_docker_compose
            pull_images
            ;;
        "cleanup")
            cleanup
            ;;
        "health")
            check_endpoints
            ;;
        *)
            echo "Usage: $0 {start|stop|restart|status|logs [service]|build|pull|cleanup|health}"
            echo ""
            echo "Commands:"
            echo "  start    - Start all services (default)"
            echo "  stop     - Stop all services"
            echo "  restart  - Restart all services"
            echo "  status   - Show service status and URLs"
            echo "  logs     - Show logs for all services or specific service"
            echo "  build    - Build all services"
            echo "  pull     - Pull latest images"
            echo "  cleanup  - Stop services and clean up volumes/networks"
            echo "  health   - Check health of all service endpoints"
            exit 1
            ;;
    esac
}

# Run main function with all arguments
main "$@" 