#!/bin/bash -x

if [ x = "x$ANDROID_BUILD_TOP" ] ; then
echo "Android build environment must be configured"
exit 1
fi
. "$ANDROID_BUILD_TOP"/build/envsetup.sh

# Make mrproper
make mrproper

# Set config
make latona_galaxysl_defconfig

# Make modules
nice -n 10 make -j8 modules

# Copy modules
find -name '*.ko' -exec cp -av {} $ANDROID_BUILD_TOP/device/samsung/galaxysl/modules/ \;

# Build kernel
nice -n 10 make -j8 zImage

# Copy kernel
cp arch/arm/boot/zImage $ANDROID_BUILD_TOP/device/samsung/galaxysl/kernel

# Make mrproper
make mrproper
