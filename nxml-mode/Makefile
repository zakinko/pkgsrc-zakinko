# $NetBSD$

DISTNAME=	nxml-mode-20041004
PKGNAME=	${EMACS_PKGNAME_PREFIX}${DISTNAME}
PKGREVISION=	5
CATEGORIES=	textproc editors
MASTER_SITES=	http://www.thaiopensource.com/download/

MAINTAINER=	tonio@NetBSD.org
HOMEPAGE=	http://www.thaiopensource.com/nxml-mode/
COMMENT=	Major mode for editing XML documents for emacs
LICENSE=	gnu-gpl-v2

NO_CONFIGURE=		yes
USE_TOOLS+=		makeinfo
# nxml-mode was written for Emacs 21 and is bundled since Emacs 23.  On
# emacs20, devel/elisp-compat supplies what Emacs 20 lacks and
# files/nxml-e20.el the mode's own fontification (see the patches);
# Mule-UCS supplies decode-char.  The patches change nothing on Emacs 21.
EMACS_VERSIONS_ACCEPTED=	emacs20 emacs21 emacs21nox

INSTALLATION_DIRS=	${EMACS_LISPPREFIX}/nxml-mode/schema \
			${EMACS_LISPPREFIX}/nxml-mode/char-name/unicode ${EMACS_INFOPREFIX}

.include "../../editors/emacs/modules.mk"

.if ${EMACS_VERSION_MAJOR} == 20
USE_TOOLS+=		perl
DEPENDS+=		${EMACS_PKGNAME_PREFIX}Mule-UCS-[0-9]*:../../zakinko/mule-ucs

# Emacs 20's reader has no #x hex syntax; the sources use it 14,490 times,
# so turn the numbers into decimal at build time rather than in a patch.
post-patch:
	cd ${WRKSRC} && ${PERL5} -pi -e 's/#x([0-9A-Fa-f]+)\b/hex($$1)/ge' \
		*.el char-name/unicode/*.el
	${CP} ${FILESDIR}/nxml-e20.el ${WRKSRC}/

# the distfile's .elc were compiled by Emacs 21 and do not load in 20
do-build:
	cd ${WRKSRC} && ${RM} -f *.elc && ${EMACS_BIN} -batch -q --no-site-file \
		-L . -L ${EMACS_LISPPREFIX} -L ${EMACS_LISPPREFIX}/mule-ucs \
		-l un-define -l nxml-e20 \
		-f batch-byte-compile *.el && ${RM} -f rng-auto.elc

.include "../../zakinko/elisp-compat/buildlink3.mk"
.else
# The bundled Makefile compiles with EMACS=emacs, which is whichever Emacs
# bin/emacs points at, not the one this package is built for.
MAKE_FLAGS+=		EMACS=${EMACS_BIN:Q}
.endif

do-install:
	${INSTALL_DATA} ${WRKSRC}/*.el ${WRKSRC}/*.elc ${DESTDIR}${EMACS_LISPPREFIX}/nxml-mode
	${INSTALL_DATA} ${WRKSRC}/schema/*.rnc ${DESTDIR}${EMACS_LISPPREFIX}/nxml-mode/schema
	${INSTALL_DATA} ${WRKSRC}/schema/*.xml ${DESTDIR}${EMACS_LISPPREFIX}/nxml-mode/schema
	${INSTALL_DATA} ${WRKSRC}/char-name/unicode/*.el ${DESTDIR}${EMACS_LISPPREFIX}/nxml-mode/char-name/unicode
	${INSTALL_DATA} ${WRKSRC}/nxml-mode.info ${DESTDIR}${EMACS_INFOPREFIX}

.include "../../mk/bsd.pkg.mk"
