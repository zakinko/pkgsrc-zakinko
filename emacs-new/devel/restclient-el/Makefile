# $NetBSD$

DISTNAME=	restclient-0.20220426
PKGNAME=	${EMACS_PKGNAME_PREFIX}restclient-el-0.20220426
CATEGORIES=	devel
MASTER_SITES=	${MASTER_SITE_GITHUB:=pashky/}
GITHUB_PROJECT=	restclient.el
GITHUB_TAG=	ae79e7dd283890072da69b8f48aeec1afd0d9442
WRKSRC=		${WRKDIR}/restclient.el-ae79e7dd283890072da69b8f48aeec1afd0d9442

MAINTAINER=	pkgsrc-users@NetBSD.org
HOMEPAGE=	https://github.com/pashky/restclient.el/
COMMENT=	HTTP REST client tool for GNU Emacs
LICENSE=	public-domain

EMACS_VERSIONS_ACCEPTED=	emacs29 emacs29nox emacs30 emacs30nox emacs31 emacs31nox
DEPENDS+=	${EMACS_PKGNAME_PREFIX}helm-el-[0-9]*:../../devel/helm-el
DEPENDS+=	${EMACS_PKGNAME_PREFIX}jq-mode-[0-9]*:../../devel/jq-mode

INSTALLATION_DIRS=	${EMACS_LISPPREFIX}/restclient

post-extract:
	cd ${WRKSRC} && ${RM} -f *-test.el *-tests.el *-subtest.el test-*.el tests-*.el *-testsuite.el .dir-locals.el

do-build:
	cd ${WRKSRC} && ${EMACS_BIN} --no-init-file --no-site-file -batch \
		-L . -L ${EMACS_LISPPREFIX}/helm -L ${EMACS_LISPPREFIX}/async -L ${EMACS_LISPPREFIX}/wfnames -L ${EMACS_LISPPREFIX}/jq-mode -f batch-byte-compile *.el

# files marked no-byte-compile leave no .elc behind
do-install:
	cd ${WRKSRC} && ${INSTALL_DATA} *.el ${DESTDIR}${EMACS_LISPPREFIX}/restclient
	cd ${WRKSRC} && for f in *.elc; do \
		${TEST} ! -f "$$f" || ${INSTALL_DATA} "$$f" ${DESTDIR}${EMACS_LISPPREFIX}/restclient; done

.include "../../editors/emacs/modules.mk"
.include "../../mk/bsd.pkg.mk"
