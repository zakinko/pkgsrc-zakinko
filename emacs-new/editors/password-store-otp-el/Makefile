# $NetBSD$

DISTNAME=	password-store-otp-0.1.5
PKGNAME=	${EMACS_PKGNAME_PREFIX}password-store-otp-el-0.1.5
CATEGORIES=	editors
MASTER_SITES=	${MASTER_SITE_GITHUB:=volrath/}
GITHUB_PROJECT=	password-store-otp.el
GITHUB_TAG=	${PKGVERSION_NOREV}
WRKSRC=		${WRKDIR}/password-store-otp.el-0.1.5

MAINTAINER=	pkgsrc-users@NetBSD.org
HOMEPAGE=	https://github.com/volrath/password-store-otp.el
COMMENT=	Major mode for password-store
LICENSE=	gnu-gpl-v3

EMACS_VERSIONS_ACCEPTED=	emacs29 emacs29nox emacs30 emacs30nox emacs31 emacs31nox
DEPENDS+=	password-store-[0-9]*:../../security/password-store
# XXX Gentoo also depends on app-admin/pass-otp
DEPENDS+=	${EMACS_PKGNAME_PREFIX}s-el-[0-9]*:../../devel/s-el

INSTALLATION_DIRS=	${EMACS_LISPPREFIX}/password-store-otp

post-extract:
	cd ${WRKSRC} && ${RM} -f *-test.el *-tests.el *-subtest.el test-*.el tests-*.el *-testsuite.el .dir-locals.el

do-build:
	cd ${WRKSRC} && ${EMACS_BIN} --no-init-file --no-site-file -batch \
		-L . -L ${EMACS_LISPPREFIX}/s -f batch-byte-compile *.el

# files marked no-byte-compile leave no .elc behind
do-install:
	cd ${WRKSRC} && ${INSTALL_DATA} *.el ${DESTDIR}${EMACS_LISPPREFIX}/password-store-otp
	cd ${WRKSRC} && for f in *.elc; do \
		${TEST} ! -f "$$f" || ${INSTALL_DATA} "$$f" ${DESTDIR}${EMACS_LISPPREFIX}/password-store-otp; done

.include "../../editors/emacs/modules.mk"
.include "../../mk/bsd.pkg.mk"
