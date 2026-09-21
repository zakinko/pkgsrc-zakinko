# $NetBSD: Makefile,v 1.13 2022/05/14 22:25:41 dholland Exp $

DISTNAME=		nxml-mode-20041004
PKGREVISION=		4
CATEGORIES=		textproc editors
MASTER_SITES=		http://www.thaiopensource.com/download/

MAINTAINER=		tonio@NetBSD.org
HOMEPAGE=		http://www.thaiopensource.com/nxml-mode/
COMMENT=		Major mode for editing XML documents for emacs

NO_CONFIGURE=		yes
USE_TOOLS+=		makeinfo perl

# nxml-mode was written for Emacs 21 and is bundled since Emacs 23; the
# package is for emacs20, with devel/emacs20-compat supplying what Emacs 20
# lacks and files/nxml-e20.el the mode's own fontification (see the
# patches).  Emacs 20 needs Mule-UCS for decode-char.
EMACS_VERSIONS_ACCEPTED=	emacs20
DEPENDS+=		${EMACS_PKGNAME_PREFIX}Mule-UCS-[0-9]*:../../editors/mule-ucs

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

MESSAGE_SUBST+=		LISPDIR=${EMACS_LISPPREFIX:Q}
INSTALLATION_DIRS=	${EMACS_LISPPREFIX:Q}/nxml-mode/schema \
			${EMACS_LISPPREFIX:Q}/nxml-mode/char-name/unicode ${EMACS_INFOPREFIX:Q}

do-install:
	${INSTALL_DATA} ${WRKSRC}/*.el ${WRKSRC}/*.elc ${DESTDIR}${EMACS_LISPPREFIX:Q}/nxml-mode
	${INSTALL_DATA} ${WRKSRC}/schema/*.rnc ${DESTDIR}${EMACS_LISPPREFIX:Q}/nxml-mode/schema
	${INSTALL_DATA} ${WRKSRC}/schema/*.xml ${DESTDIR}${EMACS_LISPPREFIX:Q}/nxml-mode/schema
	${INSTALL_DATA} ${WRKSRC}/char-name/unicode/*.el ${DESTDIR}${EMACS_LISPPREFIX:Q}/nxml-mode/char-name/unicode
	${INSTALL_DATA} ${WRKSRC}/nxml-mode.info ${DESTDIR}${EMACS_INFOPREFIX:Q}

.include "../../devel/emacs20-compat/buildlink3.mk"
.include "../../editors/emacs/modules.mk"
.include "../../mk/bsd.pkg.mk"
