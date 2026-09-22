# $NetBSD$

DISTNAME=	highlight-indentation-0.7.0.20210221
PKGNAME=	${EMACS_PKGNAME_PREFIX}highlight-indentation-el-0.7.0.20210221
CATEGORIES=	editors
MASTER_SITES=	${MASTER_SITE_GITHUB:=antonj/}
GITHUB_PROJECT=	Highlight-Indentation-for-Emacs
GITHUB_TAG=	d88db4248882da2d4316e76ed673b4ac1fa99ce3
WRKSRC=		${WRKDIR}/Highlight-Indentation-for-Emacs-d88db4248882da2d4316e76ed673b4ac1fa99ce3

MAINTAINER=	pkgsrc-users@NetBSD.org
HOMEPAGE=	https://github.com/antonj/Highlight-Indentation-for-Emacs/
COMMENT=	Minor modes to highlight indentation guides in Emacs
LICENSE=	gnu-gpl-v2

EMACS_VERSIONS_ACCEPTED=	emacs29 emacs29nox emacs30 emacs30nox emacs31 emacs31nox

INSTALLATION_DIRS=	${EMACS_LISPPREFIX}/highlight-indentation

post-extract:
	cd ${WRKSRC} && ${RM} -f *-test.el *-tests.el *-subtest.el test-*.el tests-*.el *-testsuite.el

do-build:
	cd ${WRKSRC} && ${EMACS_BIN} --no-init-file --no-site-file -batch \
		-L . -f batch-byte-compile *.el

do-install:
	cd ${WRKSRC} && ${INSTALL_DATA} *.el *.elc \
		${DESTDIR}${EMACS_LISPPREFIX}/highlight-indentation

.include "../../editors/emacs/modules.mk"
.include "../../mk/bsd.pkg.mk"
