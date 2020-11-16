#!/bin/bash

# 7.3 Preparing Virtual Kernel Filesystem Again
mkdir -pv $LFS/{dev,proc,sys,run}

# 7.3.1 Create Initial Device Nodes
mknod -m 600 $LFS/dev/console c 5 1
mknod -m 666 $LFS/dev/null c 1 3

# 7.3.2 Mounting and Populating /dev
mount -v --bind /dev $LFS/dev

# 7.3.3 Mounting Virtual Kernel File System
mount -v --bind /dev/pts $LFS/dev/pts
mount -vt proc proc $LFS/proc
mount -vt sysfs sysfs $LFS/sys
mount -vt tmpfs tmpfs $LFS/run
if [ -h $LFS/dev/shm ]; then
  mkdir -pv $LFS/$(readlink $LFS/dev/shm)
fi


chroot "$LFS" /usr/bin/env -i   \
    HOME=/root                  \
    TERM="$TERM"                \
    PS1='(lfs chroot) \u:\w\$ ' \
    PATH=/bin:/usr/bin:/sbin:/usr/sbin \
    /bin/bash --login -i +h <<HEREDOC

HEREDOC
