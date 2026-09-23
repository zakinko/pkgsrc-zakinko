# $NetBSD$

PKGNAME=	${DISTNAME:S/mozc-/mozc-renderer-/}

INSTALLATION_DIRS+=	libexec share/icons

DEPENDS+=	xdg-utils-[0-9]*:../../misc/xdg-utils
DEPENDS+=	mozc-server-${PKGVERSION_NOREV}{,nb*}:../../inputmethod/mozc-server334

# Upstream's renderer/renderer.gyp defines mozc_renderer only inside the
# OS=="win" and OS=="mac" conditionals.  The sources are all there under
# renderer/qt/ and renderer/qt/BUILD.bazel builds them, so what is missing is
# the target definition, not the code; patch-renderer_renderer.gyp adds it.
# 3.34 has no GYP of its own, but post-extract in Makefile.common brings the
# scaffolding across from 3.33.6089.

# Qt6 QtGui reaches GL/gl.h through qopengl.h.  Without MesaLib among the
# dependencies, buildlink never shows GL to the compiler and the build stops
# at
#
#	renderer/qt/qt_ipc_thread.cc
#	qopengl.h:115:13: fatal error: GL/gl.h: No such file or directory
#
# The header is there, it is just not visible.  333, built with GYP, never hit
# this.  Handing Bazel a bare -I does not work -- it refuses paths outside the
# execution root -- so the include goes to cc_configure instead.  cc_configure
# reads the compiler search path while assembling the toolchain from
# BAZEL_CXXOPTS, so whatever lands there ends up in
# cxx_builtin_include_directories and is mounted into the sandbox as well.
# buildlink alone makes it visible to the compiler but not inside the sandbox.
.include "../../graphics/MesaLib/buildlink3.mk"

MAKE_ENV+=	BAZEL_CXXOPTS=-std=gnu++17:-I${PREFIX}/include:-I${X11BASE}/include
# Linking has the same hole: mozc's pkg_config_repository calls --libs-only-l
# and so collects only -l flags (on Linux Qt sits on the default path).  The
# pkgsrc Qt6 lives in /qt6/lib and buildlink passes -L through
# LDFLAGS, but Bazel throws the environment away with env - and cc_configure
# does not read LDFLAGS.  It reads BAZEL_LINKOPTS, so the paths are baked into
# the toolchain from there.
MAKE_ENV+=	BAZEL_LINKOPTS=-L${PREFIX}/qt6/lib:${COMPILER_RPATH_FLAG}${PREFIX}/qt6/lib:-L${PREFIX}/lib:${COMPILER_RPATH_FLAG}${PREFIX}/lib:-L${X11BASE}/lib:${COMPILER_RPATH_FLAG}${X11BASE}/lib

.include "../../inputmethod/mozc-server334/options.mk"

.if ${MOZC_BUILDER} == "bazel"
do-build:
	cd ${WRKSRC} && ${SETENV} ${MAKE_ENV} \
		${PREFIX}/bin/bazel \
			--output_user_root=${WRKDIR}/bazel \
			build \
			renderer/qt:mozc_renderer \
			--jobs=${MAKE_JOBS:U1} \
			--host_action_env=CWRAPPERS_CONFIG_DIR=${CWRAPPERS_CONFIG_DIR} \
			--action_env=CWRAPPERS_CONFIG_DIR=${CWRAPPERS_CONFIG_DIR} \
			--host_action_env=PATH=${PATH:Q} \
			--action_env=PATH=${PATH:Q} \
			--verbose_failures \
			${BAZEL_ARGS} \
			--config oss_linux --config release_build

do-install:
	${INSTALL_PROGRAM} ${WRKSRC}/bazel-out/${OSDEST}/bin/renderer/qt/mozc_renderer \
		${DESTDIR}${PREFIX}/libexec
.for f in ui-alpha_full ui-alpha_half ui-dictionary ui-direct \
	ui-hiragana ui-katakana_full ui-katakana_half ui-properties ui-tool
	${INSTALL_DATA} ${WRKSRC}/data/images/unix/${f}.png \
		${DESTDIR}${PREFIX}/share/icons/${f:S/^ui-/mozc-/}.png
.endfor
	${INSTALL_DATA} ${WRKSRC}/data/images/product_icon_32bpp-128.png \
		${DESTDIR}${PREFIX}/share/icons/mozc.png
.else
do-build:
	cd ${WRKSRC} && ${SETENV} ${MAKE_ENV} \
		${PYTHONBIN} build_mozc.py build -c ${MOZC_BUILD_MODE} \
			--jobs=${MAKE_JOBS:U1} \
			renderer/renderer.gyp:mozc_renderer

do-install:
	${INSTALL_PROGRAM} ${WRKSRC}/out_${OSDEST}/${MOZC_BUILD_MODE}/mozc_renderer \
		${DESTDIR}${PREFIX}/libexec
.for f in ui-alpha_full ui-alpha_half ui-dictionary ui-direct \
	ui-hiragana ui-katakana_full ui-katakana_half ui-properties ui-tool
	${INSTALL_DATA} ${WRKSRC}/data/images/unix/${f}.png \
		${DESTDIR}${PREFIX}/share/icons/${f:S/^ui-/mozc-/}.png
.endfor
	${INSTALL_DATA} ${WRKSRC}/data/images/product_icon_32bpp-128.png \
		${DESTDIR}${PREFIX}/share/icons/mozc.png
.endif

.include "../../inputmethod/mozc-server334/Makefile.common"
.include "../../mk/bsd.pkg.mk"
