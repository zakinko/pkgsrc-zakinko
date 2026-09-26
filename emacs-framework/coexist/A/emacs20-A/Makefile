# $NetBSD: Makefile,v 1.68 2026/09/14 12:38:31 wiz Exp $

DISTNAME=	emacs-20.7
PKGNAME?=	${DISTNAME:S/emacs/emacs20/}
PKGREVISION=	28
CATEGORIES=	editors
MASTER_SITES=	http://ftp.gnu.org/pub/old-gnu/emacs/
MASTER_SITES+=	ftp://ftp.gnu.org/pub/old-gnu/emacs
DISTFILES=	${DISTNAME}${EXTRACT_SUFX}
DISTFILES+=	${DISTNAME}-mule-4.1b-elc${EXTRACT_SUFX}
SITES.${DISTNAME}-mule-4.1b-elc.tar.gz=	${MASTER_SITE_LOCAL}

# Mule enhancement (back port) patch by Satoshi Yatagawa
SITES.emacs-20.7-mule-4.1b.patch=	\
			http://www.teu.ac.jp/nsit/~yatagawa/comp/emacs/
PATCHFILES=		emacs-20.7-mule-4.1b.patch
# XIM fix patch by Seiichiro Inoue
SITES.emacs20-xim-20000713.diff=	\
			http://home.catv.ne.jp/pp/ginoue/software/emacs-xim/
PATCHFILES+=		emacs20-xim-20000713.diff

# dholland's jumbo patch
PATCHFILES+=		emacs20-jumbo-patch-20170723.gz
SITES.emacs20-jumbo-patch-20170723.gz= \
			http://www.NetBSD.org/~dholland/patchkits/emacs20/

MAINTAINER=	dholland@NetBSD.org
HOMEPAGE=	https://www.gnu.org/software/emacs/emacs.html
COMMENT=	GNU editing macros (editor)

# configure: error: Emacs hasn't been ported to `x86_64-apple-darwin17' systems.
BROKEN_ON_PLATFORM=	Darwin-*-* DragonFly-*-*

CONFLICTS=	mule-[0-9]*

GNU_CONFIGURE=		yes
USE_TOOLS+=		gmake
GNU_ARCH.mipsbe=	mips

MKPIE_SUPPORTED=	no

# build PATH in the dumped emacs is not a problem
CHECK_WRKREF_SKIP+=	bin/emacs
CHECK_WRKREF_SKIP+=	bin/emacs-20.7

.include "../../mk/bsd.prefs.mk"

# If using GNU ld 2.13.2.1 or later, avoid creating combined reloc
# sections and .data reloc sections, both of which Emacs can't handle
# properly.  Analyzed by Stephen Ma.
LDFLAGS+=	-Wl,-z,nocombreloc

.if (${OPSYS} == "NetBSD") && \
    !exists(/usr/lib/libgcc_s.so) && !exists(/usr/lib/libgcc.a)
# NetBSD with native Clang doesn't provide libgcc, everything is in libc.
pre-configure: fake-libgcc

fake-libgcc:
	${AR} q ${BUILDLINK_DIR}/lib/libgcc.a
.endif

# NetBSD < 5.99.24 uses termcap; afterwards terminfo. Emacs needs to be told.
.if (${OPSYS} == "NetBSD") && !exists(/usr/include/term.h)
CPPFLAGS+=	-D__NETBSD_USE_TERMCAP__
.endif

.if (${OPSYS} == "DragonFly") && exists(/usr/lib/crtn.o)
CPPFLAGS+=	-DDFLY_CRT_USRLIB
.endif

.include "options.mk"

MAKE_ENV+=	INSTALL_STRIP=${_STRIPFLAG_INSTALL:Q}

.include "../../mk/compiler.mk"
.if !empty(CC_VERSION:Mgcc-3.*)
CFLAGS+=	-fno-zero-initialized-in-bss
.endif

CFLAGS+=	-Wno-implicit-int
CFLAGS+=	-Wno-implicit-function-declaration
CFLAGS+=	-Wno-incompatible-pointer-types

.if !empty(PKGSRC_COMPILER:Mclang)
TOOL_DEPENDS+=	tradcpp-[0-9]*:../../devel/tradcpp
MAKEFILECPP=	${PREFIX}/bin/tradcpp
.else
MAKEFILECPP=	${CPP} -traditional-cpp
.endif
ALL_ENV+=	MAKEFILECPP=${MAKEFILECPP:Q}

# emacs-20.7/lib-src/etags.c: In function 'init':
# emacs-20.7/lib-src/etags.c:1208:35: error: array subscript has type 'char' [-Werror=char-subscripts]
#    for (sp = white; *sp; sp++) _wht[*sp] = TRUE;    _wht[0] = _wht['\n'];
#                                    ^
# Maybe fix this later.
BUILDLINK_TRANSFORM+=	rm:-Werror=char-subscripts

INFO_FILES=	yes

INSTALL_PROGRAM=	${INSTALL} ${COPY} -o ${BINOWN} -g ${BINGRP} -m ${BINMODE}

post-extract:
	${CP} ${FILESDIR}/amd64.h ${WRKSRC}/src/m
	${CP} ${FILESDIR}/dragonfly.h ${WRKSRC}/src/s

# lisp/files.el is patched, but the dumped emacs carries the files.elc
# from the distfile and temacs cannot load the source in its place, so
# compile it with the first dump and dump again.  loadup numbers the
# build from the emacs-20.7.* files left in src, so remove the first
# dump's output to keep the .1 names the PLIST expects.
post-build:
	cd ${WRKSRC}/lisp && ../src/emacs -batch -q --no-site-file \
		-f batch-byte-compile files.el
	cd ${WRKSRC} && ${RM} -f src/emacs src/emacs-${PKGVERSION_NOREV}.1 \
		etc/DOC-${PKGVERSION_NOREV}.1 lib-src/fns-${PKGVERSION_NOREV}.1.el
	cd ${WRKSRC}/src && ${BUILD_MAKE_CMD} emacs

pre-install:
	@${FIND} ${WRKSRC} -type f -name "*.orig*" -print | ${XARGS} ${RM} -f

# 同じ prefix に複数の Emacs を入れるとき用。configure が binary と man を
# 版付きにする。20.7 の Makefile.in は program_transform_name を受け取る
# だけで使っていないので、patch-ae と patch-ak が 22.3 の形を backport
# している。
#
# EMACS_TAG は X 版では版そのもの、nox 版 (emacs20-nox11) では -nox11 が
# 付き、nox 版は datadir と libexecdir も自分の場所へ移す。emacs30-A と
# 同じ形。
EMACS_TAG?=		20.7
# The transform is written without "$": configure copies it verbatim
# into TRANSFORM, and gmake reads "$/" in s/$/-20.7/ as a variable, so
# every renamed file came out of sed as "s/-20.7/" (unterminated).
CONFIGURE_ARGS+=	--program-transform-name='s/.*/&-${EMACS_TAG}/'
.if ${EMACS_TAG} != "20.7"
_EMACS_DATADIR=		share/emacs-${EMACS_TAG}
_EMACS_LIBEXEC=		libexec/emacs-${EMACS_TAG}
CONFIGURE_ARGS+=	--datadir=${PREFIX}/${_EMACS_DATADIR}
CONFIGURE_ARGS+=	--libexecdir=${PREFIX}/${_EMACS_LIBEXEC}
.else
_EMACS_DATADIR=		share
_EMACS_LIBEXEC=		libexec
.endif
GNU_CONFIGURE_INFODIR=	${PREFIX}/${_EMACS_DATADIR}/emacs/20.7/info
PLIST_SUBST+=		EMACS_VERSION=20.7
PLIST_SUBST+=		EMACS_TAG=${EMACS_TAG}
PRINT_PLIST_AWK+=	{ gsub(/${EMACS_TAG:S/./\./g}/, "$${EMACS_TAG}"); }
PRINT_PLIST_AWK+=	{ gsub(/20\.7/, "$${EMACS_VERSION}"); }

post-install:
	${CHOWN} -R ${SHAREOWN}:${SHAREGRP} ${DESTDIR}${PREFIX}/${_EMACS_DATADIR}/emacs
# The versioned copy sits beside it; the unversioned one would be the same
# file from every Emacs in the prefix, so only one package could own it.
	${RM} -f ${DESTDIR}${PREFIX}/${_EMACS_DATADIR}/emacs/site-lisp/subdirs.el

.include "../../mk/bsd.pkg.mk"
