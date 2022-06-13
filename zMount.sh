#!/bin/bash
#Steam Deck Mount External Drive by scawp
#License: DBAD: https://github.com/scawp/Steam-Deck.Mount-External-Drive/blob/main/LICENSE.md
#Source: https://github.com/scawp/Steam-Deck.Mount-External-Drive

tmp_dir="$(dirname "$(realpath "$0")")/tmp"

external_drive_list="$tmp_dir/external_drive_list.txt"
external_drive_info="$tmp_dir/external_drive_info.txt"
external_part_list="$tmp_dir/external_partition_list.txt"

mount_path="/run/media/deck/"

zenity_timeout=3 #seconds


#create temp dir if missing
if [ ! -d "$tmp_dir" ]; then
  echo "creating tmp dir"
  mkdir "$tmp_dir"
fi

#TODO this is to fore kdesu dialog to use sudo, maybe theres a better way?
if [ ! -f ~/.config/kdesurc ];then
  touch ~/.config/kdesurc
  echo "[super-user-command]" > ~/.config/kdesurc
  echo "super-user-command=sudo" >> ~/.config/kdesurc
fi

#purge temp files
true > "$external_drive_list"
true > "$external_drive_info"
true > "$external_part_list"

show_sd_card=0
if [ "$1" = "sd" ]; then
  show_sd_card=1
fi

function do_mount () {
  if [ ! -n "$2" ] ; then
    echo "No Drive Selected"
    exit 1;
  fi

  if [ "$1" = "Unmount" ] ; then
    kdesu -c "umount \"$2\""
  else
    if grep -i '^UUID='$3 /etc/fstab; then
      #if theres an entry in fstab use those values (by default)
      kdesu -c "mount $mount_path$4"
    else
      if [ ! -d "$mount_path$3" ]; then
        echo "creating mount point"
        kdesu -c "mkdir -p $mount_path$4; mount $2 $mount_path$4"
      else
        kdesu -c "mount $2 $mount_path$4"
      fi
    fi
  fi
  
  if [ "$?" -eq 1 ]; then
    #TODO check this is reachable
    zenity --error \
      --text="$1ing failed, Aborting!" --timeout="$zenity_timeout"
    echo "Aborted"
    exit 1;
  fi

  #TODO better feedback here, assumes no errors
  zenity --info \
    --text="$1ed!" --timeout="$zenity_timeout"
  echo "Exit"
  exit 0;
}

function auto_mount () {
  #1=uuid 2=fs
  if grep -i '^UUID='$1 /etc/fstab; then
    #TODO Add option to delete auto mount
    zenity --error \
      --width=600 \
      --text="Mount Point $mount_path$1 Exists, Aborting!" --timeout="$zenity_timeout"
    exit 1;
  else
    kdesu -c "echo -e \"\nUUID=$1 $mount_path$1 $2  defaults,nofail  0 0\" | tee -a \"/etc/fstab\""
    
    #TODO this might no longer be reachable
    if [ "$?" = 1 ]; then
      zenity --error \
        --text="Writing to Fstab failed, Aborting!" --timeout="$zenity_timeout"
      echo "Fail"
      exit 1;
    fi

    if grep -i '^UUID='$1 /etc/fstab; then
    zenity --info \
      --width=600 \
      --text="Mount Point $mount_path$1 will Auto Mount on Restart!" --timeout="$zenity_timeout"
    fi
    #TODO else!
  fi
}

#run
(
  #sleep 1;
  until [ -s "$external_drive_list" ]; do
    #sleep 1;
    if [ "$show_sd_card" -eq 0 ]; then
      #RM "Removeable Drive" doens't show mmc cards
      lsblk -ndo RM,NAME,SIZE | grep -i '^\s*1' > "$external_drive_list"
    else
      #HOTPLUG does show mmc drives
      lsblk -ndo HOTPLUG,NAME,SIZE | grep -i '^\s*1' > "$external_drive_list"
    fi

    #TODO can get stuck in loop if dialog is closed
  done
  echo "# External Drive Found!"; sleep 2 #need the sleep for the re-check below
  echo "100";
) | zenity --progress \
      --title="Please Insert External Drive" --text="Searching..." \
      --width=300 \
      --percentage=0 --pulsate --auto-close

echo "$?"
if [ "$?" = 1 ] ; then
  echo "Aborted"
  exit 1;
fi

#check again, list might not have been fully populated
if [ "$show_sd_card" -eq 0 ]; then
  lsblk -ndo RM,NAME,SIZE | grep -i '^\s*1' > "$external_drive_list"
else
  lsblk -ndo HOTPLUG,NAME,SIZE | grep -i '^\s*1' > "$external_drive_list"
fi

num_of_drives="$(wc -l < "$external_drive_list")" 

  if [ $num_of_drives -gt 1 ]; then
  selected_drive=$(zenity --list --title="Multiple Drives Found" \
    --width=500 --height=500 --print-column=2 \
    --separator='\t' --ok-label "Select Drive" \
    --radiolist --column="Select" --column="Name" --column="Size" \
    $(cat "$external_drive_list"))
  if [ "$?" = 1 ] ; then
    echo "Aborted"
    exit 1;
  fi
else
  #this is a bit poo but works
  read -r line < "$external_drive_list"
  column=($line)
  selected_drive=${column[1]}
fi

#check we have selected a drive or die
if [ ! -n "$selected_drive" ] ; then
  echo "No Drive Selected"
  exit 1;
fi

#get full info on the selected drives partitions
lsblk -io NAME,SIZE,FSTYPE,UUID \
  | grep -i '[\`|\|]\-'$selected_drive | sed 's/[\|\`][\-]//' > "$external_part_list"

num_of_partitions="$(wc -l < "$external_part_list")" 

if [ $num_of_partitions -gt 1 ]; then
  selected_drive=$(zenity --list --title="Please Select a Partiton" \
    --width=800 --height=200 --print-column=1 \
    --separator='\t' --ok-label "Select" \
    --column="Name" --column="Size" --column="Type" --column="UUID" \
    $(cat "$external_part_list"))
  
  if [ "$?" = 1 ] ; then
    echo "Aborted"
    exit 1;
  fi
fi

if [ $num_of_partitions -eq 1 ]; then
  read -r line < "$external_part_list"
  echo "$line"
  column=($line) #0=NAME 1=SIZE 2=FSTYPE 4=UUID 3=MOUNTPOINT
  selected_drive=${column[0]}
fi

if [ ! -n "$selected_drive" ] ; then
  echo "No Drive Selected"
  zenity --error \
    --text="No Drive Selected, Aborting!" --timeout="$zenity_timeout"  
  exit 1;
fi


#get full info on the drive/partiton
lsblk -nlo NAME,SIZE,FSTYPE,UUID,LABEL,MOUNTPOINT \
| grep -i '^'$selected_drive > "$external_drive_info"

read -r line < "$external_drive_info"
echo "$line"
column=($line) #0=NAME 1=SIZE 2=FSTYPE 4=UUID 3=MOUNTPOINT

if [ ! -n "${column[3]}" ]; then
  echo "Error No UUID"
  zenity --error \
    --text="No UUID, Aborting!" --timeout="$zenity_timeout"
  exit 1;
fi

mount_type="Mount"
#TODO assumes the presence of a mount point that the drive is mounted. check.
if [ -n "${column[5]}" ]; then
  mount_type="Unmount"
fi

option=$(zenity --info --text="What would you like to do with /dev/${column[0]} \(${column[4]}\)?" --width=400 \
    --extra-button "$mount_type" --extra-button "Auto Mount" \
    --ok-label "Quit")
  #1 means a button thats isn't "ok" was pressed
  if [ "$?" = 1 ] ; then
    if [ "$option" = "$mount_type" ]; then
      do_mount "$mount_type" "/dev/${column[0]}" "${column[3]}" "${column[4]}" 
      #TODO un-hardcode (3) /dev/ maybe check 0 has a value
    else
      if [ "$option" = "Auto Mount" ]; then
        auto_mount "${column[3]}" "${column[2]}"
      fi
    fi
  fi

echo "script finshed"
exit 0;
