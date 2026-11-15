#!/bin/sh
# Runs as root at boot after extensions load.
chown -R tc:staff /home/tc
chmod +x /home/tc/.xsession
