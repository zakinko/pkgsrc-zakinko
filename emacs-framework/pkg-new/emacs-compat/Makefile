# $NetBSD$

# 版は EMACS_PKGNAME_PREFIX が付ける。ここで名前に版を書くと
# emacs20-emacs20-compat のように二重になる。
DISTNAME=	compat-20260922
PKGNAME=	${EMACS_PKGNAME_PREFIX}${DISTNAME}
CATEGORIES=	devel
DISTFILES=	# none

MAINTAINER=	pkgsrc-users@NetBSD.org
COMMENT=	Pieces of later Emacsen that elisp written since needs on older ones
LICENSE=	gnu-gpl-v3

# 配る file は Emacs の版ごとに違う。いまのところ足りないものが在るのは
# Emacs 20 だけで、21 以降は全部持っている。版を足すときは、files/ に
# eNN-compat.el を置いて下の一行と EMACS_VERSIONS_ACCEPTED を増やす。
COMPAT_FILE.20=		e20-compat.el
COMPAT_FILE=		${COMPAT_FILE.${EMACS_VERSION_MAJOR}}

EMACS_VERSIONS_ACCEPTED=	emacs20

WRKSRC=		${WRKDIR}
NO_CONFIGURE=	yes

PLIST_SUBST+=	COMPAT_FILE=${COMPAT_FILE:Q}

INSTALLATION_DIRS=	${EMACS_LISPPREFIX}

do-extract:
	${CP} ${FILESDIR}/${COMPAT_FILE} ${WRKSRC}/

do-build:
	cd ${WRKSRC} && ${EMACS_BIN} -batch -q --no-site-file -L . \
		-l ${COMPAT_FILE:R} -f batch-byte-compile ${COMPAT_FILE}

do-install:
	${INSTALL_DATA} ${WRKSRC}/${COMPAT_FILE} ${WRKSRC}/${COMPAT_FILE}c \
		${DESTDIR}${EMACS_LISPPREFIX}

.include "../../editors/emacs/modules.mk"
.include "../../mk/bsd.pkg.mk"
