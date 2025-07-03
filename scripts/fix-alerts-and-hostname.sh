#!/bin/bash

echo "🔧 Fixing alerts and hostname configuration..."

# Set the HOSTNAME environment variable if not already set
if [ -z "$HOSTNAME" ]; then
    export HOSTNAME=$(hostname)
    echo "📝 Set HOSTNAME to: $HOSTNAME"
fi

# Stop the current monitoring stack
echo "🛑 Stopping monitoring stack..."
docker-compose down

# Start the monitoring stack with the fixed configuration
echo "🚀 Starting monitoring stack with fixed configuration..."
docker-compose up -d

# Wait for services to start
echo "⏳ Waiting for services to start..."
sleep 30

# Check if services are running
echo "🔍 Checking service status..."
docker-compose ps

# Test Prometheus configuration
echo "🧪 Testing Prometheus configuration..."
curl -s http://localhost:9090/-/reload

echo "✅ Monitoring stack restarted with fixed configuration!"
echo "📊 Prometheus: http://localhost:9090"
echo "📈 Grafana: http://localhost:3000 (admin/admin123)"
echo "📋 Alertmanager: http://localhost:9093"
echo "📝 Loki: http://localhost:3100"

echo ""
echo "🔍 To verify the fixes:"
echo "1. Check Prometheus targets: http://localhost:9090/targets"
echo "2. Check alert rules: http://localhost:9090/rules"
echo "3. Check Alertmanager: http://localhost:9093"
echo "4. The hostname should now show correctly in alerts instead of 'cadvisor:8080'"
echo "5. Container alerts should only fire for actual Docker containers, not system containers" 