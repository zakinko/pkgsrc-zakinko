# $NetBSD$

DISTNAME=	initsplit-1.8pre20160919
PKGNAME=	${EMACS_PKGNAME_PREFIX}initsplit-el-1.8pre20160919
CATEGORIES=	editors
MASTER_SITES=	${MASTER_SITE_GITHUB:=dabrahams/}
GITHUB_PROJECT=	initsplit
GITHUB_TAG=	c941d436eb2b10b01c76a582c5a2b23fb30751aa
WRKSRC=		${WRKDIR}/initsplit-c941d436eb2b10b01c76a582c5a2b23fb30751aa

MAINTAINER=	pkgsrc-users@NetBSD.org
HOMEPAGE=	https://www.emacswiki.org/emacs/InitSplit
COMMENT=	Split customizations into different files
LICENSE=	gnu-gpl-v2

EMACS_VERSIONS_ACCEPTED=	emacs29 emacs29nox emacs30 emacs30nox emacs31 emacs31nox

INSTALLATION_DIRS=	${EMACS_LISPPREFIX}/initsplit

post-extract:
	cd ${WRKSRC} && ${RM} -f *-test.el *-tests.el *-subtest.el test-*.el tests-*.el *-testsuite.el

do-build:
	cd ${WRKSRC} && ${EMACS_BIN} --no-init-file --no-site-file -batch \
		-L . -f batch-byte-compile *.el

do-install:
	cd ${WRKSRC} && ${INSTALL_DATA} *.el *.elc \
		${DESTDIR}${EMACS_LISPPREFIX}/initsplit

.include "../../editors/emacs/modules.mk"
.include "../../mk/bsd.pkg.mk"
