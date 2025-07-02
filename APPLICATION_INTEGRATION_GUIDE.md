# Application Integration Guide

This guide shows you how to add monitoring to your Docker applications to track:
- Container failures and restarts
- Failed transactions
- Error logs
- Application health

## 🐳 What You Need to Add to Your Docker Apps

### 1. **Docker Log Monitoring (No Code Changes)**

Your existing Java and React applications already write logs to stdout/stderr. The monitoring stack will automatically capture and analyze these logs for:

- **Failed transactions** - Any log containing "failed"
- **Successful operations** - Any log containing "success" or "completed"  
- **Error messages** - Any log containing "error" or "errored"
- **Java exceptions** - Any log containing "Exception" or "ERROR"
- **Warning messages** - Any log containing "WARN"

**No code changes needed!** Just deploy the monitoring stack and it will capture all your Docker logs automatically.

### 2. **Docker Log Analysis (Automatic)**

The monitoring stack automatically analyzes your existing Docker logs for:

**Java Application Logs:**
```
2024-01-15 10:30:15 INFO  - Transaction completed successfully
2024-01-15 10:30:16 ERROR - Transaction failed: Insufficient funds
2024-01-15 10:30:17 WARN  - Database connection timeout
2024-01-15 10:30:18 ERROR - java.lang.Exception: Connection refused
```

**React Application Logs:**
```
2024-01-15 10:30:15 [INFO] API call completed successfully
2024-01-15 10:30:16 [ERROR] API call failed: Network error
2024-01-15 10:30:17 [WARN] Component rendering slow
2024-01-15 10:30:18 [ERROR] User authentication failed
```

**No changes needed to your existing logging!** The monitoring stack will automatically detect and categorize these patterns.

### 3. **Container Health Monitoring (Automatic)**

The monitoring stack automatically tracks container health through:

- **Container status** (running/stopped/restarting)
- **Container restart count** 
- **Container exit codes**
- **Resource usage** (CPU, memory, disk)
- **Container logs** (all stdout/stderr)

**No health check endpoints needed!** Docker container health is monitored automatically.

## 🐳 Docker Compose Configuration (Optional)

Your existing Docker Compose files will work as-is. If you want better log categorization, you can optionally add labels:

```yaml
version: '3.8'
services:
  remittance-app:
    image: your-remittance-app:latest
    container_name: remittance-app
    labels:
      - "logging.jobname=remittance"
      - "logging.app=remittance"
    restart: unless-stopped

  collection-app:
    image: your-collection-app:latest
    container_name: collection-app
    labels:
      - "logging.jobname=collection"
      - "logging.app=collection"
    restart: unless-stopped

  agency-app:
    image: your-agency-app:latest
    container_name: agency-app
    labels:
      - "logging.jobname=agency"
      - "logging.app=agency"
    restart: unless-stopped
```

**Labels are optional!** The monitoring stack will work with your existing containers without any changes.

## 📊 What Gets Monitored Automatically

### Container Health (No Code Changes Needed)
- ✅ Container status (running/stopped/restarting)
- ✅ Container restart count
- ✅ Container exit codes
- ✅ Container resource usage (CPU, memory)
- ✅ Container logs (stdout/stderr)

### Business Metrics (Automatic from Logs)
- ✅ Failed transactions (detected from logs)
- ✅ API error rates (detected from logs)
- ✅ Database connection failures (detected from logs)
- ✅ Application-specific errors (detected from logs)

## 🔧 Quick Integration Steps

**Note: All steps below are optional. The monitoring stack works automatically with your existing Docker containers.**

### Step 1: Add Metrics Endpoint (Optional)
Add `/metrics` endpoint to your applications for custom metrics

### Step 2: Add Health Check (Optional)
Add `/health` endpoint to your applications for health checks

### Step 3: Update Docker Compose (Optional)
Add labels and health checks to your containers for better categorization

### Step 4: Update Prometheus Config (Optional)
Add your application metrics endpoints:

```yaml
# In config/prometheus/prometheus.yml
- job_name: 'docker-applications'
  static_configs:
    - targets:
      - 'app-server-1:8080'  # Remittance app
      - 'app-server-1:8081'  # Collection app
      - 'app-server-1:8082'  # Agency app
  metrics_path: /metrics
  scrape_interval: 30s
```

## 📈 What You'll See in Grafana

### Container Health Dashboard
- Container status overview
- Restart count per container
- Exit codes table
- Resource usage graphs

### Business Metrics Dashboard
- Failed transactions by service
- Success rate gauges
- API error rates
- Database connection failures

### Logs Dashboard
- Error logs from containers
- Failed transaction logs
- Application-specific errors

## 🚨 Alerts You'll Get

### Container Alerts
- Container down/stopped
- Container restarting frequently
- Container exited with error
- High resource usage

### Business Alerts
- High transaction failure rate
- API error rate > 10%
- Database connection failures
- Application health check failed

## ✅ Checklist

**Automatic Monitoring (No Changes Required):**
- [x] Container logs captured automatically
- [x] Container health monitored automatically
- [x] System metrics collected automatically
- [x] Log analysis performed automatically

**Optional Enhancements:**
- [ ] Add `/metrics` endpoint to applications (for custom metrics)
- [ ] Add `/health` endpoint to applications (for health checks)
- [ ] Add structured logging (for better log parsing)
- [ ] Update Docker Compose with labels (for better categorization)
- [ ] Add health checks to containers (for better health monitoring)
- [ ] Update Prometheus config with app endpoints (for custom metrics)

**Testing:**
- [ ] Test metrics endpoint: `curl http://your-app:8080/metrics` (if added)
- [ ] Test health endpoint: `curl http://your-app:8080/health` (if added)

That's it! The monitoring stack works automatically with your existing Docker containers. Optional enhancements can be added later for more detailed monitoring. 