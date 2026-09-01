# $NetBSD$

DISTNAME=	xwpe-1.6.9
CATEGORIES=	editors
MASTER_SITES=	${MASTER_SITE_CODEBERG:=mendezr/xwpe/releases/download/v${PKGVERSION_NOREV}/}

MAINTAINER=	vins@NetBSD.org
HOMEPAGE=	https://codeberg.org/mendezr/xwpe
COMMENT=	Programming environment for UNIX systems
LICENSE=	gnu-gpl-v2

GNU_CONFIGURE=		yes
USE_TOOLS+=		pkg-config

# configure defaults both of these to "auto", so what gets built depends on
# what happens to be installed on the build host.  Pin them, or the PLIST
# stops matching.
CONFIGURE_ARGS+=	--without-wayland
CONFIGURE_ARGS+=	--without-gpm

# The install-data-hook also renders PNG icons from the SVG when
# rsvg-convert is available.  Nothing here depends on librsvg, so it does
# not run, but adding such a dependency would change the PLIST silently.

BUILDLINK_DEPMETHOD.libXt?=	build

.include "../../sysutils/desktop-file-utils/desktopdb.mk"
.include "../../graphics/hicolor-icon-theme/buildlink3.mk"
.include "../../textproc/json-c/buildlink3.mk"
.include "../../x11/libSM/buildlink3.mk"
.include "../../x11/libX11/buildlink3.mk"
.include "../../x11/libXt/buildlink3.mk"
.include "../../devel/zlib/buildlink3.mk"

# configure requires wide-character curses (it looks for get_wch) and stops
# without it.  mk/curses.buildlink3.mk says a package that genuinely needs
# ncurses should include its buildlink3.mk directly, so do that.
.include "../../devel/ncurses/buildlink3.mk"
.include "../../mk/bsd.pkg.mk"
