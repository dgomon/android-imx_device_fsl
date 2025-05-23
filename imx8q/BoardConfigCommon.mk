# -------@block_common_config-------
#
# SoC-specific compile-time definitions.
#

BOARD_HAVE_VPU := true
BOARD_VPU_TYPE := malone
FSL_VPU_OMX_ONLY := true
HAVE_FSL_IMX_GPU2D := true
HAVE_FSL_IMX_GPU3D := true
HAVE_FSL_IMX_PXP := false
TARGET_USES_HWC2 := true
TARGET_HAVE_VULKAN := true
ENABLE_DMABUF_HEAP := true

#
# Product-specific compile-time definitions.
#

SOONG_CONFIG_NAMESPACES += IMXPLUGIN
SOONG_CONFIG_IMXPLUGIN += BOARD_PLATFORM \
IMX_CAR \
NUM_FRAMEBUFFER_SURFACE_BUFFERS \
BOARD_HAVE_IMX_EVS \
BOARD_SOC_TYPE \
BOARD_SOC_CLASS \
HAVE_FSL_IMX_GPU3D \
TARGET_HWCOMPOSER_VERSION \
TARGET_GRALLOC_VERSION \
PREBUILT_FSL_IMX_GPU \
PRODUCT_MANUFACTURER \
BOARD_HAVE_VPU \
BOARD_VPU_TYPE \
BOARD_VPU_ONLY \
PREBUILT_FSL_IMX_CODEC \
ENABLE_DMABUF_HEAP

SOONG_CONFIG_IMXPLUGIN_BOARD_PLATFORM = imx8
SOONG_CONFIG_IMXPLUGIN_BOARD_HAVE_IMX_EVS = true
SOONG_CONFIG_IMXPLUGIN_BOARD_SOC_TYPE = IMX8Q
SOONG_CONFIG_IMXPLUGIN_BOARD_SOC_CLASS = IMX8
SOONG_CONFIG_IMXPLUGIN_HAVE_FSL_IMX_GPU3D = true
SOONG_CONFIG_IMXPLUGIN_BOARD_HAVE_VPU = true
SOONG_CONFIG_IMXPLUGIN_BOARD_VPU_TYPE = malone
SOONG_CONFIG_IMXPLUGIN_BOARD_VPU_ONLY = false
SOONG_CONFIG_IMXPLUGIN_PREBUILT_FSL_IMX_CODEC = true
SOONG_CONFIG_IMXPLUGIN_ENABLE_DMABUF_HEAP = true

ifeq ($(IMX_BUILD_32BIT_ROOTFS),true)
TARGET_ARCH := arm
TARGET_ARCH_VARIANT := armv7-a-neon
TARGET_CPU_ABI := armeabi-v7a
TARGET_CPU_ABI2 := armeabi
TARGET_CPU_VARIANT := cortex-a9
TARGET_USES_64_BIT_BINDER := true
else
TARGET_ARCH := arm64
TARGET_ARCH_VARIANT := armv8-a
TARGET_CPU_ABI := arm64-v8a
TARGET_CPU_ABI2 :=
TARGET_CPU_VARIANT := cortex-a53

ifneq ($(filter TRUE true 1,$(IMX_BUILD_32BIT_64BIT_ROOTFS)),)
TARGET_2ND_ARCH := arm
TARGET_2ND_ARCH_VARIANT := armv7-a-neon
TARGET_2ND_CPU_ABI := armeabi-v7a
TARGET_2ND_CPU_ABI2 := armeabi
TARGET_2ND_CPU_VARIANT := cortex-a9
endif
endif

BOARD_SOC_CLASS := IMX8
BOARD_SOC_TYPE := IMX8Q
SOONG_CONFIG_IMXPLUGIN_PRODUCT_MANUFACTURER = nxp

# -------@block_security-------
ENABLE_CFI=true

# -------@block_kernel_bootimg-------
TARGET_NO_BOOTLOADER := true
TARGET_NO_KERNEL := false
TARGET_NO_RECOVERY := true
TARGET_NO_RADIOIMAGE := true

BOARD_KERNEL_BASE := 0x80200000
BOARD_KERNEL_OFFSET := 0x00080000
BOARD_RAMDISK_OFFSET := 0x7BE00000
ifeq ($(TARGET_USE_VENDOR_BOOT),true)
BOARD_BOOT_HEADER_VERSION := 4
BOARD_INIT_BOOT_HEADER_VERSION := 4
BOARD_INCLUDE_DTB_IN_BOOTIMG := false
else
BOARD_BOOT_HEADER_VERSION := 2
endif

BOARD_MKBOOTIMG_ARGS = --kernel_offset $(BOARD_KERNEL_OFFSET) --ramdisk_offset $(BOARD_RAMDISK_OFFSET) --header_version $(BOARD_BOOT_HEADER_VERSION)
BOARD_MKBOOTIMG_INIT_ARGS += --header_version $(BOARD_INIT_BOOT_HEADER_VERSION)

ifeq ($(BOARD_BOOT_HEADER_VERSION),2)
    BOARD_MKBOOTIMG_ARGS += --dtb $(word 1,$(TARGET_DTB))
endif

ifeq ($(TARGET_USE_VENDOR_BOOT),true)
  BOARD_MOVE_RECOVERY_RESOURCES_TO_VENDOR_BOOT := true
else
  BOARD_USES_RECOVERY_AS_BOOT := true
endif

# kernel module's copy to vendor need this folder setting
KERNEL_OUT ?= $(OUT_DIR)/target/product/$(PRODUCT_DEVICE)/obj/KERNEL_OBJ

TARGET_BOARD_KERNEL_HEADERS := $(CONFIG_REPO_PATH)/common/kernel-headers

TARGET_IMX_KERNEL ?= false
ifeq ($(TARGET_IMX_KERNEL),false)
BOARD_PREBUILT_BOOTIMAGE := vendor/nxp-opensource/imx-gki/boot_8q.img
TARGET_NO_KERNEL := true
endif

# -------@block_app-------
# Enable dex-preoptimization to speed up first boot sequence
ifeq ($(HOST_OS),linux)
  ifeq ($(TARGET_BUILD_VARIANT),user)
    ifeq ($(WITH_DEXPREOPT),)
      WITH_DEXPREOPT := true
    endif
  endif
endif

# -------@block_storage-------
AB_OTA_UPDATER := true
ifeq ($(IMX_NO_PRODUCT_PARTITION),true)
AB_OTA_PARTITIONS += dtbo boot system system_dlkm system_ext vendor vendor_dlkm vbmeta
else
ifeq ($(TARGET_USE_VENDOR_BOOT),true)
AB_OTA_PARTITIONS += dtbo boot init_boot vendor_boot system system_dlkm system_ext vendor vendor_dlkm vbmeta product
else
AB_OTA_PARTITIONS += dtbo boot system system_dlkm system_ext vendor vendor_dlkm vbmeta product
endif
endif

BOARD_DTBOIMG_PARTITION_SIZE := 4194304
BOARD_BOOTIMAGE_PARTITION_SIZE := 67108864
BOARD_INIT_BOOT_IMAGE_PARTITION_SIZE := 8388608
ifeq ($(TARGET_USE_VENDOR_BOOT),true)
BOARD_VENDOR_BOOTIMAGE_PARTITION_SIZE := 67108864
endif

BOARD_SYSTEMIMAGE_FILE_SYSTEM_TYPE := erofs

BOARD_VENDORIMAGE_FILE_SYSTEM_TYPE := erofs
TARGET_COPY_OUT_VENDOR := vendor

ifneq ($(IMX_NO_PRODUCT_PARTITION),true)
  BOARD_USES_PRODUCTIMAGE := true
  BOARD_PRODUCTIMAGE_FILE_SYSTEM_TYPE := erofs
  TARGET_COPY_OUT_PRODUCT := product
endif

# Build a separate system_ext.img partition
BOARD_USES_SYSTEM_EXTIMAGE := true
BOARD_SYSTEM_EXTIMAGE_FILE_SYSTEM_TYPE := erofs
TARGET_COPY_OUT_SYSTEM_EXT := system_ext

# Build a separate vendor_dlkm partition
BOARD_USES_VENDOR_DLKMIMAGE := true
BOARD_VENDOR_DLKMIMAGE_FILE_SYSTEM_TYPE := erofs
TARGET_COPY_OUT_VENDOR_DLKM := vendor_dlkm

# Build a separate system_dlkm partition
BOARD_USES_SYSTEM_DLKMIMAGE := true
BOARD_SYSTEM_DLKMIMAGE_FILE_SYSTEM_TYPE := erofs
TARGET_COPY_OUT_SYSTEM_DLKM := system_dlkm
ifeq ($(PRODUCT_IMX_CAR),)
BOARD_SYSTEM_KERNEL_MODULES += $(wildcard vendor/nxp-opensource/imx-gki/system_dlkm_staging_8q/flatten/lib/modules/*.ko)
endif


BOARD_FLASH_BLOCK_SIZE := 4096

ifeq ($(TARGET_USE_DYNAMIC_PARTITIONS),true)
  BOARD_SUPER_PARTITION_GROUPS := nxp_dynamic_partitions
  BOARD_SUPER_PARTITION_SIZE := 4294967296
  BOARD_NXP_DYNAMIC_PARTITIONS_SIZE := 4284481536
  ifeq ($(IMX_NO_PRODUCT_PARTITION),true)
    BOARD_NXP_DYNAMIC_PARTITIONS_PARTITION_LIST := system system_dlkm system_ext vendor vendor_dlkm
  else
    BOARD_NXP_DYNAMIC_PARTITIONS_PARTITION_LIST := system system_dlkm system_ext vendor vendor_dlkm product

  endif
else
  BOARD_VENDORIMAGE_PARTITION_SIZE := 671088640
  BOARD_SYSTEM_EXTIMAGE_PARTITION_SIZE := 134217728
  ifeq ($(IMX_NO_PRODUCT_PARTITION),true)
    BOARD_SYSTEMIMAGE_PARTITION_SIZE := 2952790016
  else
    BOARD_SYSTEMIMAGE_PARTITION_SIZE := 1610612736

    BOARD_PRODUCTIMAGE_PARTITION_SIZE := 1879048192
  endif
endif

# -------@block_bluetooth-------
BOARD_HAVE_BLUETOOTH := true

# -------@block_camera-------
BOARD_HAVE_IMX_CAMERA := true

# -------@block_display-------
TARGET_GRALLOC_VERSION := v4
TARGET_HWCOMPOSER_VERSION = v2.0

SOONG_CONFIG_IMXPLUGIN_NUM_FRAMEBUFFER_SURFACE_BUFFERS = 3
SOONG_CONFIG_IMXPLUGIN_TARGET_HWCOMPOSER_VERSION = v2.0
SOONG_CONFIG_IMXPLUGIN_TARGET_GRALLOC_VERSION = v4

TARGET_RECOVERY_PIXEL_FORMAT := "RGBX_8888"

TARGET_RECOVERY_UI_LIB := librecovery_ui_imx

# -------@block_gpu-------
# Indicate use vivante drm based egl and gralloc
BOARD_GPU_DRIVERS := vivante

# Not build mesa3d to avoid conflict with imx
BOARD_USE_CUSTOMIZED_MESA := true

# Indicate use NXP libdrm-imx or Android external/libdrm
BOARD_GPU_LIBDRM := libdrm_imx

PREBUILT_FSL_IMX_GPU := true
SOONG_CONFIG_IMXPLUGIN_PREBUILT_FSL_IMX_GPU = true

# override some prebuilt setting if DISABLE_FSL_PREBUILT is define
ifneq (,$(filter GPU ALL,$(DISABLE_FSL_PREBUILT)))
  PREBUILT_FSL_IMX_GPU := false
  SOONG_CONFIG_IMXPLUGIN_PREBUILT_FSL_IMX_GPU = false
endif

# -------@block_sensor-------
PREBUILT_FSL_IMX_SENSOR_FUSION := true

# override some prebuilt setting if DISABLE_FSL_PREBUILT is define
ifneq (,$(filter SENSOR_FUSION ALL,$(DISABLE_FSL_PREBUILT)))
    PREBUILT_FSL_IMX_SENSOR_FUSION := false
endif

# -------@block_treble-------
BOARD_VNDK_VERSION := current

# -------@block_multimedia_codec-------
-include $(FSL_RESTRICTED_CODEC_PATH)/fsl-restricted-codec/fsl_ms_codec/BoardConfig.mk
-include $(FSL_RESTRICTED_CODEC_PATH)/fsl-restricted-codec/fsl_real_dec/BoardConfig.mk

BOARD_MOVE_GSI_AVB_KEYS_TO_VENDOR_BOOT := true

# Set Vendor SPL to match platform
VENDOR_SECURITY_PATCH = $(PLATFORM_SECURITY_PATCH)

# Set boot SPL
BOOT_SECURITY_PATCH = $(PLATFORM_SECURITY_PATCH)

TARGET_ENABLE_MEDIADRM_64 := true
