# $NetBSD: Makefile,v 1.24 2026/05/14 16:41:19 ryoon Exp $

PKGNAME=	${EMACS_PKGNAME_PREFIX}${DISTNAME:S/mozc-/mozc-elisp-/}
PKGREVISION=	47
CATEGORIES=	inputmethod editors

# mozc.el は mozc_emacs_helper を起動するだけで、変換は helper が
# mozc_server に投げる。server が無いと CreateSession は通るのに
# 最初の SendKey が session-error になる。上流はこの依存を書いて
# いないので、helper だけ入れて動かない、という形になる。
#
# 版は固定する。client は server の版が違うと拒み、再起動を試して
# それでも合わなければ CheckVersionOrRestartServer() failed で終わる。
# >= だと 2.29 の mozc-server でも満たされてしまい、入るのに動かない。
DEPENDS+=	mozc-server-${MOZC_VER}{,nb*}:../../zakinko/mozc-server226

EMACS_MODULES=	base leim

# Package Requires >= 24.3 for cl-lib etc.
EMACS_VERSIONS_ACCEPTED=	emacs29 emacs29nox
EMACS_VERSIONS_ACCEPTED+=	emacs30 emacs30nox
EMACS_VERSIONS_ACCEPTED+=	emacs31 emacs31nox

.include "../../editors/emacs/modules.mk"

INSTALLATION_DIRS=	${EMACS_LISPPREFIX} bin

pre-configure:
	${RM} ${WRKSRC}/unix/uim/uim.gyp


do-build:
	cd ${WRKSRC} && ${SETENV} ${MAKE_ENV} \
		${PYTHONBIN} build_mozc.py build -c Release \
			unix/emacs/emacs.gyp:mozc_emacs_helper
	cd ${WRKSRC}/unix/emacs && \
		${EMACS_BIN} -q -batch -no-site-file -no-init-file \
			-f batch-byte-compile mozc.el

do-install:
	${INSTALL_PROGRAM} ${WRKSRC}/out_${OSDEST}/Release/mozc_emacs_helper \
		${DESTDIR}${PREFIX}/bin
	${INSTALL_DATA} ${WRKSRC}/unix/emacs/mozc.el \
		${DESTDIR}${EMACS_LISPPREFIX}
	${INSTALL_DATA} ${WRKSRC}/unix/emacs/mozc.elc \
		${DESTDIR}${EMACS_LISPPREFIX}

.include "../../zakinko/mozc-server226/Makefile.common"
.include "../../mk/bsd.pkg.mk"
