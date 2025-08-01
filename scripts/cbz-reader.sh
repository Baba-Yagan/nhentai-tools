#!/bin/bash

# Check if file argument is provided
if [ $# -eq 0 ]; then
    echo "Usage: $0 <archive-file>"
    echo "Example: $0 'my-comic.cbz' or $0 'my-comic.zip'"
    exit 1
fi

archive_file="$1"

# Check if file exists
if [ ! -f "$archive_file" ]; then
    echo "Error: File '$archive_file' not found"
    exit 1
fi

temp_dir="/tmp/$(pwgen 10 1)"
mkdir -p "$temp_dir" || exit 1
/home/user/.local/bin/ratarmount "$archive_file" "$temp_dir"

# Trap errors and exit to always cleanup
trap '/home/user/.local/bin/ratarmount -u "$temp_dir"; rm -rf "$temp_dir"; exit 1' ERR INT TERM EXIT

ls "$temp_dir"

#  (Insert your image processing/display code here)
# Use mapfile to properly handle filenames with spaces
mapfile -t -d '' images < <(find "$temp_dir" -type f \( -iname "*.jpg" -o -iname "*.jpeg" -o -iname "*.jxl" -o -iname "*.png" -o -iname "*.gif" -o -iname "*.bmp" -o -iname "*.webp" -o -iname "*.tiff" -o -iname "*.tif" -o -iname "*.svg" \) -print0 | sort -z -V)
feh --zoom max "${images[@]}"

/home/user/.local/bin/ratarmount -u "$temp_dir"
rm -rf "$temp_dir"

# Remove trap after successful execution, or on error it will execute twice
trap - ERR INT TERM EXIT
