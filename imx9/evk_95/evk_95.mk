# -------@block_infrastructure-------
CONFIG_REPO_PATH := device/nxp
CURRENT_FILE_PATH :=  $(lastword $(MAKEFILE_LIST))
IMX_DEVICE_PATH := $(strip $(patsubst %/, %, $(dir $(CURRENT_FILE_PATH))))

PRODUCT_ENFORCE_ARTIFACT_PATH_REQUIREMENTS := true
#Enable this to choose 32 bit user space build
IMX8_BUILD_32BIT_ROOTFS ?= false

# configs shared between uboot, kernel and Android rootfs
include $(IMX_DEVICE_PATH)/SharedBoardConfig.mk

-include $(CONFIG_REPO_PATH)/common/imx_path/ImxPathConfig.mk
include $(CONFIG_REPO_PATH)/imx9/ProductConfigCommon.mk

# -------@block_common_config-------
# Overrides
PRODUCT_NAME := evk_95
PRODUCT_DEVICE := evk_95
PRODUCT_MODEL := EVK_95

TARGET_BOOTLOADER_BOARD_NAME := EVK_95

PRODUCT_CHARACTERISTICS := tablet

DEVICE_PACKAGE_OVERLAYS := $(IMX_DEVICE_PATH)/overlay

PRODUCT_COMPATIBLE_PROPERTY_OVERRIDE := true

PRODUCT_VENDOR_PROPERTIES += ro.soc.manufacturer=nxp
PRODUCT_VENDOR_PROPERTIES += ro.soc.model=IMX95
PRODUCT_VENDOR_PROPERTIES += ro.crypto.metadata_init_delete_all_keys.enabled=true
# -------@block_treble-------
PRODUCT_FULL_TREBLE_OVERRIDE := true

# -------@block_power-------
PRODUCT_SOONG_NAMESPACES += vendor/nxp-opensource/imx/power
PRODUCT_SOONG_NAMESPACES += hardware/google/pixel

PRODUCT_COPY_FILES += \
    $(IMX_DEVICE_PATH)/powerhint_imx95.json:$(TARGET_COPY_OUT_VENDOR)/etc/configs/powerhint_imx95.json

# Do not skip charger_not_need trigger by default
PRODUCT_DEFAULT_PROPERTY_OVERRIDES += \
    vendor.skip.charger_not_need=0


PRODUCT_PACKAGES += \
    android.hardware.power-service.imx

TARGET_VENDOR_PROP := $(LOCAL_PATH)/product.prop

# Thermal HAL
PRODUCT_PACKAGES += \
    android.hardware.thermal-service.imx
PRODUCT_COPY_FILES += \
    $(IMX_DEVICE_PATH)/thermal_info_config_imx95.json:$(TARGET_COPY_OUT_VENDOR)/etc/configs/thermal_info_config_imx95.json


# -------@block_app-------

# Set permission for GMS packages
PRODUCT_COPY_FILES += \
	  $(CONFIG_REPO_PATH)/imx9/permissions/privapp-permissions-imx.xml:$(TARGET_COPY_OUT_PRODUCT)/etc/permissions/privapp.permissions-imx.xml

PRODUCT_COPY_FILES += \
    $(IMX_DEVICE_PATH)/app_whitelist.xml:system/etc/sysconfig/app_whitelist.xml

# -------@block_kernel_bootimg-------

# Enable this to support vendor boot and boot header v3, this would be a MUST for GKI
TARGET_USE_VENDOR_BOOT ?= true

# Allow LZ4 compression
BOARD_RAMDISK_USE_LZ4 := true

ifeq ($(LOADABLE_KERNEL_MODULE),true)
  BOARD_USES_GENERIC_KERNEL_IMAGE := true
  $(call inherit-product, $(SRC_TARGET_DIR)/product/generic_ramdisk.mk)
endif

# We load the fstab from device tree so this is not needed, but since no kernel modules are installed to vendor
# boot ramdisk so far, we need this step to generate the vendor-ramdisk folder or build process would fail. This
# can be deleted once we figure out what kernel modules should be put into the vendor boot ramdisk.
ifeq ($(TARGET_USE_VENDOR_BOOT),true)
PRODUCT_COPY_FILES += \
    $(IMX_DEVICE_PATH)/fstab.nxp:$(TARGET_COPY_OUT_VENDOR_RAMDISK)/first_stage_ramdisk/fstab.nxp
endif

PRODUCT_COPY_FILES += \
    $(IMX_DEVICE_PATH)/early.init.cfg:$(TARGET_COPY_OUT_VENDOR)/etc/early.init.cfg \
    $(LINUX_FIRMWARE_IMX_PATH)/linux-firmware-imx/firmware/sdma/sdma-imx7d.bin:$(TARGET_COPY_OUT_VENDOR_RAMDISK)/lib/firmware/imx/sdma/sdma-imx7d.bin \
    $(CONFIG_REPO_PATH)/common/init/init.insmod.sh:$(TARGET_COPY_OUT_VENDOR)/bin/init.insmod.sh \
    $(IMX_DEVICE_PATH)/ueventd.nxp.rc:$(TARGET_COPY_OUT_VENDOR)/etc/ueventd.rc


# -------@block_storage-------
# support metadata checksum during first stage mount
ifeq ($(TARGET_USE_VENDOR_BOOT),true)
PRODUCT_PACKAGES += \
    linker.vendor_ramdisk \
    resizefs.vendor_ramdisk \
    tune2fs.vendor_ramdisk
endif

#Enable this to use dynamic partitions for the readonly partitions not touched by bootloader
TARGET_USE_DYNAMIC_PARTITIONS ?= true

ifeq ($(TARGET_USE_DYNAMIC_PARTITIONS),true)
  ifeq ($(TARGET_USE_VENDOR_BOOT),true)
    $(call inherit-product, $(SRC_TARGET_DIR)/product/virtual_ab_ota/compression_with_xor.mk)
  else
    $(call inherit-product, $(SRC_TARGET_DIR)/product/virtual_ab_ota.mk)
  endif
  PRODUCT_USE_DYNAMIC_PARTITIONS := true
  BOARD_BUILD_SUPER_IMAGE_BY_DEFAULT := true
  BOARD_SUPER_IMAGE_IN_UPDATE_PACKAGE := true
endif

#Enable this to disable product partition build.
IMX_NO_PRODUCT_PARTITION := false

$(call inherit-product, $(SRC_TARGET_DIR)/product/emulated_storage.mk)

PRODUCT_COPY_FILES += \
    $(IMX_DEVICE_PATH)/fstab.nxp:$(TARGET_COPY_OUT_VENDOR)/etc/fstab.nxp

TARGET_RECOVERY_FSTAB = $(IMX_DEVICE_PATH)/fstab.nxp

ifneq ($(filter TRUE true 1,$(IMX_OTA_POSTINSTALL)),)
  PRODUCT_PACKAGES += imx_ota_postinstall

  AB_OTA_POSTINSTALL_CONFIG += \
    RUN_POSTINSTALL_vendor=true \
    POSTINSTALL_PATH_vendor=bin/imx_ota_postinstall \
    FILESYSTEM_TYPE_vendor=erofs \
    POSTINSTALL_OPTIONAL_vendor=false

  PRODUCT_COPY_FILES += \
    $(OUT_DIR)/target/product/$(firstword $(PRODUCT_DEVICE))/obj/UBOOT_COLLECTION/spl-imx95-trusty-dual.bin:$(TARGET_COPY_OUT_VENDOR)/etc/bootloader0.img
  ifeq ($(BUILD_ENCRYPTED_BOOT),true)
    PRODUCT_COPY_FILES += \
      $(OUT_DIR)/target/product/$(firstword $(PRODUCT_DEVICE))/obj/UBOOT_COLLECTION/bootloader-imx95-trusty-dual.img:$(TARGET_COPY_OUT_VENDOR)/etc/bootloader_ab.img
  endif
endif


# fastboot_imx_flashall scripts, imx-sdcard-partition script uuu_imx_android_flash scripts
PRODUCT_COPY_FILES += \
    $(CONFIG_REPO_PATH)/common/tools/fastboot_imx_flashall.bat:fastboot_imx_flashall.bat \
    $(CONFIG_REPO_PATH)/common/tools/fastboot_imx_flashall.sh:fastboot_imx_flashall.sh \
    $(CONFIG_REPO_PATH)/common/tools/imx-sdcard-partition.sh:imx-sdcard-partition.sh \
    $(CONFIG_REPO_PATH)/common/tools/uuu_imx_android_flash.bat:uuu_imx_android_flash.bat \
    $(CONFIG_REPO_PATH)/common/tools/uuu_imx_android_flash.sh:uuu_imx_android_flash.sh

# -------@block_security-------

# Include keystore attestation keys and certificates.
ifeq ($(PRODUCT_IMX_TRUSTY),true)
-include $(IMX_SECURITY_PATH)/attestation/imx_attestation.mk
endif

ifeq ($(PRODUCT_IMX_TRUSTY),true)
PRODUCT_COPY_FILES += \
    $(CONFIG_REPO_PATH)/common/security/rpmb_key_test.bin:rpmb_key_test.bin \
    $(CONFIG_REPO_PATH)/common/security/testkey_public_rsa4096.bin:testkey_public_rsa4096.bin
endif

# Keymaster HAL
ifeq ($(PRODUCT_IMX_TRUSTY),true)
PRODUCT_PACKAGES += \
    android.hardware.security.keymint-service.rust.trusty
endif

PRODUCT_PACKAGES += \
    android.hardware.security.keymint-service-imx

# Confirmation UI
ifeq ($(PRODUCT_IMX_TRUSTY),true)
PRODUCT_PACKAGES += \
    android.hardware.confirmationui-service.trusty
endif

# new gatekeeper HAL
PRODUCT_PACKAGES += \
    android.hardware.gatekeeper-service-imx

# Add oem unlocking option in settings.
PRODUCT_PROPERTY_OVERRIDES += ro.frp.pst=/dev/block/by-name/presistdata

ifeq ($(PRODUCT_IMX_TRUSTY),true)
#Oemlock HAL support
PRODUCT_PACKAGES += \
    android.hardware.oemlock-service.imx \
    android.hardware.oemlock-service-software.imx
endif

# Add Trusty OS backed gatekeeper and secure storage proxy
ifeq ($(PRODUCT_IMX_TRUSTY),true)
PRODUCT_PACKAGES += \
    android.hardware.gatekeeper-service.trusty \
    storageproxyd \
    imx_dek_extractor \
    imx_dek_inserter
endif

# Specify rollback index for boot and vbmeta partitions
ifneq ($(AVB_RBINDEX),)
BOARD_AVB_ROLLBACK_INDEX := $(AVB_RBINDEX)
else
BOARD_AVB_ROLLBACK_INDEX := 0
endif

ifneq ($(AVB_BOOT_RBINDEX),)
BOARD_AVB_BOOT_ROLLBACK_INDEX := $(AVB_BOOT_RBINDEX)
else
BOARD_AVB_BOOT_ROLLBACK_INDEX := 0
endif

ifneq ($(AVB_INIT_BOOT_RBINDEX),)
BOARD_AVB_INIT_BOOT_ROLLBACK_INDEX := $(AVB_INIT_BOOT_RBINDEX)
else
BOARD_AVB_INIT_BOOT_ROLLBACK_INDEX := 0
endif

$(call  inherit-product-if-exists, vendor/nxp-private/security/nxp_security.mk)

# Resume on Reboot support
PRODUCT_PACKAGES += \
    android.hardware.rebootescrow-service.default

PRODUCT_PROPERTY_OVERRIDES += \
    ro.rebootescrow.device=/dev/block/pmem0

#DRM Widevine 1.4 L1 support
PRODUCT_PACKAGES += \
    android.hardware.drm-service.clearkey \
    libwvdrmcryptoplugin \
    libwvaidl \
    liboemcrypto \
    firmware_loader

TARGET_BUILD_WIDEVINE :=
TARGET_BUILD_WIDEVINE_USE_PREBUILT := true

$(call inherit-product-if-exists, vendor/nxp-private/widevine/nxp_widevine_tee_95.mk)
$(call inherit-product-if-exists, vendor/nxp-private/widevine/apex/device.mk)

# -------@block_audio-------

# Audio card json
PRODUCT_COPY_FILES += \
    $(CONFIG_REPO_PATH)/common/audio-json/cs42888_config.json:$(TARGET_COPY_OUT_VENDOR)/etc/configs/audio/cs42888_config.json \
    $(CONFIG_REPO_PATH)/common/audio-json/wm8904_config.json:$(TARGET_COPY_OUT_VENDOR)/etc/configs/audio/wm8904_config.json \
    $(CONFIG_REPO_PATH)/common/audio-json/wm8962_config.json:$(TARGET_COPY_OUT_VENDOR)/etc/configs/audio/wm8962_config.json \
    $(CONFIG_REPO_PATH)/common/audio-json/micfil_config.json:$(TARGET_COPY_OUT_VENDOR)/etc/configs/audio/micfil_config.json \
    $(CONFIG_REPO_PATH)/common/audio-json/btsco_config.json:$(TARGET_COPY_OUT_VENDOR)/etc/configs/audio/btsco_config.json \
    $(CONFIG_REPO_PATH)/common/audio-json/readme.txt:$(TARGET_COPY_OUT_VENDOR)/etc/configs/audio/readme.txt

# LPA demo
PRODUCT_COPY_FILES += \
    $(FSL_PROPRIETARY_PATH)/fsl-proprietary/mcu-sdk/imx95/imx95_mcu_demo_lpa.img:imx95_mcu_demo.img

ifeq ($(POWERSAVE),true)
PRODUCT_COPY_FILES += \
    $(CONFIG_REPO_PATH)/common/audio-json/pcm512x_config.json:$(TARGET_COPY_OUT_VENDOR)/etc/configs/audio/pcm512x_config.json
endif

PRODUCT_COPY_FILES += \
    $(IMX_DEVICE_PATH)/audio_effects.xml:$(TARGET_COPY_OUT_VENDOR)/etc/audio_effects.xml \
    $(IMX_DEVICE_PATH)/usb_audio_policy_configuration-direct-output.xml:$(TARGET_COPY_OUT_VENDOR)/etc/usb_audio_policy_configuration-direct-output.xml

ifeq ($(POWERSAVE),true)
PRODUCT_COPY_FILES += \
    $(OUT_DIR)/target/product/$(firstword $(PRODUCT_DEVICE))/imx8mp_mcu_demo.bin:imx8mp_mcu_demo.img \
    $(IMX_DEVICE_PATH)/audio_policy_configuration_pcm512x.xml:$(TARGET_COPY_OUT_VENDOR)/etc/audio_policy_configuration.xml
else
PRODUCT_COPY_FILES += \
    $(FSL_PROPRIETARY_PATH)/fsl-proprietary/mcu-sdk/imx8mp/imx8mp_mcu_demo.img:imx8mp_mcu_demo.img \
    $(IMX_DEVICE_PATH)/audio_policy_configuration.xml:$(TARGET_COPY_OUT_VENDOR)/etc/audio_policy_configuration.xml
endif

# Audio SOF firmware and tplg files
PRODUCT_COPY_FILES += \
    $(FSL_PROPRIETARY_PATH)/fsl-proprietary/sof/sof-tplg/sof-imx8mp-wm8960.tplg:$(TARGET_COPY_OUT_VENDOR)/firmware/imx/sof-tplg/sof-imx8mp-wm8960.tplg \
    $(FSL_PROPRIETARY_PATH)/fsl-proprietary/sof/sof-tplg/sof-imx8mp-compr-wm8960.tplg:$(TARGET_COPY_OUT_VENDOR)/firmware/imx/sof-tplg/sof-imx8mp-compr-wm8960.tplg \
    $(FSL_PROPRIETARY_PATH)/fsl-proprietary/sof/sof-tplg/sof-imx8mp-wm8962.tplg:$(TARGET_COPY_OUT_VENDOR)/firmware/imx/sof-tplg/sof-imx8mp-wm8962.tplg \
    $(FSL_PROPRIETARY_PATH)/fsl-proprietary/sof/sof-tplg/sof-imx8mp-compr-wm8962.tplg:$(TARGET_COPY_OUT_VENDOR)/firmware/imx/sof-tplg/sof-imx8mp-compr-wm8962.tplg \
    $(FSL_PROPRIETARY_PATH)/fsl-proprietary/sof/sof-gcc/sof-imx8m.ldc:$(TARGET_COPY_OUT_VENDOR)/firmware/imx/sof/sof-imx8m.ldc \
    $(FSL_PROPRIETARY_PATH)/fsl-proprietary/sof/sof-gcc/sof-imx8m.ri:$(TARGET_COPY_OUT_VENDOR)/firmware/imx/sof/sof-imx8m.ri

# -------@block_camera-------

PRODUCT_COPY_FILES += \
    $(IMX_DEVICE_PATH)/camera_config_imx95.json:$(TARGET_COPY_OUT_VENDOR)/etc/configs/camera_config_imx95.json \
    $(IMX_DEVICE_PATH)/external_camera_config.xml:$(TARGET_COPY_OUT_VENDOR)/etc/external_camera_config.xml

PRODUCT_PACKAGES += \
    ap130x_ar0144_single_fw.bin

PREBUILT_LIBCAMERA := false
PRODUCT_PACKAGES += \
    capture \
    libcamera-base \
    libcamera \
    libyaml

PRODUCT_SOONG_NAMESPACES += hardware/google/camera
PRODUCT_SOONG_NAMESPACES += vendor/nxp-opensource/imx/camera

# -------@block_display-------

PRODUCT_AAPT_CONFIG += xlarge large tvdpi hdpi xhdpi xxhdpi

# -----some limiataion of overlay/g2d in hwcomposer3 --------
SOONG_CONFIG_NAMESPACES += nxp_hwc
SOONG_CONFIG_nxp_hwc += overlay_ip
SOONG_CONFIG_nxp_hwc_overlay_ip := DPU

PRODUCT_PACKAGES += \
        android.hardware.graphics.composer3-service.imx \
        libg2d-dpu

# define frame buffer count
PRODUCT_DEFAULT_PROPERTY_OVERRIDES += \
    ro.surface_flinger.max_frame_buffer_acquired_buffers=3

# RenderScript HAL
PRODUCT_PACKAGES += \
    android.hardware.renderscript@1.0-impl

PRODUCT_COPY_FILES += \
    $(IMX_DEVICE_PATH)/display_settings.xml:$(TARGET_COPY_OUT_VENDOR)/etc/display_settings.xml

PRODUCT_COPY_FILES += \
    $(IMX_DEVICE_PATH)/input-port-associations.xml:$(TARGET_COPY_OUT_VENDOR)/etc/input-port-associations.xml

# -------@block_gpu-------
# include wsialloc gralloc device config
-include $(IMX_WSI_ALLOC_PATH)/android/gralloc.device.mk

PRODUCT_PACKAGES += \
    mali_csffw.bin \
    gpu.xml \
    arm.graphics-V5-ndk \
    arm.mali.platform-V2-ndk \
    libarm_egl_properties_sysprop \
    libarm_gralloc_properties_sysprop \
    libarm_mali_config_sysprops \
    libGLES_mali \
    libOpenCL \
    vulkan.mali


PRODUCT_PACKAGES += \
        android.hardware.graphics.allocator-service \
        android.hardware.graphics.allocator-V2-arm \
        mapper.arm

PRODUCT_VENDOR_PROPERTIES += \
    ro.hardware.egl = mali \
    ro.hardware.vulkan = mali

# -------@block_wifi-------

PRODUCT_COPY_FILES += \
    $(CONFIG_REPO_PATH)/common/wifi/p2p_supplicant_overlay.conf:$(TARGET_COPY_OUT_VENDOR)/etc/wifi/p2p_supplicant_overlay.conf \
    $(CONFIG_REPO_PATH)/common/wifi/wpa_supplicant_overlay.conf:$(TARGET_COPY_OUT_VENDOR)/etc/wifi/wpa_supplicant_overlay.conf

# WiFi HAL
PRODUCT_PACKAGES += \
    android.hardware.wifi-service \
    wificond

# WiFi RRO
PRODUCT_PACKAGES += \
    WifiOverlay

# nxp 8997 wifi and bluetooth combo Firmware
PRODUCT_COPY_FILES += \
    vendor/nxp/imx-firmware/nxp/FwImage_9098_PCIE/pcieuart9098_combo_v1.bin:vendor/firmware/pcieuart9098_combo_v1.bin \
    vendor/nxp/imx-firmware/nxp/FwImage_IW612_SD/sduart_nw61x_v1.bin.se:vendor/firmware/sduart_nw61x_v1.bin.se \
    vendor/nxp/imx-firmware/nxp/android_wifi_mod_para.conf:vendor/firmware/wifi_mod_para.conf

# Wifi regulatory
PRODUCT_COPY_FILES += \
    external/wireless-regdb/regulatory.db:$(TARGET_COPY_OUT_VENDOR)/firmware/regulatory.db \
    external/wireless-regdb/regulatory.db.p7s:$(TARGET_COPY_OUT_VENDOR)/firmware/regulatory.db.p7s

# -------@block_bluetooth-------

# Bluetooth HAL
PRODUCT_PACKAGES += \
    android.hardware.bluetooth@1.0-impl \
    android.hardware.bluetooth@1.0-service

#nxp 8997 Bluetooth vendor config
PRODUCT_PACKAGES += \
    bt_vendor.conf

# -------@block_usb-------

# Usb HAL
PRODUCT_PACKAGES += \
    android.hardware.usb-service.imx \
    android.hardware.usb.gadget-service.imx

PRODUCT_COPY_FILES += \
    $(IMX_DEVICE_PATH)/init.usb.rc:$(TARGET_COPY_OUT_VENDOR)/etc/init/hw/init.nxp.usb.rc

PRODUCT_DEFAULT_PROPERTY_OVERRIDES += \
    sys.usb.mtp.batchcancel=1

# -------@block_multimedia_codec-------

# Vendor seccomp policy files for media components:
PRODUCT_COPY_FILES += \
    $(IMX_DEVICE_PATH)/seccomp/mediacodec-seccomp.policy:vendor/etc/seccomp_policy/mediacodec.policy \
    $(IMX_DEVICE_PATH)/seccomp/mediaextractor-seccomp.policy:vendor/etc/seccomp_policy/mediaextractor.policy


# imx c2 codec binary
PRODUCT_PACKAGES += \
    lib_imx_c2_videodec_common \
    lib_imx_c2_videodec \
    lib_imx_c2_videoenc_common \
    lib_imx_c2_videoenc \
    lib_imx_c2_v4l2_dev \
    lib_imx_c2_v4l2_dec \
    lib_imx_c2_v4l2_enc \
    c2_component_register \
    c2_component_register_ms \
    c2_component_register_ra

PRODUCT_PACKAGES += \
    DirectAudioPlayer

ifeq ($(PREBUILT_FSL_IMX_CODEC),true)
ifneq ($(IMX8_BUILD_32BIT_ROOTFS),true)
INSTALL_64BIT_LIBRARY := true
endif
-include $(FSL_RESTRICTED_CODEC_PATH)/fsl-restricted-codec/imx_dsp/imx_dsp_8mp.mk
endif

# -------@block_vpu-------
# VPU files
PRODUCT_COPY_FILES += \
    $(LINUX_FIRMWARE_IMX_PATH)/linux-firmware-imx/firmware/vpu/wave633c_codec_fw.bin:$(TARGET_COPY_OUT_VENDOR)/firmware/wave633c_codec_fw.bin \
    $(LINUX_FIRMWARE_IMX_PATH)/linux-firmware-imx/firmware/vpu/wave633c_codec_fw.bin.signed:$(TARGET_COPY_OUT_VENDOR)/firmware/wave633c_codec_fw.bin.signed \

# -------@block_memory-------

# Include Android Go config for low memory device.
ifeq ($(LOW_MEMORY),true)
$(call inherit-product, build/target/product/go_defaults.mk)
endif

# -------@block_neural_network-------

# Neural Network HAL and lib
PRODUCT_PACKAGES += \
    libNeutronDriver \
    NeutronFirmware.elf \
    NeutronKernels.bin \
    android.hardware.neuralnetworks-shell-service-imx

# Tensorflow lite camera demo
PRODUCT_PACKAGES += \
                    tflitecamerademo

# -------@block_miscellaneous-------

# Copy device related config and binary to board
PRODUCT_COPY_FILES += \
    $(IMX_DEVICE_PATH)/init.imx95.rc:$(TARGET_COPY_OUT_VENDOR)/etc/init/hw/init.nxp.imx95.rc \
    $(IMX_DEVICE_PATH)/init.rc:$(TARGET_COPY_OUT_VENDOR)/etc/init/hw/init.nxp.rc

ifeq ($(TARGET_USE_VENDOR_BOOT),true)
  PRODUCT_COPY_FILES += \
    $(IMX_DEVICE_PATH)/init.recovery.nxp.rc:$(TARGET_COPY_OUT_VENDOR_RAMDISK)/init.recovery.nxp.rc
else
  PRODUCT_COPY_FILES += \
    $(IMX_DEVICE_PATH)/init.recovery.nxp.rc:root/init.recovery.nxp.rc
endif

ifeq ($(POWERSAVE),true)
PRODUCT_COPY_FILES += \
    $(IMX_DEVICE_PATH)/required_hardware_powersave.xml:$(TARGET_COPY_OUT_VENDOR)/etc/permissions/required_hardware.xml
else
PRODUCT_COPY_FILES += \
    $(IMX_DEVICE_PATH)/required_hardware.xml:$(TARGET_COPY_OUT_VENDOR)/etc/permissions/required_hardware.xml
endif

# ONLY devices that meet the CDD's requirements may declare these features

ifneq ($(POWERSAVE),true)
PRODUCT_COPY_FILES += \
    frameworks/native/data/etc/android.hardware.camera.external.xml:vendor/etc/permissions/android.hardware.camera.external.xml \
    frameworks/native/data/etc/android.hardware.camera.front.xml:$(TARGET_COPY_OUT_VENDOR)/etc/permissions/android.hardware.camera.front.xml \
    frameworks/native/data/etc/android.hardware.camera.xml:$(TARGET_COPY_OUT_VENDOR)/etc/permissions/android.hardware.camera.xml
endif

PRODUCT_COPY_FILES += \
    frameworks/native/data/etc/android.hardware.audio.output.xml:$(TARGET_COPY_OUT_VENDOR)/etc/permissions/android.hardware.audio.output.xml \
    frameworks/native/data/etc/android.hardware.bluetooth_le.xml:$(TARGET_COPY_OUT_VENDOR)/etc/permissions/android.hardware.bluetooth_le.xml \
    frameworks/native/data/etc/android.hardware.ethernet.xml:$(TARGET_COPY_OUT_VENDOR)/etc/permissions/android.hardware.ethernet.xml \
    frameworks/native/data/etc/android.hardware.screen.landscape.xml:$(TARGET_COPY_OUT_VENDOR)/etc/permissions/android.hardware.screen.landscape.xml \
    frameworks/native/data/etc/android.hardware.screen.portrait.xml:$(TARGET_COPY_OUT_VENDOR)/etc/permissions/android.hardware.screen.portrait.xml \
    frameworks/native/data/etc/android.hardware.touchscreen.multitouch.distinct.xml:$(TARGET_COPY_OUT_VENDOR)/etc/permissions/android.hardware.touchscreen.multitouch.distinct.xml \
    frameworks/native/data/etc/android.hardware.touchscreen.multitouch.xml:$(TARGET_COPY_OUT_VENDOR)/etc/permissions/android.hardware.touchscreen.multitouch.xml \
    frameworks/native/data/etc/android.hardware.touchscreen.xml:$(TARGET_COPY_OUT_VENDOR)/etc/permissions/android.hardware.touchscreen.xml \
    frameworks/native/data/etc/android.hardware.usb.accessory.xml:$(TARGET_COPY_OUT_VENDOR)/etc/permissions/android.hardware.usb.accessory.xml \
    frameworks/native/data/etc/android.hardware.usb.host.xml:$(TARGET_COPY_OUT_VENDOR)/etc/permissions/android.hardware.usb.host.xml \
    frameworks/native/data/etc/android.hardware.vulkan.level-1.xml:$(TARGET_COPY_OUT_VENDOR)/etc/permissions/android.hardware.vulkan.level.xml \
    frameworks/native/data/etc/android.hardware.vulkan.version-1_3.xml:$(TARGET_COPY_OUT_VENDOR)/etc/permissions/android.hardware.vulkan.version.xml \
    frameworks/native/data/etc/android.hardware.vulkan.compute-0.xml:$(TARGET_COPY_OUT_VENDOR)/etc/permissions/android.hardware.vulkan.compute.xml \
    frameworks/native/data/etc/android.software.vulkan.deqp.level-2023-03-01.xml:$(TARGET_COPY_OUT_VENDOR)/etc/permissions/android.software.vulkan.deqp.level.xml \
    frameworks/native/data/etc/android.software.opengles.deqp.level-2023-03-01.xml:$(TARGET_COPY_OUT_VENDOR)/etc/permissions/android.software.opengles.deqp.level.xml \
    frameworks/native/data/etc/android.hardware.opengles.aep.xml:$(TARGET_COPY_OUT_VENDOR)/etc/permissions/android.hardware.opengles.aep.xml \
    frameworks/native/data/etc/android.hardware.wifi.direct.xml:$(TARGET_COPY_OUT_VENDOR)/etc/permissions/android.hardware.wifi.direct.xml \
    frameworks/native/data/etc/android.hardware.wifi.xml:$(TARGET_COPY_OUT_VENDOR)/etc/permissions/android.hardware.wifi.xml \
    frameworks/native/data/etc/android.hardware.wifi.passpoint.xml:$(TARGET_COPY_OUT_VENDOR)/etc/permissions/android.hardware.wifi.passpoint.xml \
    frameworks/native/data/etc/android.software.app_widgets.xml:$(TARGET_COPY_OUT_VENDOR)/etc/permissions/android.software.app_widgets.xml \
    frameworks/native/data/etc/android.software.backup.xml:$(TARGET_COPY_OUT_VENDOR)/etc/permissions/android.software.backup.xml \
    frameworks/native/data/etc/android.software.device_admin.xml:$(TARGET_COPY_OUT_VENDOR)/etc/permissions/android.software.device_admin.xml \
    frameworks/native/data/etc/android.software.managed_users.xml:$(TARGET_COPY_OUT_VENDOR)/etc/permissions/android.software.managed_users.xml \
    frameworks/native/data/etc/android.software.midi.xml:$(TARGET_COPY_OUT_VENDOR)/etc/permissions/android.software.midi.xml \
    frameworks/native/data/etc/android.software.print.xml:$(TARGET_COPY_OUT_VENDOR)/etc/permissions/android.software.print.xml \
    frameworks/native/data/etc/android.software.sip.voip.xml:$(TARGET_COPY_OUT_VENDOR)/etc/permissions/android.software.sip.voip.xml \
    frameworks/native/data/etc/android.software.verified_boot.xml:$(TARGET_COPY_OUT_VENDOR)/etc/permissions/android.software.verified_boot.xml \
    frameworks/native/data/etc/android.software.voice_recognizers.xml:$(TARGET_COPY_OUT_VENDOR)/etc/permissions/android.software.voice_recognizers.xml \
    frameworks/native/data/etc/android.software.activities_on_secondary_displays.xml:$(TARGET_COPY_OUT_VENDOR)/etc/permissions/android.software.activities_on_secondary_displays.xml \
    frameworks/native/data/etc/android.software.picture_in_picture.xml:$(TARGET_COPY_OUT_VENDOR)/etc/permissions/android.software.picture_in_picture.xml

# trusty loadable apps
PRODUCT_COPY_FILES += \
    vendor/nxp/fsl-proprietary/uboot-firmware/imx95/confirmationui-imx95.app:/vendor/firmware/tee/confirmationui.app

# Keymint configuration
PRODUCT_COPY_FILES += \
    frameworks/native/data/etc/android.software.device_id_attestation.xml:$(TARGET_COPY_OUT_VENDOR)/etc/permissions/android.software.device_id_attestation.xml

# Included GMS package
ifeq ($(filter TRUE true 1,$(IMX_BUILD_32BIT_ROOTFS) $(IMX_BUILD_32BIT_64BIT_ROOTFS)),)
$(call inherit-product-if-exists, vendor/partner_gms/products/gms_64bit_only.mk)
else
$(call inherit-product-if-exists, vendor/partner_gms/products/gms.mk)
endif
PRODUCT_SOONG_NAMESPACES += vendor/partner_gms

ifeq ($(PRODUCT_IMX_TRUSTY),true)
PRODUCT_COPY_FILES += \
    $(CONFIG_REPO_PATH)/common/security/firmware_encrypt_key.bin:firmware_test_keys/firmware_encrypt_key.bin  \
    $(CONFIG_REPO_PATH)/common/security/firmware_public_key.der:firmware_test_keys/firmware_public_key.der
endif
