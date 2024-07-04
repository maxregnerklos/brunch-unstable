#!/bin/bash

apply_patches() {
    for patch_type in "base" "others" "chromeos" "all_devices" "surface_devices" "surface_go_devices" "surface_mwifiex_pcie_devices" "surface_np3_devices" "macbook"; do
        if [ -d "./kernel-patches/$1/$patch_type" ]; then
            for patch in ./kernel-patches/"$1/$patch_type"/*.patch; do
                echo "Applying patch: $patch"
                patch -d"./kernels/$1" -p1 --no-backup-if-mismatch -N < "$patch" || { echo "Kernel $1 patch failed"; exit 1; }
            done
        fi
    done
}

make_config() {
    sed -i -z 's@# Detect buggy gcc and clang, fixed in gcc-11 clang-14.\n\tdef_bool@# Detect buggy gcc and clang, fixed in gcc-11 clang-14.\n\tdef_bool $(success,echo 0)\n\t#def_bool@g' ./kernels/$1/init/Kconfig
    if [ "x$1" == "xchromebook-4.19" ]; then config_subfolder=""; else config_subfolder="/chromeos"; fi
    case "$1" in
        6.6|6.1|5.15)
            sed '/CONFIG_ATH\|CONFIG_BUILD\|CONFIG_EXTRA_FIRMWARE\|CONFIG_DEBUG_INFO\|CONFIG_IWL\|CONFIG_LSM\|CONFIG_MODULE_COMPRESS/d' ./kernel-patches/flex_configs > "./kernels/$1/arch/x86/configs/chromeos_defconfig" || { echo "Kernel $1 configuration failed"; exit 1; }
            make -C "./kernels/$1" O=out allmodconfig || { echo "Kernel $1 configuration failed"; exit 1; }
            sed '/CONFIG_ACPI\|CONFIG_AMD\|CONFIG_ATH\|CONFIG_AXP\|CONFIG_B4\|CONFIG_BACKLIGHT\|CONFIG_BATTERY\|CONFIG_BCM\|CONFIG_BN\|CONFIG_BRCM\|CONFIG_BT\|CONFIG_CEC\|CONFIG_CHARGER\|CONFIG_COMMON\|CONFIG_DRM_AMD\|CONFIG_DRM_GMA\|CONFIG_DRM_NOUVEAU\|CONFIG_DRM_RADEON\|CONFIG_DW_DMAC\|CONFIG_EXTCON\|CONFIG_FIREWIRE\|CONFIG_FRAMEBUFFER_CONSOLE\|CONFIG_GENERIC\|CONFIG_GPIO\|CONFIG_HID\|CONFIG_I2C\|CONFIG_I4\|CONFIG_IC\|CONFIG_IG\|CONFIG_INPUT\|CONFIG_INTEL\|CONFIG_IWL\|CONFIG_IX\|CONFIG_JOYSTICK\|CONFIG_KEYBOARD\|CONFIG_LEDS\|CONFIG_MANAGER\|CONFIG_MEDIA_CONTROLLER\|CONFIG_MFD\|CONFIG_MMC\|CONFIG_MOUSE\|CONFIG_MT7\|CONFIG_MW\|CONFIG_NFC\|CONFIG_NVME\|CONFIG_PATA\|CONFIG_POWER\|CONFIG_PWM\|CONFIG_REGULATOR\|CONFIG_RMI\|CONFIG_RT\|CONFIG_SATA\|CONFIG_SCSI\|CONFIG_SENSORS\|CONFIG_SND\|CONFIG_SOUNDWIRE\|CONFIG_SPI\|CONFIG_SSB\|CONFIG_TABLET\|CONFIG_THUNDERBOLT\|CONFIG_TOUCHSCREEN\|CONFIG_TPS68470\|CONFIG_TYPEC\|CONFIG_UCSI\|CONFIG_USB\|CONFIG_VIDEO\|CONFIG_W1\|CONFIG_WL/!d' "./kernels/$1/out/.config" >> "./kernels/$1/arch/x86/configs/chromeos_defconfig" || { echo "Kernel $1 configuration failed"; exit 1; }
            make -C "./kernels/$1" O=out allyesconfig || { echo "Kernel $1 configuration failed"; exit 1; }
            sed '/CONFIG_ATA\|CONFIG_CROS\|CONFIG_HOTPLUG\|CONFIG_MDIO\|CONFIG_PERF\|CONFIG_PINCTRL\|CONFIG.*_PMIC\|CONFIG_.*_FF=\|CONFIG_SATA\|CONFIG_SERI\|CONFIG_USB_STORAGE\|CONFIG_USB_XHCI\|CONFIG_USB_OHCI\|CONFIG_USB_EHCI/!d' "./kernels/$1/out/.config" >> "./kernels/$1/arch/x86/configs/chromeos_defconfig" || { echo "Kernel $1 configuration failed"; exit 1; }
            sed -i '/_DBG\|_DEBUG\|_MOCKUP\|_NOCODEC\|_ONLY\|_WARNINGS\|TEST\|USB_OTG\|_PLTFM\|_PLATFORM\|_SELFTEST\|_TRACING/d' "./kernels/$1/arch/x86/configs/chromeos_defconfig" || { echo "Kernel $1 configuration failed"; exit 1; }
            sed '/CONFIG_ATH\|CONFIG_DEBUG_INFO\|CONFIG_IWL\|CONFIG_MODULE_COMPRESS\|CONFIG_MOUSE/d' "./kernels/$1/chromeos/config$config_subfolder/base.config" >> "./kernels/$1/arch/x86/configs/chromeos_defconfig" || { echo "Kernel $1 configuration failed"; exit 1; }
            sed '/CONFIG_ATH\|CONFIG_DEBUG_INFO\|CONFIG_IWL\|CONFIG_MODULE_COMPRESS\|CONFIG_MOUSE/d' "./kernels/$1/chromeos/config$config_subfolder/x86_64/common.config" >> "./kernels/$1/arch/x86/configs/chromeos_defconfig" || { echo "Kernel $1 configuration failed"; exit 1; }
            cat ./kernel-patches/brunch_configs  >> "./kernels/$1/arch/x86/configs/chromeos_defconfig" || { echo "Kernel $1 configuration failed"; exit 1; }
            echo 'CONFIG_LOCALVERSION="-generic-brunch-sebanc"' >> "./kernels/$1/arch/x86/configs/chromeos_defconfig" || { echo "Kernel $1 configuration failed"; exit 1; }
            make -C "./kernels/$1" O=out chromeos_defconfig || { echo "Kernel $1 configuration failed"; exit 1; }
            cp "./kernels/$1/out/.config" "./kernels/$1/arch/x86/configs/chromeos_defconfig" || { echo "Kernel $1 configuration failed"; exit 1; }
        ;;
        *)
            sed '/CONFIG_ATH\|CONFIG_BUILD\|CONFIG_EXTRA_FIRMWARE\|CONFIG_DEBUG_INFO\|CONFIG_IWL\|CONFIG_LSM\|CONFIG_MODULE_COMPRESS/d' ./kernel-patches/flex_configs > "./kernels/$1/arch/x86/configs/chromeos_defconfig" || { echo "Kernel $1 configuration failed"; exit 1; }
            sed '/CONFIG_DEBUG_INFO\|CONFIG_MODULE_COMPRESS/d' "./kernels/$1/chromeos/config$config_subfolder/base.config" >> "./kernels/$1/arch/x86/configs/chromeos_defconfig" || { echo "Kernel $1 configuration failed"; exit 1; }
            sed '/CONFIG_DEBUG_INFO\|CONFIG_MODULE_COMPRESS/d' "./kernels/$1/chromeos/config$config_subfolder/x86_64/common.config" >> "./kernels/$1/arch/x86/configs/chromeos_defconfig" || { echo "Kernel $1 configuration failed"; exit 1; }
            sed '/CONFIG_DEBUG_INFO\|CONFIG_MODULE_COMPRESS/d' "./kernels/$1/chromeos/config$config_subfolder/x86_64/chromeos-intel-pineview.flavour.config" >> "./kernels/$1/arch/x86/configs/chromeos_defconfig" || { echo "Kernel $1 configuration failed"; exit 1; }
            cat "./kernel-patches/brunch_configs"  >> "./kernels/$1/arch/x86/configs/chromeos_defconfig" || { echo "Kernel $1 configuration failed"; exit 1; }
            echo 'CONFIG_LOCALVERSION="-chromebook-brunch-sebanc"' >> "./kernels/$1/arch/x86/configs/chromeos_defconfig" || { echo "Kernel $1 configuration failed"; exit 1; }
            make -C "./kernels/$1" O=out chromeos_defconfig || { echo "Kernel $1 configuration failed"; exit 1; }
            cp "./kernels/$1/out/.config" "./kernels/$1/arch/x86/configs/chromeos_defconfig" || { echo "Kernel $1 configuration failed"; exit 1; }
        ;;
    esac
}

download_and_patch_kernels() {
    # Find the ChromiumOS kernel remote path corresponding to the release
    kernel_remote_path="$(git ls-remote https://chromium.googlesource.com/chromiumos/third_party/kernel refs/heads/chromeos-4.19 | awk '{print $1}')"
    if [ -z "$kernel_remote_path" ]; then
        echo "Unable to find the ChromiumOS kernel path for $1"
        exit 1
    fi

    kernel_source_url="https://chromium.googlesource.com/chromiumos/third_party/kernel/+archive/$kernel_remote_path.tar.gz"

    mkdir -p ./kernels/$1
    echo "Downloading kernel $1"
    curl --output - -L "$kernel_source_url" | tar xz -C "./kernels/$1" || { echo "Kernel $1 download failed"; exit 1; }
    
    echo "Applying patches to kernel $1"
    apply_patches "$1"
    
    echo "Configuring kernel $1"
    make_config "$1"
}

kernel_versions=("6.6" "6.1" "5.15" "5.4" "4.19" "4.14" "4.9" "4.4" "3.18")

# Run the download and patching processes in parallel
for version in "${kernel_versions[@]}"; do
    download_and_patch_kernels "$version" &
done

# Wait for all parallel tasks to complete
wait

echo "All kernels downloaded, patched, and configured successfully."
