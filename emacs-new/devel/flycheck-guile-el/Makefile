# $NetBSD$

DISTNAME=	flycheck-guile-0.5
PKGNAME=	${EMACS_PKGNAME_PREFIX}flycheck-guile-el-0.5
CATEGORIES=	devel
MASTER_SITES=	${MASTER_SITE_GITHUB:=flatwhatson/}
GITHUB_PROJECT=	flycheck-guile
GITHUB_TAG=	${PKGVERSION_NOREV}

MAINTAINER=	pkgsrc-users@NetBSD.org
HOMEPAGE=	https://github.com/flatwhatson/flycheck-guile/
COMMENT=	Flycheck checker for the GNU Guile Scheme implementation
LICENSE=	gnu-gpl-v3

EMACS_VERSIONS_ACCEPTED=	emacs29 emacs29nox emacs30 emacs30nox emacs31 emacs31nox
DEPENDS+=	${EMACS_PKGNAME_PREFIX}flycheck-mode-[0-9]*:../../textproc/flycheck-mode
DEPENDS+=	${EMACS_PKGNAME_PREFIX}geiser-guile-el-[0-9]*:../../editors/geiser-guile-el

INSTALLATION_DIRS=	${EMACS_LISPPREFIX}/flycheck-guile

post-extract:
	cd ${WRKSRC} && ${RM} -f *-test.el *-tests.el *-subtest.el test-*.el tests-*.el *-testsuite.el

do-build:
	cd ${WRKSRC} && ${EMACS_BIN} --no-init-file --no-site-file -batch \
		-L . -L ${EMACS_LISPPREFIX}/geiser-guile -L ${EMACS_LISPPREFIX}/geiser -L ${EMACS_LISPPREFIX}/transient -L ${EMACS_LISPPREFIX}/compat -L ${EMACS_LISPPREFIX}/cond-let -L ${EMACS_LISPPREFIX}/llama -f batch-byte-compile *.el

do-install:
	cd ${WRKSRC} && ${INSTALL_DATA} *.el *.elc \
		${DESTDIR}${EMACS_LISPPREFIX}/flycheck-guile

.include "../../editors/emacs/modules.mk"
.include "../../mk/bsd.pkg.mk"
