# $NetBSD$

DISTNAME=	httpd-1.1
PKGNAME=	${EMACS_PKGNAME_PREFIX}httpd-el-1.1
CATEGORIES=	devel
MASTER_SITES=	https://distfiles.gentoo.org/distfiles/f0/
EXTRACT_SUFX=	.tar.gz
# an old library that Gentoo keeps on its own mirror; upstream is gone

MAINTAINER=	pkgsrc-users@NetBSD.org
HOMEPAGE=	http://www.chez.com/emarsden/downloads/
COMMENT=	A HTTP server embedded in the Emacs
LICENSE=	gnu-gpl-v2

EMACS_VERSIONS_ACCEPTED=	emacs29 emacs29nox emacs30 emacs30nox emacs31 emacs31nox

INSTALLATION_DIRS=	${EMACS_LISPPREFIX}/httpd

post-extract:
	cd ${WRKSRC} && ${RM} -f *-test.el *-tests.el *-subtest.el test-*.el tests-*.el *-testsuite.el

do-build:
	cd ${WRKSRC} && ${EMACS_BIN} --no-init-file --no-site-file -batch \
		-L . -f batch-byte-compile *.el

do-install:
	cd ${WRKSRC} && ${INSTALL_DATA} *.el *.elc \
		${DESTDIR}${EMACS_LISPPREFIX}/httpd

.include "../../editors/emacs/modules.mk"
.include "../../mk/bsd.pkg.mk"
