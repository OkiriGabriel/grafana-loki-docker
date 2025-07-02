#!/bin/bash

# Promtail Installation Script for Application Servers
# This script installs Promtail on EC2 instances and DigitalOcean droplets

set -e

echo "📝 Installing Promtail for log collection..."

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

print_status() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Get configuration
read -p "Enter the Loki server URL (e.g., http://your-monitoring-server:3100): " LOKI_URL
read -p "Enter your server name/identifier: " SERVER_NAME
read -p "Enter your environment (prod/staging/dev): " ENVIRONMENT

# Detect OS
if [[ "$OSTYPE" == "linux-gnu"* ]]; then
    if [[ -f /etc/debian_version ]]; then
        OS="debian"
    elif [[ -f /etc/redhat-release ]]; then
        OS="redhat"
    else
        OS="linux"
    fi
else
    print_error "Unsupported operating system"
    exit 1
fi

# Download Promtail
print_status "Downloading Promtail..."
PROMTAIL_VERSION="2.9.0"
PROMTAIL_URL="https://github.com/grafana/loki/releases/download/v${PROMTAIL_VERSION}/promtail-linux-amd64.zip"

wget -O /tmp/promtail.zip $PROMTAIL_URL
unzip -o /tmp/promtail.zip -d /tmp/
sudo mv /tmp/promtail-linux-amd64 /usr/local/bin/promtail
sudo chmod +x /usr/local/bin/promtail

# Create Promtail configuration
print_status "Creating Promtail configuration..."
sudo mkdir -p /etc/promtail

sudo tee /etc/promtail/promtail-config.yml > /dev/null <<EOF
server:
  http_listen_port: 9080
  grpc_listen_port: 0

positions:
  filename: /tmp/positions.yaml

clients:
  - url: ${LOKI_URL}/loki/api/v1/push

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
      - target_label: 'instance'
        replacement: '${SERVER_NAME}'
      - target_label: 'environment'
        replacement: '${ENVIRONMENT}'
    pipeline_stages:
      - json:
          expressions:
            timestamp: timestamp
            level: level
            message: message
            service: service
            trace_id: trace_id
            user_id: user_id

      - labels:
          timestamp:
          level:
          service:
          trace_id:
          user_id:

      - timestamp:
          source: timestamp
          format: RFC3339Nano

      - output:
          source: message

  # System logs
  - job_name: system
    static_configs:
      - targets:
          - localhost
        labels:
          job: varlogs
          instance: ${SERVER_NAME}
          environment: ${ENVIRONMENT}
          __path__: /var/log/*log
    pipeline_stages:
      - json:
          expressions:
            timestamp: timestamp
            level: level
            message: message
            service: service
            trace_id: trace_id
            user_id: user_id

      - labels:
          timestamp:
          level:
          service:
          trace_id:
          user_id:

      - timestamp:
          source: timestamp
          format: RFC3339Nano

      - output:
          source: message

  # Application logs
  - job_name: applications
    static_configs:
      - targets:
          - localhost
        labels:
          job: app-logs
          instance: ${SERVER_NAME}
          environment: ${ENVIRONMENT}
          __path__: /var/log/applications/*.log
    pipeline_stages:
      - json:
          expressions:
            timestamp: timestamp
            level: level
            message: message
            service: service
            trace_id: trace_id
            user_id: user_id

      - labels:
          timestamp:
          level:
          service:
          trace_id:
          user_id:

      - timestamp:
          source: timestamp
          format: RFC3339Nano

      - output:
          source: message

  # Custom log paths for your applications
  - job_name: remittance-logs
    static_configs:
      - targets:
          - localhost
        labels:
          job: remittance
          product: remittance
          instance: ${SERVER_NAME}
          environment: ${ENVIRONMENT}
          __path__: /var/log/remittance/*.log
    pipeline_stages:
      - json:
          expressions:
            timestamp: timestamp
            level: level
            message: message
            service: service
            trace_id: trace_id
            user_id: user_id

      - labels:
          timestamp:
          level:
          service:
          trace_id:
          user_id:

      - timestamp:
          source: timestamp
          format: RFC3339Nano

      - output:
          source: message

  - job_name: collection-logs
    static_configs:
      - targets:
          - localhost
        labels:
          job: collection
          product: collection
          instance: ${SERVER_NAME}
          environment: ${ENVIRONMENT}
          __path__: /var/log/collection/*.log
    pipeline_stages:
      - json:
          expressions:
            timestamp: timestamp
            level: level
            message: message
            service: service
            trace_id: trace_id
            user_id: user_id

      - labels:
          timestamp:
          level:
          service:
          trace_id:
          user_id:

      - timestamp:
          source: timestamp
          format: RFC3339Nano

      - output:
          source: message

  - job_name: agency-logs
    static_configs:
      - targets:
          - localhost
        labels:
          job: agency
          product: agency
          instance: ${SERVER_NAME}
          environment: ${ENVIRONMENT}
          __path__: /var/log/agency/*.log
    pipeline_stages:
      - json:
          expressions:
            timestamp: timestamp
            level: level
            message: message
            service: service
            trace_id: trace_id
            user_id: user_id

      - labels:
          timestamp:
          level:
          service:
          trace_id:
          user_id:

      - timestamp:
          source: timestamp
          format: RFC3339Nano

      - output:
          source: message

  # Nginx logs
  - job_name: nginx
    static_configs:
      - targets:
          - localhost
        labels:
          job: nginx
          instance: ${SERVER_NAME}
          environment: ${ENVIRONMENT}
          __path__: /var/log/nginx/*.log
    pipeline_stages:
      - json:
          expressions:
            timestamp: timestamp
            level: level
            message: message
            service: service
            trace_id: trace_id
            user_id: user_id

      - labels:
          timestamp:
          level:
          service:
          trace_id:
          user_id:

      - timestamp:
          source: timestamp
          format: RFC3339Nano

      - output:
          source: message

  # Apache logs
  - job_name: apache
    static_configs:
      - targets:
          - localhost
        labels:
          job: apache
          instance: ${SERVER_NAME}
          environment: ${ENVIRONMENT}
          __path__: /var/log/apache2/*.log
    pipeline_stages:
      - json:
          expressions:
            timestamp: timestamp
            level: level
            message: message
            service: service
            trace_id: trace_id
            user_id: user_id

      - labels:
          timestamp:
          level:
          service:
          trace_id:
          user_id:

      - timestamp:
          source: timestamp
          format: RFC3339Nano

      - output:
          source: message
EOF

# Create log directories
print_status "Creating log directories..."
sudo mkdir -p /var/log/{applications,remittance,collection,agency}
sudo chown -R $USER:$USER /var/log/{applications,remittance,collection,agency}

# Create systemd service
print_status "Creating systemd service..."
sudo tee /etc/systemd/system/promtail.service > /dev/null <<EOF
[Unit]
Description=Promtail service
After=network.target

[Service]
Type=simple
User=root
ExecStart=/usr/local/bin/promtail -config.file /etc/promtail/promtail-config.yml
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
EOF

# Enable and start Promtail
print_status "Starting Promtail service..."
sudo systemctl daemon-reload
sudo systemctl enable promtail.service
sudo systemctl start promtail.service

# Install Node Exporter for system metrics
print_status "Installing Node Exporter..."
NODE_EXPORTER_VERSION="1.6.1"
NODE_EXPORTER_URL="https://github.com/prometheus/node_exporter/releases/download/v${NODE_EXPORTER_VERSION}/node_exporter-${NODE_EXPORTER_VERSION}.linux-amd64.tar.gz"

wget -O /tmp/node_exporter.tar.gz $NODE_EXPORTER_URL
tar -xzf /tmp/node_exporter.tar.gz -C /tmp/
sudo mv /tmp/node_exporter-${NODE_EXPORTER_VERSION}.linux-amd64/node_exporter /usr/local/bin/
sudo chmod +x /usr/local/bin/node_exporter

# Create Node Exporter systemd service
sudo tee /etc/systemd/system/node_exporter.service > /dev/null <<EOF
[Unit]
Description=Node Exporter
After=network.target

[Service]
Type=simple
User=root
ExecStart=/usr/local/bin/node_exporter --path.rootfs=/host --path.procfs=/host/proc --path.sysfs=/host/sys --collector.filesystem.mount-points-exclude=^/(sys|proc|dev|host|etc)(\$\$|/)
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
EOF

# Start Node Exporter
sudo systemctl daemon-reload
sudo systemctl enable node_exporter.service
sudo systemctl start node_exporter.service

# Configure firewall
print_status "Configuring firewall..."
if command -v ufw &> /dev/null; then
    sudo ufw allow 9080/tcp  # Promtail
    sudo ufw allow 9100/tcp  # Node Exporter
elif command -v firewall-cmd &> /dev/null; then
    sudo firewall-cmd --permanent --add-port=9080/tcp
    sudo firewall-cmd --permanent --add-port=9100/tcp
    sudo firewall-cmd --reload
fi

# Create health check script
print_status "Creating health check script..."
sudo tee /usr/local/bin/promtail-health-check.sh > /dev/null <<'EOF'
#!/bin/bash

echo "Checking Promtail health..."

# Check if Promtail is running
if systemctl is-active --quiet promtail; then
    echo "✅ Promtail service is running"
else
    echo "❌ Promtail service is not running"
    exit 1
fi

# Check if Node Exporter is running
if systemctl is-active --quiet node_exporter; then
    echo "✅ Node Exporter service is running"
else
    echo "❌ Node Exporter service is not running"
    exit 1
fi

# Check Promtail metrics endpoint
if curl -s http://localhost:9080/metrics | grep -q "promtail"; then
    echo "✅ Promtail metrics endpoint is responding"
else
    echo "❌ Promtail metrics endpoint is not responding"
fi

# Check Node Exporter metrics endpoint
if curl -s http://localhost:9100/metrics | grep -q "node_"; then
    echo "✅ Node Exporter metrics endpoint is responding"
else
    echo "❌ Node Exporter metrics endpoint is not responding"
fi

echo "Health check completed!"
EOF

sudo chmod +x /usr/local/bin/promtail-health-check.sh

# Create log rotation for application logs
print_status "Configuring log rotation..."
sudo tee /etc/logrotate.d/application-logs > /dev/null <<EOF
/var/log/applications/*.log {
    daily
    missingok
    rotate 7
    compress
    delaycompress
    notifempty
    create 644 $USER $USER
    postrotate
        systemctl reload promtail
    endscript
}

/var/log/remittance/*.log {
    daily
    missingok
    rotate 7
    compress
    delaycompress
    notifempty
    create 644 $USER $USER
    postrotate
        systemctl reload promtail
    endscript
}

/var/log/collection/*.log {
    daily
    missingok
    rotate 7
    compress
    delaycompress
    notifempty
    create 644 $USER $USER
    postrotate
        systemctl reload promtail
    endscript
}

/var/log/agency/*.log {
    daily
    missingok
    rotate 7
    compress
    delaycompress
    notifempty
    create 644 $USER $USER
    postrotate
        systemctl reload promtail
    endscript
}
EOF

# Clean up
rm -f /tmp/promtail.zip /tmp/node_exporter.tar.gz

print_status "🎉 Promtail installation completed!"
echo ""
echo "📊 Services installed:"
echo "   Promtail: http://localhost:9080"
echo "   Node Exporter: http://localhost:9100"
echo ""
echo "🔧 Useful commands:"
echo "   Check status: systemctl status promtail node_exporter"
echo "   View logs: journalctl -u promtail -f"
echo "   Health check: /usr/local/bin/promtail-health-check.sh"
echo "   Restart services: systemctl restart promtail node_exporter"
echo ""
echo "⚠️  Remember to:"
echo "   1. Add this server to your Prometheus targets"
echo "   2. Configure your application to write logs to /var/log/applications/"
echo "   3. Set up proper log formats for your applications"
echo "   4. Monitor disk space for log files" 