#!/bin/bash

# Script to switch from systemctl Promtail to Docker Compose Promtail
# This script stops the systemctl service and starts the Docker version

set -e

echo "🔄 Switching from systemctl Promtail to Docker Compose Promtail..."

# Get the directory where this script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

# Change to project root
cd "$PROJECT_ROOT"

echo "📁 Working directory: $(pwd)"

# Stop and disable systemctl Promtail
echo "🛑 Stopping systemctl Promtail service..."
sudo systemctl stop promtail
sudo systemctl disable promtail

echo "✅ Systemctl Promtail service stopped and disabled"

# Stop the current monitoring stack
echo "🛑 Stopping current monitoring stack..."
docker-compose down

# Wait a moment for containers to stop
sleep 5

# Start the monitoring stack with Docker Compose Promtail
echo "🚀 Starting monitoring stack with Docker Compose Promtail..."
docker-compose up -d

# Wait for services to start
echo "⏳ Waiting for services to start..."
sleep 15

# Check if services are running
echo "🔍 Checking service status..."
docker-compose ps

# Check Promtail targets
echo "📊 Checking Promtail targets..."
sleep 5
curl -s http://localhost:9080/targets | jq '.data.targets[] | {job: .labels.job, instance: .labels.instance, health: .health}' 2>/dev/null || echo "⚠️ Could not check Promtail targets (jq not available or Promtail not ready)"

# Check Prometheus targets
echo "📊 Checking Prometheus targets..."
sleep 5
curl -s http://localhost:9090/api/v1/targets | jq '.data.activeTargets[] | {job: .labels.job, instance: .labels.instance, health: .health}' 2>/dev/null || echo "⚠️ Could not check Prometheus targets (jq not available or Prometheus not ready)"

# Check Alertmanager
echo "🚨 Checking Alertmanager status..."
curl -s http://localhost:9093/api/v1/status | jq '.data.configYAML' 2>/dev/null || echo "⚠️ Could not check Alertmanager status (jq not available or Alertmanager not ready)"

# Check Grafana
echo "📈 Checking Grafana status..."
curl -s http://localhost:3000/api/health | jq '.' 2>/dev/null || echo "⚠️ Could not check Grafana status (jq not available or Grafana not ready)"

# Check Loki
echo "📝 Checking Loki status..."
curl -s http://localhost:3100/ready | jq '.' 2>/dev/null || echo "⚠️ Could not check Loki status (jq not available or Loki not ready)"

echo ""
echo "✅ Successfully switched to Docker Compose Promtail!"
echo ""
echo "🔗 Access URLs:"
echo "   Prometheus: http://localhost:9090"
echo "   Alertmanager: http://localhost:9093"
echo "   Grafana: http://localhost:3000 (admin/admin123)"
echo "   Promtail: http://localhost:9080"
echo "   Loki: http://localhost:3100"
echo ""
echo "📋 What's now configured:"
echo "   • Docker Compose Promtail is collecting logs from ALL Docker containers"
echo "   • Container lifecycle alerts (exited after 2m, created, started, removed)"
echo "   • Docker-specific error detection in logs"
echo "   • Application startup error detection"
echo ""
echo "🧪 Test the setup:"
echo "   1. Create a new container: docker run -d --name test-container nginx"
echo "   2. Check logs in Grafana: http://localhost:3000/explore"
echo "   3. Query: {container=\"test-container\"}"
echo "   4. Stop the container: docker stop test-container"
echo "   5. Check alerts in Alertmanager: http://localhost:9093"
echo ""
echo "🔄 Docker Compose Promtail is now monitoring all Docker containers!" 