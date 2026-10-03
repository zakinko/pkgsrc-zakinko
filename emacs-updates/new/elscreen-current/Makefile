# $NetBSD$

DISTNAME=	elscreen-20180321
PKGNAME=	${EMACS_PKGNAME_PREFIX}${DISTNAME:S/elscreen-/elscreen-current-/}
CATEGORIES=	misc
MASTER_SITES=	${MASTER_SITE_GITHUB:=knu/}
GITHUB_PROJECT=	elscreen
GITHUB_TAG=	${PKGVERSION_NOREV}

CONFLICTS+=	${EMACS_PKGNAME_PREFIX}elscreen-[0-9]*

MAINTAINER=	pkgsrc-users@NetBSD.org
HOMEPAGE=	https://github.com/knu/elscreen
COMMENT=	Window manager within Emacs
LICENSE=	gnu-gpl-v2

# This is the maintained fork of ElScreen 1.4.6, for Emacs 24 and later;
# misc/elscreen keeps 1.4.6 for emacs20.  It no longer needs APEL.
EMACS_VERSIONS_ACCEPTED=	emacs29 emacs29nox emacs30 emacs30nox emacs31 emacs31nox

INSTALLATION_DIRS=	${EMACS_LISPPREFIX}/elscreen share/doc/elscreen

do-build:
	cd ${WRKSRC} && ${EMACS_BIN} --no-init-file --no-site-file -batch \
		-L . -f batch-byte-compile elscreen.el

do-install:
	cd ${WRKSRC} && ${INSTALL_DATA} *.el elscreen.elc \
		${DESTDIR}${EMACS_LISPPREFIX}/elscreen
	cd ${WRKSRC} && ${INSTALL_DATA} Readme.md GF-README GF-QuickStart \
		${DESTDIR}${PREFIX}/share/doc/elscreen

.include "../../editors/emacs/modules.mk"
.include "../../mk/bsd.pkg.mk"
