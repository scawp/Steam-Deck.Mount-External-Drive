#!/bin/bash

set -euo pipefail

# Originally from https://serverfault.com/a/767079

# This script is called from our systemd unit file to mount or unmount
# a USB drive.

usage()
{
    echo "Usage: $0 {add|remove} device_name (e.g. sdb1)"
    exit 1
}

if [[ $# -ne 2 ]]; then
    usage
fi

ACTION=$1
DEVBASE=$2
DEVICE="/dev/${DEVBASE}"

# Shared between this and the auto-mount script to ensure we're not double-triggering nor automounting while formatting
# or vice-versa.
MOUNT_LOCK="/var/run/jupiter-automount-${DEVBASE//\/_}.lock"

# Obtain lock
exec 9<>"$MOUNT_LOCK"
if ! flock -n 9; then
    echo "$MOUNT_LOCK is active: ignoring action $ACTION"
    # Do not return a success exit code: it could end up putting the service in 'started' state without doing the mount
    # work (further start commands will be ignored after that)
    exit 1
fi

# Wait N seconds for steam
wait_steam()
{
    local i=0
    local wait=$1
    echo "Waiting up to $wait seconds for steam to load"
    while ! pgrep -x steamwebhelper &>/dev/null && (( i++ < wait )); do
        sleep 1
    done
}

send_steam_url()
{
  local command="$1"
  local arg="$2"
  local encoded=$(urlencode "$arg")
  if pgrep -x "steam" > /dev/null; then
      # TODO use -ifrunning and check return value - if there was a steam process and it returns -1, the message wasn't sent
      # need to retry until either steam process is gone or -ifrunning returns 0, or timeout i guess
      systemd-run -M 1000@ --user --collect --wait sh -c "./.steam/root/ubuntu12_32/steam steam://${command}/${encoded@Q}"
      echo "Sent URL to steam: steam://${command}/${arg} (steam://${command}/${encoded})"
  else
      echo "Could not send steam URL steam://${command}/${arg} (steam://${command}/${encoded}) -- steam not running"
  fi
}

# From https://gist.github.com/HazCod/da9ec610c3d50ebff7dd5e7cac76de05
urlencode()
{
    [ -z "$1" ] || echo -n "$@" | hexdump -v -e '/1 "%02x"' | sed 's/\(..\)/%\1/g'
}

do_mount()
{
    declare -i ret
    # NOTE: these values are ABI, since they are sent to the Steam client
    readonly FSCK_ERROR=1
    readonly MOUNT_ERROR=2

    # Get info for this drive: $ID_FS_LABEL, and $ID_FS_TYPE
    dev_json=$(lsblk -o PATH,LABEL,FSTYPE --json -- "$DEVICE" | jq '.blockdevices[0]')
    ID_FS_LABEL=$(jq -r '.label | select(type == "string")' <<< "$dev_json")
    ID_FS_TYPE=$(jq -r '.fstype | select(type == "string")' <<< "$dev_json")

    # Global mount options
    OPTS="rw,noatime"

    # File system type specific mount options
    #if [[ ${ID_FS_TYPE} == "vfat" ]]; then
    #    OPTS+=",users,gid=100,umask=000,shortname=mixed,utf8=1,flush"
    #fi

        case "${ID_FS_TYPE}" in
                "ntfs")
          echo "FSType is NTFS"
          #Extra Opts don't seem necessary anymore? add if required
          #OPTS+=""
                    ;;
                "exfat")
          echo "FSType is exFat"
                    #OPTS+=",users,gid=100,umask=000,shortname=mixed,utf8=1,flush"
                    ;;
                "btrfs")
          echo "FSType is btrfs"
                    ;;
        "ext4")
                    echo "FSType is ext4"
          #exit 2
          ;;
                *)
                    echo "Error mounting ${DEVICE}: unsupported fstype: ${ID_FS_TYPE} - ${dev_json}"
          rm "${MOUNT_LOCK}"
          exit 2
                    ;;
        esac

    # Prior to talking to udisks, we need all udev hooks (we were started by one) to finish, so we know it has knowledge
    # of the drive.  Our own rule starts us as a service with --no-block, so we can wait for rules to settle here
    # safely.
    #if ! udevadm settle; then
    #  echo "Failed to wait for \`udevadm settle\`"
    #  exit 1
    #fi

    # Ask udisks to auto-mount. This needs a version of udisks that supports the 'as-user' option.
    ret=0
    reply=$(busctl call --allow-interactive-authorization=false --expect-reply=true --json=short   \
                org.freedesktop.UDisks2                                                            \
                /org/freedesktop/UDisks2/block_devices/"${DEVBASE}"                                \
                org.freedesktop.UDisks2.Filesystem                                                 \
                Mount 'a{sv}' 3                                                                    \
                  as-user s deck                                                                   \
                  auth.no_user_interaction b true                                                  \
                  options                  s "$OPTS") || ret=$?

    if (( ret != 0 )); then
        send_steam_url "system/devicemountresult" "${DEVBASE}/${MOUNT_ERROR}"
        echo "Error mounting ${DEVICE} (status = $ret)"
        exit 1
    fi

    # Expected reply is of the format
    #  {"type":"s","data":["/run/media/deck/home"]}
    mount_point=$(jq -r '.data[0] | select(type == "string")' <<< "$reply" || true)
    if [[ -z $mount_point ]]; then
        echo "Error when mounting ${DEVICE}: udisks returned success but could not parse reply:"
        echo "---"$'\n'"$reply"$'\n'"---"
        exit 1
    fi

    if [[ ${ID_FS_TYPE} == "exfat" ]]; then
        echo "exFat does not support symlinks, do not add library to Steam"
        exit 0
    fi

    # Create a symlink from /run/media to keep compatibility with apps
    # that use the older mount point (for SD cards only).
    case "${DEVBASE}" in
        mmcblk0p*)
            if [[ -z "${ID_FS_LABEL}" ]]; then
                old_mount_point="/run/media/${DEVBASE}"
            else
                old_mount_point="/run/media/${mount_point##*/}"
            fi
            if [[ ! -d "${old_mount_point}" ]]; then
                rm -f -- "${old_mount_point}"
                ln -s -- "${mount_point}" "${old_mount_point}"
            fi
            ;;
    esac

    echo "**** Mounted ${DEVICE} at ${mount_point} ****"
    
    if [ -f "${mount_point}/libraryfolder.vdf" ]; then
        send_steam_url "addlibraryfolder" "${mount_point}"
    else
        #TODO check permissions are 1000  when creating new SteamLibrary
        mkdir -p "${mount_point}/SteamLibrary"
        chown deck:deck "${mount_point}/SteamLibrary"
        send_steam_url "addlibraryfolder" "${mount_point}/SteamLibrary"
    fi
}

do_unmount()
{
    local mount_point=$(findmnt -fno TARGET "${DEVICE}" || true)
    if [[ -n $mount_point ]]; then
        # Remove symlink to the mount point that we're unmounting
        find /run/media -maxdepth 1 -xdev -type l -lname "${mount_point}" -exec rm -- {} \;
    else
        # If we don't know the mount point then remove all broken symlinks
        find /run/media -maxdepth 1 -xdev -xtype l -exec rm -- {} \;
    fi
}

do_retrigger()
{
    local mount_point=$(findmnt -fno TARGET "${DEVICE}" || true)
    [[ -n $mount_point ]] || return 0

    # In retrigger mode, we want to wait a bit for steam as the common pattern is starting in parallel with a retrigger
    wait_steam 10
    # This is a truly gnarly way to ensure steam is ready for commands.
    # TODO literally anything else
    sleep 6
    send_steam_url "addlibraryfolder" "${mount_point}"
}

case "${ACTION}" in
    add)
        do_mount
        ;;
    remove)
        do_unmount
        ;;
    retrigger)
        do_retrigger
        ;;
    *)
        usage
        ;;
esac
