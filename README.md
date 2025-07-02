# Grafana Loki Monitoring Stack

A comprehensive monitoring solution for EC2 instances and DigitalOcean droplets, featuring Grafana Loki for log aggregation, Prometheus for metrics collection, and Alertmanager for alert routing.

## 🏗️ Architecture Overview

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   EC2 Instance  │    │ DigitalOcean    │    │   Monitoring    │
│   (App Server)  │    │   Droplet       │    │   Server (EC2)  │
│                 │    │   (App Server)  │    │                 │
│ ┌─────────────┐ │    │ ┌─────────────┐ │    │ ┌─────────────┐ │
│ │  Promtail   │ │    │ │  Promtail   │ │    │ │   Grafana   │ │
│ │ Node Exporter│ │    │ │ Node Exporter│ │    │ │   Loki      │ │
│ └─────────────┘ │    │ └─────────────┘ │    │ │ Prometheus  │ │
└─────────────────┘    └─────────────────┘    │ │Alertmanager │ │
                                              │ └─────────────┘ │
                                              └─────────────────┘
```

## 📋 Components

| Component | Purpose | Port | Description |
|-----------|---------|------|-------------|
| **Grafana** | Visualization & Dashboards | 3000 | Web UI for metrics and logs |
| **Loki** | Log Aggregation | 3100 | Centralized log storage |
| **Prometheus** | Metrics Collection | 9090 | Time-series metrics database |
| **Alertmanager** | Alert Routing | 9093 | Slack/Email notifications |
| **Blackbox Exporter** | API Health Checks | 9115 | Endpoint monitoring |
| **Node Exporter** | System Metrics | 9100 | Host metrics collection |
| **Cadvisor** | Container Metrics | 8080 | Docker container monitoring |
| **Promtail** | Log Collection | 9080 | Log shipping agent |

## 🚀 Quick Start

### Prerequisites

- Docker and Docker Compose installed
- Linux server (Ubuntu 20.04+ recommended)
- At least 4GB RAM and 20GB disk space
- Ports 3000, 9090, 3100, 9093, 9115, 9100, 8080, 9080 available

### 1. Deploy Monitoring Stack

```bash
# Clone the repository
git clone <your-repo-url>
cd grafana-loki

# Make scripts executable
chmod +x scripts/*.sh

# Run the deployment script
./scripts/deploy-monitoring-stack.sh
```

The script will prompt you for:
- EC2 private IP address
- DigitalOcean droplet IPs
- Slack webhook URL
- Email configuration
- API endpoints for monitoring

### 2. Install Promtail on Application Servers

For each EC2 instance and DigitalOcean droplet running your applications:

```bash
# Run the Promtail installation script
./scripts/install-promtail.sh
```

The script will prompt you for:
- Loki server URL
- Server name/identifier
- Environment (prod/staging/dev)

## 📊 Access URLs

After deployment, access the monitoring interfaces:

- **Grafana**: `http://your-server-ip:3000` (admin/admin123)
- **Prometheus**: `http://your-server-ip:9090`
- **Alertmanager**: `http://your-server-ip:9093`
- **Loki**: `http://your-server-ip:3100`

## 🔧 Configuration

### Alertmanager Setup

1. **Slack Integration**:
   - Create a Slack app and get the webhook URL
   - Update `config/alertmanager/alertmanager.yml`
   - Replace `YOUR_SLACK_WEBHOOK_URL` with your actual webhook

2. **Email Integration**:
   - Configure SMTP settings in `config/alertmanager/alertmanager.yml`
   - For Gmail, use app passwords instead of regular passwords

### Prometheus Targets

Update `config/prometheus/prometheus.yml` with your actual server IPs:

```yaml
# EC2 Instances
- job_name: 'ec2-instances'
  static_configs:
    - targets:
      - '10.0.1.10:9100'  # Replace with your EC2 IPs
      - '10.0.1.11:9100'

# DigitalOcean Droplets
- job_name: 'digitalocean-droplets'
  static_configs:
    - targets:
      - '192.168.1.10:9100'  # Replace with your droplet IPs
      - '192.168.1.11:9100'
```

### API Endpoints

Configure your API endpoints in `config/prometheus/prometheus.yml`:

```yaml
- job_name: 'blackbox'
  static_configs:
    - targets:
      - https://your-api.com/health
      - https://remittance.your-domain.com/health
      - https://collection.your-domain.com/health
      - https://agency.your-domain.com/health
```

## 📈 Dashboards

### Pre-configured Dashboards

1. **Infrastructure Overview**: System resources across all nodes
2. **Service Health**: API endpoint monitoring and availability
3. **Logs Explorer**: Centralized log search and analysis

### Custom Dashboards

Create custom dashboards for your business metrics:

- **Remittance Dashboard**: Transaction volumes, failure rates, latency
- **Collection Dashboard**: API success rates, job durations
- **Agency Banking Dashboard**: Login activity, transaction errors

## 🔔 Alerting Rules

### Infrastructure Alerts

- **High CPU Usage**: >80% for 5 minutes
- **High Memory Usage**: >85% for 5 minutes
- **High Disk Usage**: >85% for 5 minutes
- **Node Down**: Immediate critical alert

### Service Alerts

- **Service Down**: Immediate critical alert
- **High Response Time**: >2 seconds for 5 minutes
- **High Error Rate**: >5% for 5 minutes

### Business Alerts

- **Remittance Failure Rate**: >10% for 5 minutes
- **Collection API Latency**: >1 second (95th percentile)
- **Agency Login Issues**: >10 failed attempts per minute

## 📝 Log Management

### Log Structure

```
/var/log/
├── applications/     # General application logs
├── remittance/       # Remittance service logs
├── collection/       # Collection service logs
├── agency/          # Agency banking logs
├── nginx/           # Web server logs
└── apache2/         # Web server logs
```

### Log Format

Configure your applications to output structured JSON logs:

```json
{
  "timestamp": "2024-01-15T10:30:00Z",
  "level": "info",
  "message": "Transaction processed successfully",
  "service": "remittance",
  "trace_id": "abc123",
  "user_id": "user456",
  "transaction_id": "txn789"
}
```

### Log Queries in Grafana

Example Loki queries:

```
# All logs from remittance service
{job="remittance"}

# Error logs from last hour
{job="remittance"} |= "error"

# Logs with specific trace ID
{job="remittance"} | json | trace_id="abc123"

# Logs by environment
{environment="prod"}
```

## 🛠️ Maintenance

### Health Checks

```bash
# Check monitoring stack health
./scripts/health-check.sh

# Check Promtail health on app servers
/usr/local/bin/promtail-health-check.sh
```

### Backups

```bash
# Create backup of monitoring data
./scripts/backup.sh
```

### Updates

```bash
# Update monitoring stack
docker-compose pull
docker-compose up -d

# Update Promtail on app servers
# Download new version and restart service
```

### Log Rotation

Log rotation is automatically configured:
- Daily rotation
- 7 days retention
- Compression enabled
- Automatic Promtail reload

## 🔒 Security

### Firewall Configuration

The deployment scripts automatically configure firewall rules for:
- Grafana (3000)
- Prometheus (9090)
- Loki (3100)
- Alertmanager (9093)
- Blackbox Exporter (9115)
- Node Exporter (9100)
- Cadvisor (8080)
- Promtail (9080)

### Authentication

- Change default Grafana password (admin/admin123)
- Configure SSL certificates for production
- Use VPN or private networks for internal communication
- Implement proper access controls

## 📊 Monitoring Your Applications

The monitoring stack automatically captures:

### 1. Container Metrics
- CPU and memory usage per container
- Network I/O and disk I/O
- Container status and restart counts
- Resource utilization trends

### 2. Application Logs
- All stdout/stderr logs from Docker containers
- Application-specific log files
- System logs and service logs
- Automatic log parsing and indexing

### 3. Business Metrics from Logs
The system automatically detects and tracks:
- Failed transactions (logs containing "failed", "error", "exception")
- Successful operations (logs containing "success", "completed")
- Warning messages (logs containing "warn", "warning")
- API errors and exceptions
- Database connection issues

### 4. Health Checks
- Container health status
- API endpoint availability
- Service uptime monitoring
- Automatic alerting on issues

## 🚨 Troubleshooting

### Common Issues

1. **Promtail not sending logs**:
   - Check Promtail service status: `systemctl status promtail`
   - Verify Loki server connectivity
   - Check log file permissions

2. **Prometheus targets down**:
   - Verify firewall rules
   - Check Node Exporter service status
   - Confirm network connectivity

3. **Alerts not firing**:
   - Check Alertmanager configuration
   - Verify Slack/email settings
   - Review alert rules syntax

4. **High resource usage**:
   - Monitor disk space for logs
   - Check Loki retention settings
   - Review Prometheus retention

### Useful Commands

```bash
# View all container logs
docker-compose logs -f

# Check specific service logs
docker-compose logs -f grafana

# Restart specific service
docker-compose restart prometheus

# Check service status
docker-compose ps

# View Prometheus targets
curl http://localhost:9090/api/v1/targets

# Test Loki connectivity
curl http://localhost:3100/ready

# Check Alertmanager configuration
curl http://localhost:9093/api/v1/status
```

## 📚 Additional Resources

- [Grafana Documentation](https://grafana.com/docs/)
- [Loki Documentation](https://grafana.com/docs/loki/latest/)
- [Prometheus Documentation](https://prometheus.io/docs/)
- [Alertmanager Documentation](https://prometheus.io/docs/alerting/latest/alertmanager/)

## 🤝 Support

For issues and questions:
1. Check the troubleshooting section
2. Review logs for error messages
3. Verify configuration files
4. Test connectivity between components

## 📄 License

This project is licensed under the MIT License - see the LICENSE file for details. 