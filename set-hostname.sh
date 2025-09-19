#!/bin/bash
# Script: set-hostname.sh
# Usage: sudo ./set-hostname.sh NEW_HOSTNAME
# Description: Change the hostname on Ubuntu (tested on 24.04 LTS)

set -e

# --- Check parameters ---
if [ "$#" -ne 1 ]; then
    echo "Usage: $0 NEW_HOSTNAME"
    exit 1
fi

NEW_HOSTNAME="$1"
CURRENT_HOSTNAME=$(hostname)

# --- Set hostname immediately ---
hostnamectl set-hostname "$NEW_HOSTNAME"

# --- Update /etc/hostname ---
echo "$NEW_HOSTNAME" > /etc/hostname

# --- Update /etc/hosts ---
# Replace old hostname if present
if grep -q "$CURRENT_HOSTNAME" /etc/hosts; then
    sed -i "s/\b$CURRENT_HOSTNAME\b/$NEW_HOSTNAME/g" /etc/hosts
fi

# Ensure 127.0.1.1 entry exists with new hostname
if ! grep -q "127.0.1.1\s\+$NEW_HOSTNAME" /etc/hosts; then
    # Remove any old 127.0.1.1 lines
    sed -i '/^127\.0\.1\.1/d' /etc/hosts
    echo -e "127.0.1.1\t$NEW_HOSTNAME" >> /etc/hosts
fi

echo "Hostname changed successfully from '$CURRENT_HOSTNAME' to '$NEW_HOSTNAME'."