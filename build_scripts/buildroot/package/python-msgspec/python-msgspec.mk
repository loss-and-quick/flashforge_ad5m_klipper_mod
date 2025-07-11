################################################################################
#
# python-msgspec
#
################################################################################

PYTHON_MSGSPEC_VERSION = 0.19.0
PYTHON_MSGSPEC_SOURCE = msgspec-$(PYTHON_MSGSPEC_VERSION).tar.gz
PYTHON_MSGSPEC_SITE = https://files.pythonhosted.org/packages/source/m/msgspec
PYTHON_MSGSPEC_SETUP_TYPE = setuptools
PYTHON_MSGSPEC_LICENSE = BSD-3-Clause
PYTHON_MSGSPEC_LICENSE_FILES = LICENSE

$(eval $(python-package))