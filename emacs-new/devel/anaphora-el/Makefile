# $NetBSD$

DISTNAME=	anaphora-1.0.4
PKGNAME=	${EMACS_PKGNAME_PREFIX}anaphora-el-1.0.4
CATEGORIES=	devel
MASTER_SITES=	${MASTER_SITE_GITHUB:=rolandwalker/}
GITHUB_PROJECT=	anaphora
GITHUB_TAG=	v${PKGVERSION_NOREV}

MAINTAINER=	pkgsrc-users@NetBSD.org
HOMEPAGE=	https://github.com/rolandwalker/anaphora/
COMMENT=	Anaphoric expressions for Emacs Lisp, providing implicit temporary var
LICENSE=	public-domain

EMACS_VERSIONS_ACCEPTED=	emacs29 emacs29nox emacs30 emacs30nox emacs31 emacs31nox

INSTALLATION_DIRS=	${EMACS_LISPPREFIX}/anaphora

post-extract:
	cd ${WRKSRC} && ${RM} -f *-test.el *-tests.el *-subtest.el test-*.el tests-*.el *-testsuite.el .dir-locals.el

do-build:
	cd ${WRKSRC} && ${EMACS_BIN} --no-init-file --no-site-file -batch \
		-L .  -f batch-byte-compile *.el

# files marked no-byte-compile leave no .elc behind
do-install:
	cd ${WRKSRC} && ${INSTALL_DATA} *.el ${DESTDIR}${EMACS_LISPPREFIX}/anaphora
	cd ${WRKSRC} && for f in *.elc; do \
		${TEST} ! -f "$$f" || ${INSTALL_DATA} "$$f" ${DESTDIR}${EMACS_LISPPREFIX}/anaphora; done

.include "../../editors/emacs/modules.mk"
.include "../../mk/bsd.pkg.mk"
