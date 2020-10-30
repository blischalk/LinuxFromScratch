#!/usr/bin/bash

# 5.2 Binutils Pass 1
cd $LFS/sources
echo $(pwd)
tar -xf binutils-2.35.tar.xz
cd binutils-2.35
mkdir -v build
cd       build
../configure --prefix=$LFS/tools       \
             --with-sysroot=$LFS        \
             --target=$LFS_TGT          \
             --disable-nls              \
             --disable-werror
make
make install
cd $LFS/sources
rm -rf $LFS/sources/binutils-2.35
