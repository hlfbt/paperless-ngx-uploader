#!/bin/bash
set -e

# Setup users and permissions
/bin/bash /etc/s6-overlay/scripts/config-users.sh

# Start API uploader
exec /usr/local/bin/paperless-uploader.sh "$@"
