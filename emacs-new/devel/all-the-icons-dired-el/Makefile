# $NetBSD$

DISTNAME=	all-the-icons-dired-2.0
PKGNAME=	${EMACS_PKGNAME_PREFIX}all-the-icons-dired-el-2.0
CATEGORIES=	devel
MASTER_SITES=	${MASTER_SITE_GITHUB:=wyuenho/}
GITHUB_PROJECT=	all-the-icons-dired
GITHUB_TAG=	${PKGVERSION_NOREV}

MAINTAINER=	pkgsrc-users@NetBSD.org
HOMEPAGE=	https://github.com/wyuenho/all-the-icons-dired/
COMMENT=	Display all-the-icons icon for each file in Emacs' dired buffer
LICENSE=	gnu-gpl-v3

EMACS_VERSIONS_ACCEPTED=	emacs29 emacs29nox emacs30 emacs30nox emacs31 emacs31nox
DEPENDS+=	${EMACS_PKGNAME_PREFIX}all-the-icons-el-[0-9]*:../../devel/all-the-icons-el

INSTALLATION_DIRS=	${EMACS_LISPPREFIX}/all-the-icons-dired

post-extract:
	cd ${WRKSRC} && ${RM} -f *-test.el *-tests.el *-subtest.el test-*.el tests-*.el *-testsuite.el .dir-locals.el

do-build:
	cd ${WRKSRC} && ${EMACS_BIN} --no-init-file --no-site-file -batch \
		-L . -L ${EMACS_LISPPREFIX}/all-the-icons -f batch-byte-compile *.el

do-install:
	cd ${WRKSRC} && ${INSTALL_DATA} *.el *.elc \
		${DESTDIR}${EMACS_LISPPREFIX}/all-the-icons-dired

.include "../../editors/emacs/modules.mk"
.include "../../mk/bsd.pkg.mk"
