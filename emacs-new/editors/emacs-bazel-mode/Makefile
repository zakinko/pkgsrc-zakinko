# $NetBSD$

DISTNAME=	emacs-bazel-mode-0.20230919
PKGNAME=	${EMACS_PKGNAME_PREFIX}emacs-bazel-mode-0.20230919
CATEGORIES=	editors
MASTER_SITES=	${MASTER_SITE_GITHUB:=bazel-contrib/}
GITHUB_PROJECT=	bazel.el
GITHUB_TAG=	769b30dc18282564d614d7044195b5a0c1a0a5f3
WRKSRC=		${WRKDIR}/bazel.el-769b30dc18282564d614d7044195b5a0c1a0a5f3

MAINTAINER=	pkgsrc-users@NetBSD.org
HOMEPAGE=	https://bazel.build/
COMMENT=	Emacs major modes for the Bazel build system support
LICENSE=	apache-2.0

EMACS_VERSIONS_ACCEPTED=	emacs29 emacs29nox emacs30 emacs30nox emacs31 emacs31nox

INSTALLATION_DIRS=	${EMACS_LISPPREFIX}/emacs-bazel-mode

post-extract:
	cd ${WRKSRC} && ${RM} -f *-test.el *-tests.el *-subtest.el test-*.el tests-*.el *-testsuite.el .dir-locals.el

do-build:
	cd ${WRKSRC} && ${EMACS_BIN} --no-init-file --no-site-file -batch \
		-L .  -f batch-byte-compile *.el

# files marked no-byte-compile leave no .elc behind
do-install:
	cd ${WRKSRC} && ${INSTALL_DATA} *.el ${DESTDIR}${EMACS_LISPPREFIX}/emacs-bazel-mode
	cd ${WRKSRC} && for f in *.elc; do \
		${TEST} ! -f "$$f" || ${INSTALL_DATA} "$$f" ${DESTDIR}${EMACS_LISPPREFIX}/emacs-bazel-mode; done

.include "../../editors/emacs/modules.mk"
.include "../../mk/bsd.pkg.mk"
