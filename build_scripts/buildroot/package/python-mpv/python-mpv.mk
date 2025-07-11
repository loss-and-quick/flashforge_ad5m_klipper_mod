################################################################################
#
# python-mpv
#
################################################################################

PYTHON_MPV_VERSION = 1.0.8
PYTHON_MPV_SOURCE = python_mpv-$(PYTHON_MPV_VERSION).tar.gz
PYTHON_MPV_SITE = \
    https://files.pythonhosted.org/packages/source/p/python_mpv
PYTHON_MPV_SETUP_TYPE = setuptools
PYTHON_MPV_LICENSE = MIT
PYTHON_MPV_LICENSE_FILES = LICENSE
PYTHON_MPV_DEPENDENCIES = mpv

$(eval $(python-package))