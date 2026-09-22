# $NetBSD$

DISTNAME=	emojify-1.2.20210309
PKGNAME=	${EMACS_PKGNAME_PREFIX}emojify-el-1.2.20210309
CATEGORIES=	devel
MASTER_SITES=	${MASTER_SITE_GITHUB:=iqbalansari/}
GITHUB_PROJECT=	emacs-emojify
GITHUB_TAG=	1b726412f19896abf5e4857d4c32220e33400b55
WRKSRC=		${WRKDIR}/emacs-emojify-1b726412f19896abf5e4857d4c32220e33400b55

MAINTAINER=	pkgsrc-users@NetBSD.org
HOMEPAGE=	https://github.com/iqbalansari/emacs-emojify/
COMMENT=	Display emojis in Emacs, like :smile: or plain ASCII ones like :)
LICENSE=	gnu-gpl-v3

EMACS_VERSIONS_ACCEPTED=	emacs29 emacs29nox emacs30 emacs30nox emacs31 emacs31nox
DEPENDS+=	${EMACS_PKGNAME_PREFIX}ht-el-[0-9]*:../../devel/ht-el

INSTALLATION_DIRS=	${EMACS_LISPPREFIX}/emojify
USE_TOOLS+=	pax

post-extract:
	cd ${WRKSRC} && ${RM} -f *-test.el *-tests.el *-subtest.el test-*.el tests-*.el *-testsuite.el .dir-locals.el

do-build:
	cd ${WRKSRC} && ${EMACS_BIN} --no-init-file --no-site-file -batch \
		-L . -L ${EMACS_LISPPREFIX}/ht -L ${EMACS_LISPPREFIX}/dash -f batch-byte-compile *.el

do-install:
	cd ${WRKSRC} && ${INSTALL_DATA} *.el *.elc \
		${DESTDIR}${EMACS_LISPPREFIX}/emojify
	cd ${WRKSRC}/. && ${PAX} -rw data ${DESTDIR}${EMACS_LISPPREFIX}/emojify

.include "../../editors/emacs/modules.mk"
.include "../../mk/bsd.pkg.mk"
