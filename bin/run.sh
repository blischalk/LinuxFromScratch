#!/usr/bin/bash
echo "Building LFS"
# 2.6
export LFS=/lfs
export DEFAULT_LFS_PASSWORD=changeme
echo "export LFS=$LFS" > /root/.bash_profile
echo "export LFS=$LFS" > /root/.bashrc

# 3.1
mkdir -v $LFS/sources
chmod -v a+wt $LFS/sources
wget --input-file=wget-list --continue --directory-prefix=$LFS/sources
pushd $LFS/sources
  md5sum -c md5sums
popd

# Copy previously vendored patches from 3.3 into sources directory
copy -R patches/* $LFS/sources

# 4.2
mkdir -pv $LFS/{bin,etc,lib,sbin,usr,var}
case $(uname -m) in
  x86_64) mkdir -pv $LFS/lib64 ;;
esac
mkdir -pv $LFS/tools

# 4.3
groupadd lfs
useradd -s /bin/bash -g lfs -m -k /dev/null lfs

# Change the users password via stdin for automation
echo $DEFAULT_LFS_PASSWORD | passwd --stdin lfs

chown -v lfs $LFS/{usr,lib,var,etc,bin,sbin,tools}
case $(uname -m) in
  x86_64) chown -v lfs $LFS/lib64 ;;
esac
chown -v lfs $LFS/sources

# Run commands as lfs user in HEREDOC since we can't actually
# login as a user in a script
su lfs <<HEREDOC
  whoami
HEREDOC
