# $NetBSD$

DISTNAME=	inf-clojure-3.4.0
PKGNAME=	${EMACS_PKGNAME_PREFIX}inf-clojure-el-3.4.0
CATEGORIES=	devel
MASTER_SITES=	${MASTER_SITE_GITHUB:=clojure-emacs/}
GITHUB_PROJECT=	inf-clojure
GITHUB_TAG=	v${PKGVERSION_NOREV}

MAINTAINER=	pkgsrc-users@NetBSD.org
HOMEPAGE=	https://github.com/clojure-emacs/inf-clojure/
COMMENT=	Major mode for Clojure code
LICENSE=	gnu-gpl-v3

EMACS_VERSIONS_ACCEPTED=	emacs29 emacs29nox emacs30 emacs30nox emacs31 emacs31nox
DEPENDS+=	${EMACS_PKGNAME_PREFIX}clojure-mode-[0-9]*:../../devel/clojure-mode

INSTALLATION_DIRS=	${EMACS_LISPPREFIX}/inf-clojure

post-extract:
	cd ${WRKSRC} && ${RM} -f *-test.el *-tests.el *-subtest.el test-*.el tests-*.el *-testsuite.el

do-build:
	cd ${WRKSRC} && ${EMACS_BIN} --no-init-file --no-site-file -batch \
		-L . -L ${EMACS_LISPPREFIX}/clojure-mode -f batch-byte-compile *.el

do-install:
	cd ${WRKSRC} && ${INSTALL_DATA} *.el *.elc \
		${DESTDIR}${EMACS_LISPPREFIX}/inf-clojure

.include "../../editors/emacs/modules.mk"
.include "../../mk/bsd.pkg.mk"
