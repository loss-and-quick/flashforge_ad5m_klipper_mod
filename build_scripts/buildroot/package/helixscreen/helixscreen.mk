################################################################################
#
# helixscreen
#
################################################################################

HELIXSCREEN_VERSION = v1.0.10
HELIXSCREEN_SITE = https://github.com/prestonbrown/helixscreen.git
HELIXSCREEN_SITE_METHOD = git
HELIXSCREEN_GIT_SUBMODULES = yes
HELIXSCREEN_LICENSE = GPL-3.0-or-later
HELIXSCREEN_LICENSE_FILES = LICENSE

HELIXSCREEN_DEPENDENCIES = moonraker

define HELIXSCREEN_BUILD_CMDS
	$(TARGET_MAKE_ENV) $(MAKE) $(TARGET_CONFIGURE_OPTS) -C $(@D) PLATFORM_TARGET=ad5m-br HELIX_PACKAGING=1
endef

define HELIXSCREEN_INSTALL_TARGET_CMDS
	mkdir -p $(TARGET_DIR)/opt/helixscreen
	$(INSTALL) -D -m 0755 $(@D)/build/ad5m-br/bin/helix-screen $(TARGET_DIR)/opt/helixscreen/helix-screen
endef

$(eval $(generic-package))
