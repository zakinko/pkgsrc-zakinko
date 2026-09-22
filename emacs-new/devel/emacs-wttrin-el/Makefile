# $NetBSD$

DISTNAME=	emacs-wttrin-0.3.2
PKGNAME=	${EMACS_PKGNAME_PREFIX}emacs-wttrin-el-0.3.2
CATEGORIES=	devel
MASTER_SITES=	${MASTER_SITE_GITHUB:=cjennings/}
GITHUB_PROJECT=	emacs-wttrin
GITHUB_TAG=	v${PKGVERSION_NOREV}

MAINTAINER=	pkgsrc-users@NetBSD.org
HOMEPAGE=	https://github.com/cjennings/emacs-wttrin/
COMMENT=	GNU Emacs frontend for wttr.in weather report service
LICENSE=	gnu-gpl-v3

EMACS_VERSIONS_ACCEPTED=	emacs29 emacs29nox emacs30 emacs30nox emacs31 emacs31nox
DEPENDS+=	${EMACS_PKGNAME_PREFIX}xterm-color-el-[0-9]*:../../devel/xterm-color-el

INSTALLATION_DIRS=	${EMACS_LISPPREFIX}/emacs-wttrin

post-extract:
	cd ${WRKSRC} && ${RM} -f *-test.el *-tests.el *-subtest.el test-*.el tests-*.el *-testsuite.el .dir-locals.el

do-build:
	cd ${WRKSRC} && ${EMACS_BIN} --no-init-file --no-site-file -batch \
		-L . -L ${EMACS_LISPPREFIX}/xterm-color -f batch-byte-compile *.el

# files marked no-byte-compile leave no .elc behind
do-install:
	cd ${WRKSRC} && ${INSTALL_DATA} *.el ${DESTDIR}${EMACS_LISPPREFIX}/emacs-wttrin
	cd ${WRKSRC} && for f in *.elc; do \
		${TEST} ! -f "$$f" || ${INSTALL_DATA} "$$f" ${DESTDIR}${EMACS_LISPPREFIX}/emacs-wttrin; done

.include "../../editors/emacs/modules.mk"
.include "../../mk/bsd.pkg.mk"
