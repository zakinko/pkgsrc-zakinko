# $NetBSD$

PKGNAME=	${DISTNAME:S/mozc-/mozc-renderer-/}

INSTALLATION_DIRS+=	libexec share/icons

DEPENDS+=	xdg-utils-[0-9]*:../../misc/xdg-utils
DEPENDS+=	mozc-server-${PKGVERSION_NOREV}{,nb*}:../../inputmethod/mozc-server333

# Upstream's renderer/renderer.gyp defines mozc_renderer only inside the
# OS=="win" and OS=="mac" conditions.  The sources are all in renderer/qt/
# and renderer/qt/BUILD.bazel builds them, so what is missing is the target
# definition, not the code.  patch-renderer_renderer.gyp adds it; moc comes
# from gui/qt_moc.gypi and the Qt link from gui/qt_libraries.gypi.
#
# inputmethod/mozc-server226 carries the same kind of patch for the GTK
# candidate window.  Upstream dropped GTK in 3.33 and the Qt renderer took
# its place, so the same treatment is needed here.
.include "../../inputmethod/mozc-server333/options.mk"

.if empty(PKG_OPTIONS:Mgyp)
do-build:
	cd ${WRKSRC} && ${SETENV} ${MAKE_ENV} \
		${PREFIX}/bin/bazel \
			--output_user_root=${WRKDIR}/bazel \
			--client_debug \
			build \
			renderer/qt:mozc_renderer \
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

.include "../../inputmethod/mozc-server333/Makefile.common"
.include "../../mk/bsd.pkg.mk"
