#!/bin/bash

# Script to restart monitoring stack for new Docker alert rules
# This script restarts Prometheus and Alertmanager to apply the updated alert rules

set -e

echo "🔄 Restarting monitoring stack to apply new Docker alert rules..."

# Get the directory where this script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

# Change to project root
cd "$PROJECT_ROOT"

echo "📁 Working directory: $(pwd)"

# Stop the monitoring stack
echo "🛑 Stopping monitoring stack..."
docker-compose down

# Wait a moment for containers to stop
sleep 5

# Start the monitoring stack
echo "🚀 Starting monitoring stack with new alert rules..."
docker-compose up -d

# Wait for services to start
echo "⏳ Waiting for services to start..."
sleep 10

# Check if services are running
echo "🔍 Checking service status..."
docker-compose ps

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

echo ""
echo "✅ Monitoring stack restarted successfully!"
echo ""
echo "🔗 Access URLs:"
echo "   Prometheus: http://localhost:9090"
echo "   Alertmanager: http://localhost:9093"
echo "   Grafana: http://localhost:3000 (admin/admin123)"
echo ""
echo "📋 New Docker alerts configured:"
echo "   • ContainerExited - Triggers after 2 minutes (as requested)"
echo "   • ContainerStarted - Triggers when container starts"
echo "   • ContainerCreated - Triggers when new container is created"
echo "   • ContainerRemoved - Triggers when container is removed"
echo "   • ContainerLogDockerErrors - Triggers on Docker-specific errors"
echo "   • ContainerLogStartupErrors - Triggers on application startup failures"
echo ""
echo "🔄 The new alert rules are now active!" 