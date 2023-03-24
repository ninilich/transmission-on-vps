#!/bin/bash

# use this command to remove transmission-daemon
# sudo apt-get remove transmission-daemon --purge

# check if user is root
if [[ $(id -u) -ne 0 ]]; then
   echo "This script must be run as root."
   exit 1
fi

# get the regular username
if [[ -z "${SUDO_USER}" ]]; then
  regular_username=$(whoami)
else
  regular_username=${SUDO_USER}
fi

# check if the number of arguments passed is correct
if [ $# -ne 2 ]; then
    echo "Usage: $0 <user_name> <user_password>"
    exit 1
fi


user_name=$1
user_password=$2
download_dir=/home/transmission-downloads/

# create downloads directory if it doesn't exist
if [ ! -d "$download_dir" ]; then
    mkdir $download_dir || exit 1
else
    echo "Downloads directory already exists"
fi

# update apt repositories
apt update || exit 1

# install transmission-daemon
apt install transmission-daemon -y || exit 1

# stop transmission-daemon service
service transmission-daemon stop || exit 1

# modify settings.json file
settings_file="/etc/transmission-daemon/settings.json"
if [ -f "$settings_file" ]; then
    sed -i "s#\"download-dir\": \"/var/lib/transmission-daemon/downloads\"#\"download-dir\": \"$download_dir\"#" "$settings_file"
    sed -i "s/\"rpc-enabled\": false/\"rpc-enabled\": true/" "$settings_file"
    sed -i "s/\"rpc-password\": \".*\"/\"rpc-password\": \"$user_password\"/" "$settings_file"
    sed -i "s/\"rpc-username\": \".*\"/\"rpc-username\": \"$user_name\"/" "$settings_file"
    sed -i "s/\"rpc-whitelist-enabled\": true/\"rpc-whitelist-enabled\": false/" "$settings_file"
    sed -i "s/\"umask\": 18/\"umask\": 2/" "$settings_file"
fi

sudo usermod -a -G debian-transmission $regular_username
sudo chgrp debian-transmission $download_dir
sudo chmod 770 $download_dir


# start transmission-daemon service
service transmission-daemon start || exit 1

echo "Transmission setup completed successfully."
echo "You need to restart your machine to apply some changes."
