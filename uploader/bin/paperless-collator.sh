#!/bin/bash

consumption_dir="${CONSUMPTION_DIR:-/consumption}"
collate_dir="${consumption_dir}/collate"
puid="${PUID:-1000}"
pgid="${PGID:-1000}"

if [ "$COLLATE_ENABLED" != "true" ]; then
    echo "Collate feature is disabled."
    exit 0
fi

# Ensure collate directory exists
mkdir -p "$collate_dir"
chown "${puid}:${pgid}" "$collate_dir"
chmod 775 "$collate_dir"

# Clear collate directory on startup
echo "Clearing collation directory: ${collate_dir}"
rm -f "${collate_dir}"/*.pdf

collate_files() {
    local files=("$@")
    if [ "${#files[@]}" -lt 2 ]; then
        return
    fi

    local file1="${files[0]}"
    local file2="${files[1]}"
    local base1=$(basename "$file1" .pdf)
    local output_file="${consumption_dir}/${base1}_collated.pdf"

    echo "Collating ${file1} and ${file2} into ${output_file}..."

    # Collate: interleave pages. 
    # File 1: fronts (1, 2, 3...)
    # File 2: backs in reverse order (3-back, 2-back, 1-back...)
    # qpdf syntax for interleaving: qpdf in.pdf --pages in.pdf 1-z file2.pdf z-1 -- out.pdf
    if qpdf "$file1" --pages . 1-z "$file2" z-1 --collate -- "$output_file"; then
        echo "Successfully collated. Deleting source files."
        rm "$file1" "$file2"
        chown "${puid}:${pgid}" "$output_file"
        chmod 664 "$output_file"
    else
        echo "Failed to collate ${file1} and ${file2}."
    fi
}

echo "Starting Paperless PDF Collator..."
echo "Monitoring: ${collate_dir}"

# Main loop using inotifywait
exec inotifywait -m -e close_write -e moved_to --format '%w%f' "$collate_dir" | while read -r file; do
    if [[ "$file" == *.pdf ]]; then
        # Small delay to ensure files are settled
        sleep 2
        
        # Get all PDFs in the collate directory, sorted alphabetically
        mapfile -t pdf_files < <(find "$collate_dir" -maxdepth 1 -name "*.pdf" -type f | sort)
        
        if [ "${#pdf_files[@]}" -ge 2 ]; then
            collate_files "${pdf_files[@]}"
        fi
    fi
done
