# $NetBSD$

DISTNAME=	nxml-mode-20041004
PKGREVISION=	5
CATEGORIES=	textproc editors
MASTER_SITES=	http://www.thaiopensource.com/download/

MAINTAINER=	tonio@NetBSD.org
HOMEPAGE=	http://www.thaiopensource.com/nxml-mode/
COMMENT=	Major mode for editing XML documents for emacs
LICENSE=	gnu-gpl-v2

NO_CONFIGURE=		yes
USE_TOOLS+=		makeinfo
EMACS_VERSIONS_ACCEPTED=	emacs21 emacs21nox

INSTALLATION_DIRS=	${EMACS_LISPPREFIX}/nxml-mode/schema \
			${EMACS_LISPPREFIX}/nxml-mode/char-name/unicode ${EMACS_INFOPREFIX}

do-install:
	${INSTALL_DATA} ${WRKSRC}/*.el* ${DESTDIR}${EMACS_LISPPREFIX}/nxml-mode
	${INSTALL_DATA} ${WRKSRC}/schema/*.rnc ${DESTDIR}${EMACS_LISPPREFIX}/nxml-mode/schema
	${INSTALL_DATA} ${WRKSRC}/schema/*.xml ${DESTDIR}${EMACS_LISPPREFIX}/nxml-mode/schema
	${INSTALL_DATA} ${WRKSRC}/char-name/unicode/*.el ${DESTDIR}${EMACS_LISPPREFIX}/nxml-mode/char-name/unicode
	${INSTALL_DATA} ${WRKSRC}/nxml-mode.info ${DESTDIR}${EMACS_INFOPREFIX}

.include "../../editors/emacs/modules.mk"
.include "../../mk/bsd.pkg.mk"
