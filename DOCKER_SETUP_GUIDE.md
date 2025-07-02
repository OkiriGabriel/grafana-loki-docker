# Docker-Based Monitoring Setup Guide

This guide explains how to deploy and configure the Grafana Loki monitoring stack for **Docker containers** running on EC2 instances and DigitalOcean droplets.

## 🐳 Architecture Overview

```
┌─────────────────────────────────────────────────────────────┐
│                    Monitoring Server (EC2)                  │
│  ┌─────────────┐ ┌─────────────┐ ┌─────────────┐           │
│  │   Grafana   │ │    Loki     │ │ Prometheus  │           │
│  │   (Docker)  │ │   (Docker)  │ │  (Docker)   │           │
│  └─────────────┘ └─────────────┘ └─────────────┘           │
│  ┌─────────────┐ ┌─────────────┐ ┌─────────────┐           │
│  │Alertmanager │ │Blackbox Exp │ │Node Exporter│           │
│  │  (Docker)   │ │  (Docker)   │ │  (Docker)   │           │
│  └─────────────┘ └─────────────┘ └─────────────┘           │
└─────────────────────────────────────────────────────────────┘
                              │
                              │ Promtail collects logs
                              │ Node Exporter collects metrics
                              ▼
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   EC2 Instance  │    │ DigitalOcean    │    │   EC2 Instance  │
│   (App Server)  │    │   Droplet       │    │   (App Server)  │
│                 │    │   (App Server)  │    │                 │
│ ┌─────────────┐ │    │ ┌─────────────┐ │    │ ┌─────────────┐ │
│ │Your App     │ │    │ │Your App     │ │    │ │Your App     │ │
│ │(Docker)     │ │    │ │(Docker)     │ │    │ │(Docker)     │ │
│ └─────────────┘ │    │ └─────────────┘ │    │ └─────────────┘ │
│ ┌─────────────┐ │    │ ┌─────────────┐ │    │ ┌─────────────┐ │
│ │ Promtail    │ │    │ │ Promtail    │ │    │ │ Promtail    │ │
│ │(Systemd)    │ │    │ │(Systemd)    │ │    │ │(Systemd)    │ │
│ └─────────────┘ │    │ └─────────────┘ │    │ └─────────────┘ │
│ ┌─────────────┐ │    │ ┌─────────────┐ │    │ ┌─────────────┐ │
│ │Node Exporter│ │    │ │Node Exporter│ │    │ │Node Exporter│ │
│ │(Systemd)    │ │    │ │(Systemd)    │ │    │ │(Systemd)    │ │
│ └─────────────┘ │    │ └─────────────┘ │    │ └─────────────┘ │
└─────────────────┘    └─────────────────┘    └─────────────────┘
```

## 🔧 How It Works with Docker

### 1. **Monitoring Stack (Docker Compose)**
The monitoring stack runs as Docker containers on a dedicated EC2 instance:

```yaml
# docker-compose.yml
services:
  grafana:      # Web UI for dashboards
  loki:         # Log aggregation
  prometheus:   # Metrics collection
  alertmanager: # Alert routing
  blackbox-exporter: # API monitoring
  node-exporter:     # System metrics
  cadvisor:          # Container metrics
```

### 2. **Application Servers (Docker + Systemd)**
On each application server (EC2/DigitalOcean), you have:
- **Your Docker applications** (Remittance, Collection, Agency Banking)
- **Promtail** (systemd service) - collects logs from Docker containers
- **Node Exporter** (systemd service) - collects system metrics

## 📋 Docker-Specific Configuration

### Docker Container Log Collection

Promtail automatically discovers and collects logs from all Docker containers:

```yaml
# config/promtail/promtail-config.yml
scrape_configs:
  - job_name: docker
    docker_sd_configs:
      - host: unix:///var/run/docker.sock  # Docker socket
        refresh_interval: 5s
        filters:
          - name: name
            values: ['.*']  # All containers
    relabel_configs:
      # Extract container metadata
      - source_labels: ['__meta_docker_container_name']
        regex: '/(.*)'
        target_label: 'container'
      - source_labels: ['__meta_docker_container_label_com_docker_compose_service']
        target_label: 'service'
      - source_labels: ['__meta_docker_container_label_com_docker_compose_project']
        target_label: 'project'
```

### Docker Container Metrics

Cadvisor collects detailed metrics from all Docker containers:

```yaml
# docker-compose.yml
cadvisor:
  image: gcr.io/cadvisor/cadvisor:latest
  privileged: true
  volumes:
    - /:/rootfs:ro
    - /var/run:/var/run:ro
    - /sys:/sys:ro
    - /var/lib/docker/:/var/lib/docker:ro  # Docker data
```

## 🚀 Deployment Steps for Docker Applications

### Step 1: Deploy Monitoring Stack
```bash
# On monitoring server (EC2)
git clone <your-repo>
cd grafana-loki
./scripts/deploy-monitoring-stack.sh
```

### Step 2: Configure Your Docker Applications
Ensure your Docker applications write logs to stdout/stderr or mounted volumes:

```yaml
# Example: Your application docker-compose.yml
version: '3.8'
services:
  remittance-app:
    image: your-remittance-app:latest
    container_name: remittance-app
    labels:
      - "logging.jobname=remittance"
      - "logging.level=info"
      - "logging.app=remittance"
    volumes:
      - ./logs:/app/logs
    environment:
      - LOG_LEVEL=info
    restart: unless-stopped

  collection-app:
    image: your-collection-app:latest
    container_name: collection-app
    labels:
      - "logging.jobname=collection"
      - "logging.level=info"
      - "logging.app=collection"
    volumes:
      - ./logs:/app/logs
    environment:
      - LOG_LEVEL=info
    restart: unless-stopped

  agency-app:
    image: your-agency-app:latest
    container_name: agency-app
    labels:
      - "logging.jobname=agency"
      - "logging.level=info"
      - "logging.app=agency"
    volumes:
      - ./logs:/app/logs
    environment:
      - LOG_LEVEL=info
    restart: unless-stopped
```

### Step 3: Install Promtail on Application Servers
```bash
# On each application server
./scripts/install-promtail.sh
```

Promtail will automatically:
- Discover all Docker containers
- Collect logs from stdout/stderr
- Collect logs from mounted volumes
- Send logs to Loki

## 📊 Docker-Specific Monitoring

### Container Metrics Available
- **CPU usage** per container
- **Memory usage** per container
- **Network I/O** per container
- **Disk I/O** per container
- **Container status** (running/stopped)
- **Container restart count**

### Log Collection from Docker
- **Container logs** (stdout/stderr)
- **Application logs** (mounted volumes)
- **Docker daemon logs**
- **System logs**

### Docker-Specific Queries

#### In Grafana Loki:
```logql
# All logs from remittance container
{container="remittance-app"}

# Error logs from all containers
{job="docker"} |= "error"

# Logs from specific Docker Compose project
{project="your-project-name"}

# Container logs by service
{service="remittance"}
```

#### In Grafana Prometheus:
```promql
# Container CPU usage
container_cpu_usage_seconds_total{container="remittance-app"}

# Container memory usage
container_memory_usage_bytes{container="remittance-app"}

# Container restart count
container_start_time_seconds{container="remittance-app"}

# All running containers
count(container_cpu_usage_seconds_total)
```

## 🔧 Docker Application Integration

### 1. Automatic Container Monitoring
The monitoring stack automatically captures:

- **Container metrics** - CPU, memory, network, disk usage
- **Container logs** - All stdout/stderr from your containers
- **Container health** - Status, restart counts, exit codes
- **Application logs** - Logs from mounted volumes and files

### 2. Automatic Log Analysis
The system automatically detects and tracks:

- **Failed transactions** - Logs containing "failed", "error", "exception"
- **Successful operations** - Logs containing "success", "completed"
- **Warning messages** - Logs containing "warn", "warning"
- **API errors** - Logs containing "API error", "HTTP 5xx"
- **Database issues** - Logs containing "database", "connection failed"

### 3. No Code Changes Required
Your existing Java and React Docker containers will be monitored automatically:

- Promtail discovers all containers via Docker socket
- Logs are collected from stdout/stderr and mounted volumes
- Metrics are collected by Cadvisor from container runtime
- Business events are extracted from log patterns

## 🐳 Docker Best Practices

### 1. **Logging Best Practices**
```yaml
# In your docker-compose.yml
services:
  your-app:
    image: your-app:latest
    logging:
      driver: "json-file"
      options:
        max-size: "10m"
        max-file: "3"
    labels:
      - "logging.jobname=your-app"
      - "logging.level=info"
```

### 2. **Health Checks**
```yaml
# In your docker-compose.yml
services:
  your-app:
    image: your-app:latest
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:8080/health"]
      interval: 30s
      timeout: 10s
      retries: 3
```

### 3. **Resource Limits**
```yaml
# In your docker-compose.yml
services:
  your-app:
    image: your-app:latest
    deploy:
      resources:
        limits:
          cpus: '1.0'
          memory: 1G
        reservations:
          cpus: '0.5'
          memory: 512M
```

## 🔍 Docker-Specific Troubleshooting

### Check Container Logs
```bash
# View container logs
docker logs your-app-container

# Follow logs in real-time
docker logs -f your-app-container

# Check Promtail logs
journalctl -u promtail -f
```

### Check Container Metrics
```bash
# View container stats
docker stats

# Check Cadvisor metrics
curl http://localhost:8080/metrics | grep container
```

### Verify Log Collection
```bash
# Check if Promtail sees containers
curl http://localhost:9080/targets

# Test Loki connectivity
curl http://your-loki-server:3100/ready
```

## 📈 Docker Dashboard Examples

### Container Overview Dashboard
- Container status (running/stopped)
- Resource usage per container
- Container restart history
- Network usage per container

### Application Logs Dashboard
- Log volume by container
- Error rate by container
- Recent logs with container labels
- Log level distribution

### Business Metrics Dashboard
- Transaction volume by container
- API response times by container
- Error rates by container
- Business metrics correlation

## ✅ Docker Deployment Checklist

- [ ] Monitoring stack deployed with Docker Compose
- [ ] Promtail installed on all application servers
- [ ] Docker containers configured with proper labels
- [ ] Application logs going to stdout/stderr or volumes
- [ ] Prometheus metrics exposed on `/metrics` endpoint
- [ ] Container health checks configured
- [ ] Resource limits set for containers
- [ ] Log rotation configured
- [ ] All containers visible in Grafana
- [ ] Alerts configured for container metrics

This setup provides comprehensive monitoring for your Docker-based applications without requiring Kubernetes! 