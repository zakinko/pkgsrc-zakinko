# $NetBSD$

DISTNAME=	nix-mode-1.5.0
PKGNAME=	${EMACS_PKGNAME_PREFIX}nix-mode-1.5.0
CATEGORIES=	devel
MASTER_SITES=	${MASTER_SITE_GITHUB:=NixOS/}
GITHUB_PROJECT=	nix-mode
GITHUB_TAG=	v${PKGVERSION_NOREV}

MAINTAINER=	pkgsrc-users@NetBSD.org
HOMEPAGE=	https://github.com/NixOS/nix-mode/
COMMENT=	GNU Emacs major mode for editing Nix expressions
LICENSE=	gnu-lgpl-v2.1

EMACS_VERSIONS_ACCEPTED=	emacs29 emacs29nox emacs30 emacs30nox emacs31 emacs31nox
DEPENDS+=	${EMACS_PKGNAME_PREFIX}company-mode-[0-9]*:../../devel/company-mode
DEPENDS+=	${EMACS_PKGNAME_PREFIX}magit-el-[0-9]*:../../devel/magit-el
DEPENDS+=	${EMACS_PKGNAME_PREFIX}mmm-mode-[0-9]*:../../devel/mmm-mode
DEPENDS+=	${EMACS_PKGNAME_PREFIX}transient-el-[0-9]*:../../devel/transient-el

INSTALLATION_DIRS=	${EMACS_LISPPREFIX}/nix-mode

post-extract:
	cd ${WRKSRC} && ${RM} -f *-test.el *-tests.el *-subtest.el test-*.el tests-*.el *-testsuite.el .dir-locals.el

do-build:
	cd ${WRKSRC} && ${EMACS_BIN} --no-init-file --no-site-file -batch \
		-L . -L ${EMACS_LISPPREFIX}/company-mode -L ${EMACS_LISPPREFIX}/posframe -L ${EMACS_LISPPREFIX}/magit -L ${EMACS_LISPPREFIX}/compat -L ${EMACS_LISPPREFIX}/cond-let -L ${EMACS_LISPPREFIX}/llama -L ${EMACS_LISPPREFIX}/transient -L ${EMACS_LISPPREFIX}/with-editor -L ${EMACS_LISPPREFIX}/mmm-mode -f batch-byte-compile *.el

# files marked no-byte-compile leave no .elc behind
do-install:
	cd ${WRKSRC} && ${INSTALL_DATA} *.el ${DESTDIR}${EMACS_LISPPREFIX}/nix-mode
	cd ${WRKSRC} && for f in *.elc; do \
		${TEST} ! -f "$$f" || ${INSTALL_DATA} "$$f" ${DESTDIR}${EMACS_LISPPREFIX}/nix-mode; done

.include "../../editors/emacs/modules.mk"
.include "../../mk/bsd.pkg.mk"
