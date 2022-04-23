#!/bin/bash
#Steam Deck Mount External Drive by scawp
#License: DBAD: https://github.com/scawp/Steam-Deck.Mount-External-Drive/blob/main/LICENSE.md
#Source: https://github.com/scawp/Steam-Deck.Mount-External-Drive

tmp_dir="$(dirname "$(realpath "$0")")/tmp"

external_drive_list="$tmp_dir/external_drive_list.txt"
external_drive_info="$tmp_dir/external_drive_info.txt"
external_part_list="$tmp_dir/external_partition_list.txt"

#create temp dir if missing
if [ ! -d "$tmp_dir" ]; then
  echo "creating tmp dir"
  mkdir "$tmp_dir"
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

  echo "say wut $2"
  
  if [ "$1" = "Unmount" ] ; then
    zenity --password \
      --width=600 \
      --title="Enter Sudo Password to Unmount $2" \
      --ok-label "Mount" | sudo -kS umount "$2"
  else
    zenity --password \
      --width=600 \
      --title="Enter Sudo Password to mount $2" \
      --ok-label "Mount" | sudo -kS mount "$2"
  fi
  
  if [ $? -eq 1 ]; then
    zenity --error \
      --text="(Un)mounting failed, Aborting!"
    echo "Aborted"
    exit 1;
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
      #HOTDISK does show mmc drives
      lsblk -ndo HOTDISK,NAME,SIZE | grep -i '^\s*1' > "$external_drive_list"
    fi
  done
  echo "# External Drive Found!"; sleep 2 #need the sleep for the recheck below
  echo "100";
) | zenity --progress \
      --title="Please Insert External Drive" --text="Searching..." \
      --width=300 \
      --percentage=0 --pulsate --auto-close

if [ "$?" = -1 ] ; then
  echo "Aborted"
  exit 1;
fi

#check again, list might not have been fully populated
if [ "$show_sd_card" -eq 0 ]; then
  lsblk -ndo RM,NAME,SIZE | grep -i '^\s*1' > "$external_drive_list"
else
  lsblk -ndo HOTDISK,NAME,SIZE | grep -i '^\s*1' > "$external_drive_list"
fi

num_of_drives="$(wc -l < "$external_drive_list")" 

  if [ $num_of_drives -gt 1 ]; then
  selected_drive=$(zenity --list --title="Multiple Drives Found" \
    --width=500 --height=500 --print-column=2 \
    --separator='\t' --ok-label "Select Drive" \
    --radiolist --column="Select" --column="Name" --column="Size" \
    $(cat "$external_drive_list"))
  if [ "$?" = -1 ] ; then
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
lsblk -io NAME,SIZE,FSTYPE,UUID,MOUNTPOINTS \
  | grep -i '[\`|\|]\-'$selected_drive > "$external_part_list"

num_of_partitions="$(wc -l < "$external_part_list")" 

if [ $num_of_partitions -gt 0 ]; then
  selected_drive=$(zenity --list --title="Please Select a Partiton" \
    --width=800 --height=200 --print-column=2 \
    --separator='\t' --ok-label "Select" \
    --column="Name" --column="Size" --column="Type" --column="UUID" --column="Mount" \
    $(cat "$external_part_list"))
  
  if [ "$?" = 1 ] ; then
    echo "Aborted"
    exit 1;
  fi
fi

echo "$selected_drive"

#TODO trim selected_drive when its a partition for |`- etc
#get full info on the drive/partiton
lsblk -ndo NAME,SIZE,FSTYPE,UUID,MOUNTPOINTS \
| grep -i '^'$selected_drive > "$external_drive_info"

lsblk -ndo NAME,SIZE,FSTYPE,UUID,MOUNTPOINTS \
| grep -i '^'$selected_drive

unset $line
read -r line < "$external_drive_info"
echo "$line"
column=($line) #0=NAME 1=SIZE 2=FSTYPE 3=UUID 4=MOUNTPOINTS

mount_type="Mount"
if [ -n "${column[4]}" ]; then
  mount_type="Unmount"
fi

option=$(zenity --info --text="What would you like to do?" --width=600 \
    --extra-button "$mount_type" --extra-button "Auto Mount" \
    --extra-button "Find Steam Library" --ok-label "Quit")
  #1 means a button thats isn't "ok" was pressed
  if [ "$?" = 1 ] ; then
    if [ "$option" = "$mount_type" ]; then
      do_mount "$mount_type" "/dev/${column[0]}" #TODO un-hardcode /dev/ maybe check 0 has a value
    else
      if [ "$option" = "Auto Mount" ]; then
        auto_mount
      fi
    fi
  fi

exit 0;