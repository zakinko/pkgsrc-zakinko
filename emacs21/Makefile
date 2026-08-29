# $NetBSD: Makefile,v 1.51 2025/08/30 22:44:55 wiz Exp $

PKGREVISION=	52
CATEGORIES=	editors

CONFLICTS+=	emacs21-nox11-[0-9]*

USE_TOOLS+=	imake

MKPIE_SUPPORTED=	no

.include "options.mk"

.include "../../zakinko/emacs21/Makefile.common"

# Emacs reads site-lisp/site-start.el at startup, before ~/.emacs, because
# site-run-file is "site-start" and site-lisp is on load-path.  pkgsrc has had
# no such file, so every elisp package told the user to paste autoloads into
# their own .emacs by hand.  This one loads whatever packages left in
# site-lisp/site-start.d, so they can register themselves instead.
post-install: site-start
.PHONY: site-start
site-start:
	${INSTALL_DATA} ${FILESDIR}/site-start.el \
		${DESTDIR}${PREFIX}/share/emacs/site-lisp/site-start.el

.include "../../mk/bsd.pkg.mk"
