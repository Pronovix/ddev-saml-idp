#!/usr/bin/env bash
# #ddev-generated
set -e

# Copy default configuration files to the mounted volume if config.php is missing
if [ ! -f /var/www/simplesamlphp/config/config.php ]; then
    echo "Initializing SimpleSAMLphp config..."
    mkdir -p /var/www/simplesamlphp/config
    if [ -d /var/www/simplesamlphp/defaults/config ]; then
        cp -r /var/www/simplesamlphp/defaults/config/* /var/www/simplesamlphp/config/
    fi
fi

# Copy default metadata files to the mounted volume if saml20-idp-hosted.php is missing
if [ ! -f /var/www/simplesamlphp/metadata/saml20-idp-hosted.php ]; then
    echo "Initializing SimpleSAMLphp metadata..."
    mkdir -p /var/www/simplesamlphp/metadata
    if [ -d /var/www/simplesamlphp/defaults/metadata ]; then
        cp -r /var/www/simplesamlphp/defaults/metadata/* /var/www/simplesamlphp/metadata/
    fi
fi

# Ensure certs and var directories exist and are writable
mkdir -p /var/www/simplesamlphp/certs
mkdir -p /var/www/simplesamlphp/var/temp
mkdir -p /var/www/simplesamlphp/var/cache
chmod -R 777 /var/www/simplesamlphp/var || true

# Generate local signing certificates if missing
CERT_DIR="/var/www/simplesamlphp/certs"
IDP_KEY="${CERT_DIR}/idp.key"
IDP_CRT="${CERT_DIR}/idp.crt"
SP_KEY="${CERT_DIR}/sp.key"
SP_CRT="${CERT_DIR}/sp.crt"
# After generating certs, set ownership to host user so bind-mount files are deletable from the host
CERT_OWNER_UID="${DDEV_UID:-1000}"
CERT_OWNER_GID="${DDEV_GID:-1000}"
# Get www-data GID for cross-container access (typically 33 in Debian-based images)
WWW_DATA_GID=$(getent group www-data | cut -d: -f3)
WWW_DATA_GID="${WWW_DATA_GID:-33}"

if [ -f "${IDP_KEY}" ] && [ -f "${IDP_CRT}" ] && [ -f "${SP_KEY}" ] && [ -f "${SP_CRT}" ]; then
    echo "SAML signing certificates already exist. Skipping."
else
    echo "Generating local SAML signing certificates and private keys..."
    CN_HOST="${SAML_SP_PRIMARY_HOST}"

    if [ ! -f "${IDP_KEY}" ] || [ ! -f "${IDP_CRT}" ]; then
        openssl req -newkey rsa:3072 -new -x509 -days 3652 -nodes \
            -out "${IDP_CRT}" \
            -keyout "${IDP_KEY}" \
            -subj "/CN=idp-${CN_HOST}"
        chmod 644 "${IDP_CRT}" "${IDP_KEY}"
    fi

    if [ ! -f "${SP_KEY}" ] || [ ! -f "${SP_CRT}" ]; then
        openssl req -newkey rsa:3072 -new -x509 -days 3652 -nodes \
            -out "${SP_CRT}" \
            -keyout "${SP_KEY}" \
            -subj "/CN=sp-${CN_HOST}"
        chmod 644 "${SP_CRT}" "${SP_KEY}"
    fi

    # Set ownership to host user but group to www-data for cross-container access
    chown "${CERT_OWNER_UID}:${WWW_DATA_GID}" "${IDP_KEY}" "${SP_KEY}"
    chown "${CERT_OWNER_UID}:${CERT_OWNER_GID}" "${IDP_CRT}" "${SP_CRT}"
    # Private keys: readable by owner and group (www-data)
    chmod 640 "${IDP_KEY}" "${SP_KEY}"
    # Certificates: world-readable (public keys)
    chmod 644 "${IDP_CRT}" "${SP_CRT}"
    # Ensure cert directory is executable for www-data group
    chown "${CERT_OWNER_UID}:${WWW_DATA_GID}" "${CERT_DIR}"
    chmod 750 "${CERT_DIR}"
fi

# Copy .gitignore to the saml-idp root if missing
if [ -f /var/www/simplesamlphp/defaults/.gitignore ]; then
    if [ ! -f /var/www/simplesamlphp/.gitignore ]; then
        cp /var/www/simplesamlphp/defaults/.gitignore /var/www/simplesamlphp/.gitignore
    fi
fi

# Start Apache in the foreground
exec apache2-foreground
