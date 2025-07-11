################################################################################
#
# python-pywavelets
#
################################################################################

PYTHON_PYWAVELETS_VERSION = 1.8.0
PYTHON_PYWAVELETS_SITE = $(call github,PyWavelets,pywt,v$(PYTHON_PYWAVELETS_VERSION))
PYTHON_PYWAVELETS_LICENSE = MIT
PYTHON_PYWAVELETS_LICENSE_FILES = LICENSE

PYTHON_PYWAVELETS_DEPENDENCIES = \
	python-numpy \
	host-python-numpy \
	host-python-cython \
	host-python-meson-python

PYTHON_PYWAVELETS_CONF_ENV += \
	_PYTHON_SYSCONFIGDATA_NAME=$(PKG_PYTHON_SYSCONFIGDATA_NAME) \
	PYTHONPATH=$(PYTHON3_PATH)
	
PYTHON_PYWAVELETS_MESON_EXTRA_PROPERTIES = \
	numpy-include-dir='$(STAGING_DIR)/usr/lib/python$(PYTHON3_VERSION_MAJOR)/site-packages/numpy/core/include'

$(eval $(meson-package))