#!/bin/bash

# Backup monitoring stack data
BACKUP_DIR="/backup/monitoring-$(date +%Y%m%d-%H%M%S)"
mkdir -p $BACKUP_DIR

echo "Creating backup in $BACKUP_DIR"

# Backup Prometheus data
docker run --rm -v prometheus-storage:/data -v $BACKUP_DIR:/backup alpine tar czf /backup/prometheus-data.tar.gz -C /data .

# Backup Loki data
docker run --rm -v loki-storage:/data -v $BACKUP_DIR:/backup alpine tar czf /backup/loki-data.tar.gz -C /data .

# Backup Grafana data
docker run --rm -v grafana-storage:/data -v $BACKUP_DIR:/backup alpine tar czf /backup/grafana-data.tar.gz -C /data .

# Backup Alertmanager data
docker run --rm -v alertmanager-storage:/data -v $BACKUP_DIR:/backup alpine tar czf /backup/alertmanager-data.tar.gz -C /data .

echo "Backup completed: $BACKUP_DIR"
