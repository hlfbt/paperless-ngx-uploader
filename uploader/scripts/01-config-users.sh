#!/usr/bin/with-contenv bash

# Set PUID/PGID
PUID=${PUID:-1000}
PGID=${PGID:-1000}

# Create group if it doesn't exist
if ! getent group paperless > /dev/null; then
    groupadd -g "$PGID" paperless
fi

# Create user if it doesn't exist
if ! getent passwd paperless > /dev/null; then
    useradd -u "$PUID" -g "$PGID" -m -s /bin/bash paperless
fi

# Set permissions for consumption and archive directory
mkdir -p "$CONSUMPTION_DIR"
chown "$PUID:$PGID" "$CONSUMPTION_DIR"
chmod 775 "$CONSUMPTION_DIR"

mkdir -p "$ARCHIVE_DIR"
chown "$PUID:$PGID" "$ARCHIVE_DIR"
chmod 775 "$ARCHIVE_DIR"
