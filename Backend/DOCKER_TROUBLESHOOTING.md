# Docker Build Troubleshooting Guide

## Error: "failed to build: failed to receive status: rpc error: code = Unavailable desc = error reading from server: EOF"

This error typically occurs due to network connectivity issues, resource constraints, or Docker daemon problems.

## Quick Solutions (Try in Order)

### 1. Restart Docker Daemon
```bash
# Windows
Restart Docker Desktop

# Linux
sudo systemctl restart docker

# macOS
sudo killall Docker && open /Applications/Docker.app
```

### 2. Clean Docker System
```bash
# Remove unused containers, networks, images
docker system prune -a

# Remove all stopped containers
docker container prune

# Remove unused images
docker image prune -a
```

### 3. Check Docker Resources
- **Windows/macOS**: Open Docker Desktop → Settings → Resources
- Ensure Docker has at least 4GB RAM and 20GB disk space
- Increase memory allocation if needed

### 4. Network Issues
```bash
# Check Docker network
docker network ls

# Reset Docker network
docker network prune
```

## Build Commands

### Option 1: Using Docker Compose (Recommended)
```bash
cd Backend
docker-compose up --build
```

### Option 2: Using Docker Build
```bash
cd Backend
docker build -t zerodha-backend .
```

### Option 3: Using Build Script
```bash
cd Backend
./build.sh
```

## Advanced Troubleshooting

### 1. Check Docker Logs
```bash
# Check Docker daemon logs
docker system info

# Check build logs with verbose output
docker build --progress=plain -t zerodha-backend .
```

### 2. Network Proxy Issues
If behind a corporate firewall:
```bash
# Set proxy environment variables
export HTTP_PROXY=http://proxy.company.com:8080
export HTTPS_PROXY=http://proxy.company.com:8080
export NO_PROXY=localhost,127.0.0.1
```

### 3. DNS Issues
```bash
# Check DNS resolution
nslookup registry-1.docker.io

# Try using Google DNS
docker run --dns 8.8.8.8 --dns 8.8.4.4 ...
```

### 4. Antivirus Interference
- Temporarily disable antivirus
- Add Docker directories to antivirus exclusions
- Check Windows Defender settings

### 5. Disk Space Issues
```bash
# Check available disk space
df -h

# Clean up Docker
docker system prune -a --volumes
```

## Build Optimization

### 1. Use Build Cache
```bash
# Build with cache
docker build -t zerodha-backend .

# Build without cache (if issues persist)
docker build --no-cache -t zerodha-backend .
```

### 2. Multi-stage Build (Alternative)
If the current build is too heavy, consider using multi-stage builds to reduce image size.

### 3. Build Context
Ensure you're in the correct directory:
```bash
# Should be in Backend directory
pwd
ls -la dockerfile
```

## Common Windows-Specific Issues

### 1. WSL2 Issues
```bash
# Update WSL2
wsl --update

# Restart WSL2
wsl --shutdown
```

### 2. Hyper-V Issues
```bash
# Enable Hyper-V (run as administrator)
Enable-WindowsOptionalFeature -Online -FeatureName Microsoft-Hyper-V -All
```

### 3. File Sharing Issues
- Ensure the project directory is shared in Docker Desktop
- Check Windows Defender Firewall settings

## Alternative Solutions

### 1. Use Different Base Image
If the current Python image is causing issues, try:
```dockerfile
FROM python:3.10-alpine
# Note: Alpine requires different package installation
```

### 2. Build on Different Machine
- Try building on a different machine/OS
- Use cloud build services (GitHub Actions, GitLab CI)

### 3. Manual Installation
If Docker continues to fail, consider running the application directly:
```bash
cd Backend
pip install -r requirements.txt
python app.py
```

## Getting Help

If none of the above solutions work:

1. Check Docker Desktop logs
2. Run `docker version` and `docker info`
3. Check system resources (CPU, RAM, disk)
4. Try building a simple test image first
5. Consider using a different Docker version

## Test Commands

After successful build, test the container:
```bash
# Run container
docker run -p 5000:5000 zerodha-backend

# Test health endpoint
curl http://localhost:5000/api/market_status

# Check container logs
docker logs <container_id>
``` 