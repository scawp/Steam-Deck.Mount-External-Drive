# Steam-Deck.Mount-External-Drive
Scripts to (Un)Mount and to Auto-Mount (All or Whitelisted) External USB SSD on the Steam Deck

# Video Guide

~~https://youtu.be/q9tiNzVWjVo~~ Old Video

https://youtu.be/n9UC0-KywDQ

# Bacis Usage

`chmod +x install_automount.sh`

then run `./install_automount.sh`

# Uninstall

`sudo rm /etc/udev/rules.d/99-external-drive-mount.rules`

`sudo rm /etc/systemd/system/external-drive-mount@.service`

`sudo udevadm control --reload`

`sudo systemctl daemon-reload`

Then Delete this Repo from whereever you downloaded it to your Deck

# WORK IN PROGRESS!
This will probably have bugs, so beware! log bugs under `issues`!
