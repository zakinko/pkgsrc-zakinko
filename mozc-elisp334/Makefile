# $NetBSD$

PKGNAME=	${EMACS_PKGNAME_PREFIX}${DISTNAME:S/mozc-/mozc-elisp-/}

# helper 自身は変換をしない。mozc_server と話すだけで、client は版の文字列が
# 違う server を拒む (client.cc の CheckVersionOrRestartServer)。package では
# なく版で釘を刺す。
DEPENDS+=	mozc-server-${PKGVERSION_NOREV}{,nb*}:../../zakinko/mozc-server334

.include "../../zakinko/mozc-server334/options.mk"

MOZC_GYP_ARGS=	--noqt

EMACS_MODULES=	base leim

.include "../../editors/emacs/modules.mk"

INSTALLATION_DIRS=	${EMACS_LISPPREFIX} bin

post-configure:
	cd ${WRKSRC}/dist && \
		unzip -o -d ../dictionary jigyosyo.zip && \
		unzip -o -d ../dictionary ken_all.zip

.if empty(PKG_OPTIONS:Mgyp)
do-build:
	cd ${WRKSRC} && ${SETENV} ${MAKE_ENV} \
		${PREFIX}/bin/bazel \
			--output_user_root=${WRKDIR}/bazel \
			build \
			unix/emacs:mozc_emacs_helper \
			--jobs=${MAKE_JOBS:U1} \
			--host_action_env=CWRAPPERS_CONFIG_DIR=${CWRAPPERS_CONFIG_DIR} \
			--action_env=CWRAPPERS_CONFIG_DIR=${CWRAPPERS_CONFIG_DIR} \
			--host_action_env=PATH=${PATH:Q} \
			--action_env=PATH=${PATH:Q} \
			--verbose_failures \
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
			--jobs=${MAKE_JOBS:U1} \
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

.include "../../zakinko/mozc-server334/Makefile.common"

# Makefile.common が CATEGORIES を代入で置くので、足すのはその後でなければ
# ならない。前に書くと editors が黙って消える。
CATEGORIES+=	editors

.include "../../mk/bsd.pkg.mk"
