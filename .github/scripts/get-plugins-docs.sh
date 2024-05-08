#!/bin/bash

# URL that returns the list of files
SITE_URL="https://flotiq-frontend-965-feature-24617-res-j1km42.dev.cdwv.pl"
FILES_LIST_URL="$SITE_URL/markdown-docs/files.txt"
PROJECT_DIR="."
echo "URL: $FILES_LIST_URL"
# Destination directory where files will be saved
DESTINATION_DIR="$PROJECT_DIR/docs/plugins"

# Fetch the list of files
FILES=$(curl -s "$FILES_LIST_URL" $FILES_LIST_URL| grep 'PluginDocs')

# Create destination directory if it doesn't exist
mkdir -p "$DESTINATION_DIR"

while IFS= read -r FILE; do
    # Skip empty lines
    if [ -z "$FILE" ]; then
        continue
    fi
    # Create parent directories if they don't exist
    PARENT_DIR=$(dirname "$FILE")
    mkdir -p "$DESTINATION_DIR/$PARENT_DIR"

    # Download the file
    echo "Downloading $FILE..."
    curl -s -o "$DESTINATION_DIR/$FILE" "$SITE_URL/markdown-docs/$FILE"
done <<<"$FILES"

# Directory with Plugins API Reference .md files
MD_FILES_DIRECTORY="$DESTINATION_DIR/PluginDocs"

# File with section ordered list
INDEX_FILE="$MD_FILES_DIRECTORY/index.md"
# Delete spaces before markdown code
sed -i 's/^\s*#/#/' "$INDEX_FILE"

# Extract the file names in reverse order
FILES=$(grep -o '\(.*\)' "$INDEX_FILE" | awk -F '[()]' '{print $2}' | sed 's/\.\/\([^\/]*\)/\1/' | tr ' ' '\n' | tac | xargs)
# Loop through each file name and process them
for FILE in $FILES; do
    # Delete divs and TOCs
    sed -i '/^<div/d; /<\/div>$/d' "$MD_FILES_DIRECTORY/$FILE"
    sed -i '/\[\[_TOC_\]\]/d' "$MD_FILES_DIRECTORY/$FILE"
    HEADER=$(grep -m 1 '^# ' "$MD_FILES_DIRECTORY/$FILE" | awk -F 'Reference:' '{print $2}' | awk '{$1=$1};1')
    if [ -z "$HEADER" ]; then
        echo "Header is empty."
    else
        # New content to insert
        LINE="      - '$HEADER': plugins/PluginDocs/$FILE"
        sed -i '/- Plugins API Reference/a\'"$LINE" $PROJECT_DIR/mkdocs.yml
        sed -i '/- '\''plugins-section-placeholder'\'': '\''#'\''/d' "$PROJECT_DIR/mkdocs.yml"

    fi
done