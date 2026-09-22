# $NetBSD$

DISTNAME=	citeproc-el-0.9.4
PKGNAME=	${EMACS_PKGNAME_PREFIX}citeproc-el-el-0.9.4
CATEGORIES=	devel
MASTER_SITES=	${MASTER_SITE_GITHUB:=andras-simonyi/}
GITHUB_PROJECT=	citeproc-el
GITHUB_TAG=	${PKGVERSION_NOREV}

MAINTAINER=	pkgsrc-users@NetBSD.org
HOMEPAGE=	https://github.com/andras-simonyi/citeproc-el
COMMENT=	CSL 1.0.2 Citation Processor for Emacs
LICENSE=	gnu-gpl-v3

EMACS_VERSIONS_ACCEPTED=	emacs29 emacs29nox emacs30 emacs30nox emacs31 emacs31nox
# XXX Gentoo also depends on app-editors/emacs-26
DEPENDS+=	${EMACS_PKGNAME_PREFIX}compat-el-[0-9]*:../../devel/compat-el
DEPENDS+=	${EMACS_PKGNAME_PREFIX}dash-el-[0-9]*:../../devel/dash-el
DEPENDS+=	${EMACS_PKGNAME_PREFIX}f-el-[0-9]*:../../devel/f-el
DEPENDS+=	${EMACS_PKGNAME_PREFIX}parsebib-el-[0-9]*:../../devel/parsebib-el
DEPENDS+=	${EMACS_PKGNAME_PREFIX}queue-el-[0-9]*:../../devel/queue-el
DEPENDS+=	${EMACS_PKGNAME_PREFIX}s-el-[0-9]*:../../devel/s-el
DEPENDS+=	${EMACS_PKGNAME_PREFIX}string-inflection-el-[0-9]*:../../devel/string-inflection-el

INSTALLATION_DIRS=	${EMACS_LISPPREFIX}/citeproc-el

post-extract:
	cd ${WRKSRC} && ${RM} -f *-test.el *-tests.el *-subtest.el test-*.el tests-*.el *-testsuite.el

do-build:
	cd ${WRKSRC} && ${EMACS_BIN} --no-init-file --no-site-file -batch \
		-L . -L ${EMACS_LISPPREFIX}/compat -L ${EMACS_LISPPREFIX}/dash -L ${EMACS_LISPPREFIX}/f -L ${EMACS_LISPPREFIX}/s -L ${EMACS_LISPPREFIX}/parsebib -L ${EMACS_LISPPREFIX}/queue -L ${EMACS_LISPPREFIX}/string-inflection -f batch-byte-compile *.el

do-install:
	cd ${WRKSRC} && ${INSTALL_DATA} *.el *.elc \
		${DESTDIR}${EMACS_LISPPREFIX}/citeproc-el

.include "../../editors/emacs/modules.mk"
.include "../../mk/bsd.pkg.mk"
