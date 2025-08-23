################################################################################
#
# katapult
#
################################################################################

KATAPULT_VERSION = 399e50e1210062a297dfb93c836731de150cbdc6
KATAPULT_SITE = https://github.com/Arksine/katapult.git
KATAPULT_SITE_METHOD = git

KATAPULT_LICENSE = GPL-3.0
KATAPULT_LICENSE_FILES = LICENSE

KLIPPER_DEPENDENCIES = \
	python3 \
	python-serial \
	python-can

ifneq ($(BR2_PACKAGE_KATAPULT_CONFIGS),)
KATAPULT_DEPENDENCIES += host-arm-gnu-toolchain host-python3
KATAPULT_MCU_CONFIGS_LIST = $(call qstrip,$(BR2_PACKAGE_KATAPULT_CONFIGS))
endif


define KATAPULT_BUILD_MCU_FIRMWARES
	printf "%s-%s\n" \
      "$(KATAPULT_VERSION)" "Buildroot" \
      > $(@D)/.version
	$(if $(KATAPULT_MCU_CONFIGS_LIST),
		$(foreach config,$(KATAPULT_MCU_CONFIGS_LIST),
			$(call KATAPULT_BUILD_MCU_FIRMWARE,$(config))
		)
	)
endef

define KATAPULT_BUILD_MCU_FIRMWARE
	rm -rf $(@D)/out
	cp $(1) $(@D)/.config
	$(HOST_MAKE_ENV) $(MAKE) -C $(@D) \
		CROSS_PREFIX=$(HOST_DIR)/bin/arm-none-eabi- \
		olddefconfig
	$(HOST_MAKE_ENV) $(MAKE) -C $(@D) \
		CROSS_PREFIX=$(HOST_DIR)/bin/arm-none-eabi-

	mkdir -p $(TARGET_DIR)/opt/katapult/scripts
	cp $(@D)/scripts/{flashtool.py,flash_can.py} $(TARGET_DIR)/opt/katapult/scripts

	cp -f $(@D)/out/katapult.bin $(TARGET_DIR)/opt/katapult/$(notdir $(basename $(1))).bin
	cp -f $(@D)/out/katapult.elf $(TARGET_DIR)/opt/katapult/$(notdir $(basename $(1))).elf
endef

ifneq ($(KATAPULT_MCU_CONFIGS_LIST),)
KATAPULT_POST_BUILD_HOOKS += KATAPULT_BUILD_MCU_FIRMWARES
endif

$(eval $(generic-package))