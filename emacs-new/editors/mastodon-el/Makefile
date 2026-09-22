# $NetBSD$

DISTNAME=	mastodon.el-2.0.7
PKGNAME=	${EMACS_PKGNAME_PREFIX}mastodon-el-2.0.7
CATEGORIES=	editors
MASTER_SITES=	https://codeberg.org/martianh/mastodon.el/archive/
DISTFILES=	${PKGVERSION_NOREV}${EXTRACT_SUFX}
DIST_SUBDIR=	${DISTNAME}
WRKSRC=		${WRKDIR}/mastodon.el/lisp

MAINTAINER=	pkgsrc-users@NetBSD.org
HOMEPAGE=	https://codeberg.org/martianh/mastodon.el/
COMMENT=	Emacs client for Mastodon, federated microblogging social network
LICENSE=	gnu-gpl-v3

EMACS_VERSIONS_ACCEPTED=	emacs29 emacs29nox emacs30 emacs30nox emacs31 emacs31nox
DEPENDS+=	${EMACS_PKGNAME_PREFIX}persist-el-[0-9]*:../../devel/persist-el
DEPENDS+=	${EMACS_PKGNAME_PREFIX}request-el-[0-9]*:../../devel/request-el
DEPENDS+=	${EMACS_PKGNAME_PREFIX}tp-el-[0-9]*:../../devel/tp-el

INSTALLATION_DIRS=	${EMACS_LISPPREFIX}/mastodon

post-extract:
	cd ${WRKSRC} && ${RM} -f *-test.el *-tests.el *-subtest.el test-*.el tests-*.el *-testsuite.el .dir-locals.el

do-build:
	cd ${WRKSRC} && ${EMACS_BIN} --no-init-file --no-site-file -batch \
		-L . -L ${EMACS_LISPPREFIX}/persist -L ${EMACS_LISPPREFIX}/request -L ${EMACS_LISPPREFIX}/deferred -L ${EMACS_LISPPREFIX}/tp -L ${EMACS_LISPPREFIX}/transient -L ${EMACS_LISPPREFIX}/compat -L ${EMACS_LISPPREFIX}/cond-let -L ${EMACS_LISPPREFIX}/llama -f batch-byte-compile *.el

# files marked no-byte-compile leave no .elc behind
do-install:
	cd ${WRKSRC} && ${INSTALL_DATA} *.el ${DESTDIR}${EMACS_LISPPREFIX}/mastodon
	cd ${WRKSRC} && for f in *.elc; do \
		test ! -f "$$f" || ${INSTALL_DATA} "$$f" ${DESTDIR}${EMACS_LISPPREFIX}/mastodon; done

.include "../../editors/emacs/modules.mk"
.include "../../mk/bsd.pkg.mk"
