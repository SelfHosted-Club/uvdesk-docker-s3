#!/bin/bash

# Define the source directory on the local system
source_dir="/var/www/uvdesk/public/assets/"

# Function to copy file or directory to S3
copy_to_minio() {
    sleep 15
    local path=$1
    local target_file="${path#${source_dir}}"
    target_file=$(echo "$target_file" | sed 's/^\///')  # Remove leading slash
    target_file=$(echo "$target_file" | sed 's/\/\//\//g')  # Remove additional slashes
    timestamp=$(date +"%Y-%m-%d %T")
    log_line="[$timestamp] Copying $path to S3..."
    echo "$log_line" >> /var/log/s3_sync.log
    echo "Target file: $target_file"
    mc cp "$path" "S3/$S3_BUCKET/$target_file"
}

# Function to remove file from S3
remove_from_minio() {
    local path=$1
    local target_file="${path#${source_dir}}"
    target_file=$(echo "$target_file" | sed 's/^\///')  # Remove leading slash
    target_file=$(echo "$target_file" | sed 's/\/\//\//g')  # Remove additional slashes
    timestamp=$(date +"%Y-%m-%d %T")
    log_line="[$timestamp] Removing $target_file from S3..."
    echo "$log_line" >> /var/log/s3_sync.log
    mc rm "S3/$S3_BUCKET/$target_file"
}

# Start inotifywait to monitor directory events
inotifywait -m -r -e moved_to,create,modify,delete "$source_dir" |
    while read -r directory event filename; do
        if [[ "$event" == "CREATE" || "$event" == "MODIFY" || "$event" == "CLOSE_WRITE" || "$event" == "MOVED_TO" ]]; then
            # File or directory created or modified, copy it to S3
            path="$directory/$filename"
            copy_to_minio "$path"
        elif [[ "$event" == "DELETE" ]]; then
            # File or directory deleted, remove it from S3
            path="$directory/$filename"
            remove_from_minio "$path"
        fi
    done