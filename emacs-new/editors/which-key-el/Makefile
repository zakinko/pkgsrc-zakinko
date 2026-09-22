# $NetBSD$

DISTNAME=	which-key-3.6.1
PKGNAME=	${EMACS_PKGNAME_PREFIX}which-key-el-3.6.1
CATEGORIES=	editors
MASTER_SITES=	https://elpa.gnu.org/packages/
EXTRACT_SUFX=	.tar

MAINTAINER=	pkgsrc-users@NetBSD.org
HOMEPAGE=	https://github.com/justbur/emacs-which-key/
COMMENT=	Display the key bindings following your currently entered keys
LICENSE=	gnu-gpl-v3

EMACS_VERSIONS_ACCEPTED=	emacs29 emacs29nox emacs30 emacs30nox emacs31 emacs31nox

INSTALLATION_DIRS=	${EMACS_LISPPREFIX}/which-key

post-extract:
	cd ${WRKSRC} && ${RM} -f *-test.el *-tests.el *-subtest.el test-*.el tests-*.el *-testsuite.el

do-build:
	cd ${WRKSRC} && ${EMACS_BIN} --no-init-file --no-site-file -batch \
		-L . -f batch-byte-compile *.el

do-install:
	cd ${WRKSRC} && ${INSTALL_DATA} *.el *.elc \
		${DESTDIR}${EMACS_LISPPREFIX}/which-key

.include "../../editors/emacs/modules.mk"
.include "../../mk/bsd.pkg.mk"
