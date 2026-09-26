# $NetBSD$
#

DISTNAME=	pcl-cvs-2.9.9
PKGNAME=	${EMACS_PKGNAME_PREFIX}${DISTNAME}
PKGREVISION=	5
CATEGORIES=	devel scm
MASTER_SITES=	# ftp://rum.cs.yale.edu/pub/monnier/pcl-cvs/

MAINTAINER=	pkgsrc-users@NetBSD.org
#HOMEPAGE=
COMMENT=	Front-end to CVS for emacs
LICENSE=	gnu-gpl-v2

DEPENDS+=	emacs20-elib>=1.0:../../devel/emacs20-elib

# emacs20 only.  emacs21 carries pcl-cvs itself, but under different names
# (info/pcl-cvs and lisp/pcvs-*.el, against info/pcl-cvs.info and
# site-lisp/pcl-cvs/ here), so nothing actually collides and there is no
# CONFLICTS to state.  Two were stated and neither matched anything: the
# package has been called emacs21-21.4a for a long time, not emacs-21.*,
# and "emacs21" alone is not a package pattern at all.
EMACS_VERSIONS_ACCEPTED=	emacs20

.include "../../editors/emacs/modules.mk"

# There used to be a second PKG_FAIL_REASON here, for EMACS_FLAVOR != emacs or
# EMACS_VERSION_MAJOR != 20.  modules.mk already sets one from the line above:
#
#	.if empty(EMACS_VERSIONS_ACCEPTED:M${_EMACS_TYPE})
#	PKG_FAIL_REASON+=	"Accepted versions are: ${EMACS_VERSIONS_ACCEPTED}"
#
# and with emacs20 the only accepted type, the two conditions are the same
# one -- emacs20 is the emacs flavour at major 20 and nothing else is.  The
# duplicate only added a second line to the same failure.

# The bundled makefile installs with $(PREFIX) in front of every path, so it
# has to be told about DESTDIR.  MAKE_ENV cannot do it: pkgsrc puts its own
# PREFIX=${PREFIX} into the environment after everything a package adds, and
# the later one wins, so the package's line had no effect and the install ran
# straight into the live ${PREFIX}.  What that produced was not a clean
# failure -- 19 files and three info files landed under /usr/pkg, owned by no
# package, and only then did pkg_create complain that the destdir was empty.
# Flags on the command line beat the environment, so pass it there instead.
INSTALL_MAKE_FLAGS+=	PREFIX=${DESTDIR}${PREFIX}
BUILD_TARGET=	default
INFO_FILES=	yes

.include "../../mk/bsd.pkg.mk"
