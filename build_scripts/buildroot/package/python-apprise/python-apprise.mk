################################################################################
#
# python-apprise
#
################################################################################

PYTHON_APPRISE_VERSION = 1.9.2
PYTHON_APPRISE_SOURCE = apprise-$(PYTHON_APPRISE_VERSION).tar.gz
PYTHON_APPRISE_SITE = \
    https://files.pythonhosted.org/packages/source/a/apprise
PYTHON_APPRISE_SETUP_TYPE = setuptools
PYTHON_APPRISE_DEPENDENCIES = host-python-babel
PYTHON_APPRISE_LICENSE = BSD-3-Clause
PYTHON_APPRISE_LICENSE_FILES = LICENSE

$(eval $(python-package))