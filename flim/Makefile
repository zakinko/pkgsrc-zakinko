# $NetBSD: Makefile,v 1.47 2026/09/25 09:48:06 wiz Exp $

DISTNAME=	flim-1.14.9
PKGNAME=	${EMACS_PKGNAME_PREFIX}${DISTNAME}
PKGREVISION=	7
CATEGORIES=	devel
MASTER_SITES=	#

MAINTAINER=	tech-pkg-ja@jp.NetBSD.org
#HOMEPAGE=	http://git.chise.org/elisp/flim/
COMMENT=	Emacs lisp library for message representation/encoding
LICENSE=	gnu-gpl-v2 OR gnu-gpl-v3

TOOL_DEPENDS+=	qkc-[0-9]*:../../converters/qkc

INSTALLATION_DIRS+=	${EMACS_LISPPREFIX:C|^${PREFIX}/||}/flim \
			${EMACS_INFOPREFIX:C|^${PREFIX}/||}

BUILD_TARGET=	${BUILD_TARGET.${EMACS_FLAVOR}}
INSTALL_TARGET=	${INSTALL_TARGET.${EMACS_FLAVOR}}
MAKEFLAGS=	${MAKEFLAGS.${EMACS_FLAVOR}}

USE_TOOLS+=	makeinfo
INFO_FILES=	yes
TEXINFO_REQD=	4.5

BUILD_TARGET.emacs=	elc
BUILD_TARGET.xemacs=	package
INSTALL_TARGET.emacs=	install
INSTALL_TARGET.xemacs=	install-package
MAKEFLAGS.emacs+=	EMACS=${EMACS_BIN}
MAKEFLAGS.xemacs+=	XEMACS=${EMACS_BIN} \
			PACKAGEDIR=${EMACS_LISPPREFIX:C|/lisp$||}

EMACS_MODULES=		base
EMACS_BUILDLINK=	# empty

# Emacs 22 and later have hmac-def.el; Emacs 20 needs the copy in the distfile.
post-patch:
	${TEST} ${EMACS_VERSION_MAJOR} -lt 22 || ${RM} -f ${WRKSRC}/hmac-def.el
	${RM} -f ${WRKSRC}/hex-utile.el

pre-configure:
	${MKDIR} -p ${WRKDIR}/.home/.emacs.d/elpa
	find ${WRKSRC} -name \*orig | xargs rm

post-build:
	cd ${WRKSRC}; for i in mime-en mime-ja; do			\
		makeinfo --force --no-validate $${i}.texi;		\
	done

do-install: plist
	cd ${WRKSRC};							\
	${GREP} -v '^@' ${PLIST} | ${EGREP} '/site-(packages/)?lisp/flim/' | \
	while read file; do						\
		file=$$( basename $$file );				\
		${INSTALL_DATA} $$file					\
		    ${DESTDIR}${EMACS_LISPPREFIX}/flim/$$file;		\
	done

post-install:
	cd ${WRKSRC}; for f in mime-*.info mime-*.info-[0-9]*; do	\
		${TEST} ! -f "$$f" ||					\
		${INSTALL_DATA} "$$f" ${DESTDIR}${EMACS_INFOPREFIX};	\
	done

.include "../../editors/emacs/modules.mk"

# post-patch keeps hmac-def.el before Emacs 22, but it was not in the
# PLIST, so it was never installed and hmac-md5, hmac-sha1 and sasl-cram
# could not be loaded on Emacs 20.
PLIST_VARS+=	hmacdef
.if ${EMACS_VERSION_MAJOR} < 22
PLIST.hmacdef=	yes
.endif

# cl-lib is bundled since Emacs 24.3
.if ${EMACS_VERSION_MAJOR} < 24
.include "../../zakinko/cl-lib-el/buildlink3.mk"
.endif

# xemacs-packages carries an apel too old for this flim (no
# detect-mime-charset-string), so devel/apel is required on XEmacs as well.
BUILDLINK_API_DEPENDS.apel+=	${EMACS_PKGNAME_PREFIX}apel>=10.8
.include "../../zakinko/apel/buildlink3.mk"

.include "../../mk/bsd.pkg.mk"
