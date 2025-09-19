#!/bin/bash
# Script: setup-nginx.sh
# Usage: sudo ./setup-nginx.sh
# Description: Update system, install NGINX, and create a self-signed TLS certificate

set -e
CERT_DIR="/etc/certs"
NGINX_SITE="/etc/nginx/sites-available/default"

# --- Update package lists ---
echo "Updating package lists..."
apt-get update -y

# --- Upgrade installed packages ---
echo "Upgrading installed packages..."
apt-get upgrade -y

# --- Install NGINX and OpenSSL ---
echo "Installing NGINX and OpenSSL..."
apt-get install -y nginx openssl

# --- Enable and start NGINX service ---
echo "Enabling and starting NGINX..."
systemctl enable nginx
systemctl start nginx

# --- Create certificate directory ---
CERT_DIR="/etc/certs"
mkdir -p "$CERT_DIR"
chmod 700 "$CERT_DIR"

# --- Generate self-signed certificate ---
echo "Generating self-signed certificate..."
openssl req -x509 -nodes -newkey rsa:4096 \
  -keyout "$CERT_DIR/snakeoil.key.pem" \
  -out "$CERT_DIR/snakeoil.crt.pem" \
  -days 10950 \
  -subj "/CN=snakeoil"

chmod 600 "$CERT_DIR/snakeoil.key.pem"
chmod 644 "$CERT_DIR/snakeoil.crt.pem"

echo "Self-signed TLS certificate created at:"
echo "  Key : $CERT_DIR/snakeoil.key.pem"
echo "  Cert: $CERT_DIR/snakeoil.crt.pem"

echo "System update complete and NGINX installed successfully."

# --- Write new config ---
cat > "$NGINX_SITE" <<EOF
server {
    listen 80 default_server;
    listen [::]:80 default_server;

    server_name _;

    root /var/www/html;
    index index.html index.htm;

    location / {
        try_files \$uri \$uri/ =404;
    }
}

server {
    listen 443 ssl default_server;
    listen [::]:443 ssl default_server;

    server_name _;

    root /var/www/html;
    index index.html index.htm;

    ssl_certificate     $CERT_DIR/snakeoil.crt.pem;
    ssl_certificate_key $CERT_DIR/snakeoil.key.pem;

    location / {
        try_files \$uri \$uri/ =404;
    }
}
EOF

# --- Test NGINX configuration ---
nginx -t

# --- Reload NGINX ---
systemctl reload nginx

echo "Generic HTTP (80) and HTTPS (443) site configuration applied successfully."