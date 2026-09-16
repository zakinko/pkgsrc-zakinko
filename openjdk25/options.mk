# $NetBSD$

PKG_OPTIONS_VAR=		PKG_OPTIONS.openjdk25
PKG_OPTIONS_OPTIONAL_GROUPS=	variant
PKG_OPTIONS_GROUP.variant=	jdk-hotspot-vm jdk-zero-vm
PKG_SUPPORTED_OPTIONS=		debug dtrace jre-jce x11 static-libstdcpp jdk-bundled-zlib
PKG_SUGGESTED_OPTIONS=		jre-jce x11 jdk-hotspot-vm

.include "../../mk/bsd.options.mk"

###
### Java(TM) Cryptography Extension (JCE)
###
.if !empty(PKG_OPTIONS:Mjre-jce)
CONFIGURE_ARGS+=	--enable-unlimited-crypto
.else
CONFIGURE_ARGS+=	--disable-unlimited-crypto
.endif

###
### X11 or headless build
###
# lang/openjdk21 asks "we apparently still need the Xlib headers and
# libraries to build headless. why?" and leaves it at that.  What is known:
# the openjdk21 binary pkgsrc distributes links against X even so, and
# pkg_add refuses it on a machine without the X sets --
#
#   missing required library: /usr/X11R7/lib/libX11.so.7
#
# On NetBSD that library is base X under X11BASE, so the buildlink files
# below resolve to the builtin and add no package dependency; the depmethods
# matter only where X comes from pkgsrc.  Whether a headless build could be
# made to drop X altogether has not been tried.
PLIST_VARS+=	x11
CONFIGURE_ARGS+=	--x-includes=${X11BASE}/include
CONFIGURE_ARGS+=	--x-libraries=${X11BASE}/lib
.if !empty(PKG_OPTIONS:Mx11)
PLIST.x11=	yes
CONFIGURE_ARGS+=	--disable-headless-only
DEPENDS+=		dejavu-ttf-[0-9]*:../../fonts/dejavu-ttf
.include "../../x11/libXi/buildlink3.mk"
.include "../../x11/libX11/buildlink3.mk"
.include "../../x11/libXext/buildlink3.mk"
BUILDLINK_DEPMETHOD.libXt?=	build
.include "../../x11/libXt/buildlink3.mk"
.include "../../x11/libXrender/buildlink3.mk"
.include "../../x11/libXtst/buildlink3.mk"
.include "../../x11/libXrandr/buildlink3.mk"
.else
CONFIGURE_ARGS+=	--enable-headless-only
BUILDLINK_DEPMETHOD.libX11?=	build
.include "../../x11/libX11/buildlink3.mk"
BUILDLINK_DEPMETHOD.libXext?=	build
.include "../../x11/libXext/buildlink3.mk"
BUILDLINK_DEPMETHOD.libXt?=	build
.include "../../x11/libXt/buildlink3.mk"
BUILDLINK_DEPMETHOD.libXrender?=build
.include "../../x11/libXrender/buildlink3.mk"
BUILDLINK_DEPMETHOD.libXtst?=	build
.include "../../x11/libXtst/buildlink3.mk"
BUILDLINK_DEPMETHOD.libXrandr?=	build
.include "../../x11/libXrandr/buildlink3.mk"
.endif

#
# Debugging
#
.if !empty(PKG_OPTIONS:Mdebug)
BUILD_DEBUG_LEVEL=	fastdebug
CONFIGURE_ARGS+=	--with-native-debug-symbols=external
CONFIGURE_ARGS+=	--enable-debug
PLIST_SUBST+=		DBGEXT=.debuginfo
.else
BUILD_DEBUG_LEVEL=	release
CONFIGURE_ARGS+=	--with-native-debug-symbols=zipped
PLIST_SUBST+=		DBGEXT=.diz
.endif

.if !empty(PKG_OPTIONS:Mdtrace)
CONFIGURE_ARGS+=	--enable-dtrace=yes
.else
CONFIGURE_ARGS+=	--enable-dtrace=no
.endif

#
# static libstdc++ and libgcc
#
# Linking libstdc++ into a shared library on NetBSD wants libstdc++_pic.a,
# which the compiler has no flag to select, and -static-libgcc does not work
# because libpthread needs libgcc dynamically.  So the option only removes
# the flag the JDK adds, and the default is to link both dynamically.
.if !empty(PKG_OPTIONS:Mstatic-libstdcpp)
.  if !empty(PKGSRC_COMPILER:Mgcc)
BUILDLINK_TRANSFORM+=	rm:-static-libgcc
.  endif
.else
CONFIGURE_ARGS+=	--with-stdc++lib=dynamic
.endif

#
# Build variant. Zero VM builds a portable JVM without assembly optimization.
#
PLIST_VARS+=		hotspot
.if !empty(PKG_OPTIONS:Mjdk-zero-vm)
BUILD_VARIANT=		zero
.include "../../devel/libffi/buildlink3.mk"
.else
BUILD_VARIANT=		server
PLIST.hotspot=		yes
.endif
CONFIGURE_ARGS+=	--with-jvm-variants=${BUILD_VARIANT}

PLIST_VARS+=		jdk_bundled_zlib
.if !empty(PKG_OPTIONS:Mjdk-bundled-zlib)
PLIST.jdk_bundled_zlib=	yes
CONFIGURE_ARGS+=	--with-zlib=bundled
.else
CONFIGURE_ARGS+=	--with-zlib=system
.include "../../devel/zlib/buildlink3.mk"
.endif
