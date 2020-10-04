#!/bin/bash

# *
# * Copyright (c) 2020 Fabrice Nicol <fabrnicol@gmail.com>
# *
# * This file is part of mkgentoo.
# *
# * mkgentoo is free software; you can redistribute it and/or
# * modify it under the terms of the GNU Lesser General Public
# * License as published by the Free Software Foundation; either
# * version 3 of the License, or (at your option) any later version.
# *
# * FFmpeg is distributed in the hope that it will be useful,
# * but WITHOUT ANY WARRANTY; without even the implied warranty of
# * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
# * Lesser General Public License for more details.
# *
# * You should have received a copy of the GNU Lesser General Public
# * License along with FFmpeg; if not, write to the Free Software
# * Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA
# *******************************************************************************
#
## @file mkvm_chroot.sh
## @author Fabrice Nicol
## @copyright GPL v.3
## @brief Creating Gentoo filesystem in virtual disk
## @note This file is included into the clonezilla ISO liveCD,
## then copied to the root of the virtual disk.
## @defgroup mkFileSystem Create Gentoo linux filesystem on VM disk and emerge software.

## @fn adjust_environment()
## @details
## @li Set @b /etc/fstab, sync portage tree, select desktop profile @n
## @li Set a set of per-package use files and keywords @n
## @li Oneshot emerge of @b cmake and @b lz4, prerequisites to
## <tt> world </tt> update.
## @li Update <tt> world </tt>. Log into emerge.build. Exit on error. @n
## @li Set keymaps, localization and time
## @todo Add more regional options by parametrization of commandline
## @retval Exit -1 on error at <tt>emerge</tt> stage.
## @ingroup mkFileSystem

adjust_environment() {

    # Adjusting /etc/fstab

    local uuid2=$(blkid | grep sda2 | cut -f2 -d' ')
    local uuid3=$(blkid | grep sda3 | cut -f2 -d' ')
    local uuid4=$(blkid | grep sda4 | cut -f2 -d' ')
    echo "Partition /dev/sda2 with ${uuid2}" | tee partition_log
    echo "Partition /dev/sda3 with ${uuid3}" | tee partition_log
    echo "Partition /dev/sda4 with ${uuid4}" | tee partition_log
    echo "${uuid2} /boot           vfat defaults            0 2"  >  /etc/fstab
    echo "${uuid3} none            swap sw                  0 0"  >> /etc/fstab
    echo "${uuid4} /               ext4 defaults            0 1"  >> /etc/fstab
    echo "/dev/cdrom /mnt/cdrom  auto noauto,user,discard 0 0"    >> /etc/fstab
    source /etc/profile

    # Refresh and rebuild @world
    # frequently emerge complains about having to be upgraded before anything else.
    # We shall use emerge-webrsync as emerge --sync is a bit less robust (rsync rotation bans...)

    emerge-webrsync
    ! emerge -1 sys-apps/portage \
        && echo "emerge-webrsync failed!" | tee emerge.build && exit -1

    # add logger

    emerge -1 app-admin/sysklogd
    rc-update add sysklogd default

    # select profile (most recent plasma desktop)

    local profile=$(eselect profile list \
                        | grep desktop \
                        | grep plasma \
                        | grep ${PROCESSOR} \
                        | grep -v systemd \
                        | tail -1 \
                        | cut -f1 -d'[' | cut -f1 -d']')

    eselect profile set ${profile}

    # Use and keywords (mkdir -p to neutralize error msg)

    mkdir -p /etc/portage/package.accept_keywords
    mkdir -p /etc/portage/package.use
    mv -vf "${ELIST}.accept_keywords" /etc/portage/package.accept_keywords/
    mf -vf "${ELIST}.use"             /etc/portage/package.use/

    # One needs to build cmake without the qt5 USE value first, otherwise dependencies cannot be resolved.

    USE='-qt5' emerge -1 cmake
    [ $? != 0 ] && logger -s "emerge cmake failed!" && exit -1

    # other core sysapps to be merged first. LZ4 is a kernel dependency for newer linux kernels.

    emerge app-arch/lz4
    emerge net-misc/netifrc
    emerge sys-apps/pcmciautils
    [ $? != 0 ] && logger -s "emerge netifrs/pcmiautils failed!"

    # Now on to updating @world set. Be patient and wait for about 15-24 hours
    # as syslogd is not yet there we tee a custom build log

    emerge -uDN @world  2>&1  | tee emerge.build
    [ $? != 0 ] && logger -s "emerge @world failed!"  | tee emerge.build \
                && exit -1

    # Networking in the new environment

    echo hostname=${NONROOT_USER}pc > /etc/conf.d/hostname
    cd /etc/init.d
    ln -s net.lo net.${iface}
    cd -
    rc-update add net.${iface} default

    # Set keymaps and time

    if [ "${LANGUAGE}" = "fr" ]
    then
        echo 'keymap="fr"' > /etc/conf.d/keymaps
        echo 'keymap="us"' >> /etc/conf.d/keymaps
    else
        echo 'keymap="us"' > /etc/conf.d/keymaps
    fi
    sed -i 's/clock=.*/clock="local"/' /etc/conf.d/hwclock

    # Localization.

    echo "fr_FR.UTF-8 UTF-8" > /etc/locale.gen
    echo "fr_FR ISO-8859-15" >> /etc/locale.gen
    echo "en_US.UTF-8 UTF-8" >> /etc/locale.gen
    echo "en_US ISO-8859-1"  >> /etc/locale.gen
    locale-gen
    eselect locale set 1
    env-update && source /etc/profile && export PS1="(chroot) ${PS1}"
}

## @fn build_kernel()
## @details
## @li Emerge \b gentoo-sources, \b genkernel, \b pciutils and \b linux-firmware
## @li Mount /dev/sda2 to /boot/
## @li Build kernel and initramfs. Log into kernel.log.
## @retval Exit -1 on error.
## @ingroup mkFileSystem

build_kernel() {

    # Building the kernel

    emerge gentoo-sources sys-kernel/genkernel pciutils

    # Now mount the new boot partition

    mount /dev/sda2 /boot
    cp -vf .config /usr/src/linux
    cd /usr/src/linux

    # kernel config issue here

    make syncconfig  # replaces silentoldconfig as of 4.19
    make -s -j${NCPUS} 2>&1 > kernel.log && make modules_install && make install
    [ $? != 0 ] && logger -s "Kernel building failed!" &&  exit -1
    genkernel --install initramfs
    emerge sys-kernel/linux-firmware
    make clean
    [ -f /boot/vmlinu* ] && logger -s "Kernel was built" \
                         || { logger -s "Kernel compilation failed!"; exit -1; }
    [ -f /boot/initr*.img ] && { logger -s "initramfs was built"; \
                                 logger -s "initramfs compilation failed!"; \
                                 exit -1; }
}

## @fn install_software()
## @details
## @li Emerge list of ebuilds on top of stage3 and system utils already merged.
## @li Optionaly download and build RStudio
## @retval Exit -1 on building errors
## @todo Add a script to build R dependencies
## @ingroup mkFileSystem

install_software() {

    # to avoid corruption cases of ebuild list dues to Windows editing

    cd /
    emerge dos2unix
    chown root ${ELIST}
    chmod +rw ${ELIST}
    dos2unix ${ELIST}

    # TODO: develop several options wrt to package set.

    local packages=`grep -E -v '(^\s*$|^\s*#.*$)' ${ELIST} | sed "s/dev-lang\/R-.*$/dev-lang\/R-${R_VERSION}/"`

    # Trace for debugging

    echo ${packages} > package_list

    # do not quote `packages' variable!

    emerge -uDN ${packages}  2>&1 | tee log_install_software
    if [ $? != 0 ]; then
        logger -s "Main package build step failed!"
        exit -1
    fi

    # update environment

    env-update
    source /etc/profile

    # optionally build RStudio and R dependencies (TODO)

    ! "${DOWNLOAD_RSTUDIO}" && logger -s "No RStudio build" &&  return -1

    mkdir Build
    cd Build
    wget ${GITHUBPATH}${RSTUDIO}.zip
    [ $? != 0 ] && logger -s "RStudio download failed!" &&  exit -1
    logger -s "Building RStudio"
    unzip *.zip
    cd rstudio*
    mkdir build
    cd dependencies/common
    ./install-mathjax
    ./install-dictionaries
    ./install-pandoc
    cd -
    cd build
    cmake .. -DRSTUDIO_TARGET=Desktop -DCMAKE_BUILD_TYPE=Release -DRSTUDIO_USE_SYSTEM_BOOST=1 -DQT_QMAKE_EXECUTABLE=1
    make -j${NCPUS} | tee log_install_software
    make -k install
    cd /
}


## @fn global_config()
## @details @li Cleanup log, distfiles (for deployment), kernel build sources and objects
## @li Log this into \b log_uninstall_software
## @li Update \b eix cache. Sets displaymanager for \b xdm.
## @li Add services: <b>sysklog, cronie, xdm, dbus, elogind</b>
## @li Substitute \b NetworkManager to temporary networking setup.
## @li Adjust group and \b sudo settings for non-root user and \b sddm
## @li Install \b grub in EFI mode.
## @li Set passwords for root and non-root user.
## @warning Fix \b sddm startup keyboard issue using <tt> setxkbmap</tt>
## @ingroup mkFileSystem

global_config() {
    logger -s "Cleaning up a bit aggressively before cloning..."
    eclean -d packages 2>&1 | tee log_uninstall_software.log
    rm -rf /var/tmp/*
    rm -rf /var/log/*
    rm -rf /var/cache/distfiles/*

    # kernel sources will have to be reinstalled by user if necessary

    emerge --unmerge gentoo-sources  2>&1 | tee log_uninstall_software.log
    emerge --depclean   2>&1              | tee log_uninstall_software.log
    rm -rf /usr/src/linux/*               | tee log_uninstall_software.log
    eix-update

    # Idealy the installers should do:
    # emerge gentoo-sources
    # cd /usr/src/linux
    # cp -f /boot/config* .config
    # make syncconfig
    # make modules_prepare
    # for the sake of ebuilds requesting prepared kernel sources
    # TODO: test ocs-run post_run commands.
    # Also for usb_installer=... *alone* the above code could be deactivated.
    # But then a later from_vm call would have to clean sources to lighten the resulting ISO clonezilla image.

    # Configuration
    #--- sddm

    echo "#!/bin/sh"                   > /usr/share/sddm/scripts/Xsetup
    echo "setxkbmap ${LANGUAGE},us"    > /usr/share/sddm/scripts/Xsetup
    chmod +x /usr/share/sddm/scripts/Xsetup
    sed -i 's/DISPLAYMANAGER=".*"/DISPLAYMANAGER="sddm"/' /etc/conf.d/xdm

    #--- Services

    rc-update add sysklogd default
    rc-update add cronie default
    rc-update add xdm default
    rc-update add dbus default
    rc-update add elogind boot

    #--- Networkmanager

    for x in /etc/runlevels/default/net.*
    do
        rc-update del $(basename $x) default
        rc-service --ifstarted $(basename $x) stop
    done
    rc-update del dhcpcd default
    rc-update add NetworkManager default

    #--- groups and sudo

    useradd -m -G users,wheel,audio,video,plugdev,sudo  -s /bin/bash ${NONROOT_USER}
    echo "${NONROOT_USER}     ALL=(ALL:ALL) ALL" >> /etc/sudoers
    gpasswd -a sddm video

    #--- Creating the bootloader

    grub-install --target=x86_64-efi --efi-directory=/boot --removable
    grub-mkconfig -o /boot/grub/grub.cfg

    #--- Passwords

    chpasswd <<< ${NONROOT_USER}:${PASSWD}
    chpasswd <<<  root:${ROOTPASSWD}
}

## @fn finalize()
## @details @li Cleanup \b .bashrc
## @li Cleanup other files except for logs if debug mode is on.
## @li Write zeros as much as possible to prepare for compacting.
## @ingroup mkFileSystem

finalize() {

    # Final steps: cleaning up

    sed -i 's/^export .*$//g' .bashrc
    rm -f mkvm_chroot.sh package_list ${ELIST}
    [ "${DEBUG_MODE}" = "false" ] && rm -f *

    # prepare to compact with vbox-img compact --filename ${VMPATH}/${VM}.vdi

    cat /dev/zero > zeros ; sync ; rm zeros
}

declare -i res=0
adjust_environment
[ $? = 0 ] || res=1
build_kernel
[ $? = 0 ] || res=$((res | 2))
install_software
[ $? = 0 ] || res=$((res | 4))
global_config
[ $? = 0 ] || res=$((res | 8))
finalize
[ $? = 0 ] || res=$((res | 16))
logger -s "Exiting with code: ${res}"
exit ${res}

# note: return code will be 0 if all went smoothly
# otherwise:
#    odd number: Issue with adjust_environment
#    code or code -1 is even: Issue with build_kernel
#    code - {0,1,2,3}  can be divided by 4: Issue with install_software
#    code - {0,...,7}  can be divided by 8: Issue with global_config
#    code - {0,...,15} can be divided by 16: Issue with finalize
