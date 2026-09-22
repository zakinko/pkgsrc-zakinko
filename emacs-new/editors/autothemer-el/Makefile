# $NetBSD$

DISTNAME=	autothemer-0.2.18
PKGNAME=	${EMACS_PKGNAME_PREFIX}autothemer-el-0.2.18
CATEGORIES=	editors
MASTER_SITES=	${MASTER_SITE_GITHUB:=jasonm23/}
GITHUB_PROJECT=	autothemer
GITHUB_TAG=	${PKGVERSION_NOREV}

MAINTAINER=	pkgsrc-users@NetBSD.org
HOMEPAGE=	https://github.com/jasonm23/autothemer
COMMENT=	Conveniently define themes for GNU Emacs
LICENSE=	gnu-gpl-v3

EMACS_VERSIONS_ACCEPTED=	emacs29 emacs29nox emacs30 emacs30nox emacs31 emacs31nox
DEPENDS+=	${EMACS_PKGNAME_PREFIX}dash-el-[0-9]*:../../devel/dash-el

INSTALLATION_DIRS=	${EMACS_LISPPREFIX}/autothemer

post-extract:
	cd ${WRKSRC} && ${RM} -f *-test.el *-tests.el *-subtest.el test-*.el tests-*.el *-testsuite.el

do-build:
	cd ${WRKSRC} && ${EMACS_BIN} --no-init-file --no-site-file -batch \
		-L . -L ${EMACS_LISPPREFIX}/dash -f batch-byte-compile *.el

do-install:
	cd ${WRKSRC} && ${INSTALL_DATA} *.el *.elc \
		${DESTDIR}${EMACS_LISPPREFIX}/autothemer

.include "../../editors/emacs/modules.mk"
.include "../../mk/bsd.pkg.mk"
