# $NetBSD$

DISTNAME=	rpm-spec-mode-0.16.20241209
PKGNAME=	${EMACS_PKGNAME_PREFIX}rpm-spec-mode-0.16.20241209
CATEGORIES=	devel
MASTER_SITES=	${MASTER_SITE_GITHUB:=Thaodan/}
GITHUB_PROJECT=	rpm-spec-mode
GITHUB_TAG=	283d2aac4ede343586a1fb9e9d2a5917f34809a1
WRKSRC=		${WRKDIR}/rpm-spec-mode-283d2aac4ede343586a1fb9e9d2a5917f34809a1

MAINTAINER=	pkgsrc-users@NetBSD.org
HOMEPAGE=	https://www.emacswiki.org/emacs/RpmSpecMode
COMMENT=	Emacs mode to ease editing of RPM spec files
LICENSE=	gnu-gpl-v2

EMACS_VERSIONS_ACCEPTED=	emacs29 emacs29nox emacs30 emacs30nox emacs31 emacs31nox

INSTALLATION_DIRS=	${EMACS_LISPPREFIX}/rpm-spec-mode

post-extract:
	cd ${WRKSRC} && ${RM} -f *-test.el *-tests.el *-subtest.el test-*.el tests-*.el *-testsuite.el .dir-locals.el

do-build:
	cd ${WRKSRC} && ${EMACS_BIN} --no-init-file --no-site-file -batch \
		-L .  -f batch-byte-compile *.el

do-install:
	cd ${WRKSRC} && ${INSTALL_DATA} *.el *.elc \
		${DESTDIR}${EMACS_LISPPREFIX}/rpm-spec-mode

.include "../../editors/emacs/modules.mk"
.include "../../mk/bsd.pkg.mk"
