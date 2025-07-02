#!/bin/bash

# Get the actual hostname from the system
ACTUAL_HOSTNAME=$(hostname)

# If hostname is empty or localhost, try to get EC2 instance name
if [ -z "$ACTUAL_HOSTNAME" ] || [ "$ACTUAL_HOSTNAME" = "localhost" ] || [ "$ACTUAL_HOSTNAME" = "localhost.localdomain" ]; then
    # Try to get EC2 instance name
    EC2_HOSTNAME=$(curl -s http://169.254.169.254/latest/meta-data/hostname 2>/dev/null)
    if [ ! -z "$EC2_HOSTNAME" ]; then
        ACTUAL_HOSTNAME=$(echo $EC2_HOSTNAME | cut -d'.' -f1)
    else
        # Fallback to IP address
        ACTUAL_HOSTNAME=$(hostname -I | awk '{print $1}')
    fi
fi

# If still empty, use a default
if [ -z "$ACTUAL_HOSTNAME" ]; then
    ACTUAL_HOSTNAME="unknown-host"
fi

echo "Detected hostname: $ACTUAL_HOSTNAME"

# Update Prometheus configuration with the actual hostname
sed -i "s/replacement: '.*'/replacement: '$ACTUAL_HOSTNAME'/g" config/prometheus/prometheus.yml

echo "Prometheus configuration updated with hostname: $ACTUAL_HOSTNAME"

# Export the hostname for use in docker-compose
export HOSTNAME=$ACTUAL_HOSTNAME
echo "HOSTNAME=$ACTUAL_HOSTNAME" > .env

echo "Environment variable HOSTNAME set to: $ACTUAL_HOSTNAME" 