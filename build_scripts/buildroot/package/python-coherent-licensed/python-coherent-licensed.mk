################################################################################
#
# python-coherent-licensed
#
################################################################################

PYTHON_COHERENT_LICENSED_VERSION = 0.5.2
PYTHON_COHERENT_LICENSED_SOURCE = coherent_licensed-$(PYTHON_COHERENT_LICENSED_VERSION).tar.gz
PYTHON_COHERENT_LICENSED_SITE = https://files.pythonhosted.org/packages/source/c/coherent_licensed
PYTHON_COHERENT_LICENSED_SETUP_TYPE = flit
HOST_PYTHON_COHERENT_LICENSED_SETUP_TYPE = flit
PYTHON_COHERENT_LICENSED_LICENSE = MIT
PYTHON_COHERENT_LICENSED_LICENSE_FILES = LICENSE 

$(eval $(host-python-package))