#!/bin/bash -eux

set +H

USERNAME=${SSH_USERNAME:-vagrant}

echo "==> Remove temporary DNF proxy"
sed '/^proxy=/d' -i /etc/dnf/dnf.conf

if [[ ! ( ${PACKER_BUILDER_TYPE} =~ 'amazon' || ${PACKER_BUILDER_TYPE} =~ 'docker' ) ]]; then

  echo "==> Clear out machine id"
  rm -f /etc/machine-id
  touch /etc/machine-id

  echo "==> Cleaning up temporary network addresses"
  # Make sure udev doesn't block our network
  # http://6.ptmc.org/?p=1649
  if grep -q -i "release 6" /etc/redhat-release ; then
    rm -f /etc/udev/rules.d/70-persistent-net.rules
    mkdir /etc/udev/rules.d/70-persistent-net.rules

    for ndev in `ls -1 /etc/sysconfig/network-scripts/ifcfg-*`; do
    if [ "`basename $ndev`" != "ifcfg-lo" ]; then
        sed -i '/^HWADDR/d' "$ndev";
        sed -i '/^UUID/d' "$ndev";
    fi
    done
  fi
  # Better fix that persists package updates: http://serverfault.com/a/485689
  touch /etc/udev/rules.d/75-persistent-net-generator.rules
  for ndev in `ls -1 /etc/sysconfig/network-scripts/ifcfg-*`; do
    if [ "`basename $ndev`" != "ifcfg-lo" ]; then
        sed -i '/^HWADDR/d' "$ndev";
        sed -i '/^UUID/d' "$ndev";
    fi
  done
  rm -rf /dev/.udev/

fi

if [[ ${PACKER_BUILDER_TYPE} =~ 'docker' ]]; then
    echo "==> Removing ${USERNAME} .ssh directory, to be created at runtime"
    rm -rf /home/${USERNAME}/.ssh
fi

DISK_USAGE_BEFORE_CLEANUP=$(df -h)

if [[ $CLEANUP_BUILD_TOOLS  =~ true || $CLEANUP_BUILD_TOOLS =~ 1 || $CLEANUP_BUILD_TOOLS =~ yes ]]; then
    echo "==> Removing tools used to build virtual machine drivers"
    dnf -y remove gcc libmpc mpfr cpp kernel-devel kernel-headers
fi

if [ ! -L /var/cache/dnf ]; then
    echo "==> Clean up DNF cache of metadata and packages to save space"
    dnf -y --enablerepo='*' clean all
fi

echo "==> Removing temporary files used to build box"
if mountpoint /tmp/vagrant-cache; then
    find /tmp -not -path '/tmp/vagrant-cache*' -a -not -path '/tmp' -delete

    if [ -L /var/cache/dnf ]; then
      rm /var/cache/dnf
      mkdir -p /var/cache/dnf
      chown root:root /var/cache/dnf
      chmod 0755 /var/cache/dnf
      sed -i 's/keepcache=1/keepcache=0/g' /etc/dnf/dnf.conf
    fi

    sed -i '/proxy=/d' /root/.npmrc
    sed -i '/proxy=/d' /home/${USERNAME}/.npmrc
    sed -i '/cache=/d' /root/.npmrc
    sed -i '/cache=/d' /home/${USERNAME}/.npmrc
else
    find /tmp -not -path '/tmp' -delete
fi

echo "==> Rebuild RPM DB"
rpmdb --rebuilddb
rm -f /var/lib/rpm/__db*

# delete any logs that have built up during the install
find /var/log/ -name *.log -exec rm -f {} \;

if [[ ${PACKER_BUILDER_TYPE} =~ 'qemu' ]]; then

    echo '==> Trimming filesystem to save space in the final image'
    fstrim -v /

elif [[ ! ( ${PACKER_BUILDER_TYPE} =~ 'amazon' || ${PACKER_BUILDER_TYPE} =~ 'docker' ) ]]; then

  echo '==> Clear out swap and disable until reboot'
  set +e
  swapuuid=$(/sbin/blkid -o value -l -s UUID -t TYPE=swap)
  case "$?" in
	2|0) ;;
	*) exit 1 ;;
  esac
  set -e
  if [ "x${swapuuid}" != "x" ]; then
    # Whiteout the swap partition to reduce box size
    # Swap is disabled till reboot
    swappart=$(readlink -f /dev/disk/by-uuid/$swapuuid)
    /sbin/swapoff "${swappart}"
    dd if=/dev/zero of="${swappart}" bs=1M || echo "dd exit code $? is suppressed"
    /sbin/mkswap -U "${swapuuid}" "${swappart}"
  fi

  echo '==> Zeroing out empty area to save space in the final image'
  # Zero out the free space to save space in the final image.  Contiguous
  # zeroed space compresses down to nothing.
  dd if=/dev/zero of=/EMPTY bs=1M || echo "dd exit code $? is suppressed"
  rm -f /EMPTY

  # Block until the empty file has been removed, otherwise, Packer
  # will try to kill the box while the disk is still full and that's bad
  sync

fi

echo "==> Disk usage before cleanup"
echo "${DISK_USAGE_BEFORE_CLEANUP}"

echo "==> Disk usage after cleanup"
df -h
