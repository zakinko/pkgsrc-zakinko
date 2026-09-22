# $NetBSD$

DISTNAME=	emacs-compat-20260923
PKGNAME=	${EMACS_PKGNAME_PREFIX}${DISTNAME}
CATEGORIES=	devel editors
MASTER_SITES=	# empty
DISTFILES=	# empty

MAINTAINER=	zakinko@snowrabbit.org
COMMENT=	Forward compatibility for Emacs 21 to 23
LICENSE=	gnu-gpl-v2

# Emacs 21.4 has none of what this defines, 22.3 and 23.4 have dolist and
# delete-dups only, and 24.5 and later have all of it, so the file is a
# no-op there.  Emacs 20 needs devel/emacs20-compat instead: this file is
# written with a reader that takes #x and ?\s.
EMACS_VERSIONS_ACCEPTED=	emacs31 emacs31nox emacs30 emacs30nox \
				emacs29 emacs29nox emacs28 emacs28nox \
				emacs27 emacs27nox emacs26 emacs26nox \
				emacs25 emacs25nox emacs24 emacs24nox \
				emacs23 emacs23nox emacs22 emacs22nox \
				emacs21 emacs21nox

NO_CHECKSUM=	yes
NO_CONFIGURE=	yes
WRKSRC=		${WRKDIR}
EXTRACT_ONLY=	# none

INSTALLATION_DIRS=	${EMACS_LISPPREFIX}

do-extract:
	${CP} ${FILESDIR}/emacs-compat.el ${WRKSRC}/

do-build:
	cd ${WRKSRC} && ${EMACS_BIN} -batch -q --no-site-file \
		-f batch-byte-compile emacs-compat.el

do-install:
	cd ${WRKSRC} && ${INSTALL_DATA} emacs-compat.el emacs-compat.elc \
		${DESTDIR}${EMACS_LISPPREFIX}

.include "../../editors/emacs/modules.mk"
.include "../../mk/bsd.pkg.mk"
