# $NetBSD: Makefile,v 1.47 2026/09/25 09:48:05 wiz Exp $

DISTNAME=	apel-10.8.0.20250531
PKGNAME=	${EMACS_PKGNAME_PREFIX}${DISTNAME}
CATEGORIES=	devel
MASTER_SITES=	${MASTER_SITE_GITHUB:=wanderlust/}
GITHUB_PROJECT=	apel
GITHUB_TAG=	2383abfd3a27c094ae9095b05103167cf810379b

MAINTAINER=	uebayasi@NetBSD.org
HOMEPAGE=	http://git.chise.org/elisp/apel/
COMMENT=	Portable Emacs library
LICENSE=	gnu-gpl-v2 OR gnu-gpl-v3

INSTALLATION_DIRS+=	${EMACS_LISPPREFIX:C|^${PREFIX}/||}/apel

PLIST_SRC=	${PKGDIR}/PLIST.${EMACS_FLAVOR}
BUILD_TARGET=	${BUILD_TARGET.${EMACS_FLAVOR}}
INSTALL_TARGET=	${INSTALL_TARGET.${EMACS_FLAVOR}}
MAKE_FLAGS+=	EMACS=${EMACS_BIN:Q}
MAKE_FLAGS+=	LISPDIR=${EMACS_LISPPREFIX:Q}
MAKE_FLAGS+=	VERSION_SPECIFIC_LISPDIR=${EMACS_LISPPREFIX:Q}
MAKE_FLAGS+=	${MAKE_FLAGS.${EMACS_FLAVOR}}

# xemacs-packages carries an older apel (no detect-mime-charset-string), and
# flim 1.14.9 needs this one, so XEmacs is accepted here too.
EMACS_VERSIONS_ACCEPTED+=	emacs29 emacs29nox
EMACS_VERSIONS_ACCEPTED+=	emacs30 emacs30nox
EMACS_VERSIONS_ACCEPTED+=	emacs31 emacs31nox
EMACS_VERSIONS_ACCEPTED+=	emacs20 xemacs214 xemacs214nox xemacs215 xemacs215nox

BUILD_TARGET.emacs=	elc
BUILD_TARGET.xemacs=	package
INSTALL_TARGET.emacs=	install
INSTALL_TARGET.xemacs=	install-package
MAKE_FLAGS.emacs=
MAKE_FLAGS.xemacs=	XEMACS=${EMACS_BIN:Q} \
			PACKAGEDIR=${EMACS_LISPPREFIX:C|/lisp$||}

# The compatibility layer for Emacs 20 and XEmacs that upstream removed in
# 2020 comes back through the patches and these files.
post-extract:
	${CP} ${FILESDIR}/*.el ${WRKSRC}/

.include "../../editors/emacs/modules.mk"

# XEmacs gets everything in one package directory; emu/ is GNU Emacs only.
.if ${EMACS_FLAVOR} == "emacs"
INSTALLATION_DIRS+=	${EMACS_LISPPREFIX:C|^${PREFIX}/||}/emu
.endif

PLIST_VARS+=	emacs23 emacs19
.if ${EMACS_FLAVOR} != "xemacs"
.  if ${EMACS_VERSION_MAJOR} >= 23
PLIST.emacs23=	yes
.  else
PLIST.emacs19=	yes
.  endif
.endif

# Pkgsrc developers should run "install" without this and check if PLIST is
# correct.  Users just need to install files.
do-install: plist
	cd ${WRKSRC};							\
	for subdir in emu apel; do					\
		grep -v '^@' ${PLIST} | grep "/$$subdir/" |		\
		while read file; do					\
			file=$$( basename $$file );			\
			${INSTALL_DATA} $$file				\
			    ${DESTDIR}${EMACS_LISPPREFIX}/$$subdir/$$file; \
		done							\
	done

# XEmacs packages carry their autoloads and custom dependencies in
# auto-autoloads.el and custom-load.el; upstream's install-package target
# generates them into the installed directory, so do the same here.
.if ${EMACS_FLAVOR} == "xemacs"
post-install:
	cd ${WRKSRC} && ${SETENV} ${MAKE_ENV} ${EMACS_BIN} -batch -q -no-site-file \
	    -l APEL-MK -eval '(progn (config-apel-package)		\
		(install-update-package-files "apel"			\
		    "${DESTDIR}${EMACS_LISPPREFIX}/apel" nil))' NONE
.endif
.include "../../mk/bsd.pkg.mk"
