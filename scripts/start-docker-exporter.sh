#!/bin/bash

# Start Monitoring Stack with Docker Exporter
# This script starts the monitoring stack with Docker Exporter for container monitoring

echo "🚀 Starting monitoring stack with Docker Exporter..."

# Stop any existing containers
echo "⏹️ Stopping existing containers..."
docker-compose down

# Start the monitoring stack with Docker Exporter
echo "🚀 Starting monitoring stack..."
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
    echo ""
    echo "🔄 Trying to restart Docker Exporter..."
    docker-compose restart docker-exporter
    sleep 10
    if curl -s http://localhost:9323/metrics > /dev/null; then
        echo "✅ Docker Exporter is now accessible"
    else
        echo "❌ Docker Exporter still not accessible. Check logs:"
        docker logs docker-exporter
        exit 1
    fi
fi

# Reload Prometheus configuration
echo "🔄 Reloading Prometheus configuration..."
curl -X POST http://localhost:9090/-/reload

# Check Prometheus targets
echo "📊 Checking Prometheus targets..."
sleep 5
curl -s http://localhost:9090/api/v1/targets | jq '.data.activeTargets[] | select(.labels.job == "docker-exporter") | {job: .labels.job, instance: .labels.instance, health: .health}'

echo ""
echo "✅ Monitoring stack started successfully!"
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
echo "   1. Test your alerts with the new Docker Exporter metrics"
echo "   2. Update your Grafana dashboards to use Docker Exporter metrics"
echo "   3. Verify that alerts show correct hostnames" 