# $NetBSD$

DISTNAME=	analog-1.9.99
PKGNAME=	${EMACS_PKGNAME_PREFIX}analog-el-1.9.99
CATEGORIES=	devel
MASTER_SITES=	https://distfiles.gentoo.org/distfiles/e9/
EXTRACT_SUFX=	.el.bz2
# an old library that Gentoo keeps on its own mirror; upstream is gone
WRKSRC=		${WRKDIR}
USE_TOOLS+=	bzip2

MAINTAINER=	pkgsrc-users@NetBSD.org
HOMEPAGE=	https://web.archive.org/web/20150919120435/http://mph-emacs-pkgs.alioth.debian.org/AnalogEl.html
COMMENT=	Monitor lists of files or command output
LICENSE=	gnu-gpl-v2

EMACS_VERSIONS_ACCEPTED=	emacs29 emacs29nox emacs30 emacs30nox emacs31 emacs31nox

INSTALLATION_DIRS=	${EMACS_LISPPREFIX}/analog

# a single compressed file; pkgsrc's extract would leave it as analog-1.9.99.el
do-extract:
	bzip2 -dc ${DISTDIR}/${DISTFILES} > ${WRKSRC}/analog.el

post-extract:
	cd ${WRKSRC} && ${RM} -f *-test.el *-tests.el *-subtest.el test-*.el tests-*.el *-testsuite.el .dir-locals.el

do-build:
	cd ${WRKSRC} && ${EMACS_BIN} --no-init-file --no-site-file -batch \
		-L .  -f batch-byte-compile *.el

# files marked no-byte-compile leave no .elc behind
do-install:
	cd ${WRKSRC} && ${INSTALL_DATA} *.el ${DESTDIR}${EMACS_LISPPREFIX}/analog
	cd ${WRKSRC} && for f in *.elc; do \
		${TEST} ! -f "$$f" || ${INSTALL_DATA} "$$f" ${DESTDIR}${EMACS_LISPPREFIX}/analog; done

.include "../../editors/emacs/modules.mk"
.include "../../mk/bsd.pkg.mk"
