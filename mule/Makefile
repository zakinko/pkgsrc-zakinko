# $NetBSD: Makefile,v 1.10 2015/04/08 14:58:25 makoto Exp $

MULEVERSION=		1.1
EMACSVERSION=		18.59
SNAPSHOTDATE=		20260622
DISTNAME=		${GITHUB_PROJECT}
PKGNAME=		mule-${MULEVERSION}pl${SNAPSHOTDATE}
CATEGORIES=		zakinko editors
MASTER_SITES=		${MASTER_SITE_GITHUB:=tsutsui/}
GITHUB_PROJECT=		mule1.1-netbsd
GITHUB_TAG=		${SNAPSHOTDATE}

MAINTAINER=		makoto@ki.nu
HOMEPAGE=		https://github.com/tsutsui/mule1.1-netbsd
COMMENT=		Classical Mule (MULtilingual Enhancement of GNU Emacs), based on 18.59
#unexelf.c is pulled from emacs22
LICENSE=		gnu-gpl-v1 AND gnu-gpl-v2

CONFLICTS=		emacs19-[0-9]* emacs2[0-9]-[0-9]* mule2-[0-9]*

MAKE_JOBS_SAFE=		no

# temacs dumps itself with unexec(), which rewrites its own image.
# PIE relocates that image and RELRO write-protects what unexec() patches.
# Without these the build reaches "Dumping under names xemacs" and dies
# there with SIGSEGV.  Same as zakinko/mule2.
MKPIE_SUPPORTED=	no
RELRO_SUPPORTED=	no
# _FORTIFY_SOURCE does not survive the pre-ANSI string handling here.
FORTIFY_SUPPORTED=	no

WRKSRC=			${WRKDIR}/${GITHUB_PROJECT}-${SNAPSHOTDATE}
USE_TOOLS=		gmake pax

# this chunk should be before SUBST_CLASSES= pref
SUBST_CLASSES+=		path
SUBST_MESSAGE.path=	Convert mule LIBDIR path
SUBST_STAGE.path=	pre-configure
SUBST_VARS.path=	PREFIX VARBASE EMACSVERSION
SUBST_FILES.path=	Makefile src/paths.h-dist src/mconfig.h-netbsd

SUBST_CLASSES+=		pref
SUBST_MESSAGE.pref=	Convert /usr/local to ${PREFIX}
SUBST_STAGE.pref=	pre-configure
SUBST_SED.pref=		-e 's,/usr/local,${PREFIX},g'
SUBST_FILES.pref=	\
	Makefile \
	build-install \
	etc/FAQ \
	etc/FAQ.jp \
	etc/MACHINES \
	etc/m2ps.1-dist \
	etc/mule.1-dist \
	info/canna-jp \
	info/egg-jp-2 \
	info/emacs-11 \
	info/emacs-13 \
	lisp/paths.el \
	man/canna-jp.texi \
	man/egg-jp.texi \
	man/emacs.texi \
	src/m-ibmps2-aix.h \
	src/mconfig.h-dist \
	src/ymakefile

SUBST_CLASSES+=		x11
SUBST_MESSAGE.x11=	Convert /usr/X11R7 to ${X11BASE}
SUBST_STAGE.x11=	pre-configure
SUBST_SED.x11=		-e 's,/usr/X11R7,${X11BASE},g'
SUBST_FILES.x11=	src/s-netbsd.h

REPLACE_PERL=		etc/faq2texi.perl

# build PATH in the dumped emacs may not be a problem
CHECK_WRKREF_SKIP+=     bin/mule

INSTALLATION_DIRS+=	bin ${PKGMANDIR}/man1 share/mule/${EMACSVERSION}
MAKE_DIRS+=		${VARBASE}/lock ${VARBASE}/lock/mule
MAKE_DIRS_PERMS+=	${VARBASE}/lock/mule \
			${REAL_ROOT_USER} ${REAL_ROOT_GROUP} 1777
BUILD_DEFS+=		VARBASE

.include	"../../mk/bsd.prefs.mk"

do-configure:
	(cd ${WRKSRC}; \
	${CP} src/config.h-${LOWER_OPSYS}  \
	      src/config.h ; \
	${CP} src/mconfig.h-${LOWER_OPSYS} src/mconfig.h; \
	${SED} -e 's,^;(load "japanese"),(load "japanese"),g' \
		< lisp/mule-init.el > lisp/site-init.el; \
	)

do-install:
	cd ${WRKSRC} && \
		pax -rwpp -s '/.*\.orig//' etc info lisp \
	${DESTDIR}${PREFIX}/share/mule/${EMACSVERSION}
	${INSTALL_PROGRAM} ${WRKSRC}/etc/ctags ${DESTDIR}${PREFIX}/bin
	${INSTALL_PROGRAM} ${WRKSRC}/etc/emacsclient ${DESTDIR}${PREFIX}/bin
	${INSTALL_PROGRAM} ${WRKSRC}/etc/etags ${DESTDIR}${PREFIX}/bin
	${INSTALL_PROGRAM} ${WRKSRC}/etc/m2ps ${DESTDIR}${PREFIX}/bin
	${INSTALL_PROGRAM} ${WRKSRC}/src/xemacs ${DESTDIR}${PREFIX}/bin/mule
	${INSTALL_MAN} ${WRKSRC}/etc/mule.1 ${DESTDIR}${PREFIX}/${PKGMANDIR}/man1
	${INSTALL_MAN} ${WRKSRC}/etc/m2ps.1 ${DESTDIR}${PREFIX}/${PKGMANDIR}/man1

.include "options.mk"

.include "../../inputmethod/ja-freewnn-lib/buildlink3.mk"
.include "../../mk/x11.buildlink3.mk"
.include "../../mk/bsd.pkg.mk"
