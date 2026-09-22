# $NetBSD$

DISTNAME=	remember-2.0
PKGNAME=	${EMACS_PKGNAME_PREFIX}remember-el-2.0
CATEGORIES=	devel
MASTER_SITES=	${MASTER_SITE_GITHUB:=jwiegley/}
GITHUB_PROJECT=	remember
GITHUB_TAG=	v${PKGVERSION_NOREV}

MAINTAINER=	pkgsrc-users@NetBSD.org
HOMEPAGE=	https://www.emacswiki.org/emacs/RememberMode
COMMENT=	Simplify writing short notes in emacs
LICENSE=	gnu-gpl-v3

EMACS_VERSIONS_ACCEPTED=	emacs29 emacs29nox emacs30 emacs30nox emacs31 emacs31nox
DEPENDS+=	${EMACS_PKGNAME_PREFIX}bbdb-[0-9]*:../../misc/bbdb3
DEPENDS+=	${EMACS_PKGNAME_PREFIX}planner-el-[0-9]*:../../devel/planner-el

INSTALLATION_DIRS=	${EMACS_LISPPREFIX}/remember

post-extract:
	cd ${WRKSRC} && ${RM} -f *-test.el *-tests.el *-subtest.el test-*.el tests-*.el *-testsuite.el .dir-locals.el

# remember-bibl.el needs bibl-mode; each file is compiled on its own and
# the ones whose requirement is absent stay source
do-build:
	cd ${WRKSRC} && for f in *.el; do ${EMACS_BIN} --no-init-file --no-site-file -batch \
		-L . -L ${EMACS_LISPPREFIX}/bbdb -L ${EMACS_LISPPREFIX}/planner -L ${EMACS_LISPPREFIX}/w3m -L ${EMACS_LISPPREFIX}/muse -f batch-byte-compile $$f || ${TRUE}; done

# files marked no-byte-compile leave no .elc behind
do-install:
	cd ${WRKSRC} && ${INSTALL_DATA} *.el ${DESTDIR}${EMACS_LISPPREFIX}/remember
	cd ${WRKSRC} && for f in *.elc; do \
		${TEST} ! -f "$$f" || ${INSTALL_DATA} "$$f" ${DESTDIR}${EMACS_LISPPREFIX}/remember; done

.include "../../editors/emacs/modules.mk"
.include "../../mk/bsd.pkg.mk"
