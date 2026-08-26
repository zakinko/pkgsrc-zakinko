# $NetBSD$

PKGNAME=	${EMACS_PKGNAME_PREFIX}${DISTNAME:S/mozc-/mozc-elisp-/}
CATEGORIES=	inputmethod editors

# helper は自分では変換せず /usr/pkg/libexec/mozc_server に話しかけるだけで、
# client は server の版が違えば拒む (client.cc の CheckVersionOrRestartServer)。
DEPENDS+=	mozc-server-${PKGVERSION_NOREV}{,nb*}:../../zakinko/mozc-server333

.include "../../zakinko/mozc-server333/options.mk"

MOZC_GYP_ARGS=	--noqt

EMACS_MODULES=	base leim

.include "../../editors/emacs/modules.mk"

INSTALLATION_DIRS=	${EMACS_LISPPREFIX} bin

.if empty(PKG_OPTIONS:Mgyp)
do-build:
	cd ${WRKSRC} && ${SETENV} ${MAKE_ENV} \
		${PREFIX}/bin/bazel \
			--output_user_root=${WRKDIR}/bazel \
			--client_debug \
			build \
			unix/emacs:mozc_emacs_helper \
			--jobs=${MAKE_JOBS:U1} \
			--host_action_env=CWRAPPERS_CONFIG_DIR=${CWRAPPERS_CONFIG_DIR} \
			--action_env=CWRAPPERS_CONFIG_DIR=${CWRAPPERS_CONFIG_DIR} \
			--host_action_env=PATH=${PATH} \
			--action_env=PATH=${PATH} \
			--sandbox_debug \
			--verbose_failures \
			--subcommands \
			${BAZEL_ARGS} \
			--config oss_linux --config release_build && \
		${EMACS_BIN} --no-init-file --no-site-file -batch \
			-f batch-byte-compile ${WRKSRC}/unix/emacs/mozc.el

do-install:
	${INSTALL_PROGRAM} ${WRKSRC}/bazel-out/${OSDEST}/bin/unix/emacs/mozc_emacs_helper \
		${DESTDIR}${PREFIX}/bin
	${INSTALL_DATA} ${WRKSRC}/unix/emacs/mozc.el \
		${DESTDIR}${EMACS_LISPPREFIX}
	${INSTALL_DATA} ${WRKSRC}/unix/emacs/mozc.elc \
		${DESTDIR}${EMACS_LISPPREFIX}
.else
do-build:
	cd ${WRKSRC} && ${SETENV} ${MAKE_ENV} \
		${PYTHONBIN} build_mozc.py build -c ${MOZC_BUILD_MODE} \
			unix/emacs/emacs.gyp:mozc_emacs_helper && \
		${EMACS_BIN} --no-init-file --no-site-file -batch \
			-f batch-byte-compile ${WRKSRC}/unix/emacs/mozc.el

do-install:
	${INSTALL_PROGRAM} ${WRKSRC}/out_${OSDEST}/${MOZC_BUILD_MODE}/mozc_emacs_helper \
		${DESTDIR}${PREFIX}/bin
	${INSTALL_DATA} ${WRKSRC}/unix/emacs/mozc.el \
		${DESTDIR}${EMACS_LISPPREFIX}
	${INSTALL_DATA} ${WRKSRC}/unix/emacs/mozc.elc \
		${DESTDIR}${EMACS_LISPPREFIX}
.endif

.include "../../zakinko/mozc-server333/Makefile.common"
.include "../../mk/bsd.pkg.mk"
