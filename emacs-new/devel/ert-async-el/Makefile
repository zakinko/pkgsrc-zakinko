# $NetBSD$

DISTNAME=	ert-async-0.1.2.20200105
PKGNAME=	${EMACS_PKGNAME_PREFIX}ert-async-el-0.1.2.20200105
CATEGORIES=	devel
MASTER_SITES=	${MASTER_SITE_GITHUB:=rejeep/}
GITHUB_PROJECT=	ert-async.el
GITHUB_TAG=	948cf2faa10e085bda3739034ca5ea1912893433
WRKSRC=		${WRKDIR}/ert-async.el-948cf2faa10e085bda3739034ca5ea1912893433

MAINTAINER=	pkgsrc-users@NetBSD.org
HOMEPAGE=	https://github.com/rejeep/ert-async.el/
COMMENT=	Async support for ERT
LICENSE=	gnu-gpl-v3

EMACS_VERSIONS_ACCEPTED=	emacs29 emacs29nox emacs30 emacs30nox emacs31 emacs31nox

INSTALLATION_DIRS=	${EMACS_LISPPREFIX}/ert-async

post-extract:
	cd ${WRKSRC} && ${RM} -f *-test.el *-tests.el *-subtest.el test-*.el tests-*.el *-testsuite.el

do-build:
	cd ${WRKSRC} && ${EMACS_BIN} --no-init-file --no-site-file -batch \
		-L . -f batch-byte-compile *.el

do-install:
	cd ${WRKSRC} && ${INSTALL_DATA} *.el *.elc \
		${DESTDIR}${EMACS_LISPPREFIX}/ert-async

.include "../../editors/emacs/modules.mk"
.include "../../mk/bsd.pkg.mk"
