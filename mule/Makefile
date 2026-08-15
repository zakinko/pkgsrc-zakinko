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

CFLAGS+=	-g -fno-strict-aliasing

# alloc.c installs __malloc_hook, __realloc_hook and __free_hook, and each
# hook unhooks itself, calls the real allocator, then hooks itself back.
# That only works if the compiler treats the allocator call as something
# that might read the hook variable.  GCC knows all three as builtins that
# do not read global memory, so it drops the first store as dead and the
# hook recurses into itself until the stack runs out.  Only -fno-builtin-
# malloc was listed here, which left free and realloc exposed; verified on
# NetBSD/i386 with GCC 7.5, where the store before `call free' is simply
# absent from the generated emacs_blocked_free.
CFLAGS+=	-fno-builtin-malloc -fno-builtin-realloc -fno-builtin-free
# GCC 10, which is what NetBSD 10 ships as the base compiler, made
# -fno-common the default.  This tree predates that convention and has
# tentative definitions of the same global in several translation units.
CFLAGS+=	-fcommon

CONFIGURE_ARGS+=	${MACHINE_ARCH}--${LOWER_OPSYS}
CONFIGURE_ARGS+=	--terminal-face --mcpath --canna-libraries=${PREFIX}/lib

# --valbits is only consulted when the src/m/ file leaves VALBITS
# undefined, and on NetBSD both of ours do: intel386.h only sets it under
# #ifdef XENIX, and amd64.h keeps its own under an #if 0.  So this flag is
# what actually decides VALBITS here.  src/config.h then derives
# GCTYPEBITS as 32 - VALBITS - 1, which for 26 gives 5 and puts the mark
# bit at 31 -- the right layout for ILP32, and verified in config.h on
# NetBSD/i386.
#
# The catch is that 26 caps every Lisp pointer at 26 bits, so the whole
# Lisp heap has to live below 64MB.  That is no constraint on i386, but on
# LP64 it throws away the address space that LONG_LISP_OBJECT exists to
# reach.  If a dumped mule there starts faulting on truncated pointers,
# raise MULE_VALBITS rather than hunting for the fault.
MULE_VALBITS?=	26
.if ${MACHINE_ARCH} != "alpha" && ${MACHINE_ARCH} != "sparc64" && \
    !empty(MULE_VALBITS)
CONFIGURE_ARGS+=	--valbits=${MULE_VALBITS}
.endif

.include "options.mk"

# The texinfo here is from 1994 and uses markup that makeinfo has since
# turned from warnings into errors: @itemx that does not follow its @item,
# TeX comments taken as text, an @ignore nested inside another.  makeinfo
# then refuses to write the file and the man stage takes the build down.
#
# --force writes the output anyway, which is what the makeinfo of the day
# did.  It produces byte-identical files to hand-correcting the markup,
# tried on all eight targets, and it does not require guessing where a 1994
# author meant an unterminated @ignore to end.
MAKEINFO_CMD=	makeinfo --force
MAKE_FLAGS+=	MAKEINFO=${MAKEINFO_CMD:Q}

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
.if !empty(PKG_OPTIONS:Mwnn4)
# egg looks for ~/.eggrc and then for a file literally called "eggrc" on
# the load-path, but upstream only ships the two candidates eggrc-wnn and
# eggrc-sj3 and leaves the choice to whoever installs.  With neither name
# present egg stops at "egg-startup-file がありません" before it registers
# a single dictionary, which makes Wnn input unusable out of the box.  We
# built against Wnn, so eggrc-wnn is the one that belongs here.
	${CP} ${DESTDIR}${PREFIX}/lib/mule/19.28/lisp/eggrc-wnn \
		${DESTDIR}${PREFIX}/lib/mule/19.28/lisp/eggrc
.endif

.include "../../mk/bsd.pkg.mk"
