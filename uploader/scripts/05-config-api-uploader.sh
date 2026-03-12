#!/usr/bin/with-contenv bash

if [ "$API_UPLOADER_ENABLED" != "true" ]; then
    echo "API Uploader is disabled."
    exit 0
fi

echo "Configuring API Uploader..."

if [ -z "$PAPERLESS_URL" ] || [ -z "$PAPERLESS_TOKEN" ]; then
    echo "ERROR: API_UPLOADER_ENABLED is true, but PAPERLESS_URL or PAPERLESS_TOKEN is not set."
    echo "Disabling API Uploader."
    export API_UPLOADER_ENABLED=false
    exit 1
fi

# Ensure trailing slash in PAPERLESS_URL
if [[ ! "$PAPERLESS_URL" == */ ]]; then
    export PAPERLESS_URL="${PAPERLESS_URL}/"
fi

echo "API Uploader configured for $PAPERLESS_URL"
