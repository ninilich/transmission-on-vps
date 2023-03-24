#!/bin/bash

# check if user is root
if [[ $(id -u) -ne 0 ]]; then
   echo "This script must be run as root."
   exit 1
fi

# check if the number of arguments passed is correct
if [ $# -ne 2 ]; then
    echo "Usage: $0 <user_name> <password>"
    exit 1
fi

user_name=$1
password=$2

# add user
adduser "$user_name" --disabled-password --gecos "" --force-badname || exit 1

# create downloads directory
mkdir "/home/$user_name/downloads" || exit 1

# update apt repositories
apt update || exit 1

# install transmission-daemon
apt install transmission-daemon -y || exit 1

# stop transmission-daemon service
service transmission-daemon stop || exit 1

# modify settings.json file
settings_file="/etc/transmission-daemon/settings.json"
if [ -f "$settings_file" ]; then
    sed -i "s#\"download-dir\": \"/var/lib/transmission-daemon/downloads\"#\"download-dir\": \"/home/$user_name/downloads\"#" "$settings_file"
    sed -i "s/\"rpc-enabled\": false/\"rpc-enabled\": true/" "$settings_file"
    sed -i "s/\"rpc-password\": \".*\"/\"rpc-password\": \"$password\"/" "$settings_file"
    sed -i "s/\"rpc-username\": \".*\"/\"rpc-username\": \"$user_name\"/" "$settings_file"
    sed -i "s/\"rpc-whitelist-enabled\": true/\"rpc-whitelist-enabled\": false/" "$settings_file"
fi

# start transmission-daemon service
service transmission-daemon start || exit 1

echo "Transmission daemon installed and configured successfully!"
