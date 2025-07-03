# Multi-Server Monitoring Configuration Guide

## Why Are Some Sections Commented Out?

The EC2 instances and DigitalOcean droplets sections in `config/prometheus/prometheus.yml` are commented out because:

1. **Placeholder IPs**: The IP addresses shown are just examples (`10.0.1.10`, `192.168.1.10`, etc.)
2. **Not configured yet**: These need to be replaced with your actual server IPs
3. **Avoiding connection errors**: If placeholder IPs were active, Prometheus would fail to connect and create noise in logs

## Current Active Monitoring

Your current setup monitors:
- ✅ **Local Docker containers** (via cAdvisor)
- ✅ **Local system metrics** (via Node Exporter)
- ✅ **API endpoints** (via Blackbox Exporter)
- ✅ **Monitoring stack itself** (Prometheus, Grafana, Loki, Alertmanager)

## How to Enable Multi-Server Monitoring

### Step 1: Install Node Exporter on Each Server

For each server you want to monitor, install Node Exporter:

#### On Ubuntu/Debian:
```bash
# Download Node Exporter
wget https://github.com/prometheus/node_exporter/releases/download/v1.6.1/node_exporter-1.6.1.linux-amd64.tar.gz

# Extract
tar xvf node_exporter-1.6.1.linux-amd64.tar.gz

# Move to /usr/local/bin
sudo mv node_exporter-1.6.1.linux-amd64/node_exporter /usr/local/bin/

# Create systemd service
sudo tee /etc/systemd/system/node_exporter.service > /dev/null <<EOF
[Unit]
Description=Node Exporter
After=network.target

[Service]
User=node_exporter
Group=node_exporter
Type=simple
ExecStart=/usr/local/bin/node_exporter

[Install]
WantedBy=multi-user.target
EOF

# Create user
sudo useradd -rs /bin/false node_exporter

# Start service
sudo systemctl daemon-reload
sudo systemctl enable node_exporter
sudo systemctl start node_exporter

# Verify it's running
sudo systemctl status node_exporter
```

#### On CentOS/RHEL:
```bash
# Install Node Exporter
sudo yum install -y node_exporter

# Start and enable service
sudo systemctl enable node_exporter
sudo systemctl start node_exporter

# Verify it's running
sudo systemctl status node_exporter
```

### Step 2: Configure Firewall

Ensure port 9100 is open on each server:

#### Ubuntu/Debian:
```bash
sudo ufw allow 9100/tcp
```

#### CentOS/RHEL:
```bash
sudo firewall-cmd --permanent --add-port=9100/tcp
sudo firewall-cmd --reload
```

### Step 3: Update Prometheus Configuration

Edit `config/prometheus/prometheus.yml` and replace the placeholder IPs:

```yaml
# EC2 Instances (replace with your actual EC2 private IPs)
- job_name: 'ec2-instances'
  static_configs:
    - targets:
      - 'YOUR_ACTUAL_EC2_IP_1:9100'  # Replace with real IP
      - 'YOUR_ACTUAL_EC2_IP_2:9100'  # Replace with real IP
      - 'YOUR_ACTUAL_EC2_IP_3:9100'  # Replace with real IP
  scrape_interval: 30s
  relabel_configs:
    - source_labels: [__address__]
      target_label: instance
      regex: '(.+):.+'
      replacement: '${1}'
      action: replace
    - source_labels: [instance]
      target_label: hostname
      action: replace

# DigitalOcean Droplets (replace with your actual droplet IPs)
- job_name: 'digitalocean-droplets'
  static_configs:
    - targets:
      - 'YOUR_ACTUAL_DROPLET_IP_1:9100'  # Replace with real IP
      - 'YOUR_ACTUAL_DROPLET_IP_2:9100'  # Replace with real IP
      - 'YOUR_ACTUAL_DROPLET_IP_3:9100'  # Replace with real IP
  scrape_interval: 30s
  relabel_configs:
    - source_labels: [__address__]
      target_label: instance
      regex: '(.+):.+'
      replacement: '${1}'
      action: replace
    - source_labels: [instance]
      target_label: hostname
      action: replace
```

### Step 4: Test Connectivity

Before enabling the sections, test connectivity:

```bash
# Test from your monitoring server to each target server
telnet YOUR_SERVER_IP 9100

# Or use curl to test the metrics endpoint
curl http://YOUR_SERVER_IP:9100/metrics
```

### Step 5: Enable and Restart

1. **Uncomment the sections** by removing the `#` symbols
2. **Replace placeholder IPs** with your actual server IPs
3. **Restart Prometheus**:
   ```bash
   docker-compose restart prometheus
   ```

### Step 6: Verify Targets

Check that all targets are up:
- Go to http://localhost:9090/targets
- Look for your server targets in the "UP" state

## Example Configuration

Here's an example with real IPs:

```yaml
# EC2 Instances
- job_name: 'ec2-instances'
  static_configs:
    - targets:
      - '172.31.15.100:9100'  # Web server 1
      - '172.31.15.101:9100'  # Web server 2
      - '172.31.15.102:9100'  # Database server
  scrape_interval: 30s
  relabel_configs:
    - source_labels: [__address__]
      target_label: instance
      regex: '(.+):.+'
      replacement: '${1}'
      action: replace
    - source_labels: [instance]
      target_label: hostname
      action: replace

# DigitalOcean Droplets
- job_name: 'digitalocean-droplets'
  static_configs:
    - targets:
      - '159.89.123.45:9100'  # Load balancer
      - '159.89.123.46:9100'  # Cache server
      - '159.89.123.47:9100'  # Backup server
  scrape_interval: 30s
  relabel_configs:
    - source_labels: [__address__]
      target_label: instance
      regex: '(.+):.+'
      replacement: '${1}'
      action: replace
    - source_labels: [instance]
      target_label: hostname
      action: replace
```

## Monitoring Docker Containers on Remote Servers

To monitor Docker containers on remote servers, you'll also need to install cAdvisor on each server:

### Install cAdvisor on Remote Servers

```bash
# Run cAdvisor container on each server
docker run \
  --volume=/:/rootfs:ro \
  --volume=/var/run:/var/run:ro \
  --volume=/sys:/sys:ro \
  --volume=/var/lib/docker/:/var/lib/docker:ro \
  --volume=/dev/disk/:/dev/disk:ro \
  --publish=8080:8080 \
  --detach=true \
  --name=cadvisor \
  --privileged \
  --device=/dev/kmsg \
  gcr.io/cadvisor/cadvisor:latest
```

### Add cAdvisor Targets to Prometheus

```yaml
# Remote cAdvisor instances
- job_name: 'remote-cadvisor'
  static_configs:
    - targets:
      - 'YOUR_SERVER_IP_1:8080'  # cAdvisor on server 1
      - 'YOUR_SERVER_IP_2:8080'  # cAdvisor on server 2
      - 'YOUR_SERVER_IP_3:8080'  # cAdvisor on server 3
  scrape_interval: 30s
  relabel_configs:
    - source_labels: [__address__]
      target_label: instance
      regex: '(.+):.+'
      replacement: '${1}'
      action: replace
    - source_labels: [instance]
      target_label: hostname
      action: replace
```

## Troubleshooting

### Targets Not Showing Up
1. **Check firewall**: Ensure port 9100 (Node Exporter) and 8080 (cAdvisor) are open
2. **Verify services**: Check that Node Exporter and cAdvisor are running
3. **Test connectivity**: Use telnet or curl to test from monitoring server
4. **Check Prometheus logs**: `docker-compose logs prometheus`

### Connection Refused Errors
1. **Service not running**: Start Node Exporter or cAdvisor
2. **Wrong port**: Verify services are listening on correct ports
3. **Firewall blocking**: Check firewall rules
4. **Network issues**: Verify network connectivity between servers

### High Latency
1. **Increase scrape interval**: Change from 15s to 30s or 60s
2. **Check network**: Monitor network latency between servers
3. **Optimize queries**: Use recording rules for complex queries

## Security Considerations

1. **Use private IPs**: Use internal/private IPs when possible
2. **VPN access**: Consider VPN for secure communication
3. **Authentication**: Implement basic auth for Node Exporter if needed
4. **Firewall rules**: Only allow necessary ports (9100, 8080)

## Next Steps

1. **Replace placeholder IPs** with your actual server IPs
2. **Install Node Exporter** on each server
3. **Test connectivity** before enabling
4. **Uncomment sections** and restart Prometheus
5. **Verify targets** are showing up correctly
6. **Set up alerts** for remote servers using the existing alert rules 