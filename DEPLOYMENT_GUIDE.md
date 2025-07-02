# Grafana Loki Monitoring Stack - Deployment Guide

This guide provides step-by-step instructions for deploying the complete monitoring stack for your EC2 and DigitalOcean infrastructure.

## 🎯 Deployment Overview

**Timeline**: 5 days  
**Components**: Grafana, Loki, Prometheus, Alertmanager, Blackbox Exporter  
**Coverage**: Infrastructure, Services, Business Metrics  

## 📋 Prerequisites

### Monitoring Server Requirements
- **EC2 Instance**: t3.medium or larger (2 vCPU, 4GB RAM minimum)
- **OS**: Ubuntu 20.04 LTS or later
- **Storage**: 50GB+ available disk space
- **Network**: Ports 3000, 9090, 3100, 9093, 9115, 9100, 8080, 9080 open

### Application Server Requirements
- **OS**: Ubuntu 18.04+ or CentOS 7+
- **Storage**: 10GB+ available disk space
- **Network**: Ports 9080, 9100 open for Promtail and Node Exporter

## 🚀 Day 1: Monitoring Server Setup

### Step 1: Launch EC2 Instance
```bash
# Launch t3.medium instance with Ubuntu 20.04
# Security Group: Allow ports 3000, 9090, 3100, 9093, 9115, 9100, 8080, 9080
# Storage: 50GB GP3 volume
```

### Step 2: Install Dependencies
```bash
# Update system
sudo apt update && sudo apt upgrade -y

# Install Docker
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh
sudo usermod -aG docker $USER

# Install Docker Compose
sudo curl -L "https://github.com/docker/compose/releases/download/v2.20.0/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose

# Logout and login to apply docker group changes
exit
# SSH back into the instance
```

### Step 3: Deploy Monitoring Stack
```bash
# Clone the repository
git clone <your-repo-url>
cd grafana-loki

# Run deployment script
./scripts/deploy-monitoring-stack.sh
```

**Script will prompt for:**
- EC2 private IP: `10.0.1.10` (example)
- DigitalOcean IPs: `192.168.1.10,192.168.1.11,192.168.1.12`
- Slack webhook: `https://hooks.slack.com/services/YOUR/WEBHOOK/URL`
- Email: `alerts@yourcompany.com`
- Email password: `your-app-password`
- API endpoints:
  - Main API: `https://api.yourcompany.com`
  - Remittance: `https://remittance.yourcompany.com`
  - Collection: `https://collection.yourcompany.com`
  - Agency: `https://agency.yourcompany.com`

### Step 4: Verify Deployment
```bash
# Check service status
docker-compose ps

# Run health check
./scripts/health-check.sh

# Access Grafana
# Open http://your-ec2-public-ip:3000
# Login: admin/admin123
```

## 📊 Day 2: Application Server Setup

### Step 1: Install Promtail on EC2 App Servers
For each EC2 instance running your applications:

```bash
# SSH to the application server
ssh ubuntu@your-app-server-ip

# Download and run Promtail installer
wget https://raw.githubusercontent.com/your-repo/grafana-loki/main/scripts/install-promtail.sh
chmod +x install-promtail.sh
./install-promtail.sh
```

**Script will prompt for:**
- Loki server URL: `http://your-monitoring-server-private-ip:3100`
- Server name: `ec2-app-01`
- Environment: `prod`

### Step 2: Install Promtail on DigitalOcean Droplets
For each DigitalOcean droplet:

```bash
# SSH to the droplet
ssh root@your-droplet-ip

# Download and run Promtail installer
wget https://raw.githubusercontent.com/your-repo/grafana-loki/main/scripts/install-promtail.sh
chmod +x install-promtail.sh
./install-promtail.sh
```

**Script will prompt for:**
- Loki server URL: `http://your-monitoring-server-public-ip:3100`
- Server name: `do-app-01`
- Environment: `prod`

### Step 3: Verify Log Collection
```bash
# Check Promtail status
systemctl status promtail

# Check Node Exporter status
systemctl status node_exporter

# Run health check
/usr/local/bin/promtail-health-check.sh
```

## 🔧 Day 3: Configuration & Customization

### Step 1: Configure Grafana Dashboards
1. **Access Grafana**: `http://your-monitoring-server:3000`
2. **Change Password**: Admin → Profile → Change Password
3. **Import Dashboards**:
   - Infrastructure Overview (auto-imported)
   - Service Health (auto-imported)
   - Business Metrics (auto-imported)
   - Logs Explorer (auto-imported)

### Step 2: Configure Alerting
1. **Slack Integration**:
   - Create Slack app at https://api.slack.com/apps
   - Enable Incoming Webhooks
   - Copy webhook URL to Alertmanager config

2. **Email Integration**:
   - For Gmail: Enable 2FA and create app password
   - Update Alertmanager config with credentials

### Step 3: Customize Prometheus Targets
Edit `config/prometheus/prometheus.yml`:

```yaml
# Add your actual server IPs
- job_name: 'ec2-instances'
  static_configs:
    - targets:
      - '10.0.1.10:9100'  # Your actual EC2 IPs
      - '10.0.1.11:9100'

- job_name: 'digitalocean-droplets'
  static_configs:
    - targets:
      - '192.168.1.10:9100'  # Your actual droplet IPs
      - '192.168.1.11:9100'
```

### Step 4: Application Logging
The monitoring stack automatically captures all Docker container logs. No application changes are required.

Your existing Java and React applications will have their logs automatically:
- Collected from stdout/stderr
- Parsed for errors, warnings, and business events
- Indexed and searchable in Grafana
- Monitored for patterns like failed transactions and exceptions

## 📈 Day 4: Business Metrics Integration

### Step 1: Automatic Business Metrics from Logs
The monitoring stack automatically extracts business metrics from your application logs:

- **Failed transactions** - Detected from logs containing "failed", "error", "exception"
- **Successful operations** - Detected from logs containing "success", "completed"
- **Warning messages** - Detected from logs containing "warn", "warning"
- **API errors** - Detected from logs containing "API error", "HTTP 5xx"
- **Database issues** - Detected from logs containing "database", "connection failed"

No code changes required - the system analyzes your existing log patterns automatically.

### Step 2: Update Prometheus Configuration
Add application metrics endpoints to `config/prometheus/prometheus.yml`:

```yaml
- job_name: 'application-services'
  static_configs:
    - targets:
      - 'app-server-1:8080'  # Your app endpoints
      - 'app-server-2:8080'
      - 'app-server-3:8080'
  metrics_path: /metrics
  scrape_interval: 30s
```

### Step 3: Create Business Alerts
Add business-specific alert rules to `config/prometheus/rules/alerts.yml`:

```yaml
- alert: RemittanceHighFailureRate
  expr: rate(remittance_transactions_total{status="failed"}[5m]) / rate(remittance_transactions_total[5m]) * 100 > 10
  for: 5m
  labels:
    severity: warning
    team: business
    product: remittance
  annotations:
    summary: "High remittance transaction failure rate"
    description: "Remittance transaction failure rate is above 10%"
```

## 🔔 Day 5: Testing & Validation

### Step 1: Test Infrastructure Monitoring
```bash
# Generate load to test alerts
stress-ng --cpu 4 --timeout 60s

# Check if alerts fire
# Monitor Grafana dashboards
# Verify Slack/email notifications
```

### Step 2: Test Service Monitoring
```bash
# Test API endpoints
curl -I https://your-api.com/health

# Simulate service downtime
sudo systemctl stop nginx

# Verify alerts and recovery
```

### Step 3: Test Log Collection
```bash
# Generate test logs
echo '{"timestamp":"2024-01-15T10:30:00Z","level":"info","message":"Test log entry","service":"test"}' >> /var/log/applications/test.log

# Check if logs appear in Grafana
# Query: {job="applications"}
```

### Step 4: Performance Testing
```bash
# Monitor resource usage
docker stats

# Check disk usage
df -h

# Monitor network traffic
iftop
```

## 📋 Post-Deployment Checklist

### ✅ Infrastructure
- [ ] All services running: `docker-compose ps`
- [ ] Health checks passing: `./scripts/health-check.sh`
- [ ] Firewall rules configured
- [ ] SSL certificates installed (production)
- [ ] Backup script tested: `./scripts/backup.sh`

### ✅ Monitoring
- [ ] All servers visible in Prometheus targets
- [ ] Logs flowing to Loki
- [ ] Dashboards displaying data
- [ ] Alerts configured and tested
- [ ] Slack/email notifications working

### ✅ Applications
- [ ] Promtail installed on all app servers
- [ ] Node Exporter running on all servers
- [ ] Application metrics exposed
- [ ] Structured logging configured
- [ ] Business metrics integrated

### ✅ Security
- [ ] Grafana password changed
- [ ] Access controls configured
- [ ] Network security reviewed
- [ ] SSL certificates valid
- [ ] Backup encryption configured

## 🛠️ Maintenance Procedures

### Daily Tasks
```bash
# Check service health
./scripts/health-check.sh

# Monitor disk usage
df -h /var/lib/docker/volumes/

# Review recent alerts
# Check Grafana dashboards
```

### Weekly Tasks
```bash
# Create backup
./scripts/backup.sh

# Review log retention
# Check alert effectiveness
# Update documentation
```

### Monthly Tasks
```bash
# Update components
docker-compose pull
docker-compose up -d

# Review and optimize configurations
# Analyze performance trends
# Plan capacity upgrades
```

## 🚨 Emergency Procedures

### Service Recovery
```bash
# Restart specific service
docker-compose restart prometheus

# Restart entire stack
docker-compose down
docker-compose up -d

# Check logs for issues
docker-compose logs -f [service-name]
```

### Data Recovery
```bash
# Restore from backup
tar -xzf /backup/prometheus-data.tar.gz -C /var/lib/docker/volumes/prometheus-storage/_data/

# Restart services
docker-compose restart prometheus loki
```

### Complete Rebuild
```bash
# Stop all services
docker-compose down

# Remove volumes (WARNING: Data loss)
docker volume rm grafana-loki_prometheus-storage grafana-loki_loki-storage

# Redeploy
./scripts/deploy-monitoring-stack.sh
```

## 📞 Support Contacts

- **Infrastructure Issues**: DevOps Team
- **Application Integration**: Development Team
- **Business Metrics**: Product Team
- **Alert Configuration**: Operations Team

## 📚 Additional Resources

- [Grafana Documentation](https://grafana.com/docs/)
- [Loki Documentation](https://grafana.com/docs/loki/latest/)
- [Prometheus Documentation](https://prometheus.io/docs/)
- [Alertmanager Documentation](https://prometheus.io/docs/alerting/latest/alertmanager/)

---

**Deployment completed successfully!** 🎉

Your monitoring stack is now ready to provide comprehensive observability across your EC2 and DigitalOcean infrastructure. 