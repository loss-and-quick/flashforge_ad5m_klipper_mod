################################################################################
#
# python-ldap3
#
################################################################################

PYTHON_LDAP3_VERSION = 2.9.1
PYTHON_LDAP3_SOURCE = ldap3-$(PYTHON_LDAP3_VERSION).tar.gz
PYTHON_LDAP3_SITE = https://files.pythonhosted.org/packages/source/l/ldap3
PYTHON_LDAP3_SETUP_TYPE = setuptools
PYTHON_LDAP3_LICENSE = LGPL-3.0-or-later
PYTHON_LDAP3_LICENSE_FILES = LICENSE.txt COPYING.txt COPYING.LESSER.txt

PYTHON_LDAP3_DEPENDENCIES = \
	python-pyasn1 \
	python-pycryptodomex

$(eval $(python-package))