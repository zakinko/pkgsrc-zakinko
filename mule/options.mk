# $NetBSD: options.mk,v 1.1 2005/12/01 17:34:41 wiz Exp $

PKG_OPTIONS_VAR=	PKG_OPTIONS.mule
PKG_SUPPORTED_OPTIONS=	canna wnn4 x11
PKG_SUGGESTED_OPTIONS=	canna wnn4 x11

.include "../../mk/bsd.options.mk"

.if !empty(PKG_OPTIONS:Mwnn4)
.include "../../inputmethod/ja-freewnn-lib/buildlink3.mk"
CONFIGURE_ARGS+=	--with-wnn4
CONFIGURE_ARGS+=	--wnn-includes=${BUILDLINK_PREFIX.ja-FreeWnn-lib}/include/wnn
CONFIGURE_ARGS+=	--wnn-libraries=${BUILDLINK_PREFIX.ja-FreeWnn-lib}/lib
.endif

.if !empty(PKG_OPTIONS:Mcanna)
.include "../../inputmethod/canna-lib/buildlink3.mk"
CONFIGURE_ARGS+=	--canna
CONFIGURE_ARGS+=	--canna-includes=${BUILDLINK_PREFIX.Canna-lib}/include
CONFIGURE_ARGS+=	--canna-libraries=${BUILDLINK_PREFIX.Canna-lib}/lib
.endif

# The X build pulls in the bundled Lucid toolkit and oldXMenu, which are
# the least portable part of this tree.  Both arms build and dump on
# NetBSD 9.4/i386, verified against a real X server.  On LP64 be warier:
# the last time anyone reported trying (tsutsui, 2017, NetBSD/amd64 7.1)
# `mule -nw' came up but the Xt build still dumped core.  Turning this
# option off gives a terminal-only mule and drops the X dependencies.
.if !empty(PKG_OPTIONS:Mx11)
.include "../../x11/xbitmaps/buildlink3.mk"
.include "../../x11/libXaw/buildlink3.mk"
CONFIGURE_ARGS+=	--with-x --with-x-toolkit=lucid
CONFIGURE_ARGS+=	--bdf-path=${PREFIX}/share/fonts/X11/intlfonts/bdf
.else
CONFIGURE_ARGS+=	--with-x=no
.endif
