# $NetBSD$

DISTNAME=	company-math-1.5.1
PKGNAME=	${EMACS_PKGNAME_PREFIX}company-math-el-1.5.1
CATEGORIES=	devel
MASTER_SITES=	${MASTER_SITE_GITHUB:=vspinu/}
GITHUB_PROJECT=	company-math
GITHUB_TAG=	v${PKGVERSION_NOREV}

MAINTAINER=	pkgsrc-users@NetBSD.org
HOMEPAGE=	https://github.com/vspinu/company-math/
COMMENT=	Completion back-ends for for math unicode symbols and latex tags
LICENSE=	gnu-gpl-v3

EMACS_VERSIONS_ACCEPTED=	emacs29 emacs29nox emacs30 emacs30nox emacs31 emacs31nox
DEPENDS+=	${EMACS_PKGNAME_PREFIX}company-mode-[0-9]*:../../devel/company-mode
DEPENDS+=	${EMACS_PKGNAME_PREFIX}math-symbol-lists-el-[0-9]*:../../devel/math-symbol-lists-el

INSTALLATION_DIRS=	${EMACS_LISPPREFIX}/company-math

post-extract:
	cd ${WRKSRC} && ${RM} -f *-test.el *-tests.el *-subtest.el test-*.el tests-*.el *-testsuite.el

do-build:
	cd ${WRKSRC} && ${EMACS_BIN} --no-init-file --no-site-file -batch \
		-L . -L ${EMACS_LISPPREFIX}/company-mode -L ${EMACS_LISPPREFIX}/posframe -L ${EMACS_LISPPREFIX}/math-symbol-lists -f batch-byte-compile *.el

do-install:
	cd ${WRKSRC} && ${INSTALL_DATA} *.el *.elc \
		${DESTDIR}${EMACS_LISPPREFIX}/company-math

.include "../../editors/emacs/modules.mk"
.include "../../mk/bsd.pkg.mk"
