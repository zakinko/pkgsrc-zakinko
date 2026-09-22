# $NetBSD$

DISTNAME=	dune-format-0.1
PKGNAME=	${EMACS_PKGNAME_PREFIX}dune-format-el-0.1
CATEGORIES=	devel
MASTER_SITES=	${MASTER_SITE_GITHUB:=purcell/}
GITHUB_PROJECT=	emacs-dune-format
GITHUB_TAG=	${PKGVERSION_NOREV}
WRKSRC=		${WRKDIR}/emacs-dune-format-0.1

MAINTAINER=	pkgsrc-users@NetBSD.org
HOMEPAGE=	https://github.com/purcell/emacs-dune-format/
COMMENT=	Reformat OCaml's dune files automatically
LICENSE=	gnu-gpl-v3

EMACS_VERSIONS_ACCEPTED=	emacs29 emacs29nox emacs30 emacs30nox emacs31 emacs31nox
# XXX Gentoo also depends on dev-ml/dune
DEPENDS+=	${EMACS_PKGNAME_PREFIX}reformatter-el-[0-9]*:../../devel/reformatter-el

INSTALLATION_DIRS=	${EMACS_LISPPREFIX}/dune-format

post-extract:
	cd ${WRKSRC} && ${RM} -f *-test.el *-tests.el *-subtest.el test-*.el tests-*.el *-testsuite.el .dir-locals.el

do-build:
	cd ${WRKSRC} && ${EMACS_BIN} --no-init-file --no-site-file -batch \
		-L . -L ${EMACS_LISPPREFIX}/reformatter -f batch-byte-compile *.el

# files marked no-byte-compile leave no .elc behind
do-install:
	cd ${WRKSRC} && ${INSTALL_DATA} *.el ${DESTDIR}${EMACS_LISPPREFIX}/dune-format
	cd ${WRKSRC} && for f in *.elc; do \
		${TEST} ! -f "$$f" || ${INSTALL_DATA} "$$f" ${DESTDIR}${EMACS_LISPPREFIX}/dune-format; done

.include "../../editors/emacs/modules.mk"
.include "../../mk/bsd.pkg.mk"
