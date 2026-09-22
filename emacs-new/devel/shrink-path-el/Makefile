# $NetBSD$

DISTNAME=	shrink-path.el-v0.3.1
PKGNAME=	${EMACS_PKGNAME_PREFIX}shrink-path-el-0.3.1
CATEGORIES=	devel
MASTER_SITES=	https://gitlab.com/bennya/shrink-path.el/-/archive/v${PKGVERSION_NOREV}/
EXTRACT_SUFX=	.tar.bz2

MAINTAINER=	pkgsrc-users@NetBSD.org
HOMEPAGE=	https://gitlab.com/bennya/shrink-path.el/
COMMENT=	Fish-style path truncation for GNU Emacs
LICENSE=	gnu-gpl-v2

EMACS_VERSIONS_ACCEPTED=	emacs29 emacs29nox emacs30 emacs30nox emacs31 emacs31nox
DEPENDS+=	${EMACS_PKGNAME_PREFIX}dash-el-[0-9]*:../../devel/dash-el
DEPENDS+=	${EMACS_PKGNAME_PREFIX}f-el-[0-9]*:../../devel/f-el
DEPENDS+=	${EMACS_PKGNAME_PREFIX}s-el-[0-9]*:../../devel/s-el

INSTALLATION_DIRS=	${EMACS_LISPPREFIX}/shrink-path

post-extract:
	cd ${WRKSRC} && ${RM} -f *-test.el *-tests.el *-subtest.el test-*.el tests-*.el *-testsuite.el

do-build:
	cd ${WRKSRC} && ${EMACS_BIN} --no-init-file --no-site-file -batch \
		-L . -L ${EMACS_LISPPREFIX}/dash -L ${EMACS_LISPPREFIX}/f -L ${EMACS_LISPPREFIX}/s -f batch-byte-compile *.el

do-install:
	cd ${WRKSRC} && ${INSTALL_DATA} *.el *.elc \
		${DESTDIR}${EMACS_LISPPREFIX}/shrink-path

.include "../../editors/emacs/modules.mk"
.include "../../mk/bsd.pkg.mk"
