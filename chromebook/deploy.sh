#!/bin/sh

### Personalized deploy script to setup new Debian installations to my liking.

## WM & Related ##
apt-get install i3 -y
apt-get install compton -y
## Configure i3-Gaps ##
git clone https://github.com/Airblader/i3.git

## GUI Programs ##
apt-get install firefox -y
apt-get install python -y
apt-get install python3 -y

## Dev Tools ##
apt-get install vim -y

## Utils ##
apt-get install rsync -y
apt-get install -y
apt-get install git -y
apt-get install samba -y

## Other
apt-get rtorrent -y
