#!/bin/bash
#
# Ubuntu post-install script
#
# Author:
# Trevor Edwards
#
# Description:
# Simple post-installation script for Ubuntu
#
# Based on David Brien's[0] <mr.brien@gmail.com> script, which in turn was based on scripts by the following:
# snwh[1] , ravishi[2] , and rougeth[3] scripts.
#
# [0] - https://github.com/Traceabl3/ubuntu-post-installer
# [1] - https://github.com/snwh/ubuntu-post-install/
# [2] - https://gist.github.com/ravishi/3706813s
# [3] - https://gist.github.com/rougeth/ubuntu-post-install.sh

echo '------------------------------------------------------------------------'
echo '=> Ubuntu 20.04 Post-Install Configuration Script'
echo '------------------------------------------------------------------------'

# -----------------------------------------------------------------------------
# => Pre-Work System Configurations
# -----------------------------------------------------------------------------
echo '=> Pre-Work System Configurations'

# Creates root cron job to run the dockerData backup script @ 3am every day:
# https://github.com/trevoedwards/ShellScripts/blob/main/dockerDatabkup.sh
echo "0 3 * * * root /path/to/dockerData/dockerDatabkup.sh" | tee -a /etc/crontab

# Add Docker's official GPG key:
apt-get install ca-certificates curl
install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
chmod a+r /etc/apt/keyrings/docker.asc

# Add the repository to Apt sources:
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu \
  $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
  tee /etc/apt/sources.list.d/docker.list > /dev/null

# -----------------------------------------------------------------------------
# => System update/upgrade
# -----------------------------------------------------------------------------
echo '=> Updating...'
apt-get update
echo '=> DONE <='
echo '=> Upgrading'
apt-get upgrade
echo '=> DONE <='
echo '=> Cleaning Up Unused Packages'
apt autoclean && apt autoremove
echo '=> DONE <='

# -----------------------------------------------------------------------------
# => Install Core Applications
# -----------------------------------------------------------------------------
echo '=> Installing Core Applications...'
apt install k3b -y
apt install net-tools -y
apt install lm-sensors -y
apt install glances -y
apt install smbclient -y
apt install p7zip-full -y
apt install p7zip-rar -y
apt install docker-ce -y
apt install docker-ce-cli -y
apt install containerd.io -y
apt install docker-buildx-plugin -y
apt install docker-compose-plugin -y
sleep 5
echo '=> DONE <='

# -----------------------------------------------------------------------------
# => Install snap
# -----------------------------------------------------------------------------
echo '=> Installing Snap...'
apt-get install snapd
echo '=> DONE <='

# -----------------------------------------------------------------------------
# => Install snap Applications
# -----------------------------------------------------------------------------
echo '=> Installing Snap Applications...'
snap install firefox 
snap install sublime-text --classic 
snap install code --classic
sleep 5
echo '=> DONE <='

# -----------------------------------------------------------------------------
# => Install flatpak 
# -----------------------------------------------------------------------------
echo '=> Installing Flatpak...'
apt install flatpak
flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo

# -----------------------------------------------------------------------------
# => Post-Work System Configurations
# -----------------------------------------------------------------------------
echo '=> Post-Work System Configurations'
echo 'Connecting to network share...'

# Get the current date in the format YYYY-MM-DD
current_date=$(date +"%Y-%m-%d")

# Network share variables
smb_user="USERNAME"
smb_password="PASSWORD"
smb_ip="IP_ADDR"
smb_share="SHARE_NAME"
archive_to_download="$current_date-dockerData-bkup.7z"
destination="/path/to/dockerData"
temp="/tmp/postinstall_temp"

# Connect to the SMB share download the dockerData archive
# note - requires: apt install smbclient
mkdir -p "${temp}"
echo 'Beginning download of dockerData files...'
smbclient "//$smb_ip/$smb_share" -U "$smb_user%$smb_password" -c "get $archive_to_download $temp/$archive_to_download"

sleep 5

# Check if the source archive file exists
if [ -e "$temp/${archive_to_download}" ]; then
    # Create the destination path if it doesn't exist
    mkdir -p "${destination}"
    # Extract the file to the destination path
    7z x "$temp/${archive_to_download}" -o"${destination}" 

    echo "Source archive was successfully copied using smbclient, extracted using 7zip, and all temporary contents have been removed."
else
    echo "Error: source archive file not found on file share."
fi

# Remove the temporary directory
rm -r "${temp}"
