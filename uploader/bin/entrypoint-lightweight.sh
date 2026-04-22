#!/bin/bash
set -e

# Setup users and permissions
/bin/bash /etc/s6-overlay/scripts/config-users.sh

# Start API uploader
if [ "$COLLATE_ENABLED" = "true" ]; then
    /usr/local/bin/paperless-collator.sh &
fi

exec /usr/local/bin/paperless-uploader.sh "$@"
