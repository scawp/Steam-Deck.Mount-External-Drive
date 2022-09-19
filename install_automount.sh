#!/bin/bash
#Steam Deck Mount External Drive by scawp
#License: DBAD: https://github.com/scawp/Steam-Deck.Mount-External-Drive/blob/main/LICENSE.md
#Source: https://github.com/scawp/Steam-Deck.Mount-External-Drive
# Use at own Risk!

script_dir="$(dirname $(realpath "$0"))"
lib_dir="$script_dir/lib"
rules_install_dir="/etc/udev/rules.d"
service_install_dir="/etc/systemd/system"
script_install_dir="/home/deck/.local/share/scawp"

device_name="$(uname --nodename)"
user="$(id -u deck)"

if [ "$device_name" != "steamdeck" ] || [ "$user" != "1000" ]; then
  echo -en "This code has been written specifically for the Steam Deck with user Deck \
  \nIt appears you are running on a different system/non-standard configuration. \
  \nAre you sure you want to continue? (y/n) :"
  read confirm
  if [ "$confirm" != "y" ]; then
    echo "bye then! xxx"
    exit 1;
  fi
fi

echo -en "Read https://github.com/scawp/Steam-Deck.Mount-External-Drive before proceeding. \
\nDo you want to install the Auto-Mount Service? (y/n) :"
read confirm
if [ "$confirm" != "y" ]; then
  echo "bye then! xxx"
  exit 0;
fi

echo "Making script folder $script_install_dir"
mkdir -p "$script_install_dir"

echo "Copying $script_dir/automount.sh to $script_install_dir/automount.sh"
sudo cp "$script_dir/automount.sh" "$script_install_dir/automount.sh"

echo "Adding Execute and Removing Write Permissions"
sudo chmod 555 $script_install_dir/automount.sh

echo "Copying $lib_dir/99-external-drive-mount.rules to $rules_install_dir/99-external-drive-mount.rules"
sudo cp "$lib_dir/99-external-drive-mount.rules" "$rules_install_dir/99-external-drive-mount.rules"

sed -e "s&\[AUTOMOUNTSCRIPT\]&$script_install_dir&g" "$lib_dir/template.service" > "$lib_dir/external-drive-mount@.service"

echo "Copying $lib_dir/external-drive-mount@.service to $service_install_dir/external-drive-mount@.service"
sudo cp "$lib_dir/external-drive-mount@.service" "$service_install_dir/external-drive-mount@.service"

echo "Reloading Services"
sudo udevadm control --reload
sudo systemctl daemon-reload

echo "Done."
