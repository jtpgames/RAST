#!/bin/bash

# Define source and target directories
source_dir="Extracted_Workload"
target_dir="../../locust_scripts/GS Production Workload"

cp -v "$source_dir/Request_Names.log" "$target_dir/All_Request_Names.log"

# Iterate over each log file in the source directory
for file in "$source_dir"/Requests_per_time_unit_*.log; do
    # Extract the date part from the filename
    date=$(echo "$file" | grep -oP '\d{4}-\d{2}-\d{2}')

    # Construct the new filename
    new_filename="Requests_without_alarms_$date.log"

    # Copy and rename the file to the target directory
    cp "$file" "$target_dir/$new_filename"
done
