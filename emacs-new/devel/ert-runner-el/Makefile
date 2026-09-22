# $NetBSD$

DISTNAME=	ert-runner-0.8.0
PKGNAME=	${EMACS_PKGNAME_PREFIX}ert-runner-el-0.8.0
CATEGORIES=	devel
MASTER_SITES=	${MASTER_SITE_GITHUB:=rejeep/}
GITHUB_PROJECT=	ert-runner.el
GITHUB_TAG=	v${PKGVERSION_NOREV}
WRKSRC=		${WRKDIR}/ert-runner.el-0.8.0/reporters

MAINTAINER=	pkgsrc-users@NetBSD.org
HOMEPAGE=	https://github.com/rejeep/ert-runner.el/
COMMENT=	Opinionated Emacs Ert testing workflow
LICENSE=	gnu-gpl-v3

EMACS_VERSIONS_ACCEPTED=	emacs29 emacs29nox emacs30 emacs30nox emacs31 emacs31nox
DEPENDS+=	${EMACS_PKGNAME_PREFIX}ansi-el-[0-9]*:../../devel/ansi-el
DEPENDS+=	${EMACS_PKGNAME_PREFIX}commander-el-[0-9]*:../../devel/commander-el
DEPENDS+=	${EMACS_PKGNAME_PREFIX}dash-el-[0-9]*:../../devel/dash-el
DEPENDS+=	${EMACS_PKGNAME_PREFIX}f-el-[0-9]*:../../devel/f-el
DEPENDS+=	${EMACS_PKGNAME_PREFIX}shut-up-el-[0-9]*:../../devel/shut-up-el

INSTALLATION_DIRS=	${EMACS_LISPPREFIX}/ert-runner

post-extract:
	cd ${WRKSRC} && ${RM} -f *-test.el *-tests.el *-subtest.el test-*.el tests-*.el *-testsuite.el

do-build:
	cd ${WRKSRC} && ${EMACS_BIN} --no-init-file --no-site-file -batch \
		-L . -L ${EMACS_LISPPREFIX}/ansi -L ${EMACS_LISPPREFIX}/commander -L ${EMACS_LISPPREFIX}/dash -L ${EMACS_LISPPREFIX}/f -L ${EMACS_LISPPREFIX}/s -L ${EMACS_LISPPREFIX}/shut-up -f batch-byte-compile *.el

do-install:
	cd ${WRKSRC} && ${INSTALL_DATA} *.el *.elc \
		${DESTDIR}${EMACS_LISPPREFIX}/ert-runner

.include "../../editors/emacs/modules.mk"
.include "../../mk/bsd.pkg.mk"
