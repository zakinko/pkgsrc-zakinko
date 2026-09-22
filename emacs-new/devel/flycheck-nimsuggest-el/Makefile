# $NetBSD$

DISTNAME=	flycheck-nimsuggest-0.8.1.20171027
PKGNAME=	${EMACS_PKGNAME_PREFIX}flycheck-nimsuggest-el-0.8.1.20171027
CATEGORIES=	devel
MASTER_SITES=	${MASTER_SITE_GITHUB:=yuutayamada/}
GITHUB_PROJECT=	flycheck-nimsuggest
GITHUB_TAG=	dc9a5de1cb3ee05db5794d824610959a1f603bc9
WRKSRC=		${WRKDIR}/flycheck-nimsuggest-dc9a5de1cb3ee05db5794d824610959a1f603bc9

MAINTAINER=	pkgsrc-users@NetBSD.org
HOMEPAGE=	https://github.com/yuutayamada/flycheck-nimsuggest/
COMMENT=	Emacs Flycheck backend for Nim language using nimsuggest
LICENSE=	gnu-gpl-v3

EMACS_VERSIONS_ACCEPTED=	emacs29 emacs29nox emacs30 emacs30nox emacs31 emacs31nox
# XXX Gentoo also depends on dev-lang/nim
DEPENDS+=	${EMACS_PKGNAME_PREFIX}flycheck-mode-[0-9]*:../../textproc/flycheck-mode

INSTALLATION_DIRS=	${EMACS_LISPPREFIX}/flycheck-nimsuggest

post-extract:
	cd ${WRKSRC} && ${RM} -f *-test.el *-tests.el *-subtest.el test-*.el tests-*.el *-testsuite.el

do-build:
	cd ${WRKSRC} && ${EMACS_BIN} --no-init-file --no-site-file -batch \
		-L . -f batch-byte-compile *.el

do-install:
	cd ${WRKSRC} && ${INSTALL_DATA} *.el *.elc \
		${DESTDIR}${EMACS_LISPPREFIX}/flycheck-nimsuggest

.include "../../editors/emacs/modules.mk"
.include "../../mk/bsd.pkg.mk"
