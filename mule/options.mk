# $NetBSD: options.mk,v 1.1 2015/04/07 04:53:22 makoto Exp $

PKG_OPTIONS_VAR=	PKG_OPTIONS.mule
PKG_SUPPORTED_OPTIONS=	canna exclusive wnn4
PKG_SUGGESTED_OPTIONS=	canna wnn4

.include "../../mk/bsd.options.mk"

PLIST_VARS+=	exclusive

# Wnn and Canna are compiled into the dumped binary, and the tree carries
# both: src/canna.c and lisp/canna.el are there, and src/mconfig.h-netbsd
# ships with WNN4 defined and CANNA commented out.  Flip the two defines
# from the options instead of keeping a patch per combination.  The paths
# in those defines are already turned into @PREFIX@ by
# patch-src_mconfig.h-netbsd.
.if !empty(PKG_OPTIONS:Mwnn4)
.include "../../inputmethod/ja-freewnn-lib/buildlink3.mk"
.else
# EGG has to go with it.  lisp/loadup.el, which builds the dumped image,
# says: if EGG is defined then WNN4 or SJ3 must be too, and errors out
# otherwise -- the dump dies with "You should define WNN4 or SJ3 in
# mconfig.h."  CANNA is asked for separately on the line below that, so it
# is unaffected.  ymakefile has carried a MULE_OBJ arm for the no-EGG case
# since 1992.
SUBST_CLASSES+=		wnn4
SUBST_STAGE.wnn4=	pre-configure
SUBST_MESSAGE.wnn4=	Turning Wnn and Egg support off
SUBST_FILES.wnn4=	src/mconfig.h-netbsd
SUBST_SED.wnn4=		-e 's,^\#define WNN4$$,/* \#define WNN4 */,'
SUBST_SED.wnn4+=	-e 's,^\#define EGG$$,/* \#define EGG */,'
.endif

# CANNA3_7 enables the APIs Canna grew in 3.7; pkgsrc ships 3.8.
.if !empty(PKG_OPTIONS:Mcanna)
.include "../../inputmethod/canna-lib/buildlink3.mk"
SUBST_CLASSES+=		canna
SUBST_STAGE.canna=	pre-configure
SUBST_MESSAGE.canna=	Turning Canna support on
SUBST_FILES.canna=	src/mconfig.h-netbsd
SUBST_SED.canna=	-e 's,^/\* \#define CANNA \*/$$,\#define CANNA,'
SUBST_SED.canna+=	-e 's,^/\* \#define CANNA3_7 \*/$$,\#define CANNA3_7,'
.endif

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
