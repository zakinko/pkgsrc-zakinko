# $NetBSD$

DISTNAME=	zenburn-20110907
PKGNAME=	${EMACS_PKGNAME_PREFIX}zenburn-el-20110907
CATEGORIES=	editors
MASTER_SITES=	${MASTER_SITE_GITHUB:=dbrock/}
GITHUB_PROJECT=	zenburn-el
GITHUB_TAG=	2b0672b04ef3e95c25f849dceb10d669296a188b
WRKSRC=		${WRKDIR}/zenburn-el-2b0672b04ef3e95c25f849dceb10d669296a188b

MAINTAINER=	pkgsrc-users@NetBSD.org
HOMEPAGE=	https://web.archive.org/web/20140612104441/http://slinky.imukuppi.org/zenburnpage/
COMMENT=	Zenburn color theme for Emacs
LICENSE=	gnu-gpl-v2

EMACS_VERSIONS_ACCEPTED=	emacs29 emacs29nox emacs30 emacs30nox emacs31 emacs31nox
DEPENDS+=	${EMACS_PKGNAME_PREFIX}color-theme-[0-9]*:../../misc/color-theme

INSTALLATION_DIRS=	${EMACS_LISPPREFIX}/zenburn

post-extract:
	cd ${WRKSRC} && ${RM} -f *-test.el *-tests.el *-subtest.el test-*.el tests-*.el *-testsuite.el

do-build:
	cd ${WRKSRC} && ${EMACS_BIN} --no-init-file --no-site-file -batch \
		-L . -L ${EMACS_LISPPREFIX}/color-theme -f batch-byte-compile *.el

do-install:
	cd ${WRKSRC} && ${INSTALL_DATA} *.el *.elc \
		${DESTDIR}${EMACS_LISPPREFIX}/zenburn

.include "../../editors/emacs/modules.mk"
.include "../../mk/bsd.pkg.mk"
