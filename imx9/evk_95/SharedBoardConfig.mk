# -------@block_kernel_bootimg-------
KERNEL_NAME := Image.lz4
TARGET_KERNEL_ARCH := arm64
LOADABLE_KERNEL_MODULE ?= false

#NXP 8997 wifi driver module
BOARD_VENDOR_KERNEL_MODULES += \
    $(TARGET_OUT_INTERMEDIATES)/MXMWIFI_OBJ/mlan.ko \
    $(TARGET_OUT_INTERMEDIATES)/MXMWIFI_OBJ/moal.ko

# -------@block_memory-------
#Enable this to config 1GB ddr on evk_95
LOW_MEMORY := false

# -------@block_security-------
#Enable this to include trusty support
PRODUCT_IMX_TRUSTY := true

# -------@block_storage-------
# the bootloader image used in dual-bootloader OTA
#BOARD_OTA_BOOTLOADERIMAGE := bootloader-imx8mp-trusty-dual.img
