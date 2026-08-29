# $NetBSD$

PKGNAME=	${DISTNAME:S/mozc-/mozc-server-/}

INSTALLATION_DIRS+=	libexec

.include "../../inputmethod/mozc-server333/options.mk"

# No GUI is built here, so Qt is not needed.
MOZC_GYP_ARGS=	--noqt

post-configure:
	cd ${WRKSRC}/dist && \
		unzip -o -d ../dictionary jigyosyo.zip && \
		unzip -o -d ../dictionary ken_all.zip

.if empty(PKG_OPTIONS:Mgyp)
do-build:
	cd ${WRKSRC} && ${SETENV} ${MAKE_ENV} \
		${PREFIX}/bin/bazel \
			--output_user_root=${WRKDIR}/bazel \
			--client_debug \
			build \
			server:mozc_server \
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
	${INSTALL_PROGRAM} ${WRKSRC}/bazel-out/${OSDEST}/bin/server/mozc_server \
		${DESTDIR}${PREFIX}/libexec/mozc_server
.else
do-build:
	cd ${WRKSRC} && ${SETENV} ${MAKE_ENV} \
		${PYTHONBIN} build_mozc.py build -c ${MOZC_BUILD_MODE} \
			--jobs=${MAKE_JOBS:U1} \
			server/server.gyp:mozc_server

do-install:
	${INSTALL_PROGRAM} ${WRKSRC}/out_${OSDEST}/${MOZC_BUILD_MODE}/mozc_server \
		${DESTDIR}${PREFIX}/libexec/mozc_server
.endif

.include "Makefile.common"
.include "../../mk/bsd.pkg.mk"
