# $NetBSD$

DISTNAME=	mldonkey-el-0.0.4b
PKGNAME=	${EMACS_PKGNAME_PREFIX}mldonkey-el-0.0.4b
CATEGORIES=	devel
MASTER_SITES=	https://distfiles.gentoo.org/distfiles/2a/
EXTRACT_SUFX=	.tar.gz
# upstream (fu-berlin.de) is gone

MAINTAINER=	pkgsrc-users@NetBSD.org
HOMEPAGE=	https://www.emacswiki.org/emacs/MlDonkey
COMMENT=	An Emacs Lisp interface to the MLDonkey core
LICENSE=	gnu-gpl-v2

EMACS_VERSIONS_ACCEPTED=	emacs29 emacs29nox emacs30 emacs30nox emacs31 emacs31nox

INSTALLATION_DIRS=	${EMACS_LISPPREFIX}/mldonkey

post-extract:
	cd ${WRKSRC} && ${RM} -f *-test.el *-tests.el *-subtest.el test-*.el tests-*.el *-testsuite.el .dir-locals.el

do-build:
	cd ${WRKSRC} && ${EMACS_BIN} --no-init-file --no-site-file -batch \
		-L .  -f batch-byte-compile ml*.el

# files marked no-byte-compile leave no .elc behind
do-install:
	cd ${WRKSRC} && ${INSTALL_DATA} *.el ${DESTDIR}${EMACS_LISPPREFIX}/mldonkey
	cd ${WRKSRC} && for f in *.elc; do \
		test ! -f "$$f" || ${INSTALL_DATA} "$$f" ${DESTDIR}${EMACS_LISPPREFIX}/mldonkey; done

.include "../../editors/emacs/modules.mk"
.include "../../mk/bsd.pkg.mk"
