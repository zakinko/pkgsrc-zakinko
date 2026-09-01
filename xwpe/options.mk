# $NetBSD$

PKG_OPTIONS_VAR=	PKG_OPTIONS.xwpe
PKG_SUPPORTED_OPTIONS=	x11 xft
PKG_SUGGESTED_OPTIONS=	x11 xft

.include "../../mk/bsd.options.mk"

PLIST_SRC+=		PLIST

# Without X, install-exec-hook does not make the two X-named symlinks, so
# they cannot stay in the base PLIST:
#
#   pkg_create: can't stat .../bin/xwe
#   pkg_create: can't stat .../bin/xwpe
#
# bin/we and bin/wpe are made either way, and so are the four man pages,
# the desktop file, the icon and the metainfo.
.if !empty(PKG_OPTIONS:Mx11)
PLIST_SRC+=		PLIST.x11
BUILDLINK_DEPMETHOD.libXt?=	build
.include "../../x11/libSM/buildlink3.mk"
.include "../../x11/libX11/buildlink3.mk"
.include "../../x11/libXt/buildlink3.mk"
.else
CONFIGURE_ARGS+=	--without-x
.endif

# Xft is optional, as configure says, but the tree as shipped does not
# compile without it: we_debug.c and we_xterm.c reach into
# WpeXInfo.backbuf, which WeXterm.h declares only inside #ifdef HAVE_XFT,
# at four sites no #ifdef covers.  patch-we__debug.c and patch-we__xterm.c
# guard those, so both ways build.  Reported upstream.
#
# Xft needs X: configure only looks for it when have_x11 is yes, so
# without x11 this option cannot do anything.
.if !empty(PKG_OPTIONS:Mxft) && !empty(PKG_OPTIONS:Mx11)
.include "../../x11/libXft/buildlink3.mk"
.endif
