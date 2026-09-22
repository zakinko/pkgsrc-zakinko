# $NetBSD$

DISTNAME=	emacs-ipython-notebook-0.17.1pre20251212
PKGNAME=	${EMACS_PKGNAME_PREFIX}emacs-ipython-notebook-el-0.17.1pre20251212
CATEGORIES=	devel
MASTER_SITES=	${MASTER_SITE_GITHUB:=millejoh/}
GITHUB_PROJECT=	emacs-ipython-notebook
GITHUB_TAG=	8fa836fcd1c22f45d36249b09590b32a890f2b9e
WRKSRC=		${WRKDIR}/emacs-ipython-notebook-8fa836fcd1c22f45d36249b09590b32a890f2b9e/lisp

MAINTAINER=	pkgsrc-users@NetBSD.org
HOMEPAGE=	https://github.com/millejoh/emacs-ipython-notebook/
COMMENT=	Jupyter notebook client in Emacs
LICENSE=	gnu-gpl-v3

EMACS_VERSIONS_ACCEPTED=	emacs29 emacs29nox emacs30 emacs30nox emacs31 emacs31nox
# XXX Gentoo also depends on dev-python/ipython
# XXX Gentoo also depends on dev-python/notebook
# XXX Gentoo also depends on dev-python/tornado
DEPENDS+=	${EMACS_PKGNAME_PREFIX}anaphora-el-[0-9]*:../../devel/anaphora-el
DEPENDS+=	${EMACS_PKGNAME_PREFIX}dash-el-[0-9]*:../../devel/dash-el
DEPENDS+=	${EMACS_PKGNAME_PREFIX}deferred-el-[0-9]*:../../devel/deferred-el
DEPENDS+=	${EMACS_PKGNAME_PREFIX}polymode-el-[0-9]*:../../devel/polymode-el
DEPENDS+=	${EMACS_PKGNAME_PREFIX}request-el-[0-9]*:../../devel/request-el
DEPENDS+=	${EMACS_PKGNAME_PREFIX}websocket-el-[0-9]*:../../devel/websocket-el
DEPENDS+=	${EMACS_PKGNAME_PREFIX}with-editor-el-[0-9]*:../../devel/with-editor-el

INSTALLATION_DIRS=	${EMACS_LISPPREFIX}/emacs-ipython-notebook

post-extract:
	cd ${WRKSRC} && ${RM} -f *-test.el *-tests.el *-subtest.el test-*.el tests-*.el *-testsuite.el

do-build:
	cd ${WRKSRC} && ${EMACS_BIN} --no-init-file --no-site-file -batch \
		-L . -L ${EMACS_LISPPREFIX}/anaphora -L ${EMACS_LISPPREFIX}/dash -L ${EMACS_LISPPREFIX}/deferred -L ${EMACS_LISPPREFIX}/polymode -L ${EMACS_LISPPREFIX}/request -L ${EMACS_LISPPREFIX}/websocket -L ${EMACS_LISPPREFIX}/with-editor -L ${EMACS_LISPPREFIX}/compat -L ${EMACS_LISPPREFIX}/cond-let -L ${EMACS_LISPPREFIX}/llama -f batch-byte-compile *.el

do-install:
	cd ${WRKSRC} && ${INSTALL_DATA} *.el *.elc \
		${DESTDIR}${EMACS_LISPPREFIX}/emacs-ipython-notebook

.include "../../editors/emacs/modules.mk"
.include "../../mk/bsd.pkg.mk"
