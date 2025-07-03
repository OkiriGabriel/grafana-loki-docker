#!/bin/bash

# Fix Hostname in Monitoring Stack
# This script sets the HOSTNAME environment variable and restarts the monitoring stack
# to ensure alerts show the correct hostname instead of "cadvisor:8080"

echo "🔧 Fixing hostname in monitoring stack..."

# Get the current hostname
CURRENT_HOSTNAME=$(hostname)
echo "Current hostname: $CURRENT_HOSTNAME"

# Export HOSTNAME environment variable
export HOSTNAME=$CURRENT_HOSTNAME
echo "Set HOSTNAME environment variable to: $HOSTNAME"

# Restart the monitoring stack with the correct hostname
echo "🔄 Restarting monitoring stack..."
docker-compose down
docker-compose up -d

# Wait for services to start
echo "⏳ Waiting for services to start..."
sleep 10

# Reload Prometheus configuration
echo "🔄 Reloading Prometheus configuration..."
curl -X POST http://localhost:9090/-/reload

echo "✅ Hostname fix completed!"
echo "📊 Check your alerts now - they should show '$CURRENT_HOSTNAME' instead of 'cadvisor:8080'"
echo ""
echo "🔗 Access your monitoring stack:"
echo "   - Grafana: http://localhost:3000 (admin/admin123)"
echo "   - Prometheus: http://localhost:9090"
echo "   - Alertmanager: http://localhost:9093" 