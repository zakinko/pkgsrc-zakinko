# $NetBSD$

DISTNAME=	helm-system-packages-1.10.2
PKGNAME=	${EMACS_PKGNAME_PREFIX}helm-system-packages-el-1.10.2
CATEGORIES=	devel
MASTER_SITES=	${MASTER_SITE_GITHUB:=emacs-helm/}
GITHUB_PROJECT=	helm-system-packages
GITHUB_TAG=	v${PKGVERSION_NOREV}

MAINTAINER=	pkgsrc-users@NetBSD.org
HOMEPAGE=	https://github.com/emacs-helm/helm-system-packages
COMMENT=	Helm interface to the package manager of your operating system
LICENSE=	gnu-gpl-v3

EMACS_VERSIONS_ACCEPTED=	emacs29 emacs29nox emacs30 emacs30nox emacs31 emacs31nox
DEPENDS+=	${EMACS_PKGNAME_PREFIX}helm-el-[0-9]*:../../devel/helm-el

INSTALLATION_DIRS=	${EMACS_LISPPREFIX}/helm-system-packages

post-extract:
	cd ${WRKSRC} && ${RM} -f *-test.el *-tests.el *-subtest.el test-*.el tests-*.el *-testsuite.el .dir-locals.el

do-build:
	cd ${WRKSRC} && ${EMACS_BIN} --no-init-file --no-site-file -batch \
		-L . -L ${EMACS_LISPPREFIX}/helm -L ${EMACS_LISPPREFIX}/async -L ${EMACS_LISPPREFIX}/wfnames -f batch-byte-compile *.el

# files marked no-byte-compile leave no .elc behind
do-install:
	cd ${WRKSRC} && ${INSTALL_DATA} *.el ${DESTDIR}${EMACS_LISPPREFIX}/helm-system-packages
	cd ${WRKSRC} && for f in *.elc; do \
		${TEST} ! -f "$$f" || ${INSTALL_DATA} "$$f" ${DESTDIR}${EMACS_LISPPREFIX}/helm-system-packages; done

.include "../../editors/emacs/modules.mk"
.include "../../mk/bsd.pkg.mk"
