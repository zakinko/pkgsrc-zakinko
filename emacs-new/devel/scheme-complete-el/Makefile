# $NetBSD$

DISTNAME=	scheme-complete-0.9.9
PKGNAME=	${EMACS_PKGNAME_PREFIX}scheme-complete-el-0.9.9
CATEGORIES=	devel
MASTER_SITES=	http://synthcode.com/emacs/
MASTER_SITES+=	https://distfiles.gentoo.org/distfiles/66/
EXTRACT_SUFX=	.el.gz
WRKSRC=		${WRKDIR}
USE_TOOLS+=	gzip

MAINTAINER=	pkgsrc-users@NetBSD.org
HOMEPAGE=	http://synthcode.com/
COMMENT=	Scheme tab-completion and word-completion for Emacs
LICENSE=	public-domain

EMACS_VERSIONS_ACCEPTED=	emacs29 emacs29nox emacs30 emacs30nox emacs31 emacs31nox

INSTALLATION_DIRS=	${EMACS_LISPPREFIX}/scheme-complete

# a single compressed file, which pkgsrc's extract does not unpack
do-extract:
	gzip -dc ${DISTDIR}/${DISTFILES} > ${WRKSRC}/scheme-complete.el

post-extract:
	cd ${WRKSRC} && ${RM} -f *-test.el *-tests.el *-subtest.el test-*.el tests-*.el *-testsuite.el .dir-locals.el

do-build:
	cd ${WRKSRC} && ${EMACS_BIN} --no-init-file --no-site-file -batch \
		-L .  -f batch-byte-compile *.el

# files marked no-byte-compile leave no .elc behind
do-install:
	cd ${WRKSRC} && ${INSTALL_DATA} *.el ${DESTDIR}${EMACS_LISPPREFIX}/scheme-complete
	cd ${WRKSRC} && for f in *.elc; do \
		test ! -f "$$f" || ${INSTALL_DATA} "$$f" ${DESTDIR}${EMACS_LISPPREFIX}/scheme-complete; done

.include "../../editors/emacs/modules.mk"
.include "../../mk/bsd.pkg.mk"
