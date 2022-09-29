#!/bin/bash
#Steam Deck Mount External Drive by scawp
#License: DBAD: https://github.com/scawp/Steam-Deck.Mount-External-Drive/blob/main/LICENSE.md
#Source: https://github.com/scawp/Steam-Deck.Mount-External-Drive
# Use at own Risk!

#This is a slimmed down verions of the main branch to provide 
#only automounting to ANY External Drive, such as a Dock ;)
#without worrying about configuration

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

# From https://gist.github.com/HazCod/da9ec610c3d50ebff7dd5e7cac76de05
urlencode()
{
    [ -z "$1" ] || echo -n "$@" | hexdump -v -e '/1 "%02x"' | sed 's/\(..\)/%\1/g'
}

  mount_point="$(lsblk -noMOUNTPOINT $1)"
  if [ -z "$mount_point" ];then
    echo "Failed to mount "$1" at /run/media/deck/$label"
  else
    echo "Mounted "$1" at $mount_point"

    #Below Stolen from /usr/lib/hwsupport/sdcard-mount.sh
    url=$(urlencode "${mount_point}")

    # If Steam is running, notify it
    if pgrep -x "steam" > /dev/null; then
        # TODO use -ifrunning and check return value - if there was a steam process and it returns -1, the message wasn't sent
        # need to retry until either steam process is gone or -ifrunning returns 0, or timeout i guess
        systemd-run -M 1000@ --user --collect --wait sh -c "./.steam/root/ubuntu12_32/steam steam://addlibraryfolder/${url@Q}"
    fi
  fi
}

#TODO: Do stuff on device removal
if [ "$1" = "remove" ]; then
  #TODO: if removed without unmounting first  
    #Attempt to unmount if system still thinks is mounted. btrfs seems to do this
    #mount "$2"
    #Delete orphaned dir in /dev/media/deck/[LABEL|UUID] if exists
  exit 0;
else
  #TODO: Check if Device is already mounted? eg via fstab?
  mount_drive "/dev/$2"
fi

exit 0;