#!/bin/bash

# Get EC2 instance ID
EC2_INSTANCE_ID=$(curl -s http://169.254.169.254/latest/meta-data/instance-id 2>/dev/null)

# If we can't get instance ID, fall back to hostname
if [ -z "$EC2_INSTANCE_ID" ]; then
    EC2_INSTANCE_ID=$(hostname)
fi

# If still empty, use a default
if [ -z "$EC2_INSTANCE_ID" ]; then
    EC2_INSTANCE_ID="unknown-host"
fi

echo "Using hostname: $EC2_INSTANCE_ID"

# Update Prometheus configuration with the actual hostname
sed -i "s/replacement: '.*'/replacement: '$EC2_INSTANCE_ID'/g" config/prometheus/prometheus.yml

echo "Prometheus configuration updated with hostname: $EC2_INSTANCE_ID" 