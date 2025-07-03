#!/bin/bash

# Restart Monitoring Stack with Fixed cAdvisor
# This script restarts the monitoring stack with the corrected cAdvisor configuration

echo "🔄 Restarting monitoring stack with fixed cAdvisor configuration..."

# Stop the current monitoring stack
echo "⏹️ Stopping current monitoring stack..."
docker-compose down

# Remove the problematic docker-exporter container if it exists
echo "🗑️ Removing docker-exporter container..."
docker rm -f docker-exporter 2>/dev/null || true

# Start the monitoring stack with cAdvisor
echo "🚀 Starting monitoring stack with cAdvisor..."
docker-compose up -d

# Wait for services to start
echo "⏳ Waiting for services to start..."
sleep 15

# Check if cAdvisor is running
echo "🔍 Checking cAdvisor status..."
if curl -s http://localhost:8080/metrics > /dev/null; then
    echo "✅ cAdvisor is running and accessible"
else
    echo "❌ cAdvisor is not accessible. Check logs:"
    docker logs cadvisor
    exit 1
fi

# Reload Prometheus configuration
echo "🔄 Reloading Prometheus configuration..."
curl -X POST http://localhost:9090/-/reload

# Check Prometheus targets
echo "📊 Checking Prometheus targets..."
sleep 5
curl -s http://localhost:9090/api/v1/targets | jq '.data.activeTargets[] | select(.labels.job == "cadvisor") | {job: .labels.job, instance: .labels.instance, health: .health}'

echo ""
echo "✅ Monitoring stack restarted successfully!"
echo ""
echo "🔗 Access your monitoring stack:"
echo "   - Grafana: http://localhost:3000 (admin/admin123)"
echo "   - Prometheus: http://localhost:9090"
echo "   - Alertmanager: http://localhost:9093"
echo "   - cAdvisor: http://localhost:8080"
echo ""
echo "📊 Your alerts should now show correct hostnames instead of 'cadvisor:8080'" 