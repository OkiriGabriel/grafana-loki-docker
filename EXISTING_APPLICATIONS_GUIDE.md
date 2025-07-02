# Monitoring Existing Java & React Applications

This guide shows how to monitor your existing Java and React Docker applications **without any code changes**. The monitoring stack will automatically capture and analyze your Docker logs.

## 🐳 What Gets Captured Automatically

### **Docker Logs Analysis**
Your existing applications already write logs to stdout/stderr. Promtail will automatically capture these logs and send them to Loki for analysis.

### **Log Patterns Detected**
The monitoring stack will automatically detect these patterns in your logs:
- `failed` - Failed transactions/operations
- `success` - Successful operations
- `completed` - Completed processes
- `error` / `errored` - Error messages
- `Exception` - Java exceptions
- `ERROR` - Error level logs
- `WARN` - Warning level logs

## 📋 Java Application Logs

### **Typical Java Log Patterns**
```
2024-01-15 10:30:15 INFO  - Transaction completed successfully
2024-01-15 10:30:16 ERROR - Transaction failed: Insufficient funds
2024-01-15 10:30:17 WARN  - Database connection timeout
2024-01-15 10:30:18 ERROR - java.lang.Exception: Connection refused
```

### **What Gets Monitored**
- ✅ **Failed transactions** - Any log containing "failed"
- ✅ **Successful operations** - Any log containing "success" or "completed"
- ✅ **Java exceptions** - Any log containing "Exception" or "ERROR"
- ✅ **Warning messages** - Any log containing "WARN"
- ✅ **Application errors** - Any log containing "error" or "errored"

## ⚛️ React Application Logs

### **Typical React Log Patterns**
```
2024-01-15 10:30:15 [INFO] API call completed successfully
2024-01-15 10:30:16 [ERROR] API call failed: Network error
2024-01-15 10:30:17 [WARN] Component rendering slow
2024-01-15 10:30:18 [ERROR] User authentication failed
```

### **What Gets Monitored**
- ✅ **Failed API calls** - Any log containing "failed"
- ✅ **Successful operations** - Any log containing "success" or "completed"
- ✅ **React errors** - Any log containing "error" or "ERROR"
- ✅ **Warning messages** - Any log containing "WARN"

## 🚀 Setup for Existing Applications

### **Step 1: Deploy Monitoring Stack**
```bash
# On your monitoring server
./scripts/deploy-monitoring-stack.sh
```

### **Step 2: Install Promtail on Application Servers**
```bash
# On each server running your Java/React containers
./scripts/install-promtail.sh
```

**Promtail will automatically:**
- Discover all your Docker containers
- Capture all stdout/stderr logs
- Send logs to Loki for analysis
- No configuration needed for your apps!

### **Step 3: View Your Logs in Grafana**

Access Grafana at `http://your-monitoring-server:3000` and use these queries:

#### **Find Failed Transactions**
```logql
{job="docker"} |= "failed"
```

#### **Find Successful Operations**
```logql
{job="docker"} |= "success"
```

#### **Find Completed Processes**
```logql
{job="docker"} |= "completed"
```

#### **Find Error Messages**
```logql
{job="docker"} |= "error"
```

#### **Find Java Exceptions**
```logql
{job="docker"} |= "Exception"
```

#### **Find by Container Name**
```logql
{container="your-java-app"} |= "failed"
```

#### **Find by Service**
```logql
{service="remittance"} |= "error"
```

## 📊 Pre-configured Dashboards

### **Docker Container Health Dashboard**
- Container status overview
- Restart count per container
- Exit codes table
- Resource usage graphs
- **Container log errors** - Shows all error logs from your containers

### **Logs Explorer Dashboard**
- Log volume by service
- Error rate by container
- Recent logs with container labels
- Log level distribution
- **Failed transaction logs** - Shows all failed operations

## 🔍 Log Analysis Examples

### **Find All Failed Transactions**
```logql
{job="docker"} |= "failed" | json
```

### **Find Java Exceptions**
```logql
{job="docker"} |= "Exception" | json
```

### **Find React Errors**
```logql
{container=~".*react.*"} |= "error" | json
```

### **Find by Time Range**
```logql
{job="docker"} |= "failed" | json | timestamp > "2024-01-15T10:00:00Z"
```

### **Find by Container**
```logql
{container="remittance-app"} |= "failed" | json
```

## 🚨 Automatic Alerts

The monitoring stack will automatically alert you when:

### **Container Health Issues**
- Container stopped/restarted
- Container exited with error
- Container restarting frequently

### **Log-based Alerts**
- High volume of error logs
- High volume of failed transactions
- Application exceptions detected

## 📈 What You'll See

### **Real-time Log Monitoring**
- All your Java and React application logs
- Failed transaction detection
- Error pattern analysis
- Success/completion tracking

### **Container Health**
- Which containers are running/stopped
- How many times containers restart
- Resource usage per container
- Container exit codes

### **Business Insights**
- Transaction success/failure rates
- Error patterns by service
- Performance issues
- Application health status

## ✅ No Code Changes Required

Your existing applications will work exactly as they are:

- ✅ **Java applications** - Continue logging to stdout/stderr
- ✅ **React applications** - Continue logging to console
- ✅ **Docker containers** - No changes to Dockerfiles
- ✅ **Docker Compose** - No changes to compose files
- ✅ **Application code** - No new endpoints or metrics needed

## 🔧 Quick Verification

### **Check if Logs are Being Captured**
```bash
# Check Promtail status
systemctl status promtail

# Check if containers are discovered
curl http://localhost:9080/targets

# Check Loki connectivity
curl http://your-loki-server:3100/ready
```

### **Test Log Queries in Grafana**
1. Go to Grafana → Explore
2. Select Loki as data source
3. Try these queries:
   - `{job="docker"}` - All container logs
   - `{job="docker"} |= "failed"` - Failed operations
   - `{job="docker"} |= "error"` - Error messages

## 📋 Your Applications

### **Java Applications**
- Spring Boot apps
- Microservices
- API services
- Background jobs

### **React Applications**
- Frontend apps
- Admin panels
- User interfaces
- API clients

All logs from these applications will be automatically captured and analyzed for:
- **Failed transactions**
- **Successful operations**
- **Error messages**
- **Application exceptions**
- **Warning messages**

## 🎯 Summary

**What you get without any code changes:**
1. **Automatic log capture** from all Docker containers
2. **Real-time log analysis** for failed/success/completed/errored events
3. **Container health monitoring** (restarts, failures, resource usage)
4. **Pre-configured dashboards** showing your application health
5. **Automatic alerts** for issues
6. **Log search and filtering** by container, service, or pattern

**Just deploy the monitoring stack and install Promtail - everything else is automatic!** 🚀 