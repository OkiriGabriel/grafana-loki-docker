#!/bin/bash

# Promtail Remote Server Setup Script
# This script automatically configures Promtail with the correct hostname

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}Setting up Promtail on remote server...${NC}"

# Get the current hostname
HOSTNAME=$(hostname)
echo -e "${YELLOW}Detected hostname: $HOSTNAME${NC}"

# Get Loki server IP from user
read -p "Enter your Loki server IP address: " LOKI_IP

if [ -z "$LOKI_IP" ]; then
    echo -e "${RED}Error: Loki server IP is required${NC}"
    exit 1
fi

# Create Promtail configuration directory
sudo mkdir -p /etc/promtail

# Create the Promtail configuration file with the correct hostname
cat > /tmp/promtail-config.yml << EOF
server:
  http_listen_port: 9080
  grpc_listen_port: 0

positions:
  filename: /tmp/positions.yaml

clients:
  - url: http://$LOKI_IP:3100/loki/api/v1/push

scrape_configs:
  # Docker container logs
  - job_name: docker
    docker_sd_configs:
      - host: unix:///var/run/docker.sock
        refresh_interval: 5s
        filters:
          - name: name
            values: ['.*']
    relabel_configs:
      - source_labels: ['__meta_docker_container_name']
        regex: '/(.*)'
        target_label: 'container'
      - source_labels: ['__meta_docker_container_log_stream']
        target_label: 'logstream'
      - source_labels: ['__meta_docker_container_label_logging_jobname']
        target_label: 'job'
      - source_labels: ['__meta_docker_container_label_com_docker_compose_service']
        target_label: 'service'
      - source_labels: ['__meta_docker_container_label_com_docker_compose_project']
        target_label: 'project'
      - source_labels: ['__meta_docker_container_label_logging_level']
        target_label: 'level'
      - source_labels: ['__meta_docker_container_label_logging_app']
        target_label: 'app'
      - source_labels: ['__meta_docker_container_image']
        target_label: 'image'
      - source_labels: ['__meta_docker_container_id']
        target_label: 'container_id'
      # Set the actual hostname for this server
      - target_label: 'hostname'
        replacement: '$HOSTNAME'
    pipeline_stages:
      # Try to parse JSON logs first
      - json:
          expressions:
            timestamp: timestamp
            level: level
            message: message
            service: service
            trace_id: trace_id
            user_id: user_id

      # Extract labels from JSON
      - labels:
          timestamp:
          level:
          service:
          trace_id:
          user_id:

      # Parse timestamp if available
      - timestamp:
          source: timestamp
          format: RFC3339Nano

      # For non-JSON logs, extract patterns
      - regex:
          expression: '(?P<timestamp>\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2}) (?P<level>\w+) - (?P<message>.*)'
          source: message

      # Extract Java exception patterns
      - regex:
          expression: '(?P<exception>java\.lang\.[\w.]+Exception)'
          source: message

      # Extract error patterns
      - regex:
          expression: '(?P<error_type>failed|error|errored|Exception|ERROR)'
          source: message

      # Extract success patterns
      - regex:
          expression: '(?P<success_type>success|completed|SUCCESS)'
          source: message

      # Add labels for pattern matching
      - labels:
          exception:
          error_type:
          success_type:

      # Output the message
      - output:
          source: message

  # System logs
  - job_name: system
    static_configs:
      - targets:
          - localhost
        labels:
          job: varlogs
          hostname: '$HOSTNAME'
          __path__: /var/log/*log

  # Application logs
  - job_name: applications
    static_configs:
      - targets:
          - localhost
        labels:
          job: app-logs
          hostname: '$HOSTNAME'
          __path__: /var/log/applications/*.log

  # Custom log paths for your applications
  - job_name: remittance-logs
    static_configs:
      - targets:
          - localhost
        labels:
          job: remittance
          product: remittance
          hostname: '$HOSTNAME'
          __path__: /var/log/remittance/*.log

  - job_name: collection-logs
    static_configs:
      - targets:
          - localhost
        labels:
          job: collection
          product: collection
          hostname: '$HOSTNAME'
          __path__: /var/log/collection/*.log

  - job_name: agency-logs
    static_configs:
      - targets:
          - localhost
        labels:
          job: agency
          product: agency
          hostname: '$HOSTNAME'
          __path__: /var/log/agency/*.log

  # Nginx logs
  - job_name: nginx
    static_configs:
      - targets:
          - localhost
        labels:
          job: nginx
          hostname: '$HOSTNAME'
          __path__: /var/log/nginx/*.log

  # Apache logs
  - job_name: apache
    static_configs:
      - targets:
          - localhost
        labels:
          job: apache
          hostname: '$HOSTNAME'
          __path__: /var/log/apache2/*.log

  # Docker events (for container lifecycle monitoring)
  - job_name: docker-events
    static_configs:
      - targets:
          - localhost
        labels:
          job: docker-events
          hostname: '$HOSTNAME'
          __path__: /var/lib/docker/containers/*/*-json.log
EOF

# Move the configuration file to the proper location
sudo mv /tmp/promtail-config.yml /etc/promtail/promtail-config.yml

# Create systemd service file
sudo tee /etc/systemd/system/promtail.service > /dev/null << EOF
[Unit]
Description=Promtail
After=network.target

[Service]
Type=simple
User=promtail
Group=promtail
ExecStart=/usr/local/bin/promtail -config.file=/etc/promtail/promtail-config.yml
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
EOF

# Create promtail user
sudo useradd -rs /bin/false promtail

# Download and install Promtail
echo -e "${YELLOW}Downloading Promtail...${NC}"
wget https://github.com/grafana/loki/releases/download/v2.9.0/promtail-linux-amd64.zip
unzip promtail-linux-amd64.zip
sudo mv promtail-linux-amd64 /usr/local/bin/promtail
sudo chmod +x /usr/local/bin/promtail

# Clean up downloaded files
rm promtail-linux-amd64.zip

# Set proper permissions
sudo chown -R promtail:promtail /etc/promtail

# Reload systemd and start Promtail
sudo systemctl daemon-reload
sudo systemctl enable promtail
sudo systemctl start promtail

# Check if Promtail is running
if sudo systemctl is-active --quiet promtail; then
    echo -e "${GREEN}Promtail is running successfully!${NC}"
    echo -e "${YELLOW}Configuration file: /etc/promtail/promtail-config.yml${NC}"
    echo -e "${YELLOW}Hostname configured: $HOSTNAME${NC}"
    echo -e "${YELLOW}Loki server: $LOKI_IP:3100${NC}"
else
    echo -e "${RED}Failed to start Promtail. Check logs with: sudo journalctl -u promtail${NC}"
    exit 1
fi

# Show status
echo -e "${GREEN}Promtail status:${NC}"
sudo systemctl status promtail --no-pager -l

echo -e "${GREEN}Setup complete! Promtail is now collecting logs and sending them to Loki.${NC}" 