# $NetBSD$

DISTNAME=	no-littering-1.9.1
PKGNAME=	${EMACS_PKGNAME_PREFIX}no-littering-el-1.9.1
CATEGORIES=	editors
MASTER_SITES=	${MASTER_SITE_GITHUB:=emacscollective/}
GITHUB_PROJECT=	no-littering
GITHUB_TAG=	v${PKGVERSION_NOREV}

MAINTAINER=	pkgsrc-users@NetBSD.org
HOMEPAGE=	https://github.com/emacscollective/no-littering/
COMMENT=	ELisp library that helps keeping Emacs configuration directory clean
LICENSE=	gnu-gpl-v3

EMACS_VERSIONS_ACCEPTED=	emacs29 emacs29nox emacs30 emacs30nox emacs31 emacs31nox
DEPENDS+=	${EMACS_PKGNAME_PREFIX}compat-el-[0-9]*:../../devel/compat-el

INSTALLATION_DIRS=	${EMACS_LISPPREFIX}/no-littering

post-extract:
	cd ${WRKSRC} && ${RM} -f *-test.el *-tests.el *-subtest.el test-*.el tests-*.el *-testsuite.el

do-build:
	cd ${WRKSRC} && ${EMACS_BIN} --no-init-file --no-site-file -batch \
		-L . -L ${EMACS_LISPPREFIX}/compat -f batch-byte-compile *.el

do-install:
	cd ${WRKSRC} && ${INSTALL_DATA} *.el *.elc \
		${DESTDIR}${EMACS_LISPPREFIX}/no-littering

.include "../../editors/emacs/modules.mk"
.include "../../mk/bsd.pkg.mk"
