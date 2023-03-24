#!/bin/bash
#!/bin/bash

# get the regular username
if [[ -z "${SUDO_USER}" ]]; then
  username=$(whoami)
else
  username=${SUDO_USER}
fi

# check if the number of arguments passed is correct
if [ $# -ne 2 ]; then
    echo "Usage: $0 <user_name> <user_password>"
    exit 1
fi

user_name=$1
user_password=$2

# add user to debian-transmission group
sudo usermod -a -G debian-transmission "$username" || exit 1

# create downloads directory if it doesn't exist
if [ ! -d "/home/$username/downloads" ]; then
    mkdir "/home/$username/downloads" || exit 1
else
    echo "Downloads directory already exists"
fi

# set the group ownership to debian-transmission and permissions to 770
sudo chgrp debian-transmission "/home/$username/downloads" || exit 1
sudo chmod 770 "/home/$username/downloads" || exit 1

# update umask to 002 in transmission settings
settings_file="/etc/transmission-daemon/settings.json"
if [ -f "$settings_file" ]; then
    sudo sed -i "s#\"download-dir\": \"/var/lib/transmission-daemon/downloads\"#\"download-dir\": \"/home/$username/downloads\"#" "$settings_file"
    sudo sed -i "s/\"rpc-enabled\": false/\"rpc-enabled\": true/" "$settings_file"
    sudo sed -i "s/\"rpc-password\": \".*\"/\"rpc-password\": \"$user_password\"/" "$settings_file"
    sudo sed -i "s/\"rpc-username\": \".*\"/\"rpc-username\": \"$user_name\"/" "$settings_file"
    sudo sed -i "s/\"rpc-whitelist-enabled\": true/\"rpc-whitelist-enabled\": false/" "$settings_file"
    sudo sed -i "s/\"umask\": 18/\"umask\": 2/" "$settings_file"
fi

# restart transmission-daemon service
sudo service transmission-daemon restart || exit 1

echo "Transmission setup completed successfully."
