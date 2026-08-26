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
# 30 31 の五つと、emacs20.7 emacs21.4 で建て、japanese-anthy-unicode で
# nihongo が 日本語 になり、deactivate-input-method のあと入力メソッドから
# 抜けられるところまで確かめてある。26 27 28 を書かないのは、2026-08-25 に
# 本家から消えて editors/emacs/modules.mk の表にも無く、書いても選べないため。
#
# emacs20 と emacs21 は当て物 (patch-src-util_anthy-unicode.el) と Mule-UCS が
# 要る。下の EMACS_VERSION_MAJOR < 22 の節を参照。
EMACS_VERSIONS_ACCEPTED=	emacs29 emacs29nox
EMACS_VERSIONS_ACCEPTED+=	emacs30 emacs30nox
EMACS_VERSIONS_ACCEPTED+=	emacs31 emacs31nox
EMACS_VERSIONS_ACCEPTED+=	emacs21 emacs21nox emacs20

.include "../../editors/emacs/modules.mk"

.if ${EMACS_VERSION_MAJOR} < 22
# anthy-agent-unicode は UTF-8 でしか話さない (src-util/input.c が
# ANTHY_UTF8_ENCODING を無条件に設定する。--eucjp は --egg 用の道にしか
# 効かない)。ところが Emacs 20 に utf-8 という coding system は無く、
# Emacs 21 の mule-utf-8 は CJK を落とせない — mule-unicode-* は
# U+0100〜U+33FF と U+E000〜U+FFFF しか覆わず、U+4E00〜U+9FFF を持たない。
# utf-translate-cjk は Emacs 22 から。Mule-UCS の utf-8 は CJK を
# japanese-jisx0208 に落とすので、両方ともこれで通る。
#
# byte compile の側でも要る。20/21 の byte-compiler は decode 済みの
# バッファを no-conversion で書き出すので、mule-unicode の内部表現 (先頭
# 0x9C の 4 バイト) がそのまま .elc に入り、自分で読み戻せない。Mule-UCS
# 経由なら 3 バイトの jisx0208 になって往復する。
DEPENDS+=	${EMACS_PKGNAME_PREFIX}Mule-UCS-[0-9]*:../../editors/mule-ucs
ELISP_PRELOAD=	-L ${EMACS_LISPPREFIX}/mule-ucs -l un-define
.endif

ELISP_EL=	anthy-unicode.el anthy-unicode-azik.el anthy-unicode-conf.el \
		anthy-unicode-dic.el anthy-unicode-isearch.el \
		anthy-unicode-kyuri.el

# 上流の Makefile 経由 (elisp-comp) ではなく自前で byte compile する。
# ELISP_PRELOAD を先に食わせる必要があるのが一つ、leim-list.el を対象から
# 外す必要があるのがもう一つ。leim-list.el は先頭に no-byte-compile を
# 立てているが、その cookie を見るのは Emacs 22 からで、20 と 21 の
# batch-byte-compile は構わず leim-list.elc を作ってしまい、PLIST に無い
# ファイルが出来て install が落ちる。
do-build:
	cd ${WRKSRC}/src-util && ${EMACS_BIN} -batch -q -no-site-file \
		${ELISP_PRELOAD} -L . -f batch-byte-compile ${ELISP_EL}

do-install:
	${INSTALL_DATA_DIR} ${DESTDIR}${EMACS_LISPPREFIX}/anthy-unicode
	${INSTALL_DATA} ${WRKSRC}/src-util/*.el	${DESTDIR}${EMACS_LISPPREFIX}/anthy-unicode
	${INSTALL_DATA} ${WRKSRC}/src-util/*.elc ${DESTDIR}${EMACS_LISPPREFIX}/anthy-unicode

.include "../../mk/bsd.pkg.mk"
