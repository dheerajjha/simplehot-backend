#!/bin/bash

# SimpleHot Backend Auto-Start Setup
# One-command setup for automatic service recovery

set -e

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

print_status() { echo -e "${YELLOW}[SETUP]${NC} $1"; }
print_success() { echo -e "${GREEN}[SETUP]${NC} ✅ $1"; }
print_error() { echo -e "${RED}[SETUP]${NC} ❌ $1"; }

# Check prerequisites
check_requirements() {
    print_status "Checking requirements..."
    
    if [ "$EUID" -eq 0 ]; then
        print_error "Please run as regular user, not root"
        exit 1
    fi
    
    if ! command -v docker >/dev/null 2>&1; then
        print_error "Docker not installed. Please install Docker first."
        exit 1
    fi
    
    if ! command -v docker-compose >/dev/null 2>&1; then
        print_error "Docker Compose not installed. Please install Docker Compose first."
        exit 1
    fi
    
    print_success "Requirements met"
}

# Setup Docker permissions
setup_docker() {
    print_status "Setting up Docker..."
    
    if ! groups $USER | grep -q docker; then
        sudo usermod -aG docker $USER
        print_success "Added user to docker group (logout/login required)"
    fi
    
    sudo systemctl enable docker
    sudo systemctl start docker
    print_success "Docker configured"
}

# Install systemd service
install_service() {
    print_status "Installing systemd service..."
    
    sudo cp simplehot-backend.service /etc/systemd/system/
    sudo systemctl daemon-reload
    sudo systemctl enable simplehot-backend.service
    
    print_success "Auto-start service installed"
}

# Create simple monitoring
create_monitor() {
    print_status "Creating health monitor..."
    
    cat > monitor.sh << 'EOF'
#!/bin/bash
# Simple health monitor - restarts services if any are down

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

# Check if any service is down
if ! curl -s -f http://localhost:5050/health >/dev/null 2>&1; then
    echo "[$(date)] Gateway down - restarting services"
    ./start-services.sh restart
fi
EOF
    
    chmod +x monitor.sh
    
    # Add to cron (every 5 minutes)
    (crontab -l 2>/dev/null | grep -v "monitor.sh"; echo "*/5 * * * * cd $(pwd) && ./monitor.sh") | crontab -
    
    print_success "Health monitoring configured"
}

# Make scripts executable
setup_scripts() {
    chmod +x start-services.sh setup-auto-start.sh
    print_success "Scripts made executable"
}

# Main setup
main() {
    echo "🚀 SimpleHot Backend Auto-Recovery Setup"
    echo "========================================"
    
    check_requirements
    setup_docker
    setup_scripts
    install_service
    create_monitor
    
    echo ""
    print_success "🎉 Setup complete!"
    echo ""
    echo "📋 What's configured:"
    echo "  ✅ Auto-start on boot (systemd)"
    echo "  ✅ Auto-restart on crash (docker-compose)"
    echo "  ✅ Health monitoring (cron)"
    echo ""
    echo "🚀 Quick commands:"
    echo "  ./start-services.sh start   - Start services"
    echo "  ./start-services.sh status  - Check status"
    echo "  ./start-services.sh health  - Health check"
    echo ""
    echo "🔧 System commands:"
    echo "  sudo systemctl start simplehot-backend"
    echo "  sudo systemctl status simplehot-backend"
    echo ""
    print_success "Your services will now survive crashes and reboots!"
}

main "$@"