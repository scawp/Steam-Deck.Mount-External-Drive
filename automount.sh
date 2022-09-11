#!/bin/bash
#Steam Deck Mount External Drive by scawp
#License: DBAD: https://github.com/scawp/Steam-Deck.Mount-External-Drive/blob/main/LICENSE.md
#Source: https://github.com/scawp/Steam-Deck.Mount-External-Drive
# Use at own Risk!

script_dir="$(dirname $(realpath "$0"))"
config_dir="$script_dir/config"

mkdir -p "$config_dir"

function mount_drive () {
  mkdir "/run/media/deck/$(lsblk -noLABEL $1)"
  chown deck:deck "/run/media/deck/$(lsblk -noLABEL $1)"
  mount "$1" "/run/media/deck/$(lsblk -noLABEL $1)" -ouid=1000,gid=1000
}

if [ "$1" = "remove" ]; then
  exit 0;
fi

if [ -f "$config_dir/drive_list.conf" ]; then
  if [ ! -z "$(grep "^$(lsblk -noUUID /dev/$2)$" "$config_dir/drive_list.conf")" ] || [ ! -z "$(grep "^ALWAYS$" "$config_dir/drive_list.conf")" ]; then
    mount_drive "/dev/$2"
  fi
fi

exit 0;