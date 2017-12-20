#!/usr/bin/env bash

# This script maintains the notification tray icon and a pipe used to update it

# create a FIFO file, used to manage the I/O redirection from shell
PIPE="/var/local/pending-changes/pipe"
CHANGED="/var/local/pending-changes/changed"

mkfifo $PIPE

# attach a file descriptor to the file
exec 3<> $PIPE

# add handler to manage process shutdown
function on_exit() {
    echo "quit" >&3
    rm -f $PIPE
}
trap on_exit EXIT

# add handler for tray icon left click
function on_click() {
    if [ -s /var/local/pending-changes/changed ]; then
        cat /var/local/pending-changes/changed | yad --title="Workspace Changes" --window-icon=emblem-important --on-top --maximized --text-info --escape-ok --button=Close:0
    else
        yad --title="Workspace Changes" --window-icon=emblem-generic --on-top --center --text='No Changes' --escape-ok --button=Close:0
    fi
}
export -f on_click

( sleep 5s; /usr/local/bin/check-for-changes.sh ) &

# create the notification icon
yad --notification                  \
    --listen                        \
    --image="emblem-new"              \
    --text="Scanning for changes..."   \
    --command="bash -c on_click" <&3
