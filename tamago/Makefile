# $NetBSD$

DISTNAME=	tamago-4.0.6
PKGNAME=	${EMACS_PKGNAME_PREFIX}tamago-20020909
PKGREVISION=	6
CATEGORIES=	editors
MASTER_SITES=	http://unit.aist.go.jp/itri/itri-gist/ftp.m17n.org/pub/tamago/

MAINTAINER=	tech-pkg-ja@jp.NetBSD.org
#HOMEPAGE=	http://www.m17n.org/tamago/
COMMENT=	CJK characters inputting system for emacs + leim
LICENSE=	gnu-gpl-v2

GNU_CONFIGURE=	yes
MAKE_FLAGS+=	prefix=${DESTDIR}${PREFIX}
# XXX please someone adjust paths and PLIST for XEmacs...
# 2026-09-23 に手元の Emacs 31.1 で測った。当て物二本で載り、入力メソッドも
# 11 個登録される (japanese-egg-anthy ほか)。変換までは見ていない。server が
# 要るため。古い版はそのまま受ける — 当て物はどちらも fboundp で分けてある。
EMACS_VERSIONS_ACCEPTED=	emacs21 emacs21nox emacs20
EMACS_VERSIONS_ACCEPTED+=	emacs29 emacs29nox
EMACS_VERSIONS_ACCEPTED+=	emacs30 emacs30nox
EMACS_VERSIONS_ACCEPTED+=	emacs31 emacs31nox
EMACS_MODULES+=	leim

.include "../../editors/emacs/modules.mk"

PLIST_VARS+=	jisx0213

# PLIST_VARS has to be decided before the PLIST is read, so these two can
# only be looked at here.  modules.mk is included above, so they are set.
.if ${EMACS_FLAVOR} == "emacs" && ${EMACS_VERSION_MAJOR} >= 21
PLIST.jisx0213=	yes
.endif

.include "../../mk/bsd.pkg.mk"
