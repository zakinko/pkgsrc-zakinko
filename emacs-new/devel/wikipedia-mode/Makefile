# $NetBSD$

DISTNAME=	wikipedia-mode-0.5
PKGNAME=	${EMACS_PKGNAME_PREFIX}wikipedia-mode-0.5
CATEGORIES=	devel
MASTER_SITES=	https://distfiles.gentoo.org/distfiles/19/
EXTRACT_SUFX=	.el.bz2
# an old library that Gentoo keeps on its own mirror; upstream is gone
WRKSRC=		${WRKDIR}
USE_TOOLS+=	bzip2

MAINTAINER=	pkgsrc-users@NetBSD.org
HOMEPAGE=	https://www.emacswiki.org/emacs/WikipediaMode
COMMENT=	Mode for editing Wikipedia articles off-line
LICENSE=	gnu-gpl-v2

EMACS_VERSIONS_ACCEPTED=	emacs29 emacs29nox emacs30 emacs30nox emacs31 emacs31nox
DEPENDS+=	${EMACS_PKGNAME_PREFIX}outline-magic-el-[0-9]*:../../devel/outline-magic-el

INSTALLATION_DIRS=	${EMACS_LISPPREFIX}/wikipedia-mode

# a single compressed file; pkgsrc's extract would leave it as wikipedia-mode-0.5.el
do-extract:
	bzip2 -dc ${DISTDIR}/${DISTFILES} > ${WRKSRC}/wikipedia-mode.el

post-extract:
	cd ${WRKSRC} && ${RM} -f *-test.el *-tests.el *-subtest.el test-*.el tests-*.el *-testsuite.el .dir-locals.el

do-build:
	cd ${WRKSRC} && ${EMACS_BIN} --no-init-file --no-site-file -batch \
		-L . -L ${EMACS_LISPPREFIX}/outline-magic -f batch-byte-compile *.el

# files marked no-byte-compile leave no .elc behind
do-install:
	cd ${WRKSRC} && ${INSTALL_DATA} *.el ${DESTDIR}${EMACS_LISPPREFIX}/wikipedia-mode
	cd ${WRKSRC} && for f in *.elc; do \
		${TEST} ! -f "$$f" || ${INSTALL_DATA} "$$f" ${DESTDIR}${EMACS_LISPPREFIX}/wikipedia-mode; done

.include "../../editors/emacs/modules.mk"
.include "../../mk/bsd.pkg.mk"
