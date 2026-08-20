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

# 1.6.x は autoconf/automake で組む。1.5.30a の手書き Makefile.in が
# DESTDIR を bindir の意味で使っていたのを patch-aa が直していたが、
# automake が正しく扱うので当て物ごと不要になった。

# wayland と gpm は configure の既定が auto で、箱に在れば拾う。入るものが
# 環境で変わると PLIST が合わなくなるので、どちらも明示的に切る。
CONFIGURE_ARGS+=	--without-wayland
CONFIGURE_ARGS+=	--without-gpm

# 上流の install-data-hook は rsvg-convert が在れば SVG から PNG も作る。
# pkgsrc は librsvg を引いていないので走らないが、依存が増えたときに黙って
# PLIST が変わる。要るときは PLIST ごと足すこと。

BUILDLINK_DEPMETHOD.libXt?=	build

.include "../../sysutils/desktop-file-utils/desktopdb.mk"
.include "../../graphics/hicolor-icon-theme/buildlink3.mk"
.include "../../textproc/json-c/buildlink3.mk"
.include "../../x11/libSM/buildlink3.mk"
.include "../../x11/libX11/buildlink3.mk"
.include "../../x11/libXt/buildlink3.mk"
.include "../../devel/zlib/buildlink3.mk"

# 1.6.x は広い文字の curses を要求する。configure が get_wch を探して
# 無ければ止まる。mk/curses.buildlink3.mk は「genuinely requires ncurses
# なら直接 buildlink3.mk を読め」と書いているので、そちらに従う。
# pkgsrc の devel/ncurses は --enable-widec で組まれていて、configure が
# 探しにいく ncurses.pc をそこが持っている。
.include "../../devel/ncurses/buildlink3.mk"
.include "../../mk/bsd.pkg.mk"
