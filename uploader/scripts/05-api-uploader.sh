#!/bin/bash

if [ "$API_UPLOADER_ENABLED" != "true" ]; then
    echo "API Uploader is disabled. Exiting."
    exit 0
fi

echo "Configuring API Uploader..."

if [ -z "$PAPERLESS_URL" ] || [ -z "$PAPERLESS_TOKEN" ]; then
    echo "ERROR: API_UPLOADER_ENABLED is true, but PAPERLESS_URL or PAPERLESS_TOKEN is not set."
    echo "Disabling API Uploader."
    exit 1
fi

# Ensure trailing slash in PAPERLESS_URL
if [[ ! "$PAPERLESS_URL" == */ ]]; then
    export PAPERLESS_URL="${PAPERLESS_URL}/"
fi

if [ "$API_UPLOADER_ONESHOT" = "true" ]; then
    echo "API Uploader configured for $PAPERLESS_URL (Oneshot mode enabled)"
else
    echo "API Uploader configured for $PAPERLESS_URL"
fi

echo "Starting API Uploader monitoring $CONSUMPTION_DIR..."

upload_file() {
    local file_path="$1"
    local file_name=$(basename "$file_path")
    
    # Skip hidden files
    if [[ "$file_name" == .* ]]; then
        return
    fi

    echo "Uploading $file_name to $PAPERLESS_URL..."
    
    # Perform upload
    response=$(curl -s -L -f -H "Authorization: Token $PAPERLESS_TOKEN" \
          -F "document=@$file_path" \
          "${PAPERLESS_URL}api/documents/post_document/")
    
    local exit_code=$?
    if [ $exit_code -eq 0 ]; then
        if [ "$API_UPLOADER_ON_SUCCESS" = "archive" ]; then
            local dest_path="$ARCHIVE_DIR/$(date +%Y-%m-%d_%H-%M-%S)_$file_name"
            echo "Successfully uploaded $file_name. Moving to $dest_path."
            mv "$file_path" "$dest_path"
        else
            echo "Successfully uploaded $file_name. Deleting local copy."
            rm "$file_path"
        fi
    else
        echo "Failed to upload $file_name (exit code: $exit_code). Will retry on next scan or change."
        echo "Response: $response"
    fi
}

# Initial scan for existing files
echo "Performing initial scan of $CONSUMPTION_DIR..."
find "$CONSUMPTION_DIR" -maxdepth 1 -type f | while read -r file; do
    upload_file "$file"
done

if [ "$API_UPLOADER_ONESHOT" = "true" ]; then
    echo "Oneshot mode: finished initial scan. Exiting..."
    # If running under s6-overlay, we should ideally trigger a halt, 
    # but for simplicity and compatibility with lightweight, we just exit here.
    # The entrypoint/run script can handle the rest.
    exit 0
fi

# Monitor for new files using inotifywait
echo "Setting up inotify watches on $CONSUMPTION_DIR..."
exec inotifywait -m -e close_write -e moved_to --format '%w%f' "$CONSUMPTION_DIR" | while read -r file; do
    echo "Detected change on $file"
    if [ -f "$file" ]; then
        # Small delay to ensure file is fully written/settled
        sleep 1
        upload_file "$file"
    fi
done
