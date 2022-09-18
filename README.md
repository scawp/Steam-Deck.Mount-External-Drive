# Steam-Deck.Mount-External-Drive
Scripts to Auto-Mount External USB SSD on the Steam Deck

# About

This is a slimmed down verion of the [main](https://github.com/scawp/Steam-Deck.Mount-External-Drive) branch to provide 
only automounting to ANY External Drive, such as a Dock ;)
without worrying about configuration.

# How does this work?

a `udev` rule is added to `/etc/udev/rules.d/99-external-drive-mount.rules`
which calls systemd `/etc/systemd/system/external-drive-mount@[sda1|sda2|sdd1|etc].service`
that then runs `automount.sh`

`/etc/fstab` is not required for mounting in this way, (however if a Device has an `fstab` entry these scripts will still work)

# Video Guide

https://youtu.be/n9UC0-KywDQ

# Bacis Usage

`chmod +x install_automount.sh`

then run `./install_automount.sh`, a `sudo` password is required (run `passwd` if required firs)

# Install Options

The External Drive(s) will be Auto-Mounted to `/run/media/deck/[LABEL]` eg `/run/media/deck/External-ssd/` if the Device has no `label` then the Devices `UUID` will be used eg `/run/media/deck/a12332-12bf-a33ab-eef/`

### NOTE!

Drive requires prior formatting (currently tested with NTFS, Ext4, btrfs). All Partitions will be Mounted on Boot and /or On Insert.

Drive will still need added to Steam as a Steam Library Folder in Desktop mode initially but will appear on subsequent Boots/Inserts.

# Uninstall

`sudo rm /etc/udev/rules.d/99-external-drive-mount.rules`

`sudo rm /etc/systemd/system/external-drive-mount@.service`

`sudo udevadm control --reload`

`sudo systemctl daemon-reload`

Then delete this Repo from whereever you downloaded it to your Deck

# WORK IN PROGRESS!
This will probably have bugs, so beware! log bugs under [issues](https://github.com/scawp/Steam-Deck.Mount-External-Drive/issues)!
