#!/bin/bash

#      .o8                      oooo                           oooooooooo.                 .                  oooooooooo.                      oooo                               .o. 
#     "888                      `888                           `888'   `Y8b              .o8                  `888'   `Y8b                     `888                               888 
# .oooo888   .ooooo.   .ooooo.   888  oooo   .ooooo.  oooo d8b  888      888  .oooo.   .o888oo  .oooo.         888     888  .oooo.    .ooooo.   888  oooo  oooo  oooo  oo.ooooo.  888 
#d88' `888  d88' `88b d88' `"Y8  888 .8P'   d88' `88b `888""8P  888      888 `P  )88b    888   `P  )88b        888oooo888' `P  )88b  d88' `"Y8  888 .8P'   `888  `888   888' `88b Y8P 
#888   888  888   888 888        888888.    888ooo888  888      888      888  .oP"888    888    .oP"888        888    `88b  .oP"888  888        888888.     888   888   888   888 `8' 
#888   888  888   888 888   .o8  888 `88b.  888    .o  888      888     d88' d8(  888    888 . d8(  888        888    .88P d8(  888  888   .o8  888 `88b.   888   888   888   888 .o. 
#Y8bod88P" `Y8bod8P' `Y8bod8P' o888o o888o `Y8bod8P' d888b    o888bood8P'   `Y888""8o   "888" `Y888""8o      o888bood8P'  `Y888""8o `Y8bod8P' o888o o888o  `V88V"V8P'  888bod8P' Y8P 
#                                                                                                                                                                       888           
#                                                                                                                                                                      o888o                                                                                                                                                                                               
# Author: Trevor Edwards
# Description: I have all of my Docker data stored in a root directory called dockerData. 
# This script compresses that folder into an archive, names it, and uploads it to my NAS as a local backup.

# Variables:

# Get the current date in the format YYYY-MM-DD
current_date=$(date +"%Y-%m-%d")

# Define the source and exclusion locations, as well as archive name
source_folder="/path/to/dockerData/"
exclusion_folder="???" # ex: I exclude Plex because there's like 20gb of metadata that I don't really care about backing up...
output_archive="$current_date-dockerData-bkup.7z"

# Network share variables
smb_user="USERNAME"
smb_password="PASSWORD"
smb_ip="IP_ADDR"
smb_share="SHARE_NAME"
archive_to_upload="./$current_date-dockerData-bkup.7z"

# Move to source folder
cd "$source_folder" || exit

# Create a temporary directory to stage files
mkdir -p "/random/path/temp"
temp_dir="/random/path/temp"

# Copy all files and folders (except the exclusion folder) to temporary directory
rsync -av --exclude="$exclusion_folder" . "$temp_dir"

# Archive contents of temporary directory
# note - requires: apt install p7zip-full
7z a "$output_archive" "$temp_dir"

# Remove temporary directory
rm -r "$temp_dir"

echo "Archive created: $output_archive"

echo "Proceeding with SMB connection & upload..."

# Connect to the SMB share and upload the file
# note - requires: apt install smbclient
smbclient "//$smb_ip/$smb_share" -U "$smb_user%$smb_password" -c "put $archive_to_upload"

echo "Standby..."

sleep 5

# Perform check if the upload was successful
if [ $? -eq 0 ]; then
    echo "File uploaded successfully."

    # Delete the original file
    rm "$archive_to_upload"
    echo "Original file deleted."
else
    echo "Error: Failed to upload file."
fi
