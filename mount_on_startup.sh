#!/bin/bash
#Steam Deck Mount External Drive by scawp
#License: DBAD: https://github.com/scawp/Steam-Deck.Mount-External-Drive/blob/main/LICENSE.md
#Source: https://github.com/scawp/Steam-Deck.Mount-External-Drive
# Use at own Risk!

script_dir="$(dirname $(realpath "$0"))"
tmp_dir="$script_dir/temp"
log_dir="$script_dir/logs"
config_dir="$script_dir/config"

mkdir -p "$tmp_dir"
mkdir -p "$log_dir"
mkdir -p "$config_dir"

function log_error () {
  echo "$1" | sed "s&^&[$(date "+%F %T")] ("$0") &" | tee -a "$log_dir/error.log"
}

function log_msg () {
  echo "$1" | sed "s&^&[$(date "+%F %T")] ("$0") &" | tee -a "$log_dir/info.log"
}

function mount_drive () {
  udisksctl mount --no-user-interaction -b "$1" 2> $tmp_dir/last_error.log 1> $tmp_dir/last_msg.log
  if [ "$?" != 0 ]; then
    log_error "$(sed -n '1p' $tmp_dir/last_error.log)"
  else
    log_msg "$(sed -n '1p' $tmp_dir/last_msg.log)"
  fi
}

if [ -f "$config_dir/drive_list.conf" ]; then
  while read -r drive_uuid; do
    mount_drive "/dev/disk/by-uuid/$drive_uuid"
  done < "$config_dir/drive_list.conf"
else
  log_error "No Config file, Run \"./zMount.sh\" and add a drive to \"Boot on Start up\"!"
fi