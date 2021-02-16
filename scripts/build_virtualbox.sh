#!/bin/bash

## @fn build_virtualbox()
## @brief Build VirtualBox from source using an unsquashed clonezilla CD as a
##        chrooted environment.
## @details Build scripts are copied from \b clonezilla/build
## @note This stage is only necessay if \b vbox-img is to be used to directly
##       convert the VDI virtual disk into a block device, on account of a bug
##       in Oracle source code (ticket #19901). @n
## This is only needed to reduce disk space requirements and avoid a temporary
## RAW file on disk of about 50 GB.
## Otherwise it is simpler to use the distribution stock version.
## @ingroup createInstaller

build_virtualbox() {

    cd "${VMPATH}" || exit 2
    ${LOG[*]} "[INF] Fetching live CD..."
    CLONEZILLA_INSTALL=true
    fetch_livecd
    mount_live_cd
    ${LOG[*]} "[MSG] VERSION: ${VBOX_VERSION_FULL}"
    cp -vf /etc/resolv.conf squashfs-root/etc
    for i in proc sys dev run; do mount -B "/$i" "squashfs-root/$i"; done
    cat > run.sh << EOF
#!/bin/bash
export DEBIAN_FRONTEND=noninteractive
apt update -yq
apt upgrade -yq <<< 'N'
apt install -yq  build-essential gcc <<< 'N'
apt-get -yq install acpica-tools chrpath doxygen g++-multilib libasound2-dev \
libcap-dev libcurl4-openssl-dev libdevmapper-dev libidl-dev libopus-dev \
libpam0g-dev libpulse-dev libqt5opengl5-dev libqt5x11extras5-dev libsdl1.2-dev \
libsdl-ttf2.0-dev libssl-dev libvpx-dev libxcursor-dev libxinerama-dev \
libxml2-dev libxml2-utils libxmu-dev libxrandr-dev make nasm python3-dev \
python-dev qttools5-dev-tools texlive texlive-fonts-extra texlive-latex-extra \
unzip xsltproc default-jdk libstdc++5 libxslt1-dev linux-kernel-headers \
makeself mesa-common-dev subversion yasm zlib1g-dev lib32z1 libc6-dev-i386 \
lib32gcc1 lib32stdc++6
ln -s libX11.so.6    /usr/lib32/libX11.so
ln -s libXTrap.so.6  /usr/lib32/libXTrap.so
ln -s libXt.so.6     /usr/lib32/libXt.so
ln -s libXtst.so.6   /usr/lib32/libXtst.so
ln -s libXmu.so.6    /usr/lib32/libXmu.so
ln -s libXext.so.6   /usr/lib32/libXext.so
wget https://download.virtualbox.org/virtualbox/${VBOX_VERSION}/\
VirtualBox-${VBOX_VERSION_FULL}.tar.bz2
tar xjf VirtualBox-${VBOX_VERSION_FULL}.tar.bz2
rm -f VirtualBox*bz2
mv VirtualBox-${VBOX_VERSION} VirtualBox
apt install -qy \$(apt-cache search linux-headers-.*generic | grep -v unsigned \
| head -n1 | cut -f 1 -d' ')
apt install -qy \$(apt-cache search linux-image-.*generic   | grep -v unsigned \
| head -n1 | cut -f 1 -d' ')
apt install -qy \$(apt-cache search linux-modules.*generic   | grep -v unsigned \
| head -n1 | cut -f 1 -d' ')
apt install -qy docbook docbook-xml
cd VirtualBox || exit 2
./configure --disable-hardening
chmod +x ./env.sh
source ./env.sh
sed -i "${LINENO_PATCH}d" src/VBox/Storage/testcase/vbox-img.cpp
echo Building...Please wait...
kmk all >/dev/null 2>&1
echo Packing...
kmk packing >/dev/null 2>&1
cd out/linux.amd64/release/bin/src/
KV=\$(apt-cache search linux-headers-.*generic | grep -v unsigned \
| head -n1 | cut -f 1 -d' ' | sed 's/linux-headers-//')
make KERN_VER=\${KV}
make KERN_VER=\${KV} install
cd ../.. || exit 2
rm -rf obj/
exit 0
EOF
    chmod +x run.sh
    cp -vf run.sh squashfs-root/
    chroot squashfs-root ./run.sh
    for i in proc sys dev run; do umount -l squashfs-root/$i; done
    cd "${VMPATH}" || exit 2
    [ -d virtualbox ] && rm -rf virtualbox
    mkdir virtualbox
    rsync -aH mnt2/live/squashfs-root/ virtualbox
    chown -R $USER virtualbox
    rm -rf mnt2/live/squashfs-root
    rm VirtualBox
    cat > VirtualBox << EOF
#!/bin/bash
export LD_LIBRARY_PATH="virtualbox/VirtualBox/out/linux.amd64/release/bin/\
:virtualbox/lib:virtualbox/lib32:virtualbox/lib64"
modprobe vboxdrv
./virtualbox/VirtualBox/out/linux.amd64/release/bin/VirtualBox \$*
EOF
    chmod +x VirtualBox
    chown $USER VirtualBox
    cat > vbox-img << EOF
#!/bin/bash
export LD_LIBRARY_PATH="virtualbox/VirtualBox/out/linux.amd64/release/bin/\
:virtualbox/lib:virtualbox/lib32:virtualbox/lib64"
./virtualbox/VirtualBox/out/linux.amd64/release/bin/vbox-img \$*
EOF
    chmod +x vbox-img
    chown $USER vbox-img
}
