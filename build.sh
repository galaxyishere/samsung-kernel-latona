#!/bin/bash -x

setup ()
{
    if [ x = "x$ANDROID_BUILD_TOP" ] ; then
        echo "Android build environment must be configured"
        exit 1
    fi
    . "$ANDROID_BUILD_TOP"/build/envsetup.sh

    KERNEL_DIR="$(dirname "$(readlink -f "$0")")"
    BUILD_DIR="$KERNEL_DIR/build"
    MODULES=("samsung/gps/gps.ko" "samsung/vibetonz/vibetonz.ko" "samsung/battery/samsung_battery.ko" "samsung/bma222/yas_acc_kernel_driver.ko" "samsung/orientation/yas_ori_kernel_driver.ko" "samsung/yas529/yas_mag_kernel_driver.ko" "samsung/fm_si4709/Si4709_driver.ko" "samsung/gp2a/gp2a.ko")

    if [ x = "x$NO_CCACHE" ] && ccache -V &>/dev/null ; then
        CCACHE=ccache
        CCACHE_BASEDIR="$KERNEL_DIR"
        CCACHE_COMPRESS=1
        CCACHE_DIR="$BUILD_DIR/.ccache"
        export CCACHE_DIR CCACHE_COMPRESS CCACHE_BASEDIR
    else
        CCACHE=""
    fi

    CROSS_PREFIX="$ANDROID_BUILD_TOP/prebuilt/linux-x86/toolchain/arm-eabi-4.4.0/bin/arm-eabi-"
}

build ()
{
    local target=$1
    echo "Building for $target"
    local target_dir="$BUILD_DIR/$target"
    local module
    [ x = "x$NO_RM" ] && rm -fr "$target_dir"
    mkdir -p "$target_dir/usr"
    cp "$KERNEL_DIR/usr/"*.list "$target_dir/usr"
    sed "s|usr/|$KERNEL_DIR/usr/|g" -i "$target_dir/usr/"*.list
    [ x = "x$NO_DEFCONFIG" ] && mka -C "$KERNEL_DIR" O="$target_dir" latona_${target}_defconfig HOSTCC="$CCACHE gcc"
    if [ x = "x$NO_BUILD" ] ; then
        mka -C "$KERNEL_DIR" O="$target_dir" HOSTCC="$CCACHE gcc" CROSS_COMPILE="$CCACHE $CROSS_PREFIX" modules
        mka -C "$KERNEL_DIR" O="$target_dir" HOSTCC="$CCACHE gcc" CROSS_COMPILE="$CCACHE $CROSS_PREFIX" zImage
        cp "$target_dir"/arch/arm/boot/zImage $ANDROID_BUILD_TOP/device/samsung/$target/kernel
        for module in "${MODULES[@]}" ; do
            cp "$target_dir/$module" $ANDROID_BUILD_TOP/device/samsung/$target
        done
    fi
}
    
setup

if [ "$1" = clean ] ; then
    rm -fr "$BUILD_DIR"/*
    exit 0
fi

targets=("$@")
if [ 0 = "${#targets[@]}" ] ; then
    targets=(galaxysl)
fi

START=$(date +%s)

for target in "${targets[@]}" ; do 
    build $target
done

END=$(date +%s)
ELAPSED=$((END - START))
E_MIN=$((ELAPSED / 60))
E_SEC=$((ELAPSED - E_MIN * 60))
printf "Elapsed: "
[ $E_MIN != 0 ] && printf "%d min(s) " $E_MIN
printf "%d sec(s)\n" $E_SEC