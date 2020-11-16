#!/bin/bash

# 7.2 Changing Ownership
chown -R root:root $LFS/{usr,lib,var,etc,bin,sbin,tools}
case $(uname -m) in
  x86_64) chown -R root:root $LFS/lib64 ;;
esac

# 7.3 Preparing Virtual Kernel System
mkdir -pv $LFS/{dev,proc,sys,run}

mknod -m 600 $LFS/dev/console c 5 1
mknod -m 666 $LFS/dev/null c 1 

mount -v --bind /dev $LFS/dev

mount -v --bind /dev/pts $LFS/dev/pts
mount -vt proc proc $LFS/proc
mount -vt sysfs sysfs $LFS/sys
mount -vt tmpfs tmpfs $LFS/run

if [ -h $LFS/dev/shm ]; then
  mkdir -pv $LFS/$(readlink $LFS/dev/shm)
fi

# 7.4 Entering CHROOT Environment
chroot "$LFS" /usr/bin/env -i   \
    HOME=/root                  \
    TERM="$TERM"                \
    PS1='(lfs chroot) \u:\w\$ ' \
    PATH=/bin:/usr/bin:/sbin:/usr/sbin \
    /bin/bash --login -i +h <<HEREDOC

# 7.5 Creating Directories
mkdir -pv /{boot,home,mnt,opt,srv}

mkdir -pv /etc/{opt,sysconfig}
mkdir -pv /lib/firmware
mkdir -pv /media/{floppy,cdrom}
mkdir -pv /usr/{,local/}{bin,include,lib,sbin,src}
mkdir -pv /usr/{,local/}share/{color,dict,doc,info,locale,man}
mkdir -pv /usr/{,local/}share/{misc,terminfo,zoneinfo}
mkdir -pv /usr/{,local/}share/man/man{1..8}
mkdir -pv /var/{cache,local,log,mail,opt,spool}
mkdir -pv /var/lib/{color,misc,locate}

ln -sfv /run /var/run
ln -sfv /run/lock /var/lock

install -dv -m 0750 /root
install -dv -m 1777 /tmp /var/tmp

# 7.6 Creating Essential Files and Symlinks
ln -sv /proc/self/mounts /etc/mtab
echo "127.0.0.1 localhost $(hostname)" > /etc/hosts
cat > /etc/passwd << "EOF"
root:x:0:0:root:/root:/bin/bash
bin:x:1:1:bin:/dev/null:/bin/false
daemon:x:6:6:Daemon User:/dev/null:/bin/false
messagebus:x:18:18:D-Bus Message Daemon User:/var/run/dbus:/bin/false
nobody:x:99:99:Unprivileged User:/dev/null:/bin/false
EOF

cat > /etc/group << "EOF"
root:x:0:
bin:x:1:daemon
sys:x:2:
kmem:x:3:
tape:x:4:
tty:x:5:
daemon:x:6:
floppy:x:7:
disk:x:8:
lp:x:9:
dialout:x:10:
audio:x:11:
video:x:12:
utmp:x:13:
usb:x:14:
cdrom:x:15:
adm:x:16:
messagebus:x:18:
input:x:24:
mail:x:34:
kvm:x:61:
wheel:x:97:
nogroup:x:99:
users:x:999:
EOF

echo "tester:x:$(ls -n $(tty) | cut -d" " -f3):101::/home/tester:/bin/bash" >> /etc/passwd
echo "tester:x:101:" >> /etc/group
install -o tester -d /home/tester

exec /bin/bash --login +h
touch /var/log/{btmp,lastlog,faillog,wtmp}
chgrp -v utmp /var/log/lastlog
chmod -v 664  /var/log/lastlog
chmod -v 600  /var/log/btmp

# 7.7 Libstdc++ from GCC pass 2
cd $LFS/sources
tar -xf gcc-10.2.0.tar.xz
cd gcc-10.2.0
ln -s gthr-posix.h libgcc/gthr-default.h
mkdir -v build
cd       build
../libstdc++-v3/configure            \
    CXXFLAGS="-g -O2 -D_GNU_SOURCE"  \
    --prefix=/usr                    \
    --disable-multilib               \
    --disable-nls                    \
    --host=$(uname -m)-lfs-linux-gnu \
    --disable-libstdcxx-pch
make
make install
cd $LFS/sources
rm -rf gcc-10.2.0

# 7.8.1 Gettext
cd $LFS/sources
tar -xf gettext-0.21.tar.xz
cd gettext-0.21
./configure --disable-shared
make
cp -v gettext-tools/src/{msgfmt,msgmerge,xgettext} /usr/bin
cd $LFS/sources
rm -rf gettext-0.21

# 7.9.1 Bison

cd $LFS/sources
tar -xf bison-3.7.1.tar.xz
cd bison-3.7.1
./configure --prefix=/usr \
            --docdir=/usr/share/doc/bison-3.7.1
make
make install
cd $LFS/sources
rm -rf bison-3.7.1

# 7.10.1 Perl
cd $LFS/sources
tar -xf perl-5.32.0.tar.xz
cd perl-5.32.0
sh Configure -des                                        \
             -Dprefix=/usr                               \
             -Dvendorprefix=/usr                         \
             -Dprivlib=/usr/lib/perl5/5.32/core_perl     \
             -Darchlib=/usr/lib/perl5/5.32/core_perl     \
             -Dsitelib=/usr/lib/perl5/5.32/site_perl     \
             -Dsitearch=/usr/lib/perl5/5.32/site_perl    \
             -Dvendorlib=/usr/lib/perl5/5.32/vendor_perl \
             -Dvendorarch=/usr/lib/perl5/5.32/vendor_perl
make
make install
cd $LFS/sources
rm -rf perl-5.32.0

# 7.11.1 Python
cd $LFS/sources
tar -xf Python-3.8.5.tar.xz
cd Python-3.8.5
./configure --prefix=/usr   \
            --enable-shared \
            --without-ensurepip
make
make install
cd $LFS/sources
rm -rf Python-3.8.5

# 7.12.1 Texinfo
cd $LFS/sources
tar -xf texinfo-6.7.tar.xz
cd texinfo-6.7
./configure --prefix=/usr
make
make install
cd $LFS/sources
rm -rf texinfo-6.7

# 7.13.1 Util-linux
cd $LFS/sources
tar -xf util-linux-2.36.tar.xz
cd util-linux-2.36
mkdir -pv /var/lib/hwclock
./configure ADJTIME_PATH=/var/lib/hwclock/adjtime    \
            --docdir=/usr/share/doc/util-linux-2.36 \
            --disable-chfn-chsh  \
            --disable-login      \
            --disable-nologin    \
            --disable-su         \
            --disable-setpriv    \
            --disable-runuser    \
            --disable-pylibmount \
            --disable-static     \
            --without-python
make
make install
cd $LFS/sources
rm -rf util-linux-2.36

# 7.14 Cleaning up
find /usr/{lib,libexec} -name \*.la -delete
rm -rf /usr/share/{info,man,doc}/*
HEREDOC

umount $LFS/dev{/pts,}
umount $LFS/{sys,proc,run}

# 7.14.1 Stripping
strip --strip-debug $LFS/usr/lib/*
strip --strip-unneeded $LFS/usr/{,s}bin/*
strip --strip-unneeded $LFS/tools/bin/*

# 7.14.2 Backup
cd $LFS &&
tar -cJpf $HOME/lfs-temp-tools-10.0.tar.xz .
