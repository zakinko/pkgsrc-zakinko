# $NetBSD$

.include	"../../zakinko/anthy-unicode/Makefile.common"

PKGNAME=	${EMACS_PKGNAME_PREFIX}anthy-unicode-elisp-${ANTHY_UNICODE_VERSION}
CATEGORIES=	inputmethod editors

MAINTAINER=	pkgsrc-users@NetBSD.org
COMMENT=	Emacs lisp files for inputmethod/anthy-unicode

DEPENDS+=	anthy-unicode>=${ANTHY_UNICODE_VERSION}:../../zakinko/anthy-unicode

USE_LIBTOOL=		yes
CONFIGURE_ENV+=		EMACS=${EMACS_BIN:Q}
EMACS_MODULES+=		base leim

# 受け付ける版は推測ではなく測って決めた。NetBSD 11.0/amd64 で emacs26 28 29
# 30 31 の五つで建て、nihongo が 日本語 になり、入力メソッドから抜けられる
# ところまで確かめてある。ここに emacs29 以降しか書かないのは、26 27 28 が
# 2026-08-25 に本家から消えて editors/emacs/modules.mk の表にも無く、書いても
# 選べないため。
#
# emacs20 は原理的に載らない。anthy-agent-unicode は UTF-8 で話すが、Emacs 20
# に utf-8 という coding system が無い ((coding-system-p 'utf-8) が nil)。
# 9100h の方が EUC-JP なのはそのころの Emacs に合わせてあるからで、Unicode に
# 移った代償がここに出る。emacs21 は utf-8 を持つが、依存の leim21 が建たない
# ので未確認のまま外してある。
EMACS_VERSIONS_ACCEPTED=	emacs29 emacs29nox
EMACS_VERSIONS_ACCEPTED+=	emacs30 emacs30nox
EMACS_VERSIONS_ACCEPTED+=	emacs31 emacs31nox

.include "../../editors/emacs/modules.mk"

ELISP_ELC=	anthy-unicode.elc anthy-unicode-azik.elc anthy-unicode-conf.elc \
		anthy-unicode-dic.elc anthy-unicode-isearch.elc \
		anthy-unicode-kyuri.elc leim-list.elc

do-build:
	cd ${WRKSRC}/src-util && ${MAKE} ${ELISP_ELC}

do-install:
	${INSTALL_DATA_DIR} ${DESTDIR}${EMACS_LISPPREFIX}/anthy-unicode
	${INSTALL_DATA} ${WRKSRC}/src-util/*.el	${DESTDIR}${EMACS_LISPPREFIX}/anthy-unicode
	${INSTALL_DATA} ${WRKSRC}/src-util/*.elc ${DESTDIR}${EMACS_LISPPREFIX}/anthy-unicode

.include "../../mk/bsd.pkg.mk"
