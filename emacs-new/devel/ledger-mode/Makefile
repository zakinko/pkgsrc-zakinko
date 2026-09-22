# $NetBSD$

DISTNAME=	ledger-mode-4.0.0.20260727
PKGNAME=	${EMACS_PKGNAME_PREFIX}ledger-mode-4.0.0.20260727
CATEGORIES=	devel
MASTER_SITES=	${MASTER_SITE_GITHUB:=ledger/}
GITHUB_PROJECT=	ledger-mode
GITHUB_TAG=	b0e71b7e9ee612ccb0b0e5f8bfefcfddb69ae861
WRKSRC=		${WRKDIR}/ledger-mode-b0e71b7e9ee612ccb0b0e5f8bfefcfddb69ae861

MAINTAINER=	pkgsrc-users@NetBSD.org
HOMEPAGE=	https://github.com/ledger/ledger-mode
COMMENT=	An Emacs major mode for editing ledger files
LICENSE=	gnu-gpl-v2

EMACS_VERSIONS_ACCEPTED=	emacs29 emacs29nox emacs30 emacs30nox emacs31 emacs31nox
# XXX Gentoo also depends on app-office/ledger-3.1.2

INSTALLATION_DIRS=	${EMACS_LISPPREFIX}/ledger-mode

post-extract:
	cd ${WRKSRC} && ${RM} -f .dir-locals.el

do-build:
	cd ${WRKSRC} && ${EMACS_BIN} --no-init-file --no-site-file -batch \
		-L .  -f batch-byte-compile *.el

# files marked no-byte-compile leave no .elc behind
do-install:
	cd ${WRKSRC} && ${INSTALL_DATA} *.el ${DESTDIR}${EMACS_LISPPREFIX}/ledger-mode
	cd ${WRKSRC} && for f in *.elc; do \
		test ! -f "$$f" || ${INSTALL_DATA} "$$f" ${DESTDIR}${EMACS_LISPPREFIX}/ledger-mode; done

.include "../../editors/emacs/modules.mk"
.include "../../mk/bsd.pkg.mk"
