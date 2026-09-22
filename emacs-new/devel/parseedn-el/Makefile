# $NetBSD$

DISTNAME=	parseedn-1.2.1
PKGNAME=	${EMACS_PKGNAME_PREFIX}parseedn-el-1.2.1
CATEGORIES=	devel
MASTER_SITES=	${MASTER_SITE_GITHUB:=clojure-emacs/}
GITHUB_PROJECT=	parseedn
GITHUB_TAG=	v${PKGVERSION_NOREV}

MAINTAINER=	pkgsrc-users@NetBSD.org
HOMEPAGE=	https://github.com/clojure-emacs/parseedn/
COMMENT=	EDN parser for Emacs Lisp
LICENSE=	gnu-gpl-v3

EMACS_VERSIONS_ACCEPTED=	emacs29 emacs29nox emacs30 emacs30nox emacs31 emacs31nox
DEPENDS+=	${EMACS_PKGNAME_PREFIX}parseclj-el-[0-9]*:../../devel/parseclj-el

INSTALLATION_DIRS=	${EMACS_LISPPREFIX}/parseedn

post-extract:
	cd ${WRKSRC} && ${RM} -f *-test.el *-tests.el *-subtest.el test-*.el tests-*.el *-testsuite.el

do-build:
	cd ${WRKSRC} && ${EMACS_BIN} --no-init-file --no-site-file -batch \
		-L . -L ${EMACS_LISPPREFIX}/parseclj -f batch-byte-compile *.el

do-install:
	cd ${WRKSRC} && ${INSTALL_DATA} *.el *.elc \
		${DESTDIR}${EMACS_LISPPREFIX}/parseedn

.include "../../editors/emacs/modules.mk"
.include "../../mk/bsd.pkg.mk"
