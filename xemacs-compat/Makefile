# $NetBSD$

DISTNAME=	xemacs-compat-20260923
PKGNAME=	${EMACS_PKGNAME_PREFIX}${DISTNAME}
CATEGORIES=	devel editors
MASTER_SITES=	# empty
DISTFILES=	# empty

MAINTAINER=	pkgsrc-users@NetBSD.org
COMMENT=	Forward compatibility for XEmacs 21.4 and 21.5
LICENSE=	gnu-gpl-v2

# Only what elisp written for GNU Emacs 24 and later asks for and XEmacs
# does not have.  Each definition is guarded, so the one file serves both
# XEmacs versions; they differ in delete-dups, which 21.5 has.
EMACS_VERSIONS_ACCEPTED=	xemacs215 xemacs215nox xemacs214 xemacs214nox

NO_CHECKSUM=	yes
NO_CONFIGURE=	yes
WRKSRC=		${WRKDIR}
EXTRACT_ONLY=	# none

INSTALLATION_DIRS=	${EMACS_LISPPREFIX}

do-extract:
	${CP} ${FILESDIR}/xemacs-compat.el ${WRKSRC}/

do-build:
	cd ${WRKSRC} && ${EMACS_BIN} -batch -q --no-site-file \
		-f batch-byte-compile xemacs-compat.el

do-install:
	cd ${WRKSRC} && ${INSTALL_DATA} xemacs-compat.el xemacs-compat.elc \
		${DESTDIR}${EMACS_LISPPREFIX}

.include "../../editors/emacs/modules.mk"
.include "../../mk/bsd.pkg.mk"
