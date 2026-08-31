################################################################################
#
# moonraker-telegram-bot
#
################################################################################

MOONRAKER_TELEGRAM_BOT_VERSION = 10ee7caa412f4affb3f69d858a4102efa31c1697
MOONRAKER_TELEGRAM_BOT_SITE = https://github.com/nlef/moonraker-telegram-bot.git
MOONRAKER_TELEGRAM_BOT_SITE_METHOD = git
MOONRAKER_TELEGRAM_BOT_LICENSE = CC0-1.0
MOONRAKER_TELEGRAM_BOT_LICENSE_FILES = LICENSE

MOONRAKER_TELEGRAM_BOT_DEPENDENCIES = \
	python-aiofiles \
	python-aiolimiter \
	python-anyio \
	python-apscheduler \
	python-certifi \
	python-emoji \
	python-ffmpegcv \
	python-h11 \
	python-h2 \
	python-hpack \
	python-httpcore \
	python-httpx \
	python-hyperframe \
	python-idna \
	python-orjson \
	python-pillow \
	python-telegram-bot \
	python-socksio \
	python-cachetools \
	python-tzlocal \
	python-uvloop \
	python-websockets

define MOONRAKER_TELEGRAM_BOT_INSTALL_TARGET_CMDS
    mkdir -p $(TARGET_DIR)/opt/moonraker-telegram-bot
	cp -a $(@D)/bot $(TARGET_DIR)/opt/moonraker-telegram-bot/

	$(INSTALL) -m 0644 $(@D)/README.md $(@D)/LICENSE  $(TARGET_DIR)/opt/moonraker-telegram-bot/

	# Python ssl module looks for /etc/ssl/cert.pem by default
	ln -fs /etc/ssl/certs/ca-certificates.crt $(TARGET_DIR)/etc/ssl/cert.pem
endef

$(eval $(generic-package))
