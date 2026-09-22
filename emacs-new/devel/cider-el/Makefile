# $NetBSD$

DISTNAME=	cider-2.0.1
PKGNAME=	${EMACS_PKGNAME_PREFIX}cider-el-2.0.1
CATEGORIES=	devel
MASTER_SITES=	${MASTER_SITE_GITHUB:=clojure-emacs/}
GITHUB_PROJECT=	cider
GITHUB_TAG=	v${PKGVERSION_NOREV}
WRKSRC=		${WRKDIR}/cider-2.0.1/lisp

MAINTAINER=	pkgsrc-users@NetBSD.org
HOMEPAGE=	https://cider.mx/
COMMENT=	Clojure Interactive Development Environment for GNU Emacs
LICENSE=	gnu-gpl-v3

EMACS_VERSIONS_ACCEPTED=	emacs29 emacs29nox emacs30 emacs30nox emacs31 emacs31nox
DEPENDS+=	${EMACS_PKGNAME_PREFIX}clojure-mode-[0-9]*:../../devel/clojure-mode
DEPENDS+=	${EMACS_PKGNAME_PREFIX}compat-el-[0-9]*:../../devel/compat-el
DEPENDS+=	${EMACS_PKGNAME_PREFIX}parseedn-el-[0-9]*:../../devel/parseedn-el
DEPENDS+=	${EMACS_PKGNAME_PREFIX}queue-el-[0-9]*:../../devel/queue-el
DEPENDS+=	${EMACS_PKGNAME_PREFIX}sesman-el-[0-9]*:../../devel/sesman-el
DEPENDS+=	${EMACS_PKGNAME_PREFIX}spinner-el-[0-9]*:../../editors/spinner-el
DEPENDS+=	${EMACS_PKGNAME_PREFIX}transient-el-[0-9]*:../../devel/transient-el

INSTALLATION_DIRS=	${EMACS_LISPPREFIX}/cider

post-extract:
	cd ${WRKSRC} && ${RM} -f .dir-locals.el

do-build:
	cd ${WRKSRC} && ${EMACS_BIN} --no-init-file --no-site-file -batch \
		-L . -L ${EMACS_LISPPREFIX}/clojure-mode -L ${EMACS_LISPPREFIX}/compat -L ${EMACS_LISPPREFIX}/parseedn -L ${EMACS_LISPPREFIX}/parseclj -L ${EMACS_LISPPREFIX}/queue -L ${EMACS_LISPPREFIX}/sesman -L ${EMACS_LISPPREFIX}/spinner -L ${EMACS_LISPPREFIX}/transient -L ${EMACS_LISPPREFIX}/cond-let -L ${EMACS_LISPPREFIX}/llama -f batch-byte-compile *.el

# files marked no-byte-compile leave no .elc behind
do-install:
	cd ${WRKSRC} && ${INSTALL_DATA} *.el ${DESTDIR}${EMACS_LISPPREFIX}/cider
	cd ${WRKSRC} && for f in *.elc; do \
		test ! -f "$$f" || ${INSTALL_DATA} "$$f" ${DESTDIR}${EMACS_LISPPREFIX}/cider; done

.include "../../editors/emacs/modules.mk"
.include "../../mk/bsd.pkg.mk"
