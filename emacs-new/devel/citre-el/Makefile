# $NetBSD$

DISTNAME=	citre-0.4.2
PKGNAME=	${EMACS_PKGNAME_PREFIX}citre-el-0.4.2
CATEGORIES=	devel
MASTER_SITES=	${MASTER_SITE_GITHUB:=universal-ctags/}
GITHUB_PROJECT=	citre
GITHUB_TAG=	v${PKGVERSION_NOREV}

MAINTAINER=	pkgsrc-users@NetBSD.org
HOMEPAGE=	https://github.com/universal-ctags/citre/
COMMENT=	Superior code reading and auto-completion with pluggable backends for 
LICENSE=	gnu-gpl-v3

EMACS_VERSIONS_ACCEPTED=	emacs29 emacs29nox emacs30 emacs30nox emacs31 emacs31nox
# XXX Gentoo also depends on dev-util/ctags
# XXX Gentoo also depends on dev-util/global

INSTALLATION_DIRS=	${EMACS_LISPPREFIX}/citre

post-extract:
	cd ${WRKSRC} && ${RM} -f *-test.el *-tests.el *-subtest.el test-*.el tests-*.el *-testsuite.el .dir-locals.el

do-build:
	cd ${WRKSRC} && ${EMACS_BIN} --no-init-file --no-site-file -batch \
		-L .  -f batch-byte-compile *.el

# files marked no-byte-compile leave no .elc behind
do-install:
	cd ${WRKSRC} && ${INSTALL_DATA} *.el ${DESTDIR}${EMACS_LISPPREFIX}/citre
	cd ${WRKSRC} && for f in *.elc; do \
		${TEST} ! -f "$$f" || ${INSTALL_DATA} "$$f" ${DESTDIR}${EMACS_LISPPREFIX}/citre; done

.include "../../editors/emacs/modules.mk"
.include "../../mk/bsd.pkg.mk"
