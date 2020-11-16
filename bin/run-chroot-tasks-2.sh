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

# 8.3.1 Man-pages
cd $LFS/sources
tar -xf man-pages-5.08.tar.xz
cd man-pages-5.08
make install
cd $LFS/sources
rm -rf man-pages-5.08

# 8.4.1 Tcl
cd $LFS/sources
tar -xf tcl8.6.10-src.tar.gz
cd tcl8.6.10-src
tar -xf ../tcl8.6.10-html.tar.gz --strip-components=1
SRCDIR=$(pwd)
cd unix
./configure --prefix=/usr           \
            --mandir=/usr/share/man \
            $([ "$(uname -m)" = x86_64 ] && echo --enable-64bit)
make

sed -e "s|$SRCDIR/unix|/usr/lib|" \
    -e "s|$SRCDIR|/usr/include|"  \
    -i tclConfig.sh

sed -e "s|$SRCDIR/unix/pkgs/tdbc1.1.1|/usr/lib/tdbc1.1.1|" \
    -e "s|$SRCDIR/pkgs/tdbc1.1.1/generic|/usr/include|"    \
    -e "s|$SRCDIR/pkgs/tdbc1.1.1/library|/usr/lib/tcl8.6|" \
    -e "s|$SRCDIR/pkgs/tdbc1.1.1|/usr/include|"            \
    -i pkgs/tdbc1.1.1/tdbcConfig.sh

sed -e "s|$SRCDIR/unix/pkgs/itcl4.2.0|/usr/lib/itcl4.2.0|" \
    -e "s|$SRCDIR/pkgs/itcl4.2.0/generic|/usr/include|"    \
    -e "s|$SRCDIR/pkgs/itcl4.2.0|/usr/include|"            \
    -i pkgs/itcl4.2.0/itclConfig.sh

unset SRCDIR
make test
make install
chmod -v u+w /usr/lib/libtcl8.6.so
make install-private-headers
ln -sfv tclsh8.6 /usr/bin/tclsh
cd $LFS/sources
rm -rf tcl8.6.10-src


# 8.5.1 Expect
cd $LFS/sources
tar -xf expect5.45.4.tar.gz
cd expect5.45.4
./configure --prefix=/usr           \
            --with-tcl=/usr/lib     \
            --enable-shared         \
            --mandir=/usr/share/man \
            --with-tclinclude=/usr/include
make
make test
make install
ln -svf expect5.45.4/libexpect5.45.4.so /usr/lib
cd $LFS/sources
rm -rf expect5.45.4

# 8.6.1 DejaGNU
cd $LFS/sources
tar -xf dejagnu-1.6.2.tar.gz
cd dejagnu-1.6.2
./configure --prefix=/usr
makeinfo --html --no-split -o doc/dejagnu.html doc/dejagnu.texi
makeinfo --plaintext       -o doc/dejagnu.txt  doc/dejagnu.texi
make install
install -v -dm755  /usr/share/doc/dejagnu-1.6.2
install -v -m644   doc/dejagnu.{html,txt} /usr/share/doc/dejagnu-1.6.2
make check
cd $LFS/sources
rm -rf dejagnu-1.6.2

# 8.7.1 Iana-Etc
cd $LFS/sources
tar -xf iana-etc-20200821.tar.gz
cd iana-etc-20200821
cp services protocols /etc
cd $LFS/sources
rm -rf iana-etc-20200821

# 8.8.1 Glibc
cd $LFS/sources
tar -xf glibc-2.32.tar.xz
cd glibc-2.32
patch -Np1 -i ../glibc-2.32-fhs-1.patch
mkdir -v build
cd       build
../configure --prefix=/usr                            \
             --disable-werror                         \
             --enable-kernel=3.2                      \
             --enable-stack-protector=strong          \
             --with-headers=/usr/include              \
             libc_cv_slibdir=/lib
make
case $(uname -m) in
  i?86)   ln -sfnv $PWD/elf/ld-linux.so.2        /lib ;;
  x86_64) ln -sfnv $PWD/elf/ld-linux-x86-64.so.2 /lib ;;
esac
make check
touch /etc/ld.so.conf
sed '/test-installation/s@$(PERL)@echo not running@' -i ../Makefile
make install
cp -v ../nscd/nscd.conf /etc/nscd.conf
mkdir -pv /var/cache/nscd
mkdir -pv /usr/lib/locale
localedef -i POSIX -f UTF-8 C.UTF-8 2> /dev/null || true
localedef -i cs_CZ -f UTF-8 cs_CZ.UTF-8
localedef -i de_DE -f ISO-8859-1 de_DE
localedef -i de_DE@euro -f ISO-8859-15 de_DE@euro
localedef -i de_DE -f UTF-8 de_DE.UTF-8
localedef -i el_GR -f ISO-8859-7 el_GR
localedef -i en_GB -f UTF-8 en_GB.UTF-8
localedef -i en_HK -f ISO-8859-1 en_HK
localedef -i en_PH -f ISO-8859-1 en_PH
localedef -i en_US -f ISO-8859-1 en_US
localedef -i en_US -f UTF-8 en_US.UTF-8
localedef -i es_MX -f ISO-8859-1 es_MX
localedef -i fa_IR -f UTF-8 fa_IR
localedef -i fr_FR -f ISO-8859-1 fr_FR
localedef -i fr_FR@euro -f ISO-8859-15 fr_FR@euro
localedef -i fr_FR -f UTF-8 fr_FR.UTF-8
localedef -i it_IT -f ISO-8859-1 it_IT
localedef -i it_IT -f UTF-8 it_IT.UTF-8
localedef -i ja_JP -f EUC-JP ja_JP
localedef -i ja_JP -f SHIFT_JIS ja_JP.SIJS 2> /dev/null || true
localedef -i ja_JP -f UTF-8 ja_JP.UTF-8
localedef -i ru_RU -f KOI8-R ru_RU.KOI8-R
localedef -i ru_RU -f UTF-8 ru_RU.UTF-8
localedef -i tr_TR -f UTF-8 tr_TR.UTF-8
localedef -i zh_CN -f GB18030 zh_CN.GB18030
localedef -i zh_HK -f BIG5-HKSCS zh_HK.BIG5-HKSCS
make localedata/install-locales

# 8.8.2 Configuring Glibc
cat > /etc/nsswitch.conf << "EOF"
# Begin /etc/nsswitch.conf

passwd: files
group: files
shadow: files

hosts: files dns
networks: files

protocols: files
services: files
ethers: files
rpc: files

# End /etc/nsswitch.conf
EOF

# 8.8.2.2 Adding time zone data
tar -xf ../../tzdata2020a.tar.gz

ZONEINFO=/usr/share/zoneinfo
mkdir -pv $ZONEINFO/{posix,right}

for tz in etcetera southamerica northamerica europe africa antarctica  \
          asia australasia backward pacificnew systemv; do
    zic -L /dev/null   -d $ZONEINFO       ${tz}
    zic -L /dev/null   -d $ZONEINFO/posix ${tz}
    zic -L leapseconds -d $ZONEINFO/right ${tz}
done

cp -v zone.tab zone1970.tab iso3166.tab $ZONEINFO
zic -d $ZONEINFO -p America/New_York
unset ZONEINFO

tzselect

ln -sfv /usr/share/zoneinfo/<xxx> /etc/localtime

# 8.8.2.3 Configuring the Dynamic Loader
cat > /etc/ld.so.conf << "EOF"
# Begin /etc/ld.so.conf
/usr/local/lib
/opt/lib

EOF

cat >> /etc/ld.so.conf << "EOF"
# Add an include directory
include /etc/ld.so.conf.d/*.conf

EOF
mkdir -pv /etc/ld.so.conf.d


cd $LFS/sources
rm -rf glibc-2.32

# 8.9.1 Zlib
cd $LFS/sources
tar -xf zlib-1.2.11.tar.xz
cd zlib-1.2.11
./configure --prefix=/usr
make
make check
make install
mv -v /usr/lib/libz.so.* /lib
ln -sfv ../../lib/$(readlink /usr/lib/libz.so) /usr/lib/libz.so
cd $LFS/sources
rm -rf zlib-1.2.11

# 8.10.1 Bzip2
cd $LFS/sources
tar -xf bzip2-1.0.8.tar.gz
cd bzip2-1.0.8
patch -Np1 -i ../bzip2-1.0.8-install_docs-1.patch
sed -i 's@\(ln -s -f \)$(PREFIX)/bin/@\1@' Makefile
sed -i "s@(PREFIX)/man@(PREFIX)/share/man@g" Makefile
make -f Makefile-libbz2_so
make clean
make
make PREFIX=/usr install
cp -v bzip2-shared /bin/bzip2
cp -av libbz2.so* /lib
ln -sv ../../lib/libbz2.so.1.0 /usr/lib/libbz2.so
rm -v /usr/bin/{bunzip2,bzcat,bzip2}
ln -sv bzip2 /bin/bunzip2
ln -sv bzip2 /bin/bzcat
bzip2-1.0.8cd $LFS/sources
rm -rf bzip2-1.0.8

# 8.11.1 Xz
cd $LFS/sources
tar -xf xz-5.2.5.tar.xz
cd xz-5.2.5
./configure --prefix=/usr    \
            --disable-static \
            --docdir=/usr/share/doc/xz-5.2.5
make
make check
make install
mv -v   /usr/bin/{lzma,unlzma,lzcat,xz,unxz,xzcat} /bin
mv -v /usr/lib/liblzma.so.* /lib
ln -svf ../../lib/$(readlink /usr/lib/liblzma.so) /usr/lib/liblzma.so

cd $LFS/sources
rm -rf xz-5.2.5

# 8.12.1 Zstd

cd $LFS/sources
tar -xf zstd-1.4.5.tar.gz
cd zstd-1.4.5
make
make prefix=/usr install
rm -v /usr/lib/libzstd.a
mv -v /usr/lib/libzstd.so.* /lib
ln -sfv ../../lib/$(readlink /usr/lib/libzstd.so) /usr/lib/libzstd.so

cd $LFS/sources
rm -rf zstd-1.4.5

# 8.13.1 File
cd $LFS/sources
tar -xf file-5.39.tar.gz
cd file-5.39
./configure --prefix=/usr
make
make check
make install
cd $LFS/sources
rm -rf file-5.39

# 8.14.1 Readline
cd $LFS/sources
tar -xf readline-8.0.tar.gz
cd readline-8.0
sed -i '/MV.*old/d' Makefile.in
sed -i '/{OLDSUFF}/c:' support/shlib-install
./configure --prefix=/usr    \
            --disable-static \
            --with-curses    \
            --docdir=/usr/share/doc/readline-8.0
make SHLIB_LIBS="-lncursesw"
make SHLIB_LIBS="-lncursesw" install
mv -v /usr/lib/lib{readline,history}.so.* /lib
chmod -v u+w /lib/lib{readline,history}.so.*
ln -sfv ../../lib/$(readlink /usr/lib/libreadline.so) /usr/lib/libreadline.so
ln -sfv ../../lib/$(readlink /usr/lib/libhistory.so ) /usr/lib/libhistory.so
install -v -m644 doc/*.{ps,pdf,html,dvi} /usr/share/doc/readline-8.0
cd $LFS/sources
rm -rf readline-8.0

# 8.15.1 M4
cd $LFS/sources
tar -xf m4-1.4.18.tar.xz
cd m4-1.4.18
sed -i 's/IO_ftrylockfile/IO_EOF_SEEN/' lib/*.c
echo "#define _IO_IN_BACKUP 0x100" >> lib/stdio-impl.h
./configure --prefix=/usr
make
make check
make install
cd $LFS/sources
rm -rf m4-1.4.18

# 8.16.1 Bc
cd $LFS/sources
tar -xf bc-3.1.5.tar.xz
cd bc-3.1.5
PREFIX=/usr CC=gcc CFLAGS="-std=c99" ./configure.sh -G -O3
make
make test
make install
cd $LFS/sources
rm -rf bc-3.1.5

# 8.17.1 Flex
cd $LFS/sources
tar -xf flex-2.6.4.tar.gz
cd flex-2.6.4
./configure --prefix=/usr --docdir=/usr/share/doc/flex-2.6.4
make
make check
make install
ln -sv flex /usr/bin/lex
cd $LFS/sources
rm -rf flex-2.6.4

# 8.18.1 Binutils
cd $LFS/sources
tar -xf binutils-2.35.tar.xz
cd binutils-2.35
expect -c "spawn ls"
sed -i '/@\tincremental_copy/d' gold/testsuite/Makefile.in
mkdir -v build
cd       build
../configure --prefix=/usr       \
             --enable-gold       \
             --enable-ld=default \
             --enable-plugins    \
             --enable-shared     \
             --disable-werror    \
             --enable-64-bit-bfd \
             --with-system-zlib
make tooldir=/usr
make -k check
make tooldir=/usr install
cd $LFS/sources
rm -rf binutils-2.35

# 8.19.1 GMP
cd $LFS/sources
tar -xf gmp-6.2.0.tar.xz
cd gmp-6.2.0
./configure --prefix=/usr    \
            --enable-cxx     \
            --disable-static \
            --docdir=/usr/share/doc/gmp-6.2.0
make
make html
make check 2>&1 | tee gmp-check-log
awk '/# PASS:/{total+=$3} ; END{print total}' gmp-check-log
make install
make install-html
cd $LFS/sources
rm -rf gmp-6.2.0

# 8.20.1 MPFR
cd $LFS/sources
tar -xf mpfr-4.1.0.tar.xz
cd mpfr-4.1.0
./configure --prefix=/usr        \
            --disable-static     \
            --enable-thread-safe \
            --docdir=/usr/share/doc/mpfr-4.1.0
make
make html
make check
make install
make install-html
cd $LFS/sources
rm -rf mpfr-4.1.0

# 8.21.1 MPC
cd $LFS/sources
tar -xf mpc-1.1.0.tar.gz
cd mpc-1.1.0
./configure --prefix=/usr    \
            --disable-static \
            --docdir=/usr/share/doc/mpc-1.1.0
make
make html
make check
make install
make install-html
cd $LFS/sources
rm -rf mpc-1.1.0

# 8.22.1 Attr

cd $LFS/sources
tar -xf attr-2.4.48.tar.gz
cd attr-2.4.48
./configure --prefix=/usr     \
            --bindir=/bin     \
            --disable-static  \
            --sysconfdir=/etc \
            --docdir=/usr/share/doc/attr-2.4.48
make
make check
make install
mv -v /usr/lib/libattr.so.* /lib
ln -sfv ../../lib/$(readlink /usr/lib/libattr.so) /usr/lib/libattr.so
cd $LFS/sources
rm -rf attr-2.4.48

# 8.23.1 Acl
cd $LFS/sources
tar -xf acl-2.2.53.tar.gz
cd acl-2.2.53
./configure --prefix=/usr         \
            --bindir=/bin         \
            --disable-static      \
            --libexecdir=/usr/lib \
            --docdir=/usr/share/doc/acl-2.2.53
make
make install
mv -v /usr/lib/libacl.so.* /lib
ln -sfv ../../lib/$(readlink /usr/lib/libacl.so) /usr/lib/libacl.so
cd $LFS/sources
rm -rf acl-2.2.53

# 8.24.1 Libcap
cd $LFS/sources
tar -xf libcap-2.42.tar.xz
cd libcap-2.42
sed -i '/install -m.*STACAPLIBNAME/d' libcap/Makefile
make lib=lib
make test
make lib=lib PKGCONFIGDIR=/usr/lib/pkgconfig install
chmod -v 755 /lib/libcap.so.2.42
mv -v /lib/libpsx.a /usr/lib
rm -v /lib/libcap.so
ln -sfv ../../lib/libcap.so.2 /usr/lib/libcap.so
cd $LFS/sources
rm -rf libcap-2.42

# 8.25.1 Shadow
cd $LFS/sources
tar -xf shadow-4.8.1.tar.xz
cd shadow-4.8.1
sed -i 's/groups$(EXEEXT) //' src/Makefile.in
find man -name Makefile.in -exec sed -i 's/groups\.1 / /'   {} \;
find man -name Makefile.in -exec sed -i 's/getspnam\.3 / /' {} \;
find man -name Makefile.in -exec sed -i 's/passwd\.5 / /'   {} \;
sed -e 's:#ENCRYPT_METHOD DES:ENCRYPT_METHOD SHA512:' \
    -e 's:/var/spool/mail:/var/mail:'                 \
    -i etc/login.defs
sed -i 's/1000/999/' etc/useradd
touch /usr/bin/passwd
./configure --sysconfdir=/etc \
            --with-group-name-max-length=32
make
make install
pwconv
grpconv

# If we make it here Yay!
passwd root

cd $LFS/sources
rm -rf shadow-4.8.1

# 8.26.1 GCC
HEREDOC
