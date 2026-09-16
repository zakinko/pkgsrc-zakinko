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
# FreeBSD は試している最中で、まだ通っていない。ここに並べてあるのは
# 「対応済み」の意味ではなく、CI に建てさせて最初に転ぶ場所を採るためである。
# 通ったらこの但し書きを消し、通らないと分かったら行ごと消すこと。
ONLY_FOR_PLATFORM+=	FreeBSD-*-*

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
# vapi の既定は auto で、周囲に vala が在るかどうかで中身が変わる。
# wip の PLIST は vala が在る環境で採られていて、無い箱では
#   share/vala/vapi/libnm.{deps,vapi}
# の二つが作られず file-check で食い違う。決まった物が出るよう false で固定し、
# PLIST からも外す。Vala の binding が要るようになったら、lang/vala を
# 依存に足したうえで true にして PLIST を採り直すこと。
MESON_ARGS+=	-Dvapi=false

.include "../../devel/meson/build.mk"
.include "../../devel/libuuid/buildlink3.mk"
# Linux の sysutils/libudev は eudev で、それ自身が
# BROKEN_EXCEPT_ON_PLATFORM= Linux-*-* である。BSD には devel/libudev-bsd が
# あって、NetBSD は ndevd、OpenBSD は KERN_AUTOCONF_SERIAL、Free と DragonFly は
# devd を使って同じ口を出す。
.include "../../mk/bsd.prefs.mk"
.if ${OPSYS} == "Linux"
.include "../../sysutils/libudev/buildlink3.mk"
.else
.include "../../devel/libudev-bsd/buildlink3.mk"
.endif
.include "../../sysutils/dbus/buildlink3.mk"
.include "../../zakinko/libndp/buildlink3.mk"
.include "../../devel/glib2/buildlink3.mk"
.include "../../devel/gobject-introspection/buildlink3.mk"
.include "../../security/polkit/buildlink3.mk"
# 上位の meson.build は
#   python = python_mod.find_installation('python3', required: false)
#   if python.found()
#     python_path = python.full_path()
#   endif
# と、python3 が見つかったときだけ python_path を定義する。ところが
# src/libnm-client-impl/meson.build:193 は doc 生成の枝でそれを無条件に使う。
# python3 が build 環境に無いと
#   ERROR: Unknown variable name "python_path"
# で configure が止まる (上流のガード漏れでもある)。tool として python を出す。
.include "../../lang/python/tool.mk"
.include "../../mk/bsd.pkg.mk"
