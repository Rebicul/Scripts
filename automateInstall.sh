#!/bin/bash

# Check if 'scripts' folder exists in /usr/local/sbin directory
if [ -d "/usr/local/sbin/scripts" ]; then
    echo "'scripts' folder exists, changing directory to it..."
    cd /usr/local/sbin/scripts
else
    echo "'scripts' folder does not exist, creating it..."
    mkdir /usr/local/sbin/scripts
    cd /usr/local/sbin/scripts
fi

# cURL clearVarLogs.sh from GitHub and make it executable
curl -O https://raw.githubusercontent.com/Rebicul/Scripts/master/clearVarLogs.sh
chmod +x clearVarLogs.sh

# Create a cron job to run the script on Sundays at 6 p.m.
(crontab -l ; echo "0 18 * * 0 /usr/local/sbin/scripts/your_file.sh") | crontab -
echo "Cron job added to run your_file.sh on Sundays at 6 p.m."

### Compare findmnt -T /[folder] output could be another way to identify /var/log. 

# Run df -h and grep for "/var*"
df_output=$(df -h | grep "/var*")

# Count the number of lines in the output
line_count=$(echo "$df_output" | wc -l)

if [ "$line_count" -gt 1 ]; then
    # If more than one line is returned, find the line with "/var/log" and grab its usage
    var_usage=$(echo "$df_output" | grep "/var/log$" | awk '{print $5}' | sed 's/%//')
    echo "Disk usage for /var/log is $var_log_usage%."
else
    # If only one line is returned, get the usage for /var
    var_usage=$(echo "$df_output" | awk '{print $5}' | sed 's/%//')
    echo "Disk usage for /var is $var_usage%."
fi

threshold=97

if [ "$var_usage" -ge "$threshold" ]; then
    echo "Disk usage for /var is above the threshold of $threshold%. Moving a few files into your home directory."
    
    # Prompt the user for their username
    read -p "Enter your username (e.g., luciano.bernal): " username

    # Validate that the username is not empty
    if [ -z "$username" ]; then
        echo "Username cannot be empty. Exiting."
        exit 1
    fi

    # Find files greater than 50M sorted in descending order in /var/log that haven't been modified today.
    files_to_move=$(find /var/log -type f -size +50M -mtime +0 ! -name 'lastlog' -exec ls -lSh {} +)
    
    # Create an associative array to store original paths
    declare -A original_paths

    # Get the first two files from the sorted list and store their original paths
    first_two_files=$(echo "$files_to_move" | head -n 2)
    while read -r file; do
        original_paths["$file"]=$(dirname "$file")
    done <<< "$first_two_files"

    # Run clearVarLogs.sh located in /usr/local/sbin/scripts
    if [ -f "/usr/local/sbin/scripts/clearVarLogs.sh" ]; then
        ./usr/local/sbin/scripts/clearVarLogs.sh
    else
        echo "clearVarLogs.sh not found in /usr/local/sbin/scripts."
        exit 1
    fi

    # Move the first two files back to their original directories
    for file in "${!original_paths[@]}"; do
        original_dir="${original_paths[$file]}"
        mv "$file" "$original_dir/"
    done

    # Run clearVarLogs.sh again to modify files that were not in the /var/log previously
    if [ -f "/usr/local/sbin/scripts/clearVarLogs.sh" ]; then
        ./usr/local/sbin/scripts/clearVarLogs.sh
    else
        echo "clearVarLogs.sh not found in /usr/local/sbin/scripts."
        exit 1
    fi

    echo "Operation completed."

else
    echo "Disk usage for /var is within the threshold of $threshold%. Running the script now..."
    
    # Run clearVarLogs.sh located in /usr/local/sbin/scripts
    if [ -f "/usr/local/sbin/scripts/clearVarLogs.sh" ]; then
        /usr/local/sbin/scripts/clearVarLogs.sh
    else
        echo "clearVarLogs.sh not found in /usr/local/sbin/scripts."
        exit 1
    fi
fi