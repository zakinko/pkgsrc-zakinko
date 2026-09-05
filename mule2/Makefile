# $NetBSD$

DISTNAME=	mule-2.3
PKGNAME=	${DISTNAME:S/mule/mule2/}
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

CONFLICTS=	emacs-[0-9]* emacs-nox11-[0-9]* emacs[0-9]*-[0-9]* mule-[0-9]*

# build PATH in the dumped mule is not a problem
CHECK_WRKREF_SKIP+=	bin/mule
CHECK_WRKREF_SKIP+=	bin/mule-19.28

WRKSRC=			${WRKDIR}/mule
USE_TOOLS+=		gmake makeinfo yacc
GNU_CONFIGURE=		yes
GNU_CONFIGURE_MANDIR=	${PREFIX}/${PKGMANDIR}/man1
GNU_CONFIGURE_STRICT=	no # everything ok, just ancient

# temacs dumps itself with unexec(), which rewrites its own ELF image.
# PIE relocates that image and RELRO write-protects what unexec() patches.
MKPIE_SUPPORTED=	no
RELRO_SUPPORTED=	no
# _FORTIFY_SOURCE does not survive the pre-ANSI string handling here.
FORTIFY_SUPPORTED=	no

# 1995 年の K&R C なので、方言を名指ししておく。C23 は f() を「引数不明」
# ではなく f(void) と読むので、既定が C23 の gcc 15 では
#
#   struct tm *localtime ();
#
# のような宣言に引数を渡した所が全部エラーになる。この木は lisp.h だけで
# 694 本の宣言をこの形で持っている。pkgsrc の FORCE_C_STD が採るのは
# c89 c99 c11 gnu89 gnu99 gnu11 で、gnu17 は無い。gnu11 で足りる。
FORCE_C_STD=		gnu11

.include "../../mk/bsd.prefs.mk"

# Fedora や Debian の gcc は --enable-default-pie で建っているので、黙って
# いると PIE を作る。unexec は自分の ELF を読み直して書き換えることで dump
# するので、PIE では成立せず、temacs が Lisp を読み終えた直後に落ちる。
#
# pkgsrc の MKPIE_SUPPORTED=no は「pkgsrc の側が -fPIE を足さない」という
# 意味しか持たず、コンパイラ既定の PIE までは止めない。ここで明示する。
.if ${OPSYS} == "Linux"
CFLAGS+=	-fno-pie -no-pie
LDFLAGS+=	-no-pie
.endif

CFLAGS+=	-g -fno-strict-aliasing
# alloc.c hooks the allocator and unhooks itself around the real call.
# Treated as builtins, GCC drops that store and the hook recurses forever.
CFLAGS+=	-fno-builtin-malloc -fno-builtin-realloc -fno-builtin-free
# GCC 10 and later default to -fno-common; this tree predates that.
CFLAGS+=	-fcommon

CONFIGURE_ARGS+=	${MACHINE_ARCH}--${LOWER_OPSYS}
CONFIGURE_ARGS+=	--terminal-face --mcpath --canna-libraries=${PREFIX}/lib
# VALBITS は Lisp_Object のうち値に使う幅で、残りが型と mark bit になる。
# 26 は 32bit 機の値。64bit 機にこれを渡すと、64bit のポインタが 26bit に
# 切り詰められ、heap が 64MB を越えた所で壊れる。NetBSD/amd64 で今まで
# 動いていたのは、そこまで伸びなかったからにすぎない。Fedora では起動中に
# 越えて init_obarray で落ちる。
#
# 元は alpha と sparc64 だけを外していた。2000 年当時に知られていた 64bit
# 機がその二つだったため。pkgsrc は LP64PLATFORMS を持っているので、機種を
# 数え上げずにそちらを使う。
.if empty(LP64PLATFORMS:@.P.@${MACHINE_PLATFORM:M${.P.}}@)
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
# OpenBSD 用の s/ が木に無い。configure に腕を足すだけでは足りないので
# ここで置く。中身は s/netbsd.h を土台に、名前と crypt の扱いだけ変えた物。
	${CP} ${FILESDIR}/openbsd.h ${WRKSRC}/src/s/openbsd.h

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

# termcap の API を持つ library を pkgsrc に用意させる。s/linux.h は
# -ltermcap -lcurses を、s/freebsd.h は -ltermcap を名指ししていたが、
# Debian の箱にも GhostBSD にもその名前は無い。curses.buildlink3.mk は
# 在るものを使い、無ければ devel/ncurses を建てて path も通す。
.include "../../mk/curses.buildlink3.mk"

# termcap の library の名前は系によって違う。s/linux.h は -ltermcap と
# -lcurses を、s/freebsd.h は -ltermcap を直書きしているが、Debian の箱にも
# GhostBSD にもその名前は無い。curses.buildlink3.mk が決めた名前を埋める。
SUBST_CLASSES+=		curses
SUBST_STAGE.curses=	pre-configure
SUBST_MESSAGE.curses=	Use the curses library pkgsrc picked
SUBST_FILES.curses=	src/s/linux.h src/s/freebsd.h
SUBST_SED.curses=	-e 's|^\#define LIBS_TERMCAP .*|\#define LIBS_TERMCAP ${BUILDLINK_LDADD.curses}|'
.include "../../mk/bsd.pkg.mk"
