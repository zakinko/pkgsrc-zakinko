# $NetBSD$

DISTNAME=	powershell-0.3pre20220805
PKGNAME=	${EMACS_PKGNAME_PREFIX}powershell-el-0.3pre20220805
CATEGORIES=	devel
MASTER_SITES=	${MASTER_SITE_GITHUB:=jschaf/}
GITHUB_PROJECT=	powershell.el
GITHUB_TAG=	f2da15857e430206e215a3c65289b4058ae3c976
WRKSRC=		${WRKDIR}/powershell.el-f2da15857e430206e215a3c65289b4058ae3c976

MAINTAINER=	pkgsrc-users@NetBSD.org
HOMEPAGE=	https://github.com/jschaf/powershell.el/
COMMENT=	GNU Emacs mode for editing and running PowerShell code
LICENSE=	gnu-gpl-v3

EMACS_VERSIONS_ACCEPTED=	emacs29 emacs29nox emacs30 emacs30nox emacs31 emacs31nox

INSTALLATION_DIRS=	${EMACS_LISPPREFIX}/powershell

post-extract:
	cd ${WRKSRC} && ${RM} -f *-test.el *-tests.el *-subtest.el test-*.el tests-*.el *-testsuite.el .dir-locals.el

do-build:
	cd ${WRKSRC} && ${EMACS_BIN} --no-init-file --no-site-file -batch \
		-L .  -f batch-byte-compile *.el

# files marked no-byte-compile leave no .elc behind
do-install:
	cd ${WRKSRC} && ${INSTALL_DATA} *.el ${DESTDIR}${EMACS_LISPPREFIX}/powershell
	cd ${WRKSRC} && for f in *.elc; do \
		${TEST} ! -f "$$f" || ${INSTALL_DATA} "$$f" ${DESTDIR}${EMACS_LISPPREFIX}/powershell; done

.include "../../editors/emacs/modules.mk"
.include "../../mk/bsd.pkg.mk"
