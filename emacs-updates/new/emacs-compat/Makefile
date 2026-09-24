# $NetBSD$

# The version comes from EMACS_PKGNAME_PREFIX, so this package is named
# once and installs for whichever Emacs it is built for.  Writing the
# version into the name as well gave emacs20-emacs20-compat.
DISTNAME=	emacs-compat-20260924
PKGNAME=	${EMACS_PKGNAME_PREFIX}${DISTNAME}
CATEGORIES=	devel editors
MASTER_SITES=	# empty
DISTFILES=	# empty

MAINTAINER=	pkgsrc-users@NetBSD.org
COMMENT=	What an older Emacs lacks, for elisp written since
LICENSE=	gnu-gpl-v3

# One file serves every version: each definition is made only when the
# running Emacs does not have it, so on a recent Emacs the file is a
# no-op.  It is written in the syntax Emacs 20's reader accepts, which
# is what lets the same file be used from 20 to 31.
EMACS_VERSIONS_ACCEPTED=	emacs31 emacs31nox emacs30 emacs30nox \
				emacs29 emacs29nox emacs28 emacs28nox \
				emacs27 emacs27nox emacs26 emacs26nox \
				emacs25 emacs25nox emacs24 emacs24nox \
				emacs23 emacs23nox emacs22 emacs22nox \
				emacs21 emacs21nox emacs20

NO_CHECKSUM=	yes
NO_CONFIGURE=	yes
WRKSRC=		${WRKDIR}

INSTALLATION_DIRS=	${EMACS_LISPPREFIX}

do-extract:
	${CP} ${FILESDIR}/emacs-compat.el ${WRKSRC}/

do-build:
	cd ${WRKSRC} && ${EMACS_BIN} -batch -q --no-site-file -L . \
		-f batch-byte-compile emacs-compat.el

do-install:
	${INSTALL_DATA} ${WRKSRC}/emacs-compat.el ${WRKSRC}/emacs-compat.elc \
		${DESTDIR}${EMACS_LISPPREFIX}

.include "../../editors/emacs/modules.mk"
.include "../../mk/bsd.pkg.mk"
