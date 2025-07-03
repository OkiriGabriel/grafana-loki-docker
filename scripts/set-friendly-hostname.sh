#!/bin/bash

# Set friendly hostname for monitoring server
# This script sets a more readable hostname instead of the EC2 internal IP

# Get the current hostname
CURRENT_HOSTNAME=$(hostname)

# Check if it's an EC2 instance with IP-based hostname
if [[ $CURRENT_HOSTNAME =~ ^ip-[0-9]+-[0-9]+-[0-9]+-[0-9]+$ ]]; then
    echo "Current hostname is EC2 internal IP: $CURRENT_HOSTNAME"
    
    # Set a friendly hostname
    FRIENDLY_HOSTNAME="bpay-logging-and-monitoring"
    
    echo "Setting friendly hostname: $FRIENDLY_HOSTNAME"
    
    # Set the hostname temporarily
    sudo hostname $FRIENDLY_HOSTNAME
    
    # Set the hostname permanently
    echo "$FRIENDLY_HOSTNAME" | sudo tee /etc/hostname
    
    # Update /etc/hosts if needed
    if ! grep -q "$FRIENDLY_HOSTNAME" /etc/hosts; then
        echo "127.0.1.1 $FRIENDLY_HOSTNAME" | sudo tee -a /etc/hosts
    fi
    
    echo "Hostname updated to: $FRIENDLY_HOSTNAME"
    echo "Please reboot the system for changes to take full effect"
else
    echo "Current hostname is already friendly: $CURRENT_HOSTNAME"
fi

# Export the hostname for Docker Compose
export HOSTNAME=$(hostname)
echo "HOSTNAME environment variable set to: $HOSTNAME" 