#!/command/with-contenv /bin/bash

# Set defaults
PUID="${PUID:-1000}"
PGID="${PGID:-1000}"
CONSUMPTION_DIR="${CONSUMPTION_DIR:-/consumption}"
COLLATE_DIR="${COLLATE_DIR:-${CONSUMPTION_DIR}/collate}"
ARCHIVE_DIR="${ARCHIVE_DIR:-/archive}"

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
chown "${PUID}:${PGID}" "$CONSUMPTION_DIR"
chmod 775 "$CONSUMPTION_DIR"

if [ "$COLLATE_ENABLED" = "true" ]; then
    mkdir -p "$COLLATE_DIR"
    chown "${PUID}:${PGID}" "$COLLATE_DIR"
    chmod 775 "$COLLATE_DIR"
fi

mkdir -p "$ARCHIVE_DIR"
chown "${PUID}:${PGID}" "$ARCHIVE_DIR"
chmod 775 "$ARCHIVE_DIR"
