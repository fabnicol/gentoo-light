#!/bin/bash

##
# Copyright (c) 2020-2021 Fabrice Nicol <fabrnicol@gmail.com>
#
# This file is part of mkg.
#
# mkg is free software; you can redistribute it and/or
# modify it under the terms of the GNU Lesser General Public
# License as published by the Free Software Foundation; either
# version 3 of the License, or (at your option) any later version.
#
# FFmpeg is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
# Lesser General Public License for more details.
#
# You should have received a copy of the GNU Lesser General Public
# License along with FFmpeg; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor,
# Boston, MA 02110-1301
##

# ------------------------------------------------------------------ #
# etags note
# ----------
#
# Owing to a bug in the Emacs etags program
# Use instead "Exuberant ctags" with option -e to create file TAGS
#
# ------------------------------------------------------------------ #

## @mainpage Usage
## @brief In a nutshell
## @n
## @code ./mkg [command=argument] ... [command=argument]  [file.iso]
## @endcode
## @n
## @details
## See
## <a href="https://github.com/fabnicol/gentoo-creator/wiki">
## <b>Wiki</b></a> for details.
## @n
## @author Fabrice Nicol 2020
## @copyright This software is licensed under the terms of the
## <a href="https://www.gnu.org/licenses/gpl-3.0.en.html">
## <b>GPL v3</b></a>

## @file mkgentoo.sh
## @author Fabrice Nicol <fabrnicol@gmail.com>
## @copyright GPL v.3
## @brief Process options, create Gentoo VirtualBox machine and optionally
##        create clonezilla install medium
## @note This file is not included into the clonezilla ISO liveCD.
## @par USAGE
## @code
## mkg  [[switch=argument]...]  filename.iso  [1]
## mkg  [[switch=argument]...]                [2]
## mkg  help[=md]                             [3]
## @endcode
## @par
## Usage [1] creates a bootable ISO output file with a current Gentoo
## distribution.   @n
## Usage [2] creates a VirtualBox VDI dynamic disk and a virtual machine with
## name Gentoo.   @n
## Usage [3] prints this help, in markdown form if argument 'md' is specified.
## @n
## @par
## Run: @code mkg help @endcode to print a list of possible switches and
## arguments.
## @warning you should have at least 55 GB of free disk space in the current
## directory or in vmpath
## if specified.
## Boolean values are either 'true' or 'false'. An option no followed by '='
## is equivalent to @b option=true, except for help and a possible ISO file.
## For example, to build a minimal:
## distribution,specify <tt>minimal</tt> or <tt> minimal=true</tt>
## on command line.
## @par \b Examples:
## @li Only create the VM and virtual disk, in debug mode,
## without R and set new passwords, for a French-language platform.
## Use 8 cores.
## @code mkg language=fr minimal debug_mode ncpus=8
## nonroot_user=ken passwd='util!Hx&32F' rootpasswd='Hk_32!_CD' cleanup=false
## @endcode
## @li Create ISO clonezilla image of Gentoo linux, burn it to DVD, create an
## installed OS
## on a USB stick whose model label starts with \e PNY and finally create a
## clonezilla installer
## on another USB stick mounted under <tt> /media/ken/AA45E </tt>
## @code mkgento burn hot_install ext_device="PNY" device_installer
## ext_device="Sams" my_gentoo_image.iso
## @endcode
## @defgroup createInstaller Create Gentoo linux image and installer.


# ---------------------------------------------------------------------------- #
# Global declarations
#

## @var ISO
## @brief Name of downloaded clonezilla ISO file
## @ingroup createInstaller

declare -x ISO="downloaded.iso"

## @var CREATE_ISO
## @brief Custom name of ISO output. Default value is false
##        Can be reversed by a name of type filename.iso on command line,
##        previously created and reused to burn or dd to device installer.
## @ingroup createInstaller

declare -x CREATE_ISO=false

# ---------------------------------------------------------------------------- #
# Helper functions
#

## @fn help_md()
## @brief Print usage in markdown format
## @note white space at end of echoes is there for markdown in post-processing
## @ingroup createInstaller

help_md() {

    local count=$(($(nproc --all)/3))
    echo "**USAGE:**  "
    echo "**mkg**                                        [1]  "
    echo "**mkg**  [[switch=argument]...]  filename.iso  [2]  "
    echo "**mkg**  [[switch=argument]...]                [3]  "
    echo "**mkg**  help[=md]                             [4]  "
    echo "  "
    echo "Usage [1] and [2] create a bootable ISO output file with a current"
    echo "Gentoo distribution.  "
    echo "For [1], implicit ISO output name is **gentoo.iso**  "
    echo "Usage [3] creates a VirtualBox VDI dynamic disk and a virtual machine"
    echo "with name Gentoo.  "
    echo "Usage [4] prints this help, in markdown form if argument 'md' is"
    echo "specified.  "
    echo "Warning: you should have at least 55 GB of free disk space in the"
    echo "current directory or in vmpath if specified.  "
    echo "  "
    echo "**Switches:**  "
    echo "  "
    echo "Boolean values are either 'true' or 'false'. For example, to build"
    echo "a minimal distribution, specify:  "
    echo ">  minimal=true  "
    echo "  "
    echo "on command line.  "
    echo "  "
    echo "Type Conventions:  "
    echo "b: true/false Boolean  "
    echo "o: on/off Boolean  "
    echo "n: Integer  "
    echo "f: Filepath  "
    echo "d: Directory path  "
    echo "e: Email address  "
    echo "s: String  "
    echo "u: URL  "
    echo
    echo "When a field depends on another, a colon separates the type and"
    echo "the name of the dependency."
    echo "   "
    echo "   "
    echo " | Option | Description | Default value |  "
    echo " |:-----:|:--------:|:-----:|:---------:|  "
    declare -i i
    for ((i=0; i<ARRAY_LENGTH; i++)); do
        declare -i sw=i*4       # no spaces!
        declare -i desc=i*4+1
        declare -i def=i*4+2
        declare -i type=i*4+3
        echo -e "| ${ARR[sw]} \t| ${ARR[desc]} \t| [${ARR[def]}] | ${ARR[type]}|"
    done
    echo "  "
    echo "  "
    echo  "**path1:**  https://sourceforge.net/projects/clonezilla/files/\
clonezilla_live_alternative/20200703-focal/\
clonezilla-live-20200703-focal-amd64.iso/download  "
    echo  "**path2:**  https://github.com/rstudio/rstudio/archive/v  "
    echo  "**path3:**  http://gentoo.mirrors.ovh.net/gentoo-distfiles/  "
    echo  "**count:** nproc --all / 3  "
}

## @fn help_()
## @brief Print usage to stdout
## @private
## @ingroup createInstaller

help_() {
    help_md | sed 's/[\*\|\>]//g' | grep -v -E "(Option *Desc.*|:--.*)"
}

# ---------------------------------------------------------------------------- #
# Option parsing
#

## @fn validate_option()
## @brief Check if argument is part of array #ARR as a legitimate commandline
##        option.
## @param option  String of option.
## @return true if legitimate option otherwise false.
## @ingroup createInstaller

validate_option() {

    for ((i=0; i<ARRAY_LENGTH; i++))
    do
        [ "$1" = "${ARR[i*4]}" ] && return 0
    done
    return 1
}

## @fn get_options()
## @brief Parse command line
## @ingroup createInstaller

get_options() {

    local LOGGING="true"
    local LOGGER0="$(which logger)"
    local ECHO="$(which echo)"
    [ -n "${LOGGER0}" ] && LOGGER_VERBOSE_OPTION="-s" || LOGGER0="${ECHO}"
    LOG=("${LOGGER0}" "${LOGGER_VERBOSE_OPTION}")
    export LOG

    if [ $# = 0 ]
    then
        ISO_OUTPUT="gentoo.iso"
        CREATE_ISO=true
        return 0
    fi

    while (( "$#" ))
    do
        if grep '=' <<< "$1" 2>/dev/null 1>/dev/null
        then
            left=$(sed -E 's/(.*)=(.*)/\1/'  <<< "$1")
            right=$(sed -E 's/(.*)=(.*)/\2/' <<< "$1")
            if validate_option "${left}"
            then
                declare -u VAR=${left}
                eval "${VAR}"=\"${right}\"
                if [ "${VERBOSE}" = "true" ]
                then
                    ${LOG[*]} "[CLI] Assign: ${VAR}=${!VAR}"
                fi
            fi
        else
            if  grep "\.iso"  <<< "$1" 2>/dev/null 1>/dev/null
            then
                ISO_OUTPUT="$1"
                CREATE_ISO=true
            else
                if validate_option "$1"
                then
                    declare -u VAR="$1"
                    eval "${VAR}"=true
                    [ "${VERBOSE}" = "true" ] \
                        && ${LOG[*]} "[CLI] Assign: ${VAR}=true"
                fi
            fi
        fi
        if [ "${LOGGING}" = "true" ]
        then
            LOGGER="${LOGGER0}"
        else
            LOGGER="${ECHO}"
            LOGGER_VERBOSE_OPTION=""
        fi

        # fallback

        [ -z "${LOGGER}" ] && LOGGER="${ECHO}"
        if [ "${QUIET_MODE}" = "true" ]
        then
            LOGGER_VERBOSE_OPTION=""
        fi

        LOG=("${LOGGER}" "${LOGGER_VERBOSE_OPTION}")
        shift
    done
}

## @fn test_cli_pre()
## @brief Check VirtualBox version and prepare commandline analysis
## @retval 0 otherwise exit 1 if VirtualBox is too old
## @ingroup createInstaller

test_cli_pre() {

    { [ "${VERBOSE}" = "true" ] || [ "${DEBUG_MODE}" = "true" ]; } \
        && [ "${QUIET_MODE}" = "true" ] \
        && { ${LOG[*]} "[ERR] You cannot have 'quiet' and verbose modes at \
the same time"
             exit 1; }

    # do not use ${}  as true/false in this function as vars. are not all set

    [ "$(whoami)" != "root" ] && { ${LOG[*]} "[ERR] must be root to continue"
                                   exit 1; }
    [ -d /home/partimage ] && rm -rf /home/partimag
    mkdir -p /home/partimag
    if_fails $? "[ERR] Could not create partimag directory under /home"

    # Configuration tests

    local do_exit=false
    [ -z "$(VBoxManage --version)" ] \
        && { ${LOG[*]} "[ERR] Did not find a proper VirtualBox install. \
Reinstall Virtualbox version >= 6.1"; do_exit=true; }
    [ -z "$(uuid)" ] \
        && { ${LOG[*]} "[ERR] Did not find uuid. Intall the uuid package"
             do_exit=true; }
    [ -z "$(mkisofs -version)" ] \
        && { ${LOG[*]} "[ERR] Did not find mkisofs. Install the cdrtools \
package (see Wiki)"; do_exit=true; }
    [ -z "$(mksquashfs -version)" ] \
        && { ${LOG[*]} "[ERR] Did not find squashfs. Install the squashfs \
package."; do_exit=true; }
    [ -z "$(xz --version)" ] \
        && { ${LOG[*]} "[ERR] Did not find xz. Install xz and its libraries"
             do_exit=true; }
    [ -z "$(curl --version)" ] \
        && { ${LOG[*]} "[ERR] Did not find curl. Please install it now."
             do_exit=true; }
    [ -z "$(md5sum --version)" ] \
        && { ${LOG[*]} "[ERR] Did not find md5sum. Install the coreutils \
package."; do_exit=true; }
    [ -z "$(tar --version)" ] \
        && { ${LOG[*]} "[ERR] Did not find tar."; do_exit=true; }
    { [ -z "$(mountpoint --version)" ] || [ -z "$(findmnt --version)" ]; } && {
        ${LOG[*]} "[ERR] Did not find mountpoint/findmnt. Install util-linux."
        do_exit=true; }
    [ -z "$(sed --version)" ] && { ${LOG[*]} "[ERR] Did not find sed."
                                   do_exit=true; }
    [ -z "$(which xorriso)" ] \
        && { ${LOG[*]} "[ERR] Did not find xorriso (libburnia project)"
             do_exit=true; }

    # Check VirtualBox version

    declare -r vbox_version=$(VBoxManage -v)
    declare -r version_major=$(sed -E 's/([0-9]+)\..*/\1/' <<< ${vbox_version})
    declare -r version_minor=$(sed -E 's/[0-9]+\.([0-9]+)\..*/\1/' \
                                   <<< ${vbox_version})
    declare -r version_index=$(sed -E 's/[0-9]+\.[0-9]+\.([0-9][0-9]).*/\1/' \
                                   <<< ${vbox_version})
    if [ ${version_major} -lt 6 ] || [ ${version_minor} -lt 1 ] \
           || [ ${version_index} -lt 10 ]
    then
        ${LOG[*]} "[ERR] VirtualBox must be at least version 6.1.10"
        ${LOG[*]} "[ERR] Please update and reinstall"
        do_exit=true
    fi

    #--- do_exit:

    [ "$do_exit" = "true" ] && exit 1

    #--- ISO output

    export CREATE_ISO

    if [ "${FROM_ISO}" = "true" ]
    then

        # effectively correcting first pass assignment.
        # This can be done only when cl is entirely parsed.

        CREATE_ISO="false"
    fi
    if [ -n "${ISO_OUTPUT}" ]
    then
        if [ "${VERBOSE}" = "true" ]
        then
            ${LOG[*]} "[MSG] Bootable ISO output is: ${ISO_OUTPUT}"
            if [ "${CREATE_ISO}"  = "true" ]
            then
                ${LOG[*]} "[MSG] Build Gentoo to bootable ISO"
            else
                ${LOG[*]} "[MSG] Using previously built ISO"
            fi
        fi
    fi

    [ -n "${VM}" ] && [ "${VM}" != "false" ] && [ ${FROM_VM} != "true" ] \
        && ${LOG[*]} "[MSG] A Virtual machine will be created with name ${VM}"

    return 0
}

## @fn test_cli()
## @brief Analyse commandline
## @param cli  Commandline
## @details @li Create globals of the form VAR=arg  when there is var=arg on
##              commandline
## @li Otherwise assign default values VAR=defaults (3rd argument in array #ARR)
## @li Also checks type of argument against types described for #ARR
## @ingroup createInstaller

test_cli() {

    declare -i i=$1
    local sw=${ARR[i*4]}
    local desc=${ARR[i*4+1]}
    local default0="${ARR[i*4+2]}"
    eval default=\""${default0}"\"
    local type=${ARR[i*4+3]}
    local cli_arg=false
    declare -u V=${sw}
    local y=$(sed 's/.*://' <<< "${type}")
    local cond0="${y^^}"
    local cond
    [ -n "${cond0}" ] && cond="${!cond0}"

    # Do not use ${} directly as true/false without [...] in
    # this function and the above.
    # as Boolean variables may not all be set yet.

    if [ -n "${!V}" ]
    then
        [ "${DEBUG_MODE}" = "true" ] \
            && ${LOG[*]} "[CLI] ${desc}=${!V}"

        # checking on types among values found on commandline

        case "${type}" in
            b)  if  [ "${!V}" != "true" ] && [ "${!V}" != "false" ]
                then
                    ${LOG[*]} "[ERR] ${sw} is Boolean: specify its value as \
either 'false' or 'true' on command line"
                    exit 1
                fi
                ;;
            d)  [ ! -d "${!V}" ] \
                    && { ${LOG[*]} "[ERR] ${sw}=... must be an existing \
directory."
                         exit 1; }
                ;;
            e)  if ! grep -E "[a-z]+@[a-z]+\.[a-z]+" <<< "${!V}"
                then
                    ${LOG[*]} "[ERR] ${sw}=... must be a valid email \
address"
                    exit 1
                fi
                ;;
            f)  [ ! -f "${!V}" ] \
                    && { ${LOG[*]} "[ERR] ${sw}=... must be an existing file."
                         exit 1;} ;;
            n)  [ test_numeric "${!V}" != 0 ] \
                    && { ${LOG[*]} "[ERR] ${sw}=... is not numeric."
                         exit 1; }
                ;;
            o)  [ "${!V}" != "on" ] && [ "${!V}" != "off" ] \
                    && { ${LOG[*]} "[ERR] ${sw}=on or ${sw}=off are the only \
 two possible values."
                         exit 1; }
                ;;
            u)  [ test_URL "${!V}" != 0 ] \
                    && { ${LOG[*]} "[ERR] ${sw}=... must be a valid URL"
                         exit 1; }
                ;;
            vm)  [ "${VM}" = "false" ] && VM=""
                 ;;

            # conditional types of the form e/f/s:...

            *:*)
                if [ "${cond}" != "true" ] && { [ "${cond}" = "false" ] \
                                                    || [ -z "${cond}" ]; }
                then
                    if [ -z "${cond}" ]
                    then
                        ${LOG[*]} "[ERR] Execution cannot proceed without \
specifying an explicit value for ${y}=..."
                    else
                        ${LOG[*]} "[ERR] Execution cannot proceed as option \
values for ${y}=false and ${sw}=${!V} are incompatible."
                    fi
                    ${LOG[*]} "[ERR] Fatal. Exiting..."
                    exit 1
                fi

                # [ -z "${!V}" ] <=> { [ "${cond}" = "false" ]
                # ||  [ -z "${cond}" ]; } && [ "${cond}" != "true" ]

        esac
    else
        if [ "${cond}" = "true" ] || { [ "${cond}" != "false" ] \
                                           &&  [ -n "${cond}" ]; }
        then
            local EXCEPT="FROM_${y^^}"
            if [ -z "${default}" ] && ! "${!EXCEPT}"
            then
                ${LOG[*]} "[ERR] Execution cannot proceed without an explicit \
 value for ${sw}=... as ${y}=${cond}"
                ${LOG[*]} "[ERR] Fatal. Exiting..."
                exit 1
            fi
        fi

        # not found on command line or erroneously empty
        # replacing by default in any case, except if type == "s"
        # and default empty. This is the case e.g. for passwds.

        if [ "${type}" = "s" ] && [ -z "${default}" ] && [ "${sw}" != "dep" ]
        then
            ${LOG[*]} "[ERR] Execution cannot proceed without explicit value \
for ${sw}"
            if "${INTERACTIVE}"
            then
                local reply=""
                while [ -z ${reply} ]
                do
                    ${LOG[*]} "[MSG] Please enter value: "
                    read reply
                    eval "${V}"=\"${reply}\"
                done
            else
                ${LOG[*]} "[ERR] Fatal. Exiting..."
                exit 1
            fi
        fi
        [ "${DEBUG_MODE}" = "true" ] \
            && ${LOG[*]} "[CLI] Desc/default: ${desc}=${default}"
        eval "${V}"=\""${default}"\"
    fi

    # exporting is made necessary by usage in companion scripts.

    [ "${DEBUG_MODE}" = "true" ] && ${LOG[*]} "[MSG] Export: ${V}=${!V}"
    export "${V}"
}

## @fn test_cli_post()
## @brief Check commanline coherence and incompatibilities
## @retval 0 or exit 1 on incompatibilities
## @ingroup createInstaller

test_cli_post() {

    # ruling out incompatible options

    # GUI and INTERACTIVE are linked options.
    # You should always reply to security requests unless you want the process
    # in the background

    if "${GUI}"
    then
        if ! "${INTERACTIVE}"
        then
            ${LOG[*]} "[WAR] Unless you want the process to run \
in the background, user interaction is allowed by default. \
Resetting *interactive* to *true*."
            INTERACTIVE=true
        fi
    else
        # forcing INTERACTIVE as false only for background jobs.

        case $(ps -o stat= -p $$) in
            *+*) echo "[MSG] Running in foreground with interactive=${INTERACTIVE}." ;;
            *) echo "[MSG] Running in background in non-interactive mode."
               INTERACTIVE=false
               ;;
        esac
    fi

    "${DOWNLOAD}" && ! "${CREATE_SQUASHFS}" \
        && { ${LOG[*]} "[ERR][CLI] You cannot set \
create_squashfs=false with download=true"
             exit 1; }

    if { "${FROM_ISO}" && "${FROM_DEVICE}"; } \
           || { "${FROM_VM}" && "${FROM_DEVICE}"; } \
           || { "${FROM_ISO}" && "${FROM_VM}"; }
    then
        ${LOG[*]} "[ERR] Only one of the three options from_iso, \
from_device or from_vm may be specified on commandline."
        exit 1
    fi

    # align debug_mode and verbose

    "${DEBUG_MODE}" && VERBOSE=true && CLEANUP=false

    # there are two modes of install: with CloneZilla live CD
    # (Ubuntu-based) or official Gentoo install

    "${CLONEZILLA_INSTALL}" && OSTYPE=Ubuntu_64 || OSTYPE=Gentoo_64

    # minimal CPU allocation

    [ "${NCPUS}" = "0" ] && NCPUS=1

    # VM name will be time-stamped to avoid registration issues,
    # unless 'force=true' is used on commandline

    ! "${FORCE}" && ! "${FROM_VM}" && VM="${VM}".$(date +%F-%H-%M-%S)

    "${CREATE_ISO}" && ISOVM="${VM}_ISO"

    "${FROM_VM}" && [ ! -f "${VM}.vdi" ] \
        && { ${LOG[*]} "[ERR] Virtual machine \
disk ${VMPATH}/${VM}.vdi was not found"
             exit 1; }

    # other accept_keywords can be manually added to file
    # ${ELIST}.accept_keywords defaulting to ebuilds.list.accept_keywords

    sed -i '/dev-lang\/R.*$/d'  "${ELIST}.accept_keywords"
    echo ">=dev-lang/R-${R_VERSION}  ~${PROCESSOR}" \
         >> "${ELIST}.accept_keywords"

    if [ -n "${EMAIL}" ] && [ -z "${EMAIL_PASSWD}" ]
    then
        "${INTERACTIVE}" && read -p "[MSG] Enter email password: " EMAIL_PASSWD
        [ -z "${EMAIL_PASSWD}" ] \
            && ${LOG[*]} "[WAR] No email password, aborting sendmail."
        ${LOG[*]} "[INF] Sending warning email to ${EMAIL}"
        ${LOG[*]} "[WAR] Gmail and other providers request user to activate \
third-party applications for this mail to be sent."
        ${LOG[*]} "[WAR] You will not receive any mail otherwise."
    fi

    "${GUI}" && VMTYPE="gui" || VMTYPE="headless"
    "${BIOS}" && FIRMWARE="bios" || FIRMWARE="efi"

    # note: vm=false is now vm empty

    if [ -z "${VM}" ] && ! "${BUILD_VIRTUALBOX}"
    then
        CLEANUP=false
        ${LOG[*]} "[MSG] Deactivated cleanup"
    fi

    if "${HOT_INSTALL}" && "${DEVICE_INSTALLER}"
    then
        ${LOG[*]} "[ERR] Either use hot_install or device_installer \
for a given ext_device"
        exit 1
    fi

    if  "${HOT_INSTALL}" || ([ -n "${EXT_DEVICE}" ] \
                             && [ "${EXT_DEVICE}" != "dep" ])\
                         ||  "${DEVICE_INSTALLER}"
    then
        if "${INTERACTIVE}"
        then
            echo "[WAR] All data will be wiped out on device(s): ${EXT_DEVICE}."
            read -p "Please confirm by entering uppercase Y: " rep
            [ "${rep}" != "Y" ] && exit 0
            echo "[WAR] Once again."
            echo "      All data will be wiped out on device(s): ${EXT_DEVICE}."
            read -p "      Please confirm by entering uppercase Y: " rep
            [ "${rep}" != "Y" ] && exit 0
        else
            echo "[WAR] CAUTION: non-interactive mode is on. Device ${EXT_DEVICE} \
will be erased and written to upon completion. \
You may want to abort this process just now (it should be time). \
Allowing a 10 second break for second thoughts."
            echo sleep 10
        fi
    fi
}

# ---------------------------------------------------------------------------- #
# SQUASHFS/UNSQUASHFS operations
#

## @fn mount_live_cd()
## @brief Mount Gentoo/Clonezilla live CD and unsquashfs the GNU/linux system.
## @note  live CD is mounted under $VMPATH/mnt and rsync'd to $VMPATH/mnt2
## @ingroup createInstaller

mount_live_cd() {

    check_file "${ISO}" "[ERR] No active ISO file in current directory!"
    if ! "${CREATE_SQUASHFS}"
    then
        ${LOG[*]} "[MSG] Reusing ${ISO} which was previously created... \
use this option with care if only you have run mkg before."
        ${LOG[*]} "[MSG] create_squashfs should be left at 'true' (default) \
if mkvm.sh or mkvm_chroot.sh have been altered"
        ${LOG[*]} "[MSG] or the kernel config file, the global variables, \
the boot config files, the stage3 archive or the ebuild list."
        ${LOG[*]} "[MSG] It can be set at 'false' if the install ISO file and \
stage3 archive are cached in the directory after prior downloads"
        ${LOG[*]} "[MSG] with no other changes in the above set of files."
        return 0
    fi

    # mount ISO install file

    local verb=""
    "${VERBOSE}" && verb="-v"
    mountpoint -q mnt && umount -l mnt
    [ -d mnt ] && rm -rf mnt
    mkdir mnt
    check_dir mnt
    mount -oloop "${ISO}" mnt/  2>/dev/null
    ! mountpoint -q mnt && ${LOG[*]} "[ERR] ISO not mounted!" && exit 1

    # get a copy with write access

    [ -d mnt2 ] && rm -rf mnt2/
    mkdir mnt2/
    check_dir mnt2
    "${VERBOSE}" && ${LOG[*]} "[INF] Syncing mnt2 with ISO mountpoint..."
    rsync -a mnt/ mnt2

    # parameter adjustment to account for Gentoo/CloneZilla differences

    ROOT_LIVE="${VMPATH}/mnt2"
    SQUASHFS_FILESYSTEM=image.squashfs
    export ISOLINUX_DIR=isolinux
    if "${CLONEZILLA_INSTALL}"
    then
        ISOLINUX_DIR=syslinux
        ROOT_LIVE="${VMPATH}/mnt2/live"
        SQUASHFS_FILESYSTEM=filesystem.squashfs
    fi

    # ISOLINUX config adjustments to automate the boot and reduce user input

    check_dir "mnt2/${ISOLINUX_DIR}"
    cd "mnt2/${ISOLINUX_DIR}"
    if "${CLONEZILLA_INSTALL}"
    then
        cp ${verb} -f "${VMPATH}/clonezilla/syslinux/isolinux.cfg" .
    else
        check_files isolinux.cfg
        sed -i 's/timeout.*/timeout 1/' isolinux.cfg
        sed -i 's/ontimeout.*/ontimeout gentoo/' isolinux.cfg
    fi

    # now unsquashfs the liveCD filesystem

    cd "${ROOT_LIVE}"

    "${VERBOSE}" && ${LOG[*]} "[INF] Unsquashing filesystem..." \
        && unsquashfs "${SQUASHFS_FILESYSTEM}"  \
            ||  unsquashfs -q  "${SQUASHFS_FILESYSTEM}" 2>&1 >/dev/null

    if_fails $? "[ERR] unsquashfs failed !"
}

## @fn make_boot_from_livecd()
## @brief Tweak the Gentoo minimal install CD so that the custom-
## made shell scripts and stage3 archive  are included into the squashfs
## filesystem.
## @details This function is returned from early if @code create_squashfs=false
## @endcode is given on commandline.
## @note Will be run in the ${VM} virtual machine
## @retval Returns 0 on success or -1 on failure.
## @ingroup createInstaller

make_boot_from_livecd() {

    # ------------------------------------- #
    # Monting live CD and requirement checks
    #

    mount_live_cd

    # we stick to the official mount point /mnt/gentoo

    if "${CLONEZILLA_INSTALL}"
    then
        mkdir -p ../mnt/gentoo
        check_dir  ../mnt/gentoo
    fi

    # copy the scripts, kernel config, ebuild list and stage3 archive to the
    # /root directory of the unsquashed filesystem
    # note: environment variables are passed along using a "physical" copy to
    # /root/.bashrc

    check_dir "${VMPATH}"
    cd "${VMPATH}"

    "${MINIMAL}" && cp ${verb} -f "${ELIST}.minimal" "${ELIST}"  \
            || cp ${verb} -f "${ELIST}.complete" "${ELIST}"

    check_file scripts/mkvm.sh  "[ERR] No mkvm.sh script!"
    check_file scripts/mkvm_chroot.sh "[ERR] No mkvm_chroot.sh script!"
    check_file "${ELIST}"     "[ERR] No ebuild list!"
    check_file "${ELIST}.use" "[ERR] No ebuild list!"
    check_file "${ELIST}.accept_keywords" "[ERR] No ebuild list!"
    check_file "${STAGE3}"  "[ERR] No stage3 archive!"
    check_file "${KERNEL_CONFIG}" "[ERR] No kernel configuration file!"

    # ------------------------------------------------------ #
    # Moving platform building scripts to unsquashed live CD
    #

    local sqrt="${ROOT_LIVE}/squashfs-root/root/"
    local verb
    "${VERBOSE}" && verb="-v"
    check_dir  "${sqrt}"

    ${LOG[*]} <<< $(mv ${verb} -f "${STAGE3}" ${sqrt} 2>&1 \
                        | xargs echo "[INF] Moving stage3")

    ${LOG[*]} <<< $(cp ${verb} -f scripts/mkvm.sh ${sqrt}  2>&1 \
                        | xargs echo "[INF] Moving mkvm.sh")
    ${LOG[*]} <<< $(chmod +x ${sqrt}mkvm.sh 2>&1 \
                        | xargs echo "[INF] Changing permissions")

    ${LOG[*]} <<< $(cp ${verb} -f scripts/mkvm_chroot.sh ${sqrt} 2>&1 \
                        | xargs echo "[INF] Moving mkvm_chroot.sh")

    ${LOG[*]} <<< $(chmod +x ${sqrt}mkvm_chroot.sh \
                        | xargs echo "[INF] changing permissions")

    ${LOG[*]} <<< $(cp ${verb} -f "${ELIST}" "${ELIST}.use" \
                       "${ELIST}.accept_keywords" ${sqrt} 2>&1 \
                        | xargs echo "[INF] Moving ebuild lists")

    ${LOG[*]} <<< $(cp ${verb} -f "${KERNEL_CONFIG}" ${sqrt} 2>&1 \
                        | xargs echo "[INF] Moving kernel config")
    cd ${sqrt} || exit 2

    # now prepare the .bashrc file by exporting the environment
    # this will be placed under /root in the VM

    rc=".bashrc"
    ${LOG[*]} <<< $(cp ${verb} -f /etc/bash.bashrc ${rc})
    declare -i i
    for ((i=0; i<ARRAY_LENGTH; i++))
    do
        local  capname=${ARR[i*4]^^}
        local  expstring="export ${capname}=\"${!capname}\""
        "${VERBOSE}" && ${LOG[*]} "${expstring}"
        echo "${expstring}" >> ${rc}
    done

    # the whole platform-making process will be launched by mkvm.sh under /root/
    # and fired on by .bashrc sourcing once the liveCD exits the boot process
    # into root shell

    echo  "/bin/bash mkvm.sh"  >> ${rc}

    # -------------------------------------------------------------- #
    #  Now restore the squashfs filesystem to recreate a new live CD
    #

    cd ../.. || exit 2
    ${LOG[*]} <<< $(rm ${verb} -f "${SQUASHFS_FILESYSTEM}" 2>&1 \
                        | xargs echo "[INF] Removing ${SQUASHFS_FILESYSTEM}")
    local verb2="-quiet"
    ${LOG[*]} <<< $(mksquashfs squashfs-root/ ${SQUASHFS_FILESYSTEM} \
                     ${verb2} 2>&1 | \
                        xargs echo "[INF] Created ${SQUASHFS_FILESYSTEM}")
    ${LOG[*]} <<< $(rm -rf squashfs-root/ 2>&1 \
                        | xargs echo "[INF] Removing squashfs-root")

    # restore the ISO in bootable format

    cd "${VMPATH}" || exit 2

    ${LOG[*]} <<< $(recreate_liveCD_ISO "${VMPATH}/mnt2/" | \
                        xargs echo "[INF] Recreating ISO")

    # cleanup by default

    umount -l mnt
    if "${CLEANUP}"
    then
        ${LOG[*]} <<< $(rm -rf mnt && rm -rf mnt2 2>&1 \
                            | xargs echo "[INF] Removing mount directories")
    fi
    return 0
}

# ---------------------------------------------------------------------------- #
# Virtual machine processing
#

## @fn test_vm_running()
## @brief Check if VM as first named argument exists and is running
## @param vm VM name or UUID
## @retval  Returns 0 on success and 1 is VM is not listed or not running
## @ingroup createInstaller

test_vm_running() {
    [ -n "$(VBoxManage list vms | grep \"$1\")" ] \
        && [ -n "$(VBoxManage list runningvms | grep \"$1\")" ]
}

## @fn deep_clean()
## @private
## @brief Force-clean root VirtualBox registry
## @ingroup createInstaller

deep_clean() {

    # no deep clean with 'force=false'

    ! "${FORCE}" && return 0

    ${LOG[*]} "[INF] Cleaning up hard disks in config file because of \
inconsistencies in VM settings"
    local registry="/root/.config/VirtualBox/VirtualBox.xml"
    if grep -q "${VM}.vdi" ${registry}
    then
        ${LOG[*]} "[MSG] Disk \"${VM}.vdi\" is already registered and needs \
 to be wiped out of the registry"
        ${LOG[*]} "[MSG] Otherwise issues may arise with UUIDS and data \
integrity"
        ${LOG[*]} "[WAR] Stopping VirtualBox server. You need to stop/snapshot \
your running VMs."
        ${LOG[*]} "[WAR] Enter Y when this is done or another key to exit."
        ${LOG[*]} "[WAR] In which case \"${VM}.vdi\" might not be properly \
attached to virtual machine ${VM}"
        if "${INTERACTIVE}"
        then
            [ "$1" != "ISO_STAGE" ] \
                &&   read -p "Enter Y to continue or another key to skip deep \
clean: " reply || reply="Y"
            [ "${reply}" != "Y" ] && [ "${reply}" != "y" ] && return 0
        fi
    fi
    /etc/init.d/virtualbox stop
    sleep 5
    sed -i  '/^.*HardDisk.*$/d' ${registry}
    sed -i -E  's/^(.*)<MediaRegistry>.*$/\1<MediaRegisty\/>/g' ${registry}
    sed -i '/^.*<\/MediaRegistry>.*$/d' ${registry}
    sed -i  '/^[[:space:]]*$/d' ${registry}
    "${DEBUG_MODE}" && cat  ${registry}

    # it is necessary to sleep a bit otherwise doaemons will wake up
    # with inconstitencies

    sleep 5
    /etc/init.d/virtualbox start
}

## @fn delete_vm()
## @param vm VM name
## @param ext virtual disk extension, without dot (defaults to "vdi").
## @brief Powers off, possibly with emergency stop,
##        the VM names as first argument.
## @details @li Unregisters it
## @li Deletes its folder structure and hard drive
##     (default is "vdi" as a second argument)
## @retval Returns 0 if Directory and hard drive could be erased,
##         otherwise the OR value of both
## erasing commands
## @ingroup createInstaller

delete_vm() {

    if test_vm_running "$1"
    then
        ${LOG[*]} "[INF] Powering off $1"
        ${LOG[*]} <<< $(VBoxManage controlvm "$1" poweroff 2>&1 \
                            | xargs echo "[INF]")
    fi
    if test_vm_running "$1"
    then
        ${LOG[*]} "[INF] Emergency stop for $1"
        ${LOG[*]} <<< $(VBoxManage startvm $1 --type emergencystop 2>&1 \
                            | xargs echo "[INF]")
    fi

    if [ -f "${VMPATH}/$1.$2" ]
    then
        ${LOG[*]} "[INF] Closing medium $1.$2"
        if VBoxManage showmediuminfo "${VMPATH}/$1.$2" 2>/dev/null 1>/dev/null
        then
            ${LOG[*]} <<< $(VBoxManage storageattach "$1" \
                                       --storagectl "SATA Controller" \
                                       --port 0 \
                                       --medium none 2>&1 \
                                | xargs echo "[INF]")
            ${LOG[*]} <<< $(VBoxManage closemedium  disk "${VMPATH}/$1.$2" \
                                       --delete 2>&1 \
                                | xargs echo "[INF]")
        fi
    fi

    local res=$?

    if [ ${res} != 0 ] || "${FORCE}"
    then

        # last resort.
        # Happens when debugging with successive VMS with
        # same names or disk names and not enough wait time for
        # daemons to clean up the mess one needs to deep-clean
        # twice.
        # deep_clean will peek and clean the registry altering
        # it only if requested for security. This may cause other VMs
        # to crash.

        deep_clean "$3"
    fi
    if [ -n "$(VBoxManage list vms | grep \"$1\")" ]
    then
        ${LOG[*]} "[MSF] Current virtual machine: $(VBoxManage list vms \
| grep \"$1\"))"
        ${LOG[*]} "[INF] Removing SATA controller"
        VBoxManage storagectl "$1" \
                   --name "SATA Controller" \
                   --remove 2>&1 | ${LOG[*]}
        ${LOG[*]} "[INF] Removing IDE controller"
        VBoxManage storagectl "$1" \
                   --name "IDE Controller" \
                   --remove  2>&1 | ${LOG[*]}
        ${LOG[*]} "[INF] Unregistering $1"
        VBoxManage unregistervm "$1" \
                   --delete 2>&1 | ${LOG[*]}
    fi

    # the following is overall unnecessary except for issues with
    # VBoxManage unregistervm

    if [ "$3" != "ISO_STAGE" ]
    then
        [ -d "${VMPATH}/$1" ] \
            && ${LOG[*]} "Force removing $1" \
            && rm -rf  "${VMPATH}/$1"

        # same for disk registration

        [ -n "$2" ] && [ -f "${VMPATH}/$1.$2" ] \
            && ${LOG[*]} "Force removing $1.$2" \
            && rm -f   "${VMPATH}/$1.$2"
    fi

    # deep clean again!

    { [ ${res} != 0 ] || "${FORCE}"; } && deep_clean "$3"
    return ${res}
}

## @fn create_vm()
## @brief Create main VirtualBox machine using VBoxManage commandline
## @details @li Register machine, create VDI drive, create IDE
##              drive attach disks
##          to controlers
## @li Attach augmented clonezilla LiveCD to IDE controller.
## @li Wait for the VM to complete its task. Check that it is still running
## every minute.
## @li Finally compact it.
## @note VM may be visible (vm type=gui) or without GUI (vm type=headless,
## currently to be fixed)
## @todo Find a way to only compact on success and never on failure of VM.
## @ingroup createInstaller

create_vm() {

    export PATH="${PATH}":"${VBPATH}"
    check_dir "${VMPATH}"
    cd "${VMPATH}"
    delete_vm "${VM}" "vdi"

    # create and register VM

    ${LOG[*]} <<< $(VBoxManage createvm --name "${VM}" \
                               --ostype ${OSTYPE}  \
                               --register \
                               --basefolder "${VMPATH}"  2>&1 \
                        | xargs echo "[INF]")

    # add reasonably optimal options. Note: without --cpu-profile host,
    # building issues have arisen for qtsensors
    # owing to the need of haswell+ processors to build it.
    # By default the VB processor configuration is lower-grade
    # all other parameters are listed on commandline options with default values

    ${LOG[*]} <<< $(VBoxManage modifyvm "${VM}" \
                               --cpus ${NCPUS} \
                               --cpu-profile host \
                               --memory ${MEM} \
                               --vram 128 \
                               --ioapic ${IOAPIC} \
                               --usbxhci ${USBXHCI} \
                               --usbehci ${USBEHCI} \
                               --hwvirtex ${HWVIRTEX} \
                               --pae ${PAE} \
                               --cpuexecutioncap ${CPUEXECUTIONCAP} \
                               --ostype ${OSTYPE} \
                               --vtxvpid ${VTXVPID} \
                               --paravirtprovider ${PARAVIRTPROVIDER} \
                               --rtcuseutc ${RTCUSEUTC} \
                               --firmware ${FIRMWARE} 2>&1 \
                        | xargs echo "[MSG]")

    # create virtual VDI disk, if it does not exist

    if [ ! -f  "${VM}.vdi" ] || "${FORCE}"
    then
        [ -f "${VM}.vdi" ] && rm -f "${VM}.vdi"
        ${LOG[*]} <<< $(VBoxManage createmedium --filename "${VM}.vdi" \
                                   --size ${SIZE} \
                                   --variant Standard 2>&1 | xargs echo '[MSG]')
    else
        ${LOG[*]} "[MSG] Using again old VDI disk: ${VM}.vdi, \
UUID: ${MEDIUM_UUID}"
        ${LOG[*]} "[WAR] Hopefully size and caracteristics are correct."
    fi

    MEDIUM_UUID=$(VBoxManage showmediuminfo "${VM}.vdi"  | head -n1 \
                      | sed -E 's/UUID: *([0-9a-z\-]+)$/\1/')

    [ -z "${MEDIUM_UUID}" ] && MEDIUM_UUID=`uuid`

    # set disk UUID once and for all to avoid serious debugging issues
    # whilst several VMS are around, some in zombie state, with
    # same-name disks floating around with different UUIDs and
    # registration issues

    ${LOG[*]} <<< $(VBoxManage internalcommands sethduuid "${VM}.vdi" \
                               ${MEDIUM_UUID} 2>&1 | xargs echo '[MSG]')

    # add storage controllers

    ${LOG[*]} <<< $(VBoxManage storagectl "${VM}" \
                               --name 'IDE Controller'  \
                               --add ide 2>&1 \
                        | xargs echo [MSG])
    ${LOG[*]} <<< $(VBoxManage storagectl "${VM}" \
                               --name 'SATA Controller' \
                               --add sata \
                               --bootable on 2>&1 \
                        | xargs echo [MSG])

    # attach media to controllers and double check that the attached
    # UUID is the right one as there have been occasional issues of
    # UUID switching on attachment.
    # Only one port/device is necessary
    # use --tempeject on for live CD

    ${LOG[*]} <<< $(VBoxManage storageattach "${VM}" \
                               --storagectl 'IDE Controller'  \
                               --port 0 \
                               --device 0  \
                               --type dvddrive \
                               --medium ${LIVECD} \
                               --tempeject on  2>&1 | xargs echo [MSG])

    ${LOG[*]} <<< $(VBoxManage storageattach "${VM}" \
                               --storagectl 'SATA Controller' \
                               --medium "${VM}.vdi" \
                               --port 0 \
                               --device 0 \
                               --type hdd \
                               --setuuid ${MEDIUM_UUID} 2>&1| xargs echo [MSG])

    # note: forcing UUID will potentially cause issues with
    # registration if a prior run with the same disk has set a prior
    # UUID in the register
    # (/root/.config/VirtualBox/VirtualBox.xml). So in the case a deep
    # clean is in order (see below).  Attaching empty drives may
    # potentially be useful (e.g. when installing guest additions)

    ${LOG[*]} <<< $(VBoxManage storageattach "${VM}" \
                               --storagectl 'IDE Controller' \
                               --port 0 \
                               --device 1 \
                               --type dvddrive \
                               --medium emptydrive  2>&1 \
                        | xargs echo [MSG])

    # Starting VM

    ${LOG[*]} <<< $(VBoxManage startvm "${VM}" \
                               --type ${VMTYPE} 2>&1 \
                        | xargs echo [MSG])

    # Sync with VM: this is a VBox bug workaround

    "${CLONEZILLA_INSTALL}" || ! "${GUI}" && sleep 90 \
            && ${LOG[*]} <<< $(VBoxManage controlvm "${VM}" \
                                   keyboardputscancode 1c 2>&1 \
                                   | xargs echo [MSG])

    # VM is created in a separate process
    # Wait for it to come to end
    # Test if still running every minute

    while test_vm_running ${VM}
    do
        ${LOG[*]} "[MSG] ${VM} running. Disk size: " \
                  $(du -hal "${VM}.vdi")
        sleep 60
    done
    ${LOG[*]} "[MSG] ${VM} has stopped"
    if "${COMPACT}"
    then
        ${LOG[*]} "[INF] Compacting VM..."
        ${LOG[*]} <<< $(VBoxManage modifymedium "${VM}.vdi" --compact 2>&1 \
                            | xargs echo [MSG])
    fi
}

## @fn create_iso_vm()
## @brief Create the new VirtualBox machine aimed at converting the VDI
## virtualdisk containing the Gentoo Linux distribution into an XZ-compressed
## clonezilla image uneder \b ISOFILES/home/partimag/image
## @details
## @details Register machine, create VDI drive, create IDE drive attach disks
## to controlers @n
## Attach newly augmented clonezilla LiveCD to IDE controller. @n
## Wait for the VM to complete its task. Check that it is still running every
## minute. @n
## @note VM may be visible (vm type=gui) or silent (vm type=headless,
## currently to be fixed).
## Wait for the VM to complete task. @n
## A new VM is necessary as the first VM used to build the Gentoo filesystem
## does not contain clonezilla or the VirtualBox guest additions (requested for
## sharing folders with host).
## Calls #add_guest_additions_to_clonezilla_iso to satisfy these requirements.
## @warning the \b sharedfolder command may fail vith older version of
## VirtualBox or not be implemented. It is transient, so it disappears on
## shutdown and requests prior startup of VM to be activated.
## @ingroup createInstaller

create_iso_vm() {

    cd "${VMPATH}"
    if_fails $? "[ERR] Could not cd to ${VMPATH}"

    check_file "${VM}.vdi" \
               "[ERR] A VDI disk with a Gentoo system was not found."

    # adding user to group vboxusers is recommended although not strictly
    # necessary here

    gpasswd -a "${USER}" -g vboxusers
    chgrp vboxusers "ISOFILES/home/partimag"

    # cleaning up

    delete_vm "${ISOVM}" "vdi" "ISO_STAGE"

    # creating ISO VM

    ${LOG[*]} <<< $(VBoxManage createvm \
                               --name "${ISOVM}" \
                               --ostype Ubuntu_64 \
                               --register \
                               --basefolder "${VMPATH}"  2>&1 \
                        | xargs echo [MSG])

    if_fails $? "[ERR] Failed to create VM *${ISOVM}*"

    ${LOG[*]} <<< $(VBoxManage modifyvm "${ISOVM}" \
                               --cpus ${NCPUS} \
                               --cpu-profile host \
                               --memory ${MEM} \
                               --vram 128 \
                               --ioapic ${IOAPIC} \
                               --usbxhci ${USBXHCI} \
                               --usbehci ${USBEHCI} \
                               --hwvirtex ${HWVIRTEX} \
                               --pae ${PAE} \
                               --cpuexecutioncap ${CPUEXECUTIONCAP} \
                               --vtxvpid ${VTXVPID} \
                               --paravirtprovider ${PARAVIRTPROVIDER} \
                               --rtcuseutc ${RTCUSEUTC} \
                               --firmware "bios" 2>&1 \
                        | xargs echo [MSG])

    if_fails $? "[ERR] Failed to set parameters of VM *${ISOVM}*"

    ${LOG[*]} <<< $(VBoxManage storagectl "${ISOVM}" \
                               --name 'SATA Controller' \
                               --add sata \
                               --bootable on 2>&1 \
                        | xargs echo [MSG])

    if_fails $? \
             "[ERR] Failed to attach storage SATA controller to VM *${ISOVM}*"

    # set disk UUID once and for all to avoid serious debugging issues
    # whilst several VMS are around, some in zombie state, with
    # same-name disks floating around with different UUIDs and
    # registration issues

    if [ -z ${MEDIUM_UUID} ]
    then
        "${FROM_VM}" && ${LOG[*]} "[MSG] Setting new UUID for VDI disk." \
          || ${LOG[*]} "[WAR] Could not use again VDI uuid. Setting a new one."

        local MEDIUM_UUID=$(VBoxManage showmediuminfo "${VM}.vdi"  \
                                | head -n1 \
                                | sed -E 's/UUID: *([0-9a-z\-]+)$/\1/')
    else
        ${LOG[*]} "[MSG] UUID of ${VM}.vdi will be used again: ${MEDIUM_UUID}"
    fi

    ${LOG[*]} <<< $(VBoxManage storageattach "${ISOVM}" \
                               --storagectl 'SATA Controller' \
                               --medium "${VM}.vdi" \
                               --port 0 \
                               --device 0 \
                               --type hdd 2>&1 \
                        | xargs echo [MSG])

    if_fails $? "[ERR] Failed to attach storage ${VM}.vdi to VM *${ISOVM}*"

    ${LOG[*]} <<< $(VBoxManage storagectl "${ISOVM}" \
                               --name "IDE Controller" \
                               --add ide 2>&1 \
                        | xargs echo [MSG])

    if_fails $? "[ERR] Failed to attach IDE storage controller to VM *${ISOVM}*"

    ${LOG[*]} <<< $(VBoxManage storageattach "${ISOVM}" \
                               --storagectl 'IDE Controller' \
                               --port 0 \
                               --device 0 \
                               --type dvddrive \
                               --medium "${CLONEZILLACD}" \
                               --tempeject on 2>&1 \
                        | xargs echo [MSG])

    if_fails $? "[ERR] Failed to attach clonezilla live CD to VM *${ISOVM}*"

    ${LOG[*]} <<< $(VBoxManage storageattach "${ISOVM}" \
                               --storagectl 'IDE Controller' \
                               --port 0 \
                               --device 1 \
                               --type dvddrive \
                               --medium emptydrive 2>&1 \
                        | xargs echo [MSG])

    if_fails $? "[ERR] Failed to attach IDE storage controller to VM *${ISOVM}*"

    ${LOG[*]} <<< $(VBoxManage sharedfolder add "${ISOVM}" \
                               --name shared \
                               --hostpath "${VMPATH}/ISOFILES/home/partimag" \
                               --automount \
                               --auto-mount-point '/home/partimag'  2>&1 \
                        | xargs echo [MSG])

    if_fails $? "[ERR] Failed to attach shared folder \
${VMPATH}/ISOFILES/home/partimag"

    ${LOG[*]} <<< $(VBoxManage startvm "${ISOVM}" \
                               --type ${VMTYPE} 2>&1 | xargs echo [MSG])

    while test_vm_running "${ISOVM}"
    do
        ${LOG[*]} "[MSG] ${ISOVM} running..."
        sleep 60
    done
}

## @fn clone_vm_to_device()
## @brief Directly clone Gentoo VM to USB stick (or any using block device)
## @param mode Either "vbox-img" or "guestfish"
## @warning Requests the \e patched version of \b vbox-img on account of
## Oracle source code bug (ticket #19901) or \b  guestfish
## @note build vbox-img beforehand.
## @ingroup createInstaller

clone_vm_to_device() {

    cd "${VMPATH}"

    # Test whether EXT_DEVICE is a mountpoint or a block device label

    EXT_DEVICE=$(get_device ${EXT_DEVICE})

    # Should not occur, only for paranoia

    [ -z "${EXT_DEVICE}" ] \
        && { ${LOG[*]} "[ERR] Could not find external device ${EXT_DEVICE}"
             exit 1; }

    if [ "$1" = "vbox-img" ]
    then
        VBOX_IMG_PREFIX="bin"
        echo "Using ${VBOX_IMG_PREFIX}/vbox-img convert"
        ${VBOX_IMG_PREFIX}/vbox-img convert --srcfilename "${VM}.vdi" \
                          --stdout \
                          --dstformat RAW | \
            dd of=/dev/${EXT_DEVICE} bs=4M status=progress
    else
        if [ "$1" = "guestfish" ]
        then
            echo "Using guestfish"
            check_tool guestfish

            guestfish --progress-bars  --ro -a  "${VM}.vdi" run : \
                      download /dev/sda /dev/${EXT_DEVICE}
	        sync
        else
            echo "[ERR] Mode is either vbox-img or guestfish."
            exit 1
        fi
    fi

    sync
    if_fails $? "[ERR] Could not convert dynamic virtual disk to raw USB device!"
    return 0
}

## @fn clone_vm_to_raw()
## @brief Use @code VBoxManage clonemedium @endcode
## to clone VDI to RAW file before bare-metal copy to device.
## @ingroup createInstaller

clone_vm_to_raw() {
    VBoxManage clonemedium "${VMPATH}/${VM}.vdi" "${VMPATH}/tmpdisk.raw" \
               --format RAW
}

## @fn dd_to_usb()
## @brief Bare-metal copy of temporary RAW disk to external device
## @note Used only if vbox-img (patched version) has not been built.
## @ingroup createInstaller

dd_to_usb() {
    "[INF] Bare metal copy of RAW disk to USB device..."

    # Test whether EXT_DEVICE is a mountpoint or a block device label

    EXT_DEVICE=$(get_device ${EXT_DEVICE})

    # Should not occur, only for paranoia

    [ -z "${EXT_DEVICE}" ] \
        && { ${LOG[*]} "[ERR] Could not set USB device ${EXT_DEVICE}"
             exit 1; }
    if dd if="${VMPATH}/tmpdisk.raw" \
          of=/dev/${EXT_DEVICE} bs=4M status=progress
    then
        ${LOG[*]} "[INF] Removing temporary RAW disk..."
        rm -f ${VMPATH}/tmpdisk.raw
    fi
}

## @fn vbox_img_works()
## @brief Test if \b vbox-img is functional
## @details \b vbox-img is a script; it refers to \b vbox-img.bin,
##           which is a soft link to the VirtuaBox patched build.
## @retval 0 if vbox-img --version is non-empty
## @retval 1 otherwise
## @note Currently vbox-img is broken for --stdout.
##       Using guestfish as an alternative.
##       This test is there for when vbox-img is fixed.
## @ingroup createInstaller

vbox_img_works() {
    cd "${VMPATH}" || exit 2

    # Using the custom-patched version of the vbox-img utility:

    if "${VBOX_IMG_PREFIX}/vbox-img" --version >/dev/null 2>&1
    then
        ${LOG[*]} "[MSG] bin/vbox-img works for this platform."
        return 0
    fi
}

## @fn create_device_system()
## @brief Clone VDI virtual disk to external device (USB device or hard drive)
## @details Two options are available. If vbox-img (patched) is functional
## after building VirtualBox from source, then use it and clone VDI directly
## to external device. Otherwise create a temporary RAW file and bare-metal copy
## this file to external device.
## @param Mode Mode must be vbox-img, guestfish or with-raw-buffer
## @retval In the first two cases, the exit code of #clone_vm_to_device
## @retval In the last case, the exit code of #dd_to_usb following
##         #clone_vm_to_raw
## @note Requires @b hot_install on command line to be activated as a security
##       confirmation.
##       This function performs what a live CD does to a target disk, yet using
##       the currently running operating system.
## @ingroup createInstaller

create_device_system() {

    if  [ "$1" = "guestfish" ] || [ "$1" = "vbox-img" ]
    then
        ${LOG[*]} "[INF] Cloning virtual disk to ${EXT_DEVICE} ..."
        if ! clone_vm_to_device "$1"
        then
            ${LOG[*]} "[ERR] Cloning VDI disk to external device failed !"
            return 1
        fi
    else
        if [ "$1" = "with-raw-buffer" ]
        then
            ${LOG[*]} "[INF] Cloning virtual disk to raw..."
            if ! clone_vm_to_raw
            then
                ${LOG[*]} "[ERR] Cloning VDI disk to RAW failed !"
                return 1
            fi
            ${LOG[*]} "[INF] Copying to external device..."
            if ! dd_to_usb
            then
                ${LOG[*]} "[INF] Copying raw file to external device failed!"
                ${LOG[*]} "[WAR] Check that your external device has \
at least 50 GiB of reachable space"
                exit 1
            fi
        else
            echo "[ERR] Mode must be vbox-img, guestfish or with-raw-buffer"
            exit 1
        fi
    fi
}

## @fn generate_Gentoo()
## @brief Launch routines: fetch install IO, starge3 archive, create VM
## @ingroup createInstaller

generate_Gentoo() {
    ${LOG[*]} "[INF] Fetching live CD..."
    fetch_livecd
    ${LOG[*]} "[INF] Fetching stage3 tarball..."
    fetch_stage3
    ${LOG[*]} "[INF] Tweaking live CD..."
    make_boot_from_livecd
    ${LOG[*]} "[INF] Creating VM"
    if ! create_vm; then
        ${LOG[*]} "[ERR] VM failed to be created!"
        exit 1
    fi
}

# ---------------------------------------------------------------------------- #
# CloneZilla processing
#

## @fn clonezilla_to_iso()
## @brief Create Gentoo linux clonezilla ISO installer out of a clonezilla
## directory structure and an clonezilla image.
## @param iso ISO output
## @param dir Directory to be transformed into ISO output
## @note ISO can be burned to DVD or used to create a bootable USB stick
## using dd on *nix platforms or Rufus (on Windows).
## @ingroup createInstaller

clonezilla_to_iso() {

    check_dir "${VMPATH}"
    check_dir "$2"

    cd "${VMPATH}"

    local verb=""

    "${VERBOSE}" && ${LOG[*]} "[INF] Removing $2/live/squashfs-root ..."

    rm  -rf "$2/live/squashfs-root/"

    [ ! -f "$2/syslinux/isohdpfx.bin" ] \
        && cp ${verb} -f "clonezilla/syslinux/isohdpfx.bin" "$2/syslinux"

    xorriso -as mkisofs   -isohybrid-mbr "$2/syslinux/isohdpfx.bin"  \
            -c syslinux/boot.cat   -b syslinux/isolinux.bin   -no-emul-boot \
            -boot-load-size 4   -boot-info-table   -eltorito-alt-boot  \
            -e boot/grub/efi.img \
            -no-emul-boot   -isohybrid-gpt-basdat   -o "$1"  "$2"

    if_fails $? "[ERR] Could not create ISO image from ISO package \
creation directory"
    return 0
}

## @fn add_guest_additions_to_clonezilla_iso()
## @brief Download clonezilla ISO or recover it from cache calling
## #fetch_process_clonezilla_iso. @n
## Upgrade it with virtualbox guest additions.
## @details Chroot into the clonezilla Ubuntu GNU/Linux distribution and runs
## apt to build
## kernel modules
## and install the VirtualBox guest additions ISO image. @n
## Upgrade clonezilla kernel consequently
## Recreates the quashfs system after exiting chroot.
## Copy the new \b isolinux.cfg parameter file: automates and silences
## clonezilla behaviour
## on disk recovery.
## Calls #clonezilla_to_iso
## @note Installing the guest additions is a prerequisite to folder sharing
## between the ISO VM
## and the host.
## Folder sharing is necessary to recover a compressed clonezilla image of
## the VDI virtual disk
## into the directory ISOFILES/home/partimag/image
## @ingroup createInstaller

add_guest_additions_to_clonezilla_iso() {

    bind_mount_clonezilla_iso

    cat > squashfs-root/update_clonezilla.sh << EOF
#!/bin/bash
mkdir -p  /boot
apt update -yq
apt upgrade -yq <<< 'N'

# We take the oldest supported 5.x linux headers, modules and images
# Sometimes the most recent ones are not aligned with VB wrt. building.
# Sometimes current CloneZilla kernel has no corresponding apt headers
# So replacing with common base for which headers are available and
# compilation issues probably lesser

headers="\$(apt-cache search ^linux-headers-[5-9]\.[0-9]+.*generic \
| head -n1 | grep -v unsigned |  cut -f 1 -d' ')"
kernel="\$(apt-cache  search ^linux-image-[5-9]\.[0-9]+.*generic   \
| head -n1 | grep -v unsigned |  cut -f 1 -d' ')"
modules="\$(apt-cache search ^linux-modules-[5-9]\.[0-9]+.*generic \
| head -n1 | grep -v unsigned |  cut -f 1 -d' ')"
apt install -qy "\${headers}"
apt install -qy "\${kernel}"
apt install -qy "\${modules}"
apt install -qy build-essential gcc <<< "N"
apt install -qy virtualbox virtualbox-modules virtualbox-dkms
apt install -qy virtualbox-guest-additions-iso
mount -oloop /usr/share/virtualbox/VBoxGuestAdditions.iso /mnt
cd /mnt || exit 2
/bin/bash VBoxLinuxAdditions.run
/sbin/rcvboxadd quicksetup all
cd / || exit 2
mkdir -p /home/partimag/image
umount /mnt
apt autoremove -y -q
exit
EOF

    #  apt remove -y -q "\${headers}" build-essential gcc
    #  virtualbox-guest-additions-iso virtualbox

    chmod +x squashfs-root/update_clonezilla.sh

    # now chroot and run update script

    chroot squashfs-root /bin/bash update_clonezilla.sh

    # after exit now back under live/. Update linux kernel:

    check_files squashfs-root/boot/vmlinuz squashfs-root/boot/initrd.img
    cp -vf --dereference squashfs-root/boot/vmlinuz vmlinuz
    cp -vf --dereference squashfs-root/boot/initrd.img  initrd.img

    unmount_clonezilla_iso

    [ -f "${CLONEZILLACD}" ] && rm -vf "${CLONEZILLACD}"

    # this first ISO image is a "save" one: from virtual disk to clonezilla
    # image

    clonezilla_to_iso "${CLONEZILLACD}" "mnt2"
}

bind_mount_clonezilla_iso() {

    if ! "${CREATE_ISO}" && ! "${FROM_DEVICE}" && ! "${FROM_VM}"
    then
        ${LOG[*]} <<< "[ERR] CloneZilla ISO should only be mounted to create \
an ISO installer or to back up a device"
        exit 4
    fi

    cd ${VMPATH}
    if_fails $? "[ERR] Could not cd to ${VMPATH}"

    fetch_process_clonezilla_iso

    if_fails $? "[ERR] Could not fetch CloneZilla ISO file"

    local verb=""
    "${VERBOSE}" && verb="-v"

    # copy to ISOFILES as a skeletteon for ISO recovery image authoring

    [ -d ISOFILES ] && rm -rf ISOFILES
    mkdir -p ISOFILES/home/partimag
    check_dir ISOFILES/home/partimag
    check_dir mnt2
    "${VERBOSE}" \
        && ${LOG[*]} "[INF] Now copying CloneZilla files to temporary \
folder ISOFILES"
    rsync -a mnt2/ ISOFILES
    check_dir mnt2/syslinux
    if "${CREATE_ISO}"
    then
        check_file clonezilla/savedisk/isolinux.cfg
        cp ${verb} -f clonezilla/savedisk/isolinux.cfg mnt2/syslinux/
    fi
    check_dir mnt2/live

    cd mnt2/live

    # prepare chroot in clonezilla filesystem

    for i in proc sys dev run; do mount -B /$i squashfs-root/$i; done

    if_fails $? "[ERR] Could not bind-mount squashfs-root"
    # add update script to clonezilla filesystem. Do not indent!
}

unmount_clonezilla_iso() {

    # clean up and restore squashfs back

    rm -vf filesystem.squashfs
    for i in proc sys dev run; do umount squashfs-root/$i; done
    if_fails $? "[ERR] Could not unmount squashfs-root"

    mksquashfs squashfs-root filesystem.squashfs
    if_fails $? "[ERR] Could not recreate squashfs filesystem"

    cd "${VMPATH}"
    if_fails $? "[ERR] Could not cd to ${VMPATH}"
}

## @fn clonezilla_device_to_image()
## @brief Create CloneZilla xz-compressed image out of an external block device
##        (like a USB stick)
## @details Image is created under ISOFILES/home/partimag/image under VMPATH
## @retval 0 on success otherwise exits -1 on failure
## @ingroup createInstaller

clonezilla_device_to_image() {

    find_ocs_sr=`which ocs-sr`

    # if no platform-installed ocs-sr, try to bootstrap it from clonezill iso

    if [ -z "$find_ocs_sr" ]
    then
        bind_mount_clonezilla_iso

        # now under mnt2/live

        if_fails $? "[ERR] Could not remount and bind CloneZilla ISO file"

        local CLONEZILLA_MOUNTED=true
        local PATH0="${PATH}"
        local LD0="${LD_LIBRARY_PATH}"
        PATH="${PATH}":squashfs-root/sbin:squashfs-root/bin:\
squashfs-root/usr/bin:squashfs-root/usr/sbin
        LD_LIBRARY_PATH="${LDO}":squashfs-root/lib:squashfs-root/lib64:\
squashfs-root/lib32:squashfs-root/usr/lib:squashfs-root/usr/lib64:\
squashfs-root/usr/lib32
        find_ocs_sr=$(which ocs-sr)
        if [ -z "$find_ocs_sr" ]
        then
            # local mount did not work

            ${LOG[*]} "[ERR] Could not find ocs_sr !"
            ${LOG[*]} "[MSG] Install Clonezilla in a standard path or rerun \
 after adding its path to the PATH environment variable"
            ${LOG[*]} "[MSG] Note: Debian-based distributions provide a handy \
CloneZilla package."
            unmount_clonezilla_iso
            PATH="${PATH0}"
            LD_LIBRARY_PATH="${LD0}"
            exit 1
        fi
    fi

    # now ocs-sr is an available tool
    # At this stage EXT_DEVICE can no longer be a mountpoint as it has
    # been previously converted to device label

    if findmnt "/dev/${EXT_DEVICE}"
    then
        ${LOG[*]} "[MSG] Device ${EXT_DEVICE} is mounted to: \
$(get_mountpoint /dev/${EXT_DEVICE})"
        ${LOG[*]} "[WAR] The external USB device should not be mounted"
        ${LOG[*]} "[INF] Trying to unmount..."
        if umount -l "/dev/${EXT_DEVICE}"
        then
            ${LOG[*]} "[MSG] Managed to unmount /dev/${EXT_DEVICE}"
        else
            ${LOG[*]} "[ERR] Could not manage to unmount external USB device"
            ${LOG[*]} "[MSG] Unmount it manually and rerun."
            exit 1
        fi
    fi

    # double check

    if findmnt "/dev/${EXT_DEVICE}"
    then
        ${LOG[*]} "[ERR] Impossible to unmount device ${EXT_DEVICE}"
        exit 1
    fi
    if [ -d /home/partimag ]
    then
        ${LOG[*]} "[WAR] /home/partimag needs to be wiped out..."
        ${LOG[*]} "[INF] Trying with user rights..."
        if ! rm -rf /home/partimag
        then
            ${LOG[*]} "[WAR] Directory /home/partimag needs elevated rights..."
            if ! rm -rf /home/partimag
            then
                ${LOG[*]} "[ERR] Could not fix /home/partimag issue."
                exit 1
            fi
        fi
    fi

    if "${CLEANUP}"
    then
        ${LOG[*]} "[INF] Erasing virtual disk and virtual machine to save \
disk space..."
        [ -f "${VMPATH}/${VM}.vdi" ] && rm -f "${VMPATH}/${VM}.vdi"
        [ -d "${VMPATH}/${VM}" ] && rm -rf "${VMPATH}/${VM}"
    fi
    rm -rf ISOFILES/home/partimag/image/*
    if_fails $? "[ERR] Could not remove old Clonezilla image"

    ln -s  ${VMPATH}/ISOFILES/home/partimag/image  /home/partimag
    /usr/sbin/ocs-sr -q2 -c -j2 -nogui -batch -gm -gmf -noabo -z5 \
     -i 40960000000 -fsck -senc -p poweroff \
     savedisk gentoo.img ${EXT_DEVICE}

    if_fails $? "[ERR] Cloning failed!"
    check_file /home/partimag/gentoo.img "[ERR] Cloning failed: \
did not find grentoo.img"
    ${LOG[*]} "[MSG] Cloning succeeded!"

    if "${CLONEZILLA_MOUNTED}"
    then
        unmount_clonezilla_iso
        PATH="${PATH0}"
        LD_LIBRARY_PATH="${LD0}"
    fi
    return 0
}

# ---------------------------------------------------------------------------- #
# Core program
#

## @fn main()
## @brief Main function launching routines
## @todo Daemonize the part below generate_Gentoo when #VMTYPE is `headless`
## so that the script can be detached completely with `nohup mkgentoo..  &`
## @ingroup createInstaller

main() {

    source scripts/utils.sh

    # Using a temporary writable array A so that
    # ARR will not be writable later on
    # Help cases: bail out

    if grep -q 'help=md' <<< "$@"
    then
        create_options_array options
        help_md
        exit 0
    else
        if grep -q 'help'    <<< "$@"
        then
            create_options_array options
            help_
            exit 0
        else
            create_options_array options2
        fi
    fi
    # parse command line. All arguments must be in the form a=true/false except
    # for help, file.iso. But 'a' can be used as shorthand for 'a=true'

    # Analyse commandline and source auxiliary files

    get_options $@

    check_tool "mksquashfs" "mountpoint" "findmnt" "rsync" "xorriso" \
               "VBoxManage" "curl" "grep" "lsblk" "awk"
    test_cli_pre
    for ((i=0; i<ARRAY_LENGTH; i++)); do test_cli $i; done
    test_cli_post
    cd ${VMPATH}

    source scripts/fetch_functions.sh
    source scripts/build_virtualbox.sh

    # optional VirtualBox build

    "${BUILD_VIRTUALBOX}" && { build_virtualbox; exit 0; }

    # if Gentoo has already been built into an ISO image or on an external device
    # skip generating it; otherwise go and build the Gentoo virtual machine

    # you can bypass generation by setting vm= on commandline

    [ -n "${VM}" ] && ! "${FROM_VM}" && ! "${FROM_DEVICE}" && ! "${FROM_ISO}" \
        && generate_Gentoo

    # process the virtual disk into a clonezilla image

    if [ -f "${VM}.vdi" ] \
       && ("${CREATE_ISO}" || "${FROM_VM}") \
       && ! "${FROM_DEVICE}"
    then
        # Now create a new VM from clonezilla ISO to retrieve
        # Gentoo filesystem from the VDI virtual disk.

        ${LOG[*]} "[INF] Adding VirtualBox Guest Additions to CloneZilla ISO VM."
        "${VERBOSE}" \
            && ${LOG[*]} "[INF] These are necessary to activate folder sharing."

        add_guest_additions_to_clonezilla_iso

        # And launch the corresponding VM

        ${LOG[*]} "[INF] Launching Clonezilla VM to convert virtual disk to \
clonezilla image..."
        create_iso_vm
    fi

    "${FROM_DEVICE}" && clonezilla_device_to_image

    # Now convert the clonezilla xz image image into a bootable ISO

    if "${CREATE_ISO}"
    then
        ${LOG[*]} "[INF] Creating Clonezilla bootable ISO..."

        # this second ISO image is the "restore" one: from clonezilla image
        # to target disk.
        # Now replacing the older "save" (from virtual disk to clonezilla image)
        # config file by the opposite "restore" one (from clonezilla image
        # to target disk)

        cp ${verb} -f clonezilla/restoredisk/isolinux.cfg ISOFILES/syslinux

        if clonezilla_to_iso "${ISO_OUTPUT}" ISOFILES
        then
            ${LOG[*]} "[MSG] Done."
            [ -f "${ISO_OUTPUT}" ] \
                && ${LOG[*]} "[MSG] ISO install medium was created here:\
                       ${ISO_OUTPUT}"  \
                    || ${LOG[*]} "[ERR] ISO install medium failed to be created."
        else
            ${LOG[*]} "[ERR] ISO install medium failed to be created!"
            exit 1
        fi
    fi

    # exporting ISO bootable image to external device (like USB stick)

    "${DEVICE_INSTALLER}" && create_install_ext_device

    # optional disc burning

    if "${BURN}"
    then
       ${LOG[*]}  '[INF] Now burning disk: '
       burn_iso
    fi

    # optional "hot install" on external device

    if "${HOT_INSTALL}" && [ -n "${EXT_DEVICE}" ]
    then
        ${LOG[*]} "[INF] Creating OS on device ${EXT_DEVICE}..."
        create_device_system "${CLONING_METHOD}"
    fi

    # default cleanup

    "${CLEANUP}" &&
        ${LOG[*]} <<< $(cleanup 2>&1 | xargs echo '[INF] Cleaning up: ')

    # send wake-up call

    if [ -n "${EMAIL}" ] && [ -n "${SMTP_URL}" ]
    then

        # optional email end-of-job warning

        [ -n "${EMAIL_PASSWD}" ] \
            && [ -n "${EMAIL}" ] \
            && [ -n "${SMTP_URL}" ] \
            && ${LOG[*]} <<< $(send_mail 2>&1 |xargs echo '[INF] Sending mail: ')
    fi

    ${LOG[*]} "[MSG] Gentoo building process ended."
    exit 0
}

