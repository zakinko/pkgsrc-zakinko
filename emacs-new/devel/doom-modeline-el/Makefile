# $NetBSD$

DISTNAME=	doom-modeline-4.2.1
PKGNAME=	${EMACS_PKGNAME_PREFIX}doom-modeline-el-4.2.1
CATEGORIES=	devel
MASTER_SITES=	${MASTER_SITE_GITHUB:=seagle0128/}
GITHUB_PROJECT=	doom-modeline
GITHUB_TAG=	v${PKGVERSION_NOREV}

MAINTAINER=	pkgsrc-users@NetBSD.org
HOMEPAGE=	https://seagle0128.github.io/doom-modeline/
COMMENT=	Fancy and fast mode-line for Emacs inspired by minimalism design
LICENSE=	gnu-gpl-v3

EMACS_VERSIONS_ACCEPTED=	emacs29 emacs29nox emacs30 emacs30nox emacs31 emacs31nox
DEPENDS+=	${EMACS_PKGNAME_PREFIX}compat-el-[0-9]*:../../devel/compat-el
DEPENDS+=	${EMACS_PKGNAME_PREFIX}nerd-icons-el-[0-9]*:../../devel/nerd-icons-el
DEPENDS+=	${EMACS_PKGNAME_PREFIX}shrink-path-el-[0-9]*:../../devel/shrink-path-el

INSTALLATION_DIRS=	${EMACS_LISPPREFIX}/doom-modeline

post-extract:
	cd ${WRKSRC} && ${RM} -f *-test.el *-tests.el *-subtest.el test-*.el tests-*.el *-testsuite.el .dir-locals.el

do-build:
	cd ${WRKSRC} && ${EMACS_BIN} --no-init-file --no-site-file -batch \
		-L . -L ${EMACS_LISPPREFIX}/compat -L ${EMACS_LISPPREFIX}/nerd-icons -L ${EMACS_LISPPREFIX}/shrink-path -L ${EMACS_LISPPREFIX}/dash -L ${EMACS_LISPPREFIX}/f -L ${EMACS_LISPPREFIX}/s -f batch-byte-compile *.el

# files marked no-byte-compile leave no .elc behind
do-install:
	cd ${WRKSRC} && ${INSTALL_DATA} *.el ${DESTDIR}${EMACS_LISPPREFIX}/doom-modeline
	cd ${WRKSRC} && for f in *.elc; do \
		${TEST} ! -f "$$f" || ${INSTALL_DATA} "$$f" ${DESTDIR}${EMACS_LISPPREFIX}/doom-modeline; done

.include "../../editors/emacs/modules.mk"
.include "../../mk/bsd.pkg.mk"
