# $NetBSD$

CONFLICTS+=	emacs28-nox11-[0-9]*

# CVS の最終値 47 に +1。Makefile.common の頭に書いたとおり、ここは動かさない。
PKGREVISION=	48

.include "../../zakinko/emacs28/Makefile.common"

.include "options.mk"

# Erroneously tries to enable inotify by default.
.if ${OPSYS} == "SunOS"
.  include "../../devel/glib2/buildlink3.mk"
CONFIGURE_ARGS+=	--with-file-notification=gfile
.endif

.include "../../graphics/hicolor-icon-theme/buildlink3.mk"
.include "../../sysutils/desktop-file-utils/desktopdb.mk"
.include "../../fonts/harfbuzz/buildlink3.mk"
.include "../../graphics/cairo/buildlink3.mk"
.include "../../mk/bsd.pkg.mk"
