# $NetBSD$

DISTNAME=	noflet-0.0.15.20141102
PKGNAME=	${EMACS_PKGNAME_PREFIX}noflet-el-0.0.15.20141102
CATEGORIES=	devel
MASTER_SITES=	${MASTER_SITE_GITHUB:=nicferrier/}
GITHUB_PROJECT=	emacs-noflet
GITHUB_TAG=	7ae84dc3257637af7334101456dafe1759c6b68a
WRKSRC=		${WRKDIR}/emacs-noflet-7ae84dc3257637af7334101456dafe1759c6b68a

MAINTAINER=	pkgsrc-users@NetBSD.org
HOMEPAGE=	https://github.com/nicferrier/emacs-noflet/
COMMENT=	Dynamic, local advice for Emacs-Lisp code
LICENSE=	gnu-gpl-v3

EMACS_VERSIONS_ACCEPTED=	emacs29 emacs29nox emacs30 emacs30nox emacs31 emacs31nox
DEPENDS+=	${EMACS_PKGNAME_PREFIX}dash-el-[0-9]*:../../devel/dash-el

INSTALLATION_DIRS=	${EMACS_LISPPREFIX}/noflet

post-extract:
	cd ${WRKSRC} && ${RM} -f *-test.el *-tests.el *-subtest.el test-*.el tests-*.el *-testsuite.el

do-build:
	cd ${WRKSRC} && ${EMACS_BIN} --no-init-file --no-site-file -batch \
		-L . -L ${EMACS_LISPPREFIX}/dash -l dash -f batch-byte-compile *.el

do-install:
	cd ${WRKSRC} && ${INSTALL_DATA} *.el *.elc \
		${DESTDIR}${EMACS_LISPPREFIX}/noflet

.include "../../editors/emacs/modules.mk"
.include "../../mk/bsd.pkg.mk"
