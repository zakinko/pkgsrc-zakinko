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

MAKE_ENV+=	PREFIX=${DESTDIR}${PREFIX}
BUILD_TARGET=	default
INFO_FILES=	yes

.include "../../mk/bsd.pkg.mk"
