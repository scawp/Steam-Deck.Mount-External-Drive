#!/bin/bash
#Steam Deck Mount External Drive by scawp
#License: DBAD: https://github.com/scawp/Steam-Deck.Mount-External-Drive/blob/main/LICENSE.md
#Source: https://github.com/scawp/Steam-Deck.Mount-External-Drive
# Use at own Risk!

script_dir="$(dirname $(realpath "$0"))"
config_dir="$script_dir/config"

mkdir -p "$config_dir"

function mount_drive () {
  label="$(lsblk -noLABEL $1)"
  fs_type="$(lsblk -noFSTYPE $1)"

  if [ -z "$label" ]; then
    label="$(lsblk -noUUID $1)"
    echo "No label using UUID"
  fi

  mkdir -p "/run/media/deck/$label"
  chown deck:deck "/run/media/deck"
  chown deck:deck "/run/media/deck/$label"

  #TODO: Check /run/media/deck/$label exists
  if [ "$fs_type" = "ntfs" ]; then
    #TODO: Better default options
    echo "Attempting Mounting lowntfs-3g"
    mount.lowntfs-3g "$1" "/run/media/deck/$label" -ouid=1000,gid=1000,user
  else
    #TODO: Better default options
    echo "Attempting Mounting $fs_type"
    mount "$1" "/run/media/deck/$label"
  fi

  mount_point="$(lsblk -noMOUNTPOINT $1)"
  if [ -z "$mount_point" ];then
    echo "Failed to mount "$1" at /run/media/deck/$label"
  else
    echo "Mounted "$1" at $mount_point"
  fi
}

#TODO: Do stuff on device removal
if [ "$1" = "remove" ]; then
  exit 0;
fi

if [ -f "$config_dir/drive_list.conf" ]; then
  if [ ! -z "$(grep "^$(lsblk -noUUID /dev/$2)$" "$config_dir/drive_list.conf")" ] || [ ! -z "$(grep "^ALWAYS$" "$config_dir/drive_list.conf")" ]; then
    mount_drive "/dev/$2"
  else
    echo "Drive /dev/$2 with UUID $(lsblk -noUUID /dev/$2) not whitelisted."
  fi
else
  echo "Missing Config file: $config_dir/drive_list.conf"
fi

exit 0;