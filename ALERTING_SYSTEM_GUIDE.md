# Docker Container Monitoring & Alerting System Guide

## Overview

This guide explains the comprehensive Docker container monitoring and alerting system configured for your infrastructure. The system monitors Docker containers across multiple servers and provides real-time alerts for container lifecycle events and log-based issues.

## System Components

### 1. Prometheus Alert Rules (`config/prometheus/rules/docker-alerts.yml`)

#### Container Lifecycle Alerts

**ContainerDown** - Critical
- **Trigger**: Container not seen in metrics for over 1 minute
- **Query**: `absent(container_cpu_usage_seconds_total{name=~".+"}) or (time() - container_last_seen) > 60`
- **Duration**: 1 minute
- **Description**: Container has not been seen for over 1m — it may have exited or crashed

**ContainerExited** - Critical
- **Trigger**: Container state is "exited"
- **Query**: `container_state{state="exited"} == 1`
- **Duration**: 30 seconds
- **Description**: Container has exited or stopped

**ContainerNotRunning** - Warning
- **Trigger**: Container is neither running nor exited (likely restarting)
- **Query**: `container_state{state="running"} == 0 and container_state{state="exited"} == 0`
- **Duration**: 2 minutes
- **Description**: Container is not running and not exited - likely restarting

**ContainerExitedWithError** - Critical
- **Trigger**: Container exited with non-zero exit code
- **Query**: `container_exit_code != 0`
- **Duration**: 1 minute
- **Description**: Container exited with non-zero exit code

**ContainerRestarting** - Warning
- **Trigger**: Container restarted more than 5 times in 15 minutes
- **Query**: `increase(container_start_time_seconds[15m]) > 5`
- **Duration**: 5 minutes
- **Description**: Container is restarting frequently

#### Resource Usage Alerts

**ContainerHighMemoryUsage** - Warning
- **Trigger**: Container using more than 85% of memory limit
- **Query**: `(container_memory_usage_bytes / container_spec_memory_limit_bytes * 100) > 85`
- **Duration**: 5 minutes

**ContainerHighCPUUsage** - Warning
- **Trigger**: Container using more than 80% CPU
- **Query**: `rate(container_cpu_usage_seconds_total[5m]) * 100 > 80`
- **Duration**: 5 minutes

**ContainerHighDiskIO** - Warning
- **Trigger**: Container has high disk I/O activity
- **Query**: `rate(container_fs_reads_total[5m]) + rate(container_fs_writes_total[5m]) > 1000`
- **Duration**: 5 minutes

### 2. Loki Log-Based Alerts (`config/prometheus/rules/log-alerts.yml`)

#### Log Error Detection

**ContainerLogCriticalHTTPErrors** - Critical
- **Trigger**: More than 5 HTTP errors (401, 403, 404, 500, 501, 502, 503) in 5 minutes
- **Keywords**: 401, 403, 404, 500, 501, 502, 503
- **Duration**: 2 minutes

**ContainerLogGeneralErrors** - Warning
- **Trigger**: More than 10 general errors in 5 minutes
- **Keywords**: error, ERROR, failed, FAILED, exception, EXCEPTION, timeout, TIMEOUT, connection refused, CONNECTION REFUSED
- **Duration**: 3 minutes

**ContainerLogAuthErrors** - Critical
- **Trigger**: More than 3 authentication errors in 5 minutes
- **Keywords**: 401, 403, unauthorized, UNAUTHORIZED, forbidden, FORBIDDEN, authentication failed, AUTHENTICATION FAILED
- **Duration**: 2 minutes

**ContainerLogServerErrors** - Critical
- **Trigger**: More than 3 server errors in 5 minutes
- **Keywords**: 500, 502, 503, 504, 505, internal server error, INTERNAL SERVER ERROR
- **Duration**: 2 minutes

**ContainerLogClientErrors** - Warning
- **Trigger**: More than 10 client errors in 5 minutes
- **Keywords**: All 4xx HTTP status codes
- **Duration**: 3 minutes

**ContainerLogHighErrorRate** - Critical
- **Trigger**: Error rate exceeds 20 errors per minute
- **Query**: `rate(log_general_errors_total[1m]) > 20`
- **Duration**: 1 minute

## Alert Format

All alerts follow this standardized format:

```
🔥 CRITICAL: ContainerDown
Status: FIRING
Alert: ContainerDown
Container: docker-container-name
Host: server-name
Application: docker-application
Description: Container has not been seen for over 1m — it may have exited or crashed
Logs: [View logs](https://grafana.example.com/explore?left=["now-5m","now","Loki",{"expr":"{container=\"container-name\"}"}])
```

## Alert Labels

Each alert includes these standardized labels:
- `severity`: critical or warning
- `team`: infrastructure
- `container`: container name
- `host`: hostname or instance
- `application`: Docker Compose service name or job label
- `description`: brief explanation of the issue
- `url`: direct link to logs in Grafana Loki

## Configuration Files

### 1. Prometheus Configuration (`config/prometheus/prometheus.yml`)
- Scrapes metrics from cAdvisor (container metrics)
- Scrapes metrics from Loki (log metrics)
- Loads alert rules from `rules/` directory

### 2. Loki Configuration (`config/loki/loki-config.yaml`)
- Enables ruler for generating metrics from logs
- Configures alertmanager integration
- Sets up recording rules for log-based metrics

### 3. Alertmanager Configuration (`config/alertmanager/alertmanager.yml`)
- Routes alerts to appropriate teams
- Formats alerts with standardized template
- Includes direct links to Grafana/Loki for log viewing

### 4. Loki Rules (`config/loki/rules/log-metrics.yaml`)
- Generates metrics from log data
- Enables Prometheus to alert on log patterns
- Provides aggregation by container, hostname, and job

## Deployment

1. **Update Configuration Files**:
   - All configuration files have been updated with proper alert rules
   - Loki rules directory is mounted in docker-compose.yml

2. **Restart Services**:
   ```bash
   docker-compose down
   docker-compose up -d
   ```

3. **Verify Configuration**:
   - Check Prometheus targets: http://localhost:9090/targets
   - Check Loki rules: http://localhost:3100/rules
   - Check Alertmanager: http://localhost:9093

## Testing Alerts

### Test Container Down Alert
```bash
# Stop a container
docker stop <container-name>

# Wait 1 minute for alert to fire
```

### Test Log Error Alert
```bash
# Generate error logs in a container
docker exec <container-name> sh -c "echo 'ERROR: Test error message' >> /var/log/app.log"
```

### Test Resource Usage Alert
```bash
# Generate high CPU usage
docker exec <container-name> sh -c "while true; do : ; done &"
```

## Troubleshooting

### Alerts Not Firing
1. Check Prometheus targets are up
2. Verify alert rules are loaded
3. Check query syntax in Prometheus UI
4. Ensure metrics are being collected

### Log Alerts Not Working
1. Verify Loki is receiving logs
2. Check Loki rules are loaded
3. Ensure Prometheus is scraping Loki metrics
4. Verify log format matches expected patterns

### Alert Format Issues
1. Check Alertmanager configuration
2. Verify template syntax
3. Test with simple alert first
4. Check Slack webhook configuration

## Customization

### Adding New Alert Rules
1. Add rule to appropriate file in `config/prometheus/rules/`
2. Follow existing naming conventions
3. Include all required labels
4. Test query in Prometheus UI first

### Modifying Alert Thresholds
1. Edit the `expr` field in alert rules
2. Adjust `for` duration as needed
3. Update severity levels appropriately
4. Test changes in staging first

### Adding New Log Patterns
1. Update Loki recording rules in `config/loki/rules/log-metrics.yaml`
2. Add corresponding Prometheus alert rule
3. Test with sample log data
4. Verify metrics are generated correctly

## Best Practices

1. **Use Descriptive Names**: Alert names should clearly indicate the issue
2. **Set Appropriate Severity**: Critical for service-impacting issues, Warning for potential problems
3. **Include Context**: Always include container, host, and application information
4. **Provide Actionable Information**: Description should explain what the alert means
5. **Test Alerts**: Regularly test alert conditions to ensure they work correctly
6. **Monitor Alert Volume**: Avoid alert fatigue by setting appropriate thresholds
7. **Document Changes**: Update this guide when modifying alert rules

## Support

For issues with the alerting system:
1. Check service logs: `docker-compose logs <service-name>`
2. Verify configuration syntax
3. Test individual components
4. Review Prometheus and Loki documentation
5. Check Alertmanager configuration guide 