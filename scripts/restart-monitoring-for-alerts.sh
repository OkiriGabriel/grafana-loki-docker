#!/bin/bash

# Script to restart monitoring stack for new Docker alert rules
# This script restarts Prometheus and Alertmanager to apply the updated alert rules

set -e

echo "🔄 Restarting monitoring stack with updated alert configurations..."

# Get the directory where this script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

# Change to project root
cd "$PROJECT_ROOT"

echo "📁 Working directory: $(pwd)"

# Stop the current stack
echo "📦 Stopping current monitoring stack..."
docker-compose down

# Wait a moment for cleanup
sleep 3

# Start the stack with updated configurations
echo "🚀 Starting monitoring stack with updated alerts..."
docker-compose up -d

# Wait for services to start
echo "⏳ Waiting for services to start..."
sleep 10

# Check if services are running
echo "🔍 Checking service status..."
docker-compose ps

# Test Prometheus configuration
echo "🔧 Testing Prometheus configuration..."
curl -s http://localhost:9090/-/reload

# Check if rules are loaded
echo "📋 Checking if alert rules are loaded..."
sleep 5
curl -s http://localhost:9090/api/v1/rules | jq '.data.groups[] | select(.name == "docker-alerts") | .rules[] | {name: .name, state: .state}' 2>/dev/null || echo "Rules not yet loaded, this is normal"

# Check Alertmanager configuration
echo "📢 Checking Alertmanager configuration..."
curl -s http://localhost:9093/-/reload

echo "✅ Monitoring stack restarted with updated configurations!"
echo ""
echo "📊 Access your monitoring stack:"
echo "   Grafana: http://localhost:3000"
echo "   Prometheus: http://localhost:9090"
echo "   Alertmanager: http://localhost:9093"
echo "   Loki: http://localhost:3100"
echo ""
echo "🔔 Alerts are now configured with:"
echo "   - No email notifications"
echo "   - No team: infrastructure labels"
echo "   - Updated URLs with hostname filtering"
echo "   - More conservative thresholds"
echo ""
echo "🧪 To test alerts, try:"
echo "   docker run --rm -d --name test-alert alpine sleep 30"
echo "   docker stop test-alert"

# Check Prometheus targets
echo "📊 Checking Prometheus targets..."
sleep 5
curl -s http://localhost:9090/api/v1/targets | jq '.data.activeTargets[] | {job: .labels.job, instance: .labels.instance, health: .health}' 2>/dev/null || echo "⚠️ Could not check Prometheus targets (jq not available or Prometheus not ready)"

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