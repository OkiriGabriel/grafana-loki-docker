#!/bin/bash

# Update Local Promtail Configuration Script
# This script updates your existing systemd Promtail with the correct hostname

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}Updating local Promtail configuration...${NC}"

# Get the current hostname
HOSTNAME=$(hostname)
echo -e "${YELLOW}Detected hostname: $HOSTNAME${NC}"

# Check if Promtail service exists
if ! systemctl list-unit-files | grep -q promtail; then
    echo -e "${RED}Error: Promtail systemd service not found${NC}"
    echo -e "${YELLOW}Please make sure Promtail is installed and running with systemd${NC}"
    exit 1
fi

# Backup existing config
if [ -f /etc/promtail/promtail-config.yml ]; then
    echo -e "${YELLOW}Backing up existing configuration...${NC}"
    sudo cp /etc/promtail/promtail-config.yml /etc/promtail/promtail-config.yml.backup
fi

# Copy the new configuration
echo -e "${YELLOW}Updating Promtail configuration...${NC}"
sudo cp config/promtail/promtail-config.yml /etc/promtail/promtail-config.yml

# Update the hostname in the config file
echo -e "${YELLOW}Setting hostname to: $HOSTNAME${NC}"
sudo sed -i "s/\${HOSTNAME}/$HOSTNAME/g" /etc/promtail/promtail-config.yml

# Check if we need to update the systemd service file
SERVICE_FILE="/etc/systemd/system/promtail.service"
if [ -f "$SERVICE_FILE" ]; then
    echo -e "${YELLOW}Checking systemd service file...${NC}"
    
    # Check if HOSTNAME environment variable is already set
    if ! grep -q "Environment.*HOSTNAME" "$SERVICE_FILE"; then
        echo -e "${YELLOW}Adding HOSTNAME environment variable to systemd service...${NC}"
        
        # Create a backup of the service file
        sudo cp "$SERVICE_FILE" "$SERVICE_FILE.backup"
        
        # Add environment variable after [Service] section
        sudo sed -i '/\[Service\]/a Environment=HOSTNAME='$HOSTNAME'' "$SERVICE_FILE"
        
        echo -e "${GREEN}Updated systemd service file${NC}"
    else
        echo -e "${YELLOW}HOSTNAME environment variable already exists in service file${NC}"
    fi
else
    echo -e "${YELLOW}Systemd service file not found at $SERVICE_FILE${NC}"
    echo -e "${YELLOW}You may need to manually add HOSTNAME environment variable to your Promtail service${NC}"
fi

# Reload systemd and restart Promtail
echo -e "${YELLOW}Reloading systemd and restarting Promtail...${NC}"
sudo systemctl daemon-reload
sudo systemctl restart promtail

# Check if Promtail is running
if sudo systemctl is-active --quiet promtail; then
    echo -e "${GREEN}Promtail is running successfully!${NC}"
    echo -e "${YELLOW}Configuration file: /etc/promtail/promtail-config.yml${NC}"
    echo -e "${YELLOW}Hostname configured: $HOSTNAME${NC}"
else
    echo -e "${RED}Failed to start Promtail. Check logs with: sudo journalctl -u promtail${NC}"
    echo -e "${YELLOW}Restoring backup configuration...${NC}"
    sudo cp /etc/promtail/promtail-config.yml.backup /etc/promtail/promtail-config.yml
    sudo systemctl restart promtail
    exit 1
fi

# Show status
echo -e "${GREEN}Promtail status:${NC}"
sudo systemctl status promtail --no-pager -l

echo -e "${GREEN}Update complete! Promtail is now configured with hostname: $HOSTNAME${NC}"
echo -e "${YELLOW}You can verify logs are being sent to Loki by checking:${NC}"
echo -e "${YELLOW}  - Loki targets: http://localhost:9090/targets${NC}"
echo -e "${YELLOW}  - Loki logs: http://localhost:3100/ready${NC}" 