# $NetBSD$

DISTNAME=	bind-chord-2.4.4
PKGNAME=	${EMACS_PKGNAME_PREFIX}bind-chord-el-2.4.4
CATEGORIES=	devel
MASTER_SITES=	${MASTER_SITE_GITHUB:=jwiegley/}
GITHUB_PROJECT=	use-package
GITHUB_TAG=	${PKGVERSION_NOREV}
WRKSRC=		${WRKDIR}/use-package-2.4.4

MAINTAINER=	pkgsrc-users@NetBSD.org
HOMEPAGE=	https://github.com/jwiegley/use-package/
COMMENT=	Key-chord binding helper for use-package-chords
LICENSE=	gnu-gpl-v3

EMACS_VERSIONS_ACCEPTED=	emacs29 emacs29nox emacs30 emacs30nox emacs31 emacs31nox
DEPENDS+=	${EMACS_PKGNAME_PREFIX}key-chord-el-[0-9]*:../../editors/key-chord-el

INSTALLATION_DIRS=	${EMACS_LISPPREFIX}/bind-chord

post-extract:
	cd ${WRKSRC} && ${RM} -f *-test.el *-tests.el *-subtest.el test-*.el tests-*.el *-testsuite.el .dir-locals.el

do-build:
	cd ${WRKSRC} && ${EMACS_BIN} --no-init-file --no-site-file -batch \
		-L . -L ${EMACS_LISPPREFIX}/key-chord -f batch-byte-compile bind-chord.el

# files marked no-byte-compile leave no .elc behind
do-install:
	cd ${WRKSRC} && ${INSTALL_DATA} bind-chord.el ${DESTDIR}${EMACS_LISPPREFIX}/bind-chord
	cd ${WRKSRC} && for f in bind-chord.elc; do \
		${TEST} ! -f "$$f" || ${INSTALL_DATA} "$$f" ${DESTDIR}${EMACS_LISPPREFIX}/bind-chord; done

.include "../../editors/emacs/modules.mk"
.include "../../mk/bsd.pkg.mk"
