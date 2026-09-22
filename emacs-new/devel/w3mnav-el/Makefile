# $NetBSD$

DISTNAME=	w3mnav-0.5
PKGNAME=	${EMACS_PKGNAME_PREFIX}w3mnav-el-0.5
CATEGORIES=	devel
MASTER_SITES=	https://distfiles.gentoo.org/distfiles/8f/
EXTRACT_SUFX=	.tar.gz
# an old library that Gentoo keeps on its own mirror; upstream is gone

MAINTAINER=	pkgsrc-users@NetBSD.org
HOMEPAGE=	https://www.neilvandyke.org/w3mnav/
COMMENT=	Add Info-like navigation keys to the emacs-w3m web browser
LICENSE=	gnu-gpl-v2

EMACS_VERSIONS_ACCEPTED=	emacs29 emacs29nox emacs30 emacs30nox emacs31 emacs31nox
DEPENDS+=	${EMACS_PKGNAME_PREFIX}emacs-w3m-[0-9]*:../../www/emacs-w3m

INSTALLATION_DIRS=	${EMACS_LISPPREFIX}/w3mnav

post-extract:
	cd ${WRKSRC} && ${RM} -f *-test.el *-tests.el *-subtest.el test-*.el tests-*.el *-testsuite.el .dir-locals.el

do-build:
	cd ${WRKSRC} && ${EMACS_BIN} --no-init-file --no-site-file -batch \
		-L . -L ${EMACS_LISPPREFIX}/w3m -f batch-byte-compile *.el

# files marked no-byte-compile leave no .elc behind
do-install:
	cd ${WRKSRC} && ${INSTALL_DATA} *.el ${DESTDIR}${EMACS_LISPPREFIX}/w3mnav
	cd ${WRKSRC} && for f in *.elc; do \
		${TEST} ! -f "$$f" || ${INSTALL_DATA} "$$f" ${DESTDIR}${EMACS_LISPPREFIX}/w3mnav; done

.include "../../editors/emacs/modules.mk"
.include "../../mk/bsd.pkg.mk"
