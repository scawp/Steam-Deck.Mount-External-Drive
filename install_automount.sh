#!/bin/bash
#Steam Deck Mount External Drive by scawp
#License: DBAD: https://github.com/scawp/Steam-Deck.Mount-External-Drive/blob/main/LICENSE.md
#Source: https://github.com/scawp/Steam-Deck.Mount-External-Drive
# Use at own Risk!

script_dir="$(dirname $(realpath "$0"))"
lib_dir="$script_dir/lib"
#rules_install_dir="/etc/udev/rules.d"
#service_install_dir="/home/deck/.local/share/systemd/user";mkdir -p $service_install_dir

#TEST
rules_install_dir="$script_dir/test/rules";mkdir -p $rules_install_dir
service_install_dir="$script_dir/test/service";mkdir -p $service_install_dir

sudo cp "$lib_dir/99-external-drive-mount.rules" "$rules_install_dir/99-external-drive-mount.rules"

sed -e "s&\[AUTOMOUNTSCRIPT\]&$script_dir&g" $lib_dir/external-drive-mount@.service > $service_install_dir/external-drive-mount@.service

sudo udevadm control --reload
sudo systemctl daemon-reload
