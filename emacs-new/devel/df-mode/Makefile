# $NetBSD$

DISTNAME=	df-mode-20050509
PKGNAME=	${EMACS_PKGNAME_PREFIX}df-mode-20050509
CATEGORIES=	devel
MASTER_SITES=	https://distfiles.gentoo.org/distfiles/f2/
EXTRACT_SUFX=	.el.bz2
# an old library that Gentoo keeps on its own mirror; upstream is gone
WRKSRC=		${WRKDIR}
USE_TOOLS+=	bzip2

MAINTAINER=	pkgsrc-users@NetBSD.org
HOMEPAGE=	https://web.archive.org/web/20061001221337/http://www.coli.uni-saarland.de/~fouvry/software.html
COMMENT=	Minor mode to show space left on devices in the mode line
LICENSE=	gnu-gpl-v2

EMACS_VERSIONS_ACCEPTED=	emacs29 emacs29nox emacs30 emacs30nox emacs31 emacs31nox

INSTALLATION_DIRS=	${EMACS_LISPPREFIX}/df-mode

# a single compressed file; pkgsrc's extract would leave it as df-mode-20050509.el
do-extract:
	bzip2 -dc ${DISTDIR}/${DISTFILES} > ${WRKSRC}/df-mode.el

post-extract:
	cd ${WRKSRC} && ${RM} -f *-test.el *-tests.el *-subtest.el test-*.el tests-*.el *-testsuite.el .dir-locals.el

do-build:
	cd ${WRKSRC} && ${EMACS_BIN} --no-init-file --no-site-file -batch \
		-L .  -f batch-byte-compile *.el

# files marked no-byte-compile leave no .elc behind
do-install:
	cd ${WRKSRC} && ${INSTALL_DATA} *.el ${DESTDIR}${EMACS_LISPPREFIX}/df-mode
	cd ${WRKSRC} && for f in *.elc; do \
		test ! -f "$$f" || ${INSTALL_DATA} "$$f" ${DESTDIR}${EMACS_LISPPREFIX}/df-mode; done

.include "../../editors/emacs/modules.mk"
.include "../../mk/bsd.pkg.mk"
