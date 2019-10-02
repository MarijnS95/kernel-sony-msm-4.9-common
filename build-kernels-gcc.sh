cd ../../../..
export ANDROID_ROOT=$(pwd)
export kernel_top=$ANDROID_ROOT/kernel/sony/msm-4.9
export kernel_tmp=$ANDROID_ROOT/out/kernel-49

# Cross Compiler
export CROSS_COMPILE=$ANDROID_ROOT/prebuilts/gcc/linux-x86/aarch64/aarch64-linux-android-4.9/bin/aarch64-linux-android-
export CROSS_COMPILE_ARM32=$ANDROID_ROOT/prebuilts/gcc/linux-x86/arm/arm-linux-androideabi-4.9/bin/arm-linux-androideabi-

# Mkdtimg tool
export MKDTIMG=$ANDROID_ROOT/out/host/linux-x86/bin/mkdtimg

# Check if mkdtimg tool exists
if [ ! -f $MKDTIMG ]; then
    echo "mkdtimg: File not found!"
    echo "Building mkdtimg"
    export ALLOW_MISSING_DEPENDENCIES=true
    make mkdtimg
fi

LOIRE="suzu"
TONE="dora kagura keyaki"
YOSHINO="lilac maple poplar"
NILE="discovery"
GANGES="kirin mermaid"
TAMA="akari apollo akatsuki"

PLATFORMS="loire tone yoshino nile ganges tama kumano"
PLATFORMS="loire"

cd $kernel_top/kernel

echo "================================================="
echo "Your Environment:"
echo "ANDROID_ROOT: ${ANDROID_ROOT}"
echo "kernel_top  : ${kernel_top}"
echo "kernel_tmp  : ${kernel_tmp}"

for platform in $PLATFORMS; do \

case $platform in
loire)
    DEVICE=$LOIRE;
    DTBO="false";;
tone)
    DEVICE=$TONE;
    DTBO="false";;
yoshino)
    DEVICE=$YOSHINO;
    DTBO="false";;
nile)
    DEVICE=$NILE;
    DTBO="false";;
ganges)
    DEVICE=$GANGES;
    DTBO="false";;
tama)
    DEVICE=$TAMA;
    DTBO="true";;
esac

for device in $DEVICE; do \
    device_out=$kernel_tmp/${device}-gcc
    ret=$(mkdir -p $device_out 2>&1);
    if [ ! -d $device_out ] ; then
        echo "Check your environment";
        echo "ERROR: ${ret}";
        exit 1;
    fi

    # Build command
    build="make O=$device_out ARCH=arm64 CROSS_COMPILE=$CROSS_COMPILE -j$(nproc)"

    # Copy prebuilt kernel
    CP_BLOB="cp $device_out/arch/arm64/boot/Image.gz-dtb $kernel_top/common-kernel/kernel-dtb"

    echo "================================================="
    echo "Platform -> ${platform} :: Device -> $device"
    ret=$(${build} aosp_$platform"_"$device\_defconfig 2>&1);
    case "$ret" in
        *"error"*|*"ERROR"*) echo "ERROR: $ret"; exit 1;;
    esac

    echo "The build may take up to 10 minutes. Please be patient ..."
    echo "Building new kernel image ..."
    build_log="$kernel_tmp/build_log_${platform}_${device}_gcc"
    echo "Logging to $build_log"
    $build >$build_log 2>&1;

    echo "Copying new kernel image ..."
    ret=$(${CP_BLOB}-${device} 2>&1);
    case "$ret" in
        *"error"*|*"ERROR"*) echo "ERROR: $ret"; exit 1;;
    esac
    if [ $DTBO = "true" ]; then
        $MKDTIMG create $kernel_top/common-kernel/dtbo-$device\.img `find $device_out/arch/arm64/boot/dts -name "*.dtbo"`
    fi
done
done

echo "================================================="
echo "Clean up environment"
echo "Done!"
unset ANDROID_ROOT
unset KERNEL_CFG
