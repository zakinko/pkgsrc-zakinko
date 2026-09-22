# $NetBSD$

DISTNAME=	centaur-tabs-3.2
PKGNAME=	${EMACS_PKGNAME_PREFIX}centaur-tabs-el-3.2
CATEGORIES=	devel
MASTER_SITES=	${MASTER_SITE_GITHUB:=ema2159/}
GITHUB_PROJECT=	centaur-tabs
GITHUB_TAG=	${PKGVERSION_NOREV}

MAINTAINER=	pkgsrc-users@NetBSD.org
HOMEPAGE=	https://github.com/ema2159/centaur-tabs/
COMMENT=	Customizable tabs plugin for GNU Emacs
LICENSE=	gnu-gpl-v2

EMACS_VERSIONS_ACCEPTED=	emacs29 emacs29nox emacs30 emacs30nox emacs31 emacs31nox
DEPENDS+=	${EMACS_PKGNAME_PREFIX}powerline-el-[0-9]*:../../editors/powerline-el

INSTALLATION_DIRS=	${EMACS_LISPPREFIX}/centaur-tabs

post-extract:
	cd ${WRKSRC} && ${RM} -f *-test.el *-tests.el *-subtest.el test-*.el tests-*.el *-testsuite.el .dir-locals.el

do-build:
	cd ${WRKSRC} && ${EMACS_BIN} --no-init-file --no-site-file -batch \
		-L . -L ${EMACS_LISPPREFIX}/powerline -f batch-byte-compile *.el

# files marked no-byte-compile leave no .elc behind
do-install:
	cd ${WRKSRC} && ${INSTALL_DATA} *.el ${DESTDIR}${EMACS_LISPPREFIX}/centaur-tabs
	cd ${WRKSRC} && for f in *.elc; do \
		${TEST} ! -f "$$f" || ${INSTALL_DATA} "$$f" ${DESTDIR}${EMACS_LISPPREFIX}/centaur-tabs; done

.include "../../editors/emacs/modules.mk"
.include "../../mk/bsd.pkg.mk"
