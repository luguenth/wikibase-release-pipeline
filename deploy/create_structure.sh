#!/bin/bash

# Check if the CSV file is provided as an argument
if [ "$#" -ne 1 ]; then
    echo "Usage: $0 <path_to_csv_file>"
    exit 1
fi

csv_file=$1

# Create the extensions directory if it doesn't exist
mkdir -p extensions

# Read the CSV file line by line, skipping the header
tail -n +2 "$csv_file" | while IFS=',' read -r type comment source path version custom_name
do
    # Determine the directory and file name
    if [ -z "$custom_name" ]; then
        name=$(basename "$source" .git)
    else
        name=$custom_name
    fi

    # Create directory inside the extensions folder
    mkdir -p "extensions/$name"

    # Create the PHP file
    touch "extensions/$name/$name.php"

    # Create the extension.json file with the JSON content
    cat > "extensions/$name/extension.json" <<EOF
{
    "type": "$type",
    "comment": "$comment",
    "source": "$source",
    "path": "$path",
    "version": "$version",
    "custom_name": "$custom_name"
}
EOF

done

echo "Directory structure and files have been created inside the 'extensions' folder."
