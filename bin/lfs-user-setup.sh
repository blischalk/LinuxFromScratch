#!/usr/bin/bash
set -euxo pipefail
# 4.4
cat > ~/.bash_profile << "EOF"
echo 'loaded bash_profile'
exec env -i HOME=$HOME TERM=$TERM PS1='\u:\w\$ ' /bin/bash -i
EOF

cat > ~/.bashrc << "EOF"
echo 'loaded bashrc'
set +h
umask 022
LFS=/lfs
LC_ALL=POSIX
LFS_TGT=$(uname -m)-lfs-linux-gnu
PATH=/usr/bin
if [ ! -L /bin ]; then PATH=/bin:$PATH; fi
PATH=$LFS/tools/bin:$PATH
export LFS LC_ALL LFS_TGT PATH
EOF
