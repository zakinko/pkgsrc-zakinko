# $NetBSD$

PKG_OPTIONS_VAR=	PKG_OPTIONS.mule2
PKG_SUPPORTED_OPTIONS=	canna wnn4 x11
PKG_SUGGESTED_OPTIONS=	canna wnn4 x11

.include "../../mk/bsd.options.mk"

PLIST_VARS+=	wnn4

.if !empty(PKG_OPTIONS:Mwnn4)
PLIST.wnn4=		yes
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

# Without this option mule is built for the terminal only, which drops
# the bundled Lucid toolkit and oldXMenu along with the X dependencies.
.if !empty(PKG_OPTIONS:Mx11)
.include "../../x11/xbitmaps/buildlink3.mk"
.include "../../x11/libXaw/buildlink3.mk"
CONFIGURE_ARGS+=	--with-x --with-x-toolkit=lucid
CONFIGURE_ARGS+=	--bdf-path=${PREFIX}/share/fonts/X11/intlfonts/bdf
.else
CONFIGURE_ARGS+=	--with-x=no
.endif
