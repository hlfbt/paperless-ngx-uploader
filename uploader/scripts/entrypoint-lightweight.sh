#!/bin/bash
set -e
# Setup users and permissions
/etc/cont-init.d/01-config-users.sh
# Start API uploader
exec /etc/cont-init.d/05-api-uploader.sh "$@"
