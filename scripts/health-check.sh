#!/bin/bash

# Health check for monitoring stack
echo "Checking monitoring stack health..."

# Check if containers are running
if docker-compose ps | grep -q "Up"; then
    echo "✅ All containers are running"
else
    echo "❌ Some containers are not running"
    docker-compose ps
    exit 1
fi

# Check Grafana
if curl -s http://localhost:3000/api/health | grep -q "ok"; then
    echo "✅ Grafana is healthy"
else
    echo "❌ Grafana is not responding"
fi

# Check Prometheus
if curl -s http://localhost:9090/-/healthy | grep -q "ok"; then
    echo "✅ Prometheus is healthy"
else
    echo "❌ Prometheus is not responding"
fi

# Check Loki
if curl -s http://localhost:3100/ready | grep -q "ready"; then
    echo "✅ Loki is healthy"
else
    echo "❌ Loki is not responding"
fi

echo "Health check completed!"
