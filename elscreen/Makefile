# $NetBSD$
#
# 1.4.6 は 2007 年の release で、作者のサイト (ftp.morishima.net) は既に
# 応答しない。Makefile 自身が「Emacs 24 以降は非対応、wip/elscreen-current
# を見よ」と書いていたが、その wip の名前は elscreen-git に変わっている。
#
# 維持されているのは knu/elscreen で、こちらは Package-Requires に
# ((emacs "24")) を書いている。同梱の add-on 九本も一つの tarball に入って
# いるので、1.4.6 が別々に引いていた distfile 十本が一本になる。
#
# XEmacs への言及は el のどこにも無いので、受けるのは GNU Emacs だけ。
# 一覧は devel/apel と同じにしてある。

DISTNAME=	elscreen-20180321
CATEGORIES=	misc
MASTER_SITES=	${MASTER_SITE_GITHUB:=knu/}
GITHUB_PROJECT=	elscreen
GITHUB_TAG=	${PKGVERSION_NOREV}

MAINTAINER=	uebayasi@NetBSD.org
HOMEPAGE=	https://github.com/knu/elscreen
COMMENT=	Window manager within Emacs
LICENSE=	gnu-gpl-v2

USE_LANGUAGES=	# none

# 1.4.6 と同じく byte-compile しない。elscreen-wl.el が Wanderlust を
# require するので、建てるなら mail/wl が要る。Emacs 31.1 で試すと他の
# 十一本は通り、この一本だけが
#
#	elscreen-wl.el:27:11: Error: Cannot open load file: ... wl
#
# で落ちる。依存を増やすかどうかは版上げとは別の話なので、ここでは
# これまでどおり el だけ入れる。
NO_BUILD=	yes

EMACS_VERSIONS_ACCEPTED=	emacs29 emacs29nox
EMACS_VERSIONS_ACCEPTED+=	emacs30 emacs30nox
EMACS_VERSIONS_ACCEPTED+=	emacs31 emacs31nox

DOCUMENTS=	COPYING GF-QuickStart GF-README Readme.md

INSTALLATION_DIRS+=	${EMACS_LISPPREFIX}/elscreen
INSTALLATION_DIRS+=	share/doc/elscreen

do-install:
	${INSTALL_DATA} ${WRKSRC}/*.el ${DESTDIR}${EMACS_LISPPREFIX}/elscreen
	for f in ${DOCUMENTS}; do \
		${INSTALL_DATA} ${WRKSRC}/$$f ${DESTDIR}${PREFIX}/share/doc/elscreen; \
	done

.include "../../editors/emacs/modules.mk"
.include "../../mk/bsd.pkg.mk"
