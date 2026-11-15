#!/bin/sh
# Runs as root at boot after extensions load.
chown -R tc:staff /home/tc
chmod +x /home/tc/.xsession

# Boot with "chessdebug" to dump X diagnostics to the serial console.
if grep -q chessdebug /proc/cmdline; then
  (
    for n in 1 2 3 4; do
      sleep 90
      {
        echo "=== CHESSDEBUG $n ps ==="; ps | grep -E 'icewm|xinit|Xorg|startx|\.xsession' | grep -v grep
        echo "=== CHESSDEBUG Xorg.0.log (errors) ==="; grep -E '\(EE\)|\(WW\)' /var/log/Xorg.0.log | tail -n 15
        echo "=== CHESSDEBUG xsession-errors ==="; tail -n 20 /home/tc/.xsession-errors
        echo "=== CHESSDEBUG end ==="
      } > /dev/ttyS0 2>&1
    done
  ) &
fi