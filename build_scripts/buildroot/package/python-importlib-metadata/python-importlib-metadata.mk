################################################################################
#
# python-importlib-metadata
#
################################################################################

PYTHON_IMPORTLIB_METADATA_VERSION = 8.7.0
PYTHON_IMPORTLIB_METADATA_SOURCE = importlib_metadata-$(PYTHON_IMPORTLIB_METADATA_VERSION).tar.gz
PYTHON_IMPORTLIB_METADATA_SITE = https://pypi.org/packages/source/i/importlib_metadata
PYTHON_IMPORTLIB_METADATA_SETUP_TYPE = setuptools
PYTHON_IMPORTLIB_METADATA_LICENSE = Apache-2.0
PYTHON_IMPORTLIB_METADATA_LICENSE_FILES = LICENSE

PYTHON_IMPORTLIB_METADATA_DEPENDENCIES = python-zipp
	
HOST_PYTHON_IMPORTLIB_METADATA_DEPENDENCIES = \
    host-python-setuptools-scm \
	host-python-coherent-licensed


$(eval $(python-package))