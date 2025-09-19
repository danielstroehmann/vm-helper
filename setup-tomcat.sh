#!/bin/bash
# Script: setup-tomcat10.sh
# Usage: sudo ./setup-tomcat10.sh
# Description: Update system, install Tomcat10, create TLS certs (PKCS12), and configure HTTP/HTTPS

set -e

CERT_DIR="/etc/certs"
TOMCAT_CONF="/etc/tomcat10/server.xml"
KEY_PASS="changeit"   # Passwort für den PKCS12-Keystore

WEBROOT="/var/lib/tomcat10/webapps/ROOT"
INDEX_FILE="$WEBROOT/index.html"

# --- Update package lists ---
echo "Updating package lists..."
apt-get update -y

# --- Upgrade installed packages ---
echo "Upgrading installed packages..."
apt-get upgrade -y

# --- Install Tomcat10, OpenSSL and keytool (comes with default-jdk-headless) ---
echo "Installing Tomcat10 and OpenSSL..."
apt-get install -y tomcat10 tomcat10-admin openssl default-jdk-headless

# --- Enable and start Tomcat10 service ---
echo "Enabling and starting Tomcat10..."
systemctl enable tomcat10
systemctl start tomcat10

# --- Create certificate directory ---
echo "Creating certificate directory..."
mkdir -p "$CERT_DIR"
chmod 750 "$CERT_DIR"

# --- Generate self-signed certificate ---
echo "Generating self-signed certificate..."
openssl req -x509 -nodes -newkey rsa:4096 \
  -keyout "$CERT_DIR/snakeoil.key.pem" \
  -out "$CERT_DIR/snakeoil.crt.pem" \
  -days 10950 \
  -subj "/CN=snakeoil"

chmod 640 "$CERT_DIR/snakeoil.key.pem"
chmod 644 "$CERT_DIR/snakeoil.crt.pem"

# --- Create PKCS12 keystore for Tomcat ---
echo "Creating PKCS12 keystore for Tomcat..."
openssl pkcs12 -export \
  -in "$CERT_DIR/snakeoil.crt.pem" \
  -inkey "$CERT_DIR/snakeoil.key.pem" \
  -out "$CERT_DIR/snakeoil.p12" \
  -name tomcat \
  -password pass:$KEY_PASS

chmod 640 "$CERT_DIR/snakeoil.p12"
chown root:tomcat "$CERT_DIR/snakeoil.p12"

echo "Certificates created:"
echo "  Key     : $CERT_DIR/snakeoil.key.pem"
echo "  Cert    : $CERT_DIR/snakeoil.crt.pem"
echo "  Keystore: $CERT_DIR/snakeoil.p12"

# --- Configure Tomcat server.xml ---
echo "Configuring Tomcat connectors..."

# Remove existing <Connector> entries for 8080 and 8443 to avoid duplicates
sed -i '/<Connector port="8080"/,/>/d' "$TOMCAT_CONF"
sed -i '/<Connector port="8443"/,/>/d' "$TOMCAT_CONF"

# Insert new connectors before </Service>
sed -i '/<\/Service>/i \
    <Connector port="8080" protocol="HTTP/1.1" \n\
               connectionTimeout="20000" \n\
               redirectPort="8443" /> \n\
\n\
    <Connector port="8443" protocol="org.apache.coyote.http11.Http11NioProtocol" \n\
               maxThreads="150" SSLEnabled="true" scheme="https" secure="true"> \n\
        <SSLHostConfig> \n\
            <Certificate certificateKeystoreFile="'"$CERT_DIR/snakeoil.p12"'" \n\
                         certificateKeystorePassword="'"$KEY_PASS"'" \n\
                         certificateKeystoreType="PKCS12" \n\
                         type="RSA" /> \n\
        </SSLHostConfig> \n\
    </Connector>' "$TOMCAT_CONF"

# --- Restart Tomcat to apply changes ---
echo "Restarting Tomcat..."
systemctl restart tomcat10

echo "System update complete, Tomcat10 installed, and HTTP/HTTPS configured with PKCS12 certificate."

# --- Ensure Tomcat ROOT webapp directory exists ---
mkdir -p "$WEBROOT"

# --- Write index.html ---
cat > "$INDEX_FILE" <<EOF
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <title>Tomcat Default Page</title>
</head>
<body>
    <h1 style="text-align:center; margin-top:20%;">Version #1.0 (Tomcat)</h1>
</body>
</html>
EOF

echo "index.html created at $INDEX_FILE"