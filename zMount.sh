#!/bin/bash
#Steam Deck Mount External Drive by scawp
#License: DBAD: https://github.com/scawp/Steam-Deck.Mount-External-Drive/blob/main/LICENSE.md
#Source: https://github.com/scawp/Steam-Deck.Mount-External-Drive
# Use at own Risk!

script_dir="$(dirname $(realpath "$0"))"
tmp_dir="/tmp/scawp.SDzMount"

mkdir -p "$tmp_dir"

external_drive_list="$tmp_dir/external_drive_list.txt"

#TODO this is to force kdesu dialog to use sudo, maybe theres a better way?
if [ ! -f ~/.config/kdesurc ];then
  touch ~/.config/kdesurc
  echo "[super-user-command]" > ~/.config/kdesurc
  echo "super-user-command=sudo" >> ~/.config/kdesurc
fi

function list_gui () {
  IFS=$'[\t|\n]';
  selected_device=$(zenity --list --title="Select Drive to (un)Mount" \
    --width=1000 --height=360 --print-column=1 --separator="\t" \
    --ok-label "(Un)Mount" --extra-button "Refresh" \
    --column="Path" --column="Size" --column="UUID" \
    --column="Mount Point" --column="Label" --column="File System" \
    $(cat "$external_drive_list"))
  ret_value="$?"
  unset IFS;
}

function confirm_gui () {
  zenity --question --width=400 \
    --text="Do you want to $1 device $2 with uuid of $3?"

  if [ "$?" = 1 ]; then
    exit 1;
  fi
}

function get_drive_list () {
  #Overkill? Perhaps, but Zenity (or I) was struggling with Splitting
  lsblk -PoHOTPLUG,PATH,SIZE,UUID,MOUNTPOINT,LABEL,FSTYPE | grep '^HOTPLUG="1"' | grep -v 'UUID=\"\"' | sed -e 's/^HOTPLUG=\"1\"\sPATH=\"//' -e 's/\"\"/\" \"/g' -e 's/\"\s[A-Z]*=\"/\t/g' -e 's/\"$//' | tee "$external_drive_list"
}

function sudo_mount_drive () {
  if [ "$1" = "mount" ]; then
    kdesu -c "udisksctl mount -b \"/dev/disk/by-uuid/$2\" 2> $tmp_dir/last_error.log 1> $tmp_dir/last_msg.log"
  else
    kdesu -c "udisksctl unmount -b \"/dev/disk/by-uuid/$2\" 2> $tmp_dir/last_error.log 1> $tmp_dir/last_msg.log"
  fi

  if [ "$?" != 0 ]; then
    log_error "$(sed -n '1p' $tmp_dir/last_error.log)"
    ret_value="$(sed -n '1p' $tmp_dir/last_error.log)"
    ret_success=0
  else
    log_msg "$(sed -n '1p' $tmp_dir/last_msg.log)"
    ret_value="$(sed -n '1p' $tmp_dir/last_msg.log)"
    ret_success=1
  fi
}

function mount_drive () {
  if [ "$1" = "mount" ]; then
    udisksctl mount --no-user-interaction -b "/dev/disk/by-uuid/$2" 2> $tmp_dir/last_error.log 1> $tmp_dir/last_msg.log
  else
    udisksctl unmount --no-user-interaction -b "/dev/disk/by-uuid/$2" 2> $tmp_dir/last_error.log 1> $tmp_dir/last_msg.log
  fi

  if [ "$?" != 0 ]; then
    ret_value="$(sed -n '1p' $tmp_dir/last_error.log)"
    sudo_mount_drive $1 $2
  else
    ret_value="$(sed -n '1p' $tmp_dir/last_msg.log)"
    ret_success=1
  fi
}

function main () {
  get_drive_list
  list_gui
  mount_point="$(lsblk -noMOUNTPOINT $selected_device)"
  uuid="$(lsblk -noUUID $selected_device)"

  if [ "$ret_value" = 1 ]; then
    if [ "$selected_device" = "Refresh" ]; then
      main
    else
      if [ "$selected_device" = "Auto Mount" ]; then
        continue
      else
        exit 1;
      fi
    fi
  fi

  if [ "$selected_device" = "" ]; then
    zenity --error --width=400 \
    --text="No Device Selected, Quitting!"
    exit 1;
  fi

  if [ "$mount_point" = "" ]; then
    confirm_gui "mount" "$selected_device" "$uuid"
    mount_drive "mount" "$uuid"
  else
    confirm_gui "unmount" "$selected_device" "$uuid"
    mount_drive "unmount" "$uuid"
  fi

  zenity --info --width=400 \
    --text="$ret_value"

  exit 0;
}

main
