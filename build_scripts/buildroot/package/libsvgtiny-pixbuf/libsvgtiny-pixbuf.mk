################################################################################
#
# libsvgtiny-pixbuf
#
################################################################################

LIBSVGTINY_PIXBUF_VERSION = 0.0.2
LIBSVGTINY_PIXBUF_SITE = https://michael.orlitzky.com/code/releases
LIBSVGTINY_PIXBUF_SOURCE = libsvgtiny-pixbuf-$(LIBSVGTINY_PIXBUF_VERSION).tar.xz
LIBSVGTINY_PIXBUF_LICENSE = AGPL
LIBSVGTINY_PIXBUF_LICENSE_FILES = LICENSE

LIBSVGTINY_PIXBUF_DEPENDENCIES = libsvgtiny cairo libxml2 gdk-pixbuf host-libsvgtiny-pixbuf

HOST_LIBSVGTINY_PIXBUF_DEPENDENCIES = host-libsvgtiny host-cairo host-libxml2 host-gdk-pixbuf

ifeq ($(BR2_STATIC_LIBS),)
define LIBSVGTINY_PIXBUF_UPDATE_CACHE
    $(SED) '/^"\/usr\/lib\/gdk-pixbuf-2.0\/2.10.0\/loaders\/libpixbufloader-libsvgtiny\.so"/,/^$$/d' \
            $(TARGET_DIR)/usr/lib/gdk-pixbuf-2.0/2.10.0/loaders.cache
	GDK_PIXBUF_MODULEDIR=$(HOST_DIR)/lib/gdk-pixbuf-2.0/2.10.0/loaders \
		$(HOST_DIR)/bin/gdk-pixbuf-query-loaders | \
		sed 's,^"lib,"/usr/lib,g' | \
		sed -n  '/^"\/usr\/lib\/gdk-pixbuf-2.0\/2.10.0\/loaders\/libpixbufloader-libsvgtiny\.so"/,/^$$/p' \
		>> $(TARGET_DIR)/usr/lib/gdk-pixbuf-2.0/2.10.0/loaders.cache
endef
LIBSVGTINY_PIXBUF_POST_INSTALL_TARGET_HOOKS += LIBSVGTINY_PIXBUF_UPDATE_CACHE
endif


$(eval $(autotools-package))
$(eval $(host-autotools-package))
