# $NetBSD$

DISTNAME=	dired-hacks-0.0.1.20230621
PKGNAME=	${EMACS_PKGNAME_PREFIX}dired-hacks-el-0.0.1.20230621
CATEGORIES=	devel
MASTER_SITES=	${MASTER_SITE_GITHUB:=Fuco1/}
GITHUB_PROJECT=	dired-hacks
GITHUB_TAG=	874449d6fc98aee565e1715ec18acec3c1c2cafb
WRKSRC=		${WRKDIR}/dired-hacks-874449d6fc98aee565e1715ec18acec3c1c2cafb

MAINTAINER=	pkgsrc-users@NetBSD.org
HOMEPAGE=	https://github.com/Fuco1/dired-hacks/
COMMENT=	Collection of useful dired additions for GNU Emacs
LICENSE=	gnu-gpl-v3

EMACS_VERSIONS_ACCEPTED=	emacs29 emacs29nox emacs30 emacs30nox emacs31 emacs31nox
DEPENDS+=	${EMACS_PKGNAME_PREFIX}dash-el-[0-9]*:../../devel/dash-el
DEPENDS+=	${EMACS_PKGNAME_PREFIX}eimp-el-[0-9]*:../../devel/eimp-el
DEPENDS+=	${EMACS_PKGNAME_PREFIX}f-el-[0-9]*:../../devel/f-el
DEPENDS+=	${EMACS_PKGNAME_PREFIX}s-el-[0-9]*:../../devel/s-el

INSTALLATION_DIRS=	${EMACS_LISPPREFIX}/dired-hacks

post-extract:
	cd ${WRKSRC} && ${RM} -f *-test.el *-tests.el *-subtest.el test-*.el tests-*.el *-testsuite.el .dir-locals.el

do-build:
	cd ${WRKSRC} && ${EMACS_BIN} --no-init-file --no-site-file -batch \
		-L . -L ${EMACS_LISPPREFIX}/dash -L ${EMACS_LISPPREFIX}/eimp -L ${EMACS_LISPPREFIX}/f -L ${EMACS_LISPPREFIX}/s -f batch-byte-compile dired-avfs.el dired-collapse.el dired-filter.el dired-hacks-utils.el dired-list.el dired-narrow.el dired-open.el dired-rainbow.el dired-ranger.el dired-subtree.el dired-tagsistant.el

# files marked no-byte-compile leave no .elc behind
do-install:
	cd ${WRKSRC} && ${INSTALL_DATA} *.el ${DESTDIR}${EMACS_LISPPREFIX}/dired-hacks
	cd ${WRKSRC} && for f in *.elc; do \
		${TEST} ! -f "$$f" || ${INSTALL_DATA} "$$f" ${DESTDIR}${EMACS_LISPPREFIX}/dired-hacks; done

.include "../../editors/emacs/modules.mk"
.include "../../mk/bsd.pkg.mk"
