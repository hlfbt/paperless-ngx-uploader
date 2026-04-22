#!/bin/bash
set -e

# Setup users and permissions
/bin/bash /etc/s6-overlay/scripts/config-users.sh

if [ "$COLLATE_ENABLED" = "true" ]; then
    /usr/local/bin/paperless-collator.sh &
fi

# Start API uploader
exec /usr/local/bin/paperless-uploader.sh "$@"
