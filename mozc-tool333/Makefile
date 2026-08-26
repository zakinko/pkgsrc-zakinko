# $NetBSD$

PKGNAME=	${DISTNAME:S/mozc-/mozc-tool-/}

INSTALLATION_DIRS+=	libexec

DEPENDS+=	mozc-server-${PKGVERSION_NOREV}{,nb*}:../../zakinko/mozc-server333

# gyp でも建つ。gui/gui.gyp の mozc_tool は conditions の外に在り、Qt を
# 見つけさせるだけでよい (patch-gui_qt__libraries.gypi と
# patch-gui_qt__tool__dir.gypi)。mozc-renderer と違うのはそこである。
.include "../../zakinko/mozc-server333/options.mk"

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
			gui/gui.gyp:mozc_tool

do-install:
	${INSTALL_PROGRAM} ${WRKSRC}/out_${OSDEST}/${MOZC_BUILD_MODE}/mozc_tool \
		${DESTDIR}${PREFIX}/libexec
.endif

.include "../../zakinko/mozc-server333/Makefile.common"
.include "../../mk/bsd.pkg.mk"
