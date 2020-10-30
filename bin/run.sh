#!/usr/bin/bash
echo "Building LFS"
export LFS=/lfs
echo "export LFS=$LFS" > /root/.bash_profile
echo "export LFS=$LFS" > /root/.bashrc
mkdir -v $LFS/sources
chmod -v a+wt $LFS/sources
wget --input-file=wget-list --continue --directory-prefix=$LFS/sources
pushd $LFS/sources
  md5sum -c md5sums
popd

