LOCAL_PATH := $(call my-dir)

DTS_ADDITIONAL_PATH := compulab

include $(CONFIG_REPO_PATH)/common/build/dtbo.mk
include $(CONFIG_REPO_PATH)/common/build/imx-recovery.mk
include $(CONFIG_REPO_PATH)/common/build/gpt.mk
include $(FSL_PROPRIETARY_PATH)/fsl-proprietary/media-profile/media-profile.mk
include $(FSL_PROPRIETARY_PATH)/fsl-proprietary/sensor/fsl-sensor.mk
-include $(IMX_MEDIA_CODEC_XML_PATH)/mediacodec-profile/mediacodec-profile.mk

#BOARD_PACK_RADIOIMAGES += bootloader.img
#INSTALLED_RADIOIMAGE_TARGET  += $(PRODUCT_OUT)/bootloader.img
