# SimpleHot Backend Automation

This folder contains all the scripts needed for automatic service management and recovery.

## 📁 Files

- **`start-services.sh`** - Main service management script
- **`setup-auto-start.sh`** - One-time setup for auto-recovery
- **`simplehot-backend.service`** - Systemd service file
- **`monitor.sh`** - Health monitoring script (created during setup)

## 🚀 Quick Setup

```bash
# Run once to enable auto-recovery
./setup-auto-start.sh
```

## 📋 Daily Commands

```bash
# Start all services
./start-services.sh start

# Check status
./start-services.sh status

# View logs
./start-services.sh logs

# Health check
./start-services.sh health
```

## 🔄 What Auto-Recovery Does

1. **Boot Recovery** - Services start automatically when server reboots
2. **Crash Recovery** - Docker restarts failed containers automatically  
3. **Health Monitoring** - Cron job checks every 5 minutes and restarts if needed
4. **Dependency Management** - Services wait for databases before starting

## 🛠️ System Integration

- **Systemd Service**: `sudo systemctl status simplehot-backend`
- **Cron Monitoring**: `crontab -l` to see health checks
- **Docker Restart Policy**: `restart: unless-stopped` in docker-compose.yml 