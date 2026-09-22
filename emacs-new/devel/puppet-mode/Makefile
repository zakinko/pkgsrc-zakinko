# $NetBSD$

DISTNAME=	puppet-mode-0.4
PKGNAME=	${EMACS_PKGNAME_PREFIX}puppet-mode-0.4
CATEGORIES=	devel
MASTER_SITES=	${MASTER_SITE_GITHUB:=voxpupuli/}
GITHUB_PROJECT=	puppet-mode
GITHUB_TAG=	${PKGVERSION_NOREV}

MAINTAINER=	pkgsrc-users@NetBSD.org
HOMEPAGE=	https://github.com/voxpupuli/puppet-mode/
COMMENT=	Emacs major mode for editing Puppet manifests
LICENSE=	gnu-gpl-v3

EMACS_VERSIONS_ACCEPTED=	emacs29 emacs29nox emacs30 emacs30nox emacs31 emacs31nox

INSTALLATION_DIRS=	${EMACS_LISPPREFIX}/puppet-mode

post-extract:
	cd ${WRKSRC} && ${RM} -f *-test.el *-tests.el *-subtest.el test-*.el tests-*.el *-testsuite.el

do-build:
	cd ${WRKSRC} && ${EMACS_BIN} --no-init-file --no-site-file -batch \
		-L . -f batch-byte-compile *.el

do-install:
	cd ${WRKSRC} && ${INSTALL_DATA} *.el *.elc \
		${DESTDIR}${EMACS_LISPPREFIX}/puppet-mode

.include "../../editors/emacs/modules.mk"
.include "../../mk/bsd.pkg.mk"
