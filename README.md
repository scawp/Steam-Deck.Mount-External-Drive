# Steam-Deck.Mount-External-Drive
Scripts to Auto-Mount (and to Manually mount & unmount from `GameMode`) External USB SSD on the Steam Deck

# How does this work?

a `udev` rule is added to `/etc/udev/rules.d/99-external-drive-mount.rules`
which calls systemd `/etc/systemd/system/external-drive-mount@[sda1|sda2|sdd1|etc].service`
that then runs `automount.sh` to Auto Mount any plugged in USB Storage Device.

`/etc/fstab` is not required for mounting in this way, (however if a Device has an `fstab` entry these scripts will still work)

# Video Guide

https://youtu.be/TiXmf_b7HF8 (Slightly Out of Date)

# Operation

The External Drive(s) will be Auto-Mounted to `/run/media/deck/[LABEL]` eg `/run/media/deck/External-ssd/` if the Device has no `label` then the Devices `UUID` will be used eg `/run/media/deck/a12332-12bf-a33ab-eef/`

The install will also offer an optional install of `zMount.sh` which will be added to your Steam Library as a non-steam game which can be ran from `GameMode`, this will allow manual (un)mounting of USB Devices and the SD-Card. (NOTE: This is probably more useful for unmounting as the auto mount script should mount anything anyway).

### NOTE!

Drive requires prior formatting (currently tested with NTFS, Ext4, btrfs, NOTE: btrfs mounts with incorrect ownership, TODO). All Partitions will be Mounted on Boot and /or On Insert.

~~Drive will still need added to Steam as a Steam Library Folder in Desktop mode initially but will appear on subsequent Boots/Inserts.~~ This was the case until recently, now however the Steam Library on the Drive was no longer added to Steam on Inserting the Drive. As Such I've "stolen" the following `systemd-run -M 1000@ --user --collect --wait sh -c "./.steam/root/ubuntu12_32/steam steam://addlibraryfolder/${url@Q}"` from Valve SD Card Auto Mounting Service (which is pretty similar it turns out!).

### WARNING (Maybe?)

As a result of the code mentioned above, a Steam Library will be created on ANY device inserted into the Deck if one isn't found, this may or may not be desirable for your needs. 

# Installation

## Via Curl (One Line Install)

In Konsole type `curl -sSL https://raw.githubusercontent.com/scawp/Steam-Deck.Mount-External-Drive/main/curl_install.sh | bash`

a `sudo` password is required (run `passwd` if required first)

# Uninstall

`sudo rm /etc/udev/rules.d/99-external-drive-mount.rules`

`sudo rm /etc/systemd/system/external-drive-mount@.service`

`sudo rm -r /home/deck/.local/share/scawp/SDMED`

`sudo udevadm control --reload`

`sudo systemctl daemon-reload`

# WORK IN PROGRESS!

This will probably have bugs, so beware! log bugs under [issues](https://github.com/scawp/Steam-Deck.Mount-External-Drive/issues)!

# "This is cool! How can I thank you?"
### Why not drop me a sub over on my youtube channel ;) [Chinballs Gaming](https://www.youtube.com/chinballsTV?sub_confirmation=1)

### Also [Check out all these other things I'm making](https://github.com/scawp/Steam-Deck.Tools-List)
