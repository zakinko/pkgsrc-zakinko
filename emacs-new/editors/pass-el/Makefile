# $NetBSD$

DISTNAME=	pass-2.0.20260214
PKGNAME=	${EMACS_PKGNAME_PREFIX}pass-el-2.0.20260214
CATEGORIES=	editors
MASTER_SITES=	${MASTER_SITE_GITHUB:=NicolasPetton/}
GITHUB_PROJECT=	pass
GITHUB_TAG=	143456809fd2dbece9f241f4361085e1de0b0e75
WRKSRC=		${WRKDIR}/pass-143456809fd2dbece9f241f4361085e1de0b0e75

MAINTAINER=	pkgsrc-users@NetBSD.org
HOMEPAGE=	https://github.com/NicolasPetton/pass
COMMENT=	Major mode for password-store
LICENSE=	gnu-gpl-v3

EMACS_VERSIONS_ACCEPTED=	emacs29 emacs29nox emacs30 emacs30nox emacs31 emacs31nox
DEPENDS+=	password-store-[0-9]*:../../security/password-store
DEPENDS+=	${EMACS_PKGNAME_PREFIX}f-el-[0-9]*:../../devel/f-el
DEPENDS+=	${EMACS_PKGNAME_PREFIX}password-store-otp-el-[0-9]*:../../editors/password-store-otp-el

INSTALLATION_DIRS=	${EMACS_LISPPREFIX}/pass

post-extract:
	cd ${WRKSRC} && ${RM} -f *-test.el *-tests.el *-subtest.el test-*.el tests-*.el *-testsuite.el .dir-locals.el

do-build:
	cd ${WRKSRC} && ${EMACS_BIN} --no-init-file --no-site-file -batch \
		-L . -L ${EMACS_LISPPREFIX}/f -L ${EMACS_LISPPREFIX}/dash -L ${EMACS_LISPPREFIX}/s -L ${EMACS_LISPPREFIX}/password-store-otp -f batch-byte-compile *.el

# files marked no-byte-compile leave no .elc behind
do-install:
	cd ${WRKSRC} && ${INSTALL_DATA} *.el ${DESTDIR}${EMACS_LISPPREFIX}/pass
	cd ${WRKSRC} && for f in *.elc; do \
		test ! -f "$$f" || ${INSTALL_DATA} "$$f" ${DESTDIR}${EMACS_LISPPREFIX}/pass; done

.include "../../editors/emacs/modules.mk"
.include "../../mk/bsd.pkg.mk"
