################################################################################
#
# python-pre-commit
#
################################################################################

PYTHON_PRE_COMMIT_VERSION = 4.2.0
PYTHON_PRE_COMMIT_SOURCE = pre_commit-$(PYTHON_PRE_COMMIT_VERSION).tar.gz
PYTHON_PRE_COMMIT_SITE = \
   https://files.pythonhosted.org/packages/source/p/pre_commit
PYTHON_PRE_COMMIT_SETUP_TYPE = setuptools
PYTHON_PRE_COMMIT_LICENSE = MIT
PYTHON_PRE_COMMIT_LICENSE_FILES = LICENSE

PYTHON_PRE_COMMIT_DEPENDENCIES = git

$(eval $(python-package))