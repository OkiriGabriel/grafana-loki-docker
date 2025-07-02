#!/bin/bash

echo "Starting monitoring stack with dynamic hostname detection..."

# Make the hostname detection script executable
chmod +x scripts/update-dynamic-hostname.sh

# Run the hostname detection script
./scripts/update-dynamic-hostname.sh

# Start the monitoring stack
echo "Starting Docker Compose services..."
docker-compose up -d

echo "Monitoring stack started successfully!"
echo "Grafana: http://localhost:3000 (admin/admin123)"
echo "Prometheus: http://localhost:9090"
echo "Alertmanager: http://localhost:9093"
echo "Loki: http://localhost:3100" 