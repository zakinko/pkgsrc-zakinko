# $NetBSD: Makefile,v 1.55 2020/05/31 16:12:10 rillig Exp $

DISTNAME=	mule-2.3
PKGREVISION=	10
CATEGORIES=	zakinko editors
# ftp.m17n.org has been gone for years; the KAIST hangul archive still
# carries a byte-identical copy.
MASTER_SITES=	http://ftp.kaist.ac.kr/hangul/mirror/mule/
MASTER_SITES+=	ftp://ftp.m17n.org/pub/mule/

MAINTAINER=	zakinko@snowrabbit.org
HOMEPAGE=	http://www.m17n.org/mule/
COMMENT=	Multilingual GNU editing macros (editor)
LICENSE=	gnu-gpl-v2

MAKE_JOBS_SAFE=		no

CONFLICTS=	emacs-[0-9]*

# build PATH in the dumped mule is not a problem
CHECK_WRKREF_SKIP+=	bin/mule
CHECK_WRKREF_SKIP+=	bin/mule-19.28

WRKSRC=			${WRKDIR}/mule
USE_TOOLS+=		gmake makeinfo
GNU_CONFIGURE=		yes
GNU_CONFIGURE_MANDIR=	${PREFIX}/${PKGMANDIR}/man1
GNU_CONFIGURE_STRICT=	no # everything ok, just ancient

# temacs dumps itself with unexec(), which rewrites the ELF image of the
# running process so that the initialised data segment can be restored
# verbatim at startup.  Each of these hardening features either relocates
# that image or write-protects the part of it unexec() has to patch, so
# they all have to stay off for the dump to survive.
MKPIE_SUPPORTED=	no
RELRO_SUPPORTED=	no
# _FORTIFY_SOURCE's __builtin_object_size checks do not survive contact
# with the pre-ANSI string handling in this tree.
FORTIFY_SUPPORTED=	no

.include "../../mk/bsd.prefs.mk"

CFLAGS+=	-g -fno-builtin-malloc -fno-strict-aliasing
# GCC 10, which is what NetBSD 10 ships as the base compiler, made
# -fno-common the default.  This tree predates that convention and has
# tentative definitions of the same global in several translation units.
CFLAGS+=	-fcommon

CONFIGURE_ARGS+=	${MACHINE_ARCH}--${LOWER_OPSYS}
CONFIGURE_ARGS+=	--terminal-face --mcpath --canna-libraries=${PREFIX}/lib

# --valbits only takes effect when the src/m/ file leaves VALBITS
# undefined, which is the case for both intel386 and amd64.  VALBITS=26
# caps every Lisp pointer at 26 bits, i.e. the entire Lisp heap has to
# live below 64MB.  That has held so far, but if a dumped mule starts
# faulting on truncated pointers, set MULE_VALBITS= (empty) and let
# src/lisp.h pick its own default: 24 on ILP32, 56 on LP64.
MULE_VALBITS?=	26
.if ${MACHINE_ARCH} != "alpha" && ${MACHINE_ARCH} != "sparc64" && \
    !empty(MULE_VALBITS)
CONFIGURE_ARGS+=	--valbits=${MULE_VALBITS}
.endif

.include "options.mk"

INFO_FILES=	yes

INSTALL_MAKE_FLAGS=	prefix=${DESTDIR}${PREFIX}
INSTALL_MAKE_FLAGS+=	infodir=${DESTDIR}${GNU_CONFIGURE_INFODIR}
INSTALL_MAKE_FLAGS+=	mandir=${DESTDIR}${GNU_CONFIGURE_MANDIR}

# Remove .orig files in the original tar archive
post-extract:
	rm -f ${WRKSRC}/lisp/*.orig

# Remove original versions of patched files so that aren't installed.
post-build:
	${FIND} ${WRKSRC} -name "*.orig" | ${XARGS} ${RM} -f

# Fix character mapping for pkgsrc/fonts/intlfonts
post-install:
	${SED} \
		-e 's/etl\([0-9]*\)-latin1/lt1-40-etl/' \
		-e 's/etl\([0-9]*\)-latin\([0-9]\)/lt\2-\1-etl/' \
		-e 's/jiskan24/j83-48/' \
		< ${WRKSRC}/etc/CHARSETS > ${DESTDIR}${PREFIX}/lib/mule/19.28/etc/CHARSETS
	#diff -u		${WRKSRC}/etc/CHARSETS ${DESTDIR}${PREFIX}/lib/mule/19.28/etc/CHARSETS

.include "../../mk/bsd.pkg.mk"
