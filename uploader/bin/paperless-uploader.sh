#!/bin/bash

api_url="${PAPERLESS_URL:-}"
api_token="${PAPERLESS_TOKEN:-}"
runmode="inotify"
[ "$API_UPLOADER_ONESHOT" = "true" ] && runmode="oneshot"
consumption_dir="${CONSUMPTION_DIR:-$PWD}"
archive_dir="${ARCHIVE_DIR:-$PWD/archive}"
on_success="${API_UPLOADER_ON_SUCCESS:-archive}"
filter="${CONSUMPTION_FILTER:-}"

if [ -z "$api_url" ] || [ -z "$api_token" ]; then
    echo "ERROR: Missing paperless URL or paperless token, exiting."
    exit 1
fi

while [ $# -gt 0 ]; do
    case "$1" in
      --url=*) api_url="${1:6}";;
      --token=*) api_token="${1:8}";;
      --runmode=*) runmode="${1:10}";;
      --dir=*) consumption_dir="${1:6}";;
      --archive-dir=*) archive_dir="${1:14}";;
      --on-success=*) on_success="${1:13}";;
      --filter=*) filter="${1:9}";;
    esac
    shift
done

# Ensure trailing slash in the paperless URL
if [[ ! "$api_url" == */ ]]; then
    api_url="${api_url}/"
fi

echo "Starting Paperless API Uploader..."
echo "Endpoint: ${api_url}"
echo "Monitoring: ${consumption_dir} (${runmode})"
echo -n "On Success: ${on_success}" && ([ "$on_success" = "archive" ] && echo " (${archive_dir})" || echo)
echo "Filter: /${filter}/"

archive_inside_consumption=0
[ "$consumption_dir" = "${archive_dir:0:${#consumption_dir}}" ] && archive_inside_consumption=1

upload_file() {
    local file_path="$1"
    local file_name="$(basename "$file_path")"

    # Skip hidden files
    if [[ "$file_name" == .* ]]; then
        return 4
    fi

    # Skip archived files
    if [ "$archive_inside_consumption" -eq 1 ] && \
       [ "${file_path:0:${#archive_dir}}" = "$archive_dir" ]
    then
        return 4
    fi

    if [ -n "$filter" ]; then
        # Only consume files matching the filter
        if ! [[ "$file_name" =~ $filter ]]; then
            echo "${file_name} does not match /${filter}/, skipping."
            return 6
        fi
    fi

    echo "Uploading ${file_name}..."

    # Perform upload
    response=$(curl -s -L -f -H "Authorization: Token ${api_token}" \
          -F "document=@${file_path}" \
          "${api_url}api/documents/post_document/")

    local exit_code=$?
    if [ $exit_code -eq 0 ]; then
        if [ "$on_success" = "archive" ]; then
            local dest_path="${archive_dir}/$(date +%Y-%m-%d_%H-%M-%S)_${file_name}"
            echo "Successfully uploaded ${file_name}. Moving to ${dest_path}."
            mv "$file_path" "$dest_path"
        elif [ "$on_success" = "none" ]; then
            echo "Successfully uploaded ${file_name}. Leaving file in place (none mode)."
        else
            echo "Successfully uploaded ${file_name}. Deleting local copy."
            rm "$file_path"
        fi
    else
        echo "Failed to upload ${file_name} (exit code: ${exit_code}). Will retry on next scan or change."
        echo "Response: ${response}"
        return 1
    fi
}

# Initial scan for existing files
echo "Performing initial scan of ${consumption_dir}..."
skip_count=0
succ_count=0
err_count=0
count=0
find "$consumption_dir" -maxdepth 1 -type f | while read -r file; do
    upload_file "$file"
    ((count++))
    case $? in
      0) ((succ_count++));;
      1) ((err_count++));;
      4|6) ((skip_count++));;
    esac
done

echo "Scanned ${count} files: ${succ_count} success, ${skip_count} skipped, ${err_count} errors."

if [ "$runmode" = "oneshot" ]; then
    [ "$err_count" -gt 0 ] && exit 1
    exit 0
fi

# Monitor for new files using inotifywait
echo "Setting up inotify watches on ${consumption_dir}..."
exec inotifywait -m -e close_write -e moved_to --format '%w%f' "$consumption_dir" | while read -r file; do
    echo "Detected change on ${file}"
    if [ -f "$file" ]; then
        # Small delay to ensure file is fully written/settled
        sleep 1
        upload_file "$file"
    fi
done
