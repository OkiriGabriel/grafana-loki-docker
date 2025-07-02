# Step-by-Step Deployment Guide for Grafana Loki Monitoring Stack

This guide provides detailed step-by-step instructions for deploying the complete monitoring stack for your EC2 and DigitalOcean infrastructure.

## 📋 Prerequisites Checklist

Before starting, ensure you have:

- [ ] **Monitoring Server**: EC2 instance (t3.medium or larger) with Ubuntu 20.04+
- [ ] **Application Servers**: EC2 instances and DigitalOcean droplets running your Docker applications
- [ ] **Network Access**: Ports 3000, 9090, 3100, 9093, 9115, 9100, 8080, 9080 open
- [ ] **Storage**: At least 50GB available disk space on monitoring server
- [ ] **Slack Webhook**: For alert notifications (optional)
- [ ] **Email Credentials**: For email alerts (optional)

## 🚀 Step 1: Prepare Monitoring Server

### Step 1.1: Launch EC2 Instance
```bash
# Launch a new EC2 instance with these specifications:
# - Instance Type: t3.medium (2 vCPU, 4GB RAM)
# - OS: Ubuntu 20.04 LTS
# - Storage: 50GB GP3 volume
# - Security Group: Allow ports 3000, 9090, 3100, 9093, 9115, 9100, 8080, 9080
```

### Step 1.2: Connect to Your EC2 Instance
```bash
# SSH to your EC2 instance
ssh -i your-key.pem ubuntu@your-ec2-public-ip

# Update system packages
sudo apt update && sudo apt upgrade -y
```

### Step 1.3: Install Docker
```bash
# Install Docker
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh

# Add your user to docker group
sudo usermod -aG docker $USER

# Logout and login to apply group changes
exit
# SSH back into the instance
ssh -i your-key.pem ubuntu@your-ec2-public-ip
```

### Step 1.4: Install Docker Compose
```bash
# Install Docker Compose
sudo curl -L "https://github.com/docker/compose/releases/download/v2.20.0/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose

# Verify installation
docker-compose --version
```

## 📥 Step 2: Download Monitoring Stack

### Step 2.1: Clone Repository
```bash
# Clone the monitoring stack repository
git clone <your-repo-url>
cd grafana-loki

# Make scripts executable
chmod +x scripts/*.sh
```

### Step 2.2: Verify Files
```bash
# Check that all required files are present
ls -la
ls -la config/
ls -la scripts/
```

## ⚙️ Step 3: Configure Monitoring Stack

### Step 3.1: Run Deployment Script
```bash
# Run the deployment script
./scripts/deploy-monitoring-stack.sh
```

### Step 3.2: Provide Configuration Details
The script will prompt you for the following information. Have these ready:

**Server Information:**
- **EC2 monitoring server private IP**: `10.0.1.10` (the private IP of the EC2 instance where you're installing the monitoring stack)
- **EC2 app server private IPs**: `10.0.1.11,10.0.1.12` (comma-separated private IPs of your EC2 instances running applications)
- **DigitalOcean droplet IPs**: `192.168.1.10,192.168.1.11,192.168.1.12` (comma-separated public IPs of your DigitalOcean droplets)

**How to Find Your IP Addresses:**

**For EC2 Instances:**
```bash
# On each EC2 instance, run:
curl -s http://169.254.169.254/latest/meta-data/local-ipv4
```

**For DigitalOcean Droplets:**
```bash
# On each droplet, run:
curl -s ifconfig.me
# or
curl -s ipinfo.io/ip
```

**Example IP Addresses:**
- Monitoring Server: `10.0.1.10`
- EC2 App Server 1: `10.0.1.11`
- EC2 App Server 2: `10.0.1.12`
- DigitalOcean Droplet 1: `192.168.1.10`
- DigitalOcean Droplet 2: `192.168.1.11`

**Alert Configuration:**
- Slack webhook URL: `https://hooks.slack.com/services/YOUR/WEBHOOK/URL`
- Primary email address: `alerts@yourcompany.com`
- Email password: `your-app-password` (use app password for Gmail)
- Additional email addresses: `devops@company.com,admin@company.com,tech@company.com` (comma-separated, optional)

**API Endpoints:**
- ✅ **Pre-configured** for both staging and production environments
- **Production APIs**: api.bpay.africa, remitbridge.banffapi.com, collections-api-gateway-prod.banffapi.com, core.banffapi.com, and more
- **Staging APIs**: staging.banffapi.com, remitbridge-staging.banffapi.com, staging-collections-api-gateway.banffapi.com, and more
- **Total**: 30+ API endpoints monitored automatically

### Step 3.3: Monitor Deployment Progress
```bash
# Watch the deployment progress
docker-compose ps

# Check logs if needed
docker-compose logs -f
```

## 🔧 Step 4: Verify Monitoring Stack

### Step 4.1: Check Service Status
```bash
# Check if all services are running
docker-compose ps

# Expected output should show all services as "Up"
```

### Step 4.2: Run Health Check
```bash
# Run the health check script
./scripts/health-check.sh

# Expected output:
# ✅ All containers are running
# ✅ Grafana is healthy
# ✅ Prometheus is healthy
# ✅ Loki is healthy
```

### Step 4.3: Access Web Interfaces
```bash
# Get your EC2 public IP
curl -s http://169.254.169.254/latest/meta-data/public-ipv4

# Access URLs (replace YOUR_EC2_PUBLIC_IP with actual IP):
# Grafana: http://YOUR_EC2_PUBLIC_IP:3000 (admin/admin123)
# Prometheus: http://YOUR_EC2_PUBLIC_IP:9090
# Alertmanager: http://YOUR_EC2_PUBLIC_IP:9093
```

## 📊 Step 5: Configure Grafana

### Step 5.1: Access Grafana
1. Open browser and go to `http://YOUR_EC2_PUBLIC_IP:3000`
2. Login with: `admin` / `admin123`

### Step 5.2: Change Default Password
1. Click on your profile icon (bottom left)
2. Select "Profile"
3. Click "Change Password"
4. Set a new secure password

### Step 5.3: Verify Data Sources
1. Go to Configuration → Data Sources
2. Verify these data sources are configured:
   - Prometheus (http://prometheus:9090)
   - Loki (http://loki:3100)

### Step 5.4: Check Dashboards
1. Go to Dashboards
2. Verify these dashboards are imported:
   - Infrastructure Overview
   - Service Health
   - Business Metrics
   - Logs Explorer
   - Docker Container Health

## 📝 Step 6: Install Promtail on Application Servers

### Step 6.1: Prepare Application Server Information
Before proceeding, gather:
- Loki server URL: `http://YOUR_EC2_PRIVATE_IP:3100`
- Server names for each application server
- Environment names (prod/staging/dev)

### Step 6.2: Install on EC2 Application Servers
For each EC2 instance running your applications:

```bash
# SSH to the application server
ssh -i your-key.pem ubuntu@your-app-server-ip

# Download and run Promtail installer
wget https://raw.githubusercontent.com/your-repo/grafana-loki/main/scripts/install-promtail.sh
chmod +x install-promtail.sh
./install-promtail.sh
```

**When prompted, enter:**
- Loki server URL: `http://YOUR_EC2_PRIVATE_IP:3100`
- Server name: `ec2-app-01` (or descriptive name)
- Environment: `prod`

### Step 6.3: Install on DigitalOcean Droplets
For each DigitalOcean droplet:

```bash
# SSH to the droplet
ssh root@your-droplet-ip

# Download and run Promtail installer
wget https://raw.githubusercontent.com/your-repo/grafana-loki/main/scripts/install-promtail.sh
chmod +x install-promtail.sh
./install-promtail.sh
```

**When prompted, enter:**
- Loki server URL: `http://YOUR_EC2_PUBLIC_IP:3100`
- Server name: `do-app-01` (or descriptive name)
- Environment: `prod`

### Step 6.4: Verify Promtail Installation
```bash
# Check Promtail service status
systemctl status promtail

# Check Node Exporter service status
systemctl status node_exporter

# Run health check
/usr/local/bin/promtail-health-check.sh

# Expected output:
# ✅ Promtail service is running
# ✅ Node Exporter service is running
# ✅ Promtail metrics endpoint is responding
# ✅ Node Exporter metrics endpoint is responding
```

## 🔍 Step 7: Verify Data Collection

### Step 7.1: Check Prometheus Targets
1. Go to Prometheus: `http://YOUR_EC2_PUBLIC_IP:9090`
2. Click "Status" → "Targets"
3. Verify all targets show "UP" status:
   - prometheus
   - node-exporter
   - cadvisor
   - blackbox
   - loki
   - alertmanager
   - grafana
   - Your EC2 instances
   - Your DigitalOcean droplets

### Step 7.2: Check Loki Log Collection
1. Go to Grafana: `http://YOUR_EC2_PUBLIC_IP:3000`
2. Go to Explore (compass icon)
3. Select Loki as data source
4. Run these queries to verify log collection:

```logql
# All logs
{job="docker"}

# System logs
{job="varlogs"}

# Application logs
{job="applications"}
```

### Step 7.3: Check Container Metrics
1. In Grafana, go to Dashboards
2. Open "Docker Container Health"
3. Verify you see:
   - Container status overview
   - Resource usage graphs
   - Container logs

## 🚨 Step 8: Configure Alerts

### Step 8.1: Test Slack Integration
1. Go to Alertmanager: `http://YOUR_EC2_PUBLIC_IP:9093`
2. Click "Silence" → "New Silence"
3. Create a test silence
4. Check if Slack notification is received

### Step 8.2: Test Email Integration
1. In Alertmanager, create another test silence
2. Check if email notification is received

### Step 8.3: Verify Alert Rules
1. Go to Prometheus: `http://YOUR_EC2_PUBLIC_IP:9090`
2. Click "Alerts"
3. Verify alert rules are loaded:
   - Infrastructure alerts
   - Service alerts
   - Monitoring alerts
   - Business alerts

## 📈 Step 9: Test Monitoring

### Step 9.1: Generate Test Load
```bash
# On monitoring server, generate CPU load
stress-ng --cpu 4 --timeout 60s

# Check if alerts fire in Grafana
```

### Step 9.2: Test Log Collection
```bash
# On any application server, generate test logs
echo '{"timestamp":"2024-01-15T10:30:00Z","level":"info","message":"Test log entry","service":"test"}' >> /var/log/applications/test.log

# Check if logs appear in Grafana Loki
```

### Step 9.3: Test Container Monitoring
```bash
# On any application server, restart a container
docker restart your-app-container

# Check if container restart is detected in Grafana
```

## 🔒 Step 10: Security Configuration

### Step 10.1: Configure Firewall
```bash
# Verify firewall rules are configured
sudo ufw status

# Should show these ports as ALLOWED:
# 3000/tcp (Grafana)
# 9090/tcp (Prometheus)
# 3100/tcp (Loki)
# 9093/tcp (Alertmanager)
# 9115/tcp (Blackbox Exporter)
# 9100/tcp (Node Exporter)
# 8080/tcp (Cadvisor)
# 9080/tcp (Promtail)
```

### Step 10.2: SSL Configuration (Production)
```bash
# For production, configure SSL certificates
# Install nginx and configure reverse proxy
sudo apt install nginx

# Configure SSL certificates (Let's Encrypt recommended)
sudo apt install certbot python3-certbot-nginx
```

### Step 10.3: Access Control
1. In Grafana, go to Configuration → Users
2. Create additional users as needed
3. Configure appropriate roles and permissions

## 📋 Step 11: Final Verification

### Step 11.1: Complete Health Check
```bash
# Run comprehensive health check
./scripts/health-check.sh

# Check all services
docker-compose ps

# Check disk usage
df -h

# Check memory usage
free -h
```

### Step 11.2: Verify All Components
- [ ] Grafana accessible and dashboards working
- [ ] Prometheus collecting metrics from all targets
- [ ] Loki receiving logs from all servers
- [ ] Alertmanager sending notifications
- [ ] All application servers visible in monitoring
- [ ] Container logs being collected
- [ ] Alerts configured and working
- [ ] Backup script tested

### Step 11.3: Test Backup
```bash
# Test backup functionality
./scripts/backup.sh

# Verify backup files are created
ls -la /backup/
```

## 🎉 Step 12: Deployment Complete

### Step 12.1: Documentation
```bash
# Update your documentation with:
# - Monitoring server IP
# - Access URLs
# - Alert configurations
# - Contact information
```

### Step 12.2: Team Training
1. Schedule training session for your team
2. Demonstrate key features:
   - Viewing dashboards
   - Querying logs
   - Understanding alerts
   - Troubleshooting issues

### Step 12.3: Monitoring Schedule
Set up regular monitoring tasks:
- Daily: Check service health
- Weekly: Review alerts and performance
- Monthly: Update components and review capacity

## 🆘 Troubleshooting Common Issues

### Issue: Services Not Starting
```bash
# Check logs
docker-compose logs -f [service-name]

# Restart specific service
docker-compose restart [service-name]

# Check disk space
df -h
```

### Issue: Promtail Not Sending Logs
```bash
# Check Promtail service
systemctl status promtail

# Check Promtail logs
journalctl -u promtail -f

# Verify Loki connectivity
curl http://your-loki-server:3100/ready
```

### Issue: Alerts Not Firing
```bash
# Check Alertmanager configuration
curl http://localhost:9093/api/v1/status

# Check Prometheus alert rules
curl http://localhost:9090/api/v1/rules
```

### Issue: High Resource Usage
```bash
# Check resource usage
docker stats

# Check log volume
du -sh /var/lib/docker/volumes/

# Review retention settings
```

## 📞 Support Information

- **Monitoring Stack Issues**: Check logs and health checks
- **Application Integration**: Verify Promtail configuration
- **Alert Configuration**: Test in Alertmanager
- **Performance Issues**: Monitor resource usage

Your monitoring stack is now fully deployed and operational! 🎉 