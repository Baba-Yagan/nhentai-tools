#!/bin/bash

# lf preview script for CBZ files (and other file types)

# Configuration:
TMP_DIR="/tmp/lf_preview"  # Temporary directory for image extraction

# Get terminal size - lf might pass width/height as $2 and $3
if [[ -n "$2" && -n "$3" ]]; then
  TERM_WIDTH="$2"
  TERM_HEIGHT="$3"
else
  TERM_WIDTH=$(tput cols 2>/dev/null || echo "24")
  TERM_HEIGHT=$(tput lines 2>/dev/null || echo "80")
fi

# hardcode overwrite
TERM_WIDTH=60
TERM_HEIGHT=159

# Reserve some lines for text output (filename, etc)
PREVIEW_HEIGHT=$((TERM_HEIGHT - 8))


# Check which image-to-text converter is available
if command -v chafa >/dev/null 2>&1; then
  IMGCAT="chafa --size=${TERM_WIDTH}x${PREVIEW_HEIGHT} --animate=off"
elif command -v img2txt >/dev/null 2>&1; then
  IMGCAT="img2txt --width=${TERM_WIDTH} --height=${PREVIEW_HEIGHT}"
elif command -v jp2a >/dev/null 2>&1; then
  IMGCAT="jp2a --width=${TERM_WIDTH} --height=${PREVIEW_HEIGHT}"
else
  IMGCAT=""
fi

# Function to display images using a fallback method if needed
display_image() {
  if [[ -n "$IMGCAT" ]]; then
    eval "$IMGCAT" "$1"
  else
    echo "No ASCII image viewer found (chafa/img2txt/jp2a). Install one for image previews."
    echo "Try: sudo apt install chafa caca-utils jp2a"
  fi
}

# Function to extract and display ComicInfo.xml metadata
display_comic_info() {
  local filename="$1"

  # Check if ComicInfo.xml exists in the CBZ
  if unzip -l "$filename" | grep -q "ComicInfo.xml"; then
    # Extract ComicInfo.xml to temp directory
    unzip -j -o "$filename" "ComicInfo.xml" -d "$TMP_DIR" > /dev/null 2>&1

    if [[ -f "$TMP_DIR/ComicInfo.xml" ]]; then
      # Parse and display key information
      local title
      local writer
      local year
      local pages
      local tags
      title=$(grep -o '<Title>[^<]*</Title>' "$TMP_DIR/ComicInfo.xml" | sed 's/<[^>]*>//g')
      writer=$(grep -o '<Writer>[^<]*</Writer>' "$TMP_DIR/ComicInfo.xml" | sed 's/<[^>]*>//g')
      year=$(grep -o '<Year>[^<]*</Year>' "$TMP_DIR/ComicInfo.xml" | sed 's/<[^>]*>//g')
      pages=$(grep -o '<PageCount>[^<]*</PageCount>' "$TMP_DIR/ComicInfo.xml" | sed 's/<[^>]*>//g')
      tags=$(grep -o '<Tags>[^<]*</Tags>' "$TMP_DIR/ComicInfo.xml" | sed 's/<[^>]*>//g')

      echo "📚 $(basename "$filename")"
      [[ -n "$title" ]] && echo "Title: $title"
      [[ -n "$writer" ]] && echo "Writer: $writer"
      [[ -n "$year" ]] && echo "Year: $year"
      [[ -n "$pages" ]] && echo "Pages: $pages"
      [[ -n "$tags" ]] && echo "Tags: ${tags:0:60}..." # Truncate long tags
      echo ""
    fi
  fi
}

# Create the temporary directory if it doesn't exist
mkdir -p "$TMP_DIR"

# Check if the file is a CBZ archive
if [[ "$1" == *.cbz ]]; then
  filename="$1"

  # Clear the temporary directory
  rm -rf "${TMP_DIR:?}"/*

  # Display comic info first
  display_comic_info "$filename"

  # List all images in the CBZ file and sort them properly (handles 1, 001, etc.)
  mapfile -t images < <(7z l -slt "$filename" | grep "^Path = " | sed 's/^Path = //' | grep -iE '\.(jpg|jpeg|jxl|png|gif|bmp|webp|tiff|tif|svg)$' | sort -V)

  if [[ ${#images[@]} -gt 0 ]]; then
    first_image="${images[0]}"

    # Extract only the first image
    if 7z e "$filename" "$first_image" -o"$TMP_DIR" -y > /dev/null 2>&1; then
      # Get just the filename without path for the extracted file
      extracted_filename=$(basename "$first_image")
      extracted_path="$TMP_DIR/$extracted_filename"

      # Check if file was actually extracted
      if [[ -f "$extracted_path" ]]; then
        display_image "$extracted_path"
      else
        echo "Failed to extract image: $first_image"
        echo "CBZ file: $(basename "$filename")"
      fi
    else
      echo "Failed to extract from CBZ"
      echo "CBZ file: $(basename "$filename")"
    fi
  else
    echo "No images found in CBZ"
    echo "CBZ file: $(basename "$filename")"
  fi
elif [[ -f "$1" ]]; then
  # display other file types using bat
  bat --color="always" --style="plain" --wrap="character" "$1"
else
  echo "File not found: $1"
fi

# Don't clean up immediately - let the image display first
# The temp files will be cleaned up on next run
