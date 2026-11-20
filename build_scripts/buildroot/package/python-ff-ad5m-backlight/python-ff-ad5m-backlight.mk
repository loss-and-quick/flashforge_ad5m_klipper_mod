################################################################################
#
# python-ff-ad5m-backlight
#
################################################################################

PYTHON_FF_AD5M_BACKLIGHT_VERSION = c2031b588ed68ce5bdf2d69052838d91760eca1c
PYTHON_FF_AD5M_BACKLIGHT_SITE = https://github.com/loss-and-quick/flashforge_ad5m_backlight.git
PYTHON_FF_AD5M_BACKLIGHT_SITE_METHOD = git
PYTHON_FF_AD5M_BACKLIGHT_SETUP_TYPE = setuptools
PYTHON_FF_AD5M_BACKLIGHT_LICENSE = GPLv3
PYTHON_FF_AD5M_BACKLIGHT_LICENSE_FILES = LICENSE

$(eval $(python-package))
