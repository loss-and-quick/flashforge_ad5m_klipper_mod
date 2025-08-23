################################################################################
#
# moonraker-telegram-bot
#
################################################################################

MOONRAKER_TELEGRAM_BOT_VERSION = 2.1.0
MOONRAKER_TELEGRAM_BOT_SITE = $(call github,nlef,moonraker-telegram-bot,v$(MOONRAKER_TELEGRAM_BOT_VERSION))
MOONRAKER_TELEGRAM_BOT_LICENSE = CC0-1.0
MOONRAKER_TELEGRAM_BOT_LICENSE_FILES = LICENSE

define MOONRAKER_TELEGRAM_BOT_INSTALL_TARGET_CMDS
    mkdir -p $(TARGET_DIR)/opt/moonraker-telegram-bot
	cp -a $(@D)/bot $(TARGET_DIR)/opt/moonraker-telegram-bot/

	$(INSTALL) -m 0644 $(@D)/README.md $(@D)/LICENSE  $(TARGET_DIR)/opt/moonraker-telegram-bot/
endef

$(eval $(generic-package))
