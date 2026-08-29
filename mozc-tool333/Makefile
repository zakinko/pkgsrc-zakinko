# $NetBSD$

PKGNAME=	${DISTNAME:S/mozc-/mozc-tool-/}

INSTALLATION_DIRS+=	libexec

DEPENDS+=	mozc-server-${PKGVERSION_NOREV}{,nb*}:../../inputmethod/mozc-server333

# This builds with GYP as well: gui.gyp defines mozc_tool outside any
# conditions block, so all it takes is letting the build find Qt
# (patch-gui_qt__libraries.gypi and patch-gui_qt__tool__dir.gypi).  That is
# what makes it different from mozc-renderer.
.include "../../inputmethod/mozc-server333/options.mk"

.if empty(PKG_OPTIONS:Mgyp)
do-build:
	cd ${WRKSRC} && ${SETENV} ${MAKE_ENV} \
		${PREFIX}/bin/bazel \
			--output_user_root=${WRKDIR}/bazel \
			--client_debug \
			build \
			gui/tool:mozc_tool \
			--jobs=${MAKE_JOBS:U1} \
			--host_action_env=CWRAPPERS_CONFIG_DIR=${CWRAPPERS_CONFIG_DIR} \
			--action_env=CWRAPPERS_CONFIG_DIR=${CWRAPPERS_CONFIG_DIR} \
			--host_action_env=PATH=${PATH} \
			--action_env=PATH=${PATH} \
			--sandbox_debug \
			--verbose_failures \
			--subcommands \
			${BAZEL_ARGS} \
			--config oss_linux --config release_build

do-install:
	${INSTALL_PROGRAM} ${WRKSRC}/bazel-out/${OSDEST}/bin/gui/tool/mozc_tool \
		${DESTDIR}${PREFIX}/libexec
.else
do-build:
	cd ${WRKSRC} && ${SETENV} ${MAKE_ENV} \
		${PYTHONBIN} build_mozc.py build -c ${MOZC_BUILD_MODE} \
			--jobs=${MAKE_JOBS:U1} \
			gui/gui.gyp:mozc_tool

do-install:
	${INSTALL_PROGRAM} ${WRKSRC}/out_${OSDEST}/${MOZC_BUILD_MODE}/mozc_tool \
		${DESTDIR}${PREFIX}/libexec
.endif

.include "../../inputmethod/mozc-server333/Makefile.common"
.include "../../mk/bsd.pkg.mk"
