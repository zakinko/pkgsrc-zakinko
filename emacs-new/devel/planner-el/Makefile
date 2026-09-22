# $NetBSD$

DISTNAME=	planner-3.42
PKGNAME=	${EMACS_PKGNAME_PREFIX}planner-el-3.42
CATEGORIES=	devel
MASTER_SITES=	https://dev.gentoo.org/~ulm/distfiles/
EXTRACT_SUFX=	.tar.gz
# upstream is gone; Gentoo keeps the file on its developers' mirror

MAINTAINER=	pkgsrc-users@NetBSD.org
HOMEPAGE=	https://www.emacswiki.org/emacs/PlannerMode
COMMENT=	Maintain a local Wiki using Emacs-friendly markup
LICENSE=	gnu-gpl-v3

EMACS_VERSIONS_ACCEPTED=	emacs29 emacs29nox emacs30 emacs30nox emacs31 emacs31nox
DEPENDS+=	${EMACS_PKGNAME_PREFIX}bbdb-[0-9]*:../../misc/bbdb3
DEPENDS+=	${EMACS_PKGNAME_PREFIX}emacs-w3m-[0-9]*:../../www/emacs-w3m
DEPENDS+=	${EMACS_PKGNAME_PREFIX}emacs-muse-[0-9]*:../../textproc/emacs-muse

INSTALLATION_DIRS=	${EMACS_LISPPREFIX}/planner

post-extract:
	cd ${WRKSRC} && ${RM} -f *-test.el *-tests.el *-subtest.el test-*.el tests-*.el *-testsuite.el .dir-locals.el planner-gnats.el planner-ledger.el

# The planner-*.el integrations require what they integrate with (psvn,
# vm, wl, xtla...); each file is compiled on its own and the ones whose
# requirement is absent stay source
do-build:
	cd ${WRKSRC} && for f in *.el; do ${EMACS_BIN} --no-init-file --no-site-file -batch \
		-L . -L ${EMACS_LISPPREFIX}/bbdb -L ${EMACS_LISPPREFIX}/w3m -L ${EMACS_LISPPREFIX}/muse -f batch-byte-compile $$f || ${TRUE}; done

# files marked no-byte-compile leave no .elc behind
do-install:
	cd ${WRKSRC} && ${INSTALL_DATA} *.el ${DESTDIR}${EMACS_LISPPREFIX}/planner
	cd ${WRKSRC} && for f in *.elc; do \
		test ! -f "$$f" || ${INSTALL_DATA} "$$f" ${DESTDIR}${EMACS_LISPPREFIX}/planner; done

.include "../../editors/emacs/modules.mk"
.include "../../mk/bsd.pkg.mk"
