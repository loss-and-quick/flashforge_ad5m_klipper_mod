################################################################################
#
# python-zstandard
#
################################################################################

PYTHON_ZSTANDARD_VERSION = ed3d9821bb3a9430ff574d1a2636d40612f6783f
PYTHON_ZSTANDARD_SITE = $(call github,indygreg,python-zstandard,$(PYTHON_ZSTANDARD_VERSION))
PYTHON_ZSTANDARD_LICENSE = BSD
PYTHON_ZSTANDARD_LICENSE_FILES = LICENSE
PYTHON_ZSTANDARD_SETUP_TYPE = setuptools
PYTHON_ZSTANDARD_DEPENDENCIES = \
	host-python-cffi \
	host-python-setuptools-scm

$(eval $(python-package))