# Steam-Deck.Mount-External-Drive
Scripts to (Un)Mount and to Auto-Mount (All or Whitelisted) External USB SSD on the Steam Deck

## Just want to Auto-Mount?

See [https://github.com/scawp/Steam-Deck.Mount-External-Drive/tree/Quick-Auto-Mount-Only](https://github.com/scawp/Steam-Deck.Mount-External-Drive/tree/Quick-Auto-Mount-Only)

# Video Guide

~~https://youtu.be/q9tiNzVWjVo~~ Old Video

https://youtu.be/n9UC0-KywDQ

# Bacis Usage

`chmod +x install_automount.sh`

then run `./install_automount.sh`

# Install Options

The install script will prompt to either to Mount any Removable Device that you plug in or only ones Whitelisted via `zMount.sh` (or manually adding the drives `UUID` to `config/drive_list.conf`).

Once whitelisted (or Mount Any Drive), the Device will be Mounted to `/run/media/deck/[LABEL]` eg `/run/media/deck/External-ssd/` if the Device has no `label` then the Devices `UUID` will be used eg `/run/media/deck/a12332-12bf-a33ab-eef/`

### NOTE!

Device will still need added to Steam as a Steam Library Folder in Desktop mode initially but will appear on subsequent boots.

# Uninstall

`sudo rm /etc/udev/rules.d/99-external-drive-mount.rules`

`sudo rm /etc/systemd/system/external-drive-mount@.service`

`sudo udevadm control --reload`

`sudo systemctl daemon-reload`

Then Delete this Repo from whereever you downloaded it to your Deck

# WORK IN PROGRESS!
This will probably have bugs, so beware! log bugs under `issues`!

# "This is cool! How can I thank you?"
### Why not drop me a sub over on my youtube channel ;) [Chinballs Gaming](https://www.youtube.com/chinballsTV?sub_confirmation=1)

### Also [Check out all these other things I'm making](https://github.com/scawp/Steam-Deck.Tools-List)
