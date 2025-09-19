#!/bin/bash
# Script: set-hostname.sh
# Usage: sudo ./set-hostname.sh NEW_HOSTNAME
# Description: Ändert den Hostnamen in Ubuntu (getestet auf 24.04 LTS)

set -e

# --- Parameter prüfen ---
if [ "$#" -ne 1 ]; then
    echo "Usage: $0 NEW_HOSTNAME"
    exit 1
fi

NEW_HOSTNAME="$1"
CURRENT_HOSTNAME=$(hostname)

# --- Hostname sofort setzen ---
hostnamectl set-hostname "$NEW_HOSTNAME"

# --- /etc/hostname aktualisieren ---
echo "$NEW_HOSTNAME" > /etc/hostname

# --- /etc/hosts anpassen ---
# Falls alte Hostname-Einträge existieren, diese ersetzen
if grep -q "$CURRENT_HOSTNAME" /etc/hosts; then
    sed -i "s/\b$CURRENT_HOSTNAME\b/$NEW_HOSTNAME/g" /etc/hosts
fi

# Sicherstellen, dass 127.0.1.1 eine Zeile mit neuem Hostnamen hat
if ! grep -q "127.0.1.1\s\+$NEW_HOSTNAME" /etc/hosts; then
    # Entferne evtl. alte 127.0.1.1-Zeilen
    sed -i '/^127\.0\.1\.1/d' /etc/hosts
    echo -e "127.0.1.1\t$NEW_HOSTNAME" >> /etc/hosts
fi

echo "Hostname erfolgreich geändert von '$CURRENT_HOSTNAME' auf '$NEW_HOSTNAME'."