#!/bin/bash

# Grafana Loki Monitoring Stack Deployment Script
# For EC2 Instances

set -e

echo "🚀 Starting Grafana Loki Monitoring Stack Deployment..."

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if running as root
if [[ $EUID -eq 0 ]]; then
   print_error "This script should not be run as root"
   exit 1
fi

# Check if Docker is installed
if ! command -v docker &> /dev/null; then
    print_error "Docker is not installed. Please install Docker first."
    exit 1
fi

# Check if Docker Compose is installed
if ! command -v docker-compose &> /dev/null; then
    print_error "Docker Compose is not installed. Please install Docker Compose first."
    exit 1
fi

# Create necessary directories
print_status "Creating configuration directories..."
mkdir -p config/{loki,prometheus,rules,alertmanager,blackbox,grafana/{provisioning/{datasources,dashboards},dashboards}}

# Set proper permissions
print_status "Setting proper permissions..."
sudo chown -R $USER:$USER config/
chmod -R 755 config/

# Create log directories
print_status "Creating log directories..."
sudo mkdir -p /var/log/{applications,remittance,collection,agency}
sudo chown -R $USER:$USER /var/log/{applications,remittance,collection,agency}

# Update Prometheus configuration with actual IPs
print_status "Updating Prometheus configuration..."
read -p "Enter your EC2 monitoring server private IP: " MONITORING_IP
read -p "Enter your EC2 app server private IPs (comma-separated): " EC2_APP_IPS
read -p "Enter your DigitalOcean droplet IPs (comma-separated): " DO_IPS

# Replace placeholder IPs in prometheus.yml
sed -i "s/10.0.1.10:9100/$MONITORING_IP:9100/g" config/prometheus/prometheus.yml

# Update EC2 app server IPs
IFS=',' read -ra EC2_APP_IP_ARRAY <<< "$EC2_APP_IPS"
for i in "${!EC2_APP_IP_ARRAY[@]}"; do
    sed -i "s/10.0.1.$((i+11)):9100/${EC2_APP_IP_ARRAY[$i]}:9100/g" config/prometheus/prometheus.yml
done

# Update DigitalOcean IPs
IFS=',' read -ra DO_IP_ARRAY <<< "$DO_IPS"
for i in "${!DO_IP_ARRAY[@]}"; do
    sed -i "s/192.168.1.$((i+10)):9100/${DO_IP_ARRAY[$i]}:9100/g" config/prometheus/prometheus.yml
done

# Update Alertmanager configuration
print_status "Configuring Alertmanager..."
read -p "Enter your Slack webhook URL: " SLACK_WEBHOOK
read -p "Enter your email address for alerts: " EMAIL_ADDRESS
read -p "Enter your email password (app password for Gmail): " EMAIL_PASSWORD

sed -i "s|YOUR_SLACK_WEBHOOK_URL|$SLACK_WEBHOOK|g" config/alertmanager/alertmanager.yml
sed -i "s/alerts@yourcompany.com/$EMAIL_ADDRESS/g" config/alertmanager/alertmanager.yml
sed -i "s/your-app-password/$EMAIL_PASSWORD/g" config/alertmanager/alertmanager.yml

# API endpoints are pre-configured for both staging and production
print_status "API endpoints configured for staging and production environments..."

# Create systemd service for auto-start
print_status "Creating systemd service..."
sudo tee /etc/systemd/system/monitoring-stack.service > /dev/null <<EOF
[Unit]
Description=Grafana Loki Monitoring Stack
Requires=docker.service
After=docker.service

[Service]
Type=oneshot
RemainAfterExit=yes
WorkingDirectory=$(pwd)
ExecStart=/usr/local/bin/docker-compose up -d
ExecStop=/usr/local/bin/docker-compose down
TimeoutStartSec=0

[Install]
WantedBy=multi-user.target
EOF

# Enable and start the service
sudo systemctl daemon-reload
sudo systemctl enable monitoring-stack.service

# Start the monitoring stack
print_status "Starting monitoring stack..."
docker-compose up -d

# Wait for services to be ready
print_status "Waiting for services to be ready..."
sleep 30

# Check service status
print_status "Checking service status..."
docker-compose ps

# Create firewall rules
print_status "Configuring firewall..."
sudo ufw allow 3000/tcp  # Grafana
sudo ufw allow 9090/tcp  # Prometheus
sudo ufw allow 3100/tcp  # Loki
sudo ufw allow 9093/tcp  # Alertmanager
sudo ufw allow 9115/tcp  # Blackbox Exporter
sudo ufw allow 9100/tcp  # Node Exporter
sudo ufw allow 8080/tcp  # Cadvisor

# Create a simple health check script
print_status "Creating health check script..."
cat > scripts/health-check.sh <<'EOF'
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
EOF

chmod +x scripts/health-check.sh

# Create backup script
print_status "Creating backup script..."
cat > scripts/backup.sh <<'EOF'
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
EOF

chmod +x scripts/backup.sh

# Create log rotation configuration
print_status "Configuring log rotation..."
sudo tee /etc/logrotate.d/monitoring-stack > /dev/null <<EOF
/var/log/monitoring-stack/*.log {
    daily
    missingok
    rotate 7
    compress
    delaycompress
    notifempty
    create 644 $USER $USER
    postrotate
        docker-compose restart loki
    endscript
}
EOF

print_status "🎉 Monitoring stack deployment completed!"
echo ""
echo "📊 Access URLs:"
echo "   Grafana: http://$(curl -s http://169.254.169.254/latest/meta-data/public-ipv4):3000 (admin/admin123)"
echo "   Prometheus: http://$(curl -s http://169.254.169.254/latest/meta-data/public-ipv4):9090"
echo "   Alertmanager: http://$(curl -s http://169.254.169.254/latest/meta-data/public-ipv4):9093"
echo ""
echo "🔧 Useful commands:"
echo "   Check status: docker-compose ps"
echo "   View logs: docker-compose logs -f"
echo "   Health check: ./scripts/health-check.sh"
echo "   Backup data: ./scripts/backup.sh"
echo "   Stop stack: docker-compose down"
echo "   Start stack: docker-compose up -d"
echo ""
echo "⚠️  Remember to:"
echo "   1. Change default Grafana password"
echo "   2. Configure your actual API endpoints"
echo "   3. Set up proper SSL certificates"
echo "   4. Configure backup retention policies" 