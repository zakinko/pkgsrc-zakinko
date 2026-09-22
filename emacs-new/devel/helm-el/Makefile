# $NetBSD$

DISTNAME=	helm-4.0.7
PKGNAME=	${EMACS_PKGNAME_PREFIX}helm-el-4.0.7
CATEGORIES=	devel
MASTER_SITES=	${MASTER_SITE_GITHUB:=emacs-helm/}
GITHUB_PROJECT=	helm
GITHUB_TAG=	v${PKGVERSION_NOREV}

MAINTAINER=	pkgsrc-users@NetBSD.org
HOMEPAGE=	https://emacs-helm.github.io/helm/
COMMENT=	Emacs incremental completion and selection narrowing framework
LICENSE=	gnu-gpl-v3

EMACS_VERSIONS_ACCEPTED=	emacs29 emacs29nox emacs30 emacs30nox emacs31 emacs31nox
DEPENDS+=	${EMACS_PKGNAME_PREFIX}async-el-[0-9]*:../../devel/async-el
DEPENDS+=	${EMACS_PKGNAME_PREFIX}wfnames-el-[0-9]*:../../editors/wfnames-el

INSTALLATION_DIRS=	${EMACS_LISPPREFIX}/helm

post-extract:
	cd ${WRKSRC} && ${RM} -f *-test.el *-tests.el *-subtest.el test-*.el tests-*.el *-testsuite.el .dir-locals.el

do-build:
	cd ${WRKSRC} && ${EMACS_BIN} --no-init-file --no-site-file -batch \
		-L . -L ${EMACS_LISPPREFIX}/async -L ${EMACS_LISPPREFIX}/wfnames -f batch-byte-compile *.el

do-install:
	cd ${WRKSRC} && ${INSTALL_DATA} *.el *.elc \
		${DESTDIR}${EMACS_LISPPREFIX}/helm

.include "../../editors/emacs/modules.mk"
.include "../../mk/bsd.pkg.mk"
