#!/bin/bash
#Steam Deck Mount External Drive by scawp
#License: DBAD: https://github.com/scawp/Steam-Deck.Mount-External-Drive/blob/main/LICENSE.md
#Source: https://github.com/scawp/Steam-Deck.Mount-External-Drive
# Use at own Risk!

#curl -sSL https://raw.githubusercontent.com/scawp/Steam-Deck.Mount-External-Drive/Quick-Auto-Mount-WIP/curl_install.sh | bash

#stop running script if anything returns an error (non-zero exit )
set -e

repo_url="https://raw.githubusercontent.com/scawp/Steam-Deck.Mount-External-Drive/Quick-Auto-Mount-WIP"
repo_lib_dir="$repo_url/lib"

tmp_dir="/tmp/scawp"

rules_install_dir="/etc/udev/rules.d"
service_install_dir="/etc/systemd/system"
script_install_dir="/home/deck/.local/share/scawp"

device_name="$(uname --nodename)"
user="$(id -u deck)"

if [ "$device_name" != "steamdeck" ] || [ "$user" != "1000" ]; then
  zenity --question --width=400 \
  --text="This code has been written specifically for the Steam Deck with user Deck \
  \nIt appears you are running on a different system/non-standard configuration. \
  \nAre you sure you want to continue?"
  if [ "$?" != 0 ]; then
    #NOTE: This code will never be reached due to "set -e", the system will already exit for us but just incase keep this
    echo "bye then! xxx"
    exit 1;
  fi
fi

zenity --question --width=400 \
  --text="Read $repo_url/README.md before proceeding. \
\nDo you want to install the Auto-Mount Service?"
if [ "$?" != 0 ]; then
  #NOTE: This code will never be reached due to "set -e", the system will already exit for us but just incase keep this
  echo "bye then! xxx"
  exit 0;
fi

echo "Making tmp folder $tmp_dir"
mkdir -p "$tmp_dir"

echo "Downloading Required Files"
curl -o "$tmp_dir/automount.sh" "$repo_url/automount.sh"
curl -o "$tmp_dir/template.service" "$repo_lib_dir/template.service"
curl -o "$tmp_dir/99-external-drive-mount.rules" "$repo_lib_dir/99-external-drive-mount.rules"

echo "Making script folder $script_install_dir"
mkdir -p "$script_install_dir"

echo "Copying $tmp_dir/automount.sh to $script_install_dir/automount.sh"
sudo cp "$tmp_dir/automount.sh" "$script_install_dir/automount.sh"

echo "Adding Execute and Removing Write Permissions"
sudo chmod 555 $script_install_dir/automount.sh

echo "Copying $tmp_dir/99-external-drive-mount.rules to $rules_install_dir/99-external-drive-mount.rules"
sudo cp "$tmp_dir/99-external-drive-mount.rules" "$rules_install_dir/99-external-drive-mount.rules"

sed -e "s&\[AUTOMOUNTSCRIPT\]&$script_install_dir&g" "$tmp_dir/template.service" > "$tmp_dir/external-drive-mount@.service"

echo "Copying $tmp_dir/external-drive-mount@.service to $service_install_dir/external-drive-mount@.service"
sudo cp "$tmp_dir/external-drive-mount@.service" "$service_install_dir/external-drive-mount@.service"

echo "Reloading Services"
sudo udevadm control --reload
sudo systemctl daemon-reload

echo "Done."
