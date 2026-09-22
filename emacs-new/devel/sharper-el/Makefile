# $NetBSD$

DISTNAME=	sharper-1.0.20230129
PKGNAME=	${EMACS_PKGNAME_PREFIX}sharper-el-1.0.20230129
CATEGORIES=	devel
MASTER_SITES=	${MASTER_SITE_GITHUB:=sebasmonia/}
GITHUB_PROJECT=	sharper
GITHUB_TAG=	496e90e337cb09329d85a6d171c0953a85e918fe
WRKSRC=		${WRKDIR}/sharper-496e90e337cb09329d85a6d171c0953a85e918fe

MAINTAINER=	pkgsrc-users@NetBSD.org
HOMEPAGE=	https://github.com/sebasmonia/sharper/
COMMENT=	.NET SDK CLI wrapper for GNU Emacs using Transient
LICENSE=	mit

EMACS_VERSIONS_ACCEPTED=	emacs29 emacs29nox emacs30 emacs30nox emacs31 emacs31nox
DEPENDS+=	${EMACS_PKGNAME_PREFIX}transient-el-[0-9]*:../../devel/transient-el

INSTALLATION_DIRS=	${EMACS_LISPPREFIX}/sharper

post-extract:
	cd ${WRKSRC} && ${RM} -f *-test.el *-tests.el *-subtest.el test-*.el tests-*.el *-testsuite.el

do-build:
	cd ${WRKSRC} && ${EMACS_BIN} --no-init-file --no-site-file -batch \
		-L . -L ${EMACS_LISPPREFIX}/transient -L ${EMACS_LISPPREFIX}/compat -L ${EMACS_LISPPREFIX}/cond-let -L ${EMACS_LISPPREFIX}/llama -f batch-byte-compile *.el

do-install:
	cd ${WRKSRC} && ${INSTALL_DATA} *.el *.elc \
		${DESTDIR}${EMACS_LISPPREFIX}/sharper

.include "../../editors/emacs/modules.mk"
.include "../../mk/bsd.pkg.mk"
