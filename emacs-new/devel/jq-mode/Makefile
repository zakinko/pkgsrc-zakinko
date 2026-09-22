# $NetBSD$

DISTNAME=	jq-mode-0.5.0.20220610
PKGNAME=	${EMACS_PKGNAME_PREFIX}jq-mode-0.5.0.20220610
CATEGORIES=	devel
MASTER_SITES=	${MASTER_SITE_GITHUB:=ljos/}
GITHUB_PROJECT=	jq-mode
GITHUB_TAG=	071c1c29bac30351ad338136f2b625e5601365cd
WRKSRC=		${WRKDIR}/jq-mode-071c1c29bac30351ad338136f2b625e5601365cd

MAINTAINER=	pkgsrc-users@NetBSD.org
HOMEPAGE=	https://github.com/ljos/jq-mode/
COMMENT=	Emacs major mode for editing jq queries
LICENSE=	gnu-gpl-v3

EMACS_VERSIONS_ACCEPTED=	emacs29 emacs29nox emacs30 emacs30nox emacs31 emacs31nox
# XXX Gentoo also depends on app-misc/jq

INSTALLATION_DIRS=	${EMACS_LISPPREFIX}/jq-mode

post-extract:
	cd ${WRKSRC} && ${RM} -f *-test.el *-tests.el *-subtest.el test-*.el tests-*.el *-testsuite.el .dir-locals.el

do-build:
	cd ${WRKSRC} && ${EMACS_BIN} --no-init-file --no-site-file -batch \
		-L .  -f batch-byte-compile *.el

# files marked no-byte-compile leave no .elc behind
do-install:
	cd ${WRKSRC} && ${INSTALL_DATA} *.el ${DESTDIR}${EMACS_LISPPREFIX}/jq-mode
	cd ${WRKSRC} && for f in *.elc; do \
		${TEST} ! -f "$$f" || ${INSTALL_DATA} "$$f" ${DESTDIR}${EMACS_LISPPREFIX}/jq-mode; done

.include "../../editors/emacs/modules.mk"
.include "../../mk/bsd.pkg.mk"
