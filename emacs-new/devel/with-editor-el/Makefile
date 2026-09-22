# $NetBSD$

DISTNAME=	with-editor-3.5.4
PKGNAME=	${EMACS_PKGNAME_PREFIX}with-editor-el-3.5.4
CATEGORIES=	devel
MASTER_SITES=	${MASTER_SITE_GITHUB:=magit/}
GITHUB_PROJECT=	with-editor
GITHUB_TAG=	v${PKGVERSION_NOREV}
WRKSRC=		${WRKDIR}/with-editor-3.5.4/lisp

MAINTAINER=	pkgsrc-users@NetBSD.org
HOMEPAGE=	https://magit.vc/manual/with-editor/
COMMENT=	Use the Emacsclient as the \$EDITOR of child processes
LICENSE=	gnu-gpl-v3

EMACS_VERSIONS_ACCEPTED=	emacs29 emacs29nox emacs30 emacs30nox emacs31 emacs31nox
DEPENDS+=	${EMACS_PKGNAME_PREFIX}compat-el-[0-9]*:../../devel/compat-el
DEPENDS+=	${EMACS_PKGNAME_PREFIX}cond-let-el-[0-9]*:../../devel/cond-let-el
DEPENDS+=	${EMACS_PKGNAME_PREFIX}llama-el-[0-9]*:../../devel/llama-el

INSTALLATION_DIRS=	${EMACS_LISPPREFIX}/with-editor

post-extract:
	cd ${WRKSRC} && ${RM} -f *-test.el *-tests.el *-subtest.el test-*.el tests-*.el *-testsuite.el

do-build:
	cd ${WRKSRC} && ${EMACS_BIN} --no-init-file --no-site-file -batch \
		-L . -L ${EMACS_LISPPREFIX}/compat -L ${EMACS_LISPPREFIX}/cond-let -L ${EMACS_LISPPREFIX}/llama -f batch-byte-compile *.el

do-install:
	cd ${WRKSRC} && ${INSTALL_DATA} *.el *.elc \
		${DESTDIR}${EMACS_LISPPREFIX}/with-editor

.include "../../editors/emacs/modules.mk"
.include "../../mk/bsd.pkg.mk"
