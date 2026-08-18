# $NetBSD$

DISTNAME=	mule-2.3
PKGREVISION=	11
CATEGORIES=	zakinko editors
# ftp.m17n.org is gone; the KAIST archive still has a byte-identical copy.
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

# temacs dumps itself with unexec(), which rewrites its own ELF image.
# PIE relocates that image and RELRO write-protects what unexec() patches.
MKPIE_SUPPORTED=	no
RELRO_SUPPORTED=	no
# _FORTIFY_SOURCE does not survive the pre-ANSI string handling here.
FORTIFY_SUPPORTED=	no

.include "../../mk/bsd.prefs.mk"

CFLAGS+=	-g -fno-strict-aliasing
# alloc.c hooks the allocator and unhooks itself around the real call.
# Treated as builtins, GCC drops that store and the hook recurses forever.
CFLAGS+=	-fno-builtin-malloc -fno-builtin-realloc -fno-builtin-free
# GCC 10 and later default to -fno-common; this tree predates that.
CFLAGS+=	-fcommon

CONFIGURE_ARGS+=	${MACHINE_ARCH}--${LOWER_OPSYS}
CONFIGURE_ARGS+=	--terminal-face --mcpath --canna-libraries=${PREFIX}/lib
.if ${MACHINE_ARCH} != "alpha" && ${MACHINE_ARCH} != "sparc64"
CONFIGURE_ARGS+=	--valbits=26
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
# Recompile the non-dumped lisp we patched (ledit, medit, mailpost,
# find-gc): the build only rebuilds the dumped .elc set, so the shipped
# .elc would shadow our patched .el at load time.
post-build:
	cd ${WRKSRC}/src && ./emacs -batch -q -f batch-byte-compile \
		../lisp/ledit.el ../lisp/medit.el ../lisp/mailpost.el ../lisp/find-gc.el
	${FIND} ${WRKSRC} -name "*.orig" | ${XARGS} ${RM} -f

# Fix character mapping for pkgsrc/fonts/intlfonts
post-install:
	${SED} \
		-e 's/etl\([0-9]*\)-latin1/lt1-40-etl/' \
		-e 's/etl\([0-9]*\)-latin\([0-9]\)/lt\2-\1-etl/' \
		-e 's/jiskan24/j83-48/' \
		< ${WRKSRC}/etc/CHARSETS > ${DESTDIR}${PREFIX}/lib/mule/19.28/etc/CHARSETS
	#diff -u		${WRKSRC}/etc/CHARSETS ${DESTDIR}${PREFIX}/lib/mule/19.28/etc/CHARSETS
.if !empty(PKG_OPTIONS:Mwnn4)
# egg wants a startup file called "eggrc"; upstream ships only the
# eggrc-wnn and eggrc-sj3 candidates and leaves the choice to the installer.
	${INSTALL_DATA} ${DESTDIR}${PREFIX}/lib/mule/19.28/lisp/eggrc-wnn \
		${DESTDIR}${PREFIX}/lib/mule/19.28/lisp/eggrc
.endif

.include "../../mk/bsd.pkg.mk"
