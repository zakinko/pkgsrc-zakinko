# $NetBSD$

DISTNAME=	gap-mode-8439c3622e1f9e2ec1a8ef21020eb55e917f4416
PKGNAME=	${EMACS_PKGNAME_PREFIX}gap-mode-2.2.2
CATEGORIES=	devel
MASTER_SITES=	https://gitlab.com/gvol/gap-mode/-/archive/8439c3622e1f9e2ec1a8ef21020eb55e917f4416/
EXTRACT_SUFX=	.tar.bz2

MAINTAINER=	pkgsrc-users@NetBSD.org
HOMEPAGE=	https://gitlab.com/gvol/gap-mode
COMMENT=	Major mode for editing and running GAP programs
LICENSE=	mit

EMACS_VERSIONS_ACCEPTED=	emacs29 emacs29nox emacs30 emacs30nox emacs31 emacs31nox
# XXX Gentoo also depends on dev-gap/gaplint
DEPENDS+=	${EMACS_PKGNAME_PREFIX}company-mode-[0-9]*:../../devel/company-mode
DEPENDS+=	${EMACS_PKGNAME_PREFIX}flycheck-mode-[0-9]*:../../textproc/flycheck-mode

INSTALLATION_DIRS=	${EMACS_LISPPREFIX}/gap-mode

post-extract:
	cd ${WRKSRC} && ${RM} -f *-test.el *-tests.el *-subtest.el test-*.el tests-*.el *-testsuite.el .dir-locals.el

do-build:
	cd ${WRKSRC} && ${EMACS_BIN} --no-init-file --no-site-file -batch \
		-L . -L ${EMACS_LISPPREFIX}/company-mode -L ${EMACS_LISPPREFIX}/posframe -f batch-byte-compile *.el

# files marked no-byte-compile leave no .elc behind
do-install:
	cd ${WRKSRC} && ${INSTALL_DATA} *.el ${DESTDIR}${EMACS_LISPPREFIX}/gap-mode
	cd ${WRKSRC} && for f in *.elc; do \
		${TEST} ! -f "$$f" || ${INSTALL_DATA} "$$f" ${DESTDIR}${EMACS_LISPPREFIX}/gap-mode; done

.include "../../editors/emacs/modules.mk"
.include "../../mk/bsd.pkg.mk"
