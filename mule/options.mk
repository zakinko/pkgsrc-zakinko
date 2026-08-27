# $NetBSD: options.mk,v 1.1 2015/04/07 04:53:22 makoto Exp $

PKG_OPTIONS_VAR=	PKG_OPTIONS.mule
PKG_SUPPORTED_OPTIONS=	exclusive
PKG_SUGGESTED_OPTIONS=

.include "../../mk/bsd.options.mk"

PLIST_VARS+=	exclusive

# Set the exclusive option only when no other emacsen is installed: it
# keeps ctags, etags and emacsclient, which every emacs package installs
# under the same names.  emacs2[0-9]-[0-9]* is not enough to catch them;
# it misses emacs30 and emacs31, and it misses the names that carry
# -nox11 in the middle.
.if !empty(PKG_OPTIONS:Mexclusive)
PLIST.exclusive=	YES
CONFLICTS+=	emacs-[0-9]* emacs-nox11-[0-9]* emacs[0-9]*-[0-9]*
.else
post-install:
	(cd ${DESTDIR}${PREFIX}; \
	${RM} bin/emacsclient bin/ctags bin/etags; \
	)
.endif
