# $NetBSD: Makefile,v 1.14 2024/05/08 12:20:52 wiz Exp $
#
# 上流 pkgsrc の inputmethod/anthy-elisp/Makefile の写しに、
# EMACS_VERSIONS_ACCEPTED を広げただけのもの。
#
# 上流は emacs21 世代と XEmacs しか受け付けない。この行は 2013 年から
# そのままで、Makefile 自体は 2024 年に触られているので、単に誰も
# 新しい Emacs で試していないだけに見える。そのため
#
#	editors/emacs/modules.mk
#	.if empty(EMACS_VERSIONS_ACCEPTED:M${_EMACS_TYPE})
#	PKG_FAIL_REASON+= "No valid Emacs version installed found"
#
# で、emacs26nox でも建たない。anthy.el を入れるのはこのパッケージだけ
# (あとは tamago 系) なので、~/.emacs の (load-library "anthy") が
# 効かなくなる。
#
# ここでは 26 以降を足して、実際に byte-compile が通るかを見る。通れば
# 上流 (MAINTAINER: taya@NetBSD.org) に送る。通らなければ入力方式を
# inputmethod/ddskk か mozc-elisp に移すことになる。
#
# ただし版を広げるだけでは足りなかった。anthy.el は Emacs が後で消した
# 名前を五つ使っている。set-face-underline-p (Emacs 29 で削除) は
# トップレベルで呼ばれるため、emacs30 では anthy-isearch.elc と
# anthy-kyuri.elc ができず PLIST と食い違って失敗する。残りは関数の中に
# あるので建ってしまい、使った瞬間に落ちる。とくに
# process-kill-without-query (Emacs 30 で削除) は agent の起動経路にあり、
# 最初の変換で踏む。zakinko/anthy/patches で全部直している。
#
# PKGREVISION を上げているのはその patch のぶん。入る .elc が変わる。
#
# 7 -> 8 は patch を足したぶん。7 は既に CI が Releases に上げてしまって
# いて、番号を据え置くと「もうある」と見なされて建て直されない。実際に
# 一度それで、中身の違う patch を当てたまま build 0 件の green を出した。
# patch を触ったら必ず上げること。
#
# 8 -> 9 は patch のヘッダを直したぶん。中身の効果は変わらないが、
# distinfo に入る SHA1 が変わる以上は別物として扱う。8 も Releases に
# 出ているので同じ理由で据え置けない。
#
# 9 -> 10 は当て物を書き直したぶん。入る .elc の中身が変わる。

.include	"../../zakinko/anthy/Makefile.common"
PKGNAME=	${EMACS_PKGNAME_PREFIX}anthy-elisp-${ANTHY_VERSION}
PKGREVISION=	10
CATEGORIES=	inputmethod editors

MAINTAINER=	taya@NetBSD.org
COMMENT=	Emacs lisp files for inputmethod/anthy

DEPENDS+=	anthy>=${ANTHY_VERSION}:../../zakinko/anthy

GNU_CONFIGURE=	yes
CONFIGURE_ENV+=	EMACS=${EMACS_BIN:Q}
EMACS_MODULES+=	base leim

EMACS_VERSIONS_ACCEPTED=	emacs21 emacs21nox emacs20
EMACS_VERSIONS_ACCEPTED+=	xemacs215 xemacs215nox xemacs214 xemacs214nox
EMACS_VERSIONS_ACCEPTED+=	emacs29 emacs29nox
EMACS_VERSIONS_ACCEPTED+=	emacs30 emacs30nox
EMACS_VERSIONS_ACCEPTED+=	emacs31 emacs31nox

.include "../../editors/emacs/modules.mk"

do-build:
	cd ${WRKSRC}/src-util && ${MAKE} elc-stamp

do-install:
	${INSTALL_DATA_DIR} ${DESTDIR}${EMACS_LISPPREFIX}/anthy
	${INSTALL_DATA} ${WRKSRC}/src-util/*.el	 ${DESTDIR}${EMACS_LISPPREFIX}/anthy
	${INSTALL_DATA} ${WRKSRC}/src-util/*.elc ${DESTDIR}${EMACS_LISPPREFIX}/anthy

.include "../../mk/bsd.pkg.mk"
