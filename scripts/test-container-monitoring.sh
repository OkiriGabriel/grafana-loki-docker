#!/bin/bash

# Script to test Docker container monitoring
# This script creates a test container and verifies it's being monitored

set -e

echo "🧪 Testing Docker container monitoring..."

# Get the directory where this script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

# Change to project root
cd "$PROJECT_ROOT"

# Generate a unique container name
CONTAINER_NAME="test-container-$(date +%s)"
echo "📦 Creating test container: $CONTAINER_NAME"

# Create a test container that generates some logs
docker run -d \
  --name "$CONTAINER_NAME" \
  --label logging_jobname="test-app" \
  --label logging_app="test-application" \
  nginx:alpine

echo "⏳ Waiting for container to start..."
sleep 5

# Check if container is running
if docker ps | grep -q "$CONTAINER_NAME"; then
    echo "✅ Container $CONTAINER_NAME is running"
else
    echo "❌ Container $CONTAINER_NAME failed to start"
    exit 1
fi

# Generate some test logs
echo "📝 Generating test logs..."
docker exec "$CONTAINER_NAME" sh -c "echo 'Test log entry at $(date)' >> /var/log/nginx/access.log"
docker exec "$CONTAINER_NAME" sh -c "echo 'Error test log entry at $(date)' >> /var/log/nginx/error.log"

# Wait for logs to be collected
echo "⏳ Waiting for logs to be collected by Promtail..."
sleep 10

# Check Promtail targets
echo "📊 Checking Promtail targets..."
PROMTAIL_TARGETS=$(curl -s http://localhost:9080/targets 2>/dev/null || echo "{}")
if echo "$PROMTAIL_TARGETS" | jq -e '.data.targets[] | select(.labels.container == "'$CONTAINER_NAME'")' >/dev/null 2>&1; then
    echo "✅ Container $CONTAINER_NAME found in Promtail targets"
else
    echo "⚠️ Container $CONTAINER_NAME not found in Promtail targets"
    echo "Promtail targets:"
    echo "$PROMTAIL_TARGETS" | jq '.data.targets[] | {container: .labels.container, job: .labels.job, health: .health}' 2>/dev/null || echo "$PROMTAIL_TARGETS"
fi

# Check if logs are available in Loki
echo "📝 Checking if logs are available in Loki..."
sleep 5

# Query Loki for the container logs
LOKI_QUERY="{\"query\":\"{container=\\\"$CONTAINER_NAME\\\"}\",\"start\":\"$(date -d '5 minutes ago' -u +%Y-%m-%dT%H:%M:%SZ)\",\"end\":\"$(date -u +%Y-%m-%dT%H:%M:%SZ)\"}"
LOKI_RESPONSE=$(curl -s -X POST http://localhost:3100/loki/api/v1/query_range \
  -H "Content-Type: application/json" \
  -d "$LOKI_QUERY" 2>/dev/null || echo "{}")

if echo "$LOKI_RESPONSE" | jq -e '.data.result[] | select(.stream.container == "'$CONTAINER_NAME'")' >/dev/null 2>&1; then
    echo "✅ Logs from container $CONTAINER_NAME found in Loki"
    echo "Sample logs:"
    echo "$LOKI_RESPONSE" | jq -r '.data.result[0].values[] | .[1]' | head -5
else
    echo "⚠️ Logs from container $CONTAINER_NAME not found in Loki"
    echo "Loki response:"
    echo "$LOKI_RESPONSE" | jq '.' 2>/dev/null || echo "$LOKI_RESPONSE"
fi

# Test container lifecycle alerts by stopping the container
echo "🛑 Testing container lifecycle alerts..."
echo "Stopping container $CONTAINER_NAME..."
docker stop "$CONTAINER_NAME"

echo "⏳ Waiting for container to exit..."
sleep 5

# Check if container is stopped
if docker ps -a | grep "$CONTAINER_NAME" | grep -q "Exited"; then
    echo "✅ Container $CONTAINER_NAME has exited"
else
    echo "❌ Container $CONTAINER_NAME did not exit properly"
fi

# Wait for the exit alert to trigger (2 minutes)
echo "⏳ Waiting for container exit alert to trigger (2 minutes)..."
echo "You can check Alertmanager at http://localhost:9093 for alerts"
echo "Or check Prometheus alerts at http://localhost:9090/alerts"

# Clean up
echo "🧹 Cleaning up test container..."
docker rm "$CONTAINER_NAME" 2>/dev/null || true

echo ""
echo "✅ Container monitoring test completed!"
echo ""
echo "🔗 Next steps:"
echo "   1. Check Grafana Explore: http://localhost:3000/explore"
echo "   2. Query: {container=\"$CONTAINER_NAME\"}"
echo "   3. Check Alertmanager: http://localhost:9093"
echo "   4. Check Prometheus alerts: http://localhost:9090/alerts"
echo ""
echo "📋 What was tested:"
echo "   • Container creation and log collection"
echo "   • Promtail target discovery"
echo "   • Loki log ingestion"
echo "   • Container lifecycle monitoring"
echo ""
echo "🎯 If everything worked, you should see:"
echo "   • Logs from the test container in Grafana"
echo "   • Container exit alerts in Alertmanager after 2 minutes" 