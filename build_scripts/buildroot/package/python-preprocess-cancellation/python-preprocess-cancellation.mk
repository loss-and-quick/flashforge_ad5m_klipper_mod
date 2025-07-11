################################################################################
#
# python-preprocess-cancellation
#
################################################################################

PYTHON_PREPROCESS_CANCELLATION_VERSION = 0.2.1
PYTHON_PREPROCESS_CANCELLATION_SOURCE = preprocess_cancellation-$(PYTHON_PREPROCESS_CANCELLATION_VERSION).tar.gz
PYTHON_PREPROCESS_CANCELLATION_SITE = \
    https://files.pythonhosted.org/packages/source/p/preprocess-cancellation
PYTHON_PREPROCESS_CANCELLATION_SETUP_TYPE = setuptools
PYTHON_PREPROCESS_CANCELLATION_LICENSE = MIT
PYTHON_PREPROCESS_CANCELLATION_LICENSE_FILES = LICENSE

$(eval $(python-package))