# $NetBSD$

DISTNAME=	agent-shell-0.74.3
PKGNAME=	${EMACS_PKGNAME_PREFIX}agent-shell-el-0.74.3
CATEGORIES=	devel
MASTER_SITES=	${MASTER_SITE_GITHUB:=xenodium/}
GITHUB_PROJECT=	agent-shell
GITHUB_TAG=	v${PKGVERSION_NOREV}

MAINTAINER=	pkgsrc-users@NetBSD.org
HOMEPAGE=	https://github.com/xenodium/agent-shell/
COMMENT=	Many native agentic integrations inside GNU Emacs
LICENSE=	gnu-gpl-v3

EMACS_VERSIONS_ACCEPTED=	emacs29 emacs29nox emacs30 emacs30nox emacs31 emacs31nox
DEPENDS+=	${EMACS_PKGNAME_PREFIX}acp-el-[0-9]*:../../devel/acp-el
DEPENDS+=	${EMACS_PKGNAME_PREFIX}shell-maker-el-[0-9]*:../../devel/shell-maker-el

INSTALLATION_DIRS=	${EMACS_LISPPREFIX}/agent-shell

post-extract:
	cd ${WRKSRC} && ${RM} -f *-test.el *-tests.el *-subtest.el test-*.el tests-*.el *-testsuite.el .dir-locals.el

do-build:
	cd ${WRKSRC} && ${EMACS_BIN} --no-init-file --no-site-file -batch \
		-L . -L ${EMACS_LISPPREFIX}/acp -L ${EMACS_LISPPREFIX}/shell-maker -f batch-byte-compile *.el

# files marked no-byte-compile leave no .elc behind
do-install:
	cd ${WRKSRC} && ${INSTALL_DATA} *.el ${DESTDIR}${EMACS_LISPPREFIX}/agent-shell
	cd ${WRKSRC} && for f in *.elc; do \
		${TEST} ! -f "$$f" || ${INSTALL_DATA} "$$f" ${DESTDIR}${EMACS_LISPPREFIX}/agent-shell; done

.include "../../editors/emacs/modules.mk"
.include "../../mk/bsd.pkg.mk"
