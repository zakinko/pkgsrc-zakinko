# $NetBSD$

DISTNAME=	proofgeneral-4.5
PKGNAME=	${EMACS_PKGNAME_PREFIX}proofgeneral-el-4.5
CATEGORIES=	devel
MASTER_SITES=	${MASTER_SITE_GITHUB:=ProofGeneral/}
GITHUB_PROJECT=	PG
GITHUB_TAG=	v${PKGVERSION_NOREV}
WRKSRC=		${WRKDIR}/PG-4.5

MAINTAINER=	pkgsrc-users@NetBSD.org
HOMEPAGE=	https://proofgeneral.github.io/
COMMENT=	A generic interface for proof assistants
LICENSE=	gnu-gpl-v2

EMACS_VERSIONS_ACCEPTED=	emacs29 emacs29nox emacs30 emacs30nox emacs31 emacs31nox

INSTALLATION_DIRS=	${EMACS_LISPPREFIX}/proofgeneral

post-extract:
	cd ${WRKSRC} && ${RM} -f *-test.el *-tests.el *-subtest.el test-*.el tests-*.el *-testsuite.el

do-build:
	cd ${WRKSRC} && ${EMACS_BIN} --no-init-file --no-site-file -batch \
		-L . -f batch-byte-compile *.el

do-install:
	cd ${WRKSRC} && ${INSTALL_DATA} *.el *.elc \
		${DESTDIR}${EMACS_LISPPREFIX}/proofgeneral

.include "../../editors/emacs/modules.mk"
.include "../../mk/bsd.pkg.mk"
