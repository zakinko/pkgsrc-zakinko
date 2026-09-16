# $NetBSD$

DISTNAME=	NetworkManager-1.50.0
CATEGORIES=	zakinko sysutils net
MASTER_SITES=	https://gitlab.freedesktop.org/NetworkManager/NetworkManager/-/archive/1.50.0/
EXTRACT_SUFX=	.tar.bz2

MAINTAINER=	cirnatdan@NetBSD.org
HOMEPAGE=	https://networkmanager.dev/
COMMENT=	Network configuration and connection manager
LICENSE=	gnu-gpl-v2

# NetworkManager has one platform backend, src/libnm-platform/nm-linux-platform.c,
# and reaches the kernel over netlink; there is no __NetBSD__, __FreeBSD__ or
# __OpenBSD__ anywhere in the tree.  sysutils/libudev below is eudev, itself
# marked BROKEN_EXCEPT_ON_PLATFORM= Linux-*-*, so the build stops at the
# dependency rather than at a compile error.  Say so here instead.
ONLY_FOR_PLATFORM=	Linux-*-*

# gdbus-codegen を宣言しないと、mk/tools/gdbus-codegen.mk が
# TOOLS_FAIL に入れて、わざと壊れた gdbus-codegen を tools へ置く。
# gio-2.0 の pkg-config は在処を答えるので meson はそれを拾い、
#   Program /usr/pkg/bin/gdbus-codegen found: NO
#   ERROR: Dependency 'gio-2.0' tool variable 'gdbus_codegen' contains
#          erroneous value
# で configure が止まる。実体は devel/gdbus-codegen にある。
USE_TOOLS+=		pkg-config perl gdbus-codegen
USE_PKGLOCALEDIR=	yes
USE_LANGUAGES=		c c++

PKGCONFIG_OVERRIDE+=	src/libnm-client-impl/libnm.pc.in

CHECK_PORTABILITY_SKIP+=	contrib/scripts/checkpatch-git-post-commit-hook
CHECK_PORTABILITY_SKIP+=	contrib/scripts/code-style-git-post-commit-hook

MESON_ARGS+=	-Dsystemdsystemunitdir=no
MESON_ARGS+=	-Dsystemd_journal=false
MESON_ARGS+=	-Dsession_tracking=no
MESON_ARGS+=	-Dselinux=false
MESON_ARGS+=	-Dlibaudit=no
MESON_ARGS+=	-Dcrypto=null
MESON_ARGS+=	-Dppp=false
MESON_ARGS+=	-Dmodem_manager=false
MESON_ARGS+=	-Dovs=false
MESON_ARGS+=	-Dlibpsl=false
MESON_ARGS+=	-Dconcheck=false
MESON_ARGS+=	-Dnmcli=false
MESON_ARGS+=	-Dnmtui=false
MESON_ARGS+=	-Dnm_cloud_setup=false

.include "../../devel/meson/build.mk"
.include "../../devel/libuuid/buildlink3.mk"
.include "../../sysutils/libudev/buildlink3.mk"
.include "../../sysutils/dbus/buildlink3.mk"
.include "../../zakinko/libndp/buildlink3.mk"
.include "../../devel/glib2/buildlink3.mk"
.include "../../devel/gobject-introspection/buildlink3.mk"
.include "../../security/polkit/buildlink3.mk"
.include "../../mk/bsd.pkg.mk"
