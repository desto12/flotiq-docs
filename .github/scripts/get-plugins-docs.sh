#!/bin/bash
env
echo ${{vars.SOURCE_EDITOR_URL}}
# URL that returns the list of files
if [ -z "$SOURCE_EDITOR_URL" ]; then
    echo "Variable SOURCE_EDITOR_URL not found"
    exit 1
else
    echo "Found env with source editor url!"
fi

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
sed -i '' 's/^[[:space:]]*#/#/' "$INDEX_FILE"

# Extract the file names in reverse order
FILES=$(grep -o '\(.*\)' "$INDEX_FILE" | awk -F '[()]' '{print $2}' | sed 's/\.\/\([^\/]*\)/\1/' | tr ' ' '\n' | tail -r | awk '{a[NR]=$0} END {for (i=NR; i>0;i--) print a[i]}' | xargs)
# Loop through each file name and process them
INDENT=`grep -E '\s*- Plugins API Reference' $PROJECT_DIR/mkdocs.yml | grep -Eo '^\s*'`

START_PLUGINS_NAV_PATTERN="# START_PLUGINS_FILES"
END_PLUGINS_NAV_PATTERN="# END_PLUGINS_FILES"
echo "test1"
sed -i '' -e "/$START_PLUGINS_NAV_PATTERN/,/$END_PLUGINS_NAV_PATTERN/{ /$START_PLUGINS_NAV_PATTERN/{n; d;}; /$END_PLUGINS_NAV_PATTERN/d; }" "$PROJECT_DIR/mkdocs.yml"
for FILE in $FILES; do
    # Delete divs and TOCs
    echo "test2"
    sed -i 's/<div /<div markdown="1"/g' "$MD_FILES_DIRECTORY/$FILE"
    echo "test3"
    sed -i 's#.docs/public/#../#g' "$MD_FILES_DIRECTORY/$FILE"
    echo "test4"
    sed -i '/\[\[_TOC_\]\]/d' "$MD_FILES_DIRECTORY/$FILE"
    echo "test5"
    HEADER=$(grep -m 1 '^# ' "$MD_FILES_DIRECTORY/$FILE" | awk -F 'Reference:' '{print $2}' | awk '{$1=$1};1')
    if [ -z "$HEADER" ]; then
        echo "Header is empty."
    else
        # New content to insert
        LINE="${INDENT}  - '$HEADER': plugins/PluginDocs/$FILE"
        echo "test6"
        sed -i '' -e "/# START_PLUGINS_FILES/a\\$LINE" "$PROJECT_DIR/mkdocs.yml"
    fi
done
