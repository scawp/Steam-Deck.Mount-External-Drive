#!/bin/bash
#Steam Deck Mount External Drive by scawp
#License: DBAD: https://github.com/scawp/Steam-Deck.Mount-External-Drive/blob/main/LICENSE.md
#Source: https://github.com/scawp/Steam-Deck.Mount-External-Drive
# Use at own Risk!

script_dir="$(dirname $(realpath "$0"))"
tmp_dir="$script_dir/temp"

external_drive_list="$tmp_dir/external_drive_list.txt"

function log_error () {
  echo "$1" | sed "s&^&[$(date "+%F %T")] ("$0") &" | tee -a "$log_dir/error.log"
}

function log_msg () {
  echo "$1" | sed "s&^&[$(date "+%F %T")] ("$0") &" | tee -a "$log_dir/info.log"
}

function list_gui () {
  #IFS=$'\t';
  selected_device=$(zenity --list --title="Select Drive to (un)Mount" \
    --width=1000 --height=720 --print-column=ALL   --separator="\t" \
    --ok-label "(Un)Mount" --extra-button "Refresh" \
    --column="Path" --column="Size" --column="UUID" \
    --column="Mount Point" \
    $(cat "$1" | sed -e 's/$/\t/'))
  ret_value="$?"
  #unset IFS;
}

function confirm_gui () {
  zenity --question --width=400 \
    --text="Do you want to $1 device $2 with uuid of $3?"

  if [ "$?" = 1 ]; then
    exit 1;
  fi
}

function get_drive_list () {
  lsblk -nlo HOTPLUG,PATH,SIZE,UUID,MOUNTPOINT | grep -i '^\s*1' | awk  '$4!=""' | awk '{ if ( $5!="") print $2"\t"$3"\t"$4"\t"$5;else print $2"\t"$3"\t"$4"\tUnmounted"}' > "$external_drive_list"
}

function mount_drive () {
  if [ "$1" = "mount" ]; then
    udisksctl mount --no-user-interaction -b "$1" 2> $tmp_dir/last_error.log 1> $tmp_dir/last_msg.log
  else
    udisksctl unmount --no-user-interaction -b "$1" 2> $tmp_dir/last_error.log 1> $tmp_dir/last_msg.log
  fi

  if [ "$?" != 0 ]; then
    log_error "$(sed -n '1p' $tmp_dir/last_error.log)"
    ret_value="$(sed -n '1p' $tmp_dir/last_error.log)"
  else
    log_msg "$(sed -n '1p' $tmp_dir/last_msg.log)"
    ret_value="$(sed -n '1p' $tmp_dir/last_msg.log)"
  fi
}


function main () {
  get_drive_list
  list_gui "$external_drive_list"
  echo "$ret_value"
  mount_point="$(echo "$selected_device" | awk '{ print $4 }')" 
  path="$(echo "$selected_device" | awk '{ print $1 }')"
  uuid="$(echo "$selected_device" | awk '{ print $3 }')" 
 
  echo "the path: $path"
  if [ "$ret_value" = 1 ]; then
    if [ "$selected_device" = "Refresh" ]; then
      main
    else
      exit 1;
    fi
  fi

  if [ "$selected_device" = "" ]; then
    zenity --error --width=400 \
    --text="No Device Selected, Quitting!"
    exit 1;
  fi

  if [ "$mount_point" = "Unmounted" ]; then
    confirm_gui "mount" "$path" "$uuid"
    mount_drive "mount" "$path"
  else
    confirm_gui "unmount" "$path" "$uuid"
    mount_drive "unmount" "$path"
  fi

  zenity --info --width=400 \
    --text="$ret_value"

  exit 0;
}

main