#!/bin/bash

#
# Resize home (preferred) or root filesystem to take up available disk space
#

declare -x DEV
declare -x FSTYPE

#mount | grep ' on / ' | cut -f 1,5 -d ' ' | read DEV FSTYPE
DEV=$(mount | grep ' on / ' | cut -f 1 -d ' ')
[ -z "$DEV" ] || DEV="/dev/$(lsblk -no pkname $DEV)"

FSTYPE=$(mount | grep ' on / ' | cut -f 5 -d ' ')

if [ -z "$DEV" ] || [ ! -b "$DEV" ]; then
    echo "Can't find device for root filesystem (you may need to resize the root filesystem yourself)" >&2
    exit 0
fi

if [ -z "$FSTYPE" ] || ! grep -q "$FSTYPE" /proc/filesystems; then
    echo "Can't find filesystem type for root filesystem (you may need to resize the root filesystem yourself)" >&2
    exit 0
fi
case $FSTYPE in
  xfs)
    ;;
  ext4)
    ;;
  btrfs)
    ;;
  *)
    echo "Unknown filesystem, expected: xfs, btrfs, ext4" >&2
    exit 1
esac

# Check for empty space
if [ ! -r $DEV ]; then
    echo "Can't read $DEV" >&2
    exit 1
fi
if [ ! -w $DEV ]; then
    echo "Can't write $DEV" >&2
    exit 2
fi

FREE_LINE="$(sfdisk --color=never --list-free $DEV | tail -n 1 | grep '^[0-9]' | tr -s [:space:])"
FREE=$(echo $FREE_LINE | cut -d ' ' -f 3)
FREE=${FREE:-0}
LAST_SECTOR=$(echo $FREE_LINE | cut -d ' ' -f 2)
if [[ $FREE -lt 100 ]]; then
    echo "Less than 100 unallocated sectors, no work to do"
    exit 0
fi

echo "Found $FREE unallocated sectors"

# Find partition to extend
sfdisk --color=never --dump $DEV > /tmp/sfdisk.dump
LAST_LINE="$(grep ^$DEV /tmp/sfdisk.dump | tail -n 1 | tr ',' ' ' | tr -s [:space:])"
PART="$(echo $LAST_LINE | cut -d ':' -f 1 | tr -d [:space:])"
PART_LAST_SECTOR="$(echo $LAST_LINE | cut -d ' ' -f 6)"
if [ -z "$PART" ] || [ ! -b "$PART" ]; then
    echo "Can't find last partition in $DEV" >&2
    cat /tmp/sfdisk.dump >&2
    exit 3
fi

LAST_MOUNT_POINT="$(mount | grep "^$PART " | cut -f 3 -d ' ')"
if [ -z "$LAST_MOUNT_POINT" ]; then
    echo "Can't find mount point for $PART" >&2
    exit 3
fi

# Extend partition
echo "Allocating $FREE sectors to $PART"
sed -i "s/size= *$PART_LAST_SECTOR/size= $LAST_SECTOR/" /tmp/sfdisk.dump
sfdisk --no-reread --color=never --force $DEV < /tmp/sfdisk.dump || exit $?
partprobe

case $FSTYPE in
  xfs)
    xfs_growfs $LAST_MOUNT_POINT
    ;;
  ext4)
    resize2fs $PART
    ;;
  btrfs)
    btrfs filesystem resize $LAST_MOUNT_POINT
    ;;
  *)
    echo "Unknown filesystem, expected: xfs, btrfs, ext4" >&2
    exit 1
esac    
