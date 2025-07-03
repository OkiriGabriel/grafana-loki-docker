#!/bin/bash

# Migrate from cAdvisor to Docker Exporter
# This script helps you switch from cAdvisor to Docker Exporter for container monitoring

echo "🔄 Migrating from cAdvisor to Docker Exporter..."

# Stop the current monitoring stack
echo "⏹️ Stopping current monitoring stack..."
docker-compose down

# Remove cAdvisor container if it exists
echo "🗑️ Removing cAdvisor container..."
docker rm -f cadvisor 2>/dev/null || true

# Start the monitoring stack with Docker Exporter
echo "🚀 Starting monitoring stack with Docker Exporter..."
docker-compose up -d

# Wait for services to start
echo "⏳ Waiting for services to start..."
sleep 15

# Check if Docker Exporter is running
echo "🔍 Checking Docker Exporter status..."
if curl -s http://localhost:9323/metrics > /dev/null; then
    echo "✅ Docker Exporter is running and accessible"
else
    echo "❌ Docker Exporter is not accessible. Check logs:"
    docker logs docker-exporter
    exit 1
fi

# Reload Prometheus configuration
echo "🔄 Reloading Prometheus configuration..."
curl -X POST http://localhost:9090/-/reload

# Check Prometheus targets
echo "📊 Checking Prometheus targets..."
sleep 5
curl -s http://localhost:9090/api/v1/targets | jq '.data.activeTargets[] | select(.labels.job == "docker-exporter") | {job: .labels.job, instance: .labels.instance, health: .health}'

echo ""
echo "✅ Migration completed!"
echo ""
echo "📊 Docker Exporter Metrics Available:"
echo "   - Container info: docker_container_info"
echo "   - Container state: docker_container_state"
echo "   - Container memory: docker_container_memory_usage_bytes"
echo "   - Container CPU: docker_container_cpu_usage_seconds_total"
echo "   - Container network: docker_container_network_receive_bytes_total"
echo ""
echo "🔗 Access your monitoring stack:"
echo "   - Grafana: http://localhost:3000 (admin/admin123)"
echo "   - Prometheus: http://localhost:9090"
echo "   - Alertmanager: http://localhost:9093"
echo "   - Docker Exporter: http://localhost:9323/metrics"
echo ""
echo "📝 Next steps:"
echo "   1. Update your Grafana dashboards to use Docker Exporter metrics"
echo "   2. Test your alerts with the new metric names"
echo "   3. Remove any cAdvisor-specific configurations" 