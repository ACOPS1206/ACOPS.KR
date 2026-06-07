#!/bin/bash

# Check if a URL was provided as an argument
if [ -z "$1" ]; then
    echo "Usage: $0 <URL>"
    echo "Example: $0 https://benisland.neocities.org/petpet/"
    exit 1
fi

BASE_URL="$1"

# Ensure the URL ends with a slash for proper path concatenation
if [[ "${BASE_URL: -1}" != "/" ]]; then
    BASE_URL="${BASE_URL}/"
fi

# Extract the domain name to use as the save directory
SAVE_DIR=$(echo "$BASE_URL" | awk -F/ '{print $3}')

# Fallback directory name if extraction fails
if [ -z "$SAVE_DIR" ]; then
    SAVE_DIR="crawled_site"
fi

USER_AGENT="Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36"

echo "Creating directory: $SAVE_DIR"
mkdir -p "$SAVE_DIR"
cd "$SAVE_DIR" || exit

echo "Downloading index.html from $BASE_URL..."
curl -s -A "$USER_AGENT" -o "index.html" "$BASE_URL"

# Check if index.html was downloaded successfully
if [ ! -s "index.html" ]; then
    echo "Error: Failed to download index.html or the file is empty."
    exit 1
fi

echo "Extracting and downloading assets..."

# Parse the HTML, extract links, and download them
cat index.html | grep -Eo '(src|href)=["'"'"'][^"'"'"']+["'"'"']' | awk -F'["'"'"']' '{print $2}' | sort -u | while read -r link; do

    # Skip absolute URLs (http, //), empty lines, anchors (#), and data URIs
    if [[ "$link" == http* ]] || [[ "$link" == //* ]] || [[ "$link" == \#* ]] || [[ -z "$link" ]] || [[ "$link" == "data:"* ]]; then
        continue
    fi

    # Remove leading slash to prevent writing to root filesystem
    clean_link="${link#/}"

    # Create the necessary local directory structure
    dir_name=$(dirname "$clean_link")
    if [ "$dir_name" != "." ]; then
        mkdir -p "$dir_name"
    fi

    echo "Downloading: $clean_link"
    curl -s -A "$USER_AGENT" -o "$clean_link" "${BASE_URL}${clean_link}"

done

echo "Crawling completed successfully."
