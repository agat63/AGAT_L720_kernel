#!/bin/bash
#
# Colors for error/info messages
#
TXTRED='\e[0;31m'               # Red
TXTGRN='\e[0;32m'               # Green
TXTYLW='\e[0;33m'               # Yellow
BLDRED='\e[1;31m'               # Red-Bold
BLDGRN='\e[1;32m'               # Green-Bold
BLDYLW='\e[1;33m'               # Yellow-Bold
TXTCLR='\e[0m'                  # Text Reset
#
## Settings
#
 
## Create TAR File for ODIN?
ODIN_TAR=no            # yes/no (Currently disabled due modules not included in boot.img)
 
## Create ZIP File for CWM? (needs a updater-template.zip in releasedir)
CWM_ZIP=yes             # yes/no
 
##
## Directory Settings
##
export KERNELDIR=`readlink -f .`
export TOOLBIN="${KERNELDIR}/../../bin"
export INITRAMFS_SOURCE="${KERNELDIR}/../Ramdisk"
export INITRAMFS_TMP="/tmp/initrams-tmp"
export RELEASEDIR="${KERNELDIR}/../releases"
export CCACHE_DIR="/home/agat/build/.ccache"
export USE_CCACHE=1
 
## For CWM ZIP
export UPDATER_TEMPLATE=${KERNELDIR}/../releases/tempdir
export UPDATER_TMP=/tmp/tempdir
 
# Target Configs ...
export DREAM_DEFCONF=agat_defconfig
export ARCH_CONF=jf_spr_defconfig
export SELINUX_CONF=jfselinux_defconfig
export SELINUX_LOGCONF=jfselinux_log_defconfig
 
# get time of startup
time_start=$(date +%s.%N)
 
# InitRamFS Branch to use ...
# export RAMFSBRANCH=cm10-testing
 
# Build Hostname
export KBUILD_BUILD_HOST=`hostname | sed 's|ip-projects.de|dream-irc.com|g'`
 
#
# Version of this Build
#
## 1.0 for initial build
KRNRLS="AGAT_GS4_v0.5.0"
 
 
#
## Target Settings
#
export ARCH=arm
#export CROSS_COMPILE="galaxys4-"


# Choose Propper Compiler setup
if [ "${USE_CCACHE}" == "1" ];
then
echo -e "${TXTGRN}Using ccache Compiler Cache ..${TXTCLR}"
export CCACHE_DIR="/home/agat/build/.ccache"
export CROSS_COMPILE="ccache galaxys4-"
else
echo -e "${TXTYLW}NOT using ccache Compiler Cache ..${TXTCLR}"
export CROSS_COMPILE="galaxys4-"
fi


export USE_SEC_FIPS_MODE=true

if [ "${1}" != "" ];
then
  if [ -d  $1 ];
  then
    export KERNELDIR=`readlink -f ${1}`
    echo -e "${TXTGRN}Using alternative Kernel Directory: ${KERNELDIR}${TXTCLR}"
  else
    echo -e "${BLDRED}Error: ${1} is not a directory !${TXTCLR}"
    echo -e "${BLDRED}Nothing todo, Exiting ... !${TXTCLR}"
    # finished? get elapsed time
    time_end=$(date +%s.%N)
    echo -e "${BLDYLW}Total time elapsed: ${TCTCLR}${TXTGRN}$(echo "($time_end - $time_start) / 60"|bc ) ${TXTYLW}minutes${TXTGRN} ($(echo "$time_end - $time_start"|bc ) ${TXTYLW}seconds) ${TXTCLR}"
    exit 1
  fi
fi

# make sure we have no stale config
make -j8 distclean
 
if [ ! -f $KERNELDIR/.config ];
then
  if [ ! -f $KERNELDIR/arch/arm/configs/$DREAM_DEFCONF ];
  then
    clear
    echo -e "  "
    echo -e "${BLDRED}Error: can not find default Kernel Config: ${DREAM_DEFCONF} !${TXTCLR}"
    echo -e "${BLDRED}Critical Error, Exiting ... !${TXTCLR}"
    echo -e "  "
    # finished? get elapsed time
    time_end=$(date +%s.%N)
    echo -e "${BLDYLW}Total time elapsed: ${TCTCLR}${TXTGRN}$(echo "($time_end - $time_start) / 60"|bc ) ${TXTYLW}minutes${TXTGRN} ($(echo "$time_end - $time_start"|bc ) ${TXTYLW}seconds) ${TXTCLR}"
    echo -e "  "
    exit 1
  fi
  echo -e "${TXTYLW}Creating Kernel config from default: ${DREAM_DEFCONF} ${TXTCLR}"
  # make ARCH=arm VARIANT_DEFCONFIG=${ARCH_CONF} SELINUX_DEFCONFIG=${SELINUX_CONF} SELINUX_LOG_DEFCONFIG=${SELINUX_LOGCONF} ${DREAM_DEFCONF}  2>&1 | grcat conf.gcc
  make ARCH=arm VARIANT_DEFCONFIG=${ARCH_CONF} SELINUX_DEFCONFIG=${SELINUX_CONF} ${DREAM_DEFCONF} 
  echo -e "${TXTYLW}Kernel config created ...${TXTCLR}"
fi

. $KERNELDIR/.config

# remove Files of old/previous Builds
#
echo -e "${TXTYLW}Deleting Files of previous Builds ...${TXTCLR}"
# make -j8 clean 2>&1 | grcat conf.gcc
# echo "0" > $KERNELDIR/.version

# Remove Old initramfs/updater template
if [ -d $UPDATER_TMP ];
then
  echo -e "${TXTYLW}Deleting old updater template${TXTCLR}"
  rm -rf $UPDATER_TMP
fi

if [ -d $INITRAMFS_TMP ];
then
  echo -e "${TXTYLW}Deleting old initramfs temp files${TXTCLR}"
  rm -rf $INITRAMFS_TMP
fi

if [ -f $INITRAMFS_TMP.cpio ];
then
  echo -e "${TXTYLW}Deleting old initramfs cpio Archive${TXTCLR}"
  rm -f $INITRAMFS_TMP.cpio
fi

if [ -f $INITRAMFS_TMP.img ];
then
  echo -e "${TXTYLW}Deleting old initramfs image${TXTCLR}"
  rm -f $INITRAMFS_TMP.img
fi

# Remove previous Kernelfiles
if [ -f $KERNELDIR/boot.img ];
then
  echo -e "${TXTYLW}Deleting old Kernel / Boot Images${TXTCLR}"
  rm $KERNELDIR/boot.img
  # if boot.img exists maybe this 2 also
  rm $KERNELDIR/arch/arm/boot/kernel
  rm $KERNELDIR/arch/arm/boot/zImage
fi

## INITRAMFS ##
#
# copy initramfs files to tmp directory
#
echo -e "${TXTGRN}Copying initramfs Filesystem to: ${INITRAMFS_TMP}${TXTCLR}"
cp -vax $INITRAMFS_SOURCE $INITRAMFS_TMP
sleep 1

# remove repository realated files
#
echo -e "${TXTGRN}Deleting Repository related Files (.git, .hg etc)${TXTCLR}"
find $INITRAMFS_TMP -name .git -exec rm -rf {} \;
find $INITRAMFS_TMP -name EMPTY_DIRECTORY -exec rm -rf {} \;
rm -rf $INITRAMFS_TMP/.hg

# create the initramfs cpio archive
#
$TOOLBIN/mkbootfs $INITRAMFS_TMP > $INITRAMFS_TMP.cpio
echo -e "${TXTGRN}Unpacked Initramfs: $(ls -lh $INITRAMFS_TMP.cpio)${TXTCLR}"
echo "  "

# Create gziped initramfs
#
echo -e "${TXTGRN}compressing InitRamfs...${TXTCLR}"
$TOOLBIN/minigzip < $INITRAMFS_TMP.cpio > $INITRAMFS_TMP.img
echo -e "${TXTGRN}Final gzip compressed Initramfs: $(ls -lh $INITRAMFS_TMP.img)${TXTCLR}"

# delete temp initramfs files/dirs
#
echo "  "
echo -e "${TXTGRN}Deleting Temp DIR/CPIO: ($INITRAMFS_TMP)${TXTCLR}"
rm -rf $INITRAMFS_TMP

echo -e "${TXTGRN}Deleting Temp cpio Archive: ($INITRAMFS_TMP.cpio)${TXTCLR}"
rm -f $INITRAMFS_TMP.cpio

## Start Final Kernel Build
#
echo -e "${TXTYLW}Starting final Build: Stage 2${TXTCLR}"

## Build zImage
#nice -n 10 make -j8 CC="galaxys4-gcc" zImage 2>&1 | tee compile-zImage.log
nice -n 10 make -j3 CC="ccache galaxys4-gcc" zImage 2>&1 | ${TOOLBIN}/grcat conf.gcc
 
if [ -f  $KERNELDIR/arch/arm/boot/zImage ];
then
  cp $KERNELDIR/arch/arm/boot/zImage $KERNELDIR/arch/arm/boot/kernel
  echo -e "${TXTGRN}Kernel Image compiled succesfull, Build Stage 1 completed!${TXTCLR}"
  echo " "
  echo -e "${TXTGRN}Build: Stage 2. compiling Modules !${TXTCLR}"
  echo " "
  sleep 1
else
  echo " "
  echo -e "${BLDRED}Final Build: Stage 1 failed with Error!${TXTCLR}"
  echo -e "${BLDRED}failed to build Kernel Image, exiting ...${TXTCLR}"
  echo " "
  # finished? get elapsed time
  time_end=$(date +%s.%N)
  echo -e "${BLDYLW}Total time elapsed: ${TCTCLR}${TXTGRN}$(echo "($time_end - $time_start) / 60"|bc ) ${TXTYLW}minutes${TXTGRN} ($(echo "$time_end - $time_start"|bc ) ${TXTYLW}seconds) ${TXTCLR}"
  exit 1
fi

## Build Modules
#nice -n 10 make -j8 CC="galaxys4" modules 2>&1 | tee compile-modules.log
nice -n 10 make -j3 CC="ccache galaxys4-gcc" modules 2>&1 | ${TOOLBIN}/grcat conf.gcc

## Let's compile frandom with each kernel build
cd  ${KERNELDIR}/../frandom-1.1
make
cd ${KERNELDIR}
 
## Check exitcode for module build
if [ "$?" == "0" ];
then
  echo -e "${TXTYLW}Modules Build done ...${TXTCLR}"
  sleep 2
else
  echo -e "${BLDRED}Modules Build failed, exiting  ...${TXTCLR}"
  # finished? get elapsed time
  time_end=$(date +%s.%N)
  echo -e "${BLDYLW}Total time elapsed: ${TCTCLR}${TXTGRN}$(echo "($time_end - $time_start) / 60"|bc ) ${TXTYLW}minutes${TXTGRN} ($(echo "$time_end - $time_start"|bc ) ${TXTYLW}seconds) ${TXTCLR}"
  exit 1
fi

## Create Boot Image
#
# mkbootimg Commandline .. take care
#
echo " "
echo -e "${TXTGRN}creating Boot Image (boot.img)!${TXTCLR}"
$TOOLBIN/mkbootimg --kernel $KERNELDIR/arch/arm/boot/kernel --ramdisk $INITRAMFS_TMP.img --cmdline "console=null androidboot.hardware=qcom user_debug=31 msm_rtb.filter=0x3F ehci-hcd.park=3" --base 0x80200000 --pagesize 2048 --ramdisk_offset 0x02000000 --output $KERNELDIR/boot.img

## Check for boot.img
#
if [ -f $KERNELDIR/boot.img ];
then
  echo " "
  echo -e "${TXTGRN}Boot Image sucessfully created...!${TXTCLR}"
  echo " "
  # Clean Up
  rm $KERNELDIR/arch/arm/boot/kernel
  rm -f $INITRAMFS_TMP.img
else
  echo " "
  echo -e "${BLDRED}Final Build: Stage 2 failed with Error!${TXTCLR}"
  echo -e "${BLDRED}failed to create Boot Image, exiting ...${TXTCLR}"
  echo " "
  time_end=$(date +%s.%N)
  echo -e "${BLDYLW}Total time elapsed: ${TCTCLR}${TXTGRN}$(echo "($time_end - $time_start) / 60"|bc ) ${TXTYLW}minutes${TXTGRN} ($(echo "$time_end - $time_start"|bc ) ${TXTYLW}seconds) ${TXTCLR}"
  exit 1
fi

# Archive Name for ODIN/CWM/TWRP archives
ARCNAME="$KRNRLS-`date +%m%d%H%M`"
 
## Create ODIN Flashable TAR archiv ? (Not supported for now)
if [ "${ODIN_TAR}" == "yes" ];
then
  echo -e "${BLDRED}creating ODIN-Flashable TAR: ${ARCNAME}${TXTCLR}"
  cd $KERNELDIR
  tar cf $RELEASEDIR/$ARCNAME.tar boot.img
  echo -e "${BLDRED}$(ls -lh ${RELEASEDIR}/${ARCNAME}.tar)${TXTCLR}"
else
  echo -e "${BLDRED}Skipping ODIN-TAR creation${TXTCLR}"
  echo "   "
fi

## Check for update template (CWM/TWRP)
if [ ! -d $UPDATER_TEMPLATE ];
then
  CWM_ZIP=no
  echo -e "${BLDRED}Updater Template not found!${TXTCLR}"
  echo "  "
fi

## Create CWM-ZIP ##
if [ "${CWM_ZIP}" == "yes" ];
then
  ## Update ZIP template ##

  # copy updater zip template files to tmp directory
  #
  echo "  "
  echo -e "${TXTGRN}Copying update zip template to: ${UPDATER_TMP}${TXTCLR}"
  cp -vax $UPDATER_TEMPLATE $UPDATER_TMP
  sleep 1

  # copy modules into update zip template
  #
  echo "  "
  echo -e "${TXTGRN}Copying Modules to update zip template: ${UPDATER_TMP}/system/lib/modules${TXTCLR}"
  mkdir -pv $UPDATER_TMP/system/lib/modules
  # mkdir -pv $UPDATER_TMP/system/xbin
  find $KERNELDIR -name '*.ko' -exec cp -av {} $UPDATER_TMP/system/lib/modules/ \;
  cp $KERNELDIR/../frandom-1.1/frandom.ko $UPDATER_TMP/system/lib/modules/frandom.ko
  # cp $KERNELDIR/../frandom-1.1/mount.exfat-fuse $UPDATER_TMP/system/xbin/mount.exfat-fuse
  # chmod 755 $UPDATER_TMP/system/xbin/mount.exfat-fuse
  sleep 1

  # Strip Modules
  #
  echo "  "
  echo -e "${TXTGRN}Striping Modules to save space${TXTCLR}"
  ${CROSS_COMPILE}strip --strip-unneeded $UPDATER_TMP/system/lib/modules/*
  sleep 1

  # Create Final ZIP
  #
  echo "  "
  echo -e "${BLDRED}creating CWM-Flashable ZIP: ${ARCNAME}-CWM.zip${TXTCLR}"
  cp $KERNELDIR/boot.img $UPDATER_TMP/boot.img
  cd $UPDATER_TMP
  zip -r $RELEASEDIR/$ARCNAME-CWM.zip *
  cd $KERNELDIR
  echo -e "${BLDRED}$(ls -lh ${RELEASEDIR}/${ARCNAME}-CWM.zip)${TXTCLR}"
  echo -e "  "
  # remove update template
  rm -rf $UPDATER_TMP
else
  echo -e "${BLDRED}Skipping CWM-ZIP creation${TXTCLR}"
  echo "  "
fi

# finished? get elapsed time
time_end=$(date +%s.%N)
echo "  "
echo -e "${BLDGRN}      #############################   ${TXTCLR}"
echo -e "${TXTRED}      # Script completed, exiting #   ${TXTCLR}"
echo -e "${BLDGRN}      #############################   ${TXTCLR}"
echo " "
echo -e "${BLDYLW}Total time elapsed: ${TCTCLR}${TXTGRN}$(echo "($time_end - $time_start) / 60"|bc ) ${TXTYLW}minutes${TXTGRN} ($(echo "$time_end - $time_start"|bc ) ${TXTYLW}seconds) ${TXTCLR}"
exit 0
