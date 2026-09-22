# $NetBSD$

DISTNAME=	hydra-0.15.0
PKGNAME=	${EMACS_PKGNAME_PREFIX}hydra-el-0.15.0
CATEGORIES=	editors
MASTER_SITES=	${MASTER_SITE_GITHUB:=abo-abo/}
GITHUB_PROJECT=	hydra
GITHUB_TAG=	${PKGVERSION_NOREV}

MAINTAINER=	pkgsrc-users@NetBSD.org
HOMEPAGE=	https://github.com/abo-abo/hydra/
COMMENT=	Make Emacs bindings that stick around
LICENSE=	gnu-gpl-v3

EMACS_VERSIONS_ACCEPTED=	emacs29 emacs29nox emacs30 emacs30nox emacs31 emacs31nox
DEPENDS+=	${EMACS_PKGNAME_PREFIX}lv-el-[0-9]*:../../devel/lv-el

INSTALLATION_DIRS=	${EMACS_LISPPREFIX}/hydra

post-extract:
	cd ${WRKSRC} && ${RM} -f *-test.el *-tests.el *-subtest.el test-*.el tests-*.el *-testsuite.el

do-build:
	cd ${WRKSRC} && ${EMACS_BIN} --no-init-file --no-site-file -batch \
		-L . -L ${EMACS_LISPPREFIX}/lv -f batch-byte-compile *.el

do-install:
	cd ${WRKSRC} && ${INSTALL_DATA} *.el *.elc \
		${DESTDIR}${EMACS_LISPPREFIX}/hydra

.include "../../editors/emacs/modules.mk"
.include "../../mk/bsd.pkg.mk"
