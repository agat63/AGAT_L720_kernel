#!/bin/bash
#
# Colors for error/info messages
#
TXTRED='\e[0;31m' 		# Red
TXTGRN='\e[0;32m' 		# Green
TXTYLW='\e[0;33m' 		# Yellow
BLDRED='\e[1;31m' 		# Red-Bold
BLDGRN='\e[1;32m' 		# Green-Bold
BLDYLW='\e[1;33m' 		# Yellow-Bold
TXTCLR='\e[0m'    		# Text Reset
#
## Settings
#

## Create TAR File for ODIN?
ODIN_TAR=yes		# yes/no

## Create ZIP File for CWM? (needs a updater-template.zip in releasedir)
CWM_ZIP=no		# yes/no

##
## Directory Settings
##
export KERNELDIR=`readlink -f .`
export TOOLBIN="${KERNELDIR}/../bin"
export INITRAMFS_SOURCE="${KERNELDIR}/../initramfs-sgs4-sprint"
export INITRAMFS_TMP="/tmp/initramfs-sgs4-sprint"
export RELEASEDIR="${KERNELDIR}/../releases"
export USE_CCACHE=1

# Target
export AGAT_DEFCONF=agat_defconfig
export ARCH_CONF=jf_spr_defconfig
export SELINUX_CONF=jfselinux_defconfig
export SELINUX_LOGCONF=jfselinux_log_defconfig

# get time of startup
time_start=$(date +%s.%N)

# InitRamFS Branch to use ...
# export RAMFSBRANCH=cm10-testing

rm -fv $KERNELDIR/compile-*.log

# Build Hostname
# export KBUILD_BUILD_HOST=`hostname | sed 's|ip-projects.de|dream-irc.com|g'`

#
# Version of this Build
#
## 1.0 for initial build
KRNRLS="AGAT_GS4_v0.1.0"


#
# Target Settings
#
export ARCH=arm
export CROSS_COMPILE=/home/agat/GS4/kernel-extras/arm-eabi-4.6/bin/arm-eabi-
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
  if [ ! -f $KERNELDIR/arch/arm/configs/$AGAT_DEFCONF ];
  then
    clear
    echo -e "  "
    echo -e "${BLDRED}Error: can not find default Kernel Config: ${AGAT_DEFCONF} !${TXTCLR}"
    echo -e "${BLDRED}Critical Error, Exiting ... !${TXTCLR}"
    echo -e "  "
    # finished? get elapsed time
    time_end=$(date +%s.%N)
    echo -e "${BLDYLW}Total time elapsed: ${TCTCLR}${TXTGRN}$(echo "($time_end - $time_start) / 60"|bc ) ${TXTYLW}minutes${TXTGRN} ($(echo "$time_end - $time_start"|bc ) ${TXTYLW}seconds) ${TXTCLR}"
    echo -e "  "
    exit 1
  fi
  echo -e "${TXTYLW}Creating Kernel config from default: ${AGAT_DEFCONF} ${TXTCLR}"
  make ARCH=arm VARIANT_DEFCONFIG=${ARCH_CONF} SELINUX_DEFCONFIG=${SELINUX_CONF} SELINUX_LOG_DEFCONFIG=${SELINUX_LOGCONF} ${AGAT_DEFCONF} 
  echo -e "${TXTYLW}Kernel config created ...${TXTCLR}"
fi

. $KERNELDIR/.config

# remove Files of old/previous Builds
#
echo -e "${TXTYLW}Deleting Files of previous Builds ...${TXTCLR}"
make -j8 clean
# echo "0" > $KERNELDIR/.version

# Remove Old initramfs
echo -e "${TXTYLW}Deleting old InitRAMFS${TXTCLR}"
rm -rf $INITRAMFS_TMP
rm -rf $INITRAMFS_TMP.*

# Remove previous Kernelfiles
if [ -f $KERNELDIR/boot.img ];
then
  echo -e "${TXTYLW}Deleting old Kernel / Boot Images${TXTCLR}"
  rm $KERNELDIR/boot.img
  # if boot.img exists maybe this 2 also
  rm $KERNELDIR/arch/arm/boot/kernel
  rm $KERNELDIR/arch/arm/boot/zImage
fi

# Start the Build
#
# clear
echo -e "${TXTYLW}CleanUP done, starting modules Build ...${TXTCLR}"

nice -n 10 make -j8 modules 2>&1 | tee compile-zImage.log

#
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

echo -e "${TXTGRN}Build: Stage 1 successfully completed${TXTCLR}"

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

# copy modules into initramfs
#
echo -e "${TXTGRN}Copying Modules to initramfs: ${INITRAMFS_TMP}/lib/modules${TXTCLR}"

mkdir -pv $INITRAMFS_TMP/lib/modules
find $KERNELDIR -name '*.ko' -exec cp -av {} $INITRAMFS_TMP/lib/modules/ \;
sleep 1

echo -e "${TXTGRN}Striping Modules to save space${TXTCLR}"
${CROSS_COMPILE}strip --strip-unneeded $INITRAMFS_TMP/lib/modules/*
sleep 1

# create the initramfs cpio archive
#
$TOOLBIN/mkbootfs $INITRAMFS_TMP > $INITRAMFS_TMP.cpio
echo -e "${TXTGRN}Unpacked Initramfs: $(ls -lh $INITRAMFS_TMP.cpio)${TXTCLR}"

# Create gziped initramfs
#
echo -e "${TXTGRN}compressing InitRamfs...${TXTCLR}"
$TOOLBIN/minigzip < $INITRAMFS_TMP.cpio > $INITRAMFS_TMP.img
echo -e "${TXTGRN}Final gzip compressed Initramfs: $(ls -lh $INITRAMFS_TMP.img)${TXTCLR}"

sleep 1

# Start Final Kernel Build
#
echo -e "${TXTYLW}Starting final Build: Stage 2${TXTCLR}"
nice -n 10 make -j8 zImage 2>&1 | tee compile-zImage.log

if [ -f  $KERNELDIR/arch/arm/boot/zImage ];
then
  echo -e "${TXTGRN}Kernel Image compiled succesfull, Build Stage 2 completed!${TXTCLR}"
  echo " "
  echo -e "${TXTGRN}Final Build: Stage 3. Creating bootimage !${TXTCLR}"
  echo " "
  sleep 1
  cp $KERNELDIR/arch/arm/boot/zImage $KERNELDIR/arch/arm/boot/kernel

  # mkbootimg Commandline .. take care
  $TOOLBIN/mkbootimg --kernel $KERNELDIR/arch/arm/boot/kernel --ramdisk $INITRAMFS_TMP.img --cmdline "console=null androidboot.hardware=qcom user_debug=31 msm_rtb.filter=0x3F ehci-hcd.park=3" --base 0x80200000 --pagesize 2048 --ramdisk_offset 0x02000000 --output $KERNELDIR/boot.img

  if [ -f $KERNELDIR/boot.img ];
  then
    echo " "
    echo -e "${TXTGRN}Final Build: Stage 3 completed successfully!${TXTCLR}"
    echo " "
    rm $KERNELDIR/arch/arm/boot/kernel

    # Archive Name for ODIN/CWM archives
    ARCNAME="$KRNRLS-`date +%Y%m%d%H%M%S`"

    ## Create ODIN Flashable TAR archiv ?
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

    ## Check for update template
    if [ ! -f $RELEASEDIR/updater-template.zip ];
    then
      CWM_ZIP=no
      echo -e "${BLDRED}Updater Template not found!${TXTCLR}"
      echo "  "
    fi

    ## Create CWM-ZIP ?
    if [ "${CWM_ZIP}" == "yes" ];
    then
      echo -e "${BLDRED}creating CWM-Flashable ZIP: ${ARCNAME}-CWM.zip${TXTCLR}"
      cp $RELEASEDIR/updater-template.zip $RELEASEDIR/$ARCNAME-CWM.zip
      zip -u $RELEASEDIR/$ARCNAME-CWM.zip boot.img
      ls -lh $RELEASEDIR/$ARCNAME-CWM.zip
      echo -e "${BLDRED}$(ls -lh ${RELEASEDIR}/${ARCNAME}-CWM.zip)${TXTCLR}"
      echo -e "  "
    else
      echo -e "${BLDRED}Skipping CWM-ZIP creation${TXTCLR}"
      echo "  "
    fi
    echo "  "
    echo -e "${BLDGRN}	#############################	${TXTCLR}"
    echo -e "${TXTRED}	# Script completed, exiting #	${TXTCLR}"
    echo -e "${BLDGRN}	#############################	${TXTCLR}"
    echo " "
    # finished? get elapsed time
    time_end=$(date +%s.%N)
    echo -e "${BLDYLW}Total time elapsed: ${TCTCLR}${TXTGRN}$(echo "($time_end - $time_start) / 60"|bc ) ${TXTYLW}minutes${TXTGRN} ($(echo "$time_end - $time_start"|bc ) ${TXTYLW}seconds) ${TXTCLR}"
    exit 0
  else
    echo " "
    echo -e "${BLDRED}Final Build: Stage 3 failed with Error!${TXTCLR}"
    echo -e "${BLDRED}failed to build Boot Image, exiting ...${TXTCLR}"
    echo " "
    # finished? get elapsed time
    time_end=$(date +%s.%N)
    echo -e "${BLDYLW}Total time elapsed: ${TCTCLR}${TXTGRN}$(echo "($time_end - $time_start) / 60"|bc ) ${TXTYLW}minutes${TXTGRN} ($(echo "$time_end - $time_start"|bc ) ${TXTYLW}seconds) ${TXTCLR}"
    exit 1
  fi
else
  echo " "
  echo -e "${BLDRED}Final Build: Stage 2 failed with Error!${TXTCLR}"
  echo -e "${BLDRED}failed to compile Kernel Image, exiting ...${TXTCLR}"
  echo " "
  time_end=$(date +%s.%N)
  echo -e "${BLDYLW}Total time elapsed: ${TCTCLR}${TXTGRN}$(echo "($time_end - $time_start) / 60"|bc ) ${TXTYLW}minutes${TXTGRN} ($(echo "$time_end - $time_start"|bc ) ${TXTYLW}seconds) ${TXTCLR}"
  exit 1
fi

geany ~/logs/$version.txt || exit 1
