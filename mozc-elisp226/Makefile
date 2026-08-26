# $NetBSD: Makefile,v 1.24 2026/05/14 16:41:19 ryoon Exp $

PKGNAME=	${EMACS_PKGNAME_PREFIX}${DISTNAME:S/mozc-/mozc-elisp-/}
PKGREVISION=	47
CATEGORIES=	inputmethod editors

MOZC_NO_GUI=	yes

# mozc.el は mozc_emacs_helper を起動するだけで、変換は helper が
# mozc_server に投げる。server が無いと CreateSession は通るのに
# 最初の SendKey が session-error になる。上流はこの依存を書いて
# いないので、helper だけ入れて動かない、という形になる。
DEPENDS+=	mozc-server>=${MOZC_VER}:../../inputmethod/mozc-server226

EMACS_MODULES=	base leim

# Package Requires >= 24.3 for cl-lib etc.
EMACS_VERSIONS_ACCEPTED=	emacs29 emacs29nox
EMACS_VERSIONS_ACCEPTED+=	emacs30 emacs30nox
EMACS_VERSIONS_ACCEPTED+=	emacs31 emacs31nox

.include "../../editors/emacs/modules.mk"

INSTALLATION_DIRS=	${EMACS_LISPPREFIX} bin

pre-configure:
	${RM} ${WRKSRC}/unix/uim/uim.gyp
# renderer.gyp が gyp の時点で pkg-config gtk+-2.0 を呼ぶのを止める。
# 呼ぶのは (target_platform=="Linux" or ...=="NetBSD") and
# enable_gtk_renderer==1 の枝で、NetBSD を足したのは pkgsrc の
# patch-renderer_renderer.gyp である。mozc_emacs_helper には要らない。
# build_mozc.py は任意の -D を素通ししないので、既定値の側を落とす。
	${SED} -e "s/'enable_gtk_renderer%': '1'/'enable_gtk_renderer%': '0'/" \
		${WRKSRC}/gyp/defines.gypi > ${WRKSRC}/gyp/defines.gypi.new
	${MV} ${WRKSRC}/gyp/defines.gypi.new ${WRKSRC}/gyp/defines.gypi


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

.include "../../zakinko/mozc-elisp226/Makefile.common"
.include "../../mk/bsd.pkg.mk"
