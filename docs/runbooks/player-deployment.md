# Deployment Guide

## Overview

This guide covers deploying the HexmonSignage Player to production Ubuntu systems.

## System Requirements

### Minimum Requirements
- **OS:** Ubuntu 20.04 LTS or later
- **CPU:** 2 cores (x86_64 or ARM64)
- **RAM:** 2GB
- **Disk:** 20GB free space
- **Network:** Stable internet connection (10 Mbps+)
- **Display:** HDMI output

### Recommended Requirements
- **OS:** Ubuntu 22.04 LTS
- **CPU:** 4 cores (x86_64)
- **RAM:** 4GB
- **Disk:** 50GB SSD
- **Network:** 50 Mbps+ with low latency
- **Display:** 1920x1080 or higher

### Software Dependencies
- Node.js 18+ (bundled in package)
- X11 display server
- OpenSSL 1.1.1+
- systemd

## Pre-Deployment Checklist

- [ ] Ubuntu system installed and updated
- [ ] Network connectivity verified
- [ ] Display connected and working
- [ ] Backend API accessible
- [ ] Pairing code obtained
- [ ] Firewall rules configured
- [ ] Backup plan in place

## Installation Methods

### Method 1: .deb Package (Recommended)

#### 1. Download Package
```bash
wget https://releases.hexmon.com/hexmon-signage-player_1.0.0_amd64.deb
```

#### 2. Install Package
```bash
sudo dpkg -i hexmon-signage-player_1.0.0_amd64.deb
sudo apt-get install -f  # Fix dependencies if needed
```

#### 3. Verify Installation
```bash
which hexmon-signage-player
hexmon-signage-player --version
```

### Method 2: AppImage

#### 1. Download AppImage
```bash
wget https://releases.hexmon.com/HexmonSignage-Player-1.0.0.AppImage
chmod +x HexmonSignage-Player-1.0.0.AppImage
```

#### 2. Run AppImage
```bash
./HexmonSignage-Player-1.0.0.AppImage
```

### Method 3: Build from Source

#### 1. Clone Repository
```bash
git clone https://github.com/hexmon/signage-player.git
cd signage-player
```

#### 2. Install Dependencies
```bash
npm install
```

#### 3. Build
```bash
npm run build
npm run package:deb
```

#### 4. Install
```bash
sudo dpkg -i build/hexmon-signage-player_1.0.0_amd64.deb
```

## Configuration

### 1. Edit Configuration File
```bash
sudo nano /etc/hexmon/config.json
```

### 2. Required Settings
```json
{
  "apiBase": "https://api.hexmon.com",
  "wsUrl": "wss://api.hexmon.com/ws",
  "deviceId": "",  // Will be set during pairing
  "cache": {
    "path": "/var/cache/hexmon",
    "maxBytes": 10737418240  // 10GB
  },
  "intervals": {
    "heartbeatMs": 300000,     // 5 minutes
    "schedulePollMs": 300000,  // 5 minutes
    "commandPollMs": 30000     // 30 seconds
  }
}
```

### 3. Optional Settings
```json
{
  "logLevel": "info",  // debug, info, warn, error
  "mTLS": {
    "enabled": true,
    "certPath": "/var/lib/hexmon/certs"
  },
  "display": {
    "width": 1920,
    "height": 1080,
    "fullscreen": true
  }
}
```

## Device Pairing

### Interactive Pairing
```bash
sudo hexmon-pair-device
```

Follow the prompts:
1. Enter 6-character pairing code
2. Wait for certificate generation
3. Verify pairing success

### Manual Pairing
```bash
# Generate key pair
sudo openssl ecparam -name prime256v1 -genkey -noout \
  -out /var/lib/hexmon/certs/client.key

# Generate CSR
sudo openssl req -new -key /var/lib/hexmon/certs/client.key \
  -out /var/lib/hexmon/certs/client.csr \
  -subj "/CN=$(hostname)/O=HexmonSignage"

# Submit to backend (use API or admin dashboard)
# Save returned certificate to /var/lib/hexmon/certs/client.crt
```

## Service Management

### Enable Service
```bash
sudo systemctl enable hexmon-player
```

### Start Service
```bash
sudo systemctl start hexmon-player
```

### Check Status
```bash
sudo systemctl status hexmon-player
```

### View Logs
```bash
sudo journalctl -u hexmon-player -f
```

### Restart Service
```bash
sudo systemctl restart hexmon-player
```

### Stop Service
```bash
sudo systemctl stop hexmon-player
```

## Network Configuration

### Firewall Rules
```bash
# Allow HTTPS
sudo ufw allow 443/tcp

# Allow WebSocket
sudo ufw allow 443/tcp

# Enable firewall
sudo ufw enable
```

### Proxy Configuration
If using a proxy, add to `/etc/hexmon/config.json`:
```json
{
  "proxy": {
    "http": "http://proxy.example.com:8080",
    "https": "http://proxy.example.com:8080"
  }
}
```

### DNS Configuration
Ensure DNS resolution works:
```bash
nslookup api.hexmon.com
```

## Display Configuration

### Set Resolution
```bash
xrandr --output HDMI-1 --mode 1920x1080
```

### Disable Screen Blanking
```bash
xset s off
xset s noblank
xset -dpms
```

### Auto-start X11
Edit `/etc/X11/default-display-manager`:
```
/usr/sbin/lightdm
```

## Monitoring

### Health Check
```bash
curl http://127.0.0.1:3300/healthz
```

### Metrics
```bash
curl http://127.0.0.1:3300/metrics
```

### Log Monitoring
```bash
# Real-time logs
sudo journalctl -u hexmon-player -f

# Application logs
sudo tail -f /var/cache/hexmon/logs/hexmon-*.log
```

### Alerting
Set up monitoring with:
- Prometheus + Grafana
- Nagios
- Datadog
- Custom scripts

Example Prometheus scrape config:
```yaml
scrape_configs:
  - job_name: 'hexmon-player'
    static_configs:
      - targets: ['localhost:3300']
```

## Backup and Recovery

### Backup Configuration
```bash
sudo tar -czf hexmon-backup.tar.gz \
  /etc/hexmon/ \
  /var/lib/hexmon/certs/
```

### Restore Configuration
```bash
sudo tar -xzf hexmon-backup.tar.gz -C /
sudo systemctl restart hexmon-player
```

### Disaster Recovery
1. Reinstall package
2. Restore configuration
3. Re-pair device if certificates lost
4. Restart service

## Scaling Deployment

### Ansible Playbook
```yaml
---
- hosts: signage_players
  become: yes
  tasks:
    - name: Install HexmonSignage Player
      apt:
        deb: /tmp/hexmon-signage-player_1.0.0_amd64.deb

    - name: Copy configuration
      template:
        src: config.json.j2
        dest: /etc/hexmon/config.json
        mode: '0640'

    - name: Enable and start service
      systemd:
        name: hexmon-player
        enabled: yes
        state: started
```

### Docker (Experimental)
```dockerfile
FROM ubuntu:22.04

RUN apt-get update && apt-get install -y \
    xvfb \
    x11vnc \
    openssl

COPY hexmon-signage-player_1.0.0_amd64.deb /tmp/
RUN dpkg -i /tmp/hexmon-signage-player_1.0.0_amd64.deb

CMD ["hexmon-signage-player"]
```

## Security Hardening

### File Permissions
```bash
sudo chmod 700 /var/lib/hexmon/certs
sudo chmod 600 /var/lib/hexmon/certs/*
sudo chmod 640 /etc/hexmon/config.json
```

### User Isolation
```bash
# Service runs as hexmon user (created during install)
id hexmon
```

### SELinux/AppArmor
```bash
# Enable AppArmor profile
sudo aa-enforce /etc/apparmor.d/hexmon-player
```

### Automatic Updates
```bash
# Enable unattended upgrades
sudo apt-get install unattended-upgrades
sudo dpkg-reconfigure -plow unattended-upgrades
```

## Troubleshooting

See [TROUBLESHOOTING.md](./TROUBLESHOOTING.md) for common issues and solutions.

### Quick Diagnostics
```bash
# Collect diagnostic information
sudo hexmon-collect-logs

# Check service status
sudo systemctl status hexmon-player

# Check health
curl http://127.0.0.1:3300/healthz
```

## Maintenance

### Regular Tasks

**Daily:**
- Monitor health endpoint
- Check for errors in logs

**Weekly:**
- Review system resources
- Check disk space
- Verify playback

**Monthly:**
- Update system packages
- Review security logs
- Test backup restoration
- Check certificate expiry

**Quarterly:**
- Performance review
- Security audit
- Update documentation

### Update Procedure

1. **Backup current installation**
   ```bash
   sudo hexmon-collect-logs
   sudo tar -czf backup.tar.gz /etc/hexmon /var/lib/hexmon/certs
   ```

2. **Download new version**
   ```bash
   wget https://releases.hexmon.com/hexmon-signage-player_1.1.0_amd64.deb
   ```

3. **Stop service**
   ```bash
   sudo systemctl stop hexmon-player
   ```

4. **Install update**
   ```bash
   sudo dpkg -i hexmon-signage-player_1.1.0_amd64.deb
   ```

5. **Start service**
   ```bash
   sudo systemctl start hexmon-player
   ```

6. **Verify**
   ```bash
   curl http://127.0.0.1:3300/healthz
   ```

## Uninstallation

### Remove Package
```bash
sudo systemctl stop hexmon-player
sudo systemctl disable hexmon-player
sudo dpkg -r hexmon-signage-player
```

### Remove Data (Optional)
```bash
sudo rm -rf /var/lib/hexmon
sudo rm -rf /var/cache/hexmon
sudo rm -rf /etc/hexmon
sudo userdel hexmon
```

## Support

For deployment assistance:
- Email: support@hexmon.com
- Documentation: https://docs.hexmon.com
- Community: https://community.hexmon.com

---

**Last Updated:** 2025-01-05
**Version:** 1.0.0

