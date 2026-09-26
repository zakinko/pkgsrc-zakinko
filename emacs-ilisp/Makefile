# $NetBSD$
#

# SourceForge の 20021222 は互換層が ilfsf18 から ilfsf21 までしか無く、
# Emacs 22 以降に届かない。維持されているのは Debian の barak/ilisp で、
# そちらは ilfsf22 から ilfsf25 と ilxemacs を持つ。release は切られて
# いないので HEAD を指す。
#
# GITHUB_TAG が 7 桁以上の 16 進だと mk/fetch/github.mk:60 が commit hash と
# 見なして distfile 名に足すので、落ちてくるのは
# ilisp-20230703-14eae2c0....tar.gz になる。展開先は tag のままなので
# WRKSRC を書く。
DISTNAME=	ilisp-20230703
PKGNAME=	${EMACS_PKGNAME_PREFIX}emacs-${DISTNAME}
CATEGORIES=	devel
MASTER_SITES=	${MASTER_SITE_GITHUB:=barak/}
GITHUB_PROJECT=	ilisp
GITHUB_TAG=	14eae2c05618b798c35e44fe3783a4e3b135ad10
WRKSRC=		${WRKDIR}/${GITHUB_PROJECT}-${GITHUB_TAG}

MAINTAINER=	pkgsrc-users@NetBSD.org
HOMEPAGE=	https://sourceforge.net/projects/ilisp/
COMMENT=	Emacs interface to embedded Lisp process
# ILISP is not under the GPL.  Its own terms -- "GENERAL LICENSE AGREEMENT AND
# LACK OF WARRANTY", dated January 4th, 1995 -- are reproduced in the tarball's
# debian/copyright, and a copy is in files/ilisp-license here.  pkgsrc has no
# licence of that shape among its 264, so LICENSE cannot be set until the file
# is added as licenses/ilisp-license.  Left commented so the package still
# builds; the two go together.
#LICENSE=	ilisp-license

# 2026-09-23 に手元の Emacs 31.1 で測った。当て物四本で上流の compile 目標が
# rc=0 になり、load が通って run-ilisp が command になる。Lisp を実際に
# 動かしてはいない。
EMACS_VERSIONS_ACCEPTED=	emacs20 emacs21 emacs21nox
EMACS_VERSIONS_ACCEPTED+=	emacs29 emacs29nox
EMACS_VERSIONS_ACCEPTED+=	emacs30 emacs30nox
EMACS_VERSIONS_ACCEPTED+=	emacs31 emacs31nox

MAKE_ENV+=	EMACS=${EMACS_BIN}
BUILD_TARGET=	compile

SITELISP=	${EMACS_LISPPREFIX}/ilisp

INSTALLATION_DIRS+=	share/doc/emacs-ilisp
INSTALLATION_DIRS+=	share/examples/emacs-ilisp

do-install:
	${INSTALL_DATA} ${WRKSRC}/INSTALLATION \
		${DESTDIR}${PREFIX}/share/doc/emacs-ilisp
	${INSTALL_DATA} ${WRKSRC}/README \
		${DESTDIR}${PREFIX}/share/doc/emacs-ilisp
	${INSTALL_DATA} ${WRKSRC}/ilisp.emacs \
		${DESTDIR}${PREFIX}/share/examples/emacs-ilisp
	${INSTALL_DATA_DIR} ${DESTDIR}${SITELISP}
	${INSTALL_DATA} ${WRKSRC}/*.el ${DESTDIR}${SITELISP}
	${INSTALL_DATA} ${WRKSRC}/*.elc ${DESTDIR}${SITELISP}
	${INSTALL_DATA} ${WRKSRC}/*.lisp ${DESTDIR}${SITELISP}
	${INSTALL_DATA} ${WRKSRC}/*.scm ${DESTDIR}${SITELISP}
	${INSTALL_DATA_DIR} ${DESTDIR}${SITELISP}/extra
	${INSTALL_DATA} ${WRKSRC}/extra/*.el ${DESTDIR}${SITELISP}/extra
	${INSTALL_DATA} ${WRKSRC}/extra/*.elc ${DESTDIR}${SITELISP}/extra

.include "../../editors/emacs/modules.mk"
.include "../../mk/bsd.pkg.mk"
